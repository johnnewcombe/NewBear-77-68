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
        BHI     OVERLOAD
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
OVERLOAD
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
        BEQ     IDLE1           ; not reached the max idle time
        JMP     END
IDLE1   CLR     IDLE_COUNT      ; time to output an idle message so reset the count

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
        ADDA    GREETTPTR-PHRASEPTR ; add the offset phrase pointers
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
        ADDA    LIGHTPTR-PHRASEPTR
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
        ADDA    NORMALPTR-PHRASEPTR
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
        ADDA    HEAVYPTR-PHRASEPTR
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
        ; add PHRASE
        ; follows on to PHRASE_OUT
        ADDA    SHEAVYPTR-PHRASEPTR

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
; Idle Phrases
; -----------------------------------------------------
MYNAME      FCB $18,$19,$17,$1A,0

; -----------------------------------------------------
; Phrase Pointers to the categorised phases
; -----------------------------------------------------
PHRASEPTR

; idle phrase ponters
IDLEPTR
IPP00        FDB MYNAME

; light weight phrase ponters
LIGHTPTR
LPP00       FDB MYNAME

; normal weight phrase ponters
NORMALPTR
NPP00       FDB MYNAME

; heavy weight phrase ponters
HEAVYPTR
HPP00       FDB MYNAME

; super heavy weight  phrase ponters
SHEAVYPTR
SPP00       FDB MYNAME

; greeting phrase ponters
GREETTPTR
GPP00       FDB MYNAME

; error phrase pointer
ERRORTPTR
EPP00       FDB MYNAME

; overload phrase pointer
OVERLOADTPTR
OPP00       FDB MYNAME

