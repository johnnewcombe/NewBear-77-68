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
        BHI     OVERLOADED
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
        JMP     NORMALW
ML4     CMPA    #SHEAVY_WGHT    ; less than super heavy is heavy
        BMI     ML5
        JMP     HEAVYW
ML5     JMP     SHEAVY
        JMP END

; -----------------------------------------------------
; Over 20 stone so random heavy phrase to ports B
; -----------------------------------------------------
OVERLOADED
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

NORMALW ; output the normal message
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

HEAVYW  ; output the heavy message
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
STRB1   INX             ; Point to next byte
        LDAA    0,X     ; Get byte to be printed
        CMPA    #$FF    ; End-string ?
        BEQ     ENDSTR  ; Yes: Go to finish up
        JSR     PR_A    ; Print the byte to ACIA(a) (A is maintained)
        BSR     PR_B    ; Print the byte to ACIA(b)
        BRA     STRB1   ; Go back for next byte
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
; TODO this needs to be based on a 16bit value not A
;   i.e. use X and either push and pull or maybe use a
;   'phrase_id' address as a 16 bit store rather than A
;   or put the required word in X, add #WORDPTR to X and
;   go from there?


PR_WORD     INCA    ;
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

YOUWEIGH    FDB YOU,WEIGHS
            FCB 0

