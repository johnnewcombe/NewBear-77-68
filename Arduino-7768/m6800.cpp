 #if !defined cM6800_C && defined cPROJ_ALLOW_CPP_COMPILE
#define cM6800_C

/* Modified by CDC...
 *  
 *  CDC-Oct-2023: More console work - Including ROM/RAM control
 *                Applied some fixes to SIMH code by Roberto Sancho Villa (RSV) in 2022
 *                Note: Not sure I agree with some, so mods left out for now...
 *                0x82, 0x89, 0x92, 0x99, 0xA2, 0xA9, 0xB2, 0xB9, 
 *                0xC2, 0xC9, 0xD2, 0xD9, 0xE2, 0xE9, 0xF2, 0xF9
 *  
 *  CDC-Aug-2023: Ctrl+] (EMU console) work...
 *                Semi intelligent dissassembler work, keeping data on how
 *                various bytes of memory are used and then using that to aid
 *                dissassembly.
 *                
 *                Treat Hex.02 opcode as same as NUL (opcode 0x01)
 *                
 *  CDC-Nov-2020: Applied fixes from later simh to main opcode processing loop...
 *   SIMH note:- 21 Apr 20 -- Richard Brinegar numerous fixes for flag errors
 *  
 *  CDC-Nov-2020: Added code to issue messages and restart if an illegal opcode is met
 *  for Newbear 77-68
 */
 
/* m6800.c: SWTP 6800 CPU simulator

   Copyright (c) 2005-2011, William Beech

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the "Software"),
   to deal in the Software without restriction, including without limitation
   the rights to use, copy, modify, merge, publish, distribute, sublicense,
   and/or sell copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR Reg_A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
   WILLIAM A. BEECH BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
   IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

   Except as contained in this notice, the name of William A. Beech shall not
   be used in advertising or otherwise to promote the sale, use or other dealings
   in this Software without prior written authorization from William A. Beech.

   cpu                  Motorola M6800 CPU

   The register state for the M6800 CPU is:

   A<0:7>               Accumulator A
   B<0:7>               Accumulator B
   IX<0:15>             Index Register
   CCR<0:7>             Condition Code Register
       HF                   half-carry flag
       IF                   interrupt flag
       NF                   negative flag
       ZF                   zero flag
       VF                   overflow flag
       CF                   carry flag
   PC<0:15>                 program counter
   Reg_SP <0:15>            Stack Pointer

   The M6800 is an 8-bit CPU, which uses 16-bit registers to address
   up to 64KB of memory.

   The 72 basic instructions come in as 1, 2, or 3-bytes.

   This routine is the instruction decode routine for the M6800.

   General notes: ... These notes are pre CDC mods - things have changed a bit (!)

   1. Reasons to stop.  The simulator can be stopped by:

        WAI instruction
        I/O error in I/O simulator
        Invalid OP code (if ITRAP is set on CPU)
        Invalid memory address (if MTRAP is set on CPU)

   2. Interrupts.
      There are 4 types of interrupt, and in effect they do Reg_A 
      hardware CALL instruction to one of 4 possible high memory addresses.

   3. Non-existent memory.  
        On the real 77-68 6800, reads to non-existent memory or echoes of other boards
        This emulation returns 0x00, and writes are ignored.
*/

/* Local `global` variables */

int32_t Reg_A = 0;                            /* Accumulator Reg_A */
int32_t Reg_B = 0;                            /* Accumulator Reg_B */
int32_t Reg_IX = 0;                           /* Index register */
int32_t Reg_SP = 0;                           /* Stack pointer */
int32_t Reg_CCR = CCR_ALWAYS_ON | IF;         /* Condition Code Register */
int32_t Reg_PC;                               /* global for the helper routines */
int32_t saved_PC = 0;                         /* Program counter */
int32_t int_req = 0;                          /* Interrupt request */
int32_t i32ThisOpCode;
int32_t i32ThisOpArgCount;

// CDC...
Stream * objDebugTTY = &Serial;  // Default

// Traceback data store...
struct {
  int32_t i32PC;
  int32_t i32IX;
} stTrace[10] = {
  {0,0},{0,0},{0,0},{0,0},{0,0},{0,0},
  {0,0},{0,0},{0,0},{0,0},
};
int iTraceCount = cNUMBER_OF(stTrace);

//--- START ---