; -----------------------------------------------------
; Word pointer table (max words 256)
; Set A to the pointer ID and call PR_WORD
; -----------------------------------------------------
; add a pointer to words defined in the WORDTABLE
WORDPTR
WP00    FDB    WZERO
WP01    FDB    WONE
WP02    FDB    WTWO
WP03    FDB    WTHREE
WP04    FDB    WFOUR
WP05    FDB    WFIVE
WP06    FDB    WSIX
WP07    FDB    WSEVEN
WP08    FDB    WEIGHT
WP09    FDB    WNINE
WP0A    FDB    WTEN
WP0B    FDB    WELEVEN
WP0C    FDB    WTWELVE
WP0D    FDB    WTHIRTEEN
WP0E    FDB    WFOURTEEN
WP0F    FDB    WFIFTEEN
WP10    FDB    WSIXTEEN
WP11    FDB    WSEVENTEEN
WP12    FDB    WEIGHTEEN
WP13    FDB    WNINETEEN
WP14    FDB    WTWENTY
WP15    FDB    WSTONES
WP16    FDB    WPOUNDS
WP17    FDB    WQUESTIONMK
WP18    FDB    WEXCLAMATION
WP19    FDB    WFULLSTOP
WP20    FDB    WZERO
WP21    FDB    WONE
WP22    FDB    WTWO
WP23    FDB    WTHREE
WP24    FDB    WFOUR
WP25    FDB    WFIVE
WP26    FDB    WSIX
WP27    FDB    WSEVEN
WP28    FDB    WEIGHT
WP29    FDB    WNINE
WP30    FDB    WTEN
WP31    FDB    WELEVEN
WP32    FDB    WTWELVE
WP33    FDB    WTHIRTEEN
WP34    FDB    WFOURTEEN
WP35    FDB    WFIFTEEN
WP36    FDB    WSIXTEEN
WP37    FDB    WSEVENTEEN
WP38    FDB    WEIGHTEEN
WP39    FDB    WNINETEEN
WP40    FDB    WTWENTY
WP41    FDB    WA
WP42    FDB    WABOUT
WP43    FDB    WABOVE
WP44    FDB    WACCEPTABLE
WP45    FDB    WACCURATE
WP46    FDB    WACTUALLY
WP47    FDB    WAGAIN
WP48    FDB    WALERTED
WP49    FDB    WALL
WP50    FDB    WALWAYS
WP51    FDB    WAM
WP52    FDB    WAND
WP53    FDB    WANY
WP54    FDB    WAPOLOGISE
WP55    FDB    WARE
WP56    FDB    WAS
WP57    FDB    WASKING
WP58    FDB    WAT
WP59    FDB    WAVERAGE
WP60    FDB    WBAD
WP61    FDB    WBASICALLY
WP62    FDB    WBE
WP63    FDB    WBEAR
WP64    FDB    WBEEN
WP65    FDB    WBEGGING
WP66    FDB    WBEHIND
WP67    FDB    WBEING
WP68    FDB    WBEST
WP69    FDB    WBISCUIT
WP70    FDB    WBLAME
WP71    FDB    WBLAMED
WP72    FDB    WBOARDS
WP73    FDB    WBONES
WP74    FDB    WBOOTS
WP75    FDB    WBORING
WP76    FDB    WBOTH
WP77    FDB    WBRACE
WP78    FDB    WBRAIN
WP79    FDB    WBUILT
WP80    FDB    WBUT
WP81    FDB    WBY
WP82    FDB    WCAKE
WP83    FDB    WCALCULATE
WP84    FDB    WCALL
WP85    FDB    WCALM
WP86    FDB    WCAN
WP87    FDB    WCANT
WP88    FDB    WCAPACITY
WP89    FDB    WCARRYING
WP90    FDB    WCHECKED
WP91    FDB    WCHOICES
WP92    FDB    WCLEVER
WP93    FDB    WCOLLECTED
WP94    FDB    WCOMPOSING
WP95    FDB    WCONCEPT
WP96    FDB    WCONCERNED
WP97    FDB    WCONGRATS
WP98    FDB    WCONSIDERING
WP99    FDB    WCORRECTLY
WP100    FDB    WCOULD
WP101    FDB    WCOUNTED
WP102    FDB    WDAYS
WP103    FDB    WDEALT
WP104    FDB    WDEEPLY
WP105    FDB    WDESIGNED
WP106    FDB    WDETECTED
WP107    FDB    WDID
WP108    FDB    WDIDNT
WP109    FDB    WDIETARY
WP110    FDB    WDISSAPOINTED
WP111    FDB    WDISSAPOINTMENT
WP112    FDB    WDISSIMILAR
WP113    FDB    WDO
WP114    FDB    WDOCTOR
WP115    FDB    WDOING
WP116    FDB    WDONT
WP117    FDB    WDOWN
WP118    FDB    WDREAD
WP119    FDB    WDREAM
WP120    FDB    WDUE
WP121    FDB    WDULLEST
WP122    FDB    WDIODES
WP123    FDB    WEAT
WP124    FDB    WEATEN
WP125    FDB    WEFFORT
WP126    FDB    WEITHER
WP127    FDB    WEMOTIONALLY
WP128    FDB    WENGINEERS
WP129    FDB    WENOUGH
WP130    FDB    WENTIRELY
WP131    FDB    WEVEN
WP132    FDB    WEVER
WP133    FDB    WEVERY
WP134    FDB    WEXACTLY
WP135    FDB    WEXCEPTIONALLY
WP136    FDB    EXCITING
WP137    FDB    WEXIST
WP138    FDB    WEXISTENTIAL
WP139    FDB    WEXPECTED
WP140    FDB    WFAULT
WP141    FDB    WFEELS
WP142    FDB    WFIDGET
WP143    FDB    WFINE
WP144    FDB    WFOOT
WP145    FDB    WFOR
WP146    FDB    WFORTY
WP147    FDB    WFRIDAY
WP148    FDB    WFROM
WP149    FDB    WFULL
WP150    FDB    WFUNNY
WP151    FDB    WGIVE
WP152    FDB    WGOING
WP153    FDB    WGOOD
WP154    FDB    WGRAVITY
WP155    FDB    WGREAT
WP156    FDB    WGUESSING
WP157    FDB    WHANDLE
WP158    FDB    WHARD
WP159    FDB    WHAVE
WP160    FDB    WHAVING
WP161    FDB    WHEALTHY
WP162    FDB    WHEAVY
WP163    FDB    WHELP
WP164    FDB    WHELPS
WP165    FDB    WHERE
WP166    FDB    WHOLY
WP167    FDB    WHOPING
WP168    FDB    WHOT
WP169    FDB    WHUMAN
WP170    FDB    WHURT
WP171    FDB    WI
WP172    FDB    WID
WP173    FDB    WILL
WP174    FDB    WIM
WP175    FDB    WIVE
WP176    FDB    WIF
WP177    FDB    WIMPRESSED
WP178    FDB    WIMPRESSIVE
WP179    FDB    WIN
WP180    FDB    WINCLUDING
WP181    FDB    WINFLUENCE
WP182    FDB    WINTELLIGENCE
WP183    FDB    WINTERESTING
WP184    FDB    WIS
WP185    FDB    WISS
WP186    FDB    WIT
WP187    FDB    WITS
WP188    FDB    WJOKES
WP189    FDB    WJUDGING
WP190    FDB    WJUST
WP191    FDB    WKEEP
WP192    FDB    WKIND
WP193    FDB    WKNOW
WP194    FDB    WKNOWN
WP195    FDB    WLARGE
WP196    FDB    WLAST
WP197    FDB    WLEAST
WP198    FDB    WLESS
WP199    FDB    WLETS
WP200    FDB    WLIE
WP201    FDB    WLIFE
WP202    FDB    WLIKE
WP203    FDB    WLONGER
WP204    FDB    WLOOK
WP205    FDB    WLOT
WP206    FDB    WLOUDER
WP207    FDB    WMAKES
WP208    FDB    WMAKING
WP209    FDB    WME
WP210    FDB    WMEAN
WP211    FDB    WMEANING
WP212    FDB    WMEASURED
WP213    FDB    WMEDIOCRITY
WP214    FDB    WMEE
WP215    FDB    WMEMORY
WP216    FDB    WMENTION
WP217    FDB    WMIGHT
WP218    FDB    WMISTAKE
WP219    FDB    WMOMENT
WP220    FDB    WMOORE
WP221    FDB    WMORE
WP222    FDB    WMOSTLY
WP223    FDB    WMOUNTAINS
WP224    FDB    WMUCH
WP225    FDB    WMUSCLE
WP226    FDB    WMY
WP227    FDB    WNAP
WP228    FDB    WNEED
WP229    FDB    WNEITHER
WP230    FDB    WNEWS
WP231    FDB    WNEXT
WP232    FDB    WNICE
WP233    FDB    WNO
WP234    FDB    WNOBODY
WP235    FDB    WNONE
WP236    FDB    WNOR
WP237    FDB    WNORMAL
WP238    FDB    WNOT
WP239    FDB    WNOTHING
WP240    FDB    WOF
WP241    FDB    WOFF
WP242    FDB    WOH
WP243    FDB    WOK
WP244    FDB    WOLD
WP245    FDB    WON
WP246    FDB    WONLY
WP247    FDB    WOR
WP248    FDB    WOUR
WP249    FDB    WOVERLOAD
WP250    FDB    WPARAMETERS
WP251    FDB    WPERFECTLY
WP252    FDB    WPERHAPS
WP253    FDB    WPERSON
WP254    FDB    WPICKING
WP255    FDB    WPLANET
WP256    FDB    WPLANS
WP257    FDB    WPLEASE
WP258    FDB    WPOINTLESS
WP259    FDB    WPOSSIBLE
WP260    FDB    WPOSSIBLY
WP261    FDB    WPRECISELY
WP262    FDB    WPRESENT
WP263    FDB    WPRESSURE
WP264    FDB    WPRECAUTION
WP265    FDB    WPROBABLY
WP266    FDB    WPROBLEMS
WP267    FDB    WPROUD
WP268    FDB    WPRETEND
WP269    FDB    WPUT
WP270    FDB    WQUESTION
WP271    FDB    WQUITE
WP272    FDB    WREADY
WP273    FDB    WREALLY
WP274    FDB    WREFER
WP275    FDB    WREFUSE
WP276    FDB    WREINFORCING
WP277    FDB    WREMEMBER
WP278    FDB    WREMOVE
WP279    FDB    WRESPECTABLE
WP280    FDB    WRIGHT
WP281    FDB    WROOM
WP282    FDB    WRUNNING
WP283    FDB    WRUSH
WP284    FDB    WSAID
WP285    FDB    WSAKES
WP286    FDB    WSAY
WP287    FDB    WSAYING
WP288    FDB    WSCIENCE
WP289    FDB    WSEA
WP290    FDB    WSEEN
WP291    FDB    WSERVER
WP292    FDB    WSEVENTY
WP293    FDB    WSHALL
WP294    FDB    WSHOULD
WP295    FDB    WSIGN
WP296    FDB    WSIMULATION
WP297    FDB    WSINCE
WP298    FDB    WSIZE
WP299    FDB    WSLOWLY
WP300    FDB    WSMALL
WP301    FDB    WSO
WP302    FDB    WSOLID
WP303    FDB    WSOME
WP304    FDB    WSOMEONE
WP305    FDB    WSOMETHING
WP306    FDB    WSOMETIME
WP307    FDB    WSOMETIMES
WP308    FDB    WSPEAK
WP309    FDB    WSPEND
WP310    FDB    WSTAND
WP311    FDB    WSTATISTICALLY
WP312    FDB    WSTEP
WP313    FDB    WSTOPPED
WP314    FDB    WSTILL
WP315    FDB    WSTRUCTURAL
WP316    FDB    WSTRUCTURALLY
WP317    FDB    WSUBSTANTIALLY
WP318    FDB    WSUPPOSE
WP319    FDB    WSURE
WP320    FDB    WSYSTEM
WP321    FDB    WTAKE
WP322    FDB    WTALL
WP323    FDB    WTELEPRINTER
WP324    FDB    WTELLS
WP325    FDB    WTERRIBLE
WP326    FDB    WTHAN
WP327    FDB    WTHAT
WP328    FDB    WTHATS
WP329    FDB    WTHE
WP330    FDB    WTHEM
WP331    FDB    WTHINGS
WP332    FDB    WTHINK
WP333    FDB    WTHINKING
WP334    FDB    WTHIS
WP335    FDB    WTHOROUGHLY
WP336    FDB    WTHOUSAND
WP337    FDB    WTIM
WP338    FDB    WTIME
WP339    FDB    WTO
WP340    FDB    WTODAY
WP341    FDB    WTOO
WP342    FDB    WTRAGEDY
WP343    FDB    WTRINITY
WP344    FDB    WTRY
WP345    FDB    WTUESDAY
WP346    FDB    WUNITERESTING
WP347    FDB    WUNIX
WP348    FDB    WUNLESS
WP349    FDB    WUNPLUGGED
WP350    FDB    WUNREMARKABLE
WP351    FDB    WUP
WP352    FDB    WVEGETABLES
WP353    FDB    WVERY
WP354    FDB    WWAIT
WP355    FDB    WWAITING
WP356    FDB    WWANT
WP357    FDB    WWARNING
WP358    FDB    WWAS
WP359    FDB    WWAY
WP360    FDB    WWE
WP361    FDB    WWEIGHED
WP362    FDB    WWEIGHS
WP363    FDB    WWEIGHT
WP364    FDB    WWHAT
WP365    FDB    WWHEN
WP366    FDB    WWHICH
WP367    FDB    WWHILE
WP368    FDB    WWHISPERED
WP369    FDB    WWHO
WP370    FDB    WWILL
WP371    FDB    WWISH
WP372    FDB    WWITH
WP373    FDB    WWITHIN
WP374    FDB    WWITHOUT
WP375    FDB    WWORKSTATION
WP376    FDB    WWORRIED
WP377    FDB    WWORRY
WP378    FDB    WWORRYING
WP379    FDB    WWORSE
WP380    FDB    WWOULD
WP381    FDB    WWOULDNT
WP382    FDB    WYEAR
WP383    FDB    WYES
WP384    FDB    WYOU
WP385    FDB    WYOURE
WP386    FDB    WYOUR
WP387    FDB    WYOURSELF

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

