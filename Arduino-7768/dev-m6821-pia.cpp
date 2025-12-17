#if !defined cDEV_M6821_PIA_CPP && defined cPROJ_ALLOW_CPP_COMPILE
#define cDEV_M6821_PIA_CPP

/*
 *  ------------------------------------------------------------
 *  Newbear 77-68
 *  -------------
 *  PIA : Information from Design Note 49, PIO-A board:-
 *  
 *  F300 : PIA.A : Peripheral reg : Data pins
 *  F300 : PIA.A : Data Direction reg
 *               : Bit set to 0 = pin is INPUT
 *               : Bit set to 1 = pin is OUTPUT
 *  F301 : PIA.A : CONTROL register
 *                 [7] = IRQA1 Interrupt flag(ro)
 *                 [6] = IRQA2 Interrupt flag(ro)
 *                 [5][4][3] = CA2 control
 *                 [2] 1 = Peripheral reg access
 *                     0 = Data.Dir.reg access
 *                 [1][0] = CA1 control
 *  
 *  F302 : PIA.B : Peripheral reg : Data pins
 *  F302 : PIA.B : Data Direction reg
 *  F303 : PIA.B : CONTROL register
 *  ------------------------------------------------------------
*/

// Constructor...
    
classM6821::classM6821( int32_t i32Addr ) {
      // If we got the RAM, then set our address range...
      _mmd_i32StartAddr = i32Addr;
      _mmd_i32EndAddr   = i32Addr + 3;
      _mmd_sType = (char *)"..PIA";

      _i32AddrDirOrDataA = _mmd_i32StartAddr;
      _i32AddrControlA   = _mmd_i32StartAddr + 1;
      _i32AddrDirOrDataB = _mmd_i32StartAddr + 2;
      _i32AddrControlB   = _mmd_i32StartAddr + 3;
      
    } // End: constructor


    // Note: NOT setting up output pins in constructor as that gets called
    // before OUTPUT pins are set back to OFF probably just before start of setup()
    // So this gets called early in setup() to work around that...
#if cDEV_M6821_OP_RELAYS
void classM6821::vSetupRelays() {
      if ( _i32AddrDirOrDataA != cDEV_M6821_OP_PIN_PIA_ADDR ) return;
      int32_t i32PinAt = cDEV_M6821_OP_PIN_START;
      for (int32_t i32Loop = 0; i32Loop < cDEV_M6821_OP_PIN_COUNT; i32Loop++) {
        pinMode(i32PinAt, OUTPUT);
        digitalWrite(i32PinAt, HIGH);
        i32aRelayBit[i32Loop] = HIGH;
        i32PinAt += cDEV_M6821_OP_PIN_INCREMENT;
      }
    _bUsingRelays = true;    
    }
#endif

      
int32_t classM6821::read( int32_t i32Addr ) {
      if ( i32Addr == _i32AddrControlA )       return( _i32DataControlA );
      if ( i32Addr == _i32AddrControlB )       return( _i32DataControlB );
 
      if ( i32Addr == _i32AddrDirOrDataA ) {
        if ( (_i32DataControlA & cDEV_M6821_DATA_DIR_ACCESS_BIT) > 0 ) {
          // Data Direction access...
          return( _i32DataDirBitsA );
        } else {
          // Peripheral reg data...
          //**** Read input pins here ****************************************
          return( _i32DataPeripheralA );
        }
      }
 
     if ( i32Addr == _i32AddrDirOrDataB ) {
        if ( (_i32DataControlB & cDEV_M6821_DATA_DIR_ACCESS_BIT) > 0 ) {
          // Data Direction access...
          return( _i32DataDirBitsB );
        } else {
          // Peripheral reg data...
          //**** Read input pins here ****************************************
          return( _i32DataPeripheralB );
        }
      }
 
      return( 0 );
      
    } // End: read(...)


void classM6821::write( int32_t i32Addr, int32_t i32Byte ) {
      if ( i32Addr == _i32AddrControlA ) _i32DataControlA = i32Byte;
      if ( i32Addr == _i32AddrControlB ) _i32DataControlB = i32Byte;

      if ( i32Addr == _i32AddrDirOrDataA ) {
        if ( (_i32DataControlA & cDEV_M6821_DATA_DIR_ACCESS_BIT) > 0 ) {
          // Peripheral reg data...
          //**** Write output pins here ****************************************
          // Using some pins to fire a bank of 8 relays...
#if cDEV_M6821_OP_RELAYS
          if ( _bUsingRelays ) { 
            int32_t i32BitMask = 0x01;
            int32_t i32BitStateNew;
            int32_t i32PinAt = cDEV_M6821_OP_PIN_START;
            for (int32_t i32Loop = 0; i32Loop < cDEV_M6821_OP_PIN_COUNT; i32Loop++) {
              i32BitStateNew = HIGH;
              if (( i32Byte & i32BitMask ) > 0 ) i32BitStateNew = LOW;
              if ( i32aRelayBit[i32Loop] != i32BitStateNew ) {
#if 0
Serial.print(" Set.");                
Serial.print(i32Loop);                
Serial.print("=");                
Serial.print(i32BitStateNew);                
Serial.println();
#endif
                i32aRelayBit[i32Loop] = i32BitStateNew;
                digitalWrite(i32PinAt, i32BitStateNew);
              }
              i32PinAt += cDEV_M6821_OP_PIN_INCREMENT;
              i32BitMask *= 2; // Shift left 1 bit
            }
          }
#endif
          _i32DataPeripheralA = i32Byte;
          return;
        } else {
          // Data Direction...
          _i32DataDirBitsA = i32Byte;
          return;
        }
      }
      
      if ( i32Addr == _i32AddrDirOrDataB ) {
        if ( (_i32DataControlB & cDEV_M6821_DATA_DIR_ACCESS_BIT) > 0 ) {
          // Peripheral reg data...
          //**** Write output pins here ****************************************
          _i32DataPeripheralB = i32Byte;
          return;
        } else {
          // Data Direction...
          _i32DataDirBitsB = i32Byte;
          return;
        }
      }
      
      return;
    } // End: write(...)
      


#endif
