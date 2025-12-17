#if !defined cDEV_M6821_PIA_H
#define cDEV_M6821_PIA_H

#define cDEV_M6821_DATA_DIR_ACCESS_BIT  0x04

#define  cDEV_M6821_OP_RELAYS  1

#if cDEV_M6821_OP_RELAYS
  #define cDEV_M6821_OP_PIN_PIA_ADDR   0xF300 // Address of PIA which o/ps to pins
  #define cDEV_M6821_OP_PIN_START      22
  #define cDEV_M6821_OP_PIN_INCREMENT   2
  #define cDEV_M6821_OP_PIN_COUNT       8
#endif


class classM6821 : public classMemoryMappedDevice {
    
  private:
    int32_t _i32AddrControlA   = 0;
    int32_t _i32AddrDirOrDataA = 0;
    int32_t _i32AddrControlB   = 0;
    int32_t _i32AddrDirOrDataB = 0;

    int32_t _i32DataControlA = 0;
    int32_t _i32DataControlB = 0;
    int32_t _i32DataDirBitsA = 0;
    int32_t _i32DataDirBitsB = 0;
    int32_t _i32DataPeripheralA = 0;
    int32_t _i32DataPeripheralB = 0;

#if cDEV_M6821_OP_RELAYS
    int32_t _bUsingRelays = false;
    int32_t i32aRelayBit[cDEV_M6821_OP_PIN_COUNT];
#endif
    
 
  public:
    classM6821( int32_t i32Addr );
#if cDEV_M6821_OP_RELAYS
    void vSetupRelays();
#endif
    int32_t read( int32_t i32Addr );
    void write( int32_t i32Addr, int32_t i32Byte );
};


#endif
