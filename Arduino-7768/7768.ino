/* Newbear 77-68 simulator, C.D.Carter, Oct 2020
 * CDC = Chris Carter
 * DJC = Dave Carter
 * 
 * CDC-Nov-2025: Update for V6 Demon & tweeks for passing to @GlassTTY
 *             : on Arduino DUE with no switches or lights
 * 
 * CDC-Aug-2024: Add code for Lego based switches + Due 
 *             : Add Run & Mode switches and Reset button
 *             : Run switch moved to Halt is like Ctrl+] in non-switches version
 *             : Switch to left of RESET has to be off to allow reset (just a protection)
 *             :
 *             : Possible PLAN for switched buttons:-
 *             : Sw.Run = TRUE...
 *             :    On transition from false, exit console mode back to emulation.
 *             :    Sw.Reset=PRESS AND Sw.Mode=FALSE= jump to content of reset vector
 *             :    Sw.Reset=PRESS AND Sw.Mode=TRUE= no action (effectively a RESET lock)
 *             :
 *             : Sw.Run = HALT...
 *             :    On transition from true, exit to console mode.
 *             :    Sw.Mode=FALSE= Sw.Reset will load ADDRESS value from switches
 *             :       If done once before mode or run change, high order byte is &FF
 *             :       If done twice, first value is moved to high order byte 2nd is low order
 *             :       If done 3rd time, this address is loaded to PC
 *             :    Sw.Mode=TRUE=  Sw.Reset will load DATA value from switches to address
 *             
 * CDC-Jan-2024: (approx.date) Microbit support : Note: Put verbose output ON in IDE preferences
 *             : in order to be able to locate .hex file code output to by S
 *             : Sketch -> Verify/Compile ( or Ctrl+R or the tick icon ).
 *             : When the Microbit is first is plugged in a file folder appears to which 
 *             : you can simply copy this .hex file in order to load the code.
 *             
 * CDC-Feb-2023: Remove SWTPC specifics to simplify code
 *
 * Original 6800 emulation flow taken from...
 * Standalone SWTPC simulator for Arduino Due. Bela Torok June 2014
 * Bela Torok's comments:- 
 * This software is the Aduino DUE port of the SIMH http://simh.trailing-edge.com SWTPC 
 * simulator developed by William Beech.
 * The CPU emulation is a nearly 1:1 implementation of file m6800.c in the SIMH package,
 * the rest of the code is nearly a complete rewrite of the code for standalone operation.
 * 
 * Added classes to encapsulate handling of memory mapped devices
 * for emulating various Newbear 77-68 configurations.
 * 
 * Newbear configurations based on h/w:-
 *    DEMON-SIMON ROM at F800 (2KB)
 *        ACIAs based at F400
 *         PIAs based at F300
 *       255 byte RAM at F000 (on CPU board)
 *      LEDs/Switches at F0FF
 *         Various other RAM
 * 
 * Replaced main 6800 instruction handling loop with later code from SIM-H project
 * 
 * DEMON 77-68 monitor in ROM with games in RAM at start
 */

// Arduino IDE seems to compile .cpp files in some order peculiar to itself
// So lack of cPROJ_ALLOW_CPP_COMPILE should stop them compiling when they should not
// via test in 1st line of each source file.
// This then gets defined after all .h files are processed and then the .cpp files get 
// included via this module...
#undef cPROJ_ALLOW_CPP_COMPILE

// Some system includes...
#include <stdint.h>
#include <stdio.h>
#include <Arduino.h>

#include "7768.h"

//.............................
#include "device.h"
#include "dev-ram.h"
#include "dev-rom.h"
#include "diss.h"
#include "misc.h"
#include "m6800.h"

#include "dev-m6850-acia.h"

#if defined ARDUINO_BBC_MICROBIT_V2
 #include "dev-m6850-acia_dummy.h"
#endif

#include "dev-m6821-pia.h"
#include "dev-panel.h"
 
#include "7768-data-demon.h"
// Optional RAM pre-loads...
//#include "7768-data-basic.h"
 
#if !cDISASSEMBLY
 #include "7768-data-mandc.h"
 #include "7768-data-sw-led-pia.h"
#endif
 
//.............................

// NOW we allow other .cpp modules to compile...
#define cPROJ_ALLOW_CPP_COMPILE

