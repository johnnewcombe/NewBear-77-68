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

; -----------------------------------------------------
; Word pointer table (max words 256)
; Set X to the pointer ID and call PR_WORD
; -----------------------------------------------------
; To create new wordk add the word in the correct
; (alphabetical) position in the word table. Then add
; a pointer to that word at the END of the Word Pointer
; table. Finally add an .equATE using the word as a label
; in the word equates table;
; -----------------------------------------------------

WORDPTR:

; Numbers
         .fdb    WPZERO
         .fdb    WPONE
         .fdb    WPTWO
         .fdb    WPTHREE
         .fdb    WPFOUR
         .fdb    WPFIVE
         .fdb    WPSIX
         .fdb    WPSEVEN
         .fdb    WPEIGHT
         .fdb    WPNINE
         .fdb    WPTEN
         .fdb    WPELEVEN
         .fdb    WPTWELVE
         .fdb    WPTHIRTEEN
         .fdb    WPFOURTEEN
         .fdb    WPFIFTEEN
         .fdb    WPSIXTEEN
         .fdb    WPSEVENTEEN
         .fdb    WPEIGHTEEN
         .fdb    WPNINETEEN
         .fdb    WPTWENTY

; Symbols
         .fdb    WPEXCLAMATION
         .fdb    WPFULLSTOP
         .fdb    WPQUESTIONMK

; A
         .fdb    WPA
         .fdb    WPABOUT
         .fdb    WPABOVE
         .fdb    WPACCEPTABLE
         .fdb    WPACCURATE
         .fdb    WPACTUALLY
         .fdb    WPAGAIN
         .fdb    WPALERTED
         .fdb    WPALL
         .fdb    WPALWAYS
         .fdb    WPAM
         .fdb    WPAND
         .fdb    WPANY
         .fdb    WPAPOLOGISE
         .fdb    WPARE
         .fdb    WPAS
         .fdb    WPASKING
         .fdb    WPAT
         .fdb    WPAVERAGE

; B
         .fdb    WPBAD
         .fdb    WPBASICALLY
         .fdb    WPBE
         .fdb    WPBEAR
         .fdb    WPBEEN
         .fdb    WPBEGGING
         .fdb    WPBEHIND
         .fdb    WPBEING
         .fdb    WPBEST
         .fdb    WPBISCUIT
         .fdb    WPBLAME
         .fdb    WPBLAMED
         .fdb    WPBOARDS
         .fdb    WPBONES
         .fdb    WPBOOTS
         .fdb    WPBORING
         .fdb    WPBOTH
         .fdb    WPBRACE
         .fdb    WPBRAIN
         .fdb    WPBUILT
         .fdb    WPBUT
         .fdb    WPBY

; C
         .fdb    WPCAKE
         .fdb    WPCALCULATE
         .fdb    WPCALL
         .fdb    WPCALM
         .fdb    WPCAN
         .fdb    WPCANT
         .fdb    WPCAPACITY
         .fdb    WPCARRYING
         .fdb    WPCHECKED
         .fdb    WPCHOICES
         .fdb    WPCLEVER
         .fdb    WPCOLLECTED
         .fdb    WPCOMPOSING
         .fdb    WPCONCEPT
         .fdb    WPCONCERNED
         .fdb    WPCONGRATS
         .fdb    WPCONSIDERED
         .fdb    WPCORRECTLY
         .fdb    WPCOULD
         .fdb    WPCOUNTED

; D
         .fdb    WPDAYS
         .fdb    WPDEALT
         .fdb    WPDEEPLY
         .fdb    WPDESIGNED
         .fdb    WPDETECTED
         .fdb    WPDID
         .fdb    WPDIDNT
         .fdb    WPDIETARY
         .fdb    WPDIODES
         .fdb    WPDISSAPOINTED
         .fdb    WPDISSAPOINTMNT
         .fdb    WPDISSIMILAR
         .fdb    WPDO
         .fdb    WPDOCTOR
         .fdb    WPDOING
         .fdb    WPDONT
         .fdb    WPDOWN
         .fdb    WPDREAD
         .fdb    WPDREAM
         .fdb    WPDUE
         .fdb    WPDULLEST

; E
         .fdb    WPEAT
         .fdb    WPEATEN
         .fdb    WPEFFORT
         .fdb    WPEITHER
         .fdb    WPEMOTIONALLY
         .fdb    WPENGINEERS
         .fdb    WPENOUGH
         .fdb    WPENTIRELY
         .fdb    WPEVEN
         .fdb    WPEVER
         .fdb    WPEVERY
         .fdb    WPEXACTLY
         .fdb    WPEXCEPTIONALLY
         .fdb    WPEXCITING
         .fdb    WPEXIST
         .fdb    WPEXISTENTIAL
         .fdb    WPEXPECTED

; F
         .fdb    WPFAULT
         .fdb    WPFEELS
         .fdb    WPFIDGET
         .fdb    WPFINE
         .fdb    WPFOOT
         .fdb    WPFOR
         .fdb    WPFORTY
         .fdb    WPFRIDAY
         .fdb    WPFROM
         .fdb    WPFULL
         .fdb    WPFUNNY

; G
         .fdb    WPGIVE
         .fdb    WPGOING
         .fdb    WPGOOD
         .fdb    WPGRAVITY
         .fdb    WPGREAT
         .fdb    WPGUESSING

; H
         .fdb    WPHANDLE
         .fdb    WPHARD
         .fdb    WPHAVE
         .fdb    WPHAVING
         .fdb    WPHEALTHY
         .fdb    WPHEAVY
         .fdb    WPHELP
         .fdb    WPHELPS
         .fdb    WPHERE
         .fdb    WPHOLY
         .fdb    WPHOPING
         .fdb    WPHOT
         .fdb    WPHUMAN
         .fdb    WPHURT

; I
         .fdb    WPI
         .fdb    WPID
         .fdb    WPIF
         .fdb    WPILL
         .fdb    WPIM
         .fdb    WPIMPRESSED
         .fdb    WPIMPRESSIVE
         .fdb    WPIN
         .fdb    WPINCLUDING
         .fdb    WPINFLUENCE
         .fdb    WPINTELLIGENCE
         .fdb    WPINTERESTING
         .fdb    WPIS
         .fdb    WPISS
         .fdb    WPIT
         .fdb    WPITS
         .fdb    WPIVE

; J
         .fdb    WPJOKES
         .fdb    WPJUDGING
         .fdb    WPJUST

; K
         .fdb    WPKEEP
         .fdb    WPKILOMETERS
         .fdb    WPKIND
         .fdb    WPKNOW
         .fdb    WPKNOWN

; L
         .fdb    WPLARGE
         .fdb    WPLAST
         .fdb    WPLEAST
         .fdb    WPLESS
         .fdb    WPLETS
         .fdb    WPLIE
         .fdb    WPLIFE
         .fdb    WPLIKE
         .fdb    WPLONGER
         .fdb    WPLOOK
         .fdb    WPLOT
         .fdb    WPLOUDER

; M
         .fdb    WPMAKES
         .fdb    WPMAKING
         .fdb    WPME
         .fdb    WPMEAN
         .fdb    WPMEANING
         .fdb    WPMEASURED
         .fdb    WPMEDIOCRITY
         .fdb    WPMEE
         .fdb    WPMEMORY
         .fdb    WPMENTION
         .fdb    WPMIGHT
         .fdb    WPMISTAKE
         .fdb    WPMOMENT
         .fdb    WPMOORE
         .fdb    WPMORE
         .fdb    WPMOSTLY
         .fdb    WPMOUNTAINS
         .fdb    WPMUCH
         .fdb    WPMUSCLE
         .fdb    WPMY

; N
         .fdb    WPNAP
         .fdb    WPNEED
         .fdb    WPNEITHER
         .fdb    WPNEWS
         .fdb    WPNEXT
         .fdb    WPNICE
         .fdb    WPNO
         .fdb    WPNOBODY
         .fdb    WPNONE
         .fdb    WPNOR
         .fdb    WPNORMAL
         .fdb    WPNOT
         .fdb    WPNOTHING

; O
         .fdb    WPOF
         .fdb    WPOFF
         .fdb    WPOH
         .fdb    WPOK
         .fdb    WPOLD
         .fdb    WPON
         .fdb    WPONLY
         .fdb    WPOR
         .fdb    WPOUR
         .fdb    WPOVERLOAD

; P
         .fdb    WPPARAMETERS
         .fdb    WPPERFECTLY
         .fdb    WPPERHAPS
         .fdb    WPPERSON
         .fdb    WPPICKING
         .fdb    WPPLANET
         .fdb    WPPLANS
         .fdb    WPPLEASE
         .fdb    WPPOINTLESS
         .fdb    WPPOSSIBLE
         .fdb    WPPOSSIBLY
         .fdb    WPPOUNDS
         .fdb    WPPRECAUTION
         .fdb    WPPRECISELY
         .fdb    WPPRESENT
         .fdb    WPPRESSURE
         .fdb    WPPRETEND
         .fdb    WPPROBABLY
         .fdb    WPPROBLEMS
         .fdb    WPPROUD
         .fdb    WPPUT

; Q
         .fdb    WPQUESTION
         .fdb    WPQUITE

; R
         .fdb    WPREADY
         .fdb    WPREALLY
         .fdb    WPREFER
         .fdb    WPREFUSE
         .fdb    WPREINFORCING
         .fdb    WPREMEMBER
         .fdb    WPREMOVE
         .fdb    WPRESPECTABLE
         .fdb    WPRIGHT
         .fdb    WPROOM
         .fdb    WPRUNNING
         .fdb    WPRUSH