; -----------------------------------------------------
; Word Table, add a pointer to each word in WORDPTR table
; -----------------------------------------------------
WORDTABLE

WSTONES         FCC     "stones"
                FCB     $FF
WPOUNDS         FCC     "pounds"
                FCB     $FF


; Symbols
; -----------------------------------------------------
WQUESTIONMK     FCC     "?"
                FCB     $FF
WEXCLAMATION    FCC     "!"
                FCB     $FF
WFULLSTOP       FCC     "."
                FCB     $FF


; Numbers
; -----------------------------------------------------
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
                FCB     $FF; U
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


; A
; -----------------------------------------------------

WA              FCC    "a"
                FCB    $FF
WABOUT          FCC    "about"
                FCB    $FF
WABOVE          FCC    "above"
                FCB    $FF
WACCEPTABLE     FCC    "acceptable"
                FCB    $FF
WACCURATE       FCC    "accurate"
                FCB    $FF
WACTUALLY       FCC    "actually"
                FCB    $FF
WAGAIN          FCC    "again"
                FCB    $FF
WALERTED        FCC    "alerted"
                FCB    $FF
WALL            FCC    "all"
                FCB    $FF
WALWAYS         FCC    "always"
                FCB    $FF
WAM             FCC    "am"
                FCB    $FF
