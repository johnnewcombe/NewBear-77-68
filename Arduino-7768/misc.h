#if !defined cMISC_H
#define cMISC_H

#define cCR     13
#define cTAB     9
#define cENDSTR  0
#define cBS      8
#define cSWRUN 254

void fvOutputHex2( Stream * objStream, int32_t i32Value );
void fvOutputHex4( Stream * objStream, int32_t i32Value );

int32_t fi32HexCharToInt( char chrDigit );

int32_t fi32ReadHex2(Stream * objRealDevice);
int32_t fi32ReadHex4(Stream * objRealDevice);

char fcInputChar(Stream * objRealDevice);

#endif
