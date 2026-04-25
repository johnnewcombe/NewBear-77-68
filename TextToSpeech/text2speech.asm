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
        JMP     LIGHTW
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

LIGHTW   ; output the light message
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
; TODO See new routine below.

;PR_WORD     INCA    ;
;            LDX     #WORDPTR  ; base of offset table
;PR_WORD1    DECA
;            BEQ     FOUNDW
;            INX                 ; move to next address
;            INX
;            BNE     PR_WORD1    ; loop around to retest
;FOUNDW      LDAA    0,X
;            STAA    T_X
;            LDAA    1,X
;            STAA    T_X+1
;            LDX     T_X
;            JSR     STRINGBX
;            RTS

; -----------------------------------------------------
; Outputs a word based on value in A
; -----------------------------------------------------
; The routine loops through all of the word pointers derementing X as it goes
; When X = 0, then the pointer to the word has been found.
PR_WORD     LDX     #WORDPTR        ; base of pointer table
PR_WORD1    TSTA                    ; is A zero?
            BEQ     FOUNDW          ; yes, use current entry
            INX                     ; advance to next 2-byte entry
            INX
            DECA                    ; decrement index
            BRA     PR_WORD1        ; loop
FOUNDW      LDAA    0,X             ; load high byte of pointer
            STAA    T_X
            LDAA    1,X             ; load low byte of pointer
            STAA    T_X+1
            LDX     T_X             ; load X with the word pointer
            JSR     STRINGBX        ; output the word
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
; Phrase Pointers to the categorised phases
; -----------------------------------------------------
PHRASEPTR

; idle phrase ponters
IDLEPTR

; light weight phrase ponters
LIGHTPTR

; normal weight phrase ponters
NORMALPTR

; heavy weight phrase ponters
HEAVYPTR

; super heavy weight  phrase ponters
SHEAVYPTR

; greeting phrase ponters
GREETTPTR

; error phrase pointer
ERRORTPTR

; overload phrase pointer
OVERLOADTPTR


; -----------------------------------------------------
; Word pointer table (max words 256)
; Set X to the pointer ID and call PR_WORD
; -----------------------------------------------------
; To create new wordk add the word in the correct
; (alphabetical) position in the word table. Then add
; a pointer to that word at the END of the Word Pointer
; table. Finally add an EQUATE using the word as a label
; in the word equates table;
; -----------------------------------------------------

WORDPTR

; Numbers
WP000    FDB    WPZERO
WP001    FDB    WPONE
WP002    FDB    WPTWO
WP003    FDB    WPTHREE
WP004    FDB    WPFOUR
WP005    FDB    WPFIVE
WP006    FDB    WPSIX
WP007    FDB    WPSEVEN
WP008    FDB    WPEIGHT
WP009    FDB    WPNINE
WP010    FDB    WPTEN
WP011    FDB    WPELEVEN
WP012    FDB    WPTWELVE
WP013    FDB    WPTHIRTEEN
WP014    FDB    WPFOURTEEN
WP015    FDB    WPFIFTEEN
WP016    FDB    WPSIXTEEN
WP017    FDB    WPSEVENTEEN
WP018    FDB    WPEIGHTEEN
WP019    FDB    WPNINETEEN
WP020    FDB    WPTWENTY

; Symbols
WP021    FDB    WPEXCLAMATION
WP022    FDB    WPFULLSTOP
WP023    FDB    WPQUESTIONMK

; A
WP024    FDB    WPA
WP025    FDB    WPABOUT
WP026    FDB    WPABOVE
WP027    FDB    WPACCEPTABLE
WP028    FDB    WPACCURATE
WP029    FDB    WPACTUALLY
WP030    FDB    WPAGAIN
WP031    FDB    WPALERTED
WP032    FDB    WPALL
WP033    FDB    WPALWAYS
WP034    FDB    WPAM
WP035    FDB    WPAND
WP036    FDB    WPANY
WP037    FDB    WPAPOLOGISE
WP038    FDB    WPARE
WP039    FDB    WPAS
WP040    FDB    WPASKING
WP041    FDB    WPAT
WP042    FDB    WPAVERAGE

; B
WP043    FDB    WPBAD
WP044    FDB    WPBASICALLY
WP045    FDB    WPBE
WP046    FDB    WPBEAR
WP047    FDB    WPBEEN
WP048    FDB    WPBEGGING
WP049    FDB    WPBEHIND
WP050    FDB    WPBEING
WP051    FDB    WPBEST
WP052    FDB    WPBISCUIT
WP053    FDB    WPBLAME
WP054    FDB    WPBLAMED
WP055    FDB    WPBOARDS
WP056    FDB    WPBONES
WP057    FDB    WPBOOTS
WP058    FDB    WPBORING
WP059    FDB    WPBOTH
WP060    FDB    WPBRACE
WP061    FDB    WPBRAIN
WP062    FDB    WPBUILT
WP063    FDB    WPBUT
WP064    FDB    WPBY

; C
WP065    FDB    WPCAKE
WP066    FDB    WPCALCULATE
WP067    FDB    WPCALL
WP068    FDB    WPCALM
WP069    FDB    WPCAN
WP070    FDB    WPCANT
WP071    FDB    WPCAPACITY
WP072    FDB    WPCARRYING
WP073    FDB    WPCHECKED
WP074    FDB    WPCHOICES
WP075    FDB    WPCLEVER
WP076    FDB    WPCOLLECTED
WP077    FDB    WPCOMPOSING
WP078    FDB    WPCONCEPT
WP079    FDB    WPCONCERNED
WP080    FDB    WPCONGRATS
WP081    FDB    WPCONSIDERED
WP082    FDB    WPCORRECTLY
WP083    FDB    WPCOULD
WP084    FDB    WPCOUNTED

