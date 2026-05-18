;------------------------------------------------------------------
; text2speech.asm
;------------------------------------------------------------------

                .area   CODE1 (ABS)     ; absolute i.e. not relocatable

; -----------------------------------------------------
; Reserved memory
; -----------------------------------------------------
                 .org    0x0000

T_Q:             .rmb     1       ; Temp storage for ZIN
T_Z:             .rmb     2       ;   "     "     "  RDX
T_X:             .rmb     2       ;   "     "     "  PR_WORD
T_Y:             .rmb     2       ;   "     "     "  table pointer
T_P:             .rmb     2       ;   "     "     "  PR_PHRASE
T_W:             .rmb     2       ;   "     "     "  PR_WEIGHT
T_TMP:           .rmb     2       ;   "     "     "  within subroutine
TEMP:            .rmb     2       ; temp var (non subroutine use)
T_WEIGHT:        .rmb     2       ; holds value of weight following a call to GETDATA

; these are cleared at start up
IDLE_COUNT:      .rmb     1       ; counts the number of empty measurement reports
IDLE_MSG_ID:     .rmb     1       ; holds value of next idle message to use
GREET_MSG_ID:    .rmb     1       ; holds value of next greeting message to use
LIGHT_MSG_ID:    .rmb     1       ; holds value of next light weight message to use
NORMAL_MSG_ID:   .rmb     1       ; holds value of next normal weight message to use
HEAVY_MSG_ID:    .rmb     1       ; holds value of next heavy weight message to use
SHEAVY_MSG_ID:   .rmb     1       ; holds value of next super heavy weight message to use
PROCESSING_FLG:  .rmb     1       ; non-zero indicates that that a weight is being processed
                                  ;   all following weight data is ignored until the next
                                  ;   idle (0000h) data resets it.
WORDS:           .rmb     1       ; number of words for the panel LED routines
                                  ;  this is updated each time a word is transmitted.

