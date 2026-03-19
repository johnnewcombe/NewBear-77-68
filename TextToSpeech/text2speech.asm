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

MAINLOOP:
; -----------------------------------------------------
; Data arrives at port B as four hex characters
; -----------------------------------------------------
        JSR     RD_XB           ; read 4 hex characters into X
        STX     TEMP            ; store X

        ; -----------------------------------------------------
        ; hello message "My name is MARVIN"
        ; -----------------------------------------------------
        LDAA    #$01            ; load phrase number (PTR)
        JSR     PR_PHRASE
        JSR     PR_CRB
        ; -----------------------------------------------------

        LDAA    TEMP            ; get fist byte (stones)
        CMPA    #20             ; more that 20 is too heavey
        BHI     TOHEAVY         ; say something rude
        LDAA    TEMP+1          ; get pounds
        CMPA    #13             ; invalid pounds
        BHI     ERROR           ; error

        ; all good so output the weight mesage
        LDAA    #0              ; output the 'you weigh' phrase
        JSR     PR_PHRASE       ; output phrase specified in A
        LDX     TEMP            ; restore X
        JSR     PR_WEIGHT       ; weight back X so output the weight

        BRA     END

; -----------------------------------------------------
; Over 20 stone so random heavy phrase to ports B
; -----------------------------------------------------
TOHEAVY
        SWI
ERROR

END
        LDX     #MYNAME
        JSR     PR_PHRASE
        JMP     MAINLOOP  ;START   ; all done

















; -----------------------------------------------------
; Random idle phrase to ports B
; -----------------------------------------------------
IDLE    RTS

;--------------------------------------------------------------
; DECIMAL CONVERSION EXAMPLE
;--------------------------------------------------------------
        ;JSR     PR_DEC          ; puts 3 decimal digits in DEC, DEC+1 and DEC+2
        ;LDAA    DEC+1           ; don't care about the hundreds        ADDA    #$30
        ;JSR     PR_WORD
        ;JSR     PR_SPCB
        ;LDAA    DEC+2
        ;JSR     PR_WORD

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
RD_B    INC     RND         ; simple way to get a random number
        LDAA    CTRLB       ; Get ACIA.A status byte
        BITA    #01         ; Is byte ready in DATAb
        BEQ     RD_B        ; No: Try again
        LDAA    DATAB       ; Get the data byte to A
        ANDA    #$7F        ; Mask off parity bit if it exists
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
RD_XB   BSR     ZINB    ; Read 2 digit hex value into A
        STAA    T_Z     ; Save byte (most significant)
        BSR     ZINB    ; Read 2 digit hex value into A
        STAA    T_Z+1   ; Save byte (least significant)
        LDX     T_Z     ; Load full 4 hex value into X
        RTS             ; RETURN

; -----------------------------------------------------
; Prints the message " n stones n pounds"
; place stones in MSB of X and pound in LSB
; -----------------------------------------------------
PR_WEIGHT
        STX     T_W
        LDAA    T_W             ; Load high byte of X into Accumulator A
        JSR     PR_WORD         ; n
        JSR     PR_SPCB
        LDAA    #$1B
        JSR     PR_WORD         ; "stones"
        JSR     PR_SPCB
        LDAA    T_W+1            ; Load high byte of X into Accumulator A
        JSR     PR_WORD         ; n
        LDAA    #$1C
        JSR     PR_SPCB
        JSR     PR_WORD         ; "pounds"
        JSR     PR_CRB
        RTS

; -----------------------------------------------------
; Prints a space on both consoles (preserves A)
; -----------------------------------------------------
PR_SPCB   PSHA
        LDAA    #$20        ; Put space character in A
        JSR     PR_A
        JSR     PR_B        ; Print it
        PULA
        RTS                 ; RETURN

; -----------------------------------------------------
; Prints a CRLF on both consoles (preserves A)
; -----------------------------------------------------
PR_CRB  PSHA
        LDAA    #$0D        ; Put CHAR character in A
        JSR     PR_A
        JSR     PR_B        ; Print it
        LDAA    #$0A
        JSR     PR_A
        JSR     PR_B        ; Print it
        PULA
        RTS                 ; RETURN

; -----------------------------------------------------
; Outputs a phrase from the value in A
; -----------------------------------------------------
PR_PHRASE
        INCA
        LDX     #PHRASEPTR  ; load address of phrase ponter
                            ; table
PR_PH1  DECA                ; loop through A times to get
        BEQ     FOUNDP      ;   address of phrase
        INX                 ; move to next address
        INX
        BRA     PR_PH1      ; try again
FOUNDP  LDAA    0,X         ; transfer addr pointed to by X to memory
        STAA    T_P         ; MSB
        LDAA    1,X         ;
        STAA    T_P+1       ; LSB
PR_PH3  LDX     T_P         ; load X
        LDAA    0,X         ; get word id
        INX                 ; point X to next word
        STX     T_P         ; store X away
        CMPA    #0
        BEQ     PR_PH2      ; no more words
        JSR     PR_WORD     ; print word based on value in A
        JSR     PR_SPCB
        BRA     PR_PH3      ; next word
PR_PH2  RTS

