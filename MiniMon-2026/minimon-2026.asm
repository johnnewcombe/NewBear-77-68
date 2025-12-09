; ------------------------------------------------------
; Minimon
; ------------------------------------------------------
;  Original author ACH, Dec.1978;
; ------------------------------------------------------
; 13 NOV 2025 : [JN] added NOP at FFF7 to remove gap to
;             : allow easier conversion to bin from s19
; 05 DEC 2025 : [JN] Changed ACIA(a) to be 8N2 to match
;             : PROM. So that MiniMon can be loaded and
;             : run from the same terminal config.
; ------------------------------------------------------
; 2 x ACIAs :-
;

CTRLA   EQU     $F401   ; ACIA.A Ctrl/Status
CTRLB   EQU     $F403   ; ACIA.B Ctrl/Status
DATAA   EQU     $F400   ; ACIA.A Data register
DATAB   EQU     $F402   ; ACIA.B Data register

; Note:The original 256 bytes of RAM on the CPU board 
;  appears at $F000 to $F0FE, with Switches/LEDs at $F0FF
;  when a MON1 board is installed

; Stack goes down from $F0D0
STACK   EQU     $F0D0   ; Top of MINIMON's stack



; RAM at $F0D1 to $F0DC appears to be unused

; 3 bytes reserved for each if NMI and IRQ handling
; so an application can write JMP <addr> into those
; places if those interrupts are wanted...

JNMI    EQU     $F0DD   ; Space for jump to NMI sub.
JIRQ    EQU     $F0E0   ; Space for jump to IRQ sub.

; -----------------------------------------------------
        ORG     $F0D5   ; Start of RAM variables
; -----------------------------------------------------
; Note: Temp storage variables renamed to get T_ prefix
;       as some were sharing names with labels or registers
;
; New additions to support S19 additions
d_RdFstX    RMB     2       ;  "  RD_ByteFast X
d_Hx4X      RMB     2       ;  "  RDX4 PRX4
d_TW        RMB     2       ;  "  S19
d_STOP      RMB     2       ;  "  ASK_Addrs `Stop:`
b_Csum      RMB     1       ;  "  S19
b_Count     RMB     1       ;  "  S19
b_Temp      RMB     1       ;  "  S19
d_START     RMB     2       ;  "  ASK_Start `Start:`
b_Q         RMB     1       ;  "  ZIN,DUMP

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



;
; -----------------------------------------------------
        ORG     $EC00   ; Start of ROM based code
; -----------------------------------------------------
RD_CMD  JSR     RD_A    ; Input one character 
        BEQ     RD_CMD  ; Ignore paper tape follower
        BSR     PR_A    ; Echo character
        CMPA    #'.     ; Was it a fullstop ?
        BNE     END_RD  ;
        JMP     START   ; Yes: Go to start of MINIMON
END_RD  RTS             ;  No: RETURN

; -----------------------------------------------------
; Print character in A

PR_A    LDAB    CTRLA   ; Get ACIA(a) status byte
        BITB    #02     ; Is it busy ?
        BEQ     PR_A    ; Yes: Try again
        STAA    DATAA   ;  No: Send data
        INC     T_R     ; Characters printed + One
        RTS             ; RETURN

; -----------------------------------------------------
; Check A contains a HEX character,  Set C.bit on fail

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

        RMB 26

;ZIN     BSR     RD_CMD  ; Read a character
;        BSR     VHEX    ; Is it a hex character ?
;        BCS     Z_PRQM  ; No: go to print `?`
;        STAA    T_Q     ; Yes: Save Acc.A
;        BSR     RD_CMD  ; Read 2nd character
;        BSR     VHEX    ; Is it a hex character ?
;        BCS     Z_PRQM  ; No: go to print `?`
;        TAB             ; Yes: Put it into Acc.B
;        LDAA    T_Q     ; Retrieve 1st hex char to Acc.A
;        BSR     BINARY  ; Convert A:B to binary
;        RTS             ; RETURN
;Z_PRQM  LDAA    #'?     ; Load `?` into A
;        BSR     PR_A    ; Print it
;        BRA     ZIN     ; Go back to start of hex input