// so include them now...
#include "device.cpp"  //<-<< Include before other `dev-` cpp modules as it is the device parent class
#include "dev-ram.cpp"
#include "dev-rom.cpp"
#include "diss.cpp"

#include "dev-m6850-acia.cpp"
#include "dev-m6821-pia.cpp"
#include "dev-panel.cpp"

#if defined ARDUINO_BBC_MICROBIT_V2
  #include "dev-m6850-acia-dummy.cpp" 
#endif


//...................................................................

// Note: 256 bytes of RAM on motherboard are originally set 0xFF00
//       but if MON1 card is used they move to 0xF000
//       (presumably other MON1 like boards do similar).

#if defined ARDUINO_BBC_MICROBIT_V2
 #define cNEWBEAR_MAX_RAM 0   // Not sure if we have enough RAM on microbit
#endif

#if cDISASSEMBLY
 #define cNEWBEAR_MAX_RAM 0   // Dissassembly work needs more of the Arduino RAM
#else 
 // MAX_RAM means use non-standard `ram board` size to get maximum 
 // contiguous RAM and all in 1 device, so processing is faster...
 
 // *******************************************************************************
 // [JN] Removed in order to emulate a more realistic configuration
 // *******************************************************************************
 //#define cNEWBEAR_MAX_RAM 1   // 1=Use max ram  0=Use limited RAM
 // *******************************************************************************

#endif

// Type     Name          Start    End
//------   -------------  ------  ------
//classROM   objROM_DEMON ( 0xF800, 0xFFFF, u8DEMON_F800_FFFF);  // DEMON monitor program (ROM)(2KB)
//classROM   objROM_DEMON (0xFC00,0xFFFF, u8MINIMON_FC00_ffff); // MINIMON MONITOR
classROM   objROM_DEMON (0xFC00,0xFFFF, uJMON_FC00_ffff); // MINIMON MONITOR

#if cNEWBEAR_MAX_RAM
 // 1 big chunk of RAM up to before main board RAM (no orignal Newbear board did this)...
 // Note: byte at 0xEFFF is not set as RAM, so BASIC memory size count can end without
 // corrupting F000 onwards
  classRAM   objRAM_BIG ( 0x0000, 0xEFFE ); 
#else 
 #if cDISASSEMBLY
  classRAM   objRAM_16KB  ( 0x0000, 0x3FFF );  // 16k RAM board
 #else
  // Traditional Newbear RAM cards and motherboard RAM
  //classRAM   objRAM_32KB  ( 0x0000, 0x7FFF );  // 32k RAM board
  //classRAM   objRAM_4KB   ( 0x0000, 0xBFFF );  //  4k RAM board for BASIC i/o (temp)
  classRAM   objRAM_8KB   ( 0x0000, 0x1FFF );  //  4k RAM board for BASIC i/o (temp)
  classRAM   objRAM_1KB   ( 0xF800, 0xFBFF );  //  1K Video ram handy for development as upper 1K is ROM
 #endif
#endif

classRAM   objRAM_255B  ( 0xF000, 0xF0FE );  // 255 bytes of RAM out of 256 addresses on main board...
classPANEL objPANEL     ( 0xF0FF );          // as PANEL (LEDs & Switches) use the 256th byte address

#if defined c7768_DATA_BASIC8K_H
 classRAM   objRAM_IO    ( 0xF100, 0xF2FF );  // A little area mainly for DEMON-Basic I/O glue
#endif
// Main serial ACIAs...
classM6850 objM6850_A   ( 0xF400, &Serial );
#if defined ARDUINO_BBC_MICROBIT_V2
classM6850_dummy objM6850_B_dummy ( 0xF402 ); // ACIA(b) DUMMY on MicroBit
#else
//-x classM6850 objM6850_B   ( 0xF402, &Serial ); // Test
classM6850 objM6850_B   ( 0xF402, &SerialUSB ); // ACIA(b) using 2nd USB on DUE 
#endif

#define cNEWBEAR_7768_EXTRA_SERIALS 0  // 0=No extra serials, 1=define extra serials
#if cNEWBEAR_7768_EXTRA_SERIALS
//... Adding more serial devices for spare ports on arduino DUE...
classM6850 objM6850_S1  ( 0xF404, &Serial1 );
classM6850 objM6850_S2  ( 0xF406, &Serial2 );
classM6850 objM6850_S3  ( 0xF408, &Serial3 );
#endif

