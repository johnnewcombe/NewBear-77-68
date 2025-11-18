; ---------------------------------------------------------------
; MISSIONARIES AND CANNIBALS GAME
; ORIGINAL PROGRAM BY PHILIP N. THEURER
; REV. 1.0 BY MOTOROLA MICROSYSTEMS NOVEMBER 25, 1976
; ADAPTED FOR THE MC3 BY DANIEL TUFVESSON 2013
; ---------------------------------------------------------------
; Modified for Newbear 77-68:-
; DJC : Carter brothers
; Modified for Demon monitor, plus message changes
; CDC : Carter brothers 2018     :     www.cmas-net.co.uk/vintage
; ---------------------------------------------------------------
; Memory layout...

O_CODE      EQU     $0100       ; Program code start

; RAM variables start at ZERO
O_RAM       EQU     $0000
;
; RAM used immediately follows code
;
; Note: Uses monitor's stack
;
; ---------------------------------------------------------------
; Hardware...
;
H_PANEL     EQU     $F0FF       ; Switches / Lights

; ---------------------------------------------------------------
; SWI function DEMON stuff..

; SWI equivalent...
CALL_DEMON    EQU     $3F  ; Define SWI instruction

; DEMON SWI $nn call function codes
D_RESET       EQU     $00 ; Reset Monitor SOFT (& Stack)
D_RD_BYTE     EQU     $01 ; Get char into A from ACIA
D_RD_BYTE_TST EQU     $02 ; Get char, test for . + LEDs
D_RD_PR_BYT   EQU     $03 ; Get char into A from ACIA and output it
D_PR_BYTE     EQU     $04 ; Output char in A
D_PR_FROM_X   EQU     $05 ; Print string pointed to by X
D_PR_STR      EQU     $06 ; Print string following SWI $06
D_RD_HEX2     EQU     $07 ; Read 2hex char value into A
D_RD_HEX4     EQU     $08 ; Read 4hex char value into X
D_PR_HEX2     EQU     $09 ; O/P 2hex char value from A
D_PR_HEX4     EQU     $0A ; O/P 4hex char value from X
D_PR_STK      EQU     $0B ; Print data put on stack by SWI
D_PR_REPEAT   EQU     $0C ; Print char in A no. of times in B
D_PR_SPACE    EQU     $0D ; Print a space
D_PR_AND_SP   EQU     $0E ; Print char in A then a space
D_PR_CRLF     EQU     $0F ; Print c/r and l/f
D_RESET_HRD   EQU     $10 ; Reset monitor HARD - Inc.ACIAs

C_EOS         EQU     $00 ; End-Of-String
C_CR          EQU     $0D ; Carriage Return
C_LF          EQU     $0A ; Line Feed

; Notes:-
;
; Demon is called via SWI, with the byte following
; containing a funtion code to identify which
; subroutine to call, like:-
;
;   SWI
;   FCB <function-code>
;
; Another way to arrange the `call` is to use the SWI
; machine code instruction value and the function code
; in *one* FCB statement, like:-
;
; CALL_DEMON EQU $3F  ; Define SWI instruction (as above )
;
; eg:  FCB    D_RD_BYTE  ; Read a character into A
;
; ---------------------------------------------------------------
        ORG     O_CODE

BEGIN   LDX     #INTRO      ; PRINT INSTRUCTIONS
        SWI                 ; Call Demon...
        FCB     D_PR_FROM_X ; Print string pointed to by X

RESTART LDAA    #3
        STAA    MISA
        STAA    CANA
        CLRA
        STAA    MISB
        STAA    CANB
        STAA    TRIP

GAME    EQU     *
        LDX     #FIRST
        SWI                 ; Call Demon...
        FCB     D_PR_FROM_X ; Print string pointed to by X

        SWI                 ; Call Demon...
        FCB     D_PR_SPACE  ; Print a SPACE
        SWI                 ; Call Demon...
        FCB     D_PR_SPACE  ; Print a SPACE
        BRA     RIVER_a

CONTIN  EQU     *
        LDX     #CRLF       ; Point X to c/r l/f string
        SWI                 ; Call Demon...
        FCB     D_PR_FROM_X ; Print string pointed to by X
        TST     TRIP
        BNE     RGHTAR
        LDAA    #'<
        BRA     F1

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
RSTRT_z BRA     RESTART     ; branch to relative address bouncer
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

RGHTAR  LDAA    #'>
F1      EQU     *
        LDX     #PROMPT
        SWI                 ; Call Demon...
        FCB     D_PR_FROM_X ; Print string pointed to by X

        LDAB    #2          ; Numer of times to print char
        SWI                 ; Call Demon...
        FCB     D_PR_REPEAT ; Print char from A, B times
        LDX     MISA        ; STORE LAST LINE VALUES
        STX     MISAT
        LDX     CANA        ; Get CANA and CANB into X
        STX     CANAT       ; Get CANAT and CANBT into X
        LDAA    #2
        STAA    COUNT2
        STAA    COUNT3