; -----------------------------------------------------
; Read 4 hex digits and put value into X
;FC65
RD_X    JSR     PRSP    ; Print a space
        JSR     ZIN     ; Read 2 digit hex value into A
        STAA    T_Z     ; Save byte (most significant)
        JSR     ZIN     ; Read 2 digit hex value into A
        STAA    T_Z+1   ; Save byte (least significant)
        LDX     T_Z     ; Load full 4 hex value into X
        RTS             ; RETURN

; -----------------------------------------------------
; Print string FOLLOWING JSR ( terminated by $FF )
;  IE: It starts at the `return addr` put onto the stack by JSR
;  So actual return address needed is past the string

;fc76
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
; 
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

PRX     STX     T_TMPX  ; Save X
        LDAA    T_TMPX  ; Get high order byte to A
        JSR     ZOUT    ; Print A as 2 hex digits
        LDAA    T_TMPX+1 ; Get low order byte to A
        JSR     ZOUT    ; Print A as 2 hex digits
        RTS             ; RETURN

; -----------------------------------------------------
; Print value in A as 2 hex digits

        RMB 13

;ZOUT    BSR     ASCII   ; Convert A to ASCII in A & B
;        STAB    T_M     ; Save B
;        JSR     PR_A    ; Print byte in A
;        LDAA    T_M     ; Get 2nd byte into A
;        JSR     PR_A    ; Print byte in A
;        RTS             ; RETURN

; -----------------------------------------------------

PUNCH
        RMB 47

; -----------------------------------------------------
LOAD
        RMB 36          ; spare byes

; -----------------------------------------------------
; Read byte from ACIA.A to A
;FD2B
RD_A    LDAA    CTRLA   ; Get ACIA.A status byte
        BITA    #$01    ; Is byte ready in DATAA
        BEQ     RD_A    ; No: Try again
        LDAA    DATAA   ; Get the data byte to A
        RTS             ; RETURN

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
        JMP     START   ; (RETURN) to MINIMON

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
BLKMOV  JSR     GETADD  ; Prompt for boundary addresses
        JSR     STRING  ; Print string...
        FCC     " To"   ;
        FCB     $FF     ; End-of-string
        JSR     RD_X    ; Read 4 hex digit value into X
        STX     T_NEW   ; Store it as NEW start address
        STX     T_X     ;   "    "
        LDX     T_STRT  ; Put start address into X
        STX     T_Y     ; Store it
        BSR     SUB     ; Perform T_X minus T_Y
        BPL     DOWN    ; Go to Move downwards
        LDX     T_STOP  ; Get the STOP stop address
        INX             ; Add 1 to it
        STX     T_STOP  ; and save it
DO_UP   LDX     T_STRT  ; Get START address
        CPX     T_STOP  ; Compare it with STOP
        BNE     CONT_A  ; Finished ?
STARTB  JMP     START   ; Yes: back to MINIMON
CONT_A  LDAA    0,X     ; No: Get data
        INX             ; Point X to next `old` address
        STX     T_STRT  ; and store it
        LDX     T_NEW   ; get address of NEW location
        STAA    0,X     ; Store the data at NEW address
        INX             ; Point X to next `new` address
        STX     T_NEW   ; and store it
        BRA     DO_UP   ; loop back for next byte
DOWN    LDX     T_STOP  ; Get end address
        STX     T_X     ; Store it
        BSR     SUB     ; Perform T_X minus T_Y
        ADDA    T_NEW+1 ; Add NEW (low.byte) to A
        ADDB    T_NEW   ; Add NEW (high.byte) to B
        STAA    T_NEW+1 ; Save NEW (low.byte)
        STAB    T_NEW   ;         (high.byte)
        LDX     T_STRT  ; Get START address
        DEX             ; Subract 1 from X
        STX     T_STRT  ; Store it
DO_DOWN LDX     T_STOP  ; Get STOP address
        CPX     T_STRT  ; Compare it with START address
        BEQ     STARTB  ; Effecively `JMP START`
        LDAA    0,X     ; Get data
        DEX             ; Subract 1 from X
        STX     T_STOP  ; Store it
        LDX     T_NEW   ; Load NEW loc address into X
        STAA    0,X     ; Store the data as NEW address
        DEX             ; Point X to next `new` address
        STX     T_NEW   ; Store it
        BRA     DO_DOWN ; Loop back for next byte

