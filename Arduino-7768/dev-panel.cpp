#if !defined cDEV_PANEL_CPP && defined cPROJ_ALLOW_CPP_COMPILE
#define cDEV_PANEL_CPP

// This version of panel puts LED bits onto a 10 segment LED bar
// One LED is RED (bottom bit) so data is shifted left 2 bits
// to skip it and leave a gap.
// Special calls allow the extra yellow and the red segment
// to be used.

#if cDEV_PANEL_LEDBAR
 Grove_LED_Bar _LedBar(cDEV_PANEL_LEDBAR_PIN_CLOCK, cDEV_PANEL_LEDBAR_PIN_DATA, cDEV_PANEL_LEDBAR_REVERSE_BITS);  
#endif

    // Constructor...
    
classPANEL::classPANEL( int32_t i32Addr  ) {
      // Give parent class our address range...
      _mmd_i32StartAddr = i32Addr;
      _mmd_i32EndAddr   = i32Addr;
      _mmd_sType = (char *)"PANEL";
#if cDEV_PANEL_LEDBAR
      _LedBar.begin();
      _LedBar.setBits( cDEV_PANEL_LEDBAR_EXTRA_BIT_RED ); //<- Clear LEDs + red on
#endif 
    } //  End: constructor

    //----------------------------------------
void classPANEL::vSetup() {
 #if cDEV_PANEL_SPEAKER
      pinMode( cDEV_PANEL_SPEAKER_PIN, OUTPUT );
 #endif
 #if cDEV_PANEL_LEDPINS
      int32_t i32PinAt = cDEV_PANEL_LED_PIN_START;
      for (int32_t i32Loop = 0; i32Loop < cDEV_PANEL_LED_PIN_COUNT; i32Loop++) {
        pinMode( i32PinAt, OUTPUT );
        digitalWrite( i32PinAt, LOW );
        i32PinAt += cDEV_PANEL_LED_PIN_INCREMENT;
      }
  #if defined cDEV_PANEL_LED_EXTRA_PIN_A
      pinMode( cDEV_PANEL_LED_EXTRA_PIN_A, OUTPUT );
      //x digitalWrite( cDEV_PANEL_LED_EXTRA_PIN_A, LOW );
      // Amber on Lego : turn on to show powered up....
      digitalWrite( cDEV_PANEL_LED_EXTRA_PIN_A, LOW );
  #endif
  #if defined cDEV_PANEL_LED_EXTRA_PIN_B
      pinMode( cDEV_PANEL_LED_EXTRA_PIN_B, OUTPUT );
      //x digitalWrite( cDEV_PANEL_LED_EXTRA_PIN_B, LOW );
      digitalWrite( cDEV_PANEL_LED_EXTRA_PIN_B, LOW );
  #endif      
  #if defined cDEV_PANEL_LED_EXTRA_PIN_C
      pinMode( cDEV_PANEL_LED_EXTRA_PIN_C, OUTPUT );
      digitalWrite( cDEV_PANEL_LED_EXTRA_PIN_C, LOW );
  #endif      
 #endif    
 #if cDEV_PANEL_TFT_BEAR
  Wire.begin(); // join i2c bus (address optional for master)
 #else
 #if cDEV_PANEL_MICROBIT_PIANO_KEYS
    Wire.begin(); // join i2c bus (address optional for master)
    //x _PianoKeys.readKeys();
  #endif
 #endif
    }  // End: vSetup()

    //----------------------------------------
