#if !defined cDISS_C && defined cPROJ_ALLOW_CPP_COMPILE
#define cDISS_C

/*  
 *  CDC-Aug-2023: Semi intelligent dissassembler, keeping data on how
 *                various bytes of memory are used and then using that to aid
 *                dissassembly.
 */

#include "diss.h"

//- - - - - - - - - 

const struct {
  char *sName;
  int8_t i8Cycles;
  int8_t i8ArgCount;
  int16_t i16Flags;
} stOpCode[256] = {
 {   "?",  0, 0, 0 }, // 0x00
 { "NOP",  2, 0, 0 }, // 0x01 : The normal NOP instruction in NOP page in Prog.Ref
 { "Nop",  2, 0, 0 }, // 0x02 : NOP in M6800 Prog.Ref.1975 in chart near front. Corrected by 1976.
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 { "TAP",  2, 0, 0 },
 { "TPA",  2, 0, 0 },
 { "INX",  4, 0, 0 },
 { "DEX",  4, 0, 0 },
 { "CLV",  2, 0, 0 },
 { "SEV",  2, 0, 0 },
 { "CLC",  2, 0, 0 },
 { "SEC",  2, 0, 0 },
 { "CLI",  2, 0, 0 },
 { "SEI",  2, 0, 0 },
 { "SBA",  2, 0, 0 }, // 0x10
 { "CBA",  2, 0, 0 },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 { "TAB",  2, 0, 0 },
 { "TBA",  2, 0, 0 },
 {   "?",  0, 0, 0 },
 { "DAA",  2, 0, 0 },
 {   "?",  0, 0, 0 },
 { "ABA",  2, 0, 0 },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 { "BRA",  4, 1, cOPCODE_ARG_REL }, // 0x20
 {   "?",  0, 0, 0 },
 { "BHI",  4, 1, cOPCODE_ARG_REL },
 { "BLS",  4, 1, cOPCODE_ARG_REL },
 { "BCC",  4, 1, cOPCODE_ARG_REL },
 { "BCS",  4, 1, cOPCODE_ARG_REL },
 { "BNE",  4, 1, cOPCODE_ARG_REL },
 { "BEQ",  4, 1, cOPCODE_ARG_REL },
 { "BVC",  4, 1, cOPCODE_ARG_REL },
 { "BVS",  4, 1, cOPCODE_ARG_REL },
 { "BPL",  4, 1, cOPCODE_ARG_REL },
 { "BMI",  4, 1, cOPCODE_ARG_REL },
 { "BGE",  4, 1, cOPCODE_ARG_REL },
 { "BLT",  4, 1, cOPCODE_ARG_REL },
 { "BGT",  4, 1, cOPCODE_ARG_REL },
 { "BLE",  4, 1, 0 },
 { "TSX",  4, 0, 0 }, // 0x30
 { "INS",  4, 0, 0 },
 { "PULA", 4, 0, 0 },
 { "PULB", 4, 0, 0 },
 { "DES",  4, 0, 0 },
 { "TXS",  4, 0, 0 },
 { "PSHA", 4, 0, 0 },
 { "PSHB", 4, 0, 0 },
 {   "?",  0, 0, 0 },
 { "RTS",  5, 0, 0 },
 {   "?",  0, 0, 0 },
 { "RTI", 10, 0, 0 },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 { "WAI",  9, 0, 0 },
 { "SWI", 12, 0, 0 },
 { "NEGA", 2, 0, 0 }, // 0x40
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 { "COMA", 2, 0, 0 },
 { "LSRA", 2, 0, 0 },
 {   "?",  0, 0, 0 },
 { "RORA", 2, 0, 0 },
 { "ASRA", 2, 0, 0 },
 { "ASLA", 2, 0, 0 },
 { "ROLA", 2, 0, 0 },
 { "DECA", 2, 0, 0 },
 {   "?",  0, 0, 0 },
 { "INCA", 2, 0, 0 },
 { "TSTA", 2, 0, 0 },
 {   "?",  0, 0, 0 },
 { "CLRA", 2, 0, 0 },
 { "NEGB", 2, 0, 0 }, // 0x50
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 { "COMB", 2, 0, 0 },
 { "LSRB", 2, 0, 0 },
 {   "?",  0, 0, 0 },
 { "RORB", 2, 0, 0 },
 { "ASRB", 2, 0, 0 },
 { "ASLB", 2, 0, 0 },
 { "ROLB", 2, 0, 0 },
 { "DECB", 2, 0, 0 },
 {   "?",  0, 0, 0 },
 { "INCB", 2, 0, 0 },
 { "TSTB", 2, 0, 0 },
 {   "?",  0, 0, 0 },
 { "CLRB", 2, 0, 0 },
 { "NEG",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA }, // 0x60
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 { "COM",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "LSR",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 { "ROR",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "ASR",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "ASL",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "ROL",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "DEC",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 { "INC",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "TST",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "JMP",  4, 1, cOPCODE_ARG_IND | cOPCODE_ARG_JUMP },
 { "CLR",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "NEG",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA }, // 0x70
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },
 { "COM",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "LSR",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 { "ROR",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "ASR",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "ASL",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "ROL",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "DEC",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 { "INC",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "TST",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "JMP",  3, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_JUMP },
 { "CLR",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "SUBA", 2, 1, cOPCODE_ARG_IMM }, // 0x80
 { "CMPA", 2, 1, cOPCODE_ARG_IMM },
 { "SBCA", 2, 1, cOPCODE_ARG_IMM },
 {   "?",  0, 0, 0 },
 { "ANDA", 2, 1, cOPCODE_ARG_IMM },
 { "BITA", 2, 1, cOPCODE_ARG_IMM },
 { "LDAA", 2, 1, cOPCODE_ARG_IMM },
 {   "?",  0, 0, 0 },
 { "EORA", 2, 1, cOPCODE_ARG_IMM },
 { "ADCA", 2, 1, cOPCODE_ARG_IMM },
 { "ORAA", 2, 1, cOPCODE_ARG_IMM },
 { "ADDA", 2, 1, cOPCODE_ARG_IMM },
 { "CPX",  3, 2, cOPCODE_ARG_IMM },
 { "BSR",  8, 1, cOPCODE_ARG_REL | cOPCODE_ARG_JBSR },
 { "LDS",  3, 2, cOPCODE_ARG_IMM },
 {   "?",  0, 0, 0 },
 { "SUBA", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA }, // 0x90
 { "CMPA", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "SBCA", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 { "ANDA", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "BITA", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "LDAA", 3, 1, cOPCODE_ARG_DIR },  // ** Note: LDA and STA are not marked as having DATA as target
 { "STAA", 3, 1, cOPCODE_ARG_DIR },  // **      as they move CODE sometimes (eg: Load, Blockmove)
 { "EORA", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "ADCA", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "ORAA", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "ADDA", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "CPX",  3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },  // 0x9D : HCF : Fast address line increments
 { "LDS",  4, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "STS",  5, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "SUBA", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA }, // 0xA0
 { "CMPA", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "SBCA", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 { "ANDA", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "BITA", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "LDAA", 5, 1, cOPCODE_ARG_IND }, // **
 { "STAA", 5, 1, cOPCODE_ARG_IND }, // **
 { "EORA", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "ADCA", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "ORAA", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "ADDA", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "CPX",  6, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "JSR",  8, 1, cOPCODE_ARG_IND | cOPCODE_ARG_JUMP | cOPCODE_ARG_JBSR },
 { "LDS",  6, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "STS",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "SUBA", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA }, // 0xB0
 { "CMPA", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "SBCA", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 { "ANDA", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "BITA", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "LDAA", 4, 2, cOPCODE_ARG_EXT }, // **
 { "STAA", 4, 2, cOPCODE_ARG_EXT }, // **
 { "EORA", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "ADCA", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "ORAA", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "ADDA", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "CPX",  5, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "JSR",  9, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_JUMP | cOPCODE_ARG_JBSR },
 { "LDS",  5, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "STS",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "SUBB", 2, 1, cOPCODE_ARG_IMM }, // 0xC0
 { "CMPB", 2, 1, cOPCODE_ARG_IMM },
 { "SBCB", 2, 1, cOPCODE_ARG_IMM },
 {   "?",  0, 0, 0 },
 { "ANDB", 2, 1, cOPCODE_ARG_IMM },
 { "BITB", 2, 1, cOPCODE_ARG_IMM },
 { "LDAB", 2, 1, cOPCODE_ARG_IMM },
 {   "?",  0, 0, 0 },
 { "EORB", 2, 1, cOPCODE_ARG_IMM },
 { "ADCB", 2, 1, cOPCODE_ARG_IMM },
 { "ORAB", 2, 1, cOPCODE_ARG_IMM },
 { "ADDB", 2, 1, cOPCODE_ARG_IMM },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },  // 0xCD : HCF like, but human readable speed of address line increments
 { "LDX",  3, 2, cOPCODE_ARG_IMM },
 {   "?",  0, 0, 0 },
 { "SUBB", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA }, // 0xD0
 { "CMPB", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "SBCB", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 { "ANDB", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "BITB", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "LDAB", 3, 1, cOPCODE_ARG_DIR },
 { "STAB", 3, 1, cOPCODE_ARG_DIR },
 { "EORB", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "ADCB", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "ORAB", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "ADDB", 3, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },  // 0xDD : HCF : Fast address line increments
 { "LDX",  4, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "STX",  5, 1, cOPCODE_ARG_DIR | cOPCODE_ARG_DATA },
 { "SUBB", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA }, // 0xE0
 { "CMPB", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "SBCB", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 { "ANDB", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "BITB", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "LDAB", 5, 1, cOPCODE_ARG_IND }, // **
 { "STAB", 5, 1, cOPCODE_ARG_IND }, // **
 { "EORB", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "ADCB", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "ORAB", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "ADDB", 5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },  // 0xED : HCF like, but human readable speed of address line increments
 { "LDX",  5, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "STX",  7, 1, cOPCODE_ARG_IND | cOPCODE_ARG_DATA },
 { "SUBB", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA }, // 0xF0
 { "CMPB", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "SBCB", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 { "ANDB", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "BITB", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "LDAB", 4, 2, cOPCODE_ARG_EXT }, // **
 { "STAB", 4, 2, cOPCODE_ARG_EXT }, // **
 { "EORB", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "ADCB", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "ORAB", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "ADDB", 4, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 {   "?",  0, 0, 0 },
 {   "?",  0, 0, 0 },  // 0xFD : Like HCF, but 1/2 speed (HCFs cycle address lines)
 { "LDX",  5, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA },
 { "STX",  6, 2, cOPCODE_ARG_EXT | cOPCODE_ARG_DATA }
};

int fiOpCodeArgCount( int32_t i32OpCode ) {
  return( (int)stOpCode[i32OpCode].i8ArgCount );
}

int fbOpCodeTestFlag( int32_t i32OpCode, int iFlagBits ) {
  if (( (int)stOpCode[i32OpCode].i16Flags & iFlagBits ) == iFlagBits ) return(true);
  return( false );
}

char *fiOpCodeName( int32_t i32OpCode ) {
  return( stOpCode[i32OpCode].sName );
}

// USAGE stuff...

struct {
  uint8_t *u8Flags;  // 1 byte per addressable memory byte
  int32_t i32Size;   // Set when memory assigned
  int32_t i32Start;  // Memory Address of first flag byte
  int32_t i32End;    // Memory Address of last flag byte
} stUsage = {NULL,0,0,0};
// u8Flags will get memory assigned when code started.
// Each byte will get marked during emulation
// to show how it is used. This data can then
// be used to help dissassembly

void fvUsageSet(int32_t i32Addr, int iFlag) {
  if (stUsage.i32Size <= 0) return;
  if (i32Addr < stUsage.i32Start) return;
  if (i32Addr > stUsage.i32End)   return;
  stUsage.u8Flags[i32Addr-stUsage.i32Start] |= (uint8_t)iFlag;
  return;
}

void fvUsageSetAsStack(int32_t i32SP, int iBytes) {
  int32_t i32Addr;
  if (stUsage.i32Size <= 0) return;
  if (iBytes == 0) return;
  if (iBytes < 0) {
    i32Addr = i32SP + 1;   
  } else {
    i32Addr = i32SP - (iBytes - 1);   
  }
  for (int iAt=0; iAt < abs(iBytes); iAt++) {
    fvUsageSet(i32Addr++, cUSE_FLAG_STACK);
  }
}

int fbUsageTest(int32_t i32Addr, int iFlag) {
  if (stUsage.i32Size <= 0) return(false);
  if (i32Addr < stUsage.i32Start) return(false);
  if (i32Addr > stUsage.i32End)   return(false);
  if (((int)stUsage.u8Flags[i32Addr-stUsage.i32Start] & iFlag) == iFlag) return(true);
  return(false);
}

int fbUsageFlags(int32_t i32Addr) {
  if (stUsage.i32Size <= 0) return(false);
  if (i32Addr < stUsage.i32Start) return(false);
  if (i32Addr > stUsage.i32End)   return(false);
  return((int)stUsage.u8Flags[i32Addr-stUsage.i32Start]);
}


void fvUsageInit(int32_t i32Start, int32_t i32End) {
  // Allocate memory for dissassembly flags...
  if (stUsage.i32Size > 0) {
    free(stUsage.u8Flags);
    stUsage.i32Size = 0;
  }
  stUsage.i32Size = (i32End - i32Start) + 1;
  stUsage.u8Flags = (uint8_t *)malloc(stUsage.i32Size);
  if (stUsage.u8Flags == NULL) {
    if (stUsage.i32Start != -1) {
      Serial.println("** Memory allocation for flags failed ! **");
     }
    stUsage.i32Size = 0;
    stUsage.i32Start = 0;
    stUsage.i32End = 0;
  } else {
    memset(stUsage.u8Flags, cUSE_FLAG_NONE, stUsage.i32Size);
    stUsage.i32Start = i32Start;  
    stUsage.i32End = i32End;
    Serial.print("** ");
    Serial.print(stUsage.i32Size);
    Serial.print(" bytes for flags mapped from ");
    Serial.print(stUsage.i32Start,HEX);
    Serial.print(" to ");
    Serial.println(stUsage.i32End,HEX);
  }
  return;
}  


//- - - - - - - - - 
// i32PC = PC address holding this opcode
void fvUsageForOpCode( int32_t i32PC, int32_t i32IX, int32_t i32SP ) {
  int32_t i32OpCode;
  int32_t i32Addr;
  int32_t i32ArgByte;
  int32_t i32ArgWord;
  int32_t i32ArgCount;
  int iLabelFlag = 0;
  int bDone = false;

  if (i32PC < stUsage.i32Start) return;
  if (i32PC > stUsage.i32End)   return;

  // OPERATION (OPCODE) field...
  i32OpCode = fi32GetMemoryByte( i32PC );
  // Set OpCode flag...
  fvUsageSet(i32PC, cUSE_FLAG_CODE);

  // Get OPERAND (argument)...
  i32ArgWord = 0;
  i32ArgCount = fiOpCodeArgCount( i32OpCode );
  for (int iAt=1; iAt <= i32ArgCount; iAt++) {
    i32Addr = i32PC + iAt;
    i32ArgByte = fi32GetMemoryByte( i32Addr );
    i32ArgWord = ( i32ArgWord << 8) | i32ArgByte;
    // Set Operand (arguments) flag...
    fvUsageSet(i32Addr, cUSE_FLAG_ARG);
  }

  // Prepare label type marker...
  iLabelFlag = cUSE_FLAG_LABEL;
  // For JSR or BSR, set label as `subroutine`...
  // This will get S_ prefix instead of L_ in code list
  if (fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_JBSR )) {
    iLabelFlag = cUSE_FLAG_SUBR;
  }
  
  // Check for Bxx (Branch) instruction...
  if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_REL)) {
    // It IS Bxx, so work out branch address...
    // Is it +ve or -ve ?...
    if ( ( i32ArgByte & 0x80 ) == 0x80 ) {
      i32ArgByte |= 0xFFFFFF00;  // Extend sign bit
    }
    i32Addr = (i32PC + 2) + i32ArgByte;
    // Set LABEL flag...
    fvUsageSet(i32Addr, iLabelFlag);
    bDone=true;
  }

  if (!bDone) {
    // Check for JMP or JSR (jump) instructions...
    // and set target address as a label...
    if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_JUMP) 
     ||  fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_JBSR) ) {
      if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_IND)) {
        // IND... n,X ...
        i32Addr = i32ArgByte + i32IX;
      } else {
        // EXT... nn ...
        i32Addr = i32ArgWord;
      }
      fvUsageSet(i32Addr, iLabelFlag);
    }

    // Check for code referencing DATA...
    // and set target address as likely to be data...
    // Note: LDA and STA are NOT marked as they are 
    //       often used to move code
    if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_DATA)) {
      fvUsageSet(i32Addr, cUSE_FLAG_DATA);
    }

    // Address referenced needs a label...
    if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_IND)) {
      // IND... n,X ...
      i32Addr = i32ArgByte + i32IX;
      // for DATA...
      if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_DATA)) {
        // SUPPRESS for n,X where n not zero...
        // so we get label only on base byte of item...
        if ( i32ArgByte == 0 ) {
          fvUsageSet(i32Addr, iLabelFlag);
        }
      }  
    } else {
      // DIR or EXT... n or nn ...
      i32Addr = i32ArgWord;
      fvUsageSet(i32Addr, iLabelFlag);
    }
    
  } // End: !bDone

  // Instructions using STACK to point to RAM...
  switch(i32OpCode) {
    case 0x31: // INS
    case 0x36: // PSH
    case 0x37: // PSH
      fvUsageSetAsStack(i32SP,1);
    break;
    case 0x34: // DES
    case 0x32: // PUL
    case 0x33: // PUL
      fvUsageSetAsStack(i32SP,-1);
    break;
    case 0x39: // RTS
      fvUsageSetAsStack(i32SP,-2);
    break;
    case 0x3E: // WAI 
    case 0x3B: // RTI
      fvUsageSetAsStack(i32SP,-7);
    break;
    case 0x3F: // SWI 
      fvUsageSetAsStack(i32SP,7);
    break;
    case 0xBD: // JSR
    case 0xAD: // JSR
      fvUsageSetAsStack(i32SP,2);
    break;
  }

}