; -----------------------------------------------------
SUB     LDX     #T_X    ; Point X to start of T_X data
        LDAA    1,X     ; A = T_X (low)
        LDAB    0,X     ; B = T_X (high)
        SUBA    3,X     ; A = A - T_Y (low)
        SBCB    2,X     ; B = B - T_Y (high)
        RTS             ; RETURN

        RMB 81          ; previously X and Z commands

; -----------------------------------------------------
;FE33
PRP     JSR     STRING  ; Print string...
        FCC     " P "   ;
        FCB     $FF     ; End-of-string
        RTS             ; RETURN

; -----------------------------------------------------
PRD     JSR     STRING  ; Print string...
        FCC     " D "   ;
        FCB     $FF     ; End-of-string
        RTS             ; RETURN

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


        RMB 26          ; previously the ALTER command

;FEC2
GO      JSR     RD_X    ; Get address to X (16.bit)
        JSR     RD_CMD  ; Right address ?
        LDAA    T_Z+1   ; T_Z.low to A
        LDAB    T_Z     ; T_Z.high to B
GOTO    LDX     PSTACK  ; Callers stack address to X
        STAA    7,X     ; Put new return
        STAB    6,X     ; address on stack
        LDS     PSTACK  ; Set up calling programs stack
        RTI             ; RETURN-FROM-INTERRUPT (SWI)

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
;ff63
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
        JMP     START   ; Return to MINIMON
RESET   LDS     #STACK  ; Set up stack for MINIMON
        LDAA    #$03    ; Reset:
        STAA    CTRLA   ;   ACIA.A
        STAA    CTRLB   ;   ACIA.B
SWI     STS     PSTACK  ; Save callers stack pointer
START   LDS     #STACK  ; Set up stack for MINMON
        LDAA    #$11    ; Set up:
        STAA    CTRLA   ;   ACIA.A
        JSR     STRING  ; Print string...
        FCB     $0D,$0A,$00,'*    ; c/r l/f null `*`
        FCB     $FF     ; End-of-string
        JSR     RD_CMD  ; Read a byte (test for `.`)
        CMPA    #'S     ; Is it `S` ?
        BEQ     BRPTSET ; Yes: Set breakpoint cmd
        CMPA    #'H     ; Is it `H` ?
        BEQ     HEADER  ;
        CMPA    #'P     ; Is it `P` ?
        BNE     L1      ; No: Skip
        JMP     PUNCH   ;
L1      CMPA    #'L     ; Is it `L` ?
        BNE     L2      ; No: Skip
        JMP     LOAD    ;
L2      CMPA    #'R     ; Is it `R`
        BNE     L3      ; No: Skip
        JMP     REGPRT  ;
L3      CMPA    #'B     ; Is it `B` ?
        BNE     L6      ; No: Skip
        JMP     BLKMOV  ;
L6      CMPA    #'M     ; Is it `M` ?
        BNE     L8      ; No: Skip
        JMP     MODIFY  ;
L8      CMPA    #'G     ; Is it `G` ?
        BNE     L9      ; No: Skip
        JMP     GO      ;
L9      CMPA    #'C     ; Is it `C` ?
        BNE     L10     ; No: Skip
        JMP     CONTNU  ;
L10     CMPA    #'D     ; Is it `D` ?
        BNE     START   ; No: Give up - ignore comand
        JMP     DUMP    ;

        ; [JN] The code above ends at address FFF6 and
        ; there is no instruction at FFF7. Vectors
        ; start at FFF8 (see ORG statement below)
        ; Putting a NOP at FFF7 ensures there is no gap
        ; and allows for an easy conversion from s19 to
        ; binary.
        NOP

; ============================================================================
; This is the new load and save routines to be integrated into this monitor
; this will need to relocated to fit in the original Load and Punch routines
;=============================================================================

; Spare bytes for LOAD and PUNCH commands are as follows
; Original LOAD command space = 36 Bytes
; Original PUNCH command space = 47 Bytes
; Addition space where old X and Z commands were 81 bytes
; Additional space where the old ALTER command was = 26 Bytes
; Removed old ZIN releases 26 bytes
; Removed olu ZOUT releases 13 bytes
; Total free bytes = 229 bytes


