; ----------------------------------------------------------------------------
; JMON (Jan. 2026)
; ----------------------------------------------------------------------------
;
; Created by GlassTTY, Jan. 2026, using MINIMON (ACH, Dec. 1978) as a base
; with additional code from Motorola's MIKBUG.
;
; Special thanks to Chris Carter for inspiration and help.
;
; ----------------------------------------------------------------------------
;
; This is a MINIMON compatible monitor for the 77-68 Bear/Newbear system with
; the LOAD and PUNCH commands replaced for versions that support the
; Motorola S Record Format (.s19) files.
;
; All entry points and source code labels as published in the MINIMON
; documentation have been preserved with the exception of the LOAD and PUNCH
; commands.
;
; In order to make space for the additional code required, the ALTER and
; OFFSET CALCULATION commands have been removed. This has been justified as
; the MODIFY command has very similar functionality to ALTER making ALTER
; unnecessary, and the OFFSET CALCULATION routines (commands X and Y) are
; rarely used as all cross-assemblers perform these calculations
; automatically. In addition BLOCKMOVE command (Cmd 'B') has been removed
; to allow for a memory test command to be added (Cmd 'T')'.
;
; One other minor change is that the terminal along with any devices sending
; S19 format files have been configured for 8 Data Bits, No Parity, 2 Stop
; Bits.
;
; ----------------------------------------------------------------------------

CTRLA   EQU     $F401   ; ACIA.A Ctrl/Status
CTRLB   EQU     $F403   ; ACIA.B Ctrl/Status
DATAA   EQU     $F400   ; ACIA.A Data register
DATAB   EQU     $F402   ; ACIA.B Data register

; -----------------------------------------------------
; Note:The original 256 bytes of RAM on the CPU board
;  appears at $F000 to $F0FE, with Switches/LEDs at $F0FF
;  when a MON1 board is installed
; -----------------------------------------------------
JNMI    EQU     $F0DD   ; 3 bytes for jump to NMI sub.
JIRQ    EQU     $F0E0   ; 3 bytes for jump to IRQ sub.
STACK   EQU     $F0D0   ; Stack goes down from $F0D0

; -----------------------------------------------------
        ORG     $F0D8
; -----------------------------------------------------
; $F0D1 to $F0DC APPREARS TO BE unused RAM
; -----------------------------------------------------

T_TW    RMB     2       ; New additions to support SRec
T_CSUM  RMB     1       ;            "
T_COUNT RMB     1       ;            "
T_TEMP  RMB     1       ;            "

; -----------------------------------------------------
        ORG     $F0E3   ; Start of RAM variables
; -----------------------------------------------------

T_SAVE  RMB     2       ; Temp storage for NEWLINE
T_P     RMB     1       ;   "     "     "  Z,X
T_X     RMB     2       ;   "     "     "  Sub
T_Y     RMB     2       ;   "     "     "  Sub
T_NEW   RMB     2       ;   "     "     "  Block move
T_M     RMB     1       ;   "     "     "  ZOUT
T_TMPX  RMB     2       ;   "     "     "  PRX
T_STRT  RMB     2       ;   "     "     "  GETADDRESS
T_STOP  RMB     2       ;   "     "     "  GETADDRESS
T_Z     RMB     2       ;   "     "     "   . RDX
T_R     RMB     1       ;   "     "     "     PR
T_Q     RMB     1       ;   "     "     "  ZIN,DUMP 
T_ABYT  RMB     2       ;   "     "     "  SET BR.PT.
        RMB     2       ;   "     "     "  SET BR.PT.
T_BYTE  RMB     2       ;   "     "     "  SET BR.PT.
PSTACK  RMB     2       ;   "     "     "     SWI etc

; -----------------------------------------------------
        ORG     $FC00   ; Start of ROM based code
; -----------------------------------------------------

; -----------------------------------------------------
; Read Character from ACIA
; FC00
; -----------------------------------------------------
RD_CMD  JSR     RD_A    ; Input one character
        BEQ     RD_CMD  ; Ignore paper tape follower
        BSR     PR_A    ; Echo character
        CMPA    #'.     ; Was it a fullstop ?
        BNE     PRA_END ;
        JMP     START   ; Yes: Go to start of MINIMON

        NOP

