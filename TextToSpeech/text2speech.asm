        .area   CODE1  (ABS)        ; absolute i.e. not relocatable
        .org    0x0100

;------------------------------------------------------------------
; text2speech.asm
;------------------------------------------------------------------
DATAA               .equ 0xF400 ; ACIA(a) Data register
CTRLA               .equ 0xF401 ; ACIA(a) Ctrl/Status
DATAB               .equ 0xF402 ; ACIA(b) Data register
CTRLB               .equ 0xF403 ; ACIA(b) Ctrl/Status

; MINIMON routines
STRING              .equ 0xFC76   ; Prints a string. The string should follow JSR and be terminated with 0xFF.
GETADD              .equ 0xFC89   ; Get Address, read 4 digit hex value.
ZOUT                .equ 0xFCC9   ; Print value in A as 2 hex digits.
NEWLINE             .equ 0xFE97   ; Prints a new line.
START               .equ 0xFF8F   ; Restarts MniMon.
PR_A                .equ 0xFC0F   ; Print char in A to ACIA (a)
RD_A                .equ 0xFD2B   ; Read char from A
PRSP                .equ 0xFD4D   ; Print a space
BINARY              .equ 0xFC31   ; Converts ASCII hex digits in A and B to binary?
RD_X                .equ 0xFC65   ; Read 4 hex digits Value from ACIA(a) and put value into X.
VHEX                .equ 0xFC1D   ; Checks that A contains a HEX character

IDLE_SECS           .equ 2      ; seconds between idle messages
LIGHT_WGHT          .equ 6       ; greater than 6 stones
NORM_WGHT           .equ 10
HEAVY_WGHT          .equ 13
SHEAVY_WGHT         .equ 15

; number of messages
GREET_MSG_CNT       .equ 5
IDLE_MSG_CNT        .equ 5
LIGHT_MSG_CNT       .equ 5
NORM_MSG_CNT        .equ 5
HEAVY_MSG_CNT       .equ 5
SHEAVY_MSG_CNT      .equ 5

; initialise serial port B
TX2SP:   LDAA    #0x11    ; 8 Data, No Parity, 2 Stop Bits
        STAA    CTRLB   ;   ACIA.A

TEST:
        ;LDAA    #02
        ;LDX     #GREETPTR
        ;JMP     PHRASE_OUT

MAINLOOP:
; -----------------------------------------------------
; Data arrives at port B as four hex characters
; -----------------------------------------------------
        JSR     GETDATA         ; value in T_WEIGHT, stones in A
        BCS     ML1             ; is it invalid i.e. carry clear
        JMP     IDLE
ML1:     CMPA    #20             ; more that 20 is too heavy
        BHI     OVERLOADED
        LDAA    T_WEIGHT+1      ; validate pounds
        CMPA    #13             ; invalid pounds
        BHI     ERROR           ; error
        JSR GREET               ; send a greeting message

        ; get the weight a second time, this should allow the scales time to settle
        JSR     GETDATA

        ; all good so output the weight mesage
        ; TODO get phrase from phrase table as per other message output routines
        JSR     STRINGB
        .fcc     "You weigh"
        .fcb     0x00
        LDX     T_WEIGHT        ; restore X
        JSR     PR_WEIGHT       ; weight back X so output the weight

        ; determine phrase category (light normal, heavy etc.) and jump to the section
        LDAA    T_WEIGHT
        CMPA    #LIGHT_WGHT
        BHI     ML2             ; less than light weight gets no comment
        JMP     MAINLOOP
ML2:     CMPA    #NORM_WGHT      ; less than normal is light
        BHI     ML3
        JMP     LIGHTW
ML3:     CMPA    #HEAVY_WGHT     ; less than heavy is normal
        BHI     ML4
        JMP     NORMALW
ML4:    CMPA    #SHEAVY_WGHT    ; less than super heavy is heavy
        BMI     ML5
        JMP     HEAVYW
ML5:     JMP     SHEAVYW
        JMP     MAINLOOP

