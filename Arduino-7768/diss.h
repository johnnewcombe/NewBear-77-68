#if !defined cDISS_H
#define cDISS_H

// Usage flags...

#define cUSE_FLAG_NONE   0x00  // Not referenced (yet)
#define cUSE_FLAG_LABEL  0x01  // Seen referenced by Bxx or JMP, JSR
#define cUSE_FLAG_SUBR   0x02  // LABEL seen used by JSR or BSR
#define cUSE_FLAG_CODE   0x04  // Seen read as opcode
#define cUSE_FLAG_ARG    0x08  // Seen read as opcode arguments
#define cUSE_FLAG_DATA   0x10  // Seen referenced as data by code
#define cUSE_FLAG_STACK  0x20  // Seen pointed to by S.reg

// OPCODES : See: https://en.wikipedia.org/wiki/Halt_and_Catch_Fire_(computing)
//           for HCF explanantions
//
#define cOPCODE_ARG_REL   0x01
#define cOPCODE_ARG_IND   0x02
#define cOPCODE_ARG_EXT   0x04
#define cOPCODE_ARG_IMM   0x08
#define cOPCODE_ARG_DIR   0x10 
#define cOPCODE_ARG_JUMP  0x20   // JMP or JSR ( 2-byte code address )
#define cOPCODE_ARG_JBSR  0x40   // JSR or BSR ( target is subroutine label )
#define cOPCODE_ARG_DATA  0x80   // Argument POINTS TO data (usually)

 int fiOpCodeArgCount( int32_t i32OpCode );
 int fbOpCodeTestFlag( int32_t i32OpCode, int iFlagBits );
char *fiOpCodeName( int32_t i32OpCode );
void fvUsageSet(int32_t i32Addr, int iFlag);
void fvUsageSetAsStack(int32_t i32SP, int iBytes);
 int fbUsageTest(int32_t i32Addr, int iFlag);
 int fbUsageFlags(int32_t i32Addr);
void fvUsageInit();
void fvUsageForOpCode( int32_t i32PC, int32_t i32IX, int32_t int32SP );

void fvUsageDissassembly( Stream * objStream, int32_t i32Start, int32_t i32End );

#endif  // End: diss.h
