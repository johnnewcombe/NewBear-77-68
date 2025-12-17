#if !defined cDEV_M6850_ACIA_DUMMY_H
#define cDEV_M6850_ACIA_DUMMY_H

#include "dev-m6850-acia_common.h"


class classM6850_dummy : public classMemoryMappedDevice {
  
  private:
    // Private names are given a `_` prefix

    int32_t _i32AddrCtrl = 0;
    int32_t _i32AddrData = 0;
    int32_t _i32DataCtrl = cDEV_M6850_TX_RDY;
    int32_t _b7BitData   = false;
  
  public:

    classM6850_dummy( int32_t i32BaseAddr );
    int32_t read( int32_t i32Addr );
    void write( int32_t i32Addr, int32_t i32Byte );
};

#endif