; -----------------------------------------------------
; Outputs a word based on value in A
; -----------------------------------------------------
PR_WORD     INCA
            LDX     #WORDPTR  ; base of offset table
PR_WORD1    DECA
            BEQ     FOUNDW
            INX                 ; move to next address
            INX
            BNE     PR_WORD1    ; loop around to retest
FOUNDW      LDAA    0,X
            STAA    T_X
            LDAA    1,X
            STAA    T_X+1
            LDX     T_X
            JSR     STRINGBX
            RTS

; -----------------------------------------------------
; Word pointer table (max words 256)
; Set A to the pointer ID and call PR_WORD
; -----------------------------------------------------
; add a pointer to words defined in the WORDTABLE
WORDPTR

; numbers
WP00        FDB WZERO
WP01        FDB WONE
WP02        FDB WTWO
WP03        FDB WTHREE
WP04        FDB WFOUR
WP05        FDB WFIVE
WP06        FDB WSIX
WP07        FDB WSEVEN
WP08        FDB WEIGHT
WP09        FDB WNINE
WP0A        FDB WTEN
WP0B        FDB WELEVEN
WP0C        FDB WTWELVE
WP0D        FDB WTHIRTEEN
WP0E        FDB WFOURTEEN
WP0F        FDB WFIFTEEN
WP10        FDB WSIXTEEN
WP11        FDB WSEVENTEEN
WP12        FDB WEIGHTEEN
WP13        FDB WNINETEEN
WP14        FDB WTWENTY

; general words
WP15        FDB WYOU
WP16        FDB WWEIGH
WP17        FDB WIS
WP18        FDB WMY
WP19        FDB WNAME
WP1A        FDB WMARVIN
WP1B        FDB WSTONES
WP1C        FDB WPOUNDS

; -----------------------------------------------------
; Phrase pointer table (max 256 phases)
; Set A to the pointer ID and call PR_PHRASE
; -----------------------------------------------------
PHRASEPTR
PP00        FDB YOUWEIGH
PP01        FDB MYNAME
PP02
PP03
PP04
PP05
PP06

; -----------------------------------------------------
; Phrases (each holds a list of word pointers)
; -----------------------------------------------------
;All valid weight messages include ...
;
;   Greeting message (waiting for the weight to settle)
;   the weight message
;   comment.

; standard weight phrase
YOUWEIGH    FCB $15,$16,$00

; -----------------------------------------------------
; Idle Phrases (90 sec intervals?
; -----------------------------------------------------

MYNAME      FCB $18,$19,$17,$1A,$00

;Machine for Analytical Reasoning with Variable Interest and No Enthusiasm
;All the diodes on my memory cards hurt.
;This is very boring.
;New bear, smarter than the average bear, probably.
;I know I don't look it but I am actually quite clever.


; error phrases
; i am too hot, turn me off

; -----------------------------------------------------
; Word Table
; -----------------------------------------------------

; numbers
WZERO       FCC     "zero"
            FCB     $FF
WONE        FCC     "one"
            FCB     $FF
WTWO        FCC     "two"
            FCB     $FF
WTHREE      FCC     "three"
            FCB     $FF
WFOUR       FCC     "four"
            FCB     $FF
WFIVE       FCC     "five"
            FCB     $FF
WSIX        FCC     "six"
            FCB     $FF
WSEVEN      FCC     "seven"
            FCB     $FF
WEIGHT      FCC     "eight"
            FCB     $FF
WNINE       FCC     "nine"
            FCB     $FF
WTEN        FCC     "ten"
            FCB     $FF
WELEVEN     FCC     "eleven"
            FCB     $FF
WTWELVE     FCC     "twelve"
            FCB     $FF
WTHIRTEEN   FCC     "thirteen"
            FCB     $FF
WFOURTEEN   FCC     "fourteen"
            FCB     $FF
WFIFTEEN    FCC     "fifteen"
            FCB     $FF
WSIXTEEN    FCC     "sixteen"
            FCB     $FF
WSEVENTEEN  FCC     "seventeen"
            FCB     $FF
WEIGHTEEN   FCC     "eighteen"
            FCB     $FF
WNINETEEN   FCC     "nineteen"
            FCB     $FF
WTWENTY     FCC     "twenty"
            FCB     $FF

; general words
WYOU        FCC     "you"
            FCB     $FF
WWEIGH      FCC     "weigh"
            FCB     $FF
WIS         FCC     "is"
            FCB     $FF
WMY         FCC     "my"
            FCB     $FF
WNAME       FCC     "name"
            FCB     $FF
WMARVIN     FCC     "marvin"
            FCB     $FF
WSTONES     FCC     "stones"
            FCB     $FF
WPOUNDS     FCC     "pounds"
            FCB     $FF

; -----------------------------------------------------
; Reserved memory
; -----------------------------------------------------

T_Q     RMB     1           ; Temp storage for ZIN
T_Z     RMB     2           ;   "     "     "  RDX
T_X     RMB     2           ;   "     "     "  PR_WORD
T_P     RMB     2           ;   "     "     "  PR_PHRASE
T_W     RMB     2           ;   "     "     "  PR_WEIGHT
DEC     RMB     3           ; for decimal value
RND     RMB     1           ; holds a random number (see RD_B
TEMP    RMB     2           ; temp var (non subroutine use)