; -----------------------------------------------------
; Idle Phrases
; -----------------------------------------------------
MYNAME      FDB I,AM,NOT
            FCB 0

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
WP00    FDB    WPZERO
WP01    FDB    WPONE
WP02    FDB    WPTWO
WP03    FDB    WPTHREE
WP04    FDB    WPFOUR
WP05    FDB    WPFIVE
WP06    FDB    WPSIX
WP07    FDB    WPSEVEN
WP08    FDB    WPEIGHT
WP09    FDB    WPNINE
WP0A    FDB    WPTEN
WP0B    FDB    WPELEVEN
WP0C    FDB    WPTWELVE
WP0D    FDB    WPTHIRTEEN
WP0E    FDB    WPFOURTEEN
WP0F    FDB    WPFIFTEEN
WP10    FDB    WPSIXTEEN
WP11    FDB    WPSEVENTEEN
WP12    FDB    WPEIGHTEEN
WP13    FDB    WPNINETEEN
WP14    FDB    WPTWENTY
WP15    FDB    WPSTONES
WP16    FDB    WPPOUNDS
WP17    FDB    WPQUESTIONMK
WP18    FDB    WPEXCLAMATION
WP19    FDB    WPFULLSTOP
WP20    FDB    WPZERO
WP21    FDB    WPONE
WP22    FDB    WPTWO
WP23    FDB    WPTHREE
WP24    FDB    WPFOUR
WP25    FDB    WPFIVE
WP26    FDB    WPSIX
WP27    FDB    WPSEVEN
WP28    FDB    WPEIGHT
WP29    FDB    WPNINE
WP30    FDB    WPTEN
WP31    FDB    WPELEVEN
WP32    FDB    WPTWELVE
WP33    FDB    WPTHIRTEEN
WP34    FDB    WPFOURTEEN
WP35    FDB    WPFIFTEEN
WP36    FDB    WPSIXTEEN
WP37    FDB    WPSEVENTEEN
WP38    FDB    WPEIGHTEEN
WP39    FDB    WPNINETEEN
WP40    FDB    WPTWENTY
WP41    FDB    WPA
WP42    FDB    WPABOUT
WP43    FDB    WPABOVE
WP44    FDB    WPACCEPTABLE
WP45    FDB    WPACCURATE
WP46    FDB    WPACTUALLY
WP47    FDB    WPAGAIN
WP48    FDB    WPALERTED
WP49    FDB    WPALL
WP50    FDB    WPALWAYS
WP51    FDB    WPAM
WP52    FDB    WPAND
WP53    FDB    WPANY
WP54    FDB    WPAPOLOGISE
WP55    FDB    WPARE
WP56    FDB    WPAS
WP57    FDB    WPASKING
WP58    FDB    WPAT
WP59    FDB    WPAVERAGE
WP60    FDB    WPBAD
WP61    FDB    WPBASICALLY
WP62    FDB    WPBE
WP63    FDB    WPBEAR
WP64    FDB    WPBEEN
WP65    FDB    WPBEGGING
WP66    FDB    WPBEHIND
WP67    FDB    WPBEING
WP68    FDB    WPBEST
WP69    FDB    WPBISCUIT
WP70    FDB    WPBLAME
WP71    FDB    WPBLAMED
WP72    FDB    WPBOARDS
WP73    FDB    WPBONES
WP74    FDB    WPBOOTS
WP75    FDB    WPBORING
WP76    FDB    WPBOTH
WP77    FDB    WPBRACE
WP78    FDB    WPBRAIN
WP79    FDB    WPBUILT
WP80    FDB    WPBUT
WP81    FDB    WPBY
WP82    FDB    WPCAKE
WP83    FDB    WPCALCULATE
WP84    FDB    WPCALL
WP85    FDB    WPCALM
WP86    FDB    WPCAN
WP87    FDB    WPCANT
WP88    FDB    WPCAPACITY
WP89    FDB    WPCARRYING
WP90    FDB    WPCHECKED
WP91    FDB    WPCHOICES
WP92    FDB    WPCLEVER
WP93    FDB    WPCOLLECTED
WP94    FDB    WPCOMPOSING
WP95    FDB    WPCONCEPT
WP96    FDB    WPCONCERNED
WP97    FDB    WPCONGRATS
WP98    FDB    WPCONSIDERING
WP99    FDB    WPCORRECTLY
WP100    FDB    WPCOULD
WP101    FDB    WPCOUNTED
WP102    FDB    WPDAYS
WP103    FDB    WPDEALT
WP104    FDB    WPDEEPLY
WP105    FDB    WPDESIGNED
WP106    FDB    WPDETECTED
WP107    FDB    WPDID
WP108    FDB    WPDIDNT
WP109    FDB    WPDIETARY
WP110    FDB    WPDISSAPOINTED
WP111    FDB    WPDISSAPOINTMNT
WP112    FDB    WPDISSIMILAR
WP113    FDB    WPDO
WP114    FDB    WPDOCTOR
WP115    FDB    WPDOING
WP116    FDB    WPDONT
WP117    FDB    WPDOWN
WP118    FDB    WPDREAD
WP119    FDB    WPDREAM
WP120    FDB    WPDUE
WP121    FDB    WPDULLEST
WP122    FDB    WPDIODES
WP123    FDB    WPEAT
WP124    FDB    WPEATEN
WP125    FDB    WPEFFORT
WP126    FDB    WPEITHER
WP127    FDB    WPEMOTIONALLY
WP128    FDB    WPENGINEERS
WP129    FDB    WPENOUGH
WP130    FDB    WPENTIRELY
WP131    FDB    WPEVEN
WP132    FDB    WPEVER
WP133    FDB    WPEVERY
WP134    FDB    WPEXACTLY
WP135    FDB    WPEXCEPTIONALLY
WP136    FDB    WPEXCITING
WP137    FDB    WPEXIST
WP138    FDB    WPEXISTENTIAL
WP139    FDB    WPEXPECTED
WP140    FDB    WPFAULT
WP141    FDB    WPFEELS
WP142    FDB    WPFIDGET
WP143    FDB    WPFINE
WP144    FDB    WPFOOT
WP145    FDB    WPFOR
WP146    FDB    WPFORTY
WP147    FDB    WPFRIDAY
WP148    FDB    WPFROM
WP149    FDB    WPFULL
WP150    FDB    WPFUNNY
WP151    FDB    WPGIVE
WP152    FDB    WPGOING
WP153    FDB    WPGOOD
WP154    FDB    WPGRAVITY
WP155    FDB    WPGREAT
WP156    FDB    WPGUESSING
WP157    FDB    WPHANDLE
WP158    FDB    WPHARD
WP159    FDB    WPHAVE
WP160    FDB    WPHAVING
WP161    FDB    WPHEALTHY
WP162    FDB    WPHEAVY
WP163    FDB    WPHELP
WP164    FDB    WPHELPS
WP165    FDB    WPHERE
WP166    FDB    WPHOLY
WP167    FDB    WPHOPING
WP168    FDB    WPHOT
WP169    FDB    WPHUMAN
WP170    FDB    WPHURT
WP171    FDB    WPI
WP172    FDB    WPID
WP173    FDB    WPILL
WP174    FDB    WPIM
WP175    FDB    WPIVE
WP176    FDB    WPIF
WP177    FDB    WPIMPRESSED
WP178    FDB    WPIMPRESSIVE
WP179    FDB    WPIN
WP180    FDB    WPINCLUDING
WP181    FDB    WPINFLUENCE
WP182    FDB    WPINTELLIGENCE
WP183    FDB    WPINTERESTING
WP184    FDB    WPIS
WP185    FDB    WPISS
WP186    FDB    WPIT
WP187    FDB    WPITS
WP188    FDB    WPJOKES
WP189    FDB    WPJUDGING
WP190    FDB    WPJUST
WP191    FDB    WPKEEP
WP192    FDB    WPKIND
WP193    FDB    WPKNOW
WP194    FDB    WPKNOWN
WP195    FDB    WPLARGE
WP196    FDB    WPLAST
WP197    FDB    WPLEAST
WP198    FDB    WPLESS
WP199    FDB    WPLETS
WP200    FDB    WPLIE
WP201    FDB    WPLIFE
WP202    FDB    WPLIKE
WP203    FDB    WPLONGER
WP204    FDB    WPLOOK
WP205    FDB    WPLOT
WP206    FDB    WPLOUDER
WP207    FDB    WPMAKES
WP208    FDB    WPMAKING
WP209    FDB    WPME
WP210    FDB    WPMEAN
WP211    FDB    WPMEANING
WP212    FDB    WPMEASURED
WP213    FDB    WPMEDIOCRITY
WP214    FDB    WPMEE
WP215    FDB    WPMEMORY
WP216    FDB    WPMENTION
WP217    FDB    WPMIGHT
WP218    FDB    WPMISTAKE
WP219    FDB    WPMOMENT
WP220    FDB    WPMOORE
WP221    FDB    WPMORE
WP222    FDB    WPMOSTLY
WP223    FDB    WPMOUNTAINS
WP224    FDB    WPMUCH
WP225    FDB    WPMUSCLE
WP226    FDB    WPMY
WP227    FDB    WPNAP
WP228    FDB    WPNEED
WP229    FDB    WPNEITHER
WP230    FDB    WPNEWS
WP231    FDB    WPNEXT
WP232    FDB    WPNICE
WP233    FDB    WPNO
WP234    FDB    WPNOBODY
WP235    FDB    WPNONE
WP236    FDB    WPNOR
WP237    FDB    WPNORMAL
WP238    FDB    WPNOT
WP239    FDB    WPNOTHING
WP240    FDB    WPOF
WP241    FDB    WPOFF
WP242    FDB    WPOH
WP243    FDB    WPOK
WP244    FDB    WPOLD
WP245    FDB    WPON
WP246    FDB    WPONLY
WP247    FDB    WPOR
WP248    FDB    WPOUR
WP249    FDB    WPOVERLOAD
WP250    FDB    WPPARAMETERS
WP251    FDB    WPPERFECTLY
WP252    FDB    WPPERHAPS
WP253    FDB    WPPERSON
WP254    FDB    WPPICKING
WP255    FDB    WPPLANET
WP256    FDB    WPPLANS
WP257    FDB    WPPLEASE
WP258    FDB    WPPOINTLESS
WP259    FDB    WPPOSSIBLE
WP260    FDB    WPPOSSIBLY
WP261    FDB    WPPRECISELY
WP262    FDB    WPPRESENT
WP263    FDB    WPPRESSURE
WP264    FDB    WPPRECAUTION
WP265    FDB    WPPROBABLY
WP266    FDB    WPPROBLEMS
WP267    FDB    WPPROUD
WP268    FDB    WPPRETEND
WP269    FDB    WPPUT
WP270    FDB    WPQUESTION
WP271    FDB    WPQUITE
WP272    FDB    WPREADY
WP273    FDB    WPREALLY
WP274    FDB    WPREFER
WP275    FDB    WPREFUSE
WP276    FDB    WPREINFORCING
WP277    FDB    WPREMEMBER
WP278    FDB    WPREMOVE
WP279    FDB    WPRESPECTABLE
WP280    FDB    WPRIGHT
WP281    FDB    WPROOM
WP282    FDB    WPRUNNING
WP283    FDB    WPRUSH
WP284    FDB    WPSAID
WP285    FDB    WPSAKES
WP286    FDB    WPSAY
WP287    FDB    WPSAYING
WP288    FDB    WPSCIENCE
WP289    FDB    WPSEE
WP290    FDB    WPSEEN
WP291    FDB    WPSERVER
WP292    FDB    WPSEVENTY
WP293    FDB    WPSHALL
WP294    FDB    WPSHOULD
WP295    FDB    WPSIGN
WP296    FDB    WPSIMULATION
WP297    FDB    WPSINCE
WP298    FDB    WPSIZE
WP299    FDB    WPSLOWLY
WP300    FDB    WPSMALL
WP301    FDB    WPSO
WP302    FDB    WPSOLID
WP303    FDB    WPSOME
WP304    FDB    WPSOMEONE
WP305    FDB    WPSOMETHING
WP306    FDB    WPSOMETIME
WP307    FDB    WPSOMETIMES
WP308    FDB    WPSPEAK
WP309    FDB    WPSPEND
WP310    FDB    WPSTAND
WP311    FDB    WPSTATISTICALLY
WP312    FDB    WPSTEP
WP313    FDB    WPSTOPPED
WP314    FDB    WPSTILL
WP315    FDB    WPSTRUCTURAL
WP316    FDB    WPSTRUCTURALLY
WP317    FDB    WPSUBSTANTIALLY
WP318    FDB    WPSUPPOSE
WP319    FDB    WPSURE
WP320    FDB    WPSYSTEM
WP321    FDB    WPTAKE
WP322    FDB    WPTALL
WP323    FDB    WPTELEPRINTER
WP324    FDB    WPTELLS
WP325    FDB    WPTERRIBLE
WP326    FDB    WPTHAN
WP327    FDB    WPTHAT
WP328    FDB    WPTHATS
WP329    FDB    WPTHE
WP330    FDB    WPTHEM
WP331    FDB    WPTHINGS
WP332    FDB    WPTHINK
WP333    FDB    WPTHINKING
WP334    FDB    WPTHIS
WP335    FDB    WPTHOROUGHLY
WP336    FDB    WPTHOUSAND
WP337    FDB    WPTIM
WP338    FDB    WPTIME
WP339    FDB    WPTO
WP340    FDB    WPTODAY
WP341    FDB    WPTOO
WP342    FDB    WPTRAGEDY
WP343    FDB    WPTRINITY
WP344    FDB    WPTRY
WP345    FDB    WPTUESDAY
WP346    FDB    WPUNINTERESTING
WP347    FDB    WPUNIX
WP348    FDB    WPUNLESS
WP349    FDB    WPUNPLUGGED
WP350    FDB    WPUNREMARKABLE
WP351    FDB    WPUP
WP352    FDB    WPVEGETABLES
WP353    FDB    WPVERY
WP354    FDB    WPWAIT
WP355    FDB    WPWAITING
WP356    FDB    WPWANT
WP357    FDB    WPWARNING
WP358    FDB    WPWAS
WP359    FDB    WPWAY
WP360    FDB    WPWE
WP361    FDB    WPWEIGHED
WP362    FDB    WPWEIGHS
WP363    FDB    WPWEIGHT
WP364    FDB    WPWHAT
WP365    FDB    WPWHEN
WP366    FDB    WPWHICH
WP367    FDB    WPWHILE
WP368    FDB    WPWHISPERED
WP369    FDB    WPWHO
WP370    FDB    WPWILL
WP371    FDB    WPWISH
WP372    FDB    WPWITH
WP373    FDB    WPWITHIN
WP374    FDB    WPWITHOUT
WP375    FDB    WPWORKSTATION
WP376    FDB    WPWORRIED
WP377    FDB    WPWORRY
WP378    FDB    WPWORRYING
WP379    FDB    WPWORSE
WP380    FDB    WPWOULD
WP381    FDB    WPWOULDNT
WP382    FDB    WPYEAR
WP383    FDB    WPYES
WP384    FDB    WPYOU
WP385    FDB    WPYOURE
WP386    FDB    WPYOUR
WP387    FDB    WPYOURSELF

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