#if cDEV_PANEL_SWITCHES
void classPANEL::vSetupInterrupts( void (*vInterruptRoutine)(void) ) {
      int32_t i32PinAt = cDEV_PANEL_SW_PIN_START;
      for (int32_t i32Loop = 0; i32Loop < cDEV_PANEL_SW_PIN_COUNT; i32Loop++) {
        pinMode( i32PinAt, INPUT_PULLUP );
        attachInterrupt(digitalPinToInterrupt(i32PinAt), vInterruptRoutine, CHANGE);
        i32PinAt += cDEV_PANEL_SW_PIN_INCREMENT;
      }
#if cDEV_SETUP_C
      pinMode( cDEV_PANEL_SW_PIN_RUN, INPUT_PULLUP );
      attachInterrupt(digitalPinToInterrupt(cDEV_PANEL_SW_PIN_RUN), vInterruptRoutine, CHANGE);
      pinMode( cDEV_PANEL_SW_PIN_MODE, INPUT_PULLUP );
      attachInterrupt(digitalPinToInterrupt(cDEV_PANEL_SW_PIN_MODE), vInterruptRoutine, CHANGE);
      pinMode( cDEV_PANEL_SW_PIN_RESET, INPUT_PULLUP );
      attachInterrupt(digitalPinToInterrupt(cDEV_PANEL_SW_PIN_RESET), vInterruptRoutine, CHANGE);
#endif      
    vReadSwitchPins();
    }
#endif    

    //----------------------------------------
    // Called by parent to read switches/buttons and update public `switchState` value
#if cDEV_PANEL_SWITCHES
void classPANEL::vReadSwitchPins() {
      int32_t i32Value = 0;
      int32_t i32PinAt = cDEV_PANEL_SW_PIN_START;
      for (int32_t i32Loop = 0; i32Loop < cDEV_PANEL_SW_PIN_COUNT; i32Loop++) {
        i32Value *= 2; // Shift value got so far left 1 bit
        if ( cDEV_PANEL_SW_PIN_NEGATE ) {
          i32Value += !digitalRead(i32PinAt);
        } else {
          i32Value += digitalRead(i32PinAt);
        }
        i32PinAt += cDEV_PANEL_SW_PIN_INCREMENT;
      }
      _i32SwitchValue = i32Value ;

#if cDEV_SETUP_C
      // RUN / HALT...
      i32Value = digitalRead( cDEV_PANEL_SW_PIN_RUN );
      if ( i32Value != _i32SwitchRun ) {
        _i32SwitchReset = false;  // Clear reset on Run/Halt change
        _i32SwitchRun = i32Value ;
        digitalWrite( cDEV_PANEL_LED_EXTRA_PIN_C, _i32SwitchRun );
      }

      // RESET...  ( NOTE: THIS BUTON IS true WHEN NOT PRESSED )
      i32Value = !digitalRead( cDEV_PANEL_SW_PIN_RESET );
      if ( i32Value != _i32SwitchReset ) {
        if ( _i32SwitchReset == false ) _i32SwitchReset = i32Value;
        digitalWrite( cDEV_PANEL_LED_EXTRA_PIN_A, _i32SwitchReset );
      }

      // LOAD / DATA mode for switches...
      i32Value  = digitalRead( cDEV_PANEL_SW_PIN_MODE );
      if ( i32Value != _i32SwitchMode ) {
        _i32SwitchMode = i32Value;
        digitalWrite( cDEV_PANEL_LED_EXTRA_PIN_B, _i32SwitchMode );
      }  
      
#endif      
      
    } 
#endif      
#if cDEV_PANEL_MICROBIT_PIANO_KEYS
void classPANEL::vReadSwitchPins() {
   int32_t i32Value = 0;
   _PianoKeys.readKeys();
   for (int32_t i32Loop = 0; i32Loop < 14; i32Loop++) {
     i32Value *= 2; // Shift value got so far left 1 bit
     i32Value += _PianoKeys.isKeyDown(i32Loop);
   }
    _i32SwitchValue = i32Value;
}
#endif
 
    //----------------------------------------
    // Called by parent to set the (9th) yellow and 10th (red) bit on/off
    // Returns TRUE if `switchState` has changed...