; -----------------------------------------------------
; Over 20 stone so random heavy phrase to ports B
; -----------------------------------------------------
OVERLOADED:
        ; TODO get phrase from phrase table
        JSR      STRINGB
        .fcc      "System overload, and its not me."
        .fcb      0xFF
        JMP      MAINLOOP
ERROR:
        SWI
        ; TODO get phrase from phrase table
        JSR      STRINGB
        .fcc      "Internal error, typical!"
        .fcb      0xFF
        JMP      MAINLOOP

; we cycle thought idle message when no one is on the scales, data comes in a one
; second intervals so we simply increase the idle count until it's time to display
; the next idle message

IDLE:    INC     IDLE_COUNT      ; increase the idle count
        LDAA    IDLE_COUNT      ; see if idle count = max idle time
        CMPA    #IDLE_SECS      ; a data message appears every second
        BEQ     IDLE1           ; not reached the max idle time
        JMP     MAINLOOP             ; nothing to do yet

IDLE1:   CLR     IDLE_COUNT      ; time to output an idle message so reset the count
        LDAA    IDLE_MSG_ID     ; get next Message ID
        CMPA    #IDLE_MSG_CNT   ; are we beyond the end of the list
        BNE     IDLE_OP         ; still at valid id so output idle message
        CLR     IDLE_MSG_ID     ; beyond last message so reset the current msg to zero
        CLRA                    ; set currentid back to 0
IDLE_OP:
        INC     IDLE_MSG_ID     ; set to next message for the next next time
        LDX     #IDLEPTR        ; A has phrase ID, set X to the base address
        JSR     PHRASE_OUT
        JMP     MAINLOOP

GREET:   ; output the greeting message
        LDAA    GREET_MSG_ID    ; get next Message ID
        CMPA    #GREET_MSG_CNT  ; are we beyond the end of the list
        BNE     GREET_OP        ; still at valid id so output idle message
        CLR     GREET_MSG_ID    ; beyond last message so reset the current msg to zero
        CLRA                    ; set currentid back to 0
GREET_OP:
        INC     GREET_MSG_ID    ; set to next message for the next next time
        LDX     #GREETPTR       ; A has phrase ID, set X to the base address
        JSR     PHRASE_OUT
        RTS

LIGHTW:   ; output the lightweight message
        LDAA    LIGHT_MSG_ID    ; get next Message ID
        CMPA    #LIGHT_MSG_CNT  ; are we beyond the end of the list
        BNE     LIGHT_OP        ; still at valid id so output idle message
        CLR     LIGHT_MSG_ID    ; beyond last message so reset the current msg to zero
        CLRA                    ; set currentid back to 0
LIGHT_OP:
        INC     LIGHT_MSG_ID    ; set to next message for the next next time
        LDX     #LIGHTPTR       ; A has phrase ID, set X to the base address
        JSR     PHRASE_OUT
        JMP     MAINLOOP

NORMALW: ; output the normal message
        LDAA    NORMAL_MSG_ID   ; get next Message ID
        CMPA    #NORM_MSG_CNT   ; are we beyond the end of the list
        BNE     NORMAL_OP       ; still at valid id so output idle message
        CLR     NORMAL_MSG_ID   ; beyond last message so reset the current msg to zero
        CLRA                    ; set currentid back to 0
NORMAL_OP:
        INC     NORMAL_MSG_ID   ; set to next message for the next next time
        LDX     #NORMALPTR      ; A has phrase ID, set X to the base address
        JSR     PHRASE_OUT
        JMP     MAINLOOP

HEAVYW:  ; output the heavy message
        LDAA    HEAVY_MSG_ID    ; get next Message ID
        CMPA    #HEAVY_MSG_CNT  ; are we beyond the end of the list
        BNE     HEAVY_OP        ; still at valid id so output idle message
        CLR     HEAVY_MSG_ID    ; beyond last message so reset the current msg to zero
        CLRA                    ; set currentid back to 0
HEAVY_OP:
        INC     HEAVY_MSG_ID    ; set to next message for the next next time
        LDX     #HEAVYPTR       ; A has phrase ID, set X to the base address
        JSR     PHRASE_OUT
        JMP     MAINLOOP