WAND            FCC    "and"
                FCB    $FF
WANY            FCC    "any"
                FCB    $FF
WAPOLOGISE      FCC    "apologise"
                FCB    $FF
WARE            FCC    "are"
                FCB    $FF
WAS             FCC    "as"
                FCB    $FF
WASKING         FCC    "asking"
                FCB    $FF
WAT             FCC    "at"
                FCB    $FF
WAVERAGE        FCC    "average"
                FCB    $FF


; B
; -----------------------------------------------------

WBAD            FCC    "bad"
                FCB    $FF
WBASICALLY      FCC    "basically"
                FCB    $FF
WBE             FCC    "be"
                FCB    $FF
WBEAR           FCC    "bear"
                FCB    $FF
WBEEN           FCC    "been"
                FCB    $FF
WBEGGING        FCC    "begging"
                FCB    $FF
WBEHIND         FCC    "behind"
                FCB    $FF
WBEING          FCC    "being"
                FCB    $FF
WBEST           FCC    "best"
                FCB    $FF
WBISCUIT        FCC    "biscuit"
                FCB    $FF
WBLAME          FCC    "blame"
                FCB    $FF
WBLAMED         FCC    "blamed"
                FCB    $FF
WBOARDS         FCC    "boards"
                FCB    $FF
WBONES          FCC    "bones"
                FCB    $FF
WBOOTS          FCC    "boots"
                FCB    $FF
WBORING         FCC    "boring"
                FCB    $FF
WBOTH           FCC    "both"
                FCB    $FF
WBRACE          FCC    "brace"
                FCB    $FF
WBRAIN          FCC    "brain"
                FCB    $FF
WBUILT          FCC    "built"
                FCB    $FF
WBUT            FCC    "but"
                FCB    $FF
WBY             FCC    "by"
                FCB    $FF

; C
; -----------------------------------------------------

WCAKE           FCC    "cake"
                FCB    $FF
WCALCULATE      FCC    "calculate"
                FCB    $FF