//... Add PIA board (6821 device)...
// Note: Each 6821 is 2 x 8 bit i/o sets
// the first is set up to use data pins (ouput only)
// which are coupled to relays on CDC test system.
#if defined ARDUINO_BBC_MICROBIT_V2
 // NOT on MicroBit
#else
// PIA for Twit.NT (Now with Dave Williams)
// Dave has 2xPIA chips (each with 2 8 bit I/Os) at 0xF708 & 0xF70C on his twits
classM6821 objM6821_A  ( 0xF300 ); 
#endif

// Make an array of references to the device objects which make up this system...
classMemoryMappedDevice * objDevice[] = {
  &objROM_DEMON,   // DEMON monitor ROM
#if cNEWBEAR_MAX_RAM
  &objRAM_BIG, // One big chunk of RAM
#else
 #if cDISASSEMBLY
  &objRAM_16KB,
 #else
  //&objRAM_32KB,    // 32KB RAM board
  //&objRAM_4KB,     // 4KB RAM board
  &objRAM_8KB,     // 2x4KB RAM board
  &objRAM_1KB,
 #endif
#endif  
  &objRAM_255B,    // 256 bytes on main Processor board (last byte of 256 is mapped to LED/Swtich panel)
  &objPANEL,       // LEDs and switches
#if defined c7768_DATA_BASIC8K_H
  &objRAM_IO,
#endif  
  &objM6850_A,     // Acia.A
#if defined ARDUINO_BBC_MICROBIT_V2
  &objM6850_B_dummy, // Acia.B DUMMY
#else
  &objM6850_B,     // Acia.B  
#endif  
#if cNEWBEAR_7768_EXTRA_SERIALS
//.. Adding more serial devices for spare ports on arduino DUE...
  &objM6850_S1,
  &objM6850_S2,
  &objM6850_S3,
#endif

#if defined ARDUINO_BBC_MICROBIT_V2
  #define cDEV_M6821_OP_RELAYS 0
#endif
#if cDEV_M6821_OP_RELAYS
  &objM6821_A,
#endif
};

//---------------------------------------------------

// Include m6800 code AFTER harware objects are defined...
#include "misc.cpp"
#include "m6800.cpp"

//---------------------------------------------------
int32_t fi32GetMemoryByte(int32_t i32Addr) {

  // Loop through devices...
  for (int iAtDev=0; iAtDev < cNUMBER_OF(objDevice); iAtDev++) {
    // If this device `owns` this address, then read from it and return...
    if ( objDevice[iAtDev]->mine(i32Addr) ) {
      return( objDevice[iAtDev]->read(i32Addr) );
    }
  } // End: for (<devices>)

  // If no RAM/ROM, Newbear returns FF
  // Not sure about SWTPC
  return( 0xFF ); 
}

//---------------------------------------------------
int32_t fi32GetMemoryWord(int32_t i32Addr) {
  static int32_t i32Value;
  i32Value  = ( fi32GetMemoryByte(i32Addr) << 8 );
  i32Value |= fi32GetMemoryByte(i32Addr + 1);
  return( i32Value );
}

//---------------------------------------------------
void fvPutMemoryByte(int32_t i32Addr, int32_t i32Byte) {
  // Loop through devices...
  for (int iAtDev=0; iAtDev < cNUMBER_OF(objDevice); iAtDev++) {
    // If this device `owns` this address, then write to it and return...
    if (objDevice[iAtDev]->mine(i32Addr)) {
      objDevice[iAtDev]->write(i32Addr,i32Byte);
      return;
    }
  }
  return;
}

//---------------------------------------------------
void fvPutMemoryWord(int32_t i32Addr, int32_t i32Value) {
    fvPutMemoryByte(i32Addr, i32Value >> 8);
    fvPutMemoryByte(i32Addr+1, i32Value);
}

// end of Read / Write Memory routines

