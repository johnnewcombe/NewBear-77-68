#if !defined cDEV_RAM_H
#define cDEV_RAM_H

class classRAM : public classMemoryMappedDevice {
  
  private:
    // Private names are given a `_` prefix

   uint8_t * _u8Ram = NULL;
  
  public:

    classRAM( int32_t i32BaseAddr, int32_t i32EndAddr );
    ~classRAM();
    int32_t read( int32_t i32Addr );
    void write( int32_t i32Addr, int32_t i32Byte );

};


#endif
