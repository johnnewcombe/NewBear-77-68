;------------------------------------------------------------------
; text2speech.asm
;------------------------------------------------------------------

; 7768 ACIA
DATAA               EQU $F400 ; ACIA(a) Data register
CTRLA               EQU $F401 ; ACIA(a) Ctrl/Status
DATAB               EQU $F402 ; ACIA(b) Data register
CTRLB               EQU $F403 ; ACIA(b) Ctrl/Status

; MINIMON routines
STRING              EQU $FC76   ; Prints a string. The string should follow JSR and be terminated with $FF.
GETADD              EQU $FC89   ; Get Address, read 4 digit hex value.
ZOUT                EQU $FCC9   ; Print value in A as 2 hex digits.
NEWLINE             EQU $FE97   ; Prints a new line.
START               EQU $FF8F   ; Restarts MniMon.
PR_A                EQU $FC0F   ; Print char in A to ACIA (a)
RD_A                EQU $FD2B   ; Read char from A
PRSP                EQU $FD4D   ; Print a space
BINARY              EQU $FC31   ; Converts ASCII hex digits in A and B to binary?
RD_X                EQU $FC65   ; Read 4 hex digits Value from ACIA(a) and put value into X.
VHEX                EQU $FC1D   ; Checks that A contains a HEX character

IDLE_SECS           EQU 90      ; seconds between idle messages
LIGHT_WGHT          EQU 6       ; greater than 6 stones
NORM_WGHT           EQU 10
HEAVY_WGHT          EQU 13
SHEAVY_WGHT         EQU 15

IDLE_MSG_CNT        EQU 1       ; number of messages
GREET_MSG_CNT       EQU 1       ; number of messages
LIGHT_MSG_CNT       EQU 1       ; number of messages
NORM_MSG_CNT        EQU 1       ; number of messages
HEAVY_MSG_CNT       EQU 1       ; number of messages
SHEAVY_MSG_CNT      EQU 1       ; number of messages

	    ORG $0200


; initialise serial port B
TX2SP   LDAA    #$11    ; 8 Data, No Parity, 2 Stop Bits
        STAA    CTRLB   ;   ACIA.A


MAINLOOP:
; -----------------------------------------------------
; Data arrives at port B as four hex characters
; -----------------------------------------------------
        JSR     GETDATA         ; value in T_WEIGHT, stones in A
        BCS     ML1             ; is it invalid i.e. carry clear
        JMP     IDLE
ML1     CMPA    #20             ; more that 20 is too heavy
        BHI     TOOHEAVY
        LDAA    T_WEIGHT+1      ; validate pounds
        CMPA    #13             ; invalid pounds
        BHI     ERROR           ; error
        JSR GREET               ; send a greeting message

        ; get the weight a second time, this should allow the scles time to settle
        JSR     GETDATA

        ; all good so output the weight mesage
        ; TODO get phrase from phrase table as per other message output routines
        JSR     STRINGB
        FCC     "You weigh"
        FCB     $00
        LDX     T_WEIGHT        ; restore X
        JSR     PR_WEIGHT       ; weight back X so output the weight

        ; determine phrase category (light normal, heavy etc.) and jump to the section
        LDAA    T_WEIGHT
        CMPA    #LIGHT_WGHT
        BHI     ML2             ; less than light weight gets no comment
        JMP     END
ML2     CMPA    #NORM_WGHT      ; less than normal is light
        BHI     ML3
        JMP     LIGHT
ML3     CMPA    #HEAVY_WGHT     ; less than heavy is normal
        BHI     ML4
        JMP     NORMAL
ML4     CMPA    #SHEAVY_WGHT    ; less than super heavy is heavy
        BMI     ML5
        JMP     HEAVY
ML5     JMP     SHEAVY
        JMP END

; -----------------------------------------------------
; Over 20 stone so random heavy phrase to ports B
; -----------------------------------------------------
TOOHEAVY
        ; TODO get phrase from phrase table
        JSR      STRINGB
        FCC      "System overload… and it’s not me."
        FCB      $00
        JMP      END
ERROR
        ; TODO get phrase from phrase table
        JSR      STRINGB
        FCC      "Internal error, typical!"
        FCB      $00
        JMP      END

; NEED TO CYCLE AROUND IDLE MESSAGES