; -----------------------------------------------------
; Print character in A
; FC0F
; -----------------------------------------------------
PR_A    LDAB    CTRLA   ; Get ACIA(a) status byte
        BITB    #02     ; Is it busy ?
        BEQ     PR_A    ; Yes: Try again
        STAA    DATAA   ;  No: Send data
        INC     T_R     ; Characters printed + One
PRA_END RTS             ; RETURN

; -----------------------------------------------------
; Check A contains a HEX character,  Set C.bit on fail
; FC1D
; -----------------------------------------------------
VHEX    CMPA    #$2F    ; A < 30 ?
        BLE     NotHex  ;  not hex
        CMPA    #$39    ; A > 39 ?    
        BHI     NotNum  ;  Not a Numeral
IsHex   CLC             ; It's OK (clear C bit)
        RTS             ; RETURN
NotNum  CMPA    #$40    ; A < 41 ?
        BLE     NotHex  ;  not hex
        CMPA    #$46    ; A <= 46
        BLE     IsHex   ;  then it is hex
NotHex  SEC             ; Set C bit
        RTS             ; RETURN

; -----------------------------------------------------
; Convert A:B to binary
; FC31
; -----------------------------------------------------
BINARY  BITA    #$30    ; Is it a letter ?
        BEQ     LETTA   ; Yes: Got to handle it
RIDA    ASLA            ;  No: It is a number, so
        ASLA            ;      shift
        ASLA            ;       left
        ASLA            ;        4 bits
        BITB    #$30    ; Is Acc.B a letter ?
        BEQ     LETTB   ; Yes: Go handle it
RIDB    ANDB    #$0F    ; Clear 4 high bits in Acc.B
        ABA             ; Form binary character (A=A+B)
        RTS             ; RETURN
LETTA   ADDA    #$09    ; Make Acc.A a binary
        BRA     RIDA    ;  as before
LETTB   ADDB    #$09    ; Make Acc.B a binary
        BRA     RIDB    ;  as before

; -----------------------------------------------------
; Read a 4 digit HEX value, put result into X
; FC49
; -----------------------------------------------------
ZIN     BSR     RD_CMD  ; Read a character
        BSR     VHEX    ; Is it a hex character ?
        BCS     Z_PRQM  ; No: go to print `?`
        STAA    T_Q     ; Save it
        BSR     RD_CMD  ; Read 2nd character
        BSR     VHEX    ; Is it a hex character ?
        BCS     Z_PRQM  ; No: go to print `?`
        TAB             ; Yes: Put it into B
        LDAA    T_Q     ; Retrieve 1st hex char to A
        JMP     ZIN2    ; S19 version of ZIN is longer
Z_PRQM  JSR     PR_QM   ; Print "?"
        JMP     ZIN     ; Go back to start of hex input

; -----------------------------------------------------
; Read 4 hex digits and put value into X
; FC65
; -----------------------------------------------------
RD_X    JSR     PRSP    ; Print a space
        BSR     ZIN     ; Read 2 digit hex value into A
        STAA    T_Z     ; Save byte (most significant)
        BSR     ZIN     ; Read 2 digit hex value into A
        STAA    T_Z+1   ; Save byte (least significant)
        LDX     T_Z     ; Load full 4 hex value into X
        RTS             ; RETURN

; -----------------------------------------------------
; Print string FOLLOWING JSR ( terminated by $FF )
;  IE: It starts at the `return addr` put onto the stack by JSR
;  So actual return address needed is past the string
; FC76
; -----------------------------------------------------
STRING  TSX             ; Get loc. of return addr to X
        LDX     0,X     ; Get return addr to X
        DEX             ; Point to byte before
AGAIN   INX             ; Point to next byte
        LDAA    0,X     ; Get byte to be printed
        CMPA    #$FF    ; End-string ?
        BEQ     ENDSTR  ; Yes: Go to finish up
        BSR     PR_A    ; Print the byte
        BRA     AGAIN   ; Go back for next byte