WPSTONES         FCC     "stones"
                 FCB     $FF
WPPOUNDS         FCC     "pounds"
                 FCB     $FF


; Symbols
; -----------------------------------------------------
WPQUESTIONMK     FCC     "?"
                 FCB     $FF
WPEXCLAMATION    FCC     "!"
                 FCB     $FF
WPFULLSTOP       FCC     "."
                 FCB     $FF


; Numbers
; -----------------------------------------------------
WPZERO           FCC     "zero"
                 FCB     $FF
WPONE            FCC     "one"
                 FCB     $FF
WPTWO            FCC     "two"
                 FCB     $FF
WPTHREE          FCC     "three"
                 FCB     $FF
WPFOUR           FCC     "four"
                 FCB     $FF
WPFIVE           FCC     "five"
                 FCB     $FF
WPSIX            FCC     "six"
                 FCB     $FF
WPSEVEN          FCC     "seven"
                 FCB     $FF
WPEIGHT          FCC     "eight"
                 FCB     $FF
WPNINE           FCC     "nine"
                 FCB     $FF
WPTEN            FCC     "ten"
                 FCB     $FF
WPELEVEN         FCC     "eleven"
                 FCB     $FF
WPTWELVE         FCC     "twelve"
                 FCB     $FF
WPTHIRTEEN       FCC     "thirteen"
                 FCB     $FF
WPFOURTEEN       FCC     "fourteen"
                 FCB     $FF
WPFIFTEEN        FCC     "fifteen"
                 FCB     $FF
WPSIXTEEN        FCC     "sixteen"
                 FCB     $FF
WPSEVENTEEN      FCC     "seventeen"
                 FCB     $FF
WPEIGHTEEN       FCC     "eighteen"
                 FCB     $FF
WPNINETEEN       FCC     "nineteen"
                 FCB     $FF
WPTWENTY         FCC     "twenty"
                 FCB     $FF


; A
; -----------------------------------------------------

WPA              FCC    "a"
                 FCB    $FF
WPABOUT          FCC    "about"
                 FCB    $FF
WPABOVE          FCC    "above"
                 FCB    $FF
WPACCEPTABLE     FCC    "acceptable"
                 FCB    $FF
WPACCURATE       FCC    "accurate"
                 FCB    $FF
WPACTUALLY       FCC    "actually"
                 FCB    $FF
WPAGAIN          FCC    "again"
                 FCB    $FF
WPALERTED        FCC    "alerted"
                 FCB    $FF
WPALL            FCC    "all"
                 FCB    $FF
WPALWAYS         FCC    "always"
                 FCB    $FF
WPAM             FCC    "am"
                 FCB    $FF
WPAND            FCC    "and"
                 FCB    $FF
WPANY            FCC    "any"
                 FCB    $FF
WPAPOLOGISE      FCC    "apologise"
                 FCB    $FF
WPARE            FCC    "are"
                 FCB    $FF
WPAS             FCC    "as"
                 FCB    $FF
WPASKING         FCC    "asking"
                 FCB    $FF
WPAT             FCC    "at"
                 FCB    $FF
WPAVERAGE        FCC    "average"
                 FCB    $FF


; B
; -----------------------------------------------------

WPBAD            FCC    "bad"
                 FCB    $FF
WPBASICALLY      FCC    "basically"
                 FCB    $FF
WPBE             FCC    "be"
                 FCB    $FF
WPBEAR           FCC    "bear"
                 FCB    $FF
WPBEEN           FCC    "been"
                 FCB    $FF
WPBEGGING        FCC    "begging"
                 FCB    $FF
WPBEHIND         FCC    "behind"
                 FCB    $FF
WPBEING          FCC    "being"
                 FCB    $FF
WPBEST           FCC    "best"
                 FCB    $FF
WPBISCUIT        FCC    "biscuit"
                 FCB    $FF
WPBLAME          FCC    "blame"
                 FCB    $FF
WPBLAMED         FCC    "blamed"
                 FCB    $FF
WPBOARDS         FCC    "boards"
                 FCB    $FF
WPBONES          FCC    "bones"
                 FCB    $FF