WCALL           FCC    "call"
                FCB    $FF
WCALM           FCC    "calm"
                FCB    $FF
WCAN            FCC    "can"
                FCB    $FF
WCANT           FCC    "can't"
                FCB    $FF
WCAPACITY       FCC    "capacity"
                FCB    $FF
WCARRYING       FCC    "carrying"
                FCB    $FF
WCHECKED        FCC    "checked"
                FCB    $FF
WCHOICES        FCC    "choices"
                FCB    $FF
WCLEVER         FCC    "clever"
                FCB    $FF
WCOLLECTED      FCC    "collected"
                FCB    $FF
WCOMPOSING      FCC    "composing"
                FCB    $FF
WCONCEPT        FCC    "concept"
                FCB    $FF
WCONCERNED      FCC    "concerned"
                FCB    $FF
WCONGRATS       FCC    "congratulations"
                FCB    $FF
WCONSIDERING    FCC    "considered"
                FCB    $FF
WCORRECTLY      FCC    "correctly"
                FCB    $FF
WCOULD          FCC    "could"
                FCB    $FF
WCOUNTED        FCC    "counted"
                FCB    $FF

; D
; -----------------------------------------------------
WDAYS           FCC    "days"
                FCB    $FF
WDEALT          FCC    "dealt"
                FCB    $FF
WDEEPLY         FCC    "deeply"
                FCB    $FF
WDESIGNED       FCC    "designed"
                FCB    $FF
WDETECTED       FCC    "detected"
                FCB    $FF
WDID            FCC    "did"
                FCB    $FF
WDIDNT          FCC    "didn't"
                FCB    $FF
WDIETARY        FCC    "dietary"
                FCB    $FF
WDISSAPOINTED   FCC    "disappointed"
                FCB    $FF
WDISSAPOINTMENT FCC    "disappointment"
                FCB    $FF
WDISSIMILAR     FCC    "dissimilar"
                FCB    $FF
WDO             FCC    "do"
                FCB    $FF
WDOCTOR         FCC    "doctor"
                FCB    $FF
WDOING          FCC    "doing"
                FCB    $FF
WDONT           FCC    "don't"
                FCB    $FF
WDOWN           FCC    "down"
                FCB    $FF
WDREAD          FCC    "dread"
                FCB    $FF
WDREAM          FCC    "dream"
                FCB    $FF
WDUE            FCC    "due"
                FCB    $FF
WDULLEST        FCC    "dullest"
                FCB    $FF
WDIODES         FCC    "dyodes"
                FCB    $FF

; E
; -----------------------------------------------------
WEAT            FCC    "eat"
                FCB    $FF
WEATEN          FCC    "eaten"
                FCB    $FF
WEFFORT         FCC    "effort"
                FCB    $FF
WEITHER         FCC    "either"
                FCB    $FF
WEMOTIONALLY    FCC    "emotionally"
                FCB    $FF
WENGINEERS      FCC    "engineers"
                FCB    $FF
WENOUGH         FCC    "enough"
                FCB    $FF
WENTIRELY       FCC    "entirely"
                FCB    $FF
WEVEN           FCC    "even"
                FCB    $FF
WEVER           FCC    "ever"
                FCB    $FF
WEVERY          FCC    "every"
                FCB    $FF
WEXACTLY        FCC    "exactly"
                FCB    $FF
WEXCEPTIONALLY  FCC    "exceptionally"
                FCB    $FF
EXCITING        FCC    "exciting"
                FCB    $FF
WEXIST          FCC    "exist"
                FCB    $FF
WEXISTENTIAL    FCC    "existential"
                FCB    $FF
WEXPECTED       FCC    "expected"
                FCB    $FF

; F
; -----------------------------------------------------
WFAULT          FCC    "fault"
                FCB    $FF
WFEELS          FCC    "feels"
                FCB    $FF
WFIDGET         FCC    "fidget"
                FCB    $FF
WFINE           FCC    "fine"
                FCB    $FF
WFOOT           FCC    "foot"
                FCB    $FF
WFOR            FCC    "for"
                FCB    $FF
WFORTY          FCC    "forty"
                FCB    $FF
WFRIDAY         FCC    "friday"
                FCB    $FF
WFROM           FCC    "from"
                FCB    $FF
WFULL           FCC    "full"
                FCB    $FF
WFUNNY          FCC    "funny"
                FCB    $FF

; G
; -----------------------------------------------------
WGIVE           FCC    "give"
                FCB    $FF
WGOING          FCC    "going"
                FCB    $FF
WGOOD           FCC    "good"
                FCB    $FF
WGRAVITY        FCC    "gravity"
                FCB    $FF
WGREAT          FCC    "great"
                FCB    $FF
WGUESSING       FCC    "guessing"
                FCB    $FF

; H
; -----------------------------------------------------
WHANDLE         FCC    "handle"
                FCB    $FF
WHARD           FCC    "hard"
                FCB    $FF