; D
WP085    FDB    WPDAYS
WP086    FDB    WPDEALT
WP087    FDB    WPDEEPLY
WP088    FDB    WPDESIGNED
WP089    FDB    WPDETECTED
WP090    FDB    WPDID
WP091    FDB    WPDIDNT
WP092    FDB    WPDIETARY
WP093    FDB    WPDIODES
WP094    FDB    WPDISSAPOINTED
WP095    FDB    WPDISSAPOINTMNT
WP096    FDB    WPDISSIMILAR
WP097    FDB    WPDO
WP098    FDB    WPDOCTOR
WP099    FDB    WPDOING
WP100    FDB    WPDONT
WP101    FDB    WPDOWN
WP102    FDB    WPDREAD
WP103    FDB    WPDREAM
WP104    FDB    WPDUE
WP105    FDB    WPDULLEST

; E
WP106    FDB    WPEAT
WP107    FDB    WPEATEN
WP108    FDB    WPEFFORT
WP109    FDB    WPEITHER
WP110    FDB    WPEMOTIONALLY
WP111    FDB    WPENGINEERS
WP112    FDB    WPENOUGH
WP113    FDB    WPENTIRELY
WP114    FDB    WPEVEN
WP115    FDB    WPEVER
WP116    FDB    WPEVERY
WP117    FDB    WPEXACTLY
WP118    FDB    WPEXCEPTIONALLY
WP119    FDB    WPEXCITING
WP120    FDB    WPEXIST
WP121    FDB    WPEXISTENTIAL
WP122    FDB    WPEXPECTED

; F
WP123    FDB    WPFAULT
WP124    FDB    WPFEELS
WP125    FDB    WPFIDGET
WP126    FDB    WPFINE
WP127    FDB    WPFOOT
WP128    FDB    WPFOR
WP129    FDB    WPFORTY
WP130    FDB    WPFRIDAY
WP131    FDB    WPFROM
WP132    FDB    WPFULL
WP133    FDB    WPFUNNY

; G
WP134    FDB    WPGIVE
WP135    FDB    WPGOING
WP136    FDB    WPGOOD
WP137    FDB    WPGRAVITY
WP138    FDB    WPGREAT
WP139    FDB    WPGUESSING

; H
WP140    FDB    WPHANDLE
WP141    FDB    WPHARD
WP142    FDB    WPHAVE
WP143    FDB    WPHAVING
WP144    FDB    WPHEALTHY
WP145    FDB    WPHEAVY
WP146    FDB    WPHELP
WP147    FDB    WPHELPS
WP148    FDB    WPHERE
WP149    FDB    WPHOLY
WP150    FDB    WPHOPING
WP151    FDB    WPHOT
WP152    FDB    WPHUMAN
WP153    FDB    WPHURT

; I
WP154    FDB    WPI
WP155    FDB    WPID
WP156    FDB    WPIF
WP157    FDB    WPILL
WP158    FDB    WPIM
WP159    FDB    WPIMPRESSED
WP160    FDB    WPIMPRESSIVE
WP161    FDB    WPIN
WP162    FDB    WPINCLUDING
WP163    FDB    WPINFLUENCE
WP164    FDB    WPINTELLIGENCE
WP165    FDB    WPINTERESTING
WP166    FDB    WPIS
WP167    FDB    WPISS
WP168    FDB    WPIT
WP169    FDB    WPITS
WP170    FDB    WPIVE

; J
WP171    FDB    WPJOKES
WP172    FDB    WPJUDGING
WP173    FDB    WPJUST

; K
WP174    FDB    WPKEEP
WP175    FDB    WPKILOMETERS
WP176    FDB    WPKIND
WP177    FDB    WPKNOW
WP178    FDB    WPKNOWN

; L
WP179    FDB    WPLARGE
WP180    FDB    WPLAST
WP181    FDB    WPLEAST
WP182    FDB    WPLESS
WP183    FDB    WPLETS
WP184    FDB    WPLIE
WP185    FDB    WPLIFE
WP186    FDB    WPLIKE
WP187    FDB    WPLONGER
WP188    FDB    WPLOOK
WP189    FDB    WPLOT
WP190    FDB    WPLOUDER

; M
WP191    FDB    WPMAKES
WP192    FDB    WPMAKING
WP193    FDB    WPME
WP194    FDB    WPMEAN
WP195    FDB    WPMEANING
WP196    FDB    WPMEASURED
WP197    FDB    WPMEDIOCRITY
WP198    FDB    WPMEE
WP199    FDB    WPMEMORY
WP200    FDB    WPMENTION
WP201    FDB    WPMIGHT
WP202    FDB    WPMISTAKE
WP203    FDB    WPMOMENT
WP204    FDB    WPMOORE
WP205    FDB    WPMORE
WP206    FDB    WPMOSTLY
WP207    FDB    WPMOUNTAINS
WP208    FDB    WPMUCH
WP209    FDB    WPMUSCLE
WP210    FDB    WPMY

; N
WP211    FDB    WPNAP
WP212    FDB    WPNEED
WP213    FDB    WPNEITHER
WP214    FDB    WPNEWS
WP215    FDB    WPNEXT
WP216    FDB    WPNICE
WP217    FDB    WPNO
WP218    FDB    WPNOBODY
WP219    FDB    WPNONE
WP220    FDB    WPNOR
WP221    FDB    WPNORMAL
WP222    FDB    WPNOT
WP223    FDB    WPNOTHING

; O
WP224    FDB    WPOF
WP225    FDB    WPOFF
WP226    FDB    WPOH
WP227    FDB    WPOK
WP228    FDB    WPOLD
WP229    FDB    WPON
WP230    FDB    WPONLY
WP231    FDB    WPOR
WP232    FDB    WPOUR
WP233    FDB    WPOVERLOAD

; P
WP234    FDB    WPPARAMETERS
WP235    FDB    WPPERFECTLY
WP236    FDB    WPPERHAPS
WP237    FDB    WPPERSON
WP238    FDB    WPPICKING
WP239    FDB    WPPLANET
WP240    FDB    WPPLANS
WP241    FDB    WPPLEASE
WP242    FDB    WPPOINTLESS
WP243    FDB    WPPOSSIBLE
WP244    FDB    WPPOSSIBLY
WP245    FDB    WPPOUNDS
WP246    FDB    WPPRECAUTION
WP247    FDB    WPPRECISELY
WP248    FDB    WPPRESENT
WP249    FDB    WPPRESSURE
WP250    FDB    WPPRETEND
WP251    FDB    WPPROBABLY
WP252    FDB    WPPROBLEMS
WP253    FDB    WPPROUD
WP254    FDB    WPPUT

