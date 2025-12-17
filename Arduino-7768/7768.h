#if !defined c7768_H
#define c7768_H

// Platform tests
#define cDEV_TYPE_UNKNOWN  0
#define cDEV_TYPE_MICROBIT 0
#define cDEV_TYPE_DUE      1
  
#if defined ARDUINO_BBC_MICROBIT_V2
  #define cDEV_TYPE_UNKNOWN  0
  #define cDEV_TYPE_MICROBIT 1
  #define cPLATFORM "BBC Microbit V2"
  #define cDEV_SETUP_M 1

  #if defined NRF51
    // 3 x 9 matrix
  #endif
  #if defined NRF52833_XXAA
    // 5 x 5 matrix
  #endif

  #define cMB_ButtonA_pin  5 
  #define cMB_ButtonB_pin 11

  #define cMB_Buzzer_pin  27

  #define cMB_Col1_pin     4
  #define cMB_Col2_pin     7
  #define cMB_Col3_pin     3
  #define cMB_Col4_pin     6
  #define cMB_Col5_pin    10
  
  #define cMB_Row1_pin    21
  #define cMB_Row2_pin    22
  #define cMB_Row3_pin    23
  #define cMB_Row4_pin    24
  #define cMB_Row5_pin    25
  
  #define cMB_AnalogA_pin  0
  #define cMB_AnalogB_pin  2
  #define cMB_AnalogC_pin  3
  #define cMB_AnalogD_pin  1
  #define cMB_AnalogE_pin  4
  #define cMB_AnalogF_pin 10 
#endif

#if ARDUINO_ARCH_SAM
  #define cDEV_TYPE_UNKNOWN  0
  #define cDEV_TYPE_DUE 1
  #define cPLATFORM "Arduino Due"
 //.............................
 // Set which of our Due h/w configs to compile for...
 // ... See:- dev-panel.h
 // ... A = Due with Data switches, LED bank, 
 // ...     relays(on pseudo PIA)
 // ... B = Due with proto shield for LEDs etc
 // ... C = Due mounted with switches & leds in Lego box
 //         (now superceeded by fork of project elsewhere)
 // ... D = Due with NO switches or LEDS, ( read of F0FF gives 0 )
 //         (set up initially for @GlassTTY, Nov-2025)
 // The latter is used in 7768.ino and other panel code is left out
 //
 #define cDEV_SETUP_A 0
 #define cDEV_SETUP_B 0
 #define cDEV_SETUP_C 0
 #define cDEV_SETUP_D 1

#endif

#if cDEV_TYPE_UNKNOWN
 //#error "UNSUPPORTED BOARD ?  See 7768.h"
#endif

// Include DISASSEMBLER code ?...
#define cDISASSEMBLY 0   // 1=Include   0=Leave out
#if cDISASSEMBLY
 // Oct-2023 : Enough for BASIC code area...
 #define cDISASSEMBLY_START  0x0000
 #define cDISASSEMBLY_END    0x2000
#endif

// For h/w interrupt simulation flow ? 
// #include <Scheduler.h>  // https://www.arduino.cc/en/Reference/Scheduler


//.............................
#define cEMULATION_INTERRUPT_CMD_CHAR   0x1D

#define cNUMBER_OF( x ) ( sizeof( x ) / sizeof( x[0] ) )

// GLOBAL data...
int32_t gi32_Panel_Switch_Changed = false;

// Function templates...

int32_t fi32GetMemoryByte(int32_t);
int32_t fi32GetMemoryWord(int32_t);
void fvPutMemoryByte(int32_t, int32_t);
void fvPutMemoryWord(int32_t, int32_t);

inline void digitalWriteDirect(int pin, boolean val);
void cResetArduino (void);

int freeMemory();


#endif // End: #if !defined c7768_H