//---------------------------------------------------
#if cDEV_PANEL_SWITCHES
// Interrupt routine to set flag when any switch is moved.
// Flag is then checked in main processing loop in `6800.cpp`
void fvPanelInterruptPinStateChange() {
  // Set flag for main 6800 handling loop to check...
  // Note: We want this routine to be a quick as possible so
  // as to get out of `interrupt active` state asap...
  gi32_Panel_Switch_Changed = true;
}
#endif

//---------------------------------------------------
// From: https://forum.arduino.cc/t/port-manipulation-pinx-commands-with-arduino-due/127121/16
// See:  https://forum.arduino.cc/t/port-manipulation-pinx-commands-with-arduino-due/127121/39
// for setting multiple pins in same call.
//--- 
// Note: For Arduino DUE, will not compile on many other board types...
inline void digitalWriteDirect(int pin, boolean val) {
  
#if defined ARDUINO_BBC_MICROBIT_V2
 digitalWrite(pin, val);
#else
#if 1
  if(val) g_APinDescription[pin].pPort -> PIO_SODR = g_APinDescription[pin].ulPin;
  else    g_APinDescription[pin].pPort -> PIO_CODR = g_APinDescription[pin].ulPin;
#else
 digitalWrite(pin, val);
#endif
#endif
}

//---
// A random note... hangover from some old experiment...
//x inline int digitalReadDirect(int pin){
//x   return !!(g_APinDescription[pin].pPort -> PIO_PDSR & g_APinDescription[pin].ulPin);
//x }


//---------------------------------------------------
#if ARDUINO_BBC_MICROBIT_V2
void cResetArduino(void) {
 // For Microbit, just tell user to do it ! ... 
 Serial.println("** Press RESET on the Microbit **");
 while(true) { delay(1000); /*wait forever*/ }
}
#endif


#if ARDUINO_ARCH_AVR
// A jump to location zero will reset
// AVR type Arduinos...
// Declare reset function at address 0
void(* resetFunc) (void) = 0;
void cResetArduino(void) {
 resetFunc(); //call reset  
 //... in case reset fails...>
 Serial.println("** Press RESET on the Arduino **");
 while(true) { delay(1000); /*wait forever*/ }
}
#endif

#if ARDUINO_ARCH_SAM
void cResetArduino (void) {
 // From: https://forum.arduino.cc/t/due-software-reset/332764
 //Defines so the device can do a self reset
 #define SYSRESETREQ    (1<<2)
 #define VECTKEY        (0x05fa0000UL)
 #define VECTKEY_MASK   (0x0000ffffUL)
 #define AIRCR          (*(uint32_t*)0xe000ed0cUL) // fixed arch-defined address
 #define REQUEST_EXTERNAL_RESET (AIRCR=(AIRCR&VECTKEY_MASK)|VECTKEY|SYSRESETREQ)
 Serial.println();
 Serial.println("** Restarting **");
 delay(1500);
 REQUEST_EXTERNAL_RESET;

 //... in case reset fails...>
 Serial.println("** Press RESET on the Arduino **");
 while(true) { delay(1000); /*wait forever*/ }
}
#endif // ARDUINO_ARCH_SAM

//:::::::::::::::::::::::::::::::::::::::::::::::::::
#ifdef __arm__
// should use uinstd.h to define sbrk but Due causes a conflict
extern "C" char* sbrk(int incr);
#else  // __ARM__
extern char *__brkval;
#endif  // __arm__

int freeMemory() {
  char top;
#ifdef __arm__
  return &top - reinterpret_cast<char*>(sbrk(0));
#elif defined(CORE_TEENSY) || (ARDUINO > 103 && ARDUINO != 151)
  return &top - __brkval;
#else  // __arm__
  return __brkval ? &top - __brkval : &top - __malloc_heap_start;
#endif  // __arm__
}