IDLE    INC     IDLE_COUNT      ; increase the idle count
        LDAA    IDLE_COUNT      ; see if idle count = max idle time
        CMPA    #IDLE_SECS      ; a data message appears every second
        BNE     END             ; not reached the max idle time
        CLR     IDLE_COUNT      ; time to output an idle message so reset the count

        ; output the idle message
        INC     IDLE_MSG_ID     ; get next idle message
        LDAA    IDLE_MSG_ID
        CMPA    #IDLE_MSG_CNT   ; are we beyond the end of the list
        BNE     IDLE_OP         ; still at valid id so output idle message
        LDAA    #0              ; beyond last message so reset the current msg to zero
        STAA    IDLE_MSG_ID

IDLE_OP
        ; TODO consider the offset depending upon where the idle phrases are within the phrase pointer table
        JMP     PHRASE_OUT

GREET   ; output the greeting message
        INC     GREET_MSG_ID    ; get next idle message
        LDAA    GREET_MSG_ID
        CMPA    #GREET_MSG_CNT  ; are we beyond the end of the list
        BNE     GREET_OP        ; still at valid id so output idle message
        LDAA    #0              ; beyond last message so reset the current msg to zero
        STAA    GREET_MSG_ID

GREET_OP
        ; TODO consider the offset depending upon where the idle phrases are within the phrase pointer table
        JSR     PR_PHRASE       ; output idle message
        JSR     PR_CRB          ; CR/LF
        RTS

LIGHT   ; output the light message
        INC     LIGHT_MSG_ID    ; get next idle message
        LDAA    LIGHT_MSG_ID
        CMPA    #LIGHT_MSG_CNT  ; are we beyond the end of the list
        BNE     LIGHT_OP        ; still at valid id so output idle message
        LDAA    #0              ; beyond last message so reset the current msg to zero
        STAA    LIGHT_MSG_ID

LIGHT_OP
        ; TODO consider the offset depending upon where the idle phrases are within the phrase pointer table
        JMP     PHRASE_OUT

NORMAL  ; output the normal message
        INC     NORMAL_MSG_ID   ; get next idle message
        LDAA    NORMAL_MSG_ID
        CMPA    #NORM_MSG_CNT   ; are we beyond the end of the list
        BNE     NORMAL_OP       ; still at valid id so output idle message
        LDAA    #0              ; beyond last message so reset the current msg to zero
        STAA    NORMAL_MSG_ID

NORMAL_OP
        ; TODO consider the offset depending upon where the idle phrases are within the phrase pointer table
        JMP     PHRASE_OUT

HEAVY   ; output the heavy message
        INC     HEAVY_MSG_ID    ; get next idle message
        LDAA    HEAVY_MSG_ID
        CMPA    #HEAVY_MSG_CNT  ; are we beyond the end of the list
        BNE     HEAVY_OP        ; still at valid id so output idle message
        LDAA    #0              ; beyond last message so reset the current msg to zero
        STAA    HEAVY_MSG_ID

HEAVY_OP
        ; TODO consider the offset depending upon where the idle phrases are within the phrase pointer table
        JMP     PHRASE_OUT

SHEAVY   ; output the heavy message
        INC     SHEAVY_MSG_ID   ; get next idle message
        LDAA    SHEAVY_MSG_ID
        CMPA    #SHEAVY_MSG_CNT ; are we beyond the end of the list
        BNE     SHEAVY_OP       ; still at valid id so output idle message
        LDAA    #0              ; beyond last message so reset the current msg to zero
        STAA    HEAVY_MSG_ID

SHEAVY_OP
        ; TODO consider the offset depending upon where the idle phrases are within the phrase pointer table

PHRASE_OUT
        JSR     PR_PHRASE       ; output idle message
        JSR     PR_CRB          ; CR/LF
        JMP     END

END     JMP     MAINLOOP  ;START   ; all done

;--------------------------------------------------------------
; Gets the weight data from the scales and rerurns with carry
; set if a valid reading, carry clear otherwise. A valid weight
; reading resets the idle count. Data received is stored in
; T_WEIGHT and MSB in A.
;--------------------------------------------------------------
GETDATA
        JSR     RD_XB           ; read 4 hex characters into X
        STX     T_WEIGHT        ; store X
        CLC
        LDAA    T_WEIGHT        ; get fist byte (stones)
        BEQ     GDDONE          ; idle message
        CLR     IDLE_SECS       ; not an idle message so reset the idle counter
        SEC                     ; non idle message return with carry set
GDDONE  RTS

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

