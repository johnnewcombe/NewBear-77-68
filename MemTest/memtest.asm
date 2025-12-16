;------------------------------------------------------------------
; MemTest.asm
; MemTest from MON1 documentation updated to run from F000
;
; Load and run memtest.ptp to F000 using MiniMon, e.g.
;
;   L F000
;   G F0FF
;
; Set LOMEM and HIMEM to desired memory range.
;------------------------------------------------------------------

RD_CMD  EQU $FC00 ; Inputs a character from the MiniMon prompt and echos the character. The routine restarts MiniMon if a full stop is entered. The value is returned in A.
PR_A    EQU $FC0F ; Sends the character in A to ACIA(a). Address T_R contains the number of characters printed.character
VHEX    EQU $FC1D ; Checks that A contains a HEX character
BINARY  EQU $FC31 ; Converts ASCII hex digits in A and B to binary?
ZIN     EQU $FC49 ; Reads a 2 digit hex value from ACIA(a) and puts it into A.
RD_X    EQU $FC65 ; Read 4 hex digits alue from ACIA(a) and put value into X.
STRING  EQU $FC76 ; Prints a string. The string should follow JSR and be terminated with $FF.
GETADD  EQU $FC89 ; Get Address, read 4 digit hex value.
ASCII   EQU $FC9E ; Convert value in A to 2 x ASCII hex digits in A and B.
PRX     EQU $FCBB ; Print value in X as 4 hex digits.
ZOUT    EQU $FCC9 ; Print value in A as 2 hex digits.
PUNCH   EQU $FDE2 ; Invokes the PUNCH command use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
LOAD    EQU $FCE3 ; Invokes the LOAD command use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
BIN     EQU $FD01 ; Inistialise ACIA(a) to 8N2 (MiniMon terminal originally used 7E1 for normal interaction).
RD_A    EQU $FD2B ; Read byte from ACIA.A to A.
REGPRT  EQU $FD36 ; Invoke the REGISTER PRINT Command, use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
PRSP    EQU $FD4D ; Prints a space.
BLKMOV  EQU $FD62 ; Invokes the BLOCK MOVE command.
SUB     EQU $FDD6 ; Subtract uses T_X 16 bit data area at F0E6.
PRP     EQU $FE33 ; Prints he string " P ".
PRD     EQU $FE3B ; Prints he string " D ".
MODIFY  EQU $FE43 ; Invokes the MODIFY command.
NEWLINE EQU $FE97 ; Prints a new line.
GO      EQU $FEC2 ; Invokes the GO command, This is an SW1 call.
CONTNU  EQU $FED9 ; Invokes the CONTINUE command, as THIS IS NOT A SUBROUTINE but restarts MiniMon.
DUMP    EQU $FF07 ; Invokes the DUMP command.
BRPTSET EQU $FF39 ; Invokes the SET BREAKPOINT command.terminal
HEADER  EQU $FF63 ; Prints the header used for the register display.
RESET   EQU $FF81 ; Resets ACIAs saves the callers stack pointer and restarts MiniMon.
SWI     EQU $FF8C ; Saves callers stack pointer and restarts MiniMon.
START   EQU $FF8F ; Restarts MniMon.

; Memory addresses

T_STRT  EQU $F0EF ; Temp storage for GETADDRESS
T_STOP  EQU $F0F1 ; Temp storage for GETADDRESS
T_Q     EQU $F0F6 ; Temp storage for ZIN,DUMP,MEMTEST

;IO

CTRLA   EQU $F401 ; ACIA.A Ctrl/Status
CTRLB   EQU $F403 ; ACIA.B Ctrl/Status
DATAA   EQU $F400 ; ACIA.A Data register
DATAB   EQU $F402 ; ACIA.B Data register

	    ORG $F000

MEMTEST
        JSR     PRCR
        JSR     GETADD      ; get the start and finish addresses
        CLRB                ; set up accumulators
.TST    PSHB
        JSR     PRCR
        PULB
        TBA
        JSR     ZOUT
        LDX     T_STRT      ; put start address in X
        CLRA
.LOOP1  ABA                 ; create the pattern
        STAA    0,X         ; Write to memory
        INX
        CPX     T_STOP      ; Check for end of memory
        BNE     .LOOP1
        LDX     T_STRT
        CLRA
.LOOP2  ABA
        CMPA     0,X        ; Read from memory
        BNE     .FAULT
.NOPR   INX
        CPX     T_STOP
        BNE     .LOOP2
        LDAA    CTRLA       ; Read ACIA status
        BITA    #$01        ; Key waiting?
        BNE     .END        ; Yes so end the test
        INCB                ; change the pattern and repeat
        BNE     .TST        ; we loop the test 256 times
.END    LDAA    DATAA       ; Clear a byte from ACIA
        JMP     START
.FAULT  JSR     NEWLINE
        JSR     STRING
        FCC     " FLT"
        FCB     $FF
        JMP     START
PRCR    JSR     STRING      ; CR
        FCB     $0D,$0A
        FCB     $FF
        RTS