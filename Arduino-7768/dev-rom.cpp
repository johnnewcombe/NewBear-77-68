#if !defined cDEV_ROM_CPP && defined cPROJ_ALLOW_CPP_COMPILE
#define cDEV_ROM_CPP


    // Constructor...
classROM::classROM( int32_t i32BaseAddr, int32_t i32EndAddr, const uint8_t * u8RomData ) {
      // Point to ROM data...
      if ( u8RomData == NULL ) return;
      _u8Rom = (uint8_t *)u8RomData;
      // Give parent class our address range...
      _mmd_i32StartAddr = i32BaseAddr;
      _mmd_i32EndAddr   = i32EndAddr;
      _mmd_sType = (char *)"..ROM";
    }
      
int32_t classROM::read( int32_t i32Addr ) {
      int32_t i32Byte;
      if ( !mine( i32Addr ) ) return( 0 );
      i32Byte = (int32_t)_u8Rom[ i32Addr - _mmd_i32StartAddr ] & 0xFF;
      return( i32Byte );
    } // End: read(...)

#endif
