#if !defined cM6800_H
#define cM6800_H

/* Memory */
#define cM6800_MAX_ADDR_MASK	0xFFFF

/* Simulator stop codes */

#define cM6800_STOP_HALT	  1		// HALT-( WAI instruction )


/* function prototypes */
void m6800_reset(void);
int32_t sim_6800_go(void);
void fvPrintOperand( Stream * objStream, int32_t i32Cycles, int32_t i32PC );
void fvPrintTraceback( Stream * objStream );
void dump_state( Stream * objStream );
void dump_regs( Stream * objStream );
int32_t fi32FetchByteIncPC(void);
int32_t fi32FetchWordIncPC(void);
unsigned char pop_byte(void);
uint16_t pop_word(void);
void push_byte(unsigned char);
void push_word(uint16_t);
void go_rel(int32_t);
int32_t get_rel_addr(void);
int32_t get_dir_val(void);
int32_t get_dir_addr(void);
int32_t get_indir_val(void);
int32_t get_indir_addr(void);
int32_t get_ext_val(void);
int32_t get_flag(int32_t);
void condevalVa(int32_t, int32_t);
void condevalVs(int32_t, int32_t);
void condevalHa(int32_t op1, int32_t op2);

/* Flag values to set proper positions in CCR */
#define HF      0x20
#define IF      0x10
#define NF      0x08
#define ZF      0x04
#define VF      0x02
#define CF      0x01

/* Macros to handle the flags in the CCR */
#define CCR_ALWAYS_ON       (0xC0)        /* for 6800 */
#define CCR_MSK (HF|IF|NF|ZF|VF|CF)
#define TOGGLE_FLAG(FLAG)   (Reg_CCR ^= FLAG)
#define SET_FLAG(FLAG)      (Reg_CCR |= FLAG)
#define CLR_FLAG(FLAG)      (Reg_CCR &= ~FLAG)
#define GET_FLAG(FLAG)      (Reg_CCR & FLAG)
#define COND_SET_FLAG(COND,FLAG) \
    if (COND) SET_FLAG(FLAG);      else CLR_FLAG(FLAG)
#define COND_SET_FLAG_N(VAR) \
    if (VAR & 0x80) SET_FLAG(NF);  else CLR_FLAG(NF)
#define COND_SET_FLAG_Z(VAR) \
    if (VAR == 0) SET_FLAG(ZF);    else CLR_FLAG(ZF)
#define COND_SET_FLAG_H(VAR) \
    if (VAR & 0x10) SET_FLAG(HF);  else CLR_FLAG(HF)
#define COND_SET_FLAG_C(VAR) \
    if (VAR & 0x100) SET_FLAG(CF); else CLR_FLAG(CF)
#define COND_SET_FLAG_V(COND) \
    if (COND) SET_FLAG(VF);        else CLR_FLAG(VF)

#endif    
