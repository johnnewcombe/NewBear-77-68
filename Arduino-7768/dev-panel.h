#if !defined cDEV_PANEL_H
#define cDEV_PANEL_H

//....................................................
#if cDEV_SETUP_A

 #define cDEV_PANEL_SPEAKER  1    // Output : Speaker to be set to same as low bit of panel
 #define cDEV_PANEL_SPEAKER_PIN 3 // Physical pin for speaker on DUE
 
 #define cDEV_PANEL_LEDBAR   0   // Output to Grove (or similar SDA/SCL) LEDBAR
 #define cDEV_PANEL_LEDPINS  1   // Output to simple 1-pin per LED LEDBAR

 #if cDEV_PANEL_LEDPINS

  #define cDEV_PANEL_LED_PIN_START      23
  #define cDEV_PANEL_LED_PIN_INCREMENT   2
  #define cDEV_PANEL_LED_PIN_COUNT       8
  #define cDEV_PANEL_LED_EXTRA_PIN_A    39
  #define cDEV_PANEL_LED_EXTRA_PIN_B    41

  #define cDEV_PANEL_LEDBAR_EXTRA_BIT_RED    0x01
  #define cDEV_PANEL_LEDBAR_EXTRA_BIT_YELLOW 0x02
 #endif

 #define cDEV_PANEL_SWITCHES 1   // Input
 #if cDEV_PANEL_SWITCHES
 #if 0
   #define cDEV_PANEL_SW_PIN_START      38
   #define cDEV_PANEL_SW_PIN_INCREMENT   2
   #define cDEV_PANEL_SW_PIN_COUNT       8
   #define cDEV_PANEL_SW_PIN_NEGATE   false
  #else
   #define cDEV_PANEL_SW_PIN_START      52
   #define cDEV_PANEL_SW_PIN_INCREMENT  -2
   #define cDEV_PANEL_SW_PIN_COUNT       8
   #define cDEV_PANEL_SW_PIN_NEGATE   false
  #endif
 #endif
#endif
//....................................................

#if cDEV_SETUP_B
 // This setup not currently used
 #define cDEV_PANEL_SPEAKER  1   // Output : Speaker to be set to same as low bit of panel
 #if cDEV_PANEL_SPEAKER
  #define cDEV_PANEL_SPEAKER_PIN 22 // Physical pin for speaker on DUE
 #endif
  
 #define cDEV_PANEL_LEDBAR   0   // Output
 #define cDEV_PANEL_LEDPINS  1   // Output

 #if cDEV_PANEL_LEDPINS
  #define cDEV_PANEL_LED_PIN_START      34
  #define cDEV_PANEL_LED_PIN_INCREMENT   2
  #define cDEV_PANEL_LED_PIN_COUNT       8
  #define cDEV_PANEL_LED_EXTRA_PIN_A    50
  #define cDEV_PANEL_LED_EXTRA_PIN_B    52

  #define cDEV_PANEL_LEDBAR_EXTRA_BIT_RED    0x01
  #define cDEV_PANEL_LEDBAR_EXTRA_BIT_YELLOW 0x02
 #endif

 #define cDEV_PANEL_SWITCHES 1   // Input
 #if cDEV_PANEL_SWITCHES
  #define cDEV_PANEL_SW_PIN_START       A0
  #define cDEV_PANEL_SW_PIN_INCREMENT   1
  #define cDEV_PANEL_SW_PIN_COUNT       8
  #define cDEV_PANEL_SW_PIN_NEGATE   true
 #endif
#endif

//....................................................
#if cDEV_SETUP_C
// Lego Due

 #define cDEV_PANEL_SPEAKER  1   // Output : Speaker to be set to same as low bit of panel
 #define cDEV_PANEL_SPEAKER_PIN 3 // Physical pin for speaker on DUE

 #define cDEV_PANEL_LEDPINS  1   // Output

 #if cDEV_PANEL_LEDPINS
  #define cDEV_PANEL_LED_PIN_START      41
  #define cDEV_PANEL_LED_PIN_INCREMENT  -1
  #define cDEV_PANEL_LED_PIN_COUNT       8
  
  #define cDEV_PANEL_LED_EXTRA_PIN_A     5
  #define cDEV_PANEL_LED_EXTRA_PIN_B     6
  #define cDEV_PANEL_LED_EXTRA_PIN_C     7

 #endif
  
 #define cDEV_PANEL_SWITCHES 1   // Input
 #if cDEV_PANEL_SWITCHES
   #define cDEV_PANEL_SW_PIN_START      22
   #define cDEV_PANEL_SW_PIN_INCREMENT   1
   #define cDEV_PANEL_SW_PIN_COUNT       8
   #define cDEV_PANEL_SW_PIN_NEGATE   false

   #define cDEV_PANEL_SW_PIN_RUN         30
   #define cDEV_PANEL_SW_PIN_MODE        31 
   #define cDEV_PANEL_SW_PIN_RESET       9

 #endif