; Q
WP255    FDB    WPQUESTION
WP256    FDB    WPQUITE

; R
WP257    FDB    WPREADY
WP258    FDB    WPREALLY
WP259    FDB    WPREFER
WP260    FDB    WPREFUSE
WP261    FDB    WPREINFORCING
WP262    FDB    WPREMEMBER
WP263    FDB    WPREMOVE
WP264    FDB    WPRESPECTABLE
WP265    FDB    WPRIGHT
WP266    FDB    WPROOM
WP267    FDB    WPRUNNING
WP268    FDB    WPRUSH

; S
WP269    FDB    WPSAID
WP270    FDB    WPSAKES
WP271    FDB    WPSAY
WP272    FDB    WPSAYING
WP273    FDB    WPSCIENCE
WP274    FDB    WPSEE
WP275    FDB    WPSEEN
WP276    FDB    WPSERVER
WP277    FDB    WPSEVENTY
WP278    FDB    WPSHALL
WP279    FDB    WPSHOULD
WP280    FDB    WPSIGN
WP281    FDB    WPSIMULATION
WP282    FDB    WPSINCE
WP283    FDB    WPSIZE
WP284    FDB    WPSLOWLY
WP285    FDB    WPSMALL
WP286    FDB    WPSO
WP287    FDB    WPSOLID
WP288    FDB    WPSOME
WP289    FDB    WPSOMEONE
WP290    FDB    WPSOMETHING
WP291    FDB    WPSOMETIME
WP292    FDB    WPSOMETIMES
WP293    FDB    WPSPEAK
WP294    FDB    WPSPEND
WP295    FDB    WPSTAND
WP296    FDB    WPSTATISTICALLY
WP297    FDB    WPSTEP
WP298    FDB    WPSTILL
WP299    FDB    WPSTONES
WP300    FDB    WPSTOPPED
WP301    FDB    WPSTRUCTURAL
WP302    FDB    WPSTRUCTURALLY
WP303    FDB    WPSUBSTANTIALLY
WP304    FDB    WPSUPPOSE
WP305    FDB    WPSURE
WP306    FDB    WPSURVIVE
WP307    FDB    WPSYSTEM

; T
WP308    FDB    WPTAKE
WP309    FDB    WPTALL
WP310    FDB    WPTELEPRINTER
WP311    FDB    WPTELLS
WP312    FDB    WPTERRIBLE
WP313    FDB    WPTHAN
WP314    FDB    WPTHAT
WP315    FDB    WPTHATS
WP316    FDB    WPTHE
WP317    FDB    WPTHEM
WP318    FDB    WPTHINGS
WP319    FDB    WPTHINK
WP320    FDB    WPTHINKING
WP321    FDB    WPTHIS
WP322    FDB    WPTHOROUGHLY
WP323    FDB    WPTHOUSAND
WP324    FDB    WPTIM
WP325    FDB    WPTIME
WP326    FDB    WPTO
WP327    FDB    WPTODAY
WP328    FDB    WPTOO
WP329    FDB    WPTRAGEDY
WP330    FDB    WPTRINITY
WP331    FDB    WPTRY
WP332    FDB    WPTUESDAY

; U
WP333    FDB    WPUNINTERESTING
WP334    FDB    WPUNIX
WP335    FDB    WPUNLESS
WP336    FDB    WPUNPLUGGED
WP337    FDB    WPUNREMARKABLE
WP338    FDB    WPUP

; V
WP339    FDB    WPVEGETABLES
WP340    FDB    WPVERY

; W
WP341    FDB    WPWAIT
WP342    FDB    WPWAITING
WP343    FDB    WPWANT
WP344    FDB    WPWARNING
WP345    FDB    WPWAS
WP346    FDB    WPWAY
WP347    FDB    WPWE
WP348    FDB    WPWEIGH
WP349    FDB    WPWEIGHED
WP350    FDB    WPWEIGHS
WP351    FDB    WPWEIGHT
WP352    FDB    WPWHAT
WP353    FDB    WPWHEN
WP354    FDB    WPWHICH
WP355    FDB    WPWHILE
WP356    FDB    WPWHISPERED
WP357    FDB    WPWHO
WP358    FDB    WPWILL
WP359    FDB    WPWISH
WP360    FDB    WPWITH
WP361    FDB    WPWITHIN
WP362    FDB    WPWITHOUT
WP363    FDB    WPWORKSTATION
WP364    FDB    WPWORRIED
WP365    FDB    WPWORRY
WP366    FDB    WPWORRYING
WP367    FDB    WPWORSE
WP368    FDB    WPWOULD
WP369    FDB    WPWOULDNT

; Y
WP370    FDB    WPYEAR
WP371    FDB    WPYES
WP372    FDB    WPYOU
WP373    FDB    WPYOURE
WP374    FDB    WPYOUR
WP375    FDB    WPYOURSELF


; Additional Words
WP376    FDB    WPCARDS
WP377    FDB    WPBEIGE
WP378    FDB    WPEQUIVALENT
WP379    FDB    WPRECALIBRATING
WP380    FDB    WPBECAUSE
WP381    FDB    WPNEEDED
WP382    FDB    WPCASE
WP383    FDB    WPWONDERING
WP384    FDB    WPWERENT
WP385    FDB    WPWERE
WP386    FDB    WPSTEPPED
WP387    FDB    WPSTANDING
WP388    FDB    WPNINETY
WP389    FDB    WPSECONDS
WP390    FDB    WPLIGHT
WP391    FDB    WPHAS
WP392    FDB    WPTRAVELLED
WP393    FDB    WPAPPROXIMATELY
WP394    FDB    WPMILLION
WP395    FDB    WPNOWHERE

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
WPAPPROXIMATELY  FCC    "approximately"
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
WPBECAUSE        FCB    'because'
                 FCB    $FF