int32_t sim_6800_go() {
  int32_t DAR, reason, hi, lo, op1;
  int iRunCount = -1;
  int bBreak;

//x  fvUsageInit( 0xF800, 0xFFFF ); // DEMON
#if cDISASSEMBLY
  fvUsageInit( cDISASSEMBLY_START, cDISASSEMBLY_END );
#endif
   
  Reg_PC = saved_PC & cM6800_MAX_ADDR_MASK;           /* load local PC */
  reason = 0;

  /* Main instruction fetch/decode loop */

  while (reason == 0) {               /* loop until halted */

#if cDEV_PANEL_SWITCHES
      if ( gi32_Panel_Switch_Changed ) {
        gi32_Panel_Switch_Changed = false;
        objPANEL.vReadSwitchPins();
      }
#endif

#if cDISASSEMBLY
      // Set memory usage flags for this instruction...
      fvUsageForOpCode( Reg_PC, Reg_IX, Reg_SP );
#endif      

      // Move traceback list items up one...
      for (int iAt=( iTraceCount - 1 ); iAt>0; iAt--) {
        stTrace[iAt].i32PC = stTrace[iAt-1].i32PC;
        stTrace[iAt].i32IX = stTrace[iAt-1].i32IX;
      }
      // Push this (next) instruction onto traceback list...
      stTrace[0].i32PC = Reg_PC;
      stTrace[0].i32IX = Reg_IX;      
      i32ThisOpCode = fi32FetchByteIncPC();  // fetch instruction and increment Reg_PC

      // USER INTERRUPT ?...
      if (iRunCount > 0) iRunCount--;

      bBreak = false;
      if (iRunCount == 0)  bBreak = true;

      // Is next instruction a WAI ?...
      if (i32ThisOpCode == 0x3E) {
        bBreak = true;
        objDebugTTY = &Serial;
        Serial.println();
        Serial.println("M6800 WAI instruction:-");
        // Turn this opcode into NOP so that
        // a `C` command should restore state and
        // continue program...
        i32ThisOpCode = 0x01;
      }


      // Look for `Esc` keystroke on main tty...     
      if ( Serial.peek() == cEMULATION_INTERRUPT_CMD_CHAR ) {
        Serial.read(); // Flush out the char
        bBreak = true;
        objDebugTTY = &Serial;
        Serial.println();
        Serial.println("M6800 User interrupt:-");
      }

#if cDEV_TYPE_DUE
      // Look for `Esc` keystroke on main DUEs USB serial...     
      if ( SerialUSB.peek() == cEMULATION_INTERRUPT_CMD_CHAR ) {
        SerialUSB.read(); // Flush out the char
        bBreak = true;
        objDebugTTY = &SerialUSB;
        Serial.println();
        Serial.println("M6800 Debug interrupt:-");
      }
#endif

#if cDEV_SETUP_C  // (Lego, IE: with switches)...
      // Look for RUN/HALT going to HALT(=false) button press...
      if ( objPANEL.readSwRun() ) {
        // RUN mode...
        // Look for RESET button press...
        if ( objPANEL.readSwReset() ) {
          int32_t i32Addr;
          // Restart via address in reset vector...
          i32Addr = fi32GetMemoryWord(0xFFFE);
          Reg_PC = i32Addr;
          i32ThisOpCode = fi32FetchByteIncPC();  /* Fetch instruction */
          Reg_CCR = CCR_ALWAYS_ON | IF;          /* Reset CC bits */
          iRunCount = -1;
          delay(500); // Time for RESET button to release
        }
      } else {
        bBreak = true;
        objDebugTTY = &Serial;
        Serial.println();
        Serial.println("M6800 HALT interrupt:-");
      }
#endif      

      // Break out to user...
      if ( bBreak ) {
        char cOne = '#';
        //
        objDebugTTY->println("M6800 Emulator Control:-");
        //
#if cDEV_PANEL_LEDBAR
        // The little LED bar has 10 LEDs, these bits control
        // the extra 2 not needed to emuate the 8 panel LEDs...
        objPANEL.setExtraBits( cDEV_PANEL_LEDBAR_EXTRA_BIT_RED );
#endif        
        //
        while(true) {
          objDebugTTY->print("Cmd> ");
          cOne = fcInputChar( objDebugTTY );
          cOne = toupper(cOne);

          // Modify (similar to  MINIMON, DEMON etc)...
          if (cOne == 'M') {
            int32_t i32Addr;
            int32_t i32Data;
            int iCount = 99;
            objDebugTTY->print(" Start:");
            i32Addr = fi32ReadHex4( objDebugTTY );
            while (i32Addr >=0 ) {
              iCount++;
              if (iCount >= 8) {
                iCount = 0;
                objDebugTTY->println();
                fvOutputHex4( objDebugTTY, i32Addr );
                objDebugTTY->print(": ");
              }
              i32Data = fi32GetMemoryByte( i32Addr );
              fvOutputHex2( objDebugTTY, i32Data );
              objDebugTTY->print("=");
              i32Data = fi32ReadHex2( objDebugTTY );
              if (i32Data == -1) break;;
              if (i32Data == -2) i32Addr++;
              if (i32Data >= 0) {
                fvPutMemoryByte(i32Addr, i32Data);
                i32Addr++;
                objDebugTTY->print(" ");
              }
            }
          }


          // Go (similar to  MINIMON, DEMON etc)...
          if (cOne == 'G') {
            int32_t i32Addr;
            objDebugTTY->print(" Start:");
            i32Addr = fi32ReadHex4( objDebugTTY );
            if (i32Addr >= 0) {
              Reg_PC = i32Addr;
              i32ThisOpCode = fi32FetchByteIncPC();
              iRunCount = -1;
              break;
            }
          }

          if (cOne == 'H') {
            // Hard reset...
            cResetArduino();
          }
           
          if (cOne == 'S') {
            int32_t i32Addr;
            // Restart via address in reset vector...
            i32Addr = fi32GetMemoryWord(0xFFFE);
            Reg_PC = i32Addr;
            i32ThisOpCode = fi32FetchByteIncPC();  /* Fetch instruction */
            Reg_CCR = CCR_ALWAYS_ON | IF;          /* Reset CC bits */
            iRunCount = -1;
            break;
          }

          if (cOne == 'T') {
            fvPrintTraceback( objDebugTTY );
          }

          if ((cOne >= '1') && (cOne <= '9')) {
            objDebugTTY->println();
            iRunCount = cOne - '0';
            break;
          }

          // Input routine returns -1 if HALT/RUN switch goes to RUN...
          if ( (cOne == 'C') || (cOne == cSWRUN) ) {
            objDebugTTY->println();
            iRunCount = -1;
            break;
          }

#if defined c7768_DATA_MANDC_H
          if (cOne == 'U') {
            // Load Missionaries And Cannibals game into RAM...
            int32_t iOffset = 0x0100;
            for (int32_t iAt=0; iAt < sizeof(u8RAM_MANDC); iAt++) {
              fvPutMemoryByte( (iAt + iOffset), u8RAM_MANDC[iAt] );
            }
          }
#endif 
#if defined c7768_DATA_SWTOPIA_H
          if (cOne == 'V') {
            // Load Switches to LEDs and PIA into RAM...
            int32_t iOffset = 0x0100;
            for (int32_t iAt=0; iAt < sizeof(u8RAM_SWTOPIA); iAt++) {
              fvPutMemoryByte( (iAt + iOffset), u8RAM_SWTOPIA[iAt] );
            }
          }  
#endif

#if defined c7768_DATA_BASIC8K_H
          if (cOne == 'Z') {
            // Load BASIC into RAM at 0x0000...
            int32_t iOffset = 0x0000;
            for (int32_t iAt=0; iAt < sizeof(u8RAM_BASIC8Ka); iAt++) {
              fvPutMemoryByte( (iAt + iOffset), u8RAM_BASIC8Ka[iAt] );
            }
            // Load I/O into RAM at 0xF100...
            iOffset = 0xF100;
            for (int32_t iAt=0; iAt < sizeof(u8RAM_BASIC8Kb); iAt++) {
              fvPutMemoryByte( (iAt + iOffset), u8RAM_BASIC8Kb[iAt] );
            }
          }  
#endif


#if cDISASSEMBLY
          if (cOne == '=') {
            fvUsageInit( cDISASSEMBLY_START, cDISASSEMBLY_END );
          }
          if (cOne == '!') {
            fvUsageInit( 0,0 );
          }
          if (cOne == '/') {
            fvUsageDissassembly( &Serial, cDISASSEMBLY_START, cDISASSEMBLY_END ); // See 7768.h
          }
          if (cOne == '@') {
            fvUsageDissassembly( &SerialUSB, cDISASSEMBLY_START, cDISASSEMBLY_END );
          }
#endif          

          if (cOne == '?') {
            objDebugTTY->println();
            //objDebugTTY->print("Free RAM: ");
            //objDebugTTY->println( freeMemory() );
            objDebugTTY->println("Commands:-");
            objDebugTTY->println("  M = Modify memory");
            objDebugTTY->println("  C = Continue");
            objDebugTTY->println("  G = Go to address");
            objDebugTTY->println("  H = Hard reset");
            objDebugTTY->println("  S = Soft reset emulator");
            objDebugTTY->println("  T = Show traceback");
            objDebugTTY->println("  1 to 9 = Step `n` times");
#if defined c7768_DATA_MANDC_H
            objDebugTTY->println("  U = Load Missionaries game to 0100");
#endif 
#if defined c7768_DATA_SWTOPIA_H
            objDebugTTY->println("  V = Load Switches to LED & PIA to 0100");
#endif
#if defined c7768_DATA_BASIC8K_H
            objDebugTTY->println("  Z = Load BASIC, G 0000 to start");
#endif
      
#if cDISASSEMBLY
            objDebugTTY->println("  ! = Disassembly OFF");
            objDebugTTY->println("  = = Disassembly ON & Init");
            objDebugTTY->println("  / = Disassemble to ACIA-A");
            objDebugTTY->println("  @ = Disassemble to ACIA-B");
#endif            
            objDebugTTY->println("  ? = Display this message");
#if cUSE_ROMRAM
            fvShowRomRamState( objDebugTTY );
#endif
          }

        objDebugTTY->println();
        } // End: while (true)

        objPANEL.setExtraBits( 0 );
      } // End: `Break` to user

       switch (i32ThisOpCode) {
        //x case 0x00:               /* Works as NOP : Tested on DJC->CDC->DW 77-68nt */
        //x   break;
        case 0x01:                  /* NOP */
          break;
        case 0x02:                  /* Nop : CDC allowing this as it is used in some very old code */
          break;
        case 0x06:                  /* TAP */
          Reg_CCR = Reg_A | CCR_ALWAYS_ON;        
          break;
        case 0x07:                  /* TPA */
          Reg_A = Reg_CCR;
          break;
        case 0x08:                  /* INX */
          Reg_IX = (Reg_IX + 1) & cM6800_MAX_ADDR_MASK;
          COND_SET_FLAG_Z(Reg_IX);
          break;
        case 0x09:                  /* DEX */
          Reg_IX = (Reg_IX - 1) & cM6800_MAX_ADDR_MASK;
          COND_SET_FLAG_Z(Reg_IX);
          break;
        case 0x0A:                  /* CLV */
          CLR_FLAG(VF);
          break;
        case 0x0B:                  /* SEV */
          SET_FLAG(VF);
          break;
        case 0x0C:                  /* CLC */
          CLR_FLAG(CF);
          break;
        case 0x0D:                  /* SEC */
          SET_FLAG(CF);
          break;
        case 0x0E:                  /* CLI */
          CLR_FLAG(IF);
          break;
        case 0x0F:                  /* SEI */
          SET_FLAG(IF);
          break;
        case 0x10:                  /* SBA */
          op1 = Reg_A;
          Reg_A = Reg_A - Reg_B;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVs(op1, Reg_B);
          break;
        case 0x11:                  /* CBA */
          lo = Reg_A - Reg_B;
          COND_SET_FLAG_C(lo);
          lo &= 0xFF;
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          condevalVs(Reg_A, Reg_B );
          break;
        case 0x16:                  /* TAB */
          Reg_B = Reg_A;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          CLR_FLAG(VF);
          break;
        case 0x17:                  /* TBA */
          Reg_A = Reg_B;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          CLR_FLAG(VF);
          break;
        case 0x19:                  /* DAA */
          DAR = Reg_A & 0x0F;
          if ((DAR > 9) || get_flag(HF)) {
            DAR += 6 ;
            Reg_A = (Reg_A & 0xF0) + DAR;
            COND_SET_FLAG(DAR & 0x10, HF);
          }
          DAR = (Reg_A >> 4) & 0x0F;
          if ((DAR > 9) || get_flag(CF)) {
            DAR += 6;
            Reg_A = (Reg_A & 0x0F) | (DAR << 4) | 0x100;
          }
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          COND_SET_FLAG_N(Reg_A);        
          COND_SET_FLAG_Z(Reg_A);        
        case 0x1B:                  /* ABA */
          op1 = Reg_A ;
          Reg_A += Reg_B;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          condevalHa(op1, Reg_B);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVa(op1, Reg_B);        
          break;
        case 0x20:                  /* BRA rel */
          go_rel(1);
          break;
        case 0x22:                  /* BHI rel */
          go_rel(!(get_flag(CF) | get_flag(ZF)));
         break;
        case 0x23:                  /* BLS rel */
          go_rel(get_flag(CF) | get_flag(ZF));
          break;
        case 0x24:                  /* BCC rel */
          go_rel(!get_flag(CF));
          break;
        case 0x25:                  /* BCS rel */
          go_rel(get_flag(CF));
          break;
        case 0x26:                  /* BNE rel */
          go_rel(!get_flag(ZF));
          break;
        case 0x27:                  /* BEQ rel */
          go_rel(get_flag(ZF));
          break;
        case 0x28:                  /* BVC rel */
          go_rel(!get_flag(VF));
          break;
        case 0x29:                  /* BVS rel */
          go_rel(get_flag(VF));
          break;
        case 0x2A:                  /* BPL rel */
          go_rel(!get_flag(NF));
          break;
        case 0x2B:                  /* BMI rel */
          go_rel(get_flag(NF));
          break;
        case 0x2C:                  /* BGE rel */
          go_rel(!(get_flag(NF) ^ get_flag(VF)));
          break;
        case 0x2D:                  /* BLT rel */
          go_rel(get_flag(NF) ^ get_flag(VF));
          break;
        case 0x2E:                  /* BGT rel */
          go_rel(!(get_flag(ZF) | (get_flag(NF) ^ get_flag(VF))));
          break;
        case 0x2F:                  /* BLE rel */
          go_rel(get_flag(ZF) | (get_flag(NF) ^ get_flag(VF)));
          break;
        case 0x30:                  /* TSX */
          Reg_IX = (Reg_SP + 1) & cM6800_MAX_ADDR_MASK;
          break;
        case 0x31:                  /* INS */
          Reg_SP = (Reg_SP + 1) & cM6800_MAX_ADDR_MASK;
          break;
        case 0x32:                  /* PUL Reg_A */
          Reg_A = pop_byte();
          break;
        case 0x33:                  /* PUL Reg_B */
          Reg_B = pop_byte();
          break;
        case 0x34:                  /* DES */
          Reg_SP = (Reg_SP - 1) & cM6800_MAX_ADDR_MASK;
          break;
        case 0x35:                  /* TXS */
          Reg_SP = (Reg_IX - 1) & cM6800_MAX_ADDR_MASK;
          break;
        case 0x36:                  /* PSH Reg_A */
          push_byte(Reg_A);
          break;
        case 0x37:                  /* PSH Reg_B */
          push_byte(Reg_B);
          break;
        case 0x39:                  /* RTS */
          Reg_PC = pop_word();
          break;
        case 0x3B:                  /* RTI */
          Reg_CCR = pop_byte();
          Reg_B = pop_byte();
          Reg_A = pop_byte();
          Reg_IX = pop_word();
          Reg_PC = pop_word();
          break;
        case 0x3E:                  /* WAI */
          /* CDC : cut out old WAI handling...
           *  Simply now ignoring it as earlier code in this module
           *  changes it to 0x01 (NOP) when it is used
           *  earlier in flow to show a traceback and
           *  menu - Same as user keystroke Ctrl+]
          push_word(Reg_PC);
          push_word(Reg_IX);
          push_byte(Reg_A);
          push_byte(Reg_B);
          push_byte(Reg_CCR);       
          // Needs work for interrupt handling ? -->
          if (get_flag(IF)) {
            reason = cM6800_STOP_HALT;
            continue;
          } else {
            SET_FLAG(IF);
            Reg_PC = fi32GetMemoryWord(0xFFFE);  //<-- This is RESET vector
          }
          */
          break;
        case 0x3F:                  /* SWI */
          push_word(Reg_PC);
          push_word(Reg_IX);
          push_byte(Reg_A);
          push_byte(Reg_B);
          push_byte(Reg_CCR);
          SET_FLAG(IF);
          Reg_PC = fi32GetMemoryWord(0xFFFA);
          break;
        case 0x40:                  /* NEG Reg_A */
          op1 = Reg_A;
          Reg_A = (0 - Reg_A) & 0xFF;
          condevalVs(Reg_A, op1);
          COND_SET_FLAG(Reg_A,CF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x43:                  /* COM Reg_A */
          Reg_A = ~Reg_A & 0xFF;
          CLR_FLAG(VF);
          SET_FLAG(CF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x44:                  /* LSR Reg_A */
          COND_SET_FLAG(Reg_A & 0x01,CF);
          Reg_A = (Reg_A >> 1) & 0xFF;
          CLR_FLAG(NF);
          COND_SET_FLAG_Z(Reg_A);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x46:                  /* ROR Reg_A */
          hi = get_flag(CF);
          COND_SET_FLAG(Reg_A & 0x01,CF);
          Reg_A = (Reg_A >> 1) & 0xFF;
          if (hi) {
            Reg_A |= 0x80;
          }
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x47:                  /* ASR Reg_A */
          COND_SET_FLAG(Reg_A & 0x01,CF);
          lo = Reg_A & 0x80;
          Reg_A = (Reg_A >> 1) & 0xFF;
          Reg_A |= lo; 
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x48:                  /* ASL Reg_A */
          COND_SET_FLAG(Reg_A & 0x80,CF);
          Reg_A = (Reg_A << 1) & 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x49:                  /* ROL Reg_A */
          hi = get_flag(CF);  
          COND_SET_FLAG(Reg_A & 0x80,CF);
          Reg_A = (Reg_A << 1) & 0xFF;
          if (hi) {
            Reg_A |= 0x01;
          }
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x4A:                  /* DEC Reg_A */
          COND_SET_FLAG_V(Reg_A == 0x80);
          Reg_A = (Reg_A - 1) & 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x4C:                  /* INC Reg_A */
          COND_SET_FLAG_V(Reg_A == 0x7F);
          Reg_A = (Reg_A + 1) & 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x4D:                  /* TST Reg_A */
          lo = Reg_A & 0xFF;
          CLR_FLAG(VF);
          CLR_FLAG(CF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x4F:                  /* CLR Reg_A */
          Reg_A = 0;
          CLR_FLAG(NF);
          CLR_FLAG(VF);
          CLR_FLAG(CF);
          SET_FLAG(ZF);
          break;
        case 0x50:                  /* NEG Reg_B */
          op1 = Reg_B;
          Reg_B = (0 - Reg_B) & 0xFF;
          condevalVs(Reg_B,op1);
          COND_SET_FLAG(Reg_B,CF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0x53:                  /* COM Reg_B */
          Reg_B = ~Reg_B;
          Reg_B &= 0xFF;
          CLR_FLAG(VF);
          SET_FLAG(CF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0x54:                  /* LSR Reg_B */
          COND_SET_FLAG(Reg_B & 0x01,CF);
          Reg_B = (Reg_B >> 1) & 0xFF;
          CLR_FLAG(NF);
          COND_SET_FLAG_Z(Reg_B);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x56:                  /* ROR Reg_B */
          hi = get_flag(CF); 
          COND_SET_FLAG(Reg_B & 0x01,CF);
          Reg_B = (Reg_B >> 1) & 0xFF;
          if (hi) {
            Reg_B |= 0x80;
          }    
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x57:                  /* ASR Reg_B */
          COND_SET_FLAG(Reg_B & 0x01,CF);
          lo = Reg_B & 0x80;
          Reg_B = (Reg_B >> 1) & 0xFF;
          Reg_B |= lo;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x58:                  /* ASL Reg_B */
          COND_SET_FLAG(Reg_B & 0x80,CF);
          Reg_B = (Reg_B << 1) & 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x59:                  /* ROL Reg_B */
          hi = get_flag(CF);
          COND_SET_FLAG(Reg_B & 0x80,CF);
          Reg_B = (Reg_B << 1) & 0xFF;
          if (hi) {
            Reg_B |= 0x01;
          }    
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x5A:                  /* DEC Reg_B */
          COND_SET_FLAG_V(Reg_B == 0x80);
          Reg_B = (Reg_B - 1) & 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0x5C:                  /* INC Reg_B */
          COND_SET_FLAG_V(Reg_B == 0x7F);
          Reg_B = (Reg_B + 1) & 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0x5D:                  /* TST Reg_B */
          lo = Reg_B & 0xFF;
          CLR_FLAG(VF);
          CLR_FLAG(CF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x5F:                  /* CLR Reg_B */
          Reg_B = 0;
          CLR_FLAG(NF);
          CLR_FLAG(VF);
          CLR_FLAG(CF);
          SET_FLAG(ZF);
          break;
        case 0x60:                  /* NEG ind */
          DAR = (fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK;
          op1 = fi32GetMemoryByte(DAR);
          lo = (0- op1) & 0xFF;
          fvPutMemoryByte(DAR, lo);
          condevalVs(lo,op1);
          COND_SET_FLAG(lo,CF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x63:                  /* COM ind */
          DAR = ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK);
          lo = ~fi32GetMemoryByte(DAR);
          lo &= 0xFF;
          fvPutMemoryByte(DAR, lo);
          CLR_FLAG(VF);
          SET_FLAG(CF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x64:                  /* LSR ind */
          DAR = ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK);
          lo = fi32GetMemoryByte(DAR);
          COND_SET_FLAG(lo & 0x01,CF);
          lo >>= 1;
          fvPutMemoryByte(DAR, lo);
          CLR_FLAG(NF);
          COND_SET_FLAG_Z(lo);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x66:                  /* ROR ind */
          DAR = ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK);
          lo = fi32GetMemoryByte(DAR);
          hi = get_flag(CF);
          COND_SET_FLAG(lo & 0x01,CF);
          lo >>= 1;
          if (hi) {
            lo |= 0x80;
          }    
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x67:                  /* ASR ind */
          DAR = ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK);
          lo = fi32GetMemoryByte(DAR);
          COND_SET_FLAG(lo & 0x01,CF);
          lo = (lo & 0x80) | (lo >> 1);
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x68:                  /* ASL ind */
          DAR = ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK);
          lo = fi32GetMemoryByte(DAR);
          COND_SET_FLAG(lo & 0x80,CF);
          lo = (lo << 1) & 0xFF;
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x69:                  /* ROL ind */
          DAR = ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK);
          lo = fi32GetMemoryByte(DAR);
          hi = get_flag(CF);
          COND_SET_FLAG(lo & 0x80,CF);
          lo = (lo << 1) & 0xFF;
          if (hi) {
            lo |= 0x01;
          }
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x6A:                  /* DEC ind */
          DAR = ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK);
          lo = fi32GetMemoryByte(DAR);
          COND_SET_FLAG_V(lo == 0x80);
          lo = (lo - 1) & 0xFF;
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x6C:                  /* INC ind */
          DAR= ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK);
          lo = fi32GetMemoryByte(DAR);
          COND_SET_FLAG_V(lo == 0x7F);
          lo = (lo + 1) & 0xFF;
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x6D:                  /* TST ind */
          lo = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) ) & 0xFF;
          CLR_FLAG(VF);
          CLR_FLAG(CF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x6E:                  /* JMP ind */
          Reg_PC = ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK);
          break;
        case 0x6F:                  /* CLR ind */
          fvPutMemoryByte(((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK), 0);
          CLR_FLAG(NF);
          CLR_FLAG(VF);
          CLR_FLAG(CF);
          SET_FLAG(ZF);
          break;
        case 0x70:                  /* NEG ext */
          DAR = fi32FetchWordIncPC();
          op1 = fi32GetMemoryByte(DAR);
          lo = (0 - op1) & 0xFF;
          fvPutMemoryByte(DAR, lo);
          condevalVs(lo, op1);          
          if (lo) {
            SET_FLAG(CF);
          } else {
            CLR_FLAG(CF);
          }
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x73:                  /* COM ext */
          DAR = fi32FetchWordIncPC();
          lo = ~fi32GetMemoryByte(DAR);
          lo &= 0xFF;
          fvPutMemoryByte(DAR, lo);
          CLR_FLAG(VF);
          SET_FLAG(CF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x74:                  /* LSR ext */
          DAR = fi32FetchWordIncPC();
          lo = fi32GetMemoryByte(DAR);
          COND_SET_FLAG(lo & 0x01,CF);
          lo >>= 1;
          fvPutMemoryByte(DAR, lo);
          CLR_FLAG(NF);
          COND_SET_FLAG_Z(lo);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x76:                  /* ROR ext */
          DAR = fi32FetchWordIncPC();
          lo = fi32GetMemoryByte(DAR);
          hi = get_flag(CF);
          COND_SET_FLAG(lo & 0x01,CF);
          lo >>= 1;
          if (hi) {
            lo |= 0x80;
          }  
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x77:                  /* ASR ext */
          DAR = fi32FetchWordIncPC();
          lo = fi32GetMemoryByte(DAR);
          COND_SET_FLAG(lo & 0x01,CF);
          hi = lo & 0x80;
          lo >>= 1;
          lo |= hi;
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x78:                  /* ASL ext */
          DAR = fi32FetchWordIncPC();
          lo = fi32GetMemoryByte(DAR);
          COND_SET_FLAG(lo & 0x80,CF);
          lo = (lo << 1) & 0xFF;
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x79:                  /* ROL ext */
          DAR = fi32FetchWordIncPC();
          lo = fi32GetMemoryByte(DAR);
          hi = get_flag(CF);
          COND_SET_FLAG(lo & 0x80,CF);
          lo = (lo << 1) & 0xFF;
          if (hi) {
            lo |= 0x01;
          }
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          COND_SET_FLAG_V(get_flag(NF) ^ get_flag(CF));
          break;
        case 0x7A:                  /* DEC ext */
          DAR = fi32FetchWordIncPC();
          lo = fi32GetMemoryByte(DAR);
          COND_SET_FLAG_V(lo == 0x80);
          lo = (lo - 1) & 0xFF;
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x7C:                  /* INC ext */
          DAR = fi32FetchWordIncPC();
          lo = fi32GetMemoryByte(DAR);
          COND_SET_FLAG_V(lo == 0x7F);
          lo = (lo + 1) & 0xFF;
          fvPutMemoryByte(DAR, lo);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x7D:                  /* TST ext */
          lo = fi32GetMemoryByte(fi32FetchWordIncPC());
          CLR_FLAG(VF);
          CLR_FLAG(CF);
          COND_SET_FLAG_N(lo);
          lo &= 0xFF;
          COND_SET_FLAG_Z(lo);
          break;
        case 0x7E:                  /* JMP ext */
          Reg_PC = fi32FetchWordIncPC() & cM6800_MAX_ADDR_MASK;
          break;
        case 0x7F:                  /* CLR ext */
          fvPutMemoryByte(fi32FetchWordIncPC(), 0);
          CLR_FLAG(NF);
          CLR_FLAG(VF);
          CLR_FLAG(CF);
          SET_FLAG(ZF);
          break;
        case 0x80:                  /* SUB Reg_A imm */
          lo = fi32FetchByteIncPC();
          op1 = Reg_A;
          Reg_A = Reg_A - lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVs(op1, lo);
          break;
        case 0x81:                  /* CMP Reg_A imm */
          op1 = fi32FetchByteIncPC();
          lo = Reg_A - op1;
          COND_SET_FLAG_C(lo);
          lo &= 0xFF;
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          condevalVs(Reg_A, op1);
          break;
        case 0x82:                  /* SBC Reg_A imm */
          lo = fi32FetchByteIncPC() + get_flag(CF);
          op1 = Reg_A;
          Reg_A = Reg_A - lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          COND_SET_FLAG_N(Reg_A); 
          COND_SET_FLAG_Z(Reg_A);
          condevalVs(op1, lo);
          break;
        case 0x84:                  /* AND Reg_A imm */
          Reg_A = (Reg_A & fi32FetchByteIncPC()) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x85:                  /* BIT Reg_A imm */
          lo = (Reg_A & fi32FetchByteIncPC()) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x86:                  /* LDA Reg_A imm */
          Reg_A = fi32FetchByteIncPC();
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x88:                  /* EOR Reg_A imm */
          Reg_A = (Reg_A ^ fi32FetchByteIncPC()) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x89:                  /* ADC Reg_A imm */
          lo = fi32FetchByteIncPC() + get_flag(CF);
          op1 = Reg_A;
          Reg_A = Reg_A + lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVa(op1, lo);
          break;
        case 0x8A:                  /* ORA Reg_A imm */
          Reg_A = (Reg_A | fi32FetchByteIncPC()) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x8B:                  /* ADD Reg_A imm */
          lo = fi32FetchByteIncPC();
          op1 = Reg_A;
          Reg_A = Reg_A + lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVa(op1, lo);
          break;
        case 0x8C:                  /* CPX imm */
          op1 = Reg_IX - fi32FetchWordIncPC();
          COND_SET_FLAG_Z(op1);
          COND_SET_FLAG_N(op1 >> 8);
          COND_SET_FLAG_V(op1 & 0x10000);
          break;
        case 0x8D:                  /* BSR rel */
          lo = get_rel_addr();
          push_word(Reg_PC);
          Reg_PC = Reg_PC + lo;
          Reg_PC &= cM6800_MAX_ADDR_MASK;
          break;
        case 0x8E:                  /* LDS imm */
          Reg_SP = fi32FetchWordIncPC();
          COND_SET_FLAG_N(Reg_SP >> 8);
          COND_SET_FLAG_Z(Reg_SP);
          CLR_FLAG(VF);
          break;
        case 0x90:                  /* SUB Reg_A dir */
          lo = fi32GetMemoryByte( fi32FetchByteIncPC() );
          op1 = Reg_A;
          Reg_A = Reg_A - lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVs(op1, lo);
          break;
        case 0x91:                  /* CMP Reg_A dir */
          op1 = fi32GetMemoryByte( fi32FetchByteIncPC() );
          lo = Reg_A - op1;
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_C(lo);
          condevalVs(Reg_A, op1);
          lo &= 0xFF;
          COND_SET_FLAG_Z(lo);
          break;
        case 0x92:                  /* SBC Reg_A dir */
          lo = fi32GetMemoryByte( fi32FetchByteIncPC() ) + get_flag(CF);
          Reg_A = Reg_A - lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVs(op1, lo);
          break;
        case 0x94:                  /* AND Reg_A dir */
          Reg_A = (Reg_A & fi32GetMemoryByte( fi32FetchByteIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x95:                  /* BIT Reg_A dir */
          lo = (Reg_A & fi32GetMemoryByte( fi32FetchByteIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0x96:                  /* LDA Reg_A dir */
          Reg_A = fi32GetMemoryByte( fi32FetchByteIncPC() );
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x97:                  /* STA Reg_A dir */
          fvPutMemoryByte(fi32FetchByteIncPC(), Reg_A);
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x98:                  /* EOR Reg_A dir */
          Reg_A = (Reg_A ^ fi32GetMemoryByte( fi32FetchByteIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x99:                  /* ADC Reg_A dir */
          lo = fi32GetMemoryByte( fi32FetchByteIncPC() ) + get_flag(CF);
          op1 = Reg_A;
          Reg_A = Reg_A + lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVa(op1, lo);
          break;
        case 0x9A:                  /* ORA Reg_A dir */
          Reg_A = (Reg_A | fi32GetMemoryByte( fi32FetchByteIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0x9B:                  /* ADD Reg_A dir */
          lo = fi32GetMemoryByte( fi32FetchByteIncPC() );
          op1 = Reg_A;
          Reg_A = Reg_A + lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVa(op1, lo);
          break;
        case 0x9C:                  /* CPX dir */
          op1 = Reg_IX - fi32GetMemoryWord(fi32FetchByteIncPC());
          COND_SET_FLAG_Z(op1);
          COND_SET_FLAG_N(op1 >> 8);
          COND_SET_FLAG_V(op1 & 0x10000);
          break;
        case 0x9E:                  /* LDS dir */
          Reg_SP = fi32GetMemoryWord(fi32FetchByteIncPC());
          COND_SET_FLAG_N(Reg_SP >> 8);
          COND_SET_FLAG_Z(Reg_SP);
          CLR_FLAG(VF);
          break;
        case 0x9F:                  /* STS dir */
          fvPutMemoryWord(fi32FetchByteIncPC(), Reg_SP);
          COND_SET_FLAG_N(Reg_SP >> 8);
          COND_SET_FLAG_Z(Reg_SP);
          CLR_FLAG(VF);
          break;
        case 0xA0:                  /* SUB Reg_A ind */
          lo = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) );
          op1 = Reg_A;
          Reg_A = Reg_A - lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVs(op1, lo);
          break;
        case 0xA1:                  /* CMP Reg_A ind */
          op1 = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) );
          lo = Reg_A - op1;
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_C(lo);
          condevalVs(Reg_A, op1);
          lo &= 0xFF;
          COND_SET_FLAG_Z(lo);
          break;
        case 0xA2:                  /* SBC Reg_A ind */
          lo = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) ) + get_flag(CF);
          Reg_A = Reg_A - lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVs(op1, lo);
          break;
        case 0xA4:                  /* AND Reg_A ind */
          Reg_A = (Reg_A & fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0xA5:                  /* BIT Reg_A ind */
          lo = (Reg_A & fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0xA6:                  /* LDA Reg_A ind */
          Reg_A = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) );
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0xA7:                  /* STA Reg_A ind */
          fvPutMemoryByte(((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK), Reg_A);
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0xA8:                  /* EOR Reg_A ind */
          Reg_A = (Reg_A ^ fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0xA9:                  /* ADC Reg_A ind */
          lo = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) ) + get_flag(CF);
          op1 = Reg_A;
          Reg_A = Reg_A + lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVa(op1, lo);
          break;
        case 0xAA:                  /* ORA Reg_A ind */
          Reg_A = (Reg_A | fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0xAB:                  /* ADD Reg_A ind */
          lo = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) );
          op1 = Reg_A;
          Reg_A = Reg_A + lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVa(op1, lo);
          break;
        case 0xAC:                  /* CPX ind */
          op1 = (Reg_IX - ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK)) & cM6800_MAX_ADDR_MASK;
          COND_SET_FLAG_Z(op1);
          COND_SET_FLAG_N(op1 >> 8);
          COND_SET_FLAG_V(op1 & 0x10000);
          break;
        case 0xAD:                  /* JSR ind */
          DAR = ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK);
          push_word(Reg_PC);
          Reg_PC = DAR;
          break;
        case 0xAE:                  /* LDS ind */
          Reg_SP = fi32GetMemoryWord(((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK));
          COND_SET_FLAG_N(Reg_SP >> 8);
          COND_SET_FLAG_Z(Reg_SP);
          CLR_FLAG(VF);
          break;
        case 0xAF:                  /* STS ind */
          fvPutMemoryWord(((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK), Reg_SP);
          COND_SET_FLAG_N(Reg_SP >> 8);
          COND_SET_FLAG_Z(Reg_SP);
          CLR_FLAG(VF);
          break;
        case 0xB0:                  /* SUB Reg_A ext */
          lo = fi32GetMemoryByte( fi32FetchWordIncPC() );
          op1 = Reg_A;
          Reg_A = Reg_A - lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVs(op1, lo);
          break;
        case 0xB1:                  /* CMP Reg_A ext */
          op1 = fi32GetMemoryByte( fi32FetchWordIncPC() );
          lo = Reg_A - op1;
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_C(lo);
          condevalVs(Reg_A, op1);
          lo &= 0xFF;
          COND_SET_FLAG_Z(lo);
          break;
        case 0xB2:                  /* SBC Reg_A ext */
          lo = fi32GetMemoryByte( fi32FetchWordIncPC() ) + get_flag(CF);
          op1 = Reg_A;
          Reg_A = Reg_A - lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVs(op1, lo);
          break;
        case 0xB4:                  /* AND Reg_A ext */
          Reg_A = (Reg_A & fi32GetMemoryByte( fi32FetchWordIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0xB5:                  /* BIT Reg_A ext */
          lo = (Reg_A & fi32GetMemoryByte( fi32FetchWordIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0xB6:                  /* LDA Reg_A ext */
          Reg_A = fi32GetMemoryByte( fi32FetchWordIncPC() );
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0xB7:                  /* STA Reg_A ext */
          fvPutMemoryByte(fi32FetchWordIncPC(), Reg_A);
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0xB8:                  /* EOR Reg_A ext */
          Reg_A = (Reg_A ^ fi32GetMemoryByte( fi32FetchWordIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0xB9:                  /* ADC Reg_A ext */
          lo = fi32GetMemoryByte( fi32FetchWordIncPC() ) + get_flag(CF);
          op1 = Reg_A;
          Reg_A = Reg_A + lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVa(op1, lo);
          break;
        case 0xBA:                  /* ORA Reg_A ext */
          Reg_A = (Reg_A | fi32GetMemoryByte( fi32FetchWordIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          break;
        case 0xBB:                  /* ADD Reg_A ext */
          lo = fi32GetMemoryByte( fi32FetchWordIncPC() );
          op1 = Reg_A;
          Reg_A = Reg_A + lo;
          COND_SET_FLAG_C(Reg_A);
          Reg_A &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_A);
          COND_SET_FLAG_Z(Reg_A);
          condevalVa(op1, lo);
          break;
        case 0xBC:                  /* CPX ext */
          op1 = (Reg_IX - fi32GetMemoryWord(fi32FetchWordIncPC()));
          COND_SET_FLAG_Z(op1);
          COND_SET_FLAG_N(op1 >> 8);
          COND_SET_FLAG_V(op1 & 0x10000);
          break;
        case 0xBD:                  /* JSR ext */
          DAR = fi32FetchWordIncPC();
          push_word(Reg_PC);
          Reg_PC = DAR;
          break;
        case 0xBE:                  /* LDS ext */
          Reg_SP = fi32GetMemoryWord(fi32FetchWordIncPC());
          COND_SET_FLAG_N(Reg_SP >> 8);
          COND_SET_FLAG_Z(Reg_SP);
          CLR_FLAG(VF);
          break;
        case 0xBF:                  /* STS ext */
          fvPutMemoryWord(fi32FetchWordIncPC(), Reg_SP);
          COND_SET_FLAG_N(Reg_SP >> 8);
          COND_SET_FLAG_Z(Reg_SP);
          CLR_FLAG(VF);
          break;
        case 0xC0:                  /* SUB Reg_B imm */
          lo = fi32FetchByteIncPC();
          op1 = Reg_B;
          Reg_B = Reg_B - lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVs(op1, lo);
          break;
        case 0xC1:                  /* CMP Reg_B imm */
          op1 = fi32FetchByteIncPC();
          lo = Reg_B - op1;
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_C(lo);
          condevalVs(Reg_B, op1);
          lo &= 0xFF;
          COND_SET_FLAG_Z(lo);
          break;
        case 0xC2:                  /* SBC Reg_B imm */
          lo = fi32FetchByteIncPC() + get_flag(CF);
          Reg_B = Reg_B - lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVs(op1, lo);
          break;
        case 0xC4:                  /* AND Reg_B imm */
          Reg_B = (Reg_B & fi32FetchByteIncPC()) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xC5:                  /* BIT Reg_B imm */
          lo = (Reg_B & fi32FetchByteIncPC()) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0xC6:                  /* LDA Reg_B imm */
          Reg_B = fi32FetchByteIncPC();
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xC8:                  /* EOR Reg_B imm */
          Reg_B = (Reg_B ^ fi32FetchByteIncPC()) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xC9:                  /* ADC Reg_B imm */
          lo = fi32FetchByteIncPC() + get_flag(CF);
          Reg_B = Reg_B + lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVa(op1, lo);
          break;
        case 0xCA:                  /* ORA Reg_B imm */
          Reg_B = (Reg_B | fi32FetchByteIncPC()) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xCB:                  /* ADD Reg_B imm */
          lo = fi32FetchByteIncPC();
          op1 = Reg_B;
          Reg_B = Reg_B + lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVa(op1, lo); 
          break;
        case 0xCE:                  /* LDX imm */
           Reg_IX = fi32FetchWordIncPC();
          COND_SET_FLAG_N(Reg_IX >> 8);
          COND_SET_FLAG_Z(Reg_IX);
          CLR_FLAG(VF);
          break;
        case 0xD0:                  /* SUB Reg_B dir */
          lo = fi32GetMemoryByte( fi32FetchByteIncPC() );
          op1 = Reg_B;
          Reg_B = Reg_B - lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVs(op1, lo);
          break;
        case 0xD1:                  /* CMP Reg_B dir */
          lo = fi32GetMemoryByte( fi32FetchByteIncPC() );
          op1 = Reg_B - lo;
          COND_SET_FLAG_C(op1);
          op1 &= 0xFF;
          COND_SET_FLAG_N(op1);
          COND_SET_FLAG_Z(op1);
          condevalVs(Reg_B, lo);
          break;
        case 0xD2:                  /* SBC Reg_B dir */
          lo = fi32GetMemoryByte( fi32FetchByteIncPC() ) + get_flag(CF);
          Reg_B = Reg_B - lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVs(op1, lo);
          break;
        case 0xD4:                  /* AND Reg_B dir */
          Reg_B = (Reg_B & fi32GetMemoryByte( fi32FetchByteIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xD5:                  /* BIT Reg_B dir */
          lo = (Reg_B & fi32GetMemoryByte( fi32FetchByteIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0xD6:                  /* LDA Reg_B dir */
          Reg_B = fi32GetMemoryByte( fi32FetchByteIncPC() );
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xD7:                  /* STA Reg_B dir */
          fvPutMemoryByte(fi32FetchByteIncPC(), Reg_B);
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xD8:                  /* EOR Reg_B dir */
          Reg_B = (Reg_B ^ fi32GetMemoryByte( fi32FetchByteIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xD9:                  /* ADC Reg_B dir */
          lo = fi32GetMemoryByte( fi32FetchByteIncPC() ) + get_flag(CF);
          op1 = Reg_B;
          Reg_B = Reg_B + lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVa(op1, lo);
          break;
        case 0xDA:                  /* ORA Reg_B dir */
          Reg_B = (Reg_B | fi32GetMemoryByte( fi32FetchByteIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xDB:                  /* ADD Reg_B dir */
          lo = fi32GetMemoryByte( fi32FetchByteIncPC() );
          op1 = Reg_B;
          Reg_B = Reg_B + lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVa(op1, lo);
          break;
        case 0xDE:                  /* LDX dir */
          Reg_IX = fi32GetMemoryWord(fi32FetchByteIncPC());
          COND_SET_FLAG_N(Reg_IX >> 8);
          COND_SET_FLAG_Z(Reg_IX);
          CLR_FLAG(VF);
          break;
        case 0xDF:                  /* STX dir */
          fvPutMemoryWord(fi32FetchByteIncPC(), Reg_IX);
          COND_SET_FLAG_N(Reg_IX >> 8);
          COND_SET_FLAG_Z(Reg_IX);
          CLR_FLAG(VF);
          break;
        case 0xE0:                  /* SUB Reg_B ind */
          lo = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) );
          op1 = Reg_B;
          Reg_B = Reg_B - lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVs(op1, lo);
          break;
        case 0xE1:                  /* CMP Reg_B ind */
          op1 = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) );
          lo = Reg_B - op1;
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_C(lo);
          condevalVs(Reg_B, op1);
          lo &= 0xFF;
          COND_SET_FLAG_Z(lo);
          break;
        case 0xE2:                  /* SBC Reg_B ind */
          lo = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) ) + get_flag(CF);
          op1 = Reg_B;
          Reg_B = Reg_B - lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVs(op1, lo);
          break;
        case 0xE4:                  /* AND Reg_B ind */
          Reg_B = (Reg_B & fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xE5:                  /* BIT Reg_B ind */
          lo = (Reg_B & fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0xE6:                  /* LDA Reg_B ind */
          Reg_B = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) );
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xE7:                  /* STA Reg_B ind */
          fvPutMemoryByte(((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK), Reg_B);
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xE8:                  /* EOR Reg_B ind */
          Reg_B = (Reg_B ^ fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xE9:                  /* ADC Reg_B ind */
          lo = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) ) + get_flag(CF);
          op1 = Reg_B;
          Reg_B = Reg_B + lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVa(op1, lo);
          break;
        case 0xEA:                  /* ORA Reg_B ind */
          Reg_B = (Reg_B | fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xEB:                  /* ADD Reg_B ind */
          lo = fi32GetMemoryByte( ((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK) );
          op1 = Reg_B;
          Reg_B = Reg_B + lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVa(op1, lo);
          break;
        case 0xEE:                  /* LDX ind */
          Reg_IX = fi32GetMemoryWord(((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK));
          COND_SET_FLAG_N(Reg_IX >> 8);
          COND_SET_FLAG_Z(Reg_IX);
          CLR_FLAG(VF);
          break;
        case 0xEF:                  /* STX ind */
          fvPutMemoryWord(((fi32FetchByteIncPC() + Reg_IX) & cM6800_MAX_ADDR_MASK), Reg_IX);
          COND_SET_FLAG_N(Reg_IX >> 8);
          COND_SET_FLAG_Z(Reg_IX);
          CLR_FLAG(VF);
          break;
        case 0xF0:                  /* SUB Reg_B ext */
          lo = fi32GetMemoryByte( fi32FetchWordIncPC() );
          op1 = Reg_B;
          Reg_B = Reg_B - lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVs(op1, lo);
          break;
        case 0xF1:                  /* CMP Reg_B ext */
          op1 = fi32GetMemoryByte( fi32FetchWordIncPC() );
          lo = Reg_B - op1;
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_C(lo);
          condevalVs(Reg_B, op1);
          lo &= 0xFF;
          COND_SET_FLAG_Z(lo);
          break;
        case 0xF2:                  /* SBC Reg_B ext */
          lo = fi32GetMemoryByte( fi32FetchWordIncPC() ) + get_flag(CF);
          Reg_B = Reg_B - lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVs(op1, lo);
          break;
        case 0xF4:                  /* AND Reg_B ext */
          Reg_B = (Reg_B & fi32GetMemoryByte( fi32FetchWordIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xF5:                  /* BIT Reg_B ext */
          lo = (Reg_B & fi32GetMemoryByte( fi32FetchWordIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(lo);
          COND_SET_FLAG_Z(lo);
          break;
        case 0xF6:                  /* LDA Reg_B ext */
          Reg_B = fi32GetMemoryByte( fi32FetchWordIncPC() );
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xF7:                  /* STA Reg_B ext */
          fvPutMemoryByte(fi32FetchWordIncPC(), Reg_B);
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xF8:                  /* EOR Reg_B ext */
          Reg_B = (Reg_B ^ fi32GetMemoryByte( fi32FetchWordIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xF9:                  /* ADC Reg_B ext */
          lo = fi32GetMemoryByte( fi32FetchWordIncPC() ) + get_flag(CF);
          op1 = Reg_B;
          Reg_B = Reg_B + lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVa(op1, lo);
          break;
        case 0xFA:                  /* ORA Reg_B ext */
          Reg_B = (Reg_B | fi32GetMemoryByte( fi32FetchWordIncPC() )) & 0xFF;
          CLR_FLAG(VF);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          break;
        case 0xFB:                  /* ADD Reg_B ext */
          lo = fi32GetMemoryByte( fi32FetchWordIncPC() );
          op1 = Reg_B;
          Reg_B = Reg_B + lo;
          COND_SET_FLAG_C(Reg_B);
          Reg_B &= 0xFF;
          condevalHa(op1, lo);
          COND_SET_FLAG_N(Reg_B);
          COND_SET_FLAG_Z(Reg_B);
          condevalVa(op1, lo);
          break;
        case 0xFE:                  /* LDX ext */
          Reg_IX = fi32GetMemoryWord(fi32FetchWordIncPC());
          COND_SET_FLAG_N(Reg_IX >> 8);
          COND_SET_FLAG_Z(Reg_IX);
          CLR_FLAG(VF);
          break;
        case 0xFF:                  /* STX ext */
          fvPutMemoryWord(fi32FetchWordIncPC(), Reg_IX);
          COND_SET_FLAG_N(Reg_IX >> 8);
          COND_SET_FLAG_Z(Reg_IX);
          CLR_FLAG(VF);
          break;

       default:           /* Unassigned */
         Serial.println();
         Serial.print("M6800: Bad OpCode: ");
         fvOutputHex2( &Serial, i32ThisOpCode );
         Serial.print(" PC: ");
         fvOutputHex4( &Serial, Reg_PC );
         Serial.print(" SP: ");
         fvOutputHex4( &Serial, Reg_SP );
         Serial.print(" X: ");
         fvOutputHex4( &Serial, Reg_IX );
         Serial.print(" A: ");
         fvOutputHex2( &Serial, Reg_A );
         Serial.print(" B: ");
         fvOutputHex2( &Serial, Reg_B );
         Serial.print(" CC: ");
         fvOutputHex2( &Serial, Reg_CCR );
         Serial.println();
         iRunCount = 1; // Set up to go to into EMU menu next loop
         break;
        } // End: switch
    } // End: while (reason == 0)    /* Simulation halted - lets dump all the registers! */
    dump_state( &Serial );
    saved_PC = Reg_PC;
    return reason;
}


void fvPrintOperand( Stream * objStream, int32_t i32OpCode, int32_t i32ArgCount, int32_t i32PC, int32_t i32IX ) {
  int32_t i32Addr;
  int32_t i32ArgByte = i32PC;
  objStream->print(" ");
  if ( i32ArgCount < 0 ) return;

  // Check for Bxx (Branch) instruction (REL addressing)...
  if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_REL ) ) {
    // It IS Bxx, so work out branch address...
    i32ArgByte = fi32GetMemoryByte( i32PC + 1 );
    // Is it +ve or -ve ?...
    if ( ( i32ArgByte & 0x80 ) == 0x80 ) {
      i32ArgByte |= 0xFFFFFF00;  // Extend sign bit
    }
    objStream->print("L_");
    i32Addr = (i32PC + 2) + i32ArgByte;
    fvOutputHex4( objStream, i32Addr );
    objStream->print("  ; (");
    fvOutputHex2( objStream, i32ArgByte );
    objStream->print(")");
    // Set LABEL flag...
    fvUsageSet(i32Addr, cUSE_FLAG_LABEL);
  } else {
    if (i32ArgCount>0) objStream->print("$");
    for (int iAt=1; iAt <= i32ArgCount; iAt++) {
      i32ArgByte = fi32GetMemoryByte( i32PC + iAt );
      fvOutputHex2( objStream, i32ArgByte );
      // Set Operand (arguments) flag...
      fvUsageSet((i32PC + iAt ) & 0xFF, cUSE_FLAG_ARG);
    }
  }

  if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_IMM )
   && (i32ArgCount == 1) 
   && (i32ArgByte > ' ') 
   && (i32ArgByte < 0x7F)) {
    objStream->print("    ; #'");
    objStream->print((char)i32ArgByte);
  }

  if ( fbOpCodeTestFlag( i32OpCode, cOPCODE_ARG_IND ) ) {
    objStream->print(",X   ; (");
    fvOutputHex4( objStream, i32IX + i32ArgByte );
    objStream->print(")");
  }
  
}


void fvPrintTraceback( Stream * objStream ) {
  int32_t i32OpCode;
  objStream->println();
  for (int iAt=( iTraceCount - 1 ); iAt>=0; iAt--) {
    objStream->print("Back.");
    if (iAt<10) objStream->print("0");
    objStream->print(iAt);
    objStream->print(": PC=");
    fvOutputHex4( objStream, stTrace[iAt].i32PC );
    objStream->print(": ");

    i32OpCode = fi32GetMemoryByte( stTrace[iAt].i32PC );
    fvOutputHex2( objStream, i32OpCode );
    objStream->print(": ");
    // Set OpCode flag...
    fvUsageSet(stTrace[iAt].i32PC, cUSE_FLAG_CODE);

    // Label ?...
    if ( fbUsageTest(stTrace[iAt].i32PC,cUSE_FLAG_LABEL) ) {
      objStream->print("L_");
      fvOutputHex4( objStream, stTrace[iAt].i32PC );
      objStream->print(" ");
    } else {
     objStream->print("       ");
    }
    
    // Opcode name...
    objStream->print(fiOpCodeName(i32OpCode));
    if (strlen(fiOpCodeName(i32OpCode)) < 4) objStream->print(" ");
    objStream->print(" ");

    // Operand (arguments)...
    i32ThisOpArgCount = fiOpCodeArgCount( i32OpCode );
    fvPrintOperand( objStream, i32OpCode, i32ThisOpArgCount, stTrace[iAt].i32PC, stTrace[iAt].i32IX );
    objStream->println();
  } // End: for (...)
  dump_regs( objStream );
}

#if 1
/* dump the working registers */
void dump_state( Stream * objStream ) {
  int32_t i32OpCode;
  objStream->flush();
#if cNEWBEAR_7768
  objStream->println();
  objStream->println("M6800: 77-68");
#endif
  objStream->println();
  objStream->print("PC=");
  objStream->print(       Reg_PC-1 & 0xFFFF, HEX );
  i32OpCode=fi32GetMemoryByte(Reg_PC-1);
  objStream->print(" : ");
  fvOutputHex2( objStream, i32OpCode );
  i32ThisOpArgCount = fiOpCodeArgCount( i32OpCode );
  fvPrintOperand( objStream, i32OpCode, i32ThisOpArgCount, Reg_PC-1, Reg_IX );
  objStream->print(" : OP=");
  objStream->print(fiOpCodeName(i32OpCode));
  objStream->println();
  dump_regs( objStream );
}
#endif
void dump_regs( Stream * objStream ) {
#if 1
  objStream->print("PC=");
  fvOutputHex4( objStream, Reg_PC-1 & 0xFFFF );
  objStream->print(" ");
#endif  
  objStream->print("SP=");
  fvOutputHex4( objStream, Reg_SP );
  objStream->print(" X=");
  fvOutputHex4( objStream, Reg_IX );
  objStream->print(" A=");
  fvOutputHex2( objStream, Reg_A );
  objStream->print(" B=");
  fvOutputHex2( objStream, Reg_B );
  objStream->print(" CCR=");
  fvOutputHex2( objStream, Reg_CCR );
#if cNEWBEAR_7768
  // Get LEDs...
  objStream->print(" Switches:");
  fvOutputHex2( objStream, fi32GetMemoryByte(0xF0FF));
#endif
  objStream->println();
}

/* fetch an instruction or byte */
int32_t fi32FetchByteIncPC(void) {
  int32_t i32Val;
  i32Val = fi32GetMemoryByte(Reg_PC);   // fetch byte
  Reg_PC = (Reg_PC + 1) & cM6800_MAX_ADDR_MASK;           /* increment PC */
  return( i32Val );
}

/* fetch a word */
int32_t fi32FetchWordIncPC(void) {
  int32_t i32Val;
  i32Val = fi32GetMemoryByte(Reg_PC) << 8;     /* fetch high byte */
  i32Val |= fi32GetMemoryByte(Reg_PC + 1); /* fetch low byte */
  Reg_PC = (Reg_PC + 2) & cM6800_MAX_ADDR_MASK;           /* increment PC */
  return( i32Val );
}

/* push Reg_A byte to the stack */
void push_byte(unsigned char val) {
  fvPutMemoryByte(Reg_SP , val & 0xFF);
  Reg_SP = (Reg_SP - 1) & cM6800_MAX_ADDR_MASK;
}

/* push Reg_A word to the stack */
void push_word(uint16_t val) {
  push_byte(val & 0xFF);
  push_byte(val >> 8);
}

/* pop Reg_A byte from the stack */
unsigned char pop_byte(void) {
  register unsigned char res;
  Reg_SP = (Reg_SP + 1) & cM6800_MAX_ADDR_MASK;
  res = fi32GetMemoryByte(Reg_SP );
  return( res );
}

/* pop Reg_A word from the stack */
uint16_t pop_word(void) {
  register uint16_t res;
  res = pop_byte() << 8;
  res |= pop_byte();
  return( res );
}

/* this routine does the jump to relative offset if the condition is
   met.  Otherwise, execution continues at the current PC. */

void go_rel(int32_t cond) {
  int32_t temp;
  temp = get_rel_addr();
  if (cond) {
    Reg_PC += temp;
  }
  Reg_PC &= cM6800_MAX_ADDR_MASK;
}

/* returns the relative offset sign-extended */

int32_t get_rel_addr(void) {
  int32_t temp;
  temp = fi32FetchByteIncPC();
  if (temp & 0x80) {
    temp |= 0xFF00;
  }
  return( temp & cM6800_MAX_ADDR_MASK );
}


/* return 1 for flag set or 0 for flag clear */

int32_t get_flag(int32_t flg) {
  if (Reg_CCR & flg) return 1;
  return( 0 );
}


/* test and set V for addition */

void condevalVa(int32_t op1, int32_t op2)
{
    if (((op1 & 0x80) == (op2 & 0x80)) &&
        (((op1 + op2) & 0x80) != (op1 & 0x80))) 
        SET_FLAG(VF);
    else 
        CLR_FLAG(VF);
}

/* test and set V for subtraction */

void condevalVs(int32_t op1, int32_t op2)
{
    if ( ((op1 & 0x80) != (op2 & 0x80) ) 
     &&  (((op1 - op2) & 0x80) == (op2 & 0x80)) ) { 
      SET_FLAG(VF);
     } else {
      CLR_FLAG(VF);
     }
}

/* test and set H for addition */
void condevalHa(int32_t op1, int32_t op2) {
  if (((op1 & 0x0f) + (op2 & 0x0f)) & 0x10) {
    SET_FLAG(HF);
  } else { 
    CLR_FLAG(HF);
  }
}

/* Reset routine */

void m6800_reset (void)
{
    Reg_CCR = CCR_ALWAYS_ON | IF;
    int_req = 0;
//    sim_brk_types = sim_brk_dflt = SWMASK ('E');
    saved_PC = fi32GetMemoryWord(0xFFFE);
#if cM6800_SHOW_RESET_MESSAGE
 objStream->println();
 objStream->print("Reset PC to: ");
 objStream->print(saved_PC,HEX);
 objStream->println();
#endif
}
/* end of m6800.c */

#endif