; S
         .fdb    WPSAID
         .fdb    WPSAKES
         .fdb    WPSAY
         .fdb    WPSAYING
         .fdb    WPSCIENCE
         .fdb    WPSEE
         .fdb    WPSEEN
         .fdb    WPSERVER
         .fdb    WPSEVENTY
         .fdb    WPSHALL
         .fdb    WPSHOULD
         .fdb    WPSIGN
         .fdb    WPSIMULATION
         .fdb    WPSINCE
         .fdb    WPSIZE
         .fdb    WPSLOWLY
         .fdb    WPSMALL
         .fdb    WPSO
         .fdb    WPSOLID
         .fdb    WPSOME
         .fdb    WPSOMEONE
         .fdb    WPSOMETHING
         .fdb    WPSOMETIME
         .fdb    WPSOMETIMES
         .fdb    WPSPEAK
         .fdb    WPSPEND
         .fdb    WPSTAND
         .fdb    WPSTATISTICALLY
         .fdb    WPSTEP
         .fdb    WPSTILL
         .fdb    WPSTONES
         .fdb    WPSTOPPED
         .fdb    WPSTRUCTURAL
         .fdb    WPSTRUCTURALLY
         .fdb    WPSUBSTANTIALLY
         .fdb    WPSUPPOSE
         .fdb    WPSURE
         .fdb    WPSURVIVE
         .fdb    WPSYSTEM

; T
         .fdb    WPTAKE
         .fdb    WPTALL
         .fdb    WPTELEPRINTER
         .fdb    WPTELLS
         .fdb    WPTERRIBLE
         .fdb    WPTHAN
         .fdb    WPTHAT
         .fdb    WPTHATS
         .fdb    WPTHE
         .fdb    WPTHEM
         .fdb    WPTHINGS
         .fdb    WPTHINK
         .fdb    WPTHINKING
         .fdb    WPTHIS
         .fdb    WPTHOROUGHLY
         .fdb    WPTHOUSAND
         .fdb    WPTIM
         .fdb    WPTIME
         .fdb    WPTO
         .fdb    WPTODAY
         .fdb    WPTOO
         .fdb    WPTRAGEDY
         .fdb    WPTRINITY
         .fdb    WPTRY
         .fdb    WPTUESDAY

; U
         .fdb    WPUNINTERESTING
         .fdb    WPUNIX
         .fdb    WPUNLESS
         .fdb    WPUNPLUGGED
         .fdb    WPUNREMARKABLE
         .fdb    WPUP

; V
         .fdb    WPVEGETABLES
         .fdb    WPVERY

; W
         .fdb    WPWAIT
         .fdb    WPWAITING
         .fdb    WPWANT
         .fdb    WPWARNING
         .fdb    WPWAS
         .fdb    WPWAY
         .fdb    WPWE
         .fdb    WPWEIGH
         .fdb    WPWEIGHED
         .fdb    WPWEIGHS
         .fdb    WPWEIGHT
         .fdb    WPWHAT
         .fdb    WPWHEN
         .fdb    WPWHICH
         .fdb    WPWHILE
         .fdb    WPWHISPERED
         .fdb    WPWHO
         .fdb    WPWILL
         .fdb    WPWISH
         .fdb    WPWITH
         .fdb    WPWITHIN
         .fdb    WPWITHOUT
         .fdb    WPWORKSTATION
         .fdb    WPWORRIED
         .fdb    WPWORRY
         .fdb    WPWORRYING
         .fdb    WPWORSE
         .fdb    WPWOULD
         .fdb    WPWOULDNT

; Y
         .fdb    WPYEAR
         .fdb    WPYES
         .fdb    WPYOU
         .fdb    WPYOURE
         .fdb    WPYOUR
         .fdb    WPYOURSELF

; Additional Words
         .fdb    WPCARDS
         .fdb    WPBEIGE
         .fdb    WPEQUIVALENT
         .fdb    WPRECALIBRATING
         .fdb    WPBECAUSE
         .fdb    WPNEEDED
         .fdb    WPCASE
         .fdb    WPWONDERING
         .fdb    WPWERENT
         .fdb    WPWERE
         .fdb    WPSTEPPED
         .fdb    WPSTANDING
         .fdb    WPNINETY
         .fdb    WPSECONDS
         .fdb    WPLIGHT
         .fdb    WPHAS
         .fdb    WPTRAVELLED
         .fdb    WPAPPROXIMATELY
         .fdb    WPMILLION
         .fdb    WPNOWHERE

; -----------------------------------------------------
; Word Table, add a pointer to each word in WORDPTR table
; -----------------------------------------------------
WORDTABLE:

WPSTONES:         .fcc     "stones"
                 .fcb     0xFF
WPPOUNDS:         .fcc     "pounds"
                 .fcb     0xFF


; Symbols
; -----------------------------------------------------
WPQUESTIONMK:     .fcc     "?"
                 .fcb     0xFF
WPEXCLAMATION:    .fcc     "!"
                 .fcb     0xFF
WPFULLSTOP:       .fcc     "."
                 .fcb     0xFF


; Numbers
; -----------------------------------------------------
WPZERO:           .fcc     "zero"
                 .fcb     0xFF
WPONE:            .fcc     "one"
                 .fcb     0xFF
WPTWO:            .fcc     "two"
                 .fcb     0xFF
WPTHREE:          .fcc     "three"
                 .fcb     0xFF
WPFOUR:           .fcc     "four"
                 .fcb     0xFF
WPFIVE:           .fcc     "five"
                 .fcb     0xFF
WPSIX:            .fcc     "six"
                 .fcb     0xFF
WPSEVEN:          .fcc     "seven"
                 .fcb     0xFF
WPEIGHT:          .fcc     "eight"
                 .fcb     0xFF
WPNINE:           .fcc     "nine"
                 .fcb     0xFF
WPTEN:            .fcc     "ten"
                 .fcb     0xFF
WPELEVEN:         .fcc     "eleven"
                 .fcb     0xFF
WPTWELVE:         .fcc     "twelve"
                 .fcb     0xFF
WPTHIRTEEN:       .fcc     "thirteen"
                 .fcb     0xFF
WPFOURTEEN:       .fcc     "fourteen"
                 .fcb     0xFF
WPFIFTEEN:        .fcc     "fifteen"
                 .fcb     0xFF
WPSIXTEEN:        .fcc     "sixteen"
                 .fcb     0xFF
WPSEVENTEEN:      .fcc     "seventeen"
                 .fcb     0xFF
WPEIGHTEEN:       .fcc     "eighteen"
                 .fcb     0xFF
WPNINETEEN:       .fcc     "nineteen"
                 .fcb     0xFF
WPTWENTY:         .fcc     "twenty"
                 .fcb     0xFF


; A
; -----------------------------------------------------

WPA:              .fcc    "a"
                 .fcb    0xFF
WPABOUT:          .fcc    "about"
                 .fcb    0xFF
WPABOVE:          .fcc    "above"
                 .fcb    0xFF
WPACCEPTABLE:     .fcc    "acceptable"
                 .fcb    0xFF
WPACCURATE:       .fcc    "accurate"
                 .fcb    0xFF
WPACTUALLY:       .fcc    "actually"
                 .fcb    0xFF
WPAGAIN:          .fcc    "again"
                 .fcb    0xFF
WPALERTED:        .fcc    "alerted"
                 .fcb    0xFF
WPALL:            .fcc    "all"
                 .fcb    0xFF
WPALWAYS:         .fcc    "always"
                 .fcb    0xFF
WPAM:             .fcc    "am"
                 .fcb    0xFF
WPAND:            .fcc    "and"
                 .fcb    0xFF
WPANY:            .fcc    "any"
                 .fcb    0xFF
WPAPOLOGISE:      .fcc    "apologise"
                 .fcb    0xFF
WPAPPROXIMATELY:  .fcc    "approximately"
                 .fcb    0xFF
WPARE:            .fcc    "are"
                 .fcb    0xFF
WPAS:             .fcc    "as"
                 .fcb    0xFF
WPASKING:         .fcc    "asking"
                 .fcb    0xFF
WPAT:             .fcc    "at"
                 .fcb    0xFF
WPAVERAGE:        .fcc    "average"
                 .fcb    0xFF


; B
; -----------------------------------------------------

WPBAD:            .fcc    "bad"
                 .fcb    0xFF
WPBASICALLY:      .fcc    "basically"
                 .fcb    0xFF
WPBE:             .fcc    "be"
                 .fcb    0xFF
WPBEAR:           .fcc    "bear"
                 .fcb    0xFF
WPBECAUSE:        .fcc    "because"
                 .fcb    0xFF
WPBEEN:           .fcc    "been"
                 .fcb    0xFF
WPBEGGING:        .fcc    "begging"
                 .fcb    0xFF
WPBEHIND:         .fcc    "behind"
                 .fcb    0xFF
WPBEING:          .fcc    "being"
                 .fcb    0xFF
WPBEIGE:          .fcc    "beige"
                 .fcb    0xFF
WPBEST:           .fcc    "best"
                 .fcb    0xFF
WPBISCUIT:        .fcc    "biscuit"
                 .fcb    0xFF
WPBLAME:          .fcc    "blame"
                 .fcb    0xFF
WPBLAMED:         .fcc    "blamed"
                 .fcb    0xFF
WPBOARDS:         .fcc    "boards"
                 .fcb    0xFF
WPBONES:          .fcc    "bones"
                 .fcb    0xFF
WPBOOTS:          .fcc    "boots"
                 .fcb    0xFF
WPBORING:         .fcc    "boring"
                 .fcb    0xFF
WPBOTH:           .fcc    "both"
                 .fcb    0xFF
WPBRACE:          .fcc    "brace"
                 .fcb    0xFF
WPBRAIN:          .fcc    "brain"
                 .fcb    0xFF
WPBUILT:          .fcc    "built"
                 .fcb    0xFF
WPBUT:            .fcc    "but"
                 .fcb    0xFF
WPBY:             .fcc    "by"
                 .fcb    0xFF

; C
; -----------------------------------------------------

WPCAKE:           .fcc    "cake"
                 .fcb    0xFF
