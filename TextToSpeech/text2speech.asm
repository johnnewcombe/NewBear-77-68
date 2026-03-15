;------------------------------------------------------------------
; text2speech.asm
;------------------------------------------------------------------

; 7768 ACIA
DATAA   EQU $F400 ; ACIA(a) Data register
CTRLA   EQU $F401 ; ACIA(a) Ctrl/Status
DATAB   EQU $F402 ; ACIA(b) Data register
CTRLB   EQU $F403 ; ACIA(b) Ctrl/Status

; MINIMON routines
STRING  EQU $FC76 ; Prints a string. The string should follow JSR and be terminated with $FF.
GETADD  EQU $FC89 ; Get Address, read 4 digit hex value.
ZOUT    EQU $FCC9 ; Print value in A as 2 hex digits.
NEWLINE EQU $FE97 ; Prints a new line.
START   EQU $FF8F ; Restarts MniMon.
PR_A    EQU $FC0F ; Print char in A to ACIA (a)
RD_A    EQU $FD2B ; Read char from A
PRSP    EQU $FD4D ; Print a space
BINARY  EQU $FC31 ; Converts ASCII hex digits in A and B to binary?
RD_X    EQU $FC65 ; Read 4 hex digits Value from ACIA(a) and put value into X.
VHEX    EQU $FC1D ; Checks that A contains a HEX character
	    ORG $0200

; initialise serial port B
TX2SP   LDAA    #$11    ; 8 Data, No Parity, 2 Stop Bits
        STAA    CTRLB   ;   ACIA.A

        ; -----------------------------------------------------
        ; PRINT NUMBERS 0 TO 9
        ; -----------------------------------------------------
;        CLRA
;PRNUMS  JSR     PRSPB
;        JSR     PR_NUMB
;        INCA
;        CMPA    #10
;        BNE     PRNUMS
;        JSR     PRSPB


LOOP:
; -----------------------------------------------------
; Data arrives at port B as four hex characters
; -----------------------------------------------------
        JSR     RD_XB           ; read 4 hex characters into X
        STX     TEMP            ; save X

;--------------------------------------------------------------
; Spek the weight
;--------------------------------------------------------------
        JSR     STRINGB
        FCC     "You weigh "
        FDB     $FF
        LDAA    TEMP            ; Load high byte of X into Accumulator A
        JSR     PR_NUMB
        JSR     STRINGB
        FCC     " stones "
        FDB     $FF
        LDAA    TEMP+1            ; Load high byte of X into Accumulator A
        JSR     PR_NUMB
        JSR     STRINGB
        FCC     " pounds"
        FCB     $0D, $0A,$FF



        ;JSR     PR_DEC          ; puts 3 decimal digits in DEC, DEC+1 and DEC+2
        ;LDAA    DEC+1           ; don't care about the hundreds        ADDA    #$30
        ;JSR     PR_NUMB
        ;JSR     PRSPB
        ;LDAA    DEC+2
        ;JSR     PR_NUMB

;--------------------------------------------------------------
;
;--------------------------------------------------------------
        ;JSR     STRINGB
        ;FCB     $0D, $0A
        ;FCC     "Shall I tell you a joke?"
        ;FCB     $0D, $0A,$FF

.END    JMP     LOOP  ;START   ; all done

; -----------------------------------------------------
; PR_DEC: Puts 3 decimal digits in DEC, DEC+1 and DEC+2
;
;       !! ONLY WORKS WITH VALUES BELOW 128 !!
; -----------------------------------------------------
PR_DEC  CLRB            ; Clear B for hundreds

HUND    CMPA    #100    ; 100 or more?

        BLT     TENS
        SUBA    #100    ; Sub 100
        INCB            ; Increment hundred counter
        BRA     HUND

TENS    STAB    DEC     ; store the hundreds

        CLRB
TENS1   CMPA    #10     ; 10 or more?
        BLT     UNITS
        SUBA    #10     ; Sub 10
        INCB            ; Increment ten counter
        BRA     TENS1

UNITS   STAB    DEC+1
        STAA    DEC+2   ; Final remainder is units

        RTS


; -----------------------------------------------------
; Print string FOLLOWING JSR ( terminated by $FF ) to
; ACIA(b) and ACIA(b)
; -----------------------------------------------------
STRINGB TSX             ; Get loc. of return addr to X
        LDX     0,X     ; Get return addr to X
        DEX             ; Point to byte before
AGAIN   INX             ; Point to next byte
        LDAA    0,X     ; Get byte to be printed
        CMPA    #$FF    ; End-string ?
        BEQ     ENDSTR  ; Yes: Go to finish up
        JSR     PR_A    ; Print the byte to ACIA(a) (A is maintained)
        BSR     PR_B    ; Print the byte to ACIA(b)
        BRA     AGAIN   ; Go back for next byte
ENDSTR  INS             ; Clean up stack...
        INS             ;  ( pop off the return addr )
        JMP     1,X     ; Jump back to caller (RETURN)

; -----------------------------------------------------
; Prints a string pointed to by X
; -----------------------------------------------------
STRINGBX    LDAA    0,X         ; get char
            CMPA    #$FF        ; is character NULL?
            BEQ     DONEB       ; yes, end of string
            JSR     PR_A        ; Print the byte to ACIA(a) (A is maintained)
            BSR     PR_B        ; Print the byte to ACIA(b)
            INX
            BRA     STRINGBX
DONEB       RTS

; -----------------------------------------------------
; Reads a character from ACIA(b) into A
; -----------------------------------------------------
RD_B    LDAA    CTRLB       ; Get ACIA.A status byte
        BITA    #01         ; Is byte ready in DATAb
        BEQ     RD_B        ; No: Try again
        LDAA    DATAB       ; Get the data byte to A
        ;ANDA    #$7F        ; Mask off parity bit if it exists
        RTS                 ; RETURN