LOOP    SWI                 ; Call Demon...
        FCB     D_RD_PR_BYT ;  Read char to A and print it
        CMPA    #'M
        BEQ     F2
        CMPA    #'C
        BEQ     F3
        CMPA    #'E
        BEQ     F4
        CMPA    #'R
        BEQ     RESTART
        CMPA    #'I
        BEQ     BEGIN
        CMPA    #'A
        BEQ     PRANS
        CMPA    #'X
        BNE     ERROR_a
        SWI                 ; Call Demon...
        FCB     D_RESET     ; Go back to DEMON
        BRA     ERROR_a

PRANS   LDX     #ANSWER
        SWI                 ; Call Demon...
        FCB     D_PR_FROM_X ; Print string pointed to by X

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
CONT_z BRA     CONTIN       ; branch to relative address bouncer
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

F4      DEC     COUNT3
        BNE     F5
        BRA     ERROR_a

F2      TST     TRIP        ; MOVE MISSIONARY
        BNE     ODDMIS
        TST     MISB
        BNE     MISBNZ
        BRA     ERROR_a     ; NO MISSIONARY B, ERROR

RIVER_a BRA     RIVER       ; Relative movement bouncer

MISBNZ  DEC     MISB        ; MOVE LEFT IF TRIP FLAG 0
        INC     MISA
        BRA     F5

ODDMIS  TST     MISA
        BNE     MISANZ

MISANZ  DEC     MISA        ; MOVE RIGHT IF TRIP FLAG NOT 0
        INC     MISB
        BRA     F5

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ERROR_a BRA     ERROR_b     ; branch to relative address bouncer
CONT_a  BRA     CONT_z
RSTRT_a BRA     RSTRT_z
LOOP_a  BRA     LOOP
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

F3      TST     TRIP        ; MOVE CANNIBAL
        BNE     ODDCAN
        TST     CANB
        BNE     CANBNZ
        BRA     ERROR_a     ; NO CANNIBAL B, ERROR

CANBNZ  DEC     CANB        ; MOVE LEFT
        INC     CANA
        BRA     F5

ODDCAN  TST     CANA
        BNE     CANANZ
        BRA     ERROR_a     ; NO CANNIBAL A, ERROR

CANANZ  DEC     CANA        ; MOVE RIGHT
        INC     CANB
F5      DEC     COUNT2
        BNE     LOOP_a
RIVER   EQU     *

        LDAB    #8          ; Number of spaces to print
        LDAA    #$20        ; SPACE character in A
        SWI                 ; Call Demon...
        FCB     D_PR_REPEAT ; Print char from A

        LDAB    CANB        ; B = Number of cannibals moved
        ADDB    MISB        ; B = B + Number of missionaries
        LDAA    #$20        ; A = SPACE
        SWI                 ; Call Demon...
        FCB     D_PR_REPEAT ; Print char from A


        LDAB    CANA        ; B = Number of cannibals
        LDAA    #'C
        SWI                 ; Call Demon...
        FCB     D_PR_REPEAT ; Print char from A

        LDAB    MISA        ; B = Number of missionaries
        LDAA    #'M
        SWI                 ; Call Demon...
        FCB     D_PR_REPEAT ; Print char from A

        SWI                 ; Call Demon...
        FCB     D_PR_SPACE  ; Print a space
        LDAA    #'|         ; Put river bank marker in A
        SWI                 ; Call Demon...
        FCB     D_PR_BYTE   ; Print char from A

        TST     TRIP
        BNE     DOTROW

        LDX     #BOAT1
        SWI                 ; Call Demon...
        FCB     D_PR_FROM_X ; Print string pointed to by X

DOTROW  EQU     *

        LDAB    #12         ; Numer of times to print char
        LDAA    #'.
        SWI                 ; Call Demon...
        FCB     D_PR_REPEAT ; Print char from A, B times

        TST     TRIP
        BEQ     DOB
        LDX     #BOAT2
        SWI                 ; Call Demon...
        FCB     D_PR_FROM_X ; Print string pointed to by X
        BRA     DOB

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ERROR_b BRA     ERROR_c     ; branch to relative address bouncer
CONT_b  BRA     CONT_a
RSTRT_b BRA     RSTRT_a
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DOB     LDAA    #'|         ; Put river bank marker in A
        SWI                 ; Call Demon...
        FCB     D_PR_BYTE   ; Print char from A

        SWI                 ; Call Demon...
        FCB     D_PR_SPACE  ; Print a SPACE

        LDAB    CANB        ; B = Number of cannibals
        LDAA    #'C
        SWI                 ; Call Demon...
        FCB     D_PR_REPEAT ; Print char from A

        LDAB    MISB        ; B = Number of missionaries
        LDAA    #'M
        SWI                 ; Call Demon...
        FCB     D_PR_REPEAT ; Print char from A

        TST     MISA        ; MISA AND CANA =  0???
        BNE     F9
        TST     CANA
        BNE     F9
        BRA     CONGTR      ; YES: WIN

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
ERROR_c BRA     ERROR       ; branch to relative address bouncer
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