;PR_PHRASE
;        LDAA    0,X         ; get word id
;        INX                 ; point X to next word
;        STX     T_P         ; store X away
;        CMPA    #0
;        BEQ     PR_END      ; no more words
;        JSR     PR_WORD     ; print word based on value in A
;        JSR     PR_SPCB
;        LDX     T_P        ; recover X
;        BRA     PR_PHRASE   ; next word
;PR_END  RTS


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
; Phrases (each holds a list of word pointers)
; -----------------------------------------------------
;All valid weight messages include ...
;
;   Greeting message (waiting for the weight to settle)
;   the weight message
;   comment.

; -----------------------------------------------------
; General Phrases
; -----------------------------------------------------
YOUWEIGH    FCB $15,$16,$00

; -----------------------------------------------------
; Idle Phrases (90 sec intervals?
; -----------------------------------------------------
MYNAME      FCB $18,$19,$17,$1A,0
DIODESHURT  FCB $2E,$2F,$30,$31,$18,$32,$33,$34,0
BORING      FCB $35,$17,$36,$37,0
SMARTER     FCB $3b,$3C,$3D,$2F,$3E,$3F,$40,0
CLEVER      FCB $20,$41,$42,$43,$44,$20,$21,$45,$46,$47,0

; -----------------------------------------------------
; Phrase Pointers to the categorised phases
; -----------------------------------------------------
PHRASEPTR

; idle phrase ponters
IPP00        FDB MYNAME
IPP01        FDB DIODESHURT
IPP02        FDB BORING
IPP03        FDB SMARTER
IPP04        FDB CLEVER

; light weight phrase ponters
LPP00       FDB MYNAME

; normal weight phrase ponters
NPP00       FDB MYNAME

; heavy weight phrase ponters
HPP00       FDB MYNAME

; super heavy weight  phrase ponters
SPP00       FDB MYNAME

; -----------------------------------------------------
; Word Table, add a pointer to each word in WORDPTR table
; -----------------------------------------------------
WORDTABLE

; numbers
WZERO           FCC     "zero"
                FCB     $FF
WONE            FCC     "one"
                FCB     $FF
WTWO            FCC     "two"
                FCB     $FF
WTHREE          FCC     "three"
                FCB     $FF
WFOUR           FCC     "four"
                FCB     $FF
WFIVE           FCC     "five"
                FCB     $FF
WSIX            FCC     "six"
                FCB     $FF
WSEVEN          FCC     "seven"
                FCB     $FF
WEIGHT          FCC     "eight"
                FCB     $FF
WNINE           FCC     "nine"
                FCB     $FF
WTEN            FCC     "ten"
                FCB     $FF
WELEVEN         FCC     "eleven"
                FCB     $FF
WTWELVE         FCC     "twelve"
                FCB     $FF
WTHIRTEEN       FCC     "thirteen"
                FCB     $FF
WFOURTEEN       FCC     "fourteen"
                FCB     $FF
WFIFTEEN        FCC     "fifteen"
                FCB     $FF
WSIXTEEN        FCC     "sixteen"
                FCB     $FF
WSEVENTEEN      FCC     "seventeen"
                FCB     $FF
WEIGHTEEN       FCC     "eighteen"
                FCB     $FF
WNINETEEN       FCC     "nineteen"
                FCB     $FF
WTWENTY         FCC     "twenty"
                FCB     $FF

; general words
WYOU            FCC     "you"
                FCB     $FF
WWEIGH          FCC     "weigh"
                FCB     $FF
WIS             FCC     "is"
                FCB     $FF
WMY             FCC     "my"
                FCB     $FF
WNAME           FCC     "name"
                FCB     $FF
WMARVIN         FCC     "marvin"
                FCB     $FF
WSTONES         FCC     "stones"
                FCB     $FF
WPOUNDS         FCC     "pounds"
                FCB     $FF
WHA             FCC     "ha"
                FCB     $FF
WQUESTION       FCC     "?"
                FCB     $FF
WEXCLAMATION    FCC     "!"
                FCB     $FF
WFULLTOP        FCC     "."
                FCB     $FF
WI              FCC     "I"
                FCB     $FF
WAM             FCC     "am"
                FCB     $FF
WA              FCC     "a"
                FCB     $FF
WMACHINE        FCC     "machine"
                FCB     $FF
WFOR            FCC     "for"
                FCB     $FF
WANALYTICAL     FCC     "analytical"
                FCB     $FF
WREASONING      FCC     "reasoning"
                FCB     $FF
WWITH           FCC     "with"
                FCB     $FF
WVARIABLE       FCC     "very"
                FCB     $FF
WLITTLE         FCC     "little"
                FCB     $FF
WINTEREST       FCC     "interest"
                FCB     $FF
WAND            FCC     "and"
                FCB     $FF
WNO             FCC     "no"
                FCB     $FF
WENTHUSIASM     FCC     "enthusiasm"
                FCB     $FF
WALL            FCC     "all"
                FCB     $FF
WTHE            FCC     "the"
                FCB     $FF
WDIODES         FCC     "diodes"
                FCB     $FF
WON             FCC     "on"
                FCB     $FF
WMEMORY         FCC     "memory"
                FCB     $FF
WCARDS          FCC     "cards"
                FCB     $FF
WHURT           FCC     "hurt"
                FCB     $FF
WTHIS           FCC     "this"
                FCB     $FF
WVERY           FCC     "very"
                FCB     $FF
WBORING         FCC     "boring"
                FCB     $FF
WSHALL          FCC     "shall"
                FCB     $FF
WTELL           FCC     "tell"
                FCB     $FF
WJOKE           FCC     "joke"
                FCB     $FF
WNEWBEAR        FCC     "newbear"
                FCB     $FF
WSMARTER        FCC     "smarter"
                FCB     $FF
WTHAN           FCC     "than"
                FCB     $FF
WAVERAGE        FCC     "average"
                FCB     $FF
WBEAR           FCC     "bear"
                FCB     $FF
WPROBABLY       FCC     "probably"
                FCB     $FF
WKNOW           FCC     "know"
                FCB     $FF
WLOOK           FCC     "look"
                FCB     $FF
WIT             FCC     "it"
                FCB     $FF
WBUT            FCC     "but"
                FCB     $FF
WACTUALLY       FCC     "actually"
                FCB     $FF
WQUITE          FCC     "quite"
                FCB     $FF
WCLEVER         FCC     "clever"
                FCB     $FF

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
WP1D        FDB WQUESTION
WP1E        FDB WEXCLAMATION
WP1F        FDB WFULLTOP
WP20        FDB WI
WP21        FDB WAM
WP22        FDB WA
WP23        FDB WMACHINE
WP24        FDB WFOR
WP25        FDB WANALYTICAL
WP26        FDB WREASONING
WP27        FDB WWITH
WP28        FDB WVARIABLE
WP29        FDB WLITTLE
WP2A        FDB WINTEREST
WP2B        FDB WAND
WP2C        FDB WNO
WP2D        FDB WENTHUSIASM
WP2E        FDB WALL
WP2F        FDB WTHE
WP30        FDB WDIODES
WP31        FDB WON
WP32        FDB WMEMORY
WP33        FDB WCARDS
WP34        FDB WHURT
WP35        FDB WTHIS
WP36        FDB WVERY
WP37        FDB WBORING
WP38        FDB WSHALL
WP39        FDB WTELL
WP3A        FDB WJOKE
WP3B        FDB WNEWBEAR
WP3C        FDB WSMARTER
WP3D        FDB WTHAN
WP3E        FDB WAVERAGE
WP3F        FDB WBEAR
WP40        FDB WPROBABLY
WP41        FDB WKNOW
WP42        FDB WLOOK
WP43        FDB WIT
WP44        FDB WBUT
WP45        FDB WACTUALLY
WP46        FDB WQUITE
WP47        FDB WCLEVER
WP48        FDB WHA


; -----------------------------------------------------
; Reserved memory
; -----------------------------------------------------

T_Q             RMB     1       ; Temp storage for ZIN
T_Z             RMB     2       ;   "     "     "  RDX
T_X             RMB     2       ;   "     "     "  PR_WORD
T_P             RMB     2       ;   "     "     "  PR_PHRASE
T_W             RMB     2       ;   "     "     "  PR_WEIGHT
DEC             RMB     3       ; for decimal value
RND             RMB     1       ; holds a random number (see RD_B
TEMP            RMB     2       ; temp var (non subroutine use)
T_WEIGHT        RMB     2       ; holds value of weight following a call to GETDATA
IDLE_COUNT      RMB     1       ; counts the number of empty measurement reports
IDLE_MSG_ID     RMB     1       ; holds value of next idle message to use
GREET_MSG_ID    RMB     1       ; holds value of next greeting message to use
LIGHT_MSG_ID    RMB     1       ; holds value of next light weight message to use
NORMAL_MSG_ID   RMB     1       ; holds value of next normal weight message to use
HEAVY_MSG_ID    RMB     1       ; holds value of next heavy weight message to use
SHEAVY_MSG_ID   RMB     1       ; holds value of next super heavy weight message to use