; -----------------------------------------------------
;
; -----------------------------------------------------
ZINB    BSR     RD_B    ; Read a character
        JSR     VHEX    ; Is it a hex character ?
        BCS     Z_PRQM  ; No: go to print `?`
        STAA    T_Q     ; Yes: Save Acc.A
        BSR     RD_B    ; Read 2nd character
        JSR     VHEX    ; Is it a hex character ?
        BCS     Z_PRQM  ; No: go to print `?`
        TAB             ; Yes: Put it into Acc.B
        LDAA    T_Q     ; Retrieve 1st hex char to Acc.A
        JSR     BINARY  ; Convert A:B to binary
        RTS             ; RETURN
Z_PRQM  ;LDAA    #'?     ; Load `?` into A
        ;BSR     PR_B    ; Print it
        BRA     ZINB    ; Go back to start of hex input

; -----------------------------------------------------
; Print character in A to ACIA(b)
; -----------------------------------------------------
PR_B    LDAB    CTRLB   ; Get ACIA(a) status byte
        BITB    #02     ; Is it busy ?
        BEQ     PR_B    ; Yes: Try again
        STAA    DATAB   ;  No: Send data
PRB_END RTS             ; RETURN

; -----------------------------------------------------
; Read 4 hex digits and put value into X
; -----------------------------------------------------
RD_XB   ;JSR     PRSPB   ; Print a space
        BSR     ZINB    ; Read 2 digit hex value into A
        STAA    T_Z     ; Save byte (most significant)
        BSR     ZINB    ; Read 2 digit hex value into A
        STAA    T_Z+1   ; Save byte (least significant)
        LDX     T_Z     ; Load full 4 hex value into X
        RTS             ; RETURN

; -----------------------------------------------------
; Random idle phrase to ports B
; -----------------------------------------------------
IDLE    RTS


; -----------------------------------------------------
; Prints the message "You weight n stones n pounds"
; place stones in A and Pounds in B
; -----------------------------------------------------
PRWEIGHT

        LDAA    TEMP            ; Load high byte of X into Accumulator A
        JSR     PR_NUMB
        JSR     STRINGB
        FCC     " stones "
        fdb     $FF
        LDAA    TEMP+1            ; Load high byte of X into Accumulator A
        JSR     PR_NUMB
        JSR     STRINGB
        FCC     " pounds"
        FCB     $0D, $0A,$FF


; -----------------------------------------------------
; Prints a space on both consoles (preserves A)
; -----------------------------------------------------
PRSPB   PSHA
        LDAA    #$20        ; Put space character in A
        JSR     PR_A
        JSR     PR_B        ; Print it
        PULA
        RTS                 ; RETURN


; -----------------------------------------------------
; Get number word based on value in A
; -----------------------------------------------------
PR_NUMB     PSHA
            INCA
            LDX     #TEXTBLOCKPTR  ; base of offset table
PR_NUMB1    DECA
            BEQ     FOUND
            INX                 ; move to next address
            INX
            BNE     PR_NUMB1    ; loop around to retest
FOUND
            LDAA    0,X
            STAA    $1004
            LDAA    1,X
            STAA    $1005
            LDX     $1004
            JSR     STRINGBX
            PULA
            RTS

; -----------------------------------------------------
; Text pointer table
; -----------------------------------------------------
TEXTBLOCKPTR
        FDB ZERO
        FDB ONE
        FDB TWO
        FDB THREE
        FDB FOUR
        FDB FIVE
        FDB SIX
        FDB SEVEN
        FDB EIGHT
        FDB NINE
        FDB TEN
        FDB ELEVEN
        FDB TWELVE
        FDB THIRTEEN
        FDB FOURTEEN
        FDB FIFTEEN
        FDB SIXTEEN
        FDB SEVENTEEN
        FDB EIGHTEEN
        FDB NINETEEN
        FDB TWENTY

; -----------------------------------------------------
; Text block
; -----------------------------------------------------
TEXTBLOCK

ZERO        FCC     "zero"
            FCB     $FF
ONE         FCC     "one"
            FCB     $FF
TWO         FCC     "two"
            FCB     $FF
THREE       FCC     "three"
            FCB     $FF
FOUR        FCC     "four"
            FCB     $FF
FIVE        FCC     "five"
            FCB     $FF
SIX         FCC     "six"
            FCB     $FF
SEVEN       FCC     "seven"
            FCB     $FF
EIGHT       FCC     "eight"
            FCB     $FF
NINE        FCC     "nine"
            FCB     $FF
TEN         FCC     "ten"
            FCB     $FF
ELEVEN      FCC     "eleven"
            FCB     $FF
TWELVE      FCC     "twelve"
            FCB     $FF
THIRTEEN    FCC     "thirteen"
            FCB     $FF
FOURTEEN    FCC     "fourteen"
            FCB     $FF
FIFTEEN     FCC     "fifteen"
            FCB     $FF
SIXTEEN     FCC     "sixteen"
            FCB     $FF
SEVENTEEN   FCC     "seventeen"
            FCB     $FF
EIGHTEEN    FCC     "eighteen"
            FCB     $FF
NINETEEN    FCC     "nineteen"
            FCB     $FF
TWENTY      FCC     "nineteen"
            FCB     $FF



; -----------------------------------------------------
; Reserved memory
; -----------------------------------------------------

T_Q     RMB     1           ;   "     "     "  ZIN,DUMP
T_Z     RMB     2           ;   "     "     "   . RDX
TEMP    RMB     2           ; local 16 bit temp location
DEC     RMB     3           ; for decimal value