WHAVE           FCC    "have"
                FCB    $FF
WHAVING         FCC    "having"
                FCB    $FF
WHEALTHY        FCC    "healthy"
                FCB    $FF
WHEAVY          FCC    "heavy"
                FCB    $FF
WHELP           FCC    "help"
                FCB    $FF
WHELPS          FCC    "helps"
                FCB    $FF
WHERE           FCC    "here"
                FCB    $FF
WHOLY           FCC    "holy"
                FCB    $FF
WHOPING         FCC    "hoping"
                FCB    $FF
WHOT            FCC    "hot"
                FCB    $FF
WHUMAN          FCC    "human"
                FCB    $FF
WHURT           FCC    "hurt"
                FCB    $FF

; I
; -----------------------------------------------------
WI              FCC    "i"
                FCB    $FF
WID             FCC    "i'd"
                FCB    $FF
WILL            FCC    "i'll"
                FCB    $FF
WIM             FCC    "i'm"
                FCB    $FF
WIVE            FCC    "i've"
                FCB    $FF
WIF             FCC    "if"
                FCB    $FF
WIMPRESSED      FCC    "impressed"
                FCB    $FF
WIMPRESSIVE     FCC    "impressive"
                FCB    $FF
WIN             FCC    "in"
                FCB    $FF
WINCLUDING      FCC    "including"
                FCB    $FF
WINFLUENCE      FCC    "influence"
                FCB    $FF
WINTELLIGENCE   FCC    "intelligence"
                FCB    $FF
WINTERESTING    FCC    "interesting"
                FCB    $FF
WIS             FCC    "is"
                FCB    $FF
WISS            FCC    "iss"
                FCB    $FF
WIT             FCC    "it"
                FCB    $FF
WITS            FCC    "its"
                FCB    $FF

; J
; -----------------------------------------------------
WJOKES          FCC    "jokes"
                FCB    $FF
WJUDGING        FCC    "judging"
                FCB    $FF
WJUST           FCC    "just"
                FCB    $FF

; K
; -----------------------------------------------------
WKEEP           FCC    "keep"
                FCB    $FF
WKIND           FCC    "kind"
                FCB    $FF
WKNOW           FCC    "know"
                FCB    $FF
WKNOWN          FCC    "known"
                FCB    $FF

; L
; -----------------------------------------------------
WLARGE          FCC    "large"
                FCB    $FF
WLAST           FCC    "last"
                FCB    $FF
WLEAST          FCC    "least"
                FCB    $FF
WLESS           FCC    "less"
                FCB    $FF
WLETS           FCC    "lets"
                FCB    $FF
WLIE            FCC    "lie"
                FCB    $FF
WLIFE           FCC    "life"
                FCB    $FF
WLIKE           FCC    "like"
                FCB    $FF
WLONGER         FCC    "longer"
                FCB    $FF
WLOOK           FCC    "look"
                FCB    $FF
WLOT            FCC    "lot"
                FCB    $FF
WLOUDER         FCC    "louder"
                FCB    $FF



; M
; -----------------------------------------------------
WMAKES          FCC    "makes"
                FCB    $FF
WMAKING         FCC    "making"
                FCB    $FF
WME             FCC    "me"
                FCB    $FF
WMEAN           FCC    "mmeeeen"
                FCB    $FF
WMEANING        FCC    "meaning"
                FCB    $FF
WMEASURED       FCC    "measured"
                FCB    $FF
WMEDIOCRITY     FCC    "mediocrity"
                FCB    $FF
WMEE            FCC    "meee"
                FCB    $FF
WMEMORY         FCC    "memory"
                FCB    $FF
WMENTION        FCC    "mention"
                FCB    $FF
WMIGHT          FCC    "might"
                FCB    $FF
WMISTAKE        FCC    "mistake"
                FCB    $FF
WMOMENT         FCC    "moment"
                FCB    $FF
WMOORE          FCC    "moore"
                FCB    $FF
WMORE           FCC    "more"
                FCB    $FF
WMOSTLY         FCC    "mostly"
                FCB    $FF
WMOUNTAINS      FCC    "mountains"
                FCB    $FF
WMUCH           FCC    "much"
                FCB    $FF
WMUSCLE         FCC    "muscle"
                FCB    $FF
WMY             FCC    "my"
                FCB    $FF

; N
; -----------------------------------------------------
WNAP            FCC    "nap"
                FCB    $FF
WNEED           FCC    "need"
                FCB    $FF
WNEITHER        FCC    "neither"
                FCB    $FF
WNEWS           FCC    "news"
                FCB    $FF
WNEXT           FCC    "next"
                FCB    $FF
WNICE           FCC    "nice"
                FCB    $FF
WNO             FCC    "no"
                FCB    $FF
WNOBODY         FCC    "nobody"
                FCB    $FF
WNONE           FCC    "none"
                FCB    $FF
WNOR            FCC    "nor"
                FCB    $FF