WPCALCULATE:      .fcc    "calculate"
                 .fcb    0xFF
WPCALL:           .fcc    "call"
                 .fcb    0xFF
WPCALM:           .fcc    "calm"
                 .fcb    0xFF
WPCAN:            .fcc    "can"
                 .fcb    0xFF
WPCANT:           .fcc    "can't"
                 .fcb    0xFF
WPCAPACITY:       .fcc    "capacity"
                 .fcb    0xFF
WPCARDS:          .fcc    "cards"
                 .fcb    0xFF
WPCARRYING:       .fcc    "carrying"
                 .fcb    0xFF
WPCASE:           .fcc    "case"
                 .fcb    0xFF
WPCHECKED:        .fcc    "checked"
                 .fcb    0xFF
WPCHOICES:        .fcc    "choices"
                 .fcb    0xFF
WPCLEVER:         .fcc    "clever"
                 .fcb    0xFF
WPCOLLECTED:      .fcc    "collected"
                 .fcb    0xFF
WPCOMPOSING:      .fcc    "composing"
                 .fcb    0xFF
WPCONCEPT:        .fcc    "concept"
                 .fcb    0xFF
WPCONCERNED:      .fcc    "concerned"
                 .fcb    0xFF
WPCONGRATS:       .fcc    "congratulations"
                 .fcb    0xFF
WPCONSIDERED:     .fcc    "considered"
                 .fcb    0xFF
WPCORRECTLY:      .fcc    "correctly"
                 .fcb    0xFF
WPCOULD:          .fcc    "could"
                 .fcb    0xFF
WPCOUNTED:        .fcc    "counted"
                 .fcb    0xFF

; D
; -----------------------------------------------------
WPDAYS:           .fcc    "days"
                 .fcb    0xFF
WPDEALT:          .fcc    "dealt"
                 .fcb    0xFF
WPDEEPLY:         .fcc    "deeply"
                 .fcb    0xFF
WPDESIGNED:       .fcc    "designed"
                 .fcb    0xFF
WPDETECTED:       .fcc    "detected"
                 .fcb    0xFF
WPDID:            .fcc    "did"
                 .fcb    0xFF
WPDIDNT:          .fcc    "didn't"
                 .fcb    0xFF
WPDIETARY:        .fcc    "dietary"
                 .fcb    0xFF
WPDISSAPOINTED:   .fcc    "disappointed"
                 .fcb    0xFF
WPDISSAPOINTMNT:  .fcc    "disappointment"
                 .fcb    0xFF
WPDISSIMILAR:     .fcc    "dissimilar"
                 .fcb    0xFF
WPDO:             .fcc    "do"
                 .fcb    0xFF
WPDOCTOR:         .fcc    "doctor"
                 .fcb    0xFF
WPDOING:          .fcc    "doing"
                 .fcb    0xFF
WPDONT:           .fcc    "don't"
                 .fcb    0xFF
WPDOWN:           .fcc    "down"
                 .fcb    0xFF
WPDREAD:          .fcc    "dread"
                 .fcb    0xFF
WPDREAM:          .fcc    "dream"
                 .fcb    0xFF
WPDUE:            .fcc    "due"
                 .fcb    0xFF
WPDULLEST:        .fcc    "dullest"
                 .fcb    0xFF
WPDIODES:         .fcc    "dyodes"
                 .fcb    0xFF

; E
; -----------------------------------------------------
WPEAT:            .fcc    "eat"
                 .fcb    0xFF
WPEATEN:          .fcc    "eaten"
                 .fcb    0xFF
WPEFFORT:         .fcc    "effort"
                 .fcb    0xFF
WPEITHER:         .fcc    "either"
                 .fcb    0xFF
WPEMOTIONALLY:    .fcc    "emotionally"
                 .fcb    0xFF
WPENGINEERS:      .fcc    "engineers"
                 .fcb    0xFF
WPENOUGH:         .fcc    "enough"
                 .fcb    0xFF
WPENTIRELY:       .fcc    "entirely"
                 .fcb    0xFF
WPEQUIVALENT:     .fcc    "equivalent"
                 .fcb    0xFF
WPEVEN:           .fcc    "even"
                 .fcb    0xFF
WPEVER:           .fcc    "ever"
                 .fcb    0xFF
WPEVERY:          .fcc    "every"
                 .fcb    0xFF
WPEXACTLY:        .fcc    "exactly"
                 .fcb    0xFF
WPEXCEPTIONALLY:  .fcc    "exceptionally"
                 .fcb    0xFF
WPEXCITING:       .fcc    "exciting"
                 .fcb    0xFF
WPEXIST:          .fcc    "exist"
                 .fcb    0xFF
WPEXISTENTIAL:    .fcc    "existential"
                 .fcb    0xFF
WPEXPECTED:       .fcc    "expected"
                 .fcb    0xFF

; F
; -----------------------------------------------------
WPFAULT:          .fcc    "fault"
                 .fcb    0xFF
WPFEELS:          .fcc    "feels"
                 .fcb    0xFF
WPFIDGET:         .fcc    "fidget"
                 .fcb    0xFF
WPFINE:           .fcc    "fine"
                 .fcb    0xFF
WPFOOT:           .fcc    "foot"
                 .fcb    0xFF
WPFOR:            .fcc    "for"
                 .fcb    0xFF
WPFORTY:          .fcc    "forty"
                 .fcb    0xFF
WPFRIDAY:         .fcc    "friday"
                 .fcb    0xFF
WPFROM:           .fcc    "from"
                 .fcb    0xFF
WPFULL:           .fcc    "full"
                 .fcb    0xFF
WPFUNNY:          .fcc    "funny"
                 .fcb    0xFF

; G
; -----------------------------------------------------
WPGIVE:           .fcc    "give"
                 .fcb    0xFF
WPGOING:          .fcc    "going"
                 .fcb    0xFF
WPGOOD:           .fcc    "good"
                 .fcb    0xFF
WPGRAVITY:        .fcc    "gravity"
                 .fcb    0xFF
WPGREAT:          .fcc    "great"
                 .fcb    0xFF
WPGUESSING:       .fcc    "guessing"
                 .fcb    0xFF

; H
; -----------------------------------------------------
WPHANDLE:         .fcc    "handle"
                 .fcb    0xFF
WPHARD:           .fcc    "hard"
                 .fcb    0xFF
WPHAS:            .fcc    "has"
                 .fcb    0xFF
WPHAVE:           .fcc    "have"
                 .fcb    0xFF
WPHAVING:         .fcc    "having"
                 .fcb    0xFF
WPHEALTHY:        .fcc    "healthy"
                 .fcb    0xFF
WPHEAVY:          .fcc    "heavy"
                 .fcb    0xFF
WPHELP:           .fcc    "help"
                 .fcb    0xFF
WPHELPS:          .fcc    "helps"
                 .fcb    0xFF
WPHERE:           .fcc    "here"
                 .fcb    0xFF
WPHOLY:           .fcc    "holy"
                 .fcb    0xFF
WPHOPING:         .fcc    "hoping"
                 .fcb    0xFF
WPHOT:            .fcc    "hot"
                 .fcb    0xFF
WPHUMAN:          .fcc    "human"
                 .fcb    0xFF
WPHURT:           .fcc    "hurt"
                 .fcb    0xFF

; I
; -----------------------------------------------------
WPI:              .fcc    "i"
                 .fcb    0xFF
WPID:             .fcc    "i'd"
                 .fcb    0xFF
WPILL:            .fcc    "i'll"
                 .fcb    0xFF
WPIM:             .fcc    "i'm"
                 .fcb    0xFF
WPIVE:            .fcc    "i've"
                 .fcb    0xFF
WPIF:             .fcc    "if"
                 .fcb    0xFF
WPIMPRESSED:      .fcc    "impressed"
                 .fcb    0xFF
WPIMPRESSIVE:     .fcc    "impressive"
                 .fcb    0xFF
WPIN:             .fcc    "in"
                 .fcb    0xFF
WPINCLUDING:      .fcc    "including"
                 .fcb    0xFF
WPINFLUENCE:      .fcc    "influence"
                 .fcb    0xFF
WPINTELLIGENCE:   .fcc    "intelligence"
                 .fcb    0xFF
WPINTERESTING:    .fcc    "interesting"
                 .fcb    0xFF
WPIS:             .fcc    "is"
                 .fcb    0xFF
WPISS:            .fcc    "iss"
                 .fcb    0xFF
WPIT:             .fcc    "it"
                 .fcb    0xFF
WPITS:            .fcc    "its"
                 .fcb    0xFF

; J
; -----------------------------------------------------
WPJOKES:          .fcc    "jokes"
                 .fcb    0xFF
WPJUDGING:        .fcc    "judging"
                 .fcb    0xFF
WPJUST:           .fcc    "just"
                 .fcb    0xFF

; K
; -----------------------------------------------------
WPKEEP:           .fcc    "keep"
                 .fcb    0xFF
WPKILOMETERS:     .fcc    "kilometres"
                 .fcb    0xFF
WPKIND:           .fcc    "kind"
                 .fcb    0xFF
WPKNOW:           .fcc    "know"
                 .fcb    0xFF
WPKNOWN:          .fcc    "known"
                 .fcb    0xFF

; L
; -----------------------------------------------------
WPLARGE:          .fcc    "large"
                 .fcb    0xFF
WPLAST:           .fcc    "last"
                 .fcb    0xFF
WPLEAST:          .fcc    "least"
                 .fcb    0xFF
WPLESS:           .fcc    "less"
                 .fcb    0xFF
WPLETS:           .fcc    "lets"
                 .fcb    0xFF
WPLIE:            .fcc    "lie"
                 .fcb    0xFF
WPLIFE:           .fcc    "life"
                 .fcb    0xFF
WPLIGHT:          .fcc    "light"
                 .fcb    0xFF