#endif
//....................................................
#if cDEV_SETUP_D

 #define cDEV_PANEL_SPEAKER  1    // Output : Speaker to be set to same as low bit of panel
 #define cDEV_PANEL_SPEAKER_PIN 3 // Physical pin for speaker on DUE
 
 #define cDEV_PANEL_LEDBAR   0   // Output to Grove (or similar SDA/SCL) LEDBAR
 #define cDEV_PANEL_LEDPINS  0   // Output to simple 1-pin per LED LEDBAR
 #define cDEV_PANEL_SWITCHES 0   // Input
 
#endif
//....................................................

#if cDEV_SETUP_M

 #define cDEV_PANEL_SPEAKER  1   // Output : Speaker to be set to same as low bit of panel
 #define cDEV_PANEL_SPEAKER_PIN 27 // Physical pin for buzzer on MicroBit
  
 #define cDEV_PANEL_LEDBAR   1   // Output via I2C1 i/f pins
 #define cDEV_PANEL_LEDBAR_REVERSE_BITS 0
 #if 0
 // Pins labelled I2C on MicroBit...
 #define cDEV_PANEL_LEDBAR_PIN_CLOCK  19
 #define cDEV_PANEL_LEDBAR_PIN_DATA   20
#else 
 // Spare GPIO on MicroBit...
 // ( it works ! )...
 #define cDEV_PANEL_LEDBAR_PIN_CLOCK   8
 #define cDEV_PANEL_LEDBAR_PIN_DATA    9
#endif
 
 #define cDEV_PANEL_SWITCHES 0   // Input
 #define cDEV_PANEL_MICROBIT_PIANO_KEYS 0 // Input keys  WORK IN PROGRESS

#endif
//....................................................


#if cDEV_PANEL_LEDBAR
 #include <Grove_LED_Bar.h>
 //
 #if cDEV_PANEL_LEDBAR_REVERSE_BITS
  #define cDEV_PANEL_LEDBAR_EXTRA_BIT_RED     0x200
  #define cDEV_PANEL_LEDBAR_EXTRA_BIT_YELLOW  0x100
  #define cDEV_PANEL_LEDBAR_EXTRA_BIT_MASK    0x300
 #else
  #define cDEV_PANEL_LEDBAR_EXTRA_BIT_RED     0x001
  #define cDEV_PANEL_LEDBAR_EXTRA_BIT_YELLOW  0x002
  #define cDEV_PANEL_LEDBAR_EXTRA_BIT_MASK    0x003
 #endif
#endif

#define cDEV_PANEL_TFT_BEAR 0
#if cDEV_PANEL_TFT_BEAR  // (Never implemented, one day, perhaps !)
 // TFT-Bear is a UNO with a TFT shield
 // which we pass LED state to via I2C 
 #include <Wire.h>
#endif

#if cDEV_PANEL_MICROBIT_PIANO_KEYS
 // BBC Microbit with SDcomponents piano keyboard
 // Note: Nov-2025: Don't think this worked well
 #include <Wire.h>
 #include <TTP229.h>
#endif


//---

class classPANEL : public classMemoryMappedDevice {
  
  private:
    int32_t _i32LedState = 0;
    int32_t _i32LedExtraBits = 0;
    int32_t _i32SwitchValue = 0;
#if cDEV_PANEL_TFT_BEAR
    int32_t _TFT_Bear = true;
#endif
#if cDEV_PANEL_MICROBIT_PIANO_KEYS
    TTP229 _PianoKeys;
#endif 
#if cDEV_SETUP_C
    int32_t _i32SwitchReset = false;
    int32_t _i32SwitchMode  = false;
    int32_t _i32SwitchRun   = false;
#endif

  public:
    classPANEL( int32_t i32Addr  );
    void vSetup();
    void vSetupInterrupts( void (*vInterruptRoutine)(void) );
#if cDEV_PANEL_SWITCHES
    void vReadSwitchPins();
#endif      
#if cDEV_PANEL_MICROBIT_PIANO_KEYS
    void vReadSwitchPins();
#endif      
    void setExtraBits(int32_t i32ExtraSet);
    int32_t read( int32_t i32Addr );
    void write( int32_t i32Addr, int32_t i32Byte );

#if cDEV_SETUP_C
    int32_t readSwReset();
    int32_t readSwMode();
    int32_t readSwRun();
#endif
};


#endif