; 31 bytes
RD_ByteFast EQU     *           ; Read ONE Character (fast)
            STX     d_RdFstX    ; Save X
            LDX     DATAA       ; X = addr of current ACIA
.rdChkF     LDAA    1,X         ; Get ACIA status byte DATAA + 1
            ASRA                ; Shift low order bit to C
            BCC     .rdChkF     ; Loop until C set
            LDAA    0,X         ; Get the data byte to A
            JSR     PR_BYTE     ; Echo character ...echo...
            ANDA    #$7F        ; Strip off `parity` bit, if present
            BEQ     .rdChkF     ; Ignore paper tape follower
            CMPA    #'.         ; Was it
            BNE     .rfDone     ;  a fullstop ?
            JMP     START       ; Yes: Go to START
.rfDone     LDX     d_RdFstX    ; Restore X
            RTS                 ; RETURN

; -----------------------------------------------------
; S format data load : Modded version of Mikbug code
;
CMD_L       EQU     *           ; L = Load = Input an S19 file
            JSR     STRING
            FCC     " + "
            FCB     $0D,$0A     ; c/r l/f
            FCB     $FF         ; End-Of-String
.sRead      BSR     RD_ByteFast ; Read+Echo, test for '.'
            CMPA    #'S         ; Is it `S` ?
            BNE     .sRead      ; No: Keep waiting for `S`
            BSR     RD_ByteFast ; Read+Echo, test for '.'
            CMPA    #'9         ; Is it `9` ?  ( `S9` record )
            BEQ     .sDone      ; Yes: End-data, Back to START
            CMPA    #'1         ; Is it `1` ?  ( `S1` record )
            BNE     .sRead      ; No: Wait for next `S`
            CLR     b_Csum      ; Clear checksum
            JSR     ZIN         ; Read 2xHex = data.byte count to A
            SUBA    #2          ; Subtract 2 (to get bytes left in line)
            STAA    b_Count     ; Store byte count
            JSR     RD_X        ; Read 4xHex digit address to X
.sDoByt     JSR     ZIN         ; Read 2xHex digits, value to A
            DEC     b_Count     ; Decrement our byte count
            BEQ     .sChk       ; If end-of-line, go look at checksum
            STAA    0,X         ; Save byte where X points
            INX                 ; Point X at next byte
            BRA     .sDoByt     ; Go get next byte
.sChk       INC     b_Csum      ; Add 1 to checksum
            BEQ     .sRead      ; OK: Go read next record
            JSR     PR_QM       ; Print "?"
.sDone      EQU     *
STARTS      JMP     START       ; Go to START

; -----------------------------------------------------
; S format data output : Modded version of Mikbug code
;
CMD_P       EQU     *           ; P = Punch : Output an S19 file
            JSR     ASK_Addrs   ; Prompt for "Start:","Stop:"
            LDX     d_START     ; Get start address
            STX     d_TW        ; save it to work area
.fOut1      LDAA    d_STOP+1    ; get low order of end address
            SUBA    d_TW+1      ; Subtract low order start
            LDAB    d_STOP      ; ( carry not affected by LDA )
            SBCB    d_TW        ; Subtract with Carry
            BNE     .fOut2
            CMPA    #16
            BCS     .fOut3
.fOut2      LDAA    #15
.fOut3      ADDA    #4
            STAA    b_Count     ; FRAME COUNT THIS RECORD
            SUBA    #3
            STAA    b_Temp      ; BYTE COUNT THIS RECORD
            JSR     STRING      ; Output this string...
            FCB     $0D,$0A       ; c/r l/f
            FCB     'S,'1       ; S1
            FCB     $FF         ; End-Of-String
            CLRB                ; Clear checksum

; Output frame count...
            LDX     #b_Count    ; X = Address of Framecount
            BSR     .fOutHx2    ; O/P byte <-X and inc X

; Output address...
            LDX     #d_TW
            BSR     .fOutHx2    ; O/P byte <-X and inc X
            BSR     .fOutHx2    ; O/P byte <-X and inc X