//------------------------

void fvUsageDissassembly( Stream * objStream, int32_t i32Start, int32_t i32End ) {
  int32_t i32At = i32Start;
  int32_t i32OpCode;
  int32_t i32ArgCount;
  int32_t i32ArgByte;
  int32_t i32ArgWord;
  int32_t i32Addr;
  int32_t i32Data;
  int32_t i32LineStartAt;

  if (stUsage.i32Size <= 0) return;
  if (i32At < stUsage.i32Start) return;

  objStream->println();

  // Loop through bytes
  while( i32At <= stUsage.i32End ) {
    i32LineStartAt = i32At;
    i32ArgWord = 0;
    
    if (fbUsageTest(i32At, cUSE_FLAG_CODE)) {
      // This is an INSTRUCTION line...
      
      // LABEL field...
      if ( fbUsageTest(i32At,cUSE_FLAG_LABEL) 
       ||  fbUsageTest(i32At,cUSE_FLAG_SUBR)) {
        if ( fbUsageTest(i32At,cUSE_FLAG_SUBR) ) {
          objStream->print("S_");  // Subroutine
        } else {
          objStream->print("L_");  // Ordinary label
        }
        fvOutputHex4( objStream, i32LineStartAt );
        objStream->print(" ");
      } else {
       objStream->print("       ");
      }

      // OPERATION field...
      i32OpCode = fi32GetMemoryByte( i32At++ );
      // Opcode name...
      objStream->print( fiOpCodeName(i32OpCode) );
      if (strlen(fiOpCodeName(i32OpCode)) < 4) objStream->print(" ");
      objStream->print(" ");

      // OPERAND (argument) field...
      // Get operand (argument bytes)...
      i32ArgByte = 0;  // One byte argument value
      i32ArgWord = 0;  // One or two byte argument value
      i32ArgCount = fiOpCodeArgCount( i32OpCode );
      if (i32ArgCount > 0) { 
        for (int iLoop=0; iLoop < i32ArgCount; iLoop++) {
          i32ArgByte = fi32GetMemoryByte( i32At++ );
          i32ArgWord = ( i32ArgWord << 8) | i32ArgByte;
        }
      }
      
      // Check for Bxx (Branch) instruction (REL addressing)...
      if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_REL ) ) {
        // It IS Bxx, so work out branch address...
        // Is it +ve or -ve ?...
        if ( ( i32ArgByte & 0x80 ) == 0x80 ) {
          i32ArgByte |= 0xFFFFFF00;  // Extend sign bit
        }
        i32Addr = (i32LineStartAt + 2) + i32ArgByte;
        if ( fbUsageTest(i32Addr,cUSE_FLAG_SUBR) ) {
          objStream->print("S_");
        } else {
          objStream->print("L_");
        }
        fvOutputHex4( objStream, i32Addr );
        // Comment...
        objStream->print("  ; ($");
        fvOutputHex2( objStream, i32ArgByte );
        objStream->print(")");
        objStream->println();
        continue; // DONE... On to next byte...
      } // End: Bxx : REL address

      // Check for JSR...
      if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_JBSR ) ) {
        if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_EXT ) ) {
          // EXT : nn...
          objStream->print("S_");
          fvOutputHex4( objStream, i32ArgWord );
        }
        objStream->println();
        continue; // DONE... On to next byte...
      }

      if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_IND ) ) {
        // IND : n,X...
        objStream->print("$");
        fvOutputHex2( objStream, i32ArgByte );
        objStream->print(",X");
      }
      
      if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_EXT ) 
       ||  fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_DIR ) ) {
        // DIR or EXT : nn...
        if ( fbUsageTest(i32ArgWord,cUSE_FLAG_SUBR) ) {
          objStream->print("S_");
        } else {
          objStream->print("L_");
        }
        fvOutputHex4( objStream, i32ArgWord );
      }
      
      if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_IMM ) ) {
        // IMM : n...
        // IMM : nn...
        objStream->print("#$");
        if (i32ArgCount==1) fvOutputHex2( objStream, i32ArgByte );
        if (i32ArgCount==2) fvOutputHex4( objStream, i32ArgWord );

        if ((i32ArgCount == 1) 
         && (i32ArgByte > ' ') 
         && (i32ArgByte < 0x7F)) {
          objStream->print("    ; #'");
          objStream->print((char)i32ArgByte);
        }
      }
      
    } // End: CODE
    else
    { // DATA ?
    
      // LABEL field...
      if ( fbUsageTest(i32LineStartAt,cUSE_FLAG_LABEL) 
       ||  fbUsageTest(i32LineStartAt,cUSE_FLAG_SUBR) ) {
        
        if ( fbUsageTest(i32LineStartAt,cUSE_FLAG_SUBR) ) {
          objStream->print("S_");  // Subroutine !!!
        } else {
          objStream->print("L_");  // Ordinary label
        }
        
        fvOutputHex4( objStream, i32LineStartAt );
        objStream->print(" ");
      } else {
        objStream->print("       ");
      }

      // FCB...
      i32Data = fi32GetMemoryByte( i32At++ );
      objStream->print("FCB $");
      fvOutputHex2( objStream, i32Data );

      if ((i32Data > ' ') && (i32Data < 0x7F)) {
        objStream->print(" ;#'");
        objStream->print((char)i32Data);
      }
    }

    objStream->print("  ;F:");
    fvOutputHex2( objStream, fbUsageFlags(i32LineStartAt) );
    if (fbUsageTest(i32LineStartAt,cUSE_FLAG_DATA))  objStream->print(";D");
    if (fbUsageTest(i32LineStartAt,cUSE_FLAG_LABEL)) objStream->print(";L");
    if (fbUsageTest(i32LineStartAt,cUSE_FLAG_SUBR))  objStream->print(";S");
    if (fbUsageTest(i32LineStartAt,cUSE_FLAG_STACK)) objStream->print(";Stk");
    if (fbUsageTest(i32LineStartAt,cUSE_FLAG_CODE))  objStream->print(";C");
    if (fbUsageTest(i32LineStartAt,cUSE_FLAG_ARG))   objStream->print(";A");
    objStream->print(" ; PC:");
    fvOutputHex4( objStream, i32LineStartAt );
    objStream->print("  ;AF:");
    fvOutputHex4( objStream, i32ArgWord );
    objStream->print("=");
    fvOutputHex2( objStream, fbUsageFlags(i32ArgWord) );
    if (fbUsageTest(i32ArgWord,cUSE_FLAG_DATA))  objStream->print(";D");
    if (fbUsageTest(i32ArgWord,cUSE_FLAG_LABEL)) objStream->print(";L");
    if (fbUsageTest(i32ArgWord,cUSE_FLAG_SUBR))  objStream->print(";S");
    if (fbUsageTest(i32ArgWord,cUSE_FLAG_STACK)) objStream->print(";Stk");
    if (fbUsageTest(i32ArgWord,cUSE_FLAG_CODE))  objStream->print(";C");
    if (fbUsageTest(i32ArgWord,cUSE_FLAG_ARG))   objStream->print(";A");
    objStream->println();
  } // End: while()
}  
     
#endif  // End: diss.c