SHEAVYW: ; output the superheavy message
        LDAA    SHEAVY_MSG_ID   ; get next Message ID
        CMPA    #SHEAVY_MSG_CNT ; are we beyond the end of the list
        BNE     SHEAVY_OP       ; still at valid id so output idle message
        CLR     SHEAVY_MSG_ID   ; beyond last message so reset the current msg to zero
        CLRA                    ; set currentid back to 0
SHEAVY_OP:
        INC     SHEAVY_MSG_ID   ; set to next message for the next next time
        LDX     #SHEAVYPTR      ; A has phrase ID, set X to the base address
        BSR     PHRASE_OUT
        JMP     MAINLOOP

PHRASE_OUT:

        ASLA                    ; multiply A by 2 as each pointer is two bytes
        JSR     ADX             ; now have the correct pointer value in X

; get address of message in X from the pointer in X
        LDAA    0,X             ;  get high byte of word pointed to by X
        LDAB    1,X             ;  get low byte of word pointed to by X
        STAA    TEMP
        STAB    TEMP+1
        LDX     TEMP
        JSR     PR_PHRASE       ; output idle message
        JSR     PR_CRB          ; CR/LF
        RTS

;END:     JMP     MAINLOOP  ;START   ; all done

;--------------------------------------------------------------
; Gets the weight data from the scales and rerurns with carry
; set if a valid reading, carry clear otherwise. A valid weight
; reading resets the idle count. Data received is stored in
; T_WEIGHT and MSB in A.
;--------------------------------------------------------------
GETDATA:
        JSR     RD_XB           ; read 4 hex characters into X
        STX     T_WEIGHT        ; store X
        CLC
        LDAA    T_WEIGHT        ; get fist byte (stones)
        BEQ     GDDONE          ; idle message
        CLR     IDLE_SECS       ; not an idle message so reset the idle counter
        SEC                     ; non idle message return with carry set
GDDONE:  RTS

;--------------------------------------------------------------
; DECIMAL CONVERSION EXAMPLE
;--------------------------------------------------------------
        ;JSR     PR_DEC          ; puts 3 decimal digits in DEC, DEC+1 and DEC+2
        ;LDAA    DEC+1           ; don't care about the hundreds        ADDA    #0x30
        ;JSR     PR_WORD
        ;JSR     PR_SPCB
        ;LDAA    DEC+2
        ;JSR     PR_WORD

; -----------------------------------------------------
; PR_DEC: Puts 3 decimal digits in DEC, DEC+1 and DEC+2
;
;       !! ONLY WORKS WITH VALUES BELOW 128 !!
; -----------------------------------------------------
PR_DEC:  CLRB            ; Clear B for hundreds

HUND:    CMPA    #100    ; 100 or more?

        BLT     TENS
        SUBA    #100    ; Sub 100
        INCB            ; Increment hundred counter
        BRA     HUND

TENS:    STAB    DEC     ; store the hundreds

        CLRB
TENS1:   CMPA    #10     ; 10 or more?
        BLT     UNITS
        SUBA    #10     ; Sub 10
        INCB            ; Increment ten counter
        BRA     TENS1

UNITS:   STAB    DEC+1
        STAA    DEC+2   ; Final remainder is units

        RTS


; -----------------------------------------------------
; Print string FOLLOWING JSR ( terminated by 0xFF ) to
; ACIA(b) and ACIA(b)
; -----------------------------------------------------
STRINGB: TSX             ; Get loc. of return addr to X
        LDX     0,X     ; Get return addr to X
        DEX             ; Point to byte before
STRB1:   INX             ; Point to next byte
        LDAA    0,X     ; Get byte to be printed
        CMPA    #0xFF    ; End-string ?
        BEQ     ENDSTR  ; Yes: Go to finish up
        JSR     PR_A    ; Print the byte to ACIA(a) (A is maintained)
        BSR     PR_B    ; Print the byte to ACIA(b)
        BRA     STRB1   ; Go back for next byte
ENDSTR:  INS             ; Clean up stack...
        INS             ;  ( pop off the return addr )
        JMP     1,X     ; Jump back to caller (RETURN)