ENDSTR  INS             ; Clean up stack...
        INS             ;  ( pop off the return addr )
        JMP     1,X     ; Jump back to caller (RETURN)

; -----------------------------------------------------
; FC89
; -----------------------------------------------------
GETADD  BSR     STRING  ; Print string...
        FCC     " S"    ;
        FCB     $FF     ; End-of-string
        BSR     RD_X    ; Read 4 digit HEX addr value
        STX     T_STRT  ; Save it
        BSR     STRING  ; Print string...
        FCC     " F"    ;
        FCB     $FF     ; End-of-string
        BSR     RD_X    ; Read 4 digit HEX addr value
        STX     T_STOP  ; Save it
        RTS             ; RETURN

; -----------------------------------------------------
; Convert value in A to 2 x ASCII hex digits in A and B
; FC9E
; -----------------------------------------------------
ASCII   TAB             ; Copy A to B
        ANDA    #$F0    ; Clear low order 4 bits of A
        LSRA            ; Shift
        LSRA            ;  right
        LSRA            ;   4
        LSRA            ;    bits
        CMPA    #$09    ; Letter or number ?
        BHI     SUBT    ; 
        ADDA    #$30    ; Make it an ASCII number
AND     ANDB    #$0F    ; Clear high order bits of B
        CMPB    #$09    ; Letter or number ?
        BHI     ADD     ;
        ADDB    #$30    ; Make it an ASCII number
        RTS             ; RETURN
SUBT    ADDA    #$37    ; Make it an ASCI letter
        BRA     AND     ; Go to process low order value
ADD     ADDB    #$37    ; Make it an ASII letter
        RTS             ; RETURN

; -----------------------------------------------------
; Print value in X as 4 hex digits
; FCBB
; -----------------------------------------------------
PRX     STX     T_TMPX  ; Save X
        LDAA    T_TMPX  ; Get high order byte to A
        BSR     ZOUT    ; Print A as 2 hex digits
        LDAA    T_TMPX+1; Get low order byte to A
        BRA     ZOUT    ; Print A as 2 hex digits

        NOP

; -----------------------------------------------------
; Print value in A as 2 hex digits, Preserve B
; X unchanged by called routines
; This is 1 byte shorter that original ZOUT
; FCC9
; -----------------------------------------------------
ZOUT    PSHB            ; Save B to STACK
        PSHA            ; Save A to STACK
        BSR     ASCII   ; Convert A to ASCII in A & B
        PSHB            ; Save B (2nd byte) to STACK
        JSR     PR_A    ; Print byte in A
        PULA            ; Get 2nd byte into A from STACK
        JSR     PR_A    ; Print byte in A
        PULA            ; Recover A from STACK
        PULB            ; Recover B from STACK
        RTS             ; RETURN


; second part of S19 version of ZIN
ZIN2    JSR     BINARY  ; Convert A:B to binary to A
        TAB             ; B=A
        ADDB    T_CSUM  ; Add this value
        STAB    T_CSUM  ; to the Checksum (for S19)
        RTS             ; RETURN

; -----------------------------------------------------
; S19 format data load : Modded version of Mikbug code
; FCE3
; -----------------------------------------------------
LOAD    EQU     *       ; L = Load = Input an S19 file
        BSR     STRING
        FCB     $0D,$0A ; c/r l/f
        FCB     $FF     ; End-Of-String
LREAD   JSR     RD_CMD  ; Read+Echo, test for '.'
        CMPA    #'S     ; Is it `S` ?
        BNE     LREAD   ; No: Keep waiting for `S`
        JSR     RD_CMD  ; Read+Echo, test for '.'
        CMPA    #'9     ; Is it `9` ?  ( `S9` record )
        BNE     LREAD1
        JMP     STERMR  ; handle termination record