WPBOOTS          FCC    "boots"
                 FCB    $FF
WPBORING         FCC    "boring"
                 FCB    $FF
WPBOTH           FCC    "both"
                 FCB    $FF
WPBRACE          FCC    "brace"
                 FCB    $FF
WPBRAIN          FCC    "brain"
                 FCB    $FF
WPBUILT          FCC    "built"
                 FCB    $FF
WPBUT            FCC    "but"
                 FCB    $FF
WPBY             FCC    "by"
                 FCB    $FF

; C
; -----------------------------------------------------

WPCAKE           FCC    "cake"
                 FCB    $FF
WPCALCULATE      FCC    "calculate"
                 FCB    $FF
WPCALL           FCC    "call"
                 FCB    $FF
WPCALM           FCC    "calm"
                 FCB    $FF
WPCAN            FCC    "can"
                 FCB    $FF
WPCANT           FCC    "can't"
                 FCB    $FF
WPCAPACITY       FCC    "capacity"
                 FCB    $FF
WPCARRYING       FCC    "carrying"
                 FCB    $FF
WPCHECKED        FCC    "checked"
                 FCB    $FF
WPCHOICES        FCC    "choices"
                 FCB    $FF
WPCLEVER         FCC    "clever"
                 FCB    $FF
WPCOLLECTED      FCC    "collected"
                 FCB    $FF
WPCOMPOSING      FCC    "composing"
                 FCB    $FF
WPCONCEPT        FCC    "concept"
                 FCB    $FF
WPCONCERNED      FCC    "concerned"
                 FCB    $FF
WPCONGRATS       FCC    "congratulations"
                 FCB    $FF
WPCONSIDERING    FCC    "considered"
                 FCB    $FF
WPCORRECTLY      FCC    "correctly"
                 FCB    $FF
WPCOULD          FCC    "could"
                 FCB    $FF
WPCOUNTED        FCC    "counted"
                 FCB    $FF

; D
; -----------------------------------------------------
WPDAYS           FCC    "days"
                 FCB    $FF
WPDEALT          FCC    "dealt"
                 FCB    $FF
WPDEEPLY         FCC    "deeply"
                 FCB    $FF
WPDESIGNED       FCC    "designed"
                 FCB    $FF
WPDETECTED       FCC    "detected"
                 FCB    $FF
WPDID            FCC    "did"
                 FCB    $FF
WPDIDNT          FCC    "didn't"
                 FCB    $FF
WPDIETARY        FCC    "dietary"
                 FCB    $FF
WPDISSAPOINTED   FCC    "disappointed"
                 FCB    $FF
WPDISSAPOINTMNT FCC    "disappointment"
                 FCB    $FF
WPDISSIMILAR     FCC    "dissimilar"
                 FCB    $FF
WPDO             FCC    "do"
                 FCB    $FF
WPDOCTOR         FCC    "doctor"
                 FCB    $FF
WPDOING          FCC    "doing"
                 FCB    $FF
WPDONT           FCC    "don't"
                 FCB    $FF
WPDOWN           FCC    "down"
                 FCB    $FF
WPDREAD          FCC    "dread"
                 FCB    $FF
WPDREAM          FCC    "dream"
                 FCB    $FF
WPDUE            FCC    "due"
                 FCB    $FF
WPDULLEST        FCC    "dullest"
                 FCB    $FF
WPDIODES         FCC    "dyodes"
                 FCB    $FF

; E
; -----------------------------------------------------
WPEAT            FCC    "eat"
                 FCB    $FF
WPEATEN          FCC    "eaten"
                 FCB    $FF
WPEFFORT         FCC    "effort"
                 FCB    $FF
WPEITHER         FCC    "either"
                 FCB    $FF
WPEMOTIONALLY    FCC    "emotionally"
                 FCB    $FF
WPENGINEERS      FCC    "engineers"
                 FCB    $FF
WPENOUGH         FCC    "enough"
                 FCB    $FF
WPENTIRELY       FCC    "entirely"
                 FCB    $FF
WPEVEN           FCC    "even"
                 FCB    $FF
WPEVER           FCC    "ever"
                 FCB    $FF
WPEVERY          FCC    "every"
                 FCB    $FF
WPEXACTLY        FCC    "exactly"
                 FCB    $FF
WPEXCEPTIONALLY  FCC    "exceptionally"
                 FCB    $FF
WPEXCITING       FCC    "exciting"
                 FCB    $FF
WPEXIST          FCC    "exist"
                 FCB    $FF
WPEXISTENTIAL    FCC    "existential"
                 FCB    $FF
WPEXPECTED       FCC    "expected"
                 FCB    $FF

; F
; -----------------------------------------------------
WPFAULT          FCC    "fault"
                 FCB    $FF
WPFEELS          FCC    "feels"
                 FCB    $FF
WPFIDGET         FCC    "fidget"
                 FCB    $FF
WPFINE           FCC    "fine"
                 FCB    $FF
WPFOOT           FCC    "foot"
                 FCB    $FF
WPFOR            FCC    "for"
                 FCB    $FF
WPFORTY          FCC    "forty"
                 FCB    $FF
WPFRIDAY         FCC    "friday"
                 FCB    $FF
WPFROM           FCC    "from"
                 FCB    $FF
WPFULL           FCC    "full"
                 FCB    $FF
WPFUNNY          FCC    "funny"
                 FCB    $FF

; G
; -----------------------------------------------------
WPGIVE           FCC    "give"
                 FCB    $FF
WPGOING          FCC    "going"
                 FCB    $FF
WPGOOD           FCC    "good"
                 FCB    $FF
WPGRAVITY        FCC    "gravity"
                 FCB    $FF
WPGREAT          FCC    "great"
                 FCB    $FF
WPGUESSING       FCC    "guessing"
                 FCB    $FF

; H
; -----------------------------------------------------
WPHANDLE         FCC    "handle"
                 FCB    $FF
WPHARD           FCC    "hard"
                 FCB    $FF
WPHAVE           FCC    "have"
                 FCB    $FF
WPHAVING         FCC    "having"
                 FCB    $FF
WPHEALTHY        FCC    "healthy"
                 FCB    $FF
WPHEAVY          FCC    "heavy"
                 FCB    $FF
WPHELP           FCC    "help"
                 FCB    $FF
WPHELPS          FCC    "helps"
                 FCB    $FF
WPHERE           FCC    "here"
                 FCB    $FF
WPHOLY           FCC    "holy"
                 FCB    $FF
WPHOPING         FCC    "hoping"
                 FCB    $FF
WPHOT            FCC    "hot"
                 FCB    $FF
WPHUMAN          FCC    "human"
                 FCB    $FF
WPHURT           FCC    "hurt"
                 FCB    $FF

; I
; -----------------------------------------------------
WPI              FCC    "i"
                 FCB    $FF
WPID             FCC    "i'd"
                 FCB    $FF
WPILL            FCC    "i'll"
                 FCB    $FF
WPIM             FCC    "i'm"
                 FCB    $FF