; Output data...
            LDX     d_TW
.fOut4      BSR     .fOutHx2    ; O/P byte <-X and inc X
            DEC     b_Temp      ; Decrement `bytes left` count
            BNE     .fOut4      ; Loop back if any left
            STX     d_TW
            COMB
            PSHB
            TSX                 ; X = S + 1
            BSR     .fOutHx2    ; PUNCH CHECKSUM
            PULB
            LDX     d_TW
            DEX
            CPX     d_STOP
            BNE     .fOut1

;x          JSR     PR_STRING   ; Output `S9` record...
;x          FCB     C_CR,C_LF   ; c/r l/f
;x          FCB     'S,'9       ; S9 = <eof>
;x          FCB     C_EOS       ; End-Of-String

            BSR     STARTS      ;Go to START (via `S` code)

;- - - - - - - - - - - - - - - - - - - - - - - - -
; 1) Update checksum
; 2) Output byte pointed to by X as 2 x hex chars
; 3) Increment X
;
.fOutHx2    ADDB    0,X         ; Update checksum
            PSHA                ; Push A to STACK
            LDAA    0,X         ; Load byte to be o/p
            JSR     ZOUT        ; O/P byte <- X
            PULA                ; Pull A off STACK
            INX                 ; Increment X
            RTS                 ; RETURN

; -----------------------------------------------------
; Read a 2 digit HEX value, put result into X

;RD_HEX2 This is a new ZIN and is called RD_HEX2 on GruntMon

ZIN         EQU     *
            JSR     RD_ByteFast ; Read a character
            JSR     VHEX        ; Is it a hex character ?
            BCS     Z_PRQM      ; No: go to print `?`
            STAA    T_Q         ; Save it
            JSR     RD_ByteFast ; Read 2nd character
            JSR     VHEX     ; Is it a hex character ?
            BCS     Z_PRQM     ; No: go to print `?`
            TAB                 ; Yes: Put it into B
            LDAA    T_Q         ; Retrieve 1st hex char to A
            JSR     BINARY      ; Convert A:B to binary to A
            TAB                 ; B=A
            ADDB    b_Csum      ; Add this value
            STAB    b_Csum      ; to the Checksum (for S19)
            RTS                 ; RETURN
Z_PRQM      JSR     PR_QM       ; Print "?"
            BRA     ZIN     ; Go back to start of hex input

PR_QM       LDAA #'?              ; Put '?' character in A
PR_BYTE     JSR     PR_A    ; Print it
            RTS             ; RETURN

ASK_Addrs   BSR     ASK_Start
            JSR     STRING   ; Print string...
            FCC     " Stop:"
            FCB     $FF         ; End-Of-String
            JSR     RD_X        ; Read 4 digit HEX addr value
            STX     d_STOP      ; Save it
            RTS                 ; RETURN

ASK_Start   JSR     STRING      ; Print string...
            FCC     " Start:"
            FCB     $FF         ; End-Of-String
            JSR     RD_X        ; Read 4 digit HEX addr value
            STX     d_START     ; Save it
            RTS


; -----------------------------------------------------
; Print value in A as 2 hex digits, Preserve B
; X unchanged by called routines

;PR_HEX2 Renamed to ZOUT as per old MiniMon

ZOUT        PSHB                ; Save B to STACK
            JSR     ASCII       ; Convert A to ASCII in A & B
            PSHB                ; Save B (2nd byte) to STACK
            BSR     PR_BYTE     ; Print byte in A
            PULA                ; Get 2nd byte into A from STACK
            BSR     PR_BYTE     ; Print byte in A
            PULA                ; Recover A from STACK
            PULB                ; Recover B from STACK
            RTS                 ; RETURN

PR_SP       JSR     STRING      ; Print...
            FCB     $20         ;  SPACE
            FCB     $FF         ; End-Of-String
            RTS                 ; RETURN

; -----------------------------------------------------
        ORG     $FFF8   ; 6800 interrupt vectors

        FDB     JIRQ    ; IRQ
        FDB     SWI     ; SWI
        FDB     JNMI    ; NMI
        FDB     RESET   ; Reset
; -----------------------------------------------------
;       The End


