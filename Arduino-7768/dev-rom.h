#if !defined cDEV_ROM_H
#define cDEV_R0M_H

class classROM : public classMemoryMappedDevice {
  
  private:
    // Private names are given a `_` prefix

   uint8_t * _u8Rom = NULL;
  
  public:
    classROM( int32_t i32BaseAddr, int32_t i32EndAddr, const uint8_t * u8RomData );
    int32_t read( int32_t i32Addr );
    // Attempt to .write( addr, byte ) falls through to base class, and is ignored.
};


#endif