LREAD1  CMPA    #'1     ; Is it `1` ?  ( `S1` record )
        BNE     LREAD   ; No: Wait for next `S`
        CLR     T_CSUM  ; Clear checksum
        JSR     ZIN     ; Read 2xHex = data.byte count to A
        SUBA    #2      ; Subtract 2 (to get bytes left in line)
        STAA    T_COUNT ; Store byte count
        JSR     RD_X    ; Read 4xHex digit address to X
LDOBYT  JSR     ZIN     ; Read 2xHex digits, value to A
        DEC     T_COUNT ; Decrement our byte count
        BEQ     LCHK    ; If end-of-line, go look at checksum
        STAA    0,X     ; Save byte where X points
        INX             ; Point X at next byte
        BRA     LDOBYT  ; Go get next byte
LCHK    INC     T_CSUM  ; Add 1 to checksum
        BEQ     LREAD   ; OK: Go read next record
        BSR     PR_QM   ; Print "?"
        BRA     STARTR  ; Go to START

PR_QM   LDAA #'?        ; Put '?' character in A
        JMP     PR_A    ; Print it and return via PR_As RTS

        NOP
        NOP
        NOP
        NOP
        NOP

; -----------------------------------------------------
; Read byte from ACIA.A to A
; FD2B
; -----------------------------------------------------
RD_A    LDAA    CTRLA   ; Get ACIA.A status byte
        BITA    #$01    ; Is byte ready in DATAA
        BEQ     RD_A    ; No: Try again
        JMP     PARITY  ; Need to clear parity as we
                        ; need to support 7E2 & 8N2

        NOP

; -----------------------------------------------------
; FD36
; -----------------------------------------------------
REGPRT  BSR     PRSP    ; Print a space
        LDX     PSTACK  ; Point X at user's stack
        BSR     PR2     ; Print CC
        BSR     PR2     ; Print B
        BSR     PR2     ; Print A
        BSR     PR4     ; Print X
        BSR     PR4     ; Print PC
        LDX     #PSTACK ; Point X at stack pointer
        BSR     PR4X    ; Print stack pointer
STARTR  JMP     START  ; (RETURN) to MINIMON


; -----------------------------------------------------
; FD4D
; -----------------------------------------------------
PRSP    LDAA    #$20    ; Put space character in A
        JSR     PR_A    ; Print it
        RTS             ; RETURN
PR4     INX             ; Point X to next character
PR4X    LDAA    0,X     ; Get byte pointed to by X
        JSR     ZOUT    ; Print it
PR2     INX             ; Point X to next character
        LDAA    0,X     ; Get byte pointed to by X
        JSR     ZOUT    ; Print it
        BSR     PRSP    ; Print a space
        RTS             ; RETURN

; -----------------------------------------------------
; FD62
; -----------------------------------------------------
MEMTEST JSR     GETADD      ; get the start and finish addresses
        JSR     STRING
        FCC     " TESTING..."
        FCB     $0D,$0A,$FF
        CLRB                ; set up accumulators
.TST    PSHB
        JSR     STRING
        FCB     $0D,$FF
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
        JSR     STRING
        FCC     " OK"
        FCB     $FF
        JMP     START
.FAULT  JSR     NEWLINE
        JSR     STRING
        FCC     " FLT"
        FCB     $FF
        JMP START

; -----------------------------------------------------
; FDC3
; -----------------------------------------------------
VERSION JSR     STRING
        FCC     " 1.00" ;
        FCB     $FF
        JMP     START

PARITY  LDAA    DATAA   ; Get the data byte to A
        ANDA    #$7F    ; Mask off parity bit if it exists
        RTS             ; RETURN

        NOP

; -----------------------------------------------------
; FDD6
; -----------------------------------------------------
SUB     LDX     #T_X    ; Point X to start of T_X data
        LDAA    1,X     ; A = T_X (low)
        LDAB    0,X     ; B = T_X (high)
        SUBA    3,X     ; A = A - T_Y (low)
        SBCB    2,X     ; B = B - T_Y (high)
        RTS             ; RETURN