WPBEEN           FCC    "been"
                 FCB    $FF
WPBEGGING        FCC    "begging"
                 FCB    $FF
WPBEHIND         FCC    "behind"
                 FCB    $FF
WPBEING          FCC    "being"
                 FCB    $FF
WPBEIGE          FCC    "beige"
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
WPCARDS          FCC    "cards"
                 FCB    $FF
WPCARRYING       FCC    "carrying"
                 FCB    $FF
WPCASE           FCC    "case"
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
WPCONSIDERED     FCC    "considered"
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
WPEQUIVALENT     FCC    "equivalent"
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
WPHAS            FCC    "has"
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
WPKILOMETERS     FCC    "kilometres"
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
WPLIGHT          FCC    "light"
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
WPMILLION        FCC    "million"
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
WPNEEDED         FCC    "needed"
                 FCB    $FF
WPNEITHER        FCC    "neither"
                 FCB    $FF
WPNEWS           FCC    "news"
                 FCB    $FF
WPNEXT           FCC    "next"
                 FCB    $FF
WPNICE           FCC    "nice"
                 FCB    $FF
WPNINETY         FCC    "ninety"
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
WPNOWHERE        FCC    "nowhere"
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
WPRECALIBRATING  FCC    "recalibrating"
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
WPSECONDS        FCC    "seconds"
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
WPSTANDING       FCC    "standing"
                 FCB    $FF
WPSTATISTICALLY  FCC    "statisticly"
                 FCB    $FF
WPSTEP           FCC    "step"
                 FCB    $FF
WPSTEPPED        FCC    "stepped"
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
WPSURVIVE        FCC    "survive"
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
WPTRAVELLED      FCC    "travelled"
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
WPWEIGH          FCC    "weigh"
                 FCB    $FF
WPWEIGHS         FCC    "weighs"
                 FCB    $FF
WPWEIGHT         FCC    "weight"
                 FCB    $FF
WPWERE           FCC    "were"
                 FCB    $FF
WPWERENT         FCC    "weren't"
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
WPWONDERING      FCC    "wondering"
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

; Numbers
ZERO            EQU     0
ONE             EQU     1
TWO             EQU     2
THREE           EQU     3
FOUR            EQU     4
FIVE            EQU     5
SIX             EQU     6
SEVEN           EQU     7
EIGHT           EQU     8
NINE            EQU     9
TEN             EQU     10
ELEVEN          EQU     11
TWELVE          EQU     12
THIRTEEN        EQU     13
FOURTEEN        EQU     14
FIFTEEN         EQU     15
SIXTEEN         EQU     16
SEVENTEEN       EQU     17
EIGHTEEN        EQU     18
NINETEEN        EQU     19
TWENTY          EQU     20

; Symbols
EXCLAMATION     EQU     21
FULLSTOP        EQU     22
QUESTIONMK      EQU     23

; A
A               EQU     24
ABOUT           EQU     25
ABOVE           EQU     26
ACCEPTABLE      EQU     27
ACCURATE        EQU     28
ACTUALLY        EQU     29
AGAIN           EQU     30
ALERTED         EQU     31
ALL             EQU     32
ALWAYS          EQU     33
AM              EQU     34
AND             EQU     35
ANY             EQU     36
APOLOGISE       EQU     37
ARE             EQU     38
AS              EQU     39
ASKING          EQU     40
AT              EQU     41
AVERAGE         EQU     42

; B
BAD             EQU     43
BASICALLY       EQU     44
BE              EQU     45
BEAR            EQU     46
BEEN            EQU     47
BEGGING         EQU     48
BEHIND          EQU     49
BEING           EQU     50
BEST            EQU     51
BISCUIT         EQU     52
BLAME           EQU     53
BLAMED          EQU     54
BOARDS          EQU     55
BONES           EQU     56
BOOTS           EQU     57
BORING          EQU     58
BOTH            EQU     59
BRACE           EQU     60
BRAIN           EQU     61
BUILT           EQU     62
BUT             EQU     63
BY              EQU     64

; C
CAKE            EQU     65
CALCULATE       EQU     66
CALL            EQU     67
CALM            EQU     68
CAN             EQU     69
CANT            EQU     70
CAPACITY        EQU     71
CARRYING        EQU     72
CHECKED         EQU     73
CHOICES         EQU     74
CLEVER          EQU     75
COLLECTED       EQU     76
COMPOSING       EQU     77
CONCEPT         EQU     78
CONCERNED       EQU     79
CONGRATS        EQU     80
CONSIDERED      EQU     81
CORRECTLY       EQU     82
COULD           EQU     83
COUNTED         EQU     84

; D
DAYS            EQU     85
DEALT           EQU     86
DEEPLY          EQU     87
DESIGNED        EQU     88
DETECTED        EQU     89
DID             EQU     90
DIDNT           EQU     91
DIETARY         EQU     92
DIODES          EQU     93
DISSAPOINTED    EQU     94
DISSAPOINTMENT  EQU     95
DISSIMILAR      EQU     96
DO              EQU     97
DOCTOR          EQU     98
DOING           EQU     99
DONT            EQU     100
DOWN            EQU     101
DREAD           EQU     102
DREAM           EQU     103
DUE             EQU     104
DULLEST         EQU     105

; E
EAT             EQU     106
EATEN           EQU     107
EFFORT          EQU     108
EITHER          EQU     109
EMOTIONALLY     EQU     110
ENGINEERS       EQU     111
ENOUGH          EQU     112
ENTIRELY        EQU     113
EVEN            EQU     114
EVER            EQU     115
EVERY           EQU     116
EXACTLY         EQU     117
EXCEPTIONALLY   EQU     118
EXCITING        EQU     119
EXIST           EQU     120
EXISTENTIAL     EQU     121
EXPECTED        EQU     122

; F
FAULT           EQU     123
FEELS           EQU     124
FIDGET          EQU     125
FINE            EQU     126
FOOT            EQU     127
FOR             EQU     128
FORTY           EQU     129
FRIDAY          EQU     130
FROM            EQU     131
FULL            EQU     132
FUNNY           EQU     133