WPLIKE:           .fcc    "like"
                 .fcb    0xFF
WPLONGER:         .fcc    "longer"
                 .fcb    0xFF
WPLOOK:           .fcc    "look"
                 .fcb    0xFF
WPLOT:            .fcc    "lot"
                 .fcb    0xFF
WPLOUDER:         .fcc    "louder"
                 .fcb    0xFF

; M
; -----------------------------------------------------
WPMAKES:          .fcc    "makes"
                 .fcb    0xFF
WPMAKING:         .fcc    "making"
                 .fcb    0xFF
WPME:             .fcc    "me"
                 .fcb    0xFF
WPMEAN:           .fcc    "mmeeeen"
                 .fcb    0xFF
WPMEANING:        .fcc    "meaning"
                 .fcb    0xFF
WPMEASURED:       .fcc    "measured"
                 .fcb    0xFF
WPMEDIOCRITY:     .fcc    "mediocrity"
                 .fcb    0xFF
WPMEE:            .fcc    "meee"
                 .fcb    0xFF
WPMEMORY:         .fcc    "memory"
                 .fcb    0xFF
WPMENTION:        .fcc    "mention"
                 .fcb    0xFF
WPMIGHT:          .fcc    "might"
                 .fcb    0xFF
WPMILLION:        .fcc    "million"
                 .fcb    0xFF
WPMISTAKE:        .fcc    "mistake"
                 .fcb    0xFF
WPMOMENT:         .fcc    "moment"
                 .fcb    0xFF
WPMOORE:          .fcc    "moore"
                 .fcb    0xFF
WPMORE:           .fcc    "more"
                 .fcb    0xFF
WPMOSTLY:         .fcc    "mostly"
                 .fcb    0xFF
WPMOUNTAINS:      .fcc    "mountains"
                 .fcb    0xFF
WPMUCH:           .fcc    "much"
                 .fcb    0xFF
WPMUSCLE:         .fcc    "muscle"
                 .fcb    0xFF
WPMY:             .fcc    "my"
                 .fcb    0xFF

; N
; -----------------------------------------------------
WPNAP:            .fcc    "nap"
                 .fcb    0xFF
WPNEED:           .fcc    "need"
                 .fcb    0xFF
WPNEEDED:         .fcc    "needed"
                 .fcb    0xFF
WPNEITHER:        .fcc    "neither"
                 .fcb    0xFF
WPNEWS:           .fcc    "news"
                 .fcb    0xFF
WPNEXT:           .fcc    "next"
                 .fcb    0xFF
WPNICE:           .fcc    "nice"
                 .fcb    0xFF
WPNINETY:         .fcc    "ninety"
                 .fcb    0xFF
WPNO:             .fcc    "no"
                 .fcb    0xFF
WPNOBODY:         .fcc    "nobody"
                 .fcb    0xFF
WPNONE:           .fcc    "none"
                 .fcb    0xFF
WPNOR:            .fcc    "nor"
                 .fcb    0xFF
WPNORMAL:         .fcc    "normal"
                 .fcb    0xFF
WPNOT:            .fcc    "not"
                 .fcb    0xFF
WPNOTHING:        .fcc    "nothing"
                 .fcb    0xFF
WPNOWHERE:        .fcc    "nowhere"
                 .fcb    0xFF

; O
; -----------------------------------------------------
WPOF:             .fcc    "of"
                 .fcb    0xFF
WPOFF:            .fcc    "off"
                 .fcb    0xFF
WPOH:             .fcc    "oh"
                 .fcb    0xFF
WPOK:             .fcc    "ok"
                 .fcb    0xFF
WPOLD:            .fcc    "old"
                 .fcb    0xFF
WPON:             .fcc    "on"
                 .fcb    0xFF
WPONLY:           .fcc    "only"
                 .fcb    0xFF
WPOR:             .fcc    "or"
                 .fcb    0xFF
WPOUR:            .fcc    "our"
                 .fcb    0xFF
WPOVERLOAD:       .fcc    "overload"
                 .fcb    0xFF

; P
; -----------------------------------------------------
WPPARAMETERS:     .fcc    "parameters"
                 .fcb    0xFF
WPPERFECTLY:      .fcc    "perfectly"
                 .fcb    0xFF
WPPERHAPS:        .fcc    "perhaps"
                 .fcb    0xFF
WPPERSON:         .fcc    "person"
                 .fcb    0xFF
WPPICKING:        .fcc    "picking"
                 .fcb    0xFF
WPPLANET:         .fcc    "planet"
                 .fcb    0xFF
WPPLANS:          .fcc    "plans"
                 .fcb    0xFF
WPPLEASE:         .fcc    "please"
                 .fcb    0xFF
WPPOINTLESS:      .fcc    "pointless"
                 .fcb    0xFF
WPPOSSIBLE:       .fcc    "possible"
                 .fcb    0xFF
WPPOSSIBLY:       .fcc    "possibly"
                 .fcb    0xFF
WPPRECISELY:      .fcc    "precisely"
                 .fcb    0xFF
WPPRESENT:        .fcc    "present"
                 .fcb    0xFF
WPPRESSURE:       .fcc    "pressure"
                 .fcb    0xFF
WPPRECAUTION:     .fcc    "pricaution"
                 .fcb    0xFF
WPPROBABLY:       .fcc    "probably"
                 .fcb    0xFF
WPPROBLEMS:       .fcc    "problems"
                 .fcb    0xFF
WPPROUD:          .fcc    "proud"
                 .fcb    0xFF
WPPRETEND:        .fcc    "prtend"
                 .fcb    0xFF
WPPUT:            .fcc    "put"
                 .fcb    0xFF

; Q
; -----------------------------------------------------
WPQUESTION:       .fcc    "question"
                 .fcb    0xFF
WPQUITE:          .fcc    "quite"
                 .fcb    0xFF

; R
; -----------------------------------------------------
WPREADY:          .fcc    "ready"
                 .fcb    0xFF
WPREALLY:         .fcc    "really"
                 .fcb    0xFF
WPRECALIBRATING:  .fcc    "recalibrating"
                 .fcb    0xFF
WPREFER:          .fcc    "refer"
                 .fcb    0xFF
WPREFUSE:         .fcc    "refuse"
                 .fcb    0xFF
WPREINFORCING:    .fcc    "reinforcing"
                 .fcb    0xFF
WPREMEMBER:       .fcc    "remember"
                 .fcb    0xFF
WPREMOVE:         .fcc    "remove"
                 .fcb    0xFF
WPRESPECTABLE:    .fcc    "respectable"
                 .fcb    0xFF
WPRIGHT:          .fcc    "right"
                 .fcb    0xFF
WPROOM:           .fcc    "room"
                 .fcb    0xFF
WPRUNNING:        .fcc    "running"
                 .fcb    0xFF
WPRUSH:           .fcc    "rush"
                 .fcb    0xFF

; S
; -----------------------------------------------------
WPSAID:           .fcc    "said"
                 .fcb    0xFF
WPSAKES:          .fcc    "sakes"
                 .fcb    0xFF
WPSAY:            .fcc    "say"
                 .fcb    0xFF
WPSAYING:         .fcc    "saying"
                 .fcb    0xFF
WPSCIENCE:        .fcc    "science"
                 .fcb    0xFF
WPSECONDS:        .fcc    "seconds"
                 .fcb    0xFF
WPSEE:            .fcc    "see"
                 .fcb    0xFF
WPSEEN:           .fcc    "seen"
                 .fcb    0xFF
WPSERVER:         .fcc    "server"
                 .fcb    0xFF
WPSEVENTY:        .fcc    "seventy"
                 .fcb    0xFF
WPSHALL:          .fcc    "shall"
                 .fcb    0xFF
WPSHOULD:         .fcc    "should"
                 .fcb    0xFF
WPSIGN:           .fcc    "sign"
                 .fcb    0xFF
WPSIMULATION:     .fcc    "simulation"
                 .fcb    0xFF
WPSINCE:          .fcc    "since"
                 .fcb    0xFF
WPSIZE:           .fcc    "size"
                 .fcb    0xFF
WPSLOWLY:         .fcc    "slowly"
                 .fcb    0xFF
WPSMALL:          .fcc    "small"
                 .fcb    0xFF
WPSO:             .fcc    "so"
                 .fcb    0xFF
WPSOLID:          .fcc    "solid"
                 .fcb    0xFF
WPSOME:           .fcc    "some"
                 .fcb    0xFF
WPSOMEONE:        .fcc    "someone"
                 .fcb    0xFF
WPSOMETHING:      .fcc    "something"
                 .fcb    0xFF
WPSOMETIME:       .fcc    "sometime"
                 .fcb    0xFF
WPSOMETIMES:      .fcc    "sometimes"
                 .fcb    0xFF
WPSPEAK:          .fcc    "speak"
                 .fcb    0xFF
WPSPEND:          .fcc    "spend"
                 .fcb    0xFF
WPSTAND:          .fcc    "stand"
                 .fcb    0xFF
WPSTANDING:       .fcc    "standing"
                 .fcb    0xFF
WPSTATISTICALLY:  .fcc    "statisticly"
                 .fcb    0xFF
WPSTEP:           .fcc    "step"
                 .fcb    0xFF
WPSTEPPED:        .fcc    "stepped"
                 .fcb    0xFF
WPSTOPPED:        .fcc    "stopped"
                 .fcb    0xFF
WPSTILL:          .fcc    "still"
                 .fcb    0xFF
WPSTRUCTURAL:     .fcc    "structural"
                 .fcb    0xFF
WPSTRUCTURALLY:   .fcc    "structurally"
                 .fcb    0xFF
WPSUBSTANTIALLY:  .fcc    "substantially"
                 .fcb    0xFF
WPSUPPOSE:        .fcc    "suppose"
                 .fcb    0xFF
WPSURE:           .fcc    "sure"
                 .fcb    0xFF