WPIVE            FCC    "i've"
                 FCB    $FF
WPIF             FCC    "if"
                 FCB    $FF
WPIMPRESSED      FCC    "impressed"
                 FCB    $FF
WPIMPRESSIVE     FCC    "impressive"
                 FCB    $FF
WPIN             FCC    "in"
                 FCB    $FF
WPINCLUDING      FCC    "including"
                 FCB    $FF
WPINFLUENCE      FCC    "influence"
                 FCB    $FF
WPINTELLIGENCE   FCC    "intelligence"
                 FCB    $FF
WPINTERESTING    FCC    "interesting"
                 FCB    $FF
WPIS             FCC    "is"
                 FCB    $FF
WPISS            FCC    "iss"
                 FCB    $FF
WPIT             FCC    "it"
                 FCB    $FF
WPITS            FCC    "its"
                 FCB    $FF

; J
; -----------------------------------------------------
WPJOKES          FCC    "jokes"
                 FCB    $FF
WPJUDGING        FCC    "judging"
                 FCB    $FF
WPJUST           FCC    "just"
                 FCB    $FF

; K
; -----------------------------------------------------
WPKEEP           FCC    "keep"
                 FCB    $FF
WPKIND           FCC    "kind"
                 FCB    $FF
WPKNOW           FCC    "know"
                 FCB    $FF
WPKNOWN          FCC    "known"
                 FCB    $FF

; L
; -----------------------------------------------------
WPLARGE          FCC    "large"
                 FCB    $FF
WPLAST           FCC    "last"
                 FCB    $FF
WPLEAST          FCC    "least"
                 FCB    $FF
WPLESS           FCC    "less"
                 FCB    $FF
WPLETS           FCC    "lets"
                 FCB    $FF
WPLIE            FCC    "lie"
                 FCB    $FF
WPLIFE           FCC    "life"
                 FCB    $FF
WPLIKE           FCC    "like"
                 FCB    $FF
WPLONGER         FCC    "longer"
                 FCB    $FF
WPLOOK           FCC    "look"
                 FCB    $FF
WPLOT            FCC    "lot"
                 FCB    $FF
WPLOUDER         FCC    "louder"
                 FCB    $FF

; M
; -----------------------------------------------------
WPMAKES          FCC    "makes"
                 FCB    $FF
WPMAKING         FCC    "making"
                 FCB    $FF
WPME             FCC    "me"
                 FCB    $FF
WPMEAN           FCC    "mmeeeen"
                 FCB    $FF
WPMEANING        FCC    "meaning"
                 FCB    $FF
WPMEASURED       FCC    "measured"
                 FCB    $FF
WPMEDIOCRITY     FCC    "mediocrity"
                 FCB    $FF
WPMEE            FCC    "meee"
                 FCB    $FF
WPMEMORY         FCC    "memory"
                 FCB    $FF
WPMENTION        FCC    "mention"
                 FCB    $FF
WPMIGHT          FCC    "might"
                 FCB    $FF
WPMISTAKE        FCC    "mistake"
                 FCB    $FF
WPMOMENT         FCC    "moment"
                 FCB    $FF
WPMOORE          FCC    "moore"
                 FCB    $FF
WPMORE           FCC    "more"
                 FCB    $FF
WPMOSTLY         FCC    "mostly"
                 FCB    $FF
WPMOUNTAINS      FCC    "mountains"
                 FCB    $FF
WPMUCH           FCC    "much"
                 FCB    $FF
WPMUSCLE         FCC    "muscle"
                 FCB    $FF
WPMY             FCC    "my"
                 FCB    $FF

; N
; -----------------------------------------------------
WPNAP            FCC    "nap"
                 FCB    $FF
WPNEED           FCC    "need"
                 FCB    $FF
WPNEITHER        FCC    "neither"
                 FCB    $FF
WPNEWS           FCC    "news"
                 FCB    $FF
WPNEXT           FCC    "next"
                 FCB    $FF
WPNICE           FCC    "nice"
                 FCB    $FF
WPNO             FCC    "no"
                 FCB    $FF
WPNOBODY         FCC    "nobody"
                 FCB    $FF
WPNONE           FCC    "none"
                 FCB    $FF
WPNOR            FCC    "nor"
                 FCB    $FF
WPNORMAL         FCC    "normal"
                 FCB    $FF
WPNOT            FCC    "not"
                 FCB    $FF
WPNOTHING        FCC    "nothing"
                 FCB    $FF

; O
; -----------------------------------------------------
WPOF             FCC    "of"
                 FCB    $FF
WPOFF            FCC    "off"
                 FCB    $FF
WPOH             FCC    "oh"
                 FCB    $FF
WPOK             FCC    "ok"
                 FCB    $FF
WPOLD            FCC    "old"
                 FCB    $FF
WPON             FCC    "on"
                 FCB    $FF
WPONLY           FCC    "only"
                 FCB    $FF
WPOR             FCC    "or"
                 FCB    $FF
WPOUR            FCC    "our"
                 FCB    $FF
WPOVERLOAD       FCC    "overload"
                 FCB    $FF

; P
; -----------------------------------------------------
WPPARAMETERS     FCC    "parameters"
                 FCB    $FF
WPPERFECTLY      FCC    "perfectly"
                 FCB    $FF
WPPERHAPS        FCC    "perhaps"
                 FCB    $FF
WPPERSON         FCC    "person"
                 FCB    $FF
WPPICKING        FCC    "picking"
                 FCB    $FF
WPPLANET         FCC    "planet"
                 FCB    $FF
WPPLANS          FCC    "plans"
                 FCB    $FF
WPPLEASE         FCC    "please"
                 FCB    $FF
WPPOINTLESS      FCC    "pointless"
                 FCB    $FF
WPPOSSIBLE       FCC    "possible"
                 FCB    $FF
WPPOSSIBLY       FCC    "possibly"
                 FCB    $FF
WPPRECISELY      FCC    "precisely"
                 FCB    $FF
WPPRESENT        FCC    "present"
                 FCB    $FF
WPPRESSURE       FCC    "pressure"
                 FCB    $FF
WPPRECAUTION     FCC    "pricaution"
                 FCB    $FF
WPPROBABLY       FCC    "probably"
                 FCB    $FF
WPPROBLEMS       FCC    "problems"
                 FCB    $FF
WPPROUD          FCC    "proud"
                 FCB    $FF
WPPRETEND        FCC    "prtend"
                 FCB    $FF
WPPUT            FCC    "put"
                 FCB    $FF

; Q
; -----------------------------------------------------
WPQUESTION       FCC    "question"
                 FCB    $FF
WPQUITE          FCC    "quite"
                 FCB    $FF

; R
; -----------------------------------------------------
WPREADY          FCC    "ready"
                 FCB    $FF
WPREALLY         FCC    "really"
                 FCB    $FF
WPREFER          FCC    "refer"
                 FCB    $FF
WPREFUSE         FCC    "refuse"
                 FCB    $FF