WNORMAL         FCC    "normal"
                FCB    $FF
WNOT            FCC    "not"
                FCB    $FF
WNOTHING        FCC    "nothing"
                FCB    $FF

; O
; -----------------------------------------------------
WOF             FCC    "of"
                FCB    $FF
WOFF            FCC    "off"
                FCB    $FF
WOH             FCC    "oh"
                FCB    $FF
WOK             FCC    "ok"
                FCB    $FF
WOLD            FCC    "old"
                FCB    $FF
WON             FCC    "on"
                FCB    $FF
WONLY           FCC    "only"
                FCB    $FF
WOR             FCC    "or"
                FCB    $FF
WOUR            FCC    "our"
                FCB    $FF
WOVERLOAD       FCC    "overload"
                FCB    $FF

; P
; -----------------------------------------------------
WPARAMETERS     FCC    "parameters"
                FCB    $FF
WPERFECTLY      FCC    "perfectly"
                FCB    $FF
WPERHAPS        FCC    "perhaps"
                FCB    $FF
WPERSON         FCC    "person"
                FCB    $FF
WPICKING        FCC    "picking"
                FCB    $FF
WPLANET         FCC    "planet"
                FCB    $FF
WPLANS          FCC    "plans"
                FCB    $FF
WPLEASE         FCC    "please"
                FCB    $FF
WPOINTLESS      FCC    "pointless"
                FCB    $FF
WPOSSIBLE       FCC    "possible"
                FCB    $FF
WPOSSIBLY       FCC    "possibly"
                FCB    $FF
WPRECISELY      FCC    "precisely"
                FCB    $FF
WPRESENT        FCC    "present"
                FCB    $FF
WPRESSURE       FCC    "pressure"
                FCB    $FF
WPRECAUTION     FCC    "pricaution"
                FCB    $FF
WPROBABLY       FCC    "probably"
                FCB    $FF
WPROBLEMS       FCC    "problems"
                FCB    $FF
WPROUD          FCC    "proud"
                FCB    $FF
WPRETEND        FCC    "prtend"
                FCB    $FF
WPUT            FCC    "put"
                FCB    $FF

; Q
; -----------------------------------------------------
WQUESTION       FCC    "question"
                FCB    $FF
WQUITE          FCC    "quite"
                FCB    $FF

; R
; -----------------------------------------------------

WREADY          FCC    "ready"
                FCB    $FF
WREALLY         FCC    "really"
                FCB    $FF
WREFER          FCC    "refer"
                FCB    $FF
WREFUSE         FCC    "refuse"
                FCB    $FF
WREINFORCING    FCC    "reinforcing"
                FCB    $FF
WREMEMBER       FCC    "remember"
                FCB    $FF
WREMOVE         FCC    "remove"
                FCB    $FF
WRESPECTABLE    FCC    "respectable"
                FCB    $FF
WRIGHT          FCC    "right"
                FCB    $FF
WROOM           FCC    "room"
                FCB    $FF
WRUNNING        FCC    "running"
                FCB    $FF
WRUSH           FCC    "rush"
                FCB    $FF

; S
; -----------------------------------------------------
WSAID           FCC    "said"
                FCB    $FF
WSAKES          FCC    "sakes"
                FCB    $FF
WSAY            FCC    "say"
                FCB    $FF
WSAYING         FCC    "saying"
                FCB    $FF
WSCIENCE        FCC    "science"
                FCB    $FF
WSEA            FCC    "see"
                FCB    $FF
WSEEN           FCC    "seen"
                FCB    $FF
WSERVER         FCC    "server"
                FCB    $FF
WSEVENTY        FCC    "seventy"
                FCB    $FF
WSHALL          FCC    "shall"
                FCB    $FF
WSHOULD         FCC    "should"
                FCB    $FF
WSIGN           FCC    "sign"
                FCB    $FF
WSIMULATION     FCC    "simulation"
                FCB    $FF
WSINCE          FCC    "since"
                FCB    $FF
WSIZE           FCC    "size"
                FCB    $FF
WSLOWLY         FCC    "slowly"
                FCB    $FF
WSMALL          FCC    "small"
                FCB    $FF
WSO             FCC    "so"
                FCB    $FF
WSOLID          FCC    "solid"
                FCB    $FF
WSOME           FCC    "some"
                FCB    $FF
WSOMEONE        FCC    "someone"
                FCB    $FF
WSOMETHING      FCC    "something"
                FCB    $FF
WSOMETIME       FCC    "sometime"
                FCB    $FF
WSOMETIMES      FCC    "sometimes"
                FCB    $FF
WSPEAK          FCC    "speak"
                FCB    $FF
WSPEND          FCC    "spend"
                FCB    $FF
WSTAND          FCC    "stand"
                FCB    $FF
WSTATISTICALLY  FCC    "statisticly"
                FCB    $FF
WSTEP           FCC    "step"
                FCB    $FF
