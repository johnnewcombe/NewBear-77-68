#if !defined cDEV_M6850_ACIA_H
#define cDEV_M6850_ACIA_H

#include "7768.h"
#include "dev-m6850-acia_common.h"

class classM6850 : public classMemoryMappedDevice {
  
  private:
    // Private names are given a `_` prefix

    int32_t _i32AddrCtrl = 0;
    int32_t _i32AddrData = 0;
    int32_t _i32DataCtrl = cDEV_M6850_TX_RDY;
    int32_t _b7BitData   = false;
    Stream * _objRealDevice = NULL;
  
  public:

    classM6850( int32_t i32BaseAddr, Stream * objRealDevice );
    int32_t read( int32_t i32Addr );
    void write( int32_t i32Addr, int32_t i32Byte );
};


#endif