; TODO Have a lead character (invalid hex) on each packet from the scales
;   and either restart the receive sequence with an invalid hex or wait for the
;   start packet character (make it printable e.g. '@' or 'Z' etc.


;LREAD   JSR     RD_CMD      ; Read+Echo, test for '.'
;        CMPA    #'S         ; Is it `S` ?
;        BNE     LREAD       ; No: Keep waiting for `S`
;        JSR     RD_CMD      ; Read+Echo, test for '.'


                .org    0x0200

STACK           .equ    0x01FF
DATAA           .equ    0xF400          ; ACIA(a) Data register
CTRLA           .equ    0xF401          ; ACIA(a) Ctrl/Status
DATAB           .equ    0xF402          ; ACIA(b) Data register
CTRLB           .equ    0xF403          ; ACIA(b) Ctrl/Status

; MINIMON routines
STRING          .equ    0xFC76          ; Prints a string.
GETADD          .equ    0xFC89          ; Get Address, read 4 digit hex value.
ZOUT            .equ    0xFCC9          ; Print value in A as 2 hex digits.
NEWLINE         .equ    0xFE97          ; Prints a new line.
START           .equ    0xFF8F          ; Restarts MniMon.
PR_A            .equ    0xFC0F          ; Print char in A to ACIA (a)
RD_A            .equ    0xFD2B          ; Read char from A
PRSP            .equ    0xFD4D          ; Print a space
BINARY          .equ    0xFC31          ; Converts ASCII hex digits in A and B to binary?
RD_X            .equ    0xFC65          ; Read 4 hex digits Value from ACIA(a) and put value into X.
VHEX            .equ    0xFC1D          ; Checks that A contains a HEX character
PRX             .equ    0xFCBB          ; print val in X as four hex digits

PANEL           .equ    0xF0FF          ; LEDs and switches
DELAY_VAL       .equ    0x0B00          ; Delay loop count - adjust to taste (16 BIT VALUE)
ASC_STX         .equ    0x40            ; Start of Text

IDLE_TICS       .equ   45              ; ticks between idle messages (1 tic = 2 secs approx)
SHEAVY_WGHT     .equ    15              ; >= 15 stones
HEAVY_WGHT      .equ    13              ; >= 13 stones
NORM_WGHT       .equ    10              ; >= 10 stones
LIGHT_WGHT      .equ    6               ; >= 6 stones
TOO_HEAVY       .equ    20

; number of messages
GREET_MSG_CNT   .equ    13
LIGHT_MSG_CNT   .equ    10
NORM_MSG_CNT    .equ    21
HEAVY_MSG_CNT   .equ    18
SHEAVY_MSG_CNT  .equ    10
IDLE_MSG_CNT    .equ    25

INIT:
                ; set the stack
                LDS     #STACK

                ; clear the counters
                CLR     IDLE_COUNT
                CLR     IDLE_MSG_ID
                CLR     GREET_MSG_ID
                CLR     LIGHT_MSG_ID
                CLR     NORMAL_MSG_ID
                CLR     HEAVY_MSG_ID
                CLR     SHEAVY_MSG_ID
                CLR     PROCESSING_FLG
                CLR     WORDS
                CLR     PANEL

                ; initialise serial port B
                LDAA    #0x11           ; 8 Data, No Parity, 2 Stop Bits
                STAA    CTRLB           ;   ACIA.A

                JSR STRING
                .fcc    "I Speak Your Weight (c) John Newcombe 2026"
                .Fcb    0x0d, 0x0a, 0xff

                ; initialise the speach processor
                ;   @R6 = excitability (Default=3)
                ;   @W2 = speed (Default=3)
                ;   @F8 = pitch center (Default=8)
                ;   @V3 = one of six preset voices
                ;   @K0 = male or non-male table
                ;
                JSR STRINGB
                .fcc    "@R6@W2@F8@V3@K0"
                .fcb    0x0d, 0x0a, 0xFF

MAINLOOP:
; -----------------------------------------------------
; Data arrives at port B as four hex characters
; -----------------------------------------------------
                JSR     GETDATA         ; value in T_WEIGHT, stones in A
                BCS     ML1             ; is it invalid i.e. carry clear
                JMP     IDLE
ML1:            TST     PROCESSING_FLG  ; are we already processing a weight
                BNE     MAINLOOP        ; flag non-zero so ignore everything that follows
                INC     PROCESSING_FLG  ; ignore any following data until we next idle
                CMPA    #TOO_HEAVY      ; more that 20 is too heavy
                BHI     OVERLOADED
                LDAA    T_WEIGHT+1      ; validate pounds
                CMPA    #13             ; invalid pounds
                BHI     IERROR          ; internal error
                JSR     GREET           ; send a greeting message

                ; get the weight a second time, this should allow the scales time to settle
                JSR     GETDATA

                ; output "you weigh" maybe use a phrase rather than individual words
                LDX     #MYOUWEIGH
                JSR     PR_PHRASE
                LDX     T_WEIGHT        ; restore X
                JSR     PR_WEIGHT       ; weight back X so output the weight

                ; output a comments
                LDAA    T_WEIGHT        ; stones
                CMPA    #SHEAVY_WGHT
                BLO     ML2             ; not super heavy weight
                JMP     SHEAVYW
ML2:            CMPA    #HEAVY_WGHT
                BLO     ML3             ; not heavy weight
                JMP     HEAVYW
ML3:            CMPA    #NORM_WGHT
                BLO     ML4             ; not normal weight
                JMP     NORMALW
ML4:            CMPA    #LIGHT_WGHT
                BLO     ML5             ; not light weight
                JMP     LIGHTW
ML5:            JMP     MAINLOOP        ; no comments for less than light weight

; -----------------------------------------------------
; Over 20 stone so random heavy phrase to ports B
; -----------------------------------------------------
OVERLOADED:
                JSR     STRING
                .fcc    "ST:SOFL "
                .fcb    0x20,0xff
                LDX     #MTOOHEAVY1
                JSR     PR_PHRASE
                JSR     PR_CRB
                JMP     MAINLOOP
IERROR:
                JSR     STRING
                .fcc    "ST:IERR "
                .fcb    0x20,0xff
                LDX     #MERROR
                JSR     PR_PHRASE
                JSR     PR_CRB
                JMP     MAINLOOP

; we cycle thought idle message when no one is on the scales, data comes in a one
; second intervals so we simply increase the idle count until it's time to display
; the next idle message

IDLE:   CLR     PROCESSING_FLG  ; clear the processing flag as no one
                                ;   is standing on the scales
        INC     IDLE_COUNT      ; increase the idle count
        LDAA    IDLE_COUNT      ; see if idle count = max idle time
        CMPA    #IDLE_TICS      ; a data message appears every second
        BEQ     IDLE1           ; not reached the max idle time
        JMP     MAINLOOP             ; nothing to do yet

IDLE1:  JSR     STRING
        .fcc    "ST:IMSG "
        .fcb    0x20,0xff
        CLR     IDLE_COUNT      ; time to output an idle message so reset the count
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
        JSR     STRING
        .fcc    "ST:GMSG "
        .fcb    0x20,0xff
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
        JSR     STRING
        .fcc    "ST:LMSG "
        .fcb    0x20,0xff
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
        JSR     STRING
        .fcc    "ST:NMSG "
        .fcb    0x20,0xff
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
        JSR     STRING
        .fcc    "ST:HMSG "
        .fcb    0x20,0xff
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
        JSR     STRING
        .fcc    "ST:SMSG "
        .fcb    0x20,0xff
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
        JSR     STRING
        .fcc    "DR:"
        .fcb    0xff
        LDX     T_WEIGHT
        JSR     PRX             ; print the data
        JSR    PRSP
        CLC
        LDAA    T_WEIGHT        ; get fist byte (stones)
        BEQ     GDDONE          ; idle message
        CLR     IDLE_TICS       ; not an idle message so reset the idle counter
        SEC                     ; non idle message return with carry set
GDDONE:  RTS

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
         LDAB    PANEL
         BITB     #1
         BEQ     STRB    ; panel switch 0 is debug and copies data to A
         JSR     PR_A    ; Print the byte to ACIA(a) (A is maintained)
                         ;  DEBUG depending on panel data switch zero
STRB:    BSR     PR_B    ; Print the byte to ACIA(b)
         BRA     STRB1   ; Go back for next byte
ENDSTR:  INS             ; Clean up stack...
         INS             ;  ( pop off the return addr )
         JMP     1,X     ; Jump back to caller (RETURN)

; -----------------------------------------------------
; Prints a string pointed to by X
; -----------------------------------------------------
STRINGBX:   LDAA    0,X         ; get char
            CMPA    #0xFF        ; is character NULL?
            BEQ     DONEB       ; yes, end of string
            LDAB    PANEL
            BITB    #1
            BEQ     STRBX       ; panel switch 0 is debug and copies data to A
            JSR     PR_A        ; Print the byte to ACIA(a) (A is maintained)
STRBX:      BSR     PR_B        ; Print the byte to ACIA(b)
            INX
            BRA     STRINGBX
DONEB:      RTS

; -----------------------------------------------------
; Reads a character from ACIA(b) into A
; -----------------------------------------------------
RD_B:   LDAA    CTRLB       ; Get ACIA.A status byte
        BITA    #01         ; Is byte ready in DATAb
        BEQ     RD_B        ; No: Try again
        LDAA    DATAB       ; Get the data byte to A
        ;STAA     PANEL
        ANDA    #0x7F        ; Mask off parity bit if it exists
        RTS                 ; RETURN

; -----------------------------------------------------
; Reads 2 hex ascii characters and saves them the
; byte value to A e.g. "0F" received is stored to A as
; 15d.
; This version ignores non-hex characters
; -----------------------------------------------------
ZINB:   BSR     RD_B    ; Read a character
        JSR     VHEX    ; Is it a hex character ?
        BCC     ZINBA   ; No: go to print `?`
        LDAA    #0xFF
ZINBA:  STAA    T_Q     ; Yes: Save Acc.A
        BSR     RD_B    ; Read 2nd character
        JSR     VHEX    ; Is it a hex character ?
        BCC     ZINBB   ; No: go to print `?`
        LDAA    #0xFF
ZINBB:  TAB             ; Yes: Put it into Acc.B
        LDAA    T_Q     ; Retrieve 1st hex char to Acc.A
        JSR     BINARY  ; Convert A:B to binary
        RTS             ; RETURN

; -----------------------------------------------------
; Print character in A to ACIA(b)
; -----------------------------------------------------
PR_B:    LDAB    CTRLB   ; Get ACIA(a) status byte
        BITB    #02     ; Is it busy ?
        BEQ     PR_B    ; Yes: Try again
        STAA    DATAB   ;  No: Send data
        STAA    PANEL
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
; Loads X with A, A is preserved.
; -----------------------------------------------------
TAX:    STAA    T_TMP+1       ; store A as low byte of X
        CLR     T_TMP         ; zero the high byte
        LDX     T_TMP         ; load X
        RTS

; -----------------------------------------------------
; Prints the message " n stones n pounds"
; place stones in MSB of X and pound in LSB
; -----------------------------------------------------
PR_WEIGHT:

        STX     T_W
        LDAA    T_W
        JSR     TAX
        JSR     PR_WORD         ; n
        JSR     PR_SPCB
        LDX     #STONES
        JSR     PR_WORD         ; "stones"
        JSR     PR_SPCB
        LDAA    T_W+1            ; Load high byte of X into Accumulator A
        JSR     TAX
        JSR     PR_WORD         ; n
        LDX     #POUNDS
        JSR     PR_SPCB
        JSR     PR_WORD         ; "pounds"
        JSR     PR_CRB
        RTS

; -----------------------------------------------------
; Prints a space on both consoles (preserves A)
; -----------------------------------------------------
PR_SPCB: PSHA
        LDAA    #0x20        ; Put space character in A
        ;JSR     PR_A
        JSR     PR_B        ; Print it
        PULA
        RTS                 ; RETURN

; -----------------------------------------------------
; Prints a CRLF on both consoles (preserves A)
; -----------------------------------------------------
PR_CRB:     PSHA
            LDAA    #0x0D        ; Put CHAR character in A
            JSR     PR_A
            JSR     PR_B        ; Print it
            LDAA    #0x0A
            LDAB     PANEL
            BITB    #1
            BEQ     PR_CRB1
            JSR     PR_A
PR_CRB1:    JSR     PR_B        ; Print it
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
            INC     WORDS
            JSR     PRSP
            RTS

                .include    "words.asm"
                .include    "phrases.asm"