; -----------------------------------------------------
; Prints a string pointed to by X
; -----------------------------------------------------
STRINGBX:    LDAA    0,X         ; get char
            CMPA    #0xFF        ; is character NULL?
            BEQ     DONEB       ; yes, end of string
            JSR     PR_A        ; Print the byte to ACIA(a) (A is maintained)
            BSR     PR_B        ; Print the byte to ACIA(b)
            INX
            BRA     STRINGBX
DONEB:       RTS

; -----------------------------------------------------
; Reads a character from ACIA(b) into A
; -----------------------------------------------------
RD_B:    INC     RND         ; simple way to get a random number
        LDAA    CTRLB       ; Get ACIA.A status byte
        BITA    #01         ; Is byte ready in DATAb
        BEQ     RD_B        ; No: Try again
        LDAA    DATAB       ; Get the data byte to A
        ANDA    #0x7F        ; Mask off parity bit if it exists
        RTS                 ; RETURN

; -----------------------------------------------------
;
; -----------------------------------------------------
ZINB:    BSR     RD_B    ; Read a character
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
Z_PRQM:  ;LDAA    #'?     ; Load `?` into A
        ;BSR     PR_B    ; Print it
        BRA     ZINB    ; Go back to start of hex input

; -----------------------------------------------------
; Print character in A to ACIA(b)
; -----------------------------------------------------
PR_B:    LDAB    CTRLB   ; Get ACIA(a) status byte
        BITB    #02     ; Is it busy ?
        BEQ     PR_B    ; Yes: Try again
        STAA    DATAB   ;  No: Send data
PRB_END: RTS             ; RETURN

; -----------------------------------------------------
; Read 4 hex digits and put value into X
; -----------------------------------------------------
RD_XB:   BSR     ZINB    ; Read 2 digit hex value into A
        STAA    T_Z     ; Save byte (most significant)
        BSR     ZINB    ; Read 2 digit hex value into A
        STAA    T_Z+1   ; Save byte (least significant)
        LDX     T_Z     ; Load full 4 hex value into X
        RTS             ; RETURN
; -----------------------------------------------------
; Adds A to X and leaves the result in X, A is
; preserved.
; -----------------------------------------------------
ADX:     PSHA
        STX     T_TMP
        ADDA    T_TMP+1   ; add A to low byte
        STAA    T_TMP+1
        LDAA    T_TMP     ; get high byte
        ADCA    #0      ; add carry only
        STAA    T_TMP
        LDX     T_TMP
        PULA
        RTS

; -----------------------------------------------------
; Prints the message " n stones n pounds"
; place stones in MSB of X and pound in LSB
; -----------------------------------------------------
PR_WEIGHT:
        STX     T_W
        LDAA    T_W             ; Load high byte of X into Accumulator A
        JSR     PR_WORD         ; n
        JSR     PR_SPCB
        LDAA    #0x1B
        JSR     PR_WORD         ; "stones"
        JSR     PR_SPCB
        LDAA    T_W+1            ; Load high byte of X into Accumulator A
        JSR     PR_WORD         ; n
        LDAA    #0x1C
        JSR     PR_SPCB
        JSR     PR_WORD         ; "pounds"
        JSR     PR_CRB
        RTS

; -----------------------------------------------------
; Prints a space on both consoles (preserves A)
; -----------------------------------------------------
PR_SPCB: PSHA
        LDAA    #0x20        ; Put space character in A
        JSR     PR_A
        JSR     PR_B        ; Print it
        PULA
        RTS                 ; RETURN

; -----------------------------------------------------
; Prints a CRLF on both consoles (preserves A)
; -----------------------------------------------------
PR_CRB:  PSHA
        LDAA    #0x0D        ; Put CHAR character in A
        JSR     PR_A
        JSR     PR_B        ; Print it
        LDAA    #0x0A
        JSR     PR_A
        JSR     PR_B        ; Print it
        PULA
        RTS                 ; RETURN

; -----------------------------------------------------
; Outputs a phrase from the memory location in X
; -----------------------------------------------------
PR_PHRASE:

PR_PH1:  LDAA    0,X         ; get high byte of word
        LDAB    1,X         ; get low byte
        CMPA    #0xFF        ; check high byte
        BEQ     PR_PH2      ; high byte is 0xFF so we're done
PR_PH3:  STX     T_Y         ; save table pointer
        STAA    T_P
        STAB    T_P+1
        LDX     T_P         ; X now points to the word
        JSR     PR_WORD
        JSR     PR_SPCB
        LDX     T_Y         ; restore table pointer
        INX                 ; move to next entry
        INX                 ; (2 bytes per entry)
        BRA     PR_PH1
PR_PH2:  RTS


; -----------------------------------------------------
; Outputs a word based on value in A
; -----------------------------------------------------
; TODO See new routine below.

;PR_WORD:     INCA    ;
;            LDX     #WORDPTR  ; base of offset table
;PR_WORD1:    DECA
;            BEQ     FOUNDW
;            INX                 ; move to next address
;            INX
;            BNE     PR_WORD1    ; loop around to retest
;FOUNDW:      LDAA    0,X
;            STAA    T_X
;            LDAA    1,X
;            STAA    T_X+1
;            LDX     T_X
;            JSR     STRINGBX
;            RTS

; -----------------------------------------------------
; Outputs a word based on value in X
; -----------------------------------------------------
PR_WORD:
            STX     T_X             ; use ASL and ROL to multiply by 2 (pointer is 2 bytes wide)
            ASL     T_X+1           ; shift low byte left, bit 7 goes to carry
            ROL     T_X             ; rotate high byte left, carry in from low byte
            LDX     T_X
            STX     T_X             ; Stash X
            LDAA    T_X             ; High byte of X
            LDAB    T_X+1           ; Low byte of X
            ADDB    #<WORDPTR    ; Add low byte of WORDPTR address
            ADCA    #>WORDPTR    ; Add high byte of WORDPTR address + carry
            STAA    T_X             ; T_X has the address of the pointer NOT the word
            STAB    T_X+1
            LDX     T_X             ; X has the address of the pointer NOT the word

            LDAA    0,X             ; get the hi byte of the word
            STAA    T_X
            LDAA    1,X             ; get the low byte of the word
            STAA    T_X+1
            LDX     T_X             ; X now has address of the word
            JSR     STRINGBX        ; output the word
            RTS

                .include    "words.asm"
                .include    "phrases.asm"

; -----------------------------------------------------
; Phrases (each holds a list of word pointers)
; -----------------------------------------------------
;All valid weight messages include ...
;
;   Greeting message (waiting for the weight to settle)
;   the weight message
;   comment.


; -----------------------------------------------------
; Reserved memory
; -----------------------------------------------------

T_Q:             .rmb     1       ; Temp storage for ZIN
T_Z:             .rmb     2       ;   "     "     "  RDX
T_X:             .rmb     2       ;   "     "     "  PR_WORD
T_Y:             .rmb     2       ;   "     "     "  table pointer
T_P:             .rmb     2       ;   "     "     "  PR_PHRASE
T_W:             .rmb     2       ;   "     "     "  PR_WEIGHT
T_TMP:           .rmb     2       ;   "     "     "  within subroutine
DEC:             .rmb     3       ; for decimal value
RND:             .rmb     1       ; holds a random number (see RD_B
TEMP:            .rmb     2       ; temp var (non subroutine use)
T_WEIGHT:        .rmb     2       ; holds value of weight following a call to GETDATA
IDLE_COUNT:      .rmb     1       ; counts the number of empty measurement reports
IDLE_MSG_ID:     .rmb     1       ; holds value of next idle message to use
GREET_MSG_ID:    .rmb     1       ; holds value of next greeting message to use
LIGHT_MSG_ID:    .rmb     1       ; holds value of next light weight message to use
NORMAL_MSG_ID:   .rmb     1       ; holds value of next normal weight message to use
HEAVY_MSG_ID:    .rmb     1       ; holds value of next heavy weight message to use
SHEAVY_MSG_ID:   .rmb     1       ; holds value of next super heavy weight message to use