; -----------------------------------------------------
; S format data output : Modded version of Mikbug code
; -----------------------------------------------------
PUNCH   JSR     GETADD      ; Prompt for "Start:","Stop:"
        LDX     T_STRT      ; Get start address
        STX     T_TW        ; save it to work area
POUT1   LDAA    T_STOP+1    ; get low order of end address
        SUBA    T_TW+1      ; Subtract low order start
        LDAB    T_STOP      ; ( carry not affected by LDA )
        SBCB    T_TW        ; Subtract with Carry
        BNE     POUT2
        CMPA    #16
        BCS     POUT3
POUT2   LDAA    #15
POUT3   ADDA    #4
        STAA    T_COUNT     ; FRAME COUNT THIS RECORD
        SUBA    #3
        STAA    T_TEMP      ; BYTE COUNT THIS RECORD
        JSR     STRING      ; Output this string...
        FCB     $0D,$0A     ; c/r l/f
        FCB     'S,'1       ; S1
        FCB     $FF         ; End-Of-String
        CLRB                ; Clear checksum

; Output frame count...
        LDX     #T_COUNT    ; X = Address of Framecount
        JSR     POUTH2      ; O/P byte <-X and inc X

; Output address...
        LDX     #T_TW
        JSR     POUTH2      ; O/P byte <-X and inc X
        JSR     POUTH2      ; O/P byte <-X and inc X

; Output data...
        LDX     T_TW
POUT4   JSR     POUTH2      ; O/P byte <-X and inc X
        DEC     T_TEMP      ; Decrement `bytes left` count
        BNE     POUT4       ; Loop back if any left
        STX     T_TW
        COMB
        PSHB
        TSX                ; X = S + 1
        BSR     POUTH2     ; PUNCH CHECKSUM
        PULB
        LDX     T_TW
        DEX
        CPX     T_STOP
        BNE     POUT1
        JMP     STERMS

        NOP
        NOP

; -----------------------------------------------------
; FE43
; -----------------------------------------------------
MODIFY  JSR     RD_X    ; Get address to X
STRT    JSR     PRSP    ; Print a space
        CLR     T_R     ; T_R = 0
PRz     LDAA    0,X     ; Get byte pointed to by X to A
        JSR     ZOUT    ; Print it as 2.hex digits
WATSIT  JSR     RD_CMD  ; Get command character
WHAT    CMPA    #$20    ; Is it a space ?
        BNE     ISSLSH  ; No: go test for slash
CARYON  INX             ; Increment X
        LDAA    T_R     ; A = T_R
        CMPA    #$16    ; At end of line ?
        BLE     PRz     ; No: Loop back to continue
NEW_1   BSR     NEWLINE ; Print c/r l/f nul
        BRA     STRT    ; Loop back (Note: Hex was wrong in doc, E2 instead of E5)

ISSLSH  CMPA    #'/     ; Is it a slash ?
        BNE     ISCRET  ; No: go test for c/r
        DEX             ; X = X - 1
        BRA     NEW_1   ; Loop back (print newline)

ISCRET  CMPA    #$0D    ; Is it a c/r ?
        BNE     ISHEX   ; No: go test for valid Hex
        INX             ; X = X + 1
        BRA     NEW_1   ; Loop back (print newline)

ISHEX   JSR     VHEX    ; Is it a valid hex character ?
        BCS     PRQM    ; No: print `?` and ignore
        STAA    T_Q     ; T_Q = A : Save it
        JSR     RD_CMD  ; Get 2nd character
        JSR     VHEX    ; Is it a valid hex character ?
        BCS     WHAT    ; No: then see what it is
        TAB             ; B = A
        LDAA    T_Q     ; A = T_Q
        JSR     BINARY  ; Convert to binary value
        STAA    0,X     ; Store it
        JSR     PRSP    ; Print a space
        BRA     CARYON  ; Loop back

PRQM    LDAA    #'?     ; Put `?` into A
        JSR     PR_A    ; Print it
        BRA     WATSIT  ; Loop back

NEWLINE STX     T_SAVE  ; Save X
        JSR     STRING  ; Print string...
        FCB     $0D,$0A,$00
        FCB     $FF     ; End-of-string
        LDX     T_SAVE  ; Restore X
        JSR     PRX     ; Print X
        RTS             ; RETURN