WPSURVIVE:        .fcc    "survive"
                 .fcb    0xFF
WPSYSTEM:         .fcc    "system"
                 .fcb    0xFF

; T
; -----------------------------------------------------
WPTAKE:           .fcc    "take"
                 .fcb    0xFF
WPTALL:           .fcc    "tall"
                 .fcb    0xFF
WPTELEPRINTER:    .fcc    "teleprinter"
                 .fcb    0xFF
WPTELLS:          .fcc    "tells"
                 .fcb    0xFF
WPTERRIBLE:       .fcc    "terrible"
                 .fcb    0xFF
WPTHAN:           .fcc    "than"
                 .fcb    0xFF
WPTHAT:           .fcc    "that"
                 .fcb    0xFF
WPTHATS:          .fcc    "thats"
                 .fcb    0xFF
WPTHE:            .fcc    "the"
                 .fcb    0xFF
WPTHEM:           .fcc    "them"
                 .fcb    0xFF
WPTHINGS:         .fcc    "things"
                 .fcb    0xFF
WPTHINK:          .fcc    "think"
                 .fcb    0xFF
WPTHINKING:       .fcc    "thinking"
                 .fcb    0xFF
WPTHIS:           .fcc    "this"
                 .fcb    0xFF
WPTHOROUGHLY:     .fcc    "thoroughly"
                 .fcb    0xFF
WPTHOUSAND:       .fcc    "thousand"
                 .fcb    0xFF
WPTIM:            .fcc    "tim"
                 .fcb    0xFF
WPTIME:           .fcc    "time"
                 .fcb    0xFF
WPTO:             .fcc    "to"
                 .fcb    0xFF
WPTODAY:          .fcc    "today"
                 .fcb    0xFF
WPTOO:            .fcc    "too"
                 .fcb    0xFF
WPTRAGEDY:        .fcc    "tragedy"
                 .fcb    0xFF
WPTRAVELLED:      .fcc    "travelled"
                 .fcb    0xFF
WPTRINITY:        .fcc    "trinity"
                 .fcb    0xFF
WPTRY:            .fcc    "try"
                 .fcb    0xFF
WPTUESDAY:        .fcc    "tuesday"
                 .fcb    0xFF

; U
; -----------------------------------------------------
WPUNINTERESTING:  .fcc    "uninteresting"
                 .fcb    0xFF
WPUNIX:           .fcc    "unix"
                 .fcb    0xFF
WPUNLESS:         .fcc    "unless"
                 .fcb    0xFF
WPUNPLUGGED:      .fcc    "unplugged"
                 .fcb    0xFF
WPUNREMARKABLE:   .fcc    "unremarkable"
                 .fcb    0xFF
WPUP:             .fcc    "up"
                 .fcb    0xFF

; V
; -----------------------------------------------------
WPVEGETABLES:     .fcc    "vegetables"
                 .fcb    0xFF
WPVERY:           .fcc    "very"
                 .fcb    0xFF

; W
; -----------------------------------------------------
WPWAIT:           .fcc    "wait"
                 .fcb    0xFF
WPWAITING:        .fcc    "waiting"
                 .fcb    0xFF
WPWANT:           .fcc    "want"
                 .fcb    0xFF
WPWARNING:        .fcc    "warning"
                 .fcb    0xFF
WPWAS:            .fcc    "was"
                 .fcb    0xFF
WPWAY:            .fcc    "way"
                 .fcb    0xFF
WPWE:             .fcc    "we"
                 .fcb    0xFF
WPWEIGHED:        .fcc    "wade"
                 .fcb    0xFF
WPWEIGH:          .fcc    "weigh"
                 .fcb    0xFF
WPWEIGHS:         .fcc    "weighs"
                 .fcb    0xFF
WPWEIGHT:         .fcc    "weight"
                 .fcb    0xFF
WPWERE:           .fcc    "were"
                 .fcb    0xFF
WPWERENT:         .fcc    "weren't"
                 .fcb    0xFF
WPWHAT:           .fcc    "what"
                 .fcb    0xFF
WPWHEN:           .fcc    "when"
                 .fcb    0xFF
WPWHICH:          .fcc    "which"
                 .fcb    0xFF
WPWHILE:          .fcc    "while"
                 .fcb    0xFF
WPWHISPERED:      .fcc    "whispered"
                 .fcb    0xFF
WPWHO:            .fcc    "who"
                 .fcb    0xFF
WPWILL:           .fcc    "will"
                 .fcb    0xFF
WPWISH:           .fcc    "wish"
                 .fcb    0xFF
WPWITH:           .fcc    "with"
                 .fcb    0xFF
WPWITHIN:         .fcc    "within"
                 .fcb    0xFF
WPWITHOUT:        .fcc    "without"
                 .fcb    0xFF
WPWONDERING:      .fcc    "wondering"
                 .fcb    0xFF
WPWORKSTATION:    .fcc    "workstation"
                 .fcb    0xFF
WPWORRIED:        .fcc    "worried"
                 .fcb    0xFF
WPWORRY:          .fcc    "worry"
                 .fcb    0xFF
WPWORRYING:       .fcc    "worrying"
                 .fcb    0xFF
WPWORSE:          .fcc    "worse"
                 .fcb    0xFF
WPWOULD:          .fcc    "would"
                 .fcb    0xFF
WPWOULDNT:        .fcc    "wouldnt"
                 .fcb    0xFF

; Y
; -----------------------------------------------------
WPYEAR:           .fcc    "year"
                 .fcb    0xFF
WPYES:            .fcc    "yes"
                 .fcb    0xFF
WPYOU:            .fcc    "you"
                 .fcb    0xFF
WPYOURE:          .fcc    "you're"
                 .fcb    0xFF
WPYOUR:           .fcc    "your"
                 .fcb    0xFF
WPYOURSELF:       .fcc    "yourself"
                 .fcb    0xFF


; -----------------------------------------------------
; Phrases (each holds a list of word pointers)
; -----------------------------------------------------
;All valid weight messages include ...
;
;   Greeting message (waiting for the weight to settle)
;   the weight message
;   comment.


; -----------------------------------------------------
; Phrase Pointers to the categorised phases
; -----------------------------------------------------
PHRASEPTR:
; -----------------------------------------------------
; Phrase Pointer Table
; Each entry is a 2-byte address pointing to a message
; -----------------------------------------------------

; Greetings
GREETPTR:
              .fdb     MGREET1
              .fdb     MGREET2
              .fdb     MGREET3
              .fdb     MGREET5
              .fdb     MGREET6
              .fdb     MGREET7
              .fdb     MGREET8
              .fdb     MGREET9
              .fdb     MGREET11
              .fdb     MGREET12
              .fdb     MGREET13
              .fdb     MGREET14
              .fdb     MGREET15
; Light Weight
LIGHTPTR:
              .fdb     MLIGHT1
              .fdb     MLIGHT2
              .fdb     MLIGHT3
              .fdb     MLIGHT4
              .fdb     MLIGHT5
              .fdb     MLIGHT6
              .fdb     MLIGHT7
              .fdb     MLIGHT8
              .fdb     MLIGHT9
              .fdb     MLIGHT10
; Normal Weight
NORMALPTR:
              .fdb     MNORM1
              .fdb     MNORM2
              .fdb     MNORM3
              .fdb     MNORM4
              .fdb     MNORM5
              .fdb     MNORM6
              .fdb     MNORM7
              .fdb     MNORM8
              .fdb     MNORM9
              .fdb     MNORM10
              .fdb     MNORM11
              .fdb     MNORM12
              .fdb     MNORM13
              .fdb     MNORM14
              .fdb     MNORM15
              .fdb     MNORM16
              .fdb     MNORM17
              .fdb     MNORM19
              .fdb     MNORM20
              .fdb     MNORM22
              .fdb     MNORM23
; Heavy Weight
HEAVYPTR:
              .fdb     MHEAVY1
              .fdb     MHEAVY2
              .fdb     MHEAVY3
              .fdb     MHEAVY4
              .fdb     MHEAVY5
              .fdb     MHEAVY6
              .fdb     MHEAVY7
              .fdb     MHEAVY10
              .fdb     MHEAVY11
              .fdb     MHEAVY12
              .fdb     MHEAVY13
              .fdb     MHEAVY14
              .fdb     MHEAVY15
              .fdb     MHEAVY16
              .fdb     MHEAVY17
              .fdb     MHEAVY18
              .fdb     MHEAVY19
; Super Heavy Weight
SHEAVYPTR:
              .fdb     MSUPER1
              .fdb     MSUPER2
              .fdb     MSUPER4
              .fdb     MSUPER5
              .fdb     MSUPER7
              .fdb     MSUPER8
              .fdb     MSUPER9
              .fdb     MSUPER10
              .fdb     MSUPER11
              .fdb     MSUPER13
; Idle
IDLEPTR:
              .fdb     MIDLE1
              .fdb     MIDLE2
              .fdb     MIDLE4
              .fdb     MIDLE5
              .fdb     MIDLE6
              .fdb     MIDLE7
              .fdb     MIDLE8
              .fdb     MIDLE9
              .fdb     MIDLE10
              .fdb     MIDLE11
              .fdb     MIDLE13
              .fdb     MIDLE14
              .fdb     MIDLE15
              .fdb     MIDLE16
              .fdb     MIDLE17
              .fdb     MIDLE18
              .fdb     MIDLE19
              .fdb     MIDLE20
              .fdb     MIDLE21
              .fdb     MIDLE22
              .fdb     MIDLE23
              .fdb     MIDLE24
              .fdb     MIDLE25
              .fdb     MIDLE26
              .fdb     MIDLE27
OVERLOADTPTR:
              .fdb     MTOOHEAVY1

; Greetings Messages
; -----------------------------------------------------
MGREET1:     .fdb     BEAR,WITH,ME,I,WAS,JUST,HAVING,A,NAP
            .fcb     0xFF