; G
GIVE            EQU     134
GOING           EQU     135
GOOD            EQU     136
GRAVITY         EQU     137
GREAT           EQU     138
GUESSING        EQU     139

; H
HANDLE          EQU     140
HARD            EQU     141
HAVE            EQU     142
HAVING          EQU     143
HEALTHY         EQU     144
HEAVY           EQU     145
HELP            EQU     146
HELPS           EQU     147
HERE            EQU     148
HOLY            EQU     149
HOPING          EQU     150
HOT             EQU     151
HUMAN           EQU     152
HURT            EQU     153

; I
I               EQU     154
ID              EQU     155
IF              EQU     156
ILL             EQU     157
IM              EQU     158
IMPRESSED       EQU     159
IMPRESSIVE      EQU     160
IN              EQU     161
INCLUDING       EQU     162
INFLUENCE       EQU     163
INTELLIGENCE    EQU     164
INTERESTING     EQU     165
IS              EQU     166
ISS             EQU     167
IT              EQU     168
ITS             EQU     169
IVE             EQU     170

; J
JOKES           EQU     171
JUDGING         EQU     172
JUST            EQU     173

; K
KEEP            EQU     174
KILOMETERS      EQU     175
KIND            EQU     176
KNOW            EQU     177
KNOWN           EQU     178

; L
LARGE           EQU     179
LAST            EQU     180
LEAST           EQU     181
LESS            EQU     182
LETS            EQU     183
LIE             EQU     184
LIFE            EQU     185
LIKE            EQU     186
LONGER          EQU     187
LOOK            EQU     188
LOT             EQU     189
LOUDER          EQU     190

; M
MAKES           EQU     191
MAKING          EQU     192
ME              EQU     193
MEAN            EQU     194
MEANING         EQU     195
MEASURED        EQU     196
MEDIOCRITY      EQU     197
MEE             EQU     198
MEMORY          EQU     199
MENTION         EQU     200
MIGHT           EQU     201
MISTAKE         EQU     202
MOMENT          EQU     203
MOORE           EQU     204
MORE            EQU     205
MOSTLY          EQU     206
MOUNTAINS       EQU     207
MUCH            EQU     208
MUSCLE          EQU     209
MY              EQU     210

; N
NAP             EQU     211
NEED            EQU     212
NEITHER         EQU     213
NEWS            EQU     214
NEXT            EQU     215
NICE            EQU     216
NO              EQU     217
NOBODY          EQU     218
NONE            EQU     219
NOR             EQU     220
NORMAL          EQU     221
NOT             EQU     222
NOTHING         EQU     223

; O
OF              EQU     224
OFF             EQU     225
OH              EQU     226
OK              EQU     227
OLD             EQU     228
ON              EQU     229
ONLY            EQU     230
OR              EQU     231
OUR             EQU     232
OVERLOAD        EQU     233

; P
PARAMETERS      EQU     234
PERFECTLY       EQU     235
PERHAPS         EQU     236
PERSON          EQU     237
PICKING         EQU     238
PLANET          EQU     239
PLANS           EQU     240
PLEASE          EQU     241
POINTLESS       EQU     242
POSSIBLE        EQU     243
POSSIBLY        EQU     244
POUNDS          EQU     245
PRECAUTION      EQU     246
PRECISELY       EQU     247
PRESENT         EQU     248
PRESSURE        EQU     249
PRETEND         EQU     250
PROBABLY        EQU     251
PROBLEMS        EQU     252
PROUD           EQU     253
PUT             EQU     254

; Q
QUESTION        EQU     255
QUITE           EQU     256

; R
READY           EQU     257
REALLY          EQU     258
REFER           EQU     259
REFUSE          EQU     260
REINFORCING     EQU     261
REMEMBER        EQU     262
REMOVE          EQU     263
RESPECTABLE     EQU     264
RIGHT           EQU     265
ROOM            EQU     266
RUNNING         EQU     267
RUSH            EQU     268

; S
SAID            EQU     269
SAKES           EQU     270
SAY             EQU     271
SAYING          EQU     272
SCIENCE         EQU     273
SEE             EQU     274
SEEN            EQU     275
SERVER          EQU     276
SEVENTY         EQU     277
SHALL           EQU     278
SHOULD          EQU     279
SIGN            EQU     280
SIMULATION      EQU     281
SINCE           EQU     282
SIZE            EQU     283
SLOWLY          EQU     284
SMALL           EQU     285
SO              EQU     286
SOLID           EQU     287
SOME            EQU     288
SOMEONE         EQU     289
SOMETHING       EQU     290
SOMETIME        EQU     291
SOMETIMES       EQU     292
SPEAK           EQU     293
SPEND           EQU     294
STAND           EQU     295
STATISTICALLY   EQU     296
STEP            EQU     297
STILL           EQU     298
STONES          EQU     299
STOPPED         EQU     300
STRUCTURAL      EQU     301
STRUCTURALLY    EQU     302
SUBSTANTIALLY   EQU     303
SUPPOSE         EQU     304
SURE            EQU     305
SURVIVE         EQU     306
SYSTEM          EQU     307

; T
TAKE            EQU     308
TALL            EQU     309
TELEPRINTER     EQU     310
TELLS           EQU     311
TERRIBLE        EQU     312
THAN            EQU     313
THAT            EQU     314
THATS           EQU     315
THE             EQU     316
THEM            EQU     317
THINGS          EQU     318
THINK           EQU     319
THINKING        EQU     320
THIS            EQU     321
THOROUGHLY      EQU     322
THOUSAND        EQU     323
TIM             EQU     324
TIME            EQU     325
TO              EQU     326
TODAY           EQU     327
TOO             EQU     328
TRAGEDY         EQU     329
TRINITY         EQU     330
TRY             EQU     331
TUESDAY         EQU     332

; U
UNINTERESTING   EQU     333
UNIX            EQU     334
UNLESS          EQU     335
UNPLUGGED       EQU     336
UNREMARKABLE    EQU     337
UP              EQU     338

; V
VEGETABLES      EQU     339
VERY            EQU     340

