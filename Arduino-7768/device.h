#if !defined cDEVICE_H
#define cDEVICE_H

class classMemoryMappedDevice {

  protected:
    int32_t  _mmd_i32StartAddr = 0;
    int32_t  _mmd_i32EndAddr   = 0;
    char *   _mmd_sType = (char *)"?";
  
   public:
    int mine( int32_t i32Addr );
    void ShowInformation( Stream * objStream );

    // READ - MUST be defined in sub-class...
    // Pure Virtual function...
    virtual int32_t read( int32_t i32Addr ) = 0;

    // WRITE - Usually overriden in sub-class, if not then this is used...
    // Virtual function...
    virtual void write( int32_t i32Addr, int32_t i32Byte ) {
      return;
    }
};

#endif