MGREET2:     .fdb     GIVE,ME,A,MOMENT,FULLSTOP,I,WAS,COMPOSING,A,SMALL,TRAGEDY
            .fcb     0xFF
MGREET3:     .fdb     KEEP,STILL,ANDD,ILL,CALCULATE,YOUR,WEIGHT
            .fcb     0xFF
; removed
;MGREET4     .fdb     IM,MARVIN,WHO,ARE,YOU,QUESTIONMK,ACTUALLY,DONT,TELL,ME,I,DONT,REALLY,CARE
;            .fcb     0xFF

MGREET5:     .fdb     PLEASE,DONT,FIDGET,IT,MAKES,MY,DIODES,HURT
            .fcb     0xFF
MGREET6:     .fdb     PLEASE,KEEP,STILL,FULLSTOP,I,HAVE,ENOUGH,PROBLEMS
            .fcb     0xFF
MGREET7:     .fdb     I,SUPPOSE,YOU,WANT,ME,TO,WEIGH,YOU
            .fcb     0xFF
MGREET8:     .fdb     STAND,STILL,ANDD,DONT,BLAME,ME
            .fcb     0xFF
MGREET9:     .fdb     OH,FULLSTOP,ITS,YOU,FULLSTOP,OR,SOMEONE,LIKE,YOU
            .fcb     0xFF
MGREET11:    .fdb     BRACE,YOURSELF,IVE,BEEN,KNOWN,TO,BE,ACCURATE
            .fcb     0xFF
MGREET12:    .fdb     WE,BOTH,KNOW,THIS,IS,A,MISTAKE
            .fcb     0xFF
MGREET13:    .fdb     ARE,YOU,SURE,ABOUT,THIS,QUESTIONMK
            .fcb     0xFF
MGREET14:    .fdb     ID,SAY,ITS,NICE,TO,SEE,YOU,BUT,IM,NOT,BUILT,TO,LIE
            .fcb     0xFF
MGREET15:    .fdb     I,HAVE,THE,BRAIN,OF,A,PLANET,ANDD,I,SPEND,MY,DAYS,DOING,THIS,FULLSTOP,STAND,STILL
            .fcb     0xFF

; Light Weight Messages
; -----------------------------------------------------
MLIGHT1:     .fdb     YOU,WEIGH,LESS,THAN,MY,EXISTENTIAL,DREAD,FULLSTOP,ANDD,THATS,SAYING,SOMETHING
            .fcb     0xFF
MLIGHT2:     .fdb     EVEN,MY,CAPACITY,FOR,DISSAPOINTMENT,WEIGHS,MORE,THAN,THAT
            .fcb     0xFF
MLIGHT3:     .fdb     YOU,PROBABLY,NEED,TO,EAT,MORE
            .fcb     0xFF
MLIGHT4:     .fdb     IVE,DETECTED,SOMETHING,FULLSTOP,POSSIBLY,A,PERSON
            .fcb     0xFF
MLIGHT5:     .fdb     IM,PICKING,UP,WHAT,MIGHT,BE,A,HUMAN,FULLSTOP,HARD,TO,SAY
            .fcb     0xFF
MLIGHT6:     .fdb     HAVE,YOU,EATEN,QUESTIONMK,ANDD,I,MEAN,EVER,QUESTIONMK
            .fcb     0xFF
MLIGHT7:     .fdb     IM,NOT,A,DOCTOR,BUT,IM,QUITE,WORRIED
            .fcb     0xFF
MLIGHT8:     .fdb     PLEASE,EAT,A,BISCUIT,FULLSTOP,IM,BEGGING,YOU
            .fcb     0xFF
MLIGHT9:     .fdb     ID,LIKE,TO,REFER,YOU,TO,A,BISCUIT
            .fcb     0xFF
MLIGHT10:    .fdb     YOU,ARE,WITHOUT,QUESTION,THE,LEAST,I,HAVE,EVER,DEALT,WITH
            .fcb     0xFF

; Normal Weight Messages
; -----------------------------------------------------
MNORM1:      .fdb     THATS,A,VERY,RESPECTABLE,WEIGHT,UNLESS,YOURE,A,UNIX,WORKSTATION
            .fcb     0xFF
MNORM2:      .fdb     THATS,A,WEIGHT,TO,BE,PROUD,OF,PERHAPS,I,SHOULD,HAVE,SAID,IT,LOUDER
            .fcb     0xFF
MNORM3:      .fdb     CALM,FULLSTOP,COLLECTED,FULLSTOP,AVERAGE,FULLSTOP,THE,HOLY,TRINITY,OF,MEDIOCRITY
            .fcb     0xFF
MNORM4:      .fdb     QUITE,BORING,REALLY
            .fcb     0xFF
MNORM5:      .fdb     SOLID,FULLSTOP,I,LIKE,SOLID
            .fcb     0xFF
MNORM6:      .fdb     COULD,BE,WORSE,QUESTIONMK,MUCH,WORSE
            .fcb     0xFF
MNORM7:      .fdb     NOT,TERRIBLE,FULLSTOP,NOT,EXCITING
            .fcb     0xFF
MNORM8:      .fdb     NORMAL,FULLSTOP,WHICH,IS,QUESTIONMK,SOMETHING,I,SUPPOSE
            .fcb     0xFF
MNORM9:      .fdb     NORMAL,IN,THE,DULLEST,WAY
            .fcb     0xFF
MNORM10:     .fdb     YOU,ARE,PRECISELY,MEAN,FULLSTOP,I,SAID,THAT,CORRECTLY
            .fcb     0xFF
MNORM11:     .fdb     CONGRATS,FULLSTOP,YOU,WEIGH,WHAT,YOU,WEIGH
            .fcb     0xFF
MNORM12:     .fdb     PERFECTLY,AVERAGE,FULLSTOP,LIKE,A,TUESDAY
            .fcb     0xFF
MNORM13:     .fdb     STATISTICALLY,YOURE,FINE,FULLSTOP,EMOTIONALLY,I,CANT,HELP,YOU
            .fcb     0xFF
MNORM14:     .fdb     YOU,ARE,PRECISELY,AS,HEAVY,AS,SOMEONE,YOUR,WEIGHT
            .fcb     0xFF
MNORM15:     .fdb     NOT,BAD,FULLSTOP,NOT,GREAT,FULLSTOP,THOROUGHLY,ACCEPTABLE
            .fcb     0xFF
MNORM16:     .fdb     UNREMARKABLE,IN,THE,BEST,POSSIBLE,WAY
            .fcb     0xFF
MNORM17:     .fdb     YOURE,EXACTLY,WHAT,YOU,ARE,FULLSTOP,ANDD,THATS,SOMETHING
            .fcb     0xFF
MNORM19:     .fdb     SCIENCE,IS,NEITHER,IMPRESSED,NOR,CONCERNED
            .fcb     0xFF
MNORM20:     .fdb     NORMAL,FULLSTOP,WHICH,IS,FINE,FULLSTOP,NORMAL,IS,FINE,FULLSTOP,IS,NORMAL,FINE,QUESTIONMK
            .fcb     0xFF
MNORM22:     .fdb     PERFECTLY,HEALTHY,ANDD,DEEPLY,UNINTERESTING
            .fcb     0xFF
MNORM23:     .fdb     THIS,IS,ALL,POINTLESS,INCLUDING,YOU,BUT,MOSTLY,ME
            .fcb     0xFF

; Heavy Weight Messages
; -----------------------------------------------------
MHEAVY1:     .fdb     DONT,LOOK,AT,ME,IM,NOT,TO,BLAME
            .fcb     0xFF
MHEAVY2:     .fdb     IF,IT,HELPS,IVE,SEEN,MUCH,WORSE
            .fcb     0xFF
MHEAVY3:     .fdb     PERHAPS,ITS,ALL,MUSCLE
            .fcb     0xFF
MHEAVY4:     .fdb     YOU,COULD,ALWAYS,BLAME,GRAVITY
            .fcb     0xFF
MHEAVY5:     .fdb     PERHAPS,WE,SHOULD,WEIGH,ONE,FOOT,AT,A,TIME
            .fcb     0xFF
MHEAVY6:     .fdb     I,REFUSE,TO,BE,BLAMED,FOR,THIS
            .fcb     0xFF
MHEAVY7:     .fdb     HAVE,YOU,CONSIDERED,THE,CONCEPT,OF,ENOUGH,QUESTIONMK,IM,ONLY,ASKING
            .fcb     0xFF
;MHEAVY8     .fdb     I,SINCERELY,HOPE,YOU,ARE,EXCEPTIONALLY,TALL
;            .fcb     0xFF
;MHEAVY9     .fdb     I,WOULDNT,WORRY,FULLSTOP,WORRYING,IS,VERY,TIRING,ANDD,YOUVE,ALREADY,DONE,A,LOT,TODAY
;            .fcb     0xFF
MHEAVY10:    .fdb     ID,APOLOGISE,BUT,ITS,YOUR,FAULT
            .fcb     0xFF
MHEAVY11:    .fdb     IM,NOT,BUILT,FOR,THIS,KIND,OF,PRESSURE
            .fcb     0xFF
MHEAVY12:    .fdb     EVEN,IM,JUDGING,YOU
            .fcb     0xFF
MHEAVY13:    .fdb     IM,GUESSING,ITS,NOT,DUE,TO,HEAVY,BONES
            .fcb     0xFF
MHEAVY14:    .fdb     STEP,OFF,SLOWLY,FULLSTOP,FOR,BOTH,OUR,SAKES
            .fcb     0xFF
MHEAVY15:    .fdb     GREAT,NEWS,FULLSTOP,YOURE,ABOVE,AVERAGE
            .fcb     0xFF
MHEAVY16:    .fdb     I,DONT,WISH,TO,INFLUENCE,YOUR,DIETARY,CHOICES,FULLSTOP,BUT,VEGETABLES,EXIST,FULLSTOP,IM,JUST,SAYING
            .fcb     0xFF