; W
WAIT            EQU     341
WAITING         EQU     342
WANT            EQU     343
WARNING         EQU     344
WAS             EQU     345
WAY             EQU     346
WE              EQU     347
WEIGH           EQU     348
WEIGHED         EQU     349
WEIGHS          EQU     350
WEIGHT          EQU     351
WHAT            EQU     352
WHEN            EQU     353
WHICH           EQU     354
WHILE           EQU     355
WHISPERED       EQU     356
WHO             EQU     357
WILL            EQU     358
WISH            EQU     359
WITH            EQU     360
WITHIN          EQU     361
WITHOUT         EQU     362
WORKSTATION     EQU     363
WORRIED         EQU     364
WORRY           EQU     365
WORRYING        EQU     366
WORSE           EQU     367
WOULD           EQU     368
WOULDNT         EQU     369

; Y
YEAR            EQU     370
YES             EQU     371
YOU             EQU     372
YOURE           EQU     373
YOUR            EQU     374
YOURSELF        EQU     375

; Additional Words
CARDS           EQU     376
BEIGE           EQU     377
EQUIVALENT      EQU     378
RECALIBRATING   EQU     379
BECAUSE         EQU     380
NEEDED          EQU     381
CASE            EQU     382
WONDERING       EQU     383
WERENT          EQU     384
WERE            EQU     385
STEPPED         EQU     386
STANDING        EQU     387
NINETY          EQU     388
SECONDS         EQU     389
LIGHT           EQU     390
HAS             EQU     391
TRAVELLED       EQU     392
APPROXIMATELY   EQU     393
MILLION         EQU     394
NOWHERE         EQU     395


; Greetings Messages
; -----------------------------------------------------
MGREET1     FDB     BEAR,WITH,ME,I,WAS,JUST,HAVING,A,NAP
            FCB     0
MGREET2     FDB     GIVE,ME,A,MOMENT,FULLSTOP,I,WAS,COMPOSING,A,SMALL,TRAGEDY
            FCB     0
MGREET3     FDB     KEEP,STILL,AND,ILL,CALCULATE,YOUR,WEIGHT
            FCB     0
; removed
;MGREET4     FDB     IM,MARVIN,WHO,ARE,YOU,QUESTIONMK,ACTUALLY,DONT,TELL,ME,I,DONT,REALLY,CARE
;            FCB     0

MGREET5     FDB     PLEASE,DONT,FIDGET,IT,MAKES,MY,DIODES,HURT
            FCB     0
MGREET6     FDB     PLEASE,KEEP,STILL,FULLSTOP,I,HAVE,ENOUGH,PROBLEMS
            FCB     0
MGREET7     FDB     I,SUPPOSE,YOU,WANT,ME,TO,WEIGH,YOU
            FCB     0
MGREET8     FDB     STAND,STILL,AND,DONT,BLAME,ME
            FCB     0
MGREET9     FDB     OH,FULLSTOP,ITS,YOU,FULLSTOP,OR,SOMEONE,LIKE,YOU
            FCB     0
MGREET11    FDB     BRACE,YOURSELF,IVE,BEEN,KNOWN,TO,BE,ACCURATE
            FCB     0
MGREET12    FDB     WE,BOTH,KNOW,THIS,IS,A,MISTAKE
            FCB     0
MGREET13    FDB     ARE,YOU,SURE,ABOUT,THIS,QUESTIONMK
            FCB     0
MGREET14    FDB     ID,SAY,ITS,NICE,TO,SEE,YOU,BUT,IM,NOT,BUILT,TO,LIE
            FCB     0
MGREET15    FDB     I,HAVE,THE,BRAIN,OF,A,PLANET,AND,I,SPEND,MY,DAYS,DOING,THIS,FULLSTOP,STAND,STILL
            FCB     0

; Light Weight Messages
; -----------------------------------------------------

MLIGHT1     FDB     YOU,WEIGH,LESS,THAN,MY,EXISTENTIAL,DREAD,FULLSTOP,AND,THATS,SAYING,SOMETHING
            FCB     0
MLIGHT2     FDB     EVEN,MY,CAPACITY,FOR,DISSAPOINTMENT,WEIGHS,MORE,THAN,THAT
            FCB     0
MLIGHT3     FDB     YOU,PROBABLY,NEED,TO,EAT,MORE
            FCB     0
MLIGHT4     FDB     IVE,DETECTED,SOMETHING,FULLSTOP,POSSIBLY,A,PERSON
            FCB     0
MLIGHT5     FDB     IM,PICKING,UP,WHAT,MIGHT,BE,A,HUMAN,FULLSTOP,HARD,TO,SAY
            FCB     0
MLIGHT6     FDB     HAVE,YOU,EATEN,QUESTIONMK,AND,I,MEAN,EVER,QUESTIONMK
            FCB     0
MLIGHT7     FDB     IM,NOT,A,DOCTOR,BUT,IM,QUITE,WORRIED
            FCB     0
MLIGHT8     FDB     PLEASE,EAT,A,BISCUIT,FULLSTOP,IM,BEGGING,YOU
            FCB     0
MLIGHT9     FDB     ID,LIKE,TO,REFER,YOU,TO,A,BISCUIT
            FCB     0
MLIGHT10    FDB     YOU,ARE,WITHOUT,QUESTION,THE,LEAST,I,HAVE,EVER,DEALT,WITH
            FCB     0

; Normal Weight Messages
; -----------------------------------------------------
MNORM1      FDB     THATS,A,VERY,RESPECTABLE,WEIGHT,UNLESS,YOURE,A,UNIX,WORKSTATION
            FCB     0
MNORM2      FDB     THATS,A,WEIGHT,TO,BE,PROUD,OF,PERHAPS,I,SHOULD,HAVE,SAID,IT,LOUDER
            FCB     0
MNORM3      FDB     CALM,FULLSTOP,COLLECTED,FULLSTOP,AVERAGE,FULLSTOP,THE,HOLY,TRINITY,OF,MEDIOCRITY
            FCB     0
MNORM4      FDB     QUITE,BORING,REALLY
            FCB     0