//---------------------------------------------------
// SETUP
//------
void setup () 
{
#if cDEV_M6821_OP_RELAYS
  // Set up pins modes etc for 1st PIA to use RELAYS...
  objM6821_A.vSetupRelays();
#endif  

#if cDEV_PANEL_SWITCHES
  // Set an interrupt routine to get called when any switch is moved...
  // NOTE: DUE has interrupts on all data pins, most other arduinos do not.
  objPANEL.vSetupInterrupts(&fvPanelInterruptPinStateChange);
#endif

  // Open main Serial USB TTY line...
  Serial.begin(9600);
  while (!Serial) { delay(100); } // Hang about until ready

#if defined cDEV_PANEL_H
   objPANEL.vSetup(); // Set up Speaker and LED o/p pins etc
#endif   

#if cDEV_TYPE_MICROBIT
  // No builtin LED pin
  // but we do have 2 input buttons (held HIGH when unpressed)...
  //x pinMode(cMB_ButtonA_pin, INPUT);
  //x pinMode(cMB_ButtonB_pin, INPUT);
#else  
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
#endif

  Serial.println ();
  Serial.print("M6800: Newbear 77-68 emulation on ");
  Serial.println( cPLATFORM );
#if ARDUINO_BBC_MICROBIT_V2
  // Delays to try to avoid flooding o/p buffers on Microbit
  delay(50);
#endif
  Serial.print("Built at ");
  Serial.print( __TIME__ );
  Serial.print(" on ");
  Serial.println( __DATE__ );
  //Serial.print("Free RAM: ");
  //Serial.println( freeMemory() );
#if ARDUINO_BBC_MICROBIT_V2
  // Delays to try to avoid flooding o/p buffers on Microbit
  delay(50);
#endif

  // Loop through devices to write information to console...
  for (int iAtDev=0; iAtDev < cNUMBER_OF(objDevice); iAtDev++) {
    objDevice[iAtDev]->ShowInformation( &Serial );
#if ARDUINO_BBC_MICROBIT_V2
  // Delays to try to avoid flooding o/p buffers on Microbit
    delay(50);
#endif
  }
  Serial.println();
  //Serial.println ("DEMON monitor program (? for help)");
  #if defined c7768_DATA_BASIC8K_H
    Serial.println ("Type `G 0000` to start BASIC");
  #endif
#if ARDUINO_BBC_MICROBIT_V2
  // Delays to try to avoid flooding o/p buffers on Microbit
    delay(200);
#endif

  #if cDISASSEMBLY
    Serial.println ("Disassembly area set");
  #endif
  
  Serial.flush();

#if 0   // Note: An experiment with Due...
  //
  // Look for SerialUSB physical connection...
  // Ref: https://forum.arduino.cc/t/solved-serialusb-checking-if-connection-is-still-present/582448
  {
    int CountA;
    int CountB;
    CountA = (UOTGHS->UOTGHS_DEVFNUM & UOTGHS_DEVFNUM_FNUM_Msk) >> UOTGHS_DEVFNUM_FNUM_Pos;
    delay(150);
    CountB = (UOTGHS->UOTGHS_DEVFNUM & UOTGHS_DEVFNUM_FNUM_Msk) >> UOTGHS_DEVFNUM_FNUM_Pos;
    if ( CountA != CountB ) {
      Serial.println ("Note: 2nd (Native) USB is plugged in.\n");
     }
  }
#endif  

//+++++++++++++++++++++++++
//Serial.print("unsigned long =");
//Serial.println( sizeof(unsigned long) );
//+++++++++++++++++++++++++

  m6800_reset();
}

//---------------------------------------------------
// LOOP
//-----
void loop () 
{
  int32_t iReason;
  int32_t iOffset;

#if defined c7768_DATA_BASIC8K_H
  // Load BASIC into RAM at 0x0000...
  iOffset = 0x0000;
  for (int iAt=0; iAt < sizeof(u8RAM_BASIC8Ka); iAt++) {
    fvPutMemoryByte( (iAt + iOffset), u8RAM_BASIC8Ka[iAt] );
  }
  // Load I/O into RAM at 0xF100...
  iOffset = 0xF100;
  for (int iAt=0; iAt < sizeof(u8RAM_BASIC8Kb); iAt++) {
    fvPutMemoryByte( (iAt + iOffset), u8RAM_BASIC8Kb[iAt] );
  }
#endif

  iReason = sim_6800_go();

  Serial.println();
  Serial.print("M6800: ");
  switch(iReason)
  {
  case cM6800_STOP_HALT: 
    Serial.println("Opcode WAI executed");
    break;
  default:
    Serial.print("Unknown=");
    Serial.println(iReason);
    break;
  }

  Serial.println();
  Serial.println("M6800: Press Reset to reboot!");
  while(1) { delay(100); } // STOP

}

// The End
