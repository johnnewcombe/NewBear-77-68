#if !defined cDEV_RAM_CPP && defined cPROJ_ALLOW_CPP_COMPILE
#define cDEV_RAM_CPP

    // Constructor...
classRAM::classRAM( int32_t i32BaseAddr, int32_t i32EndAddr ) {
      // Allocate our memory.  
      // calloc() is like malloc(), but sets all data to zero...
      _u8Ram = (uint8_t *)calloc( 1, (i32EndAddr - i32BaseAddr) + 1 );
      if ( _u8Ram == NULL ) {
        Serial.println();
        Serial.print("M6800: NOT ENOUGH RAM ! ");
        Serial.print(i32BaseAddr,HEX);
        Serial.print(" to ");
        Serial.println(i32EndAddr,HEX);
        Serial.println("M6800: Press Reset to reboot!");
        while(1) { delay(100); } // STOP
        return;
      }
      // Give parent class our address range...
      _mmd_i32StartAddr = i32BaseAddr;
      _mmd_i32EndAddr   = i32EndAddr;
      _mmd_sType = (char *)"..RAM";
    }

    // Destructor...
    
classRAM::~classRAM() {
      // Free the RAM...
      if (_u8Ram != NULL ) free( _u8Ram );
    }

      
int32_t classRAM::read( int32_t i32Addr ) {
      if ( !mine( i32Addr ) ) return( 0 );
      return( (int32_t)_u8Ram[ i32Addr - _mmd_i32StartAddr ] & 0xFF );
    } // End: read(...)


void classRAM::write( int32_t i32Addr, int32_t i32Byte ) {
      if ( !mine( i32Addr ) ) return;
      _u8Ram[ i32Addr - _mmd_i32StartAddr ] = (uint8_t)(i32Byte & 0xFF);
      return;
    } // End: write(...)
      

#endif