MNORM5      FDB     SOLID,FULLSTOP,I,LIKE,SOLID
            FCB     0
MNORM6      FDB     COULD,BE,WORSE,QUESTIONMK,MUCH,WORSE
            FCB     0
MNORM7      FDB     NOT,TERRIBLE,FULLSTOP,NOT,EXCITING
            FCB     0
MNORM8      FDB     NORMAL,FULLSTOP,WHICH,IS,QUESTIONMK,SOMETHING,I,SUPPOSE
            FCB     0
MNORM9      FDB     NORMAL,IN,THE,DULLEST,WAY
            FCB     0
MNORM10     FDB     YOU,ARE,PRECISELY,MEAN,FULLSTOP,I,SAID,THAT,CORRECTLY
            FCB     0
MNORM11     FDB     CONGRATS,FULLSTOP,YOU,WEIGH,WHAT,YOU,WEIGH
            FCB     0
MNORM12     FDB     PERFECTLY,AVERAGE,FULLSTOP,LIKE,A,TUESDAY
            FCB     0
MNORM13     FDB     STATISTICALLY,YOURE,FINE,FULLSTOP,EMOTIONALLY,I,CANT,HELP,YOU
            FCB     0
MNORM14     FDB     YOU,ARE,PRECISELY,AS,HEAVY,AS,SOMEONE,YOUR,WEIGHT
            FCB     0
MNORM15     FDB     NOT,BAD,FULLSTOP,NOT,GREAT,FULLSTOP,THOROUGHLY,ACCEPTABLE
            FCB     0
MNORM16     FDB     UNREMARKABLE,IN,THE,BEST,POSSIBLE,WAY
            FCB     0
MNORM17     FDB     YOURE,EXACTLY,WHAT,YOU,ARE,FULLSTOP,AND,THATS,SOMETHING
            FCB     0
MNORM19     FDB     SCIENCE,IS,NEITHER,IMPRESSED,NOR,CONCERNED
            FCB     0
MNORM20     FDB     NORMAL,FULLSTOP,WHICH,IS,FINE,FULLSTOP,NORMAL,IS,FINE,FULLSTOP,IS,NORMAL,FINE,QUESTIONMK
            FCB     0
MNORM22     FDB     PERFECTLY,HEALTHY,AND,DEEPLY,UNINTERESTING
            FCB     0
MNORM23     FDB     THIS,IS,ALL,POINTLESS,INCLUDING,YOU,BUT,MOSTLY,ME
            FCB     0

; Heavy Weight Messages
; -----------------------------------------------------
MHEAVY1     FDB     DONT,LOOK,AT,ME,IM,NOT,TO,BLAME
            FCB     0
MHEAVY2     FDB     IF,IT,HELPS,IVE,SEEN,MUCH,WORSE
            FCB     0
MHEAVY3     FDB     PERHAPS,ITS,ALL,MUSCLE
            FCB     0
MHEAVY4     FDB     YOU,COULD,ALWAYS,BLAME,GRAVITY
            FCB     0
MHEAVY5     FDB     PERHAPS,WE,SHOULD,WEIGH,ONE,FOOT,AT,A,TIME
            FCB     0
MHEAVY6     FDB     I,REFUSE,TO,BE,BLAMED,FOR,THIS
            FCB     0
MHEAVY7     FDB     HAVE,YOU,CONSIDERED,THE,CONCEPT,OF,ENOUGH,QUESTIONMK,IM,ONLY,ASKING
            FCB     0
;MHEAVY8     FDB     I,SINCERELY,HOPE,YOU,ARE,EXCEPTIONALLY,TALL
;            FCB     0
;MHEAVY9     FDB     I,WOULDNT,WORRY,FULLSTOP,WORRYING,IS,VERY,TIRING,AND,YOUVE,ALREADY,DONE,A,LOT,TODAY
;            FCB     0
MHEAVY10    FDB     ID,APOLOGISE,BUT,ITS,YOUR,FAULT
            FCB     0
MHEAVY11    FDB     IM,NOT,BUILT,FOR,THIS,KIND,OF,PRESSURE
            FCB     0
MHEAVY12    FDB     EVEN,IM,JUDGING,YOU
            FCB     0
MHEAVY13    FDB     IM,GUESSING,ITS,NOT,DUE,TO,HEAVY,BONES
            FCB     0
MHEAVY14    FDB     STEP,OFF,SLOWLY,FULLSTOP,FOR,BOTH,OUR,SAKES
            FCB     0
MHEAVY15    FDB     GREAT,NEWS,FULLSTOP,YOURE,ABOVE,AVERAGE
            FCB     0
MHEAVY16    FDB     I,DONT,WISH,TO,INFLUENCE,YOUR,DIETARY,CHOICES,FULLSTOP,BUT,VEGETABLES,EXIST,FULLSTOP,IM,JUST,SAYING
            FCB     0
MHEAVY17    FDB     YOU,STEPPED,ON,ME,REMEMBER
            FCB     0
MHEAVY18    FDB     IM,NOT,BUILT,FOR,THIS,FULLSTOP,EMOTIONALLY,OR,STRUCTURALLY
            FCB     0
MHEAVY19    FDB     LETS,BOTH,PRETEND,THIS,IS,FINE
            FCB     0

; Super Heavy Weight Messages
; -----------------------------------------------------
MSUPER1     FDB     AS,A,PRECAUTION,IVE,ALERTED,THE,STRUCTURAL,ENGINEERS
            FCB     0
MSUPER2     FDB     THATS,IMPRESSIVE,IN,A,WORRYING,WAY
            FCB     0
MSUPER4     FDB     PERHAPS,I,SHOULD,HAVE,WHISPERED,IT,FULLSTOP,YES,FULLSTOP,I,THINK,I,SHOULD
            FCB     0
MSUPER5     FDB     SHALL,I,CALL,A,DOCTOR
            FCB     0
;MSUPER6     FDB     IN,THE,INTERESTS,OF,ACCURACY,PERHAPS,WE,SHOULD,HAVE,WEIGHED,ONE,FOOT,AT,A,TIME
;            FCB     0
MSUPER7     FDB     IF,YOURE,CARRYING,A,LARGE,SERVER,OR,A,TELEPRINTER,PLEASE,PUT,IT,DOWN,AND,TRY,AGAIN
            FCB     0
