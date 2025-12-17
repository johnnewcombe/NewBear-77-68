#if !defined cDEV_M6850_ACIA_DUMMY_CPP && defined cPROJ_ALLOW_CPP_COMPILE
#define cDEV_M6850_ACIA_DUMMY_CPP

/* Class to emulate ACIA for 77-68
 *  DUMMY for 2nd ACIA if only one Serial class exists 
 *  and two are wanted (eg: for DEMON monitor in 77-68)
 *  For BBC MicroBit, as 2 ACIAs using same `Serial` causes issues
 *  Chris Carter : Jan-2024
 * 
*/

    // Initialise like: classM6850 my6850( 0xF400 );
    
classM6850_dummy::classM6850_dummy( int32_t i32BaseAddr ) {
      // Give parent class our address range...
      _mmd_i32StartAddr = i32BaseAddr;
      _mmd_i32EndAddr   = i32BaseAddr + 1 ;
      _mmd_sType = (char *)"xACIA";
      // Memory addresses duplicated here for readability...
      _i32AddrData      = _mmd_i32StartAddr;
      _i32AddrCtrl      = _mmd_i32StartAddr + 1;
    }

//- - - - - 
// read( <addr> )....
int32_t classM6850_dummy::read( int32_t i32Addr ) {

      // Read CONTROL register...
      if ( i32Addr == _i32AddrCtrl) {
        // Read CTRL register...

        // Turn OFF the receive data ready bit...
        _i32DataCtrl &= cDEV_M6850_RX_BIT_OFF;

         // We are ALWAYS ready to transmit...
        _i32DataCtrl |= cDEV_M6850_TX_RDY;

        // NO incoming data...
        return( _i32DataCtrl );
     }

      // Read DATA register...
     if ( i32Addr == _i32AddrData ) {
        // Read DATA register...
        int32_t i32Byte = 0;
        i32Byte = 0; // DUMMY DATA
        return( i32Byte );
      }

    // Not this device...
    return( 0 );
    } // End: read(...)

//- - - - - 
// write( <addr>, <data> )...
void classM6850_dummy::write( int32_t i32Addr, int32_t i32Byte ) {
      
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
       // Ignored
     } // End: ( i32Addr == _i32AddrData )

    return;
    } // End: write(...)


#endif