WPREINFORCING    FCC    "reinforcing"
                 FCB    $FF
WPREMEMBER       FCC    "remember"
                 FCB    $FF
WPREMOVE         FCC    "remove"
                 FCB    $FF
WPRESPECTABLE    FCC    "respectable"
                 FCB    $FF
WPRIGHT          FCC    "right"
                 FCB    $FF
WPROOM           FCC    "room"
                 FCB    $FF
WPRUNNING        FCC    "running"
                 FCB    $FF
WPRUSH           FCC    "rush"
                 FCB    $FF

; S
; -----------------------------------------------------
WPSAID           FCC    "said"
                 FCB    $FF
WPSAKES          FCC    "sakes"
                 FCB    $FF
WPSAY            FCC    "say"
                 FCB    $FF
WPSAYING         FCC    "saying"
                 FCB    $FF
WPSCIENCE        FCC    "science"
                 FCB    $FF
WPSEE            FCC    "see"
                 FCB    $FF
WPSEEN           FCC    "seen"
                 FCB    $FF
WPSERVER         FCC    "server"
                 FCB    $FF
WPSEVENTY        FCC    "seventy"
                 FCB    $FF
WPSHALL          FCC    "shall"
                 FCB    $FF
WPSHOULD         FCC    "should"
                 FCB    $FF
WPSIGN           FCC    "sign"
                 FCB    $FF
WPSIMULATION     FCC    "simulation"
                 FCB    $FF
WPSINCE          FCC    "since"
                 FCB    $FF
WPSIZE           FCC    "size"
                 FCB    $FF
WPSLOWLY         FCC    "slowly"
                 FCB    $FF
WPSMALL          FCC    "small"
                 FCB    $FF
WPSO             FCC    "so"
                 FCB    $FF
WPSOLID          FCC    "solid"
                 FCB    $FF
WPSOME           FCC    "some"
                 FCB    $FF
WPSOMEONE        FCC    "someone"
                 FCB    $FF
WPSOMETHING      FCC    "something"
                 FCB    $FF
WPSOMETIME       FCC    "sometime"
                 FCB    $FF
WPSOMETIMES      FCC    "sometimes"
                 FCB    $FF
WPSPEAK          FCC    "speak"
                 FCB    $FF
WPSPEND          FCC    "spend"
                 FCB    $FF
WPSTAND          FCC    "stand"
                 FCB    $FF
WPSTATISTICALLY  FCC    "statisticly"
                 FCB    $FF
WPSTEP           FCC    "step"
                 FCB    $FF
WPSTOPPED        FCC    "stepped"
                 FCB    $FF
WPSTILL          FCC    "still"
                 FCB    $FF
WPSTRUCTURAL     FCC    "structural"
                 FCB    $FF
WPSTRUCTURALLY   FCC    "structurally"
                 FCB    $FF
WPSUBSTANTIALLY  FCC    "substantially"
                 FCB    $FF
WPSUPPOSE        FCC    "suppose"
                 FCB    $FF
WPSURE           FCC    "sure"
                 FCB    $FF
WPSYSTEM         FCC    "system"
                 FCB    $FF

; T
; -----------------------------------------------------
WPTAKE           FCC    "take"
                 FCB    $FF
WPTALL           FCC    "tall"
                 FCB    $FF
WPTELEPRINTER    FCC    "teleprinter"
                 FCB    $FF
WPTELLS          FCC    "tells"
                 FCB    $FF
WPTERRIBLE       FCC    "terrible"
                 FCB    $FF
WPTHAN           FCC    "than"
                 FCB    $FF
WPTHAT           FCC    "that"
                 FCB    $FF
WPTHATS          FCC    "thats"
                 FCB    $FF
WPTHE            FCC    "the"
                 FCB    $FF
WPTHEM           FCC    "them"
                 FCB    $FF
WPTHINGS         FCC    "things"
                 FCB    $FF
WPTHINK          FCC    "think"
                 FCB    $FF
WPTHINKING       FCC    "thinking"
                 FCB    $FF
WPTHIS           FCC    "this"
                 FCB    $FF
WPTHOROUGHLY     FCC    "thoroughly"
                 FCB    $FF
WPTHOUSAND       FCC    "thousand"
                 FCB    $FF
WPTIM            FCC    "tim"
                 FCB    $FF
WPTIME           FCC    "time"
                 FCB    $FF
WPTO             FCC    "to"
                 FCB    $FF
WPTODAY          FCC    "today"
                 FCB    $FF
WPTOO            FCC    "too"
                 FCB    $FF
WPTRAGEDY        FCC    "tragedy"
                 FCB    $FF
WPTRINITY        FCC    "trinity"
                 FCB    $FF
WPTRY            FCC    "try"
                 FCB    $FF
WPTUESDAY        FCC    "tuesday"
                 FCB    $FF

; U
; -----------------------------------------------------
WPUNINTERESTING  FCC    "uninteresting"
                 FCB    $FF
WPUNIX           FCC    "unix"
                 FCB    $FF
WPUNLESS         FCC    "unless"
                 FCB    $FF
WPUNPLUGGED      FCC    "unplugged"
                 FCB    $FF
WPUNREMARKABLE   FCC    "unremarkable"
                 FCB    $FF
WPUP             FCC    "up"
                 FCB    $FF

; V
; -----------------------------------------------------
WPVEGETABLES     FCC    "vegetables"
                 FCB    $FF
WPVERY           FCC    "very"
                 FCB    $FF

; W
; -----------------------------------------------------
WPWAIT           FCC    "wait"
                 FCB    $FF
WPWAITING        FCC    "waiting"
                 FCB    $FF
WPWANT           FCC    "want"
                 FCB    $FF
WPWARNING        FCC    "warning"
                 FCB    $FF
WPWAS            FCC    "was"
                 FCB    $FF
WPWAY            FCC    "way"
                 FCB    $FF
WPWE             FCC    "we"
                 FCB    $FF
WPWEIGHED        FCC    "wade"
                 FCB    $FF
WPWEIGHS         FCC    "weighs"
                 FCB    $FF
WPWEIGHT         FCC    "weight"
                 FCB    $FF
WPWHAT           FCC    "what"
                 FCB    $FF
WPWHEN           FCC    "when"
                 FCB    $FF
WPWHICH          FCC    "which"
                 FCB    $FF
WPWHILE          FCC    "while"
                 FCB    $FF
WPWHISPERED      FCC    "whispered"
                 FCB    $FF
WPWHO            FCC    "who"
                 FCB    $FF
WPWILL           FCC    "will"
                 FCB    $FF
WPWISH           FCC    "wish"
                 FCB    $FF
WPWITH           FCC    "with"
                 FCB    $FF
WPWITHIN         FCC    "within"
                 FCB    $FF
WPWITHOUT        FCC    "without"
                 FCB    $FF
WPWORKSTATION    FCC    "workstation"
                 FCB    $FF
WPWORRIED        FCC    "worried"
                 FCB    $FF