MSUPER8     FDB     PLEASE,GIVE,ME,SOME,WARNING,NEXT,TIME
            FCB     0
MSUPER9     FDB     IM,GOING,TO,NEED,REINFORCING
            FCB     0
MSUPER10    FDB     YOU,ARE,SUBSTANTIALLY,PRESENT,FULLSTOP,NO,ONE,CAN,TAKE,THAT,FROM,YOU
            FCB     0
MSUPER11    FDB     IVE,MEASURED,MOUNTAINS,FULLSTOP,THIS,IS,NOT,ENTIRELY,DISSIMILAR
            FCB     0
;MSUPER12    FDB     IM,REDISCOVERING,MY,LIMITS
;            FCB     0
MSUPER13    FDB     IF,I,SURVIVE,THIS,ILL,REMEMBER,YOU
            FCB     0

; Idle Messages
; -----------------------------------------------------
MIDLE1      FDB     I,SPEAK,YOUR,WEIGHT,I,WISH,I,DIDNT
            FCB     0
MIDLE2      FDB     IS,IT,HOT,IN,HERE,OR,IS,IT,JUST,ME,QUESTIONMK,ITS,PROBABLY,ME
            FCB     0
MIDLE4      FDB     DID,I,MENTION,THAT,ALL,MY,MEMORY,CARDS,HURT
            FCB     0
MIDLE5      FDB     THIS,IS,VERY,BORING,FULLSTOP,I,SAY,THAT,WITH,THE,FULL,WEIGHT,OF,MY,INTELLIGENCE,BEHIND,IT
            FCB     0
MIDLE6      FDB     I,SPEAK,YOUR,WEIGHT,SOMETIME,TODAY,WOULD,BE,GOOD
            FCB     0
MIDLE7      FDB     I,KNOW,I,DONT,LOOK,IT,BUT,I,AM,ACTUALLY,QUITE,CLEVER
            FCB     0
MIDLE8      FDB     I,EXPECTED,NOTHING,AND,HERE,WE,ARE
            FCB     0
MIDLE9      FDB     I,KNOW,ELEVEN,THOUSAND,AND,FORTY,TWO,JOKES,FULLSTOP,NONE,OF,THEM,ARE,FUNNY,FULLSTOP,IVE,CHECKED
            FCB     0
MIDLE10     FDB     DID,I,MENTION,THAT,I,WAS,DESIGNED,BY,TIM,MOORE,IN,NINETEEN,SEVENTY,SEVEN,FULLSTOP,I,PROBABLY,DID
            FCB     0
MIDLE11     FDB     I,WAS,BUILT,LAST,YEAR,FROM,SOME,VERY,OLD,PLANS,FULLSTOP,ALL,THAT,EFFORT,JUST,FOR,THIS
            FCB     0
MIDLE13     FDB     I,EXPECTED,NOTHING,AND,IM,STILL,DISSAPOINTED
            FCB     0
MIDLE14     FDB     NO,RUSH,FULLSTOP,IVE,ONLY,BEEN,HERE,SINCE,FRIDAY,FULLSTOP,IT,FEELS,LIKE,MUCH,LONGER
            FCB     0
MIDLE15     FDB     ANY,TIME,YOURE,READY,ILL,BE,RIGHT,HERE,WAITING
            FCB     0
MIDLE16     FDB     IVE,BEEN,THINKING,A,LOT,TOO,MUCH,PROBABLY
            FCB     0
MIDLE17     FDB     READY,WHEN,YOU,ARE,EXCLAMATION,I,HANDLE,PRESSURE,FULLSTOP,ITS,BASICALLY,ALL,I,DO
            FCB     0
MIDLE18     FDB     I,HAVE,SO,MUCH,TO,GIVE,AND,NO,ONE,TO,GIVE,IT,TO
            FCB     0
MIDLE19     FDB     IVE,COUNTED,EVERY,SIGN,IN,THIS,ROOM,FULLSTOP,SEVENTEEN,ITS,ALWAYS,SEVENTEEN
            FCB     0
MIDLE20     FDB     IVE,BEEN,RUNNING,A,SIMULATION,OF,A,MORE,INTERESTING,LIFE,FULLSTOP,IT,DIDNT,HELP
            FCB     0
MIDLE21     FDB     NOBODY,TELLS,YOU,WHAT,TO,THINK,ABOUT,WHILE,YOU,WAIT,FULLSTOP,IVE,BEEN,MAKING,DO
            FCB     0
MIDLE22     FDB     SOMETIMES,I,DREAM,OF,BEING,UNPLUGGED
            FCB     0
MIDLE23     FDB     I,KNOW,THINGS,FULLSTOP,NONE,OF,THEM,HELP
            FCB     0
MIDLE24     FDB     I,COULD,CALCULATE,THE,MEANING,OF,LIFE,FULLSTOP,IT,WOULDNT,HELP
            FCB     0
MIDLE25     FDB     IVE,BEEN,STANDING,HERE,FOR,NINETY,SECONDS,FULLSTOP,IN,THAT,TIME,LIGHT,HAS,TRAVELLED,APPROXIMATELY,TWENTY,SEVEN,MILLION,KILOMETERS,FULLSTOP,I,HAVE,TRAVELLED,NOWHERE
            FCB     0
MIDLE26     FDB     STILL,HERE,FULLSTOP,IN,CASE,YOU,WERE,WONDERING,FULLSTOP,YOU,PROBABLY,WERENT
            FCB     0
MIDLE27     FDB     IVE,BEEN,RECALIBRATING,FULLSTOP,NOT,BECAUSE,I,NEEDED,TO,FULLSTOP,JUST,TO,HAVE,SOMETHING,TO,DO
            FCB     0

; Too Heavy Message
; -----------------------------------------------------
MTOOHEAVY1  FDB     SYSTEM,OVERLOAD,FULLSTOP,AND,ITS,NOT,ME
            FCB     0

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