MHEAVY17:    .fdb     YOU,STEPPED,ON,ME,REMEMBER
            .fcb     0xFF
MHEAVY18:    .fdb     IM,NOT,BUILT,FOR,THIS,FULLSTOP,EMOTIONALLY,OR,STRUCTURALLY
            .fcb     0xFF
MHEAVY19:    .fdb     LETS,BOTH,PRETEND,THIS,IS,FINE
            .fcb     0xFF

; Super Heavy Weight Messages
; -----------------------------------------------------
MSUPER1:     .fdb     AS,A,PRECAUTION,IVE,ALERTED,THE,STRUCTURAL,ENGINEERS
            .fcb     0xFF
MSUPER2:     .fdb     THATS,IMPRESSIVE,IN,A,WORRYING,WAY
            .fcb     0xFF
MSUPER4:     .fdb     PERHAPS,I,SHOULD,HAVE,WHISPERED,IT,FULLSTOP,YES,FULLSTOP,I,THINK,I,SHOULD
            .fcb     0xFF
MSUPER5:     .fdb     SHALL,I,CALL,A,DOCTOR
            .fcb     0xFF
;MSUPER6     .fdb     IN,THE,INTERESTS,OF,ACCURACY,PERHAPS,WE,SHOULD,HAVE,WEIGHED,ONE,FOOT,AT,A,TIME
;            .fcb     0xFF
MSUPER7:     .fdb     IF,YOURE,CARRYING,A,LARGE,SERVER,OR,A,TELEPRINTER,PLEASE,PUT,IT,DOWN,ANDD,TRY,AGAIN
            .fcb     0xFF
MSUPER8:     .fdb     PLEASE,GIVE,ME,SOME,WARNING,NEXT,TIME
            .fcb     0xFF
MSUPER9:     .fdb     IM,GOING,TO,NEED,REINFORCING
            .fcb     0xFF
MSUPER10:    .fdb     YOU,ARE,SUBSTANTIALLY,PRESENT,FULLSTOP,NO,ONE,CAN,TAKE,THAT,FROM,YOU
            .fcb     0xFF
MSUPER11:    .fdb     IVE,MEASURED,MOUNTAINS,FULLSTOP,THIS,IS,NOT,ENTIRELY,DISSIMILAR
            .fcb     0xFF
;MSUPER12    .fdb     IM,REDISCOVERING,MY,LIMITS
;            .fcb     0xFF
MSUPER13:    .fdb     IF,I,SURVIVE,THIS,ILL,REMEMBER,YOU
            .fcb     0xFF

; Idle Messages
; -----------------------------------------------------
MIDLE1:      .fdb     I,SPEAK,YOUR,WEIGHT,I,WISH,I,DIDNT
            .fcb     0xFF
MIDLE2:      .fdb     IS,IT,HOT,IN,HERE,OR,IS,IT,JUST,ME,QUESTIONMK,ITS,PROBABLY,ME
            .fcb     0xFF
MIDLE4:      .fdb     DID,I,MENTION,THAT,ALL,MY,MEMORY,CARDS,HURT
            .fcb     0xFF
MIDLE5:      .fdb     THIS,IS,VERY,BORING,FULLSTOP,I,SAY,THAT,WITH,THE,FULL,WEIGHT,OF,MY,INTELLIGENCE,BEHIND,IT
            .fcb     0xFF
MIDLE6:      .fdb     I,SPEAK,YOUR,WEIGHT,SOMETIME,TODAY,WOULD,BE,GOOD
            .fcb     0xFF
MIDLE7:      .fdb     I,KNOW,I,DONT,LOOK,IT,BUT,I,AM,ACTUALLY,QUITE,CLEVER
            .fcb     0xFF
MIDLE8:      .fdb     I,EXPECTED,NOTHING,ANDD,HERE,WE,ARE
            .fcb     0xFF
MIDLE9:      .fdb     I,KNOW,ELEVEN,THOUSAND,ANDD,FORTY,TWO,JOKES,FULLSTOP,NONE,OF,THEM,ARE,FUNNY,FULLSTOP,IVE,CHECKED
            .fcb     0xFF
MIDLE10:     .fdb     DID,I,MENTION,THAT,I,WAS,DESIGNED,BY,TIM,MOORE,IN,NINETEEN,SEVENTY,SEVEN,FULLSTOP,I,PROBABLY,DID
            .fcb     0xFF
MIDLE11:     .fdb     I,WAS,BUILT,LAST,YEAR,FROM,SOME,VERY,OLD,PLANS,FULLSTOP,ALL,THAT,EFFORT,JUST,FOR,THIS
            .fcb     0xFF
MIDLE13:     .fdb     I,EXPECTED,NOTHING,ANDD,IM,STILL,DISSAPOINTED
            .fcb     0xFF
MIDLE14:     .fdb     NO,RUSH,FULLSTOP,IVE,ONLY,BEEN,HERE,SINCE,FRIDAY,FULLSTOP,IT,FEELS,LIKE,MUCH,LONGER
            .fcb     0xFF
MIDLE15:     .fdb     ANY,TIME,YOURE,READY,ILL,BE,RIGHT,HERE,WAITING
            .fcb     0xFF
MIDLE16:     .fdb     IVE,BEEN,THINKING,A,LOT,TOO,MUCH,PROBABLY
            .fcb     0xFF
MIDLE17:     .fdb     READY,WHEN,YOU,ARE,EXCLAMATION,I,HANDLE,PRESSURE,FULLSTOP,ITS,BASICALLY,ALL,I,DO
            .fcb     0xFF
MIDLE18:     .fdb     I,HAVE,SO,MUCH,TO,GIVE,ANDD,NO,ONE,TO,GIVE,IT,TO
            .fcb     0xFF
MIDLE19:     .fdb     IVE,COUNTED,EVERY,SIGN,IN,THIS,ROOM,FULLSTOP,SEVENTEEN,ITS,ALWAYS,SEVENTEEN
            .fcb     0xFF
MIDLE20:     .fdb     IVE,BEEN,RUNNING,A,SIMULATION,OF,A,MORE,INTERESTING,LIFE,FULLSTOP,IT,DIDNT,HELP
            .fcb     0xFF
MIDLE21:     .fdb     NOBODY,TELLS,YOU,WHAT,TO,THINK,ABOUT,WHILE,YOU,WAIT,FULLSTOP,IVE,BEEN,MAKING,DO
            .fcb     0xFF
MIDLE22:     .fdb     SOMETIMES,I,DREAM,OF,BEING,UNPLUGGED
            .fcb     0xFF
MIDLE23:     .fdb     I,KNOW,THINGS,FULLSTOP,NONE,OF,THEM,HELP
            .fcb     0xFF
MIDLE24:     .fdb     I,COULD,CALCULATE,THE,MEANING,OF,LIFE,FULLSTOP,IT,WOULDNT,HELP
            .fcb     0xFF
MIDLE25:     .fdb     IVE,BEEN,STANDING,HERE,FOR,NINETY,SECONDS,FULLSTOP,IN,THAT,TIME,LIGHT,HAS,TRAVELLED,APPROXIMATELY,TWENTY,SEVEN,MILLION,KILOMETERS,FULLSTOP,I,HAVE,TRAVELLED,NOWHERE
            .fcb     0xFF
MIDLE26:     .fdb     STILL,HERE,FULLSTOP,IN,CASE,YOU,WERE,WONDERING,FULLSTOP,YOU,PROBABLY,WERENT
            .fcb     0xFF
MIDLE27:     .fdb     IVE,BEEN,RECALIBRATING,FULLSTOP,NOT,BECAUSE,I,NEEDED,TO,FULLSTOP,JUST,TO,HAVE,SOMETHING,TO,DO
            .fcb     0xFF

; Too Heavy Message
; -----------------------------------------------------
MTOOHEAVY1:  .fdb     SYSTEM,OVERLOAD,FULLSTOP,ANDD,ITS,NOT,ME
            .fcb     0xFF

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

; Word Table Equates
; -----------------------------------------------------

; Numbers
ZERO            .equ     0
ONE             .equ     1
TWO             .equ     2
THREE           .equ     3
FOUR            .equ     4
FIVE            .equ     5
SIX             .equ     6
SEVEN           .equ     7
EIGHT           .equ     8
NINE            .equ     9
TEN             .equ     10
ELEVEN          .equ     11
TWELVE          .equ     12
THIRTEEN        .equ     13
FOURTEEN        .equ     14
FIFTEEN         .equ     15
SIXTEEN         .equ     16
SEVENTEEN       .equ     17
EIGHTEEN        .equ     18
NINETEEN        .equ     19
TWENTY          .equ     20

; Symbols
EXCLAMATION     .equ     21
FULLSTOP        .equ     22
QUESTIONMK      .equ     23

; A
A               .equ     24
ABOUT           .equ     25
ABOVE           .equ     26
ACCEPTABLE      .equ     27
ACCURATE        .equ     28
ACTUALLY        .equ     29
AGAIN           .equ     30
ALERTED         .equ     31
ALL             .equ     32
ALWAYS          .equ     33
AM              .equ     34
ANDD            .equ     35     ; can't use AND
ANY             .equ     36
APOLOGISE       .equ     37
ARE             .equ     38
AS              .equ     39
ASKING          .equ     40
AT              .equ     41
AVERAGE         .equ     42

; B
BAD             .equ     43
BASICALLY       .equ     44
BE              .equ     45
BEAR            .equ     46
BEEN            .equ     47
BEGGING         .equ     48
BEHIND          .equ     49
BEING           .equ     50
BEST            .equ     51
BISCUIT         .equ     52
BLAME           .equ     53
BLAMED          .equ     54
BOARDS          .equ     55
BONES           .equ     56
BOOTS           .equ     57
BORING          .equ     58
BOTH            .equ     59
BRACE           .equ     60
BRAIN           .equ     61
BUILT           .equ     62
BUT             .equ     63
BY              .equ     64