void classPANEL::setExtraBits(int32_t i32ExtraSet) {
#if cDEV_PANEL_LEDPINS
      if (_i32LedExtraBits != i32ExtraSet) {
        int32_t i32NewValue = LOW;
        _i32LedExtraBits = i32ExtraSet;
         if ((i32ExtraSet & 0x01) > 0) i32NewValue = HIGH;
         digitalWrite( cDEV_PANEL_LED_EXTRA_PIN_A, i32NewValue );
         if ((i32ExtraSet & 0x02) > 0) i32NewValue = HIGH;
         else                          i32NewValue = LOW;
         digitalWrite( cDEV_PANEL_LED_EXTRA_PIN_B, i32NewValue );
      }
#endif
      
#if cDEV_PANEL_LEDBAR
      _i32LedExtraBits = i32ExtraSet & cDEV_PANEL_LEDBAR_EXTRA_BIT_MASK;
 #if cDEV_PANEL_LEDBAR_REVERSE_BITS
      _LedBar.setBits( _i32LedState | _i32LedExtraBits );
 #else
      _LedBar.setBits( (_i32LedState<<2) | _i32LedExtraBits );
 #endif        
#endif 

#if cDEV_PANEL_TFT_BEAR
      if ( _TFT_Bear ) {
      int iError;
      Wire.beginTransmission(8); // transmit to device #8
      Wire.write(0x00);          // Function.0
      Wire.write((unsigned char)_i32LedState); 
      iError = Wire.endTransmission();    // stop transmitting
      if ( iError != 0 ) {
        // Probably not connected, so stop trying...
        _TFT_Bear = false;
      }
      }
#endif     
      return;
    } 
 
    //----------------------------------------
int32_t classPANEL::read( int32_t i32Addr ) {
      if ( !mine( i32Addr ) ) return( 0 );
#if cDEV_PANEL_SWITCHES
      return( _i32SwitchValue );
#else      
      return( 0x00 );  // No switches, so all OFF
#endif      
    } // End: read(...)

    //----------------------------------------
void classPANEL::write( int32_t i32Addr, int32_t i32Byte ) {
      int32_t i32NewState = i32Byte & 0xFF;

      if ( !mine( i32Addr ) ) return;

      if ( _i32LedState != i32NewState ) {
        _i32LedState = i32NewState;
        
 #if cDEV_PANEL_LEDPINS
        {//...
        int32_t i32PinAt = cDEV_PANEL_LED_PIN_START;
        int32_t i32Bits = _i32LedState;
        int32_t i32NewValue;
        for (int32_t i32Loop = 0; i32Loop < cDEV_PANEL_LED_PIN_COUNT; i32Loop++) {
          if ((i32Bits & 0x01) > 0) i32NewValue = HIGH;
          else                      i32NewValue = LOW;
          //x digitalWrite( i32PinAt, i32NewValue );
          digitalWriteDirect( i32PinAt, i32NewValue );
          i32PinAt += cDEV_PANEL_LED_PIN_INCREMENT;
          i32Bits >>= 1;
        }
        }//...
 #endif    
        
 #if cDEV_PANEL_LEDBAR
  #if cDEV_PANEL_LEDBAR_REVERSE_BITS
        _LedBar.setBits( _i32LedState | _i32LedExtraBits );
  #else
        _LedBar.setBits( (_i32LedState<<2) | _i32LedExtraBits );
  #endif        
 #endif
 #if cDEV_PANEL_SPEAKER
      static int32_t i32OldBit = 0;
      int32_t i32Bit = _i32LedState & 0x01;
      if ( i32OldBit != i32Bit ) {
        i32OldBit = i32Bit;
        digitalWriteDirect( cDEV_PANEL_SPEAKER_PIN, i32Bit );
      }  
 #endif

    } // End: if new state

  return;
  } // End: write(...)

    //----------------------------------------
#if cDEV_SETUP_C
int32_t classPANEL::readSwReset() {
      int32_t iState = _i32SwitchReset;
      _i32SwitchReset = false; // CLEAR RESET on read (it's a button)
      return( iState );
    } // End: readRset()

int32_t classPANEL::readSwMode() {
      return( _i32SwitchMode );
    } // End: readRset()
    
int32_t classPANEL::readSwRun() {
      return( _i32SwitchRun );
    } // End: readRset()
#endif
  

#endif
