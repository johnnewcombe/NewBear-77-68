#if !defined cDEV_M6850_ACIA_CPP && defined cPROJ_ALLOW_CPP_COMPILE
#define cDEV_M6850_ACIA_CPP

/* Class to emulate ACIA for 77-68
 *  Only features needed for simple use are implemented
 *  . No interrupt stuff
 *  . No RTS etc
 *  . Always ready to send
 *  
 *  Chris Carter : Oct-2020 : chris@cmas-net.co.uk
 *
 *  Example use:
 *  
 *  classM6850 my6850( 0xF400, &Serial1 );
 *  
 *  int32_t address = 0xF400;
 *  int32_t byte;
 *  if (my6850.mine( address )) byte = m6850.read( address );
 *  
 *  address = 0xF401;
 *  byte = '*';
 *  if (my6850.mine( address )) m6850.write( address, byte );
 *  
 *  ------------------------------------------------------------
 *  Newbear 77-68
 *  -------------
 *  ACIA : Information from Design Note 22, Mon-1 board:-
 *  
 *  F400 : DATA register
 *  F401 : CONTROL(wo) & STATUS(ro) registers
 *  
 *  Note: CONTROL and STATUS registers are at SAME address
 *        CONTROL = Write only, STATUS = Read only
 *  
 *  ACIA CONTROL register...
 *  
 *  [1][0] :-
 *   0  0 = Baud rate: Clock frequency
 *   0  1 = Baud rate:   "      "      / 16
 *   1  0 = Baud rate:   "      "      / 64
 *   1  1 = ACIA RESET
 *  
 *  [4][3][2] : Data bits  : parity : Stop bits
 *   0  0  0  =     7      :  Even  :    2
 *   0  0  1  =     7      :  Odd   :    2
 *   0  1  0  =     7      :  Even  :    1
 *   0  1  1  =     7      :  Odd   :    1
 *   1  0  0  =     8      :  none  :    2
 *   1  0  1  =     8      :  none  :    1
 *   1  1  0  =     8      :  Even  :    1
 *   1  1  1  =     8      :  Odd   :    1
 *  
 *  [6][5] : ^RTS :  Transmit Interrupt Enable
 *   0  0  =  Low       Disabled
 *   1  0  =  Low       Enabled
 *   0  1  =  High      Disabled
 *   1  1  =  Low       Disabled : Transmits `break`
 *  
 *  [7] : Receive Interrupt
 *   0  =   Disabled
 *   1  =   Enabled
 *  
 *  ACIA STATUS register...
 *  
 *  [0] : 1 = when Receive Data reg full (char received)
 *  [1] : 1 = when Transmit Data reg empty (ready for new char)
 *  [2] : 1 = ^DCD is high (Data Carrier Detect)
 *  [3] : 1 = ^CTS is high (Clear To Send)
 *  [4] : 1 = Framing error (eg: stop bit missing)
 *  [5] : 1 = Receiver overrun : New char received before old one read
 *  [6] : 1 = Parity error in received data
 *  [7] : 1 = ACUA ^IRQ line (Interrupt Request) output is low*  
 */


    // Initialise like: classM6850 my6850( 0xF400, &Serial1 );
    
classM6850::classM6850( int32_t i32BaseAddr, Stream * objRealDevice ) {
      // Give parent class our address range...
      _mmd_i32StartAddr = i32BaseAddr;
      _mmd_i32EndAddr   = i32BaseAddr + 1 ;
      _mmd_sType = (char *)".ACIA";
      // Memory addresses duplicated here for readability...
      _i32AddrData      = _mmd_i32StartAddr;
      _i32AddrCtrl      = _mmd_i32StartAddr + 1;
      _objRealDevice    = objRealDevice;
    }

//- - - - - 
// read( <addr> )....
 int32_t classM6850::read( int32_t i32Addr ) {
      // Read CONTROL register...
      if ( i32Addr == _i32AddrCtrl) {
        // Read CTRL register...

        // Turn OFF the receive data ready bit...
        _i32DataCtrl &= cDEV_M6850_RX_BIT_OFF;

         // We are ALWAYS ready to transmit...
        _i32DataCtrl |= cDEV_M6850_TX_RDY;
        // Do we have incoming data ?...
        if ( _objRealDevice->available() > 0 )  {
          // Yes: Check char is not the emulator cmd-mode char...
          if ( _objRealDevice->peek() != cEMULATION_INTERRUPT_CMD_CHAR ) {
            // Set receive data ready bit...
            _i32DataCtrl |= cDEV_M6850_RX_GOT;
          }
        } else {
      }
      return( _i32DataCtrl );
     }

      // Read DATA register...
     if ( i32Addr == _i32AddrData ) {
        // Read DATA register...
        int32_t i32Byte = 0;
        i32Byte = (int32_t)_objRealDevice->read();
        return( i32Byte );
      }

    // Not this device...
    return( 0 );
    } // End: read(...)



//- - - - - 
// write( <addr>, <data> )...
 void classM6850::write( int32_t i32Addr, int32_t i32Byte ) {
      
      if ( i32Addr == _i32AddrCtrl ) {
        // Write CTRL register... 
        // Reset ?...
        if ( i32Byte == cDEV_M6850_CONTROL_RESET ) {
          _i32DataCtrl = cDEV_M6850_TX_RDY;
          _b7BitData = true; // NOTE: Non-standard default to 7 bit TEMP
        }
        // 7 or 8 bit data ?...
        if (( i32Byte & cDEV_M6850_CONTROL_7BIT ) != 0 ) {
          _b7BitData = true;
        } else {
          _b7BitData = false;
        }
        return;
     }  // End: ( i32Addr == _i32AddrCtrl )

//-

     if ( i32Addr == _i32AddrData ) {
       // Write DATA...
       if ( _b7BitData ) {
         _objRealDevice->write( i32Byte & 0x7F );
       } else {
         _objRealDevice->write( i32Byte );
       }
     } // End: ( i32Addr == _i32AddrData )

    // Not this device...  
    return;
    } // End: write(...)
      

#endif