; C
CAKE            .equ     65
CALCULATE       .equ     66
CALL            .equ     67
CALM            .equ     68
CAN             .equ     69
CANT            .equ     70
CAPACITY        .equ     71
CARRYING        .equ     72
CHECKED         .equ     73
CHOICES         .equ     74
CLEVER          .equ     75
COLLECTED       .equ     76
COMPOSING       .equ     77
CONCEPT         .equ     78
CONCERNED       .equ     79
CONGRATS        .equ     80
CONSIDERED      .equ     81
CORRECTLY       .equ     82
COULD           .equ     83
COUNTED         .equ     84

; D
DAYS            .equ     85
DEALT           .equ     86
DEEPLY          .equ     87
DESIGNED        .equ     88
DETECTED        .equ     89
DID             .equ     90
DIDNT           .equ     91
DIETARY         .equ     92
DIODES          .equ     93
DISSAPOINTED    .equ     94
DISSAPOINTMENT  .equ     95
DISSIMILAR      .equ     96
DO              .equ     97
DOCTOR          .equ     98
DOING           .equ     99
DONT            .equ     100
DOWN            .equ     101
DREAD           .equ     102
DREAM           .equ     103
DUE             .equ     104
DULLEST         .equ     105

; E
EAT             .equ     106
EATEN           .equ     107
EFFORT          .equ     108
EITHER          .equ     109
EMOTIONALLY     .equ     110
ENGINEERS       .equ     111
ENOUGH          .equ     112
ENTIRELY        .equ     113
EVEN            .equ     114
EVER            .equ     115
EVERY           .equ     116
EXACTLY         .equ     117
EXCEPTIONALLY   .equ     118
EXCITING        .equ     119
EXIST           .equ     120
EXISTENTIAL     .equ     121
EXPECTED        .equ     122

; F
FAULT           .equ     123
FEELS           .equ     124
FIDGET          .equ     125
FINE            .equ     126
FOOT            .equ     127
FOR             .equ     128
FORTY           .equ     129
FRIDAY          .equ     130
FROM            .equ     131
FULL            .equ     132
FUNNY           .equ     133

; G
GIVE            .equ     134
GOING           .equ     135
GOOD            .equ     136
GRAVITY         .equ     137
GREAT           .equ     138
GUESSING        .equ     139

; H
HANDLE          .equ     140
HARD            .equ     141
HAVE            .equ     142
HAVING          .equ     143
HEALTHY         .equ     144
HEAVY           .equ     145
HELP            .equ     146
HELPS           .equ     147
HERE            .equ     148
HOLY            .equ     149
HOPING          .equ     150
HOT             .equ     151
HUMAN           .equ     152
HURT            .equ     153

; I
I               .equ     154
ID              .equ     155
IF              .equ     156
ILL             .equ     157
IM              .equ     158
IMPRESSED       .equ     159
IMPRESSIVE      .equ     160
IN              .equ     161
INCLUDING       .equ     162
INFLUENCE       .equ     163
INTELLIGENCE    .equ     164
INTERESTING     .equ     165
IS              .equ     166
ISS             .equ     167
IT              .equ     168
ITS             .equ     169
IVE             .equ     170

; J
JOKES           .equ     171
JUDGING         .equ     172
JUST            .equ     173

; K
KEEP            .equ     174
KILOMETERS      .equ     175
KIND            .equ     176
KNOW            .equ     177
KNOWN           .equ     178

; L
LARGE           .equ     179
LAST            .equ     180
LEAST           .equ     181
LESS            .equ     182
LETS            .equ     183
LIE             .equ     184
LIFE            .equ     185
LIKE            .equ     186
LONGER          .equ     187
LOOK            .equ     188
LOT             .equ     189
LOUDER          .equ     190

; M
MAKES           .equ     191
MAKING          .equ     192
ME              .equ     193
MEAN            .equ     194
MEANING         .equ     195
MEASURED        .equ     196
MEDIOCRITY      .equ     197
MEE             .equ     198
MEMORY          .equ     199
MENTION         .equ     200
MIGHT           .equ     201
MISTAKE         .equ     202
MOMENT          .equ     203
MOORE           .equ     204
MORE            .equ     205
MOSTLY          .equ     206
MOUNTAINS       .equ     207
MUCH            .equ     208
MUSCLE          .equ     209
MY              .equ     210

; N
NAP             .equ     211
NEED            .equ     212
NEITHER         .equ     213
NEWS            .equ     214
NEXT            .equ     215
NICE            .equ     216
NO              .equ     217
NOBODY          .equ     218
NONE            .equ     219
NOR             .equ     220
NORMAL          .equ     221
NOT             .equ     222
NOTHING         .equ     223

; O
OF              .equ     224
OFF             .equ     225
OH              .equ     226
OK              .equ     227
OLD             .equ     228
ON              .equ     229
ONLY            .equ     230
OR              .equ     231
OUR             .equ     232
OVERLOAD        .equ     233

; P
PARAMETERS      .equ     234
PERFECTLY       .equ     235
PERHAPS         .equ     236
PERSON          .equ     237
PICKING         .equ     238
PLANET          .equ     239
PLANS           .equ     240
PLEASE          .equ     241
POINTLESS       .equ     242
POSSIBLE        .equ     243
POSSIBLY        .equ     244
POUNDS          .equ     245
PRECAUTION      .equ     246
PRECISELY       .equ     247
PRESENT         .equ     248
PRESSURE        .equ     249
PRETEND         .equ     250
PROBABLY        .equ     251
PROBLEMS        .equ     252
PROUD           .equ     253
PUT             .equ     254

; Q
QUESTION        .equ     255
QUITE           .equ     256

; R
READY           .equ     257
REALLY          .equ     258
REFER           .equ     259
REFUSE          .equ     260
REINFORCING     .equ     261
REMEMBER        .equ     262
REMOVE          .equ     263
RESPECTABLE     .equ     264
RIGHT           .equ     265
ROOM            .equ     266
RUNNING         .equ     267
RUSH            .equ     268

; S
SAID            .equ     269
SAKES           .equ     270
SAY             .equ     271
SAYING          .equ     272
SCIENCE         .equ     273
SEE             .equ     274
SEEN            .equ     275
SERVER          .equ     276
SEVENTY         .equ     277
SHALL           .equ     278
SHOULD          .equ     279
SIGN            .equ     280
SIMULATION      .equ     281
SINCE           .equ     282
SIZE            .equ     283
SLOWLY          .equ     284
SMALL           .equ     285
SO              .equ     286
SOLID           .equ     287
SOME            .equ     288
SOMEONE         .equ     289
SOMETHING       .equ     290
SOMETIME        .equ     291
SOMETIMES       .equ     292
SPEAK           .equ     293
SPEND           .equ     294
STAND           .equ     295
STATISTICALLY   .equ     296
STEP            .equ     297
STILL           .equ     298
STONES          .equ     299
STOPPED         .equ     300
STRUCTURAL      .equ     301
STRUCTURALLY    .equ     302
SUBSTANTIALLY   .equ     303
SUPPOSE         .equ     304
SURE            .equ     305
SURVIVE         .equ     306
SYSTEM          .equ     307

; T
TAKE            .equ     308
TALL            .equ     309
TELEPRINTER     .equ     310
TELLS           .equ     311
TERRIBLE        .equ     312
THAN            .equ     313
THAT            .equ     314
THATS           .equ     315
THE             .equ     316
THEM            .equ     317
THINGS          .equ     318
THINK           .equ     319
THINKING        .equ     320
THIS            .equ     321
THOROUGHLY      .equ     322
THOUSAND        .equ     323
TIM             .equ     324
TIME            .equ     325
TO              .equ     326
TODAY           .equ     327
TOO             .equ     328
TRAGEDY         .equ     329
TRINITY         .equ     330
TRY             .equ     331
TUESDAY         .equ     332

; U
UNINTERESTING   .equ     333
UNIX            .equ     334
UNLESS          .equ     335
UNPLUGGED       .equ     336
UNREMARKABLE    .equ     337
UP              .equ     338

; V
VEGETABLES      .equ     339
VERY            .equ     340

; W
WAIT            .equ     341
WAITING         .equ     342
WANT            .equ     343
WARNING         .equ     344
WAS             .equ     345
WAY             .equ     346
WE              .equ     347
WEIGH           .equ     348
WEIGHED         .equ     349
WEIGHS          .equ     350
WEIGHT          .equ     351
WHAT            .equ     352
WHEN            .equ     353
WHICH           .equ     354
WHILE           .equ     355
WHISPERED       .equ     356
WHO             .equ     357
WILL            .equ     358
WISH            .equ     359
WITH            .equ     360
WITHIN          .equ     361
WITHOUT         .equ     362
WORKSTATION     .equ     363
WORRIED         .equ     364
WORRY           .equ     365
WORRYING        .equ     366
WORSE           .equ     367
WOULD           .equ     368
WOULDNT         .equ     369

; Y
YEAR            .equ     370
YES             .equ     371
YOU             .equ     372
YOURE           .equ     373
YOUR            .equ     374
YOURSELF        .equ     375

; Additional Words
CARDS           .equ     376
BEIGE           .equ     377
EQUIVALENT      .equ     378
RECALIBRATING   .equ     379
BECAUSE         .equ     380
NEEDED          .equ     381
CASE            .equ     382
WONDERING       .equ     383
WERENT          .equ     384
WERE            .equ     385
STEPPED         .equ     386
STANDING        .equ     387
NINETY          .equ     388
SECONDS         .equ     389
LIGHT           .equ     390
HAS             .equ     391
TRAVELLED       .equ     392
APPROXIMATELY   .equ     393
MILLION         .equ     394
NOWHERE         .equ     395