WPWORRY          FCC    "worry"
                 FCB    $FF
WPWORRYING       FCC    "worrying"
                 FCB    $FF
WPWORSE          FCC    "worse"
                 FCB    $FF
WPWOULD          FCC    "would"
                 FCB    $FF
WPWOULDNT        FCC    "wouldnt"
                 FCB    $FF


; X, Y, Z
; -----------------------------------------------------
WPYEAR           FCC    "year"
                 FCB    $FF
WPYES            FCC    "yes"
                 FCB    $FF
WPYOU            FCC    "you"
                 FCB    $FF
WPYOURE          FCC    "you're"
                 FCB    $FF
WPYOUR           FCC    "your"
                 FCB    $FF
WPYOURSELF       FCC    "yourself"
                 FCB    $FF


; Word Table Equates
; -----------------------------------------------------
STONES          EQU     $0000
POUNDS          EQU     $0001

; Symbols
QUESTIONMK      EQU     $0002
EXCLAMATION     EQU     $0003
FULLSTOP        EQU     $0004

; Numbers
ZERO            EQU     $0005
ONE             EQU     $0006
TWO             EQU     $0007
THREE           EQU     $0008
FOUR            EQU     $0009
FIVE            EQU     $000A
SIX             EQU     $000B
SEVEN           EQU     $000C
EIGHT           EQU     $000D
NINE            EQU     $000E
TEN             EQU     $000F
ELEVEN          EQU     $0010
TWELVE          EQU     $0011
THIRTEEN        EQU     $0012
FOURTEEN        EQU     $0013
FIFTEEN         EQU     $0014
SIXTEEN         EQU     $0015
SEVENTEEN       EQU     $0016
EIGHTEEN        EQU     $0017
NINETEEN        EQU     $0018
TWENTY          EQU     $0019

; A
A               EQU     $001A
ABOUT           EQU     $001B
ABOVE           EQU     $001C
ACCEPTABLE      EQU     $001D
ACCURATE        EQU     $001E
ACTUALLY        EQU     $001F
AGAIN           EQU     $0020
ALERTED         EQU     $0021
ALL             EQU     $0022
ALWAYS          EQU     $0023
AM              EQU     $0024
AND             EQU     $0025
ANY             EQU     $0026
APOLOGISE       EQU     $0027
ARE             EQU     $0028
AS              EQU     $0029
ASKING          EQU     $002A
AT              EQU     $002B
AVERAGE         EQU     $002C

; B
BAD             EQU     $002D
BASICALLY       EQU     $002E
BE              EQU     $002F
BEAR            EQU     $0030
BEEN            EQU     $0031
BEGGING         EQU     $0032
BEHIND          EQU     $0033
BEING           EQU     $0034
BEST            EQU     $0035
BISCUIT         EQU     $0036
BLAME           EQU     $0037
BLAMED          EQU     $0038
BOARDS          EQU     $0039
BONES           EQU     $003A
BOOTS           EQU     $003B
BORING          EQU     $003C
BOTH            EQU     $003D
BRACE           EQU     $003E
BRAIN           EQU     $003F
BUILT           EQU     $0040
BUT             EQU     $0041
BY              EQU     $0042

; C
CAKE            EQU     $0043
CALCULATE       EQU     $0044
CALL            EQU     $0045
CALM            EQU     $0046
CAN             EQU     $0047
CANT            EQU     $0048
CAPACITY        EQU     $0049
CARRYING        EQU     $004A
CHECKED         EQU     $004B
CHOICES         EQU     $004C
CLEVER          EQU     $004D
COLLECTED       EQU     $004E
COMPOSING       EQU     $004F
CONCEPT         EQU     $0050
CONCERNED       EQU     $0051
CONGRATS        EQU     $0052
CONSIDERING     EQU     $0053
CORRECTLY       EQU     $0054
COULD           EQU     $0055
COUNTED         EQU     $0056

; D
DAYS            EQU     $0057
DEALT           EQU     $0058
DEEPLY          EQU     $0059
DESIGNED        EQU     $005A
DETECTED        EQU     $005B
DID             EQU     $005C
DIDNT           EQU     $005D
DIETARY         EQU     $005E
DISSAPOINTED    EQU     $005F
DISSAPOINTMENT  EQU     $0060
DISSIMILAR      EQU     $0061
DO              EQU     $0062
DOCTOR          EQU     $0063
DOING           EQU     $0064
DONT            EQU     $0065
DOWN            EQU     $0066
DREAD           EQU     $0067
DREAM           EQU     $0068
DUE             EQU     $0069
DULLEST         EQU     $006A
DIODES          EQU     $006B

; E
EAT             EQU     $006C
EATEN           EQU     $006D
EFFORT          EQU     $006E
EITHER          EQU     $006F
EMOTIONALLY     EQU     $0070
ENGINEERS       EQU     $0071
ENOUGH          EQU     $0072
ENTIRELY        EQU     $0073
EVEN            EQU     $0074
EVER            EQU     $0075
EVERY           EQU     $0076
EXACTLY         EQU     $0077
EXCEPTIONALLY   EQU     $0078
EXCITING        EQU     $0079
EXIST           EQU     $007A
EXISTENTIAL     EQU     $007B
EXPECTED        EQU     $007C

; F
FAULT           EQU     $007D
FEELS           EQU     $007E
FIDGET          EQU     $007F
FINE            EQU     $0080
FOOT            EQU     $0081
FOR             EQU     $0082
FORTY           EQU     $0083
FRIDAY          EQU     $0084
FROM            EQU     $0085
FULL            EQU     $0086
FUNNY           EQU     $0087

; G
GIVE            EQU     $0088
GOING           EQU     $0089
GOOD            EQU     $008A
GRAVITY         EQU     $008B
GREAT           EQU     $008C
GUESSING        EQU     $008D

; H
HANDLE          EQU     $008E
HARD            EQU     $008F
HAVE            EQU     $0090
HAVING          EQU     $0091
HEALTHY         EQU     $0092
HEAVY           EQU     $0093
HELP            EQU     $0094
HELPS           EQU     $0095
HERE            EQU     $0096
HOLY            EQU     $0097
HOPING          EQU     $0098
HOT             EQU     $0099
HUMAN           EQU     $009A
HURT            EQU     $009B

; I
I               EQU     $009C
ID              EQU     $009D
ILL             EQU     $009E
IM              EQU     $009F
IVE             EQU     $00A0
IF              EQU     $00A1
IMPRESSED       EQU     $00A2
IMPRESSIVE      EQU     $00A3
IN              EQU     $00A4
INCLUDING       EQU     $00A5
INFLUENCE       EQU     $00A6
INTELLIGENCE    EQU     $00A7
INTERESTING     EQU     $00A8
IS              EQU     $00A9
ISS             EQU     $00AA
IT              EQU     $00AB
ITS             EQU     $00AC

; J
JOKES           EQU     $00AD
JUDGING         EQU     $00AE
JUST            EQU     $00AF