POUTH2 ADDB    0,X      ; Update checksum
        PSHA            ; Push A to STACK
        LDAA    0,X     ; Load byte to be o/p
        JSR     ZOUT    ; O/P byte <- X
        PULA            ; Pull A off STACK
        INX             ; Increment X
        RTS             ; RETURN

; Processes the termination record which, if we get here is an S9 record
; A will contain the umber of bytes to follow (should be 39h i.e. ASCII '9')
; which means there are left to absorb.
STERMR  LDX     #8      ; get the number of bytes left in record
STERM1  JSR     RD_CMD  ; read and echo from ACIA and ignore
        DEX
        BNE     STERM1   ; loop for remaining bytes
STARTS  JMP     START

        NOP
        NOP
        NOP

; -----------------------------------------------------
; FEC2
; -----------------------------------------------------
GO      JSR     RD_X    ; Get address to X (16.bit)
        JSR     RD_CMD  ; Right address ?
        LDAA    T_Z+1   ; T_Z.low to A
        LDAB    T_Z     ; T_Z.high to B
GOTO    LDX     PSTACK  ; Callers stack address to X
        STAA    7,X     ; Put new return
        STAB    6,X     ; address on stack
        LDS     PSTACK  ; Set up calling programs stack
        RTI             ; RETURN-FROM-INTERRUPT (SWI)

; -----------------------------------------------------
; FED9
; -----------------------------------------------------
CONTNU  JSR     RD_CMD  ; Read a byte (test for `.`)
        CMPA    #'1     ; Is it `1` ?
        BNE     IsIt2  ; No: go test for `2`
        LDX     T_ABYT  ; Get address of break.point
        LDAA    T_BYTE  ; Get saved opcode
        STAA    0,X     ; Put it back in the program
        LDAA    T_ABYT+1 ; Get address at which
        LDAB    T_ABYT  ;   to re-enter program
        BRA     GOTO    ; Go to calling program

IsIt2   CMPA    #'2     ; Is it `2`
        BEQ     G_Is2   ; Yes: go process it
        JMP     START   ; No: Return to MINIMON
G_Is2   LDX     T_ABYT+2 ; Get addr. of break.point 2
        LDAA    T_BYTE+1 ; Get old opcode
        STAA    0,X      ; Put it back
        LDAA    T_ABYT+3 ; Load address to start
        LDAB    T_ABYT+2 ;  running program at
        BRA     GOTO    ; Run user program

; -----------------------------------------------------
; FF07
; -----------------------------------------------------
DUMP    JSR     GETADD  ; Prompt for boundary addresses
        LDX     T_STRT  ;
D_NEW   JSR     NEWLINE ; Print c/r l/f nul
        LDAA    #$08    ;
        STAA    T_Q     ; T_Q = 8
        DEX             ; X = X - 1
D_NXT   INX             ; X = X + 1
        JSR     PRSP    ; Print a space
        LDAA    0,X     ; Get a byte
        JSR     ZOUT    ; Print it as 2.hex digits
        CPX     T_STOP  ; Finished ?
        BNE     D_CNT   ; No: Carry on
D_END   LDAA    DATAA   ; Get a byte from ACIA (clear)
        JMP     START   ; Return to MINIMON
D_CNT   LDAA    CTRLA   ; Read ACIA status
        BITA    #$01    ; Stop dump ?
        BNE     D_END   ; Yes; go clear ACIA etc
        DEC     T_Q     ; New line needed ?
        BNE     D_NXT   ; No: Loop back
        INX             ; Print next byte
        BRA     D_NEW   ;  on a new line

; -----------------------------------------------------
; FF39
; -----------------------------------------------------
BRPTSET JSR     RD_CMD  ; Read a byte (test for `.`)
        CMPA    #'1     ; Is it `1` ?
        BNE     Is2b    ; No: go test for `2`
        JSR     RD_X    ; Read addr value into X
        LDAA    0,X     ; Get the opcode
        STAA    T_BYTE  ; Save it
        STX     T_ABYT  ; and the address
