#if !defined cDEV_M6850_ACIA_COMMON_H
#define cDEV_M6850_ACIA_COMMON_H

#include "7768.h"


// Status (ctrl read)...
#define cDEV_M6850_RX_GOT  0x01
#define cDEV_M6850_TX_RDY  0x02
#define cDEV_M6850_DCD     0x04
#define cDEV_M6850_CTS     0x08

// Control (ctrl write)...
#define cDEV_M6850_CONTROL_RESET     0x03
#define cDEV_M6850_CONTROL_STOP_BITS 0x04 // 1=1 stop bit, 0=2 stop bits
#define cDEV_M6850_CONTROL_PARITY    0x02 // 0=Even,  1=Odd
#define cDEV_M6850_CONTROL_7BIT      0x10 // 0=7 bit, 1=8 bit

#define cDEV_M6850_RX_BIT_OFF 0xFE   // `AND` mask to turn off RX bit

#endif