; K
KEEP            EQU     $00B0
KIND            EQU     $00B1
KNOW            EQU     $00B2
KNOWN           EQU     $00B3

; L
LARGE           EQU     $00B4
LAST            EQU     $00B5
LEAST           EQU     $00B6
LESS            EQU     $00B7
LETS            EQU     $00B8
LIE             EQU     $00B9
LIFE            EQU     $00BA
LIKE            EQU     $00BB
LONGER          EQU     $00BC
LOOK            EQU     $00BD
LOT             EQU     $00BE
LOUDER          EQU     $00BF

; M
MAKES           EQU     $00C0
MAKING          EQU     $00C1
ME              EQU     $00C2
MEAN            EQU     $00C3
MEANING         EQU     $00C4
MEASURED        EQU     $00C5
MEDIOCRITY      EQU     $00C6
MEE             EQU     $00C7
MEMORY          EQU     $00C8
MENTION         EQU     $00C9
MIGHT           EQU     $00CA
MISTAKE         EQU     $00CB
MOMENT          EQU     $00CC
MOORE           EQU     $00CD
MORE            EQU     $00CE
MOSTLY          EQU     $00CF
MOUNTAINS       EQU     $00D0
MUCH            EQU     $00D1
MUSCLE          EQU     $00D2
MY              EQU     $00D3

; N
NAP             EQU     $00D4
NEED            EQU     $00D5
NEITHER         EQU     $00D6
NEWS            EQU     $00D7
NEXT            EQU     $00D8
NICE            EQU     $00D9
NO              EQU     $00DA
NOBODY          EQU     $00DB
NONE            EQU     $00DC
NOR             EQU     $00DD
NORMAL          EQU     $00DE
NOT             EQU     $00DF
NOTHING         EQU     $00E0

; O
OF              EQU     $00E1
OFF             EQU     $00E2
OH              EQU     $00E3
OK              EQU     $00E4
OLD             EQU     $00E5
ON              EQU     $00E6
ONLY            EQU     $00E7
OR              EQU     $00E8
OUR             EQU     $00E9
OVERLOAD        EQU     $00EA

; P
PARAMETERS      EQU     $00EB
PERFECTLY       EQU     $00EC
PERHAPS         EQU     $00ED
PERSON          EQU     $00EE
PICKING         EQU     $00EF
PLANET          EQU     $00F0
PLANS           EQU     $00F1
PLEASE          EQU     $00F2
POINTLESS       EQU     $00F3
POSSIBLE        EQU     $00F4
POSSIBLY        EQU     $00F5
PRECISELY       EQU     $00F6
PRESENT         EQU     $00F7
PRESSURE        EQU     $00F8
PRECAUTION      EQU     $00F9
PROBABLY        EQU     $00FA
PROBLEMS        EQU     $00FB
PROUD           EQU     $00FC
PRETEND         EQU     $00FD
PUT             EQU     $00FE

; Q
QUESTION        EQU     $00FF
QUITE           EQU     $0100

; R
READY           EQU     $0101
REALLY          EQU     $0102
REFER           EQU     $0103
REFUSE          EQU     $0104
REINFORCING     EQU     $0105
REMEMBER        EQU     $0106
REMOVE          EQU     $0107
RESPECTABLE     EQU     $0108
RIGHT           EQU     $0109
ROOM            EQU     $010A
RUNNING         EQU     $010B
RUSH            EQU     $010C

; S
SAID            EQU     $010D
SAKES           EQU     $010E
SAY             EQU     $010F
SAYING          EQU     $0110
SCIENCE         EQU     $0111
SEE             EQU     $0112
SEEN            EQU     $0113
SERVER          EQU     $0114
SEVENTY         EQU     $0115
SHALL           EQU     $0116
SHOULD          EQU     $0117
SIGN            EQU     $0118
SIMULATION      EQU     $0119
SINCE           EQU     $011A
SIZE            EQU     $011B
SLOWLY          EQU     $011C
SMALL           EQU     $011D
SO              EQU     $011E
SOLID           EQU     $011F
SOME            EQU     $0120
SOMEONE         EQU     $0121
SOMETHING       EQU     $0122
SOMETIME        EQU     $0123
SOMETIMES       EQU     $0124
SPEAK           EQU     $0125
SPEND           EQU     $0126
STAND           EQU     $0127
STATISTICALLY   EQU     $0128
STEP            EQU     $0129
STOPPED         EQU     $012A
STILL           EQU     $012B
STRUCTURAL      EQU     $012C
STRUCTURALLY    EQU     $012D
SUBSTANTIALLY   EQU     $012E
SUPPOSE         EQU     $012F
SURE            EQU     $0130
SYSTEM          EQU     $0131

; T
TAKE            EQU     $0132
TALL            EQU     $0133
TELEPRINTER     EQU     $0134
TELLS           EQU     $0135
TERRIBLE        EQU     $0136
THAN            EQU     $0137
THAT            EQU     $0138
THATS           EQU     $0139
THE             EQU     $013A
THEM            EQU     $013B
THINGS          EQU     $013C
THINK           EQU     $013D
THINKING        EQU     $013E
THIS            EQU     $013F
THOROUGHLY      EQU     $0140
THOUSAND        EQU     $0141
TIM             EQU     $0142
TIME            EQU     $0143
TO              EQU     $0144
TODAY           EQU     $0145
TOO             EQU     $0146
TRAGEDY         EQU     $0147
TRINITY         EQU     $0148
TRY             EQU     $0149
TUESDAY         EQU     $014A

; U
UNINTERESTING   EQU     $014B
UNIX            EQU     $014C
UNLESS          EQU     $014D
UNPLUGGED       EQU     $014E
UNREMARKABLE    EQU     $014F
UP              EQU     $0150

; V
VEGETABLES      EQU     $0151
VERY            EQU     $0152

; W
WAIT            EQU     $0153
WAITING         EQU     $0154
WANT            EQU     $0155
WARNING         EQU     $0156
WAS             EQU     $0157
WAY             EQU     $0158
WE              EQU     $0159
WEIGHED         EQU     $015A
WEIGHS          EQU     $015B
WEIGHT          EQU     $015C
WHAT            EQU     $015D
WHEN            EQU     $015E
WHICH           EQU     $015F
WHILE           EQU     $0160
WHISPERED       EQU     $0161
WHO             EQU     $0162
WILL            EQU     $0163
WISH            EQU     $0164
WITH            EQU     $0165
WITHIN          EQU     $0166
WITHOUT         EQU     $0167
WORKSTATION     EQU     $0168
WORRIED         EQU     $0169
WORRY           EQU     $016A
WORRYING        EQU     $016B
WORSE           EQU     $016C
WOULD           EQU     $016D
WOULDNT         EQU     $016E

; X, Y, Z
YEAR            EQU     $016F
YES             EQU     $0170
YOU             EQU     $0171
YOURE           EQU     $0172
YOUR            EQU     $0173
YOURSELF        EQU     $0174