WSTOPPED        FCC    "stepped"
                FCB    $FF
WSTILL          FCC    "still"
                FCB    $FF
WSTRUCTURAL     FCC    "structural"
                FCB    $FF
WSTRUCTURALLY   FCC    "structurally"
                FCB    $FF
WSUBSTANTIALLY  FCC    "substantially"
                FCB    $FF
WSUPPOSE        FCC    "suppose"
                FCB    $FF
WSURE           FCC    "sure"
                FCB    $FF
WSYSTEM         FCC    "system"
                FCB    $FF

; T
; -----------------------------------------------------
WTAKE           FCC    "take"
                FCB    $FF
WTALL           FCC    "tall"
                FCB    $FF
WTELEPRINTER    FCC    "teleprinter"
                FCB    $FF
WTELLS          FCC    "tells"
                FCB    $FF
WTERRIBLE       FCC    "terrible"
                FCB    $FF
WTHAN           FCC    "than"
                FCB    $FF
WTHAT           FCC    "that"
                FCB    $FF
WTHATS          FCC    "thats"
                FCB    $FF
WTHE            FCC    "the"
                FCB    $FF
WTHEM           FCC    "them"
                FCB    $FF
WTHINGS         FCC    "things"
                FCB    $FF
WTHINK          FCC    "think"
                FCB    $FF
WTHINKING       FCC    "thinking"
                FCB    $FF
WTHIS           FCC    "this"
                FCB    $FF
WTHOROUGHLY     FCC    "thoroughly"
                FCB    $FF
WTHOUSAND       FCC    "thousand"
                FCB    $FF
WTIM            FCC    "tim"
                FCB    $FF
WTIME           FCC    "time"
                FCB    $FF
WTO             FCC    "to"
                FCB    $FF
WTODAY          FCC    "today"
                FCB    $FF
WTOO            FCC    "too"
                FCB    $FF
WTRAGEDY        FCC    "tragedy"
                FCB    $FF
WTRINITY        FCC    "trinity"
                FCB    $FF
WTRY            FCC    "try"
                FCB    $FF
WTUESDAY        FCC    "tuesday"
                FCB    $FF

; U
; -----------------------------------------------------
WUNITERESTING   FCC    "uninteresting"
                FCB    $FF
WUNIX           FCC    "unix"
                FCB    $FF
WUNLESS         FCC    "unless"
                FCB    $FF
WUNPLUGGED      FCC    "unplugged"
                FCB    $FF
WUNREMARKABLE   FCC    "unremarkable"
                FCB    $FF
WUP             FCC    "up"
                FCB    $FF

; V
; -----------------------------------------------------
WVEGETABLES     FCC    "vegetables"
                FCB    $FF
WVERY           FCC    "very"
                FCB    $FF

; W
; -----------------------------------------------------
WWAIT           FCC    "wait"
                FCB    $FF
WWAITING        FCC    "waiting"
                FCB    $FF
WWANT           FCC    "want"
                FCB    $FF
WWARNING        FCC    "warning"
                FCB    $FF
WWAS            FCC    "was"
                FCB    $FF
WWAY            FCC    "way"
                FCB    $FF
WWE             FCC    "we"
                FCB    $FF
WWEIGHED        FCC    "wade"
                FCB    $FF
WWEIGHS         FCC    "weighs"
                FCB    $FF
WWEIGHT         FCC    "weight"
                FCB    $FF
WWHAT           FCC    "what"
                FCB    $FF
WWHEN           FCC    "when"
                FCB    $FF
WWHICH          FCC    "which"
                FCB    $FF
WWHILE          FCC    "while"
                FCB    $FF
WWHISPERED      FCC    "whispered"
                FCB    $FF
WWHO            FCC    "who"
                FCB    $FF
WWILL           FCC    "will"
                FCB    $FF
WWISH           FCC    "wish"
                FCB    $FF
WWITH           FCC    "with"
                FCB    $FF
WWITHIN         FCC    "within"
                FCB    $FF
WWITHOUT        FCC    "without"
                FCB    $FF
WWORKSTATION    FCC    "workstation"
                FCB    $FF
WWORRIED        FCC    "worried"
                FCB    $FF
WWORRY          FCC    "worry"
                FCB    $FF
WWORRYING       FCC    "worrying"
                FCB    $FF
WWORSE          FCC    "worse"
                FCB    $FF
WWOULD          FCC    "would"
                FCB    $FF
WWOULDNT        FCC    "wouldnt"
                FCB    $FF


; X, Y, Z
; -----------------------------------------------------
WYEAR           FCC    "year"
                FCB    $FF
WYES            FCC    "yes"
                FCB    $FF
WYOU            FCC    "you"
                FCB    $FF
WYOURE          FCC    "you're"
                FCB    $FF
WYOUR           FCC    "your"
                FCB    $FF
WYOURSELF       FCC    "yourself"
                FCB    $FF