SAME    LDAA    #$3F    ; `SWI` opcode :
        STAA    0,X     ;   set the breakpoint
ENDB    JMP     START   ; Return to MINIMON
Is2b    CMPA    #'2     ; Is it `2` ?
        BNE     ENDB   ; No: Return to MINIMON
        JSR     RD_X    ; Read address into X
        LDAA    0,X     ; Get opcode
        STAA    T_BYTE+1 ; Save it
        STX     T_ABYT+2 ; Save address
        BRA     SAME    ; Set the breakpoint

; -----------------------------------------------------
; FF63
; -----------------------------------------------------
HEADER  JSR     STRING  ; print string...
        FCC     " CC"   ;
        FCC     " B "   ;
        FCC     " A "   ;
        FCC     "  X"   ;
        FCC     "   "   ;
        FCC     " PC"   ;
        FCC     "   "   ;
        FCC     "SP"    ;
        FCB     $FF     ; End-of-string
        BRA     START   ; Return to MINIMON

        NOP

; -----------------------------------------------------
; FF81
; -----------------------------------------------------
RESET   LDS     #STACK  ; Set up stack for MINIMON
        LDAA    #$03    ; Reset:
        STAA    CTRLA   ;   ACIA.A
        STAA    CTRLB   ;   ACIA.B

; -----------------------------------------------------
; FF8C
; -----------------------------------------------------
SWI     STS     PSTACK  ; Save callers stack pointer

; -----------------------------------------------------
; FF8F
; -----------------------------------------------------
START   LDS     #STACK  ; Set up stack for JMON
        BSR     SETACIA ; Set up ACIAs
        JSR     STRING  ; Print string...
        FCB     $0D,$0A,$00,'*    ; c/r l/f null `*`
        FCB     $FF     ; End-of-string
        JSR     RD_CMD  ; Read a byte (test for `.`)
        LDX     #CMDTAB ; point to command table
CMDLP   LDAB    0,X     ; B = key byte (0 ends table)
        BEQ     START   ; end of table → default to START
        CBA             ; compare A vs B
        BEQ     FOUND   ; match → dispatch
        INX             ; skip key
        INX             ; skip FDB high
        INX             ; skip FDB low
        BRA      CMDLP  ; try next entry

FOUND   LDAB    1,X     ; B = target high byte (FDB stores high,low)
        LDAA    2,X     ; A = target low byte
        PSHA            ; push high first
        PSHB            ; push low — now low is on top of stack
        RTS             ; jump to target

; Command table: key, then FDB routine
CMDTAB  FCB     'S
        FDB     BRPTSET
        FCB     'H
        FDB     HEADER
        FCB     'P
        FDB     PUNCH
        FCB     'L
        FDB     LOAD
        FCB     'R
        FDB     REGPRT
        FCB     'M
        FDB     MODIFY
        FCB     'G
        FDB     GO
        FCB     'C
        FDB     CONTNU
        FCB     'D
        FDB     DUMP
        FCB     'T'
        FDB     MEMTEST
        FCB     'V'
        FDB     VERSION
        FCB     0       ; terminator
        FDB     START   ; not used (any value ok after 0)

; Transmit an address '0000' S9 terminating record
STERMS  JSR     STRING
        FCB     $0D,$0A
        FCC     "S9030000FC"
        FCB     $FF
        BRA     START

; Reset the ACIAs
SETACIA LDAA    #$11    ; 8 Data, No Parity, 2 Stop Bits
        STAA    CTRLA   ;   ACIA.A
        LDAA    #$01    ; 7 Data, Even Parity, 2 Stop Bits
        STAA    CTRLB   ;   ACIA.B
        RTS

        NOP
        NOP

; -----------------------------------------------------
; Vectors
; FFF8
; -----------------------------------------------------
        FDB     JIRQ    ; IRQ
        FDB     SWI     ; SWI
        FDB     JNMI    ; NMI
        FDB     RESET   ; Reset

;       The End