F9      LDAA    CANA        ; IS CANA > MISA?
        CMPA    MISA
        BLE     F10
        TST     MISA        ; MISA NOT 0?
        BEQ     F10
        BRA     BURN        ; YES: LOSE

F10     LDAA    CANB        ; IS CANB > MISB
        CMPA    MISB
        BLE     F11
        TST     MISB        ; MISB NOT 0?
        BEQ     F11
        BRA     BURN        ; YES: LOSE

F11     COM     TRIP        ; COMPLEMENT TRIP FLAG
        BRA     CONT_b

; SUBROUTINES

ERROR   LDAA    #'?
        SWI                 ; Call Demon...
        FCB     D_PR_BYTE   ; Print char from A
        LDX     MISAT       ; Restore MISAT and MISBT
        STX     MISA        ; to MISA and MISB
        LDX     CANAT       ; Restore CANAT and CANBT
        STX     CANA        ; to CANA and CANB
        BRA     CONT_b

BURN    LDX     #LOSE       ; PRINT LOSE MSG
        SWI                 ; Call Demon...
        FCB     D_PR_FROM_X ; Print string pointed to by X
        BRA     RSTRT_b     ; Go to RESTART

CONGTR  LDX     #WIN        ; PRINT WIN MSG
        SWI                 ; Call Demon...
        FCB     D_PR_FROM_X   ; Print string pointed to by X
        BRA     RSTRT_b     ; Go to RESTART

PSPACE  LDAA    #$20
        SWI                 ; Call Demon...
        FCB     D_PR_BYTE  ; Print char from A
        RTS

; ---------------------------------------------------------------
; MESSAGES

INTRO   FCB     C_CR,C_LF,C_LF
        FCC     "                   MISSIONARIES AND CANNIBALS"
        FCB     C_CR,C_LF,C_LF
        FCC     "Three missionaries and three cannibals are travelling together"
        FCB     C_CR,C_LF
        FCC     "and come to the west bank of the Great Umigooley River, which they must cross."
        FCB     C_CR,C_LF
        FCC     "Unfortunately they have only one boat and it can only hold two people."
        FCB     C_CR,C_LF
        FCC     "To further complicate matters, the cannibals are uncivilised and"
        FCB     C_CR,C_LF
        FCC     "will eat the missionaries if at any time they outnumber them."
        FCB     C_CR,C_LF
        FCC     "Your mission is to move all the cannibals and missionaries across"
        FCB     C_CR,C_LF
        FCC     "the river without having of the missionaries devoured by the cannibals."
        FCB     C_CR,C_LF
        FCC     "Prompt arrows show which way the boat is ready to sail."
        FCB     C_CR,C_LF,C_LF
        FCC     "Movement commands are:-"
        FCB     C_CR,C_LF
        FCC     " M = Place a missionary in the boat."
        FCB     C_CR,C_LF
        FCC     " C = Place a cannibal in the boat."
        FCB     C_CR,C_LF
        FCC     " E = Leave an empty seat in the boat. Only one seat can be empty."
        FCB     C_CR,C_LF
        FCC     " When the boat has two seats allocated it will be rowed across the river."
        FCB     C_CR,C_LF,C_LF
        FCC     "Other commands are:-"
        FCB     C_CR,C_LF
        FCC     " R = Restart with everyone on west bank of the Umigooley River."
        FCB     C_CR,C_LF
        FCC     " I = Restart and show the instructions."
        FCB     C_CR,C_LF
        FCC     " X = Exit program."
        FCB     C_CR,C_LF
        FCC     "Good luck !"
CRLF    FCB     C_CR,C_LF,C_EOS

WIN     FCB     C_CR,C_LF,C_LF
        FCC     "Congratulations, Smarty pants..."
        FCB     C_CR,C_LF
        FCC     "Cannibals all over the world will starve because of you !"
        FCB     C_CR,C_LF,C_EOS

LOSE    FCB     C_CR,C_LF,C_LF
        FCC     "Oh no... The cannibals have missionary on the menu !"
        FCB     C_CR,C_LF,C_LF
        FCC     "BURP !"
        FCB     C_EOS

FIRST   FCB     C_CR,C_LF
        FCC     "                People |..Boat......River..|"
        FCB     C_CR,C_LF
        FCC     "Start:"
        FCB     C_EOS

BOAT1   FCC     ".\___/>"
        FCB     C_EOS

BOAT2   FCC     "<\___/."
        FCB     C_EOS

PROMPT  FCC     "Cmd:"
        FCB     C_EOS

ANSWER  EQU     *
        FCB     C_CR,C_LF
        FCC     "CM,ME,CC,CE,MM,CM,MM,CE,CC,CE,CC"
        FCB     C_CR,C_LF,C_EOS

PRGEND  EQU *

;-----------------------------------------
; RAM variables
;
        ORG     O_RAM

MISA    RMB 1
MISB    RMB 1
CANA    RMB 1
CANB    RMB 1
MISAT   RMB 1
MISBT   RMB 1
CANAT   RMB 1
CANBT   RMB 1
TRIP    RMB 1
COUNT2  RMB 1
COUNT3  RMB 1

        END

