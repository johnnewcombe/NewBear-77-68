;------------------------------------------
; 6800 code for Scelbi Galaxy game lifted
; from .pdf document & ocr of same
; with I/O to CDC/DJC DEMON monitor
;
; MODIFY I/O ROUTINES AT THE END FOR YOUR SYSTEM
;
;   CDC 11-July-2023
;       . Assigned labels to messages and changed references 
;       . to message addresses in code to use those labels.
;       . Message characters put in ASCII WITHOUT the high bit set.
;       . Make labels for subsitution points in messages.
;       . Change INPUT and PRINT routines to use DEMON SWI calls
;       . Change NOPs after CHICKEN! message to jump back to DEMON
;
;   CDC 12-July-2023
;       . Cosmetic changes to some messages ( Change 1 to | )
;       . More use of labels for Hex adress references
;
;   CDC 13-July-2023
;       . Added Ctrl+C = Quit back to monitor to input routine
;       . More work on removing use of high bit in ASCII chars
;
;   CDC 14-July-2023
;       . Departing more from original code...
;       .  Changed Space station from >1< to ]O[
;       .  Changed Ship from <*> to <o>
;
;   CDC 18-July-2023
;       . Fixed bug in course table for direction 5.0 
;
;   Apart from some text chars not having
;   high bit set in definitions
;   and our I/O and `Chicken!` exit jump
;   code hex on listing matches original listing...
;   https://archive.org/details/Scelbi-Galaxy-Game-for-the-6800-Robert-Findley-1977
;    or
;   https://ia803208.us.archive.org/28/items/
;       Scelbi-Galaxy-Game-for-the-6800-Robert-Findley-1977/
;       Scelbi%27s_Galaxy_Game_for_the_6800_Robert_Findley_1977.pdf
;
;------------------------------------------
; Some definitions...
DATA_BASE   EQU     $0000   ; General data
GLXY_MSGE   EQU     $0080   ; Galaxy line message
GLXY_BASE   EQU     $00C0   ; Galaxy data
TEXT_BASE   EQU     $0100   ; Main message area
CODE_BASE   EQU     $0500   ; Main code area
STACK_TOP   EQU     $0EFF   ; Top of stack area
IOIF_BASE   EQU     $0F80   ; I/O interface to monitor

cCR         EQU     $0D     ; Carriage-return
cLF         EQU     $0A     ; Line-feed
cEOS        EQU     $00     ; End-of-string
cCtrlC      EQU     $03     ; Control+C

cStation1   EQU     ']      ; Spacestation left char (was '>)
cStation2   EQU     'O      ; Spacestation middle char (was '1)
cStation3   EQU     '[      ; Spacestation right char (was '<)

cShip1      EQU     '<      ; Ship left char
cShip2      EQU     'o      ; Ship middle char (was '*)
cShip3      EQU     '>      ; Ship right char

cAlien      EQU     '+      ; Alien ship is 3 of these (was +++)
cStar       EQU     '*      ; Star char (was '*)

;------------------------------------------
; Data
            ORG     DATA_BASE

Course1x0   FDB     $0200
Course1x5   FDB     $02FF
Course2x0   FDB     $02FE
Course2x5   FDB     $01FE
Course3x0   FDB     $00FE
Course3x5   FDB     $FFFE
Course4x0   FDB     $FEFE
Course4x5   FDB     $FEFF
Course5x0   FDB     $FE00   ; Bug was that this was set to $FF00
Course5x5   FDB     $FE01
Course6x0   FDB     $FE02
Course6x5   FDB     $FF02
Course7x0   FDB     $0002
Course7x5   FDB     $0102
Course8x0   FDB     $0202
Course8x5   FDB     $0201

;------------------------------------------

PNTR1       RMB     2
PNTR2       RMB     2
PNTR3       RMB     2

STORE1      EQU     *       ; Msb stored AFTER Lsb !...
Store1LSB   RMB     1
Store1MSB   RMB     1       
STORE2      EQU     *      
Store2LSB   RMB     1
Store2MSB   RMB     1       
STORE3      EQU     *      
Store3LSB   RMB     1
Store3MSB   RMB     1       
STORE4      EQU     *      
Store4LSB   RMB     1
Store4MSB   RMB     1       
STORE5      EQU     *      
Store5LSB   RMB     1
Store5MSB   RMB     1  

CNTR        RMB     1       ; Temp counter storage

CI          RMB     1       ; Crossing indicator 

CF          RMB     1       ; Crossing flag 
RNM         RMB     2       ; Random number storage 
CQC         RMB     1       ; Current quadrant’s contents 
SLOSS       RMB     1       ; Sector location of space ship 
SOLSS       RMB     7       ; Sector location of stars 
SLSS        RMB     1       ; Sector location of space station 
SLAS1       RMB     1       ; Sect. loc. of alien ship no. 1 
SLAS2       RMB     1       ; Sect. loc. of alien ship no. 2 
SLAS3       RMB     1       ; Sect. loc. of alien ship no. 3
DVME        RMB     2       ; Energy in main supply 
DVSE        RMB     2       ; Energy in shields 
VASE1       RMB     2       ; Alien ship no. 1 energy 
VASE2       RMB     2       ; Alien ship no. 2 energy 
VASE3       RMB     2       ; Alien ship no. 3 energy 
CQLSS       RMB     1       ; Quadrant loc. of space ship 
NTR         RMB     1       ; Number of torpedoes 
NSS         RMB     1       ; Number of space stations 
NAS         RMB     1       ; Number of alien ships 
NSR         RMB     1       ; Number of star dates left 
DGT1ST      RMB     1       ; Digit storage for 
DGT2ND      RMB     1       ;  Binary to decimal and 
DGT3RD      RMB     1       ;   Decimal to binary 
DGT4TH      RMB     1       ;    Conversion 
DGT5TH      RMB     1       ; 

;------------------------------------------
; Table of pointers etc - Sec 5-2, 5-3

PSTR1       FCB     $00,$26
PSTR51      FCB     $00,$2F
PSLOSS      FCB     $00,$36
PSOLSS      FCB     $00,$37
PSLSS       FCB     $00,$3E
PSLAS1      FCB     $00,$3F
PSLAS2      FCB     $00,$40
PSLAS3      FCB     $00,$41
PDVME       FCB     $00,$42
PDVSE       FCB     $00,$44
PVASE1      FCB     $00,$46
PVASE2      FCB     $00,$48
PVASE3      FCB     $00,$4A
PCQLSS      FCB     $00,$4C
PDG1ST      FCB     $00,$51
PDG5TH      FCB     $00,$55


; -----------------------------------------
            ORG     GLXY_MSGE

MSGGAL      EQU     *
; From S19 file & listing...
;X          FCB     $BD,$BA,$B1,$A0,$B0,$B0,$B7,$A0 ; 0080
;X          FCB     $B1,$A0,$B0,$B0,$B5,$A0,$B1,$A0 ; 0088
;X          FCB     $B0,$B0,$B0,$A0,$B1,$A0,$B1,$B0 ; 0090
;X          FCB     $B4,$A0,$B1,$A0,$B1,$B0,$B2,$A0 ; 0098
;X          FCB     $B1,$A0,$B0,$B0,$B0,$A0,$B1,$A0 ; 00A0
;X          FCB     $B0,$B0,$B0,$A0,$B1,$A0,$B0,$B0 ; 00A8
;X          FCB     $B0,$A0,$B1,$00,$00,$00,$00,$00 ; 00B0
;
; Same stuff but with high bit removed... (and '1's changed to '|')
              FCB     cCR,cLF                         ; 0080
              FCC     "| xxx | xxx | xxx | xxx | xxx | xxx | xxx | xxx |"
MsgGalEnd     FCB     cEOS                            ; 00B3
              FCB     $00,$00,$00,$00                 ; 00B4;

; -----------------------------------------
; Book says: 00C0 -> 00FF reserved for Galaxy Content table...
            ORG     GLXY_BASE
GALSTART    RMB     $40
GALEND      EQU     *-1
GALAFTER    EQU     *

;------------------------------------------
; Messages

            ORG     TEXT_BASE

MSG01   EQU     *   ; $0100
        FCB     cCR,cLF
        FCC     "DO YOU WANT TO GO ON A SPACE VOYAGE? "
        FCB     cEOS

MSG02   EQU     *   ; was at $0128
        FCB     cCR,cLF
        FCC     "YOU MUST DESTROY "
Msg02a  FCC     "xx ALIEN SHIPS IN "
Msg02b  FCC     "xx STARDATES WITH "
Msg02c  FCC     "x SPACE STATIONS"
        FCB     cEOS

MSG03   EQU     *   ; was at $0170
        FCB     cCR,cLF
        FCC     " -1--2--3--4--5--6--7--8-"
        FCB     cEOS

MSG04   EQU     *   ; was at $018c
        FCB     cCR,cLF
Msg04a  FCC     "8"
Msg04b  FCC     "                        "
End04   FCB     cEOS

MSG05   EQU     *   ; was at $01a8
        FCC     " STARDATE  30"
Msg05a  FCC     "xx"
        FCB     cEOS

MSG06   EQU     *   ; was at $01b8
        FCC     " CONDITION "
Msg06a  FCC     "xxxxx"
        FCB     cEOS

MSG07   EQU     *   ; was at $01c9
        FCC     " QUADRANT  "
Msg07a  FCC     "x,x"
        FCB     cEOS

MSG08   EQU     *   ; was at $01d8
        FCC     " SECTOR    "
Msg08a  FCC     "x,x"
        FCB     cEOS

MSG09   EQU     *   ; was at $01e7
        FCC     " ENERGY    "
Msg09a  FCC     "xxxx"
        FCB     cEOS

MSG10   EQU     *   ; was at $01f7
        FCC     " TORPEDOES "
Msg10a  FCC     "xx"
        FCB     cEOS

MSG11   EQU     *   ; was at $0205
        FCC     " SHIELDS   "
Msg11a  FCC     "xxxx"
        FCB     cEOS

MSG12   EQU     *   ; was at $0215
        FCB     cCR,cLF
        FCC     "COMMAND?"
        FCB     cEOS

MSG13   EQU     *   ; was at $0220
        FCB     cCR,cLF
        FCC     "COURSE (1-8.5)? "
        FCB     cEOS

MSG14   EQU     *   ; was at $0233
        FCB     cCR,cLF
        FCC     "WARP FACTOR (0.1-7.7)? "
        FCB     cEOS

MSG15   EQU     *   ; $024D
        FCB     cCR,cLF
        FCC     "L.R. SCAN FOR"
        FCB     cEOS

MSG16   EQU     *   ; was at $025D
        FCB     cCR,cLF
        FCC     "MISSION FAILED,"
        FCC     " YOU HAVE RUN OUT OF STARDATES"
        FCB     cEOS

MSG17   EQU     *   ; was at $028D
        FCB     cCR,cLF
        FCC     "KA-BOOM, YOU CRASHED INTO A STAR. "
        FCC     "YOUR SHIP IS DESTROYED"
        FCB     cEOS

MSG18   EQU     *   ; $02C8
        FCB     cCR,cLF
        FCC     "YOU MOVED OUT OF THE GALAXY, YOUR SHIP"
        FCC     " IS LOST..LOST"
        FCB     cEOS

MSG19   EQU     *   ; was at $02FF
        FCB     cCR,cLF
        FCC     "LOSS OF ENERGY "
Msg19a  FCC     "xxxx"
        FCB     cEOS

MSG20   EQU     *   ; was at $0315
        FCB     cCR,cLF
        FCC     "DANGER-SHIELD ENERGY 000"
        FCB     cEOS

MSG21   EQU     *   ; was at $0330
        FCB     cCR,cLF
        FCC     "SHIELD ENERGY TRANSFER = "
        FCB     cEOS

MSG22   EQU     *   ; was at $034C
        FCB     cCR,cLF
        FCC     "NOT ENOUGH ENERGY"
        FCB     cEOS

MSG23   EQU     *   ; was at $0360
        FCB     cCR,cLF
        FCC     "TORPEDO TRAJECTORY(1-8.5) : "
        FCB     cEOS

MSG24   EQU     *   ; was at $037F
        FCB     cCR,cLF
        FCC     "ALIEN SHIP DESTROYED"
        FCB     cEOS

MSG25   EQU     *   ; was at $0396
        FCB     cCR,cLF
        FCC     "YOU MISSED! ALIEN SHIP RETALIATES"
        FCB     cEOS

MSG26   EQU     *   ; was at $03BA
        FCB     cCR,cLF
        FCC     "SPACE STATION DESTROYED"
        FCB     cEOS

MSG27   EQU     *   ; was at $03D4
        FCB     cCR,cLF
        FCC     "CONGRATULATIONS, YOU HAVE ELIMINATED"
        FCC     " ALL OF THE ALIEN SHIPS"
        FCB     cEOS

MSG28   EQU     *   ; $0412
        FCB     cCR,cLF
        FCC     "TRACKING: "
Msg28a  FCC     "x,x"
        FCB     cEOS

MSG29   EQU     *   ; was at $0422
        FCB     cCR,cLF
        FCC     "GALAXY DISPLAY"
        FCB     cEOS

MSG30   EQU     *   ; was at $0433
        FCB     cCR,cLF
        FCC     "PHASOR ENERGY TO FIRE = "
        FCB     cEOS

MSG31   EQU     *   ; was at $044E
        FCB     cCR,cLF
        FCC     "ALIEN SHIP AT SECTOR "
Msg31a  FCC     "x,x: "
        FCB     cEOS

MSG32   EQU     *   ; $046B
        FCC     "ENERGY = "
Msg32a  FCC     "xxxx"
        FCB     cEOS

MSG33   EQU     *   ; was at $0479
        FCB     cCR,cLF
        FCC     "NO ALIEN SHIPS! WASTED SHOT"
        FCB     cEOS

MSG34   EQU     *   ; was at $0497
        FCB     cCR,cLF
        FCC     "ABANDON SHIP! NO ENERGY LEFT"
        FCB     cEOS

MSG35   EQU     *   ; was at $04B6
        FCB     cCR,cLF
        FCC     "NO TORPEDOES"
        FCB     cEOS

MSG36   EQU     *   ; was at $04C5 : Long Range scan (`1`s changed to `|`s)
        FCB     cCR,cLF
        FCC     "| "
Msg36a  FCC     "000 | "
Msg36b  FCC     "000 | "
Msg36c  FCC     "000 |"
        FCB     cEOS

MSG37   EQU     *   ; was at $04DB
        FCB     cCR,cLF
;xx   x FCC     "LAST"      ;??? "SPACE STATION DESTROYED"
        FCC     "LAST SPACE STATION GONE" ; Replace message, using up last of mem up to $04ff
        FCB     cEOS

MSG38   EQU     *   ; was at $04E2
        FCB     cCR,cLF
        FCC     "CHICKEN!"
        FCB     cEOS

LastMsgEnd EQU *-1

;------------------------------------------
;------------------------------------------
            ORG     CODE_BASE
;------------------------------------------

GALAXY      LDS         #STACK_TOP  ; Set stack pointer to stack area
            JMP         START       ; Jump to start of Galaxy program 

;------------------------------------------
; Print message pointed to by X...

MSG         LDAA        0,X 
            BEQ         MSG1 
            JSR         PRINT 
            INX 
            BRA         MSG 
MSG1        RTS 

;------------------------------------------
; Bit rotate...
ROTR4       ASRA                    ; Shift A right 1 bit
ROTR3       ASRA                    ; Shift A right 1 bit
            ASRA                    ; Shift A right 1 bit
            ASRA                    ; Shift A right 1 bit
            RTS

;------------------------------------------
; Random number generator
  
RN          LDAA        RNM
            ROLA 
            EORA        RNM 
            RORA 
            INC         RNM+$1
            ADDA        RNM+$1
            BVC         SKIP 
            DEC         RNM+$1
SKIP        STAA        RNM
            RTS 

;------------------------------------------
; Binary / Decimal conversions
;
; The Galaxy program performs a number of operations involving 
; the conversion of numbers from binary to decimal and vice versa for 
; inputting and outputting numbers. The next trio of subroutines performs
; the conversion of double precision binary whole numbers to 
; and from decimal, and also checks that digits entered on the keyboard
; fall within the range of the ASCII code for digits, namely BO 
; through B9. The binary-to-decimal routine, labeled BINDEC, converts
; a single or double precision binary number to its decimal 
; equivalent up to five digits long, and stores the result in locations 51 
; through 55 on page 00. Accumulator B is set to 01 for a single precision
; number, and 02 for a double precision number, and the index 
; register is set to the least significant byte of the number to be converted
; before the BINDEC subroutine is called. The decimal-to-binary 
; subroutine, labeled DCBN, converts the decimal values stored 
; in locations 51 through 54 on page 00 to the equivalent double precision
; binary number which is saved in location 28 for the least significant half,
; and 29 on page 00 for the most significant half of the binary value.
; The FNUM subroutine checks the memory location indicated by the index
; register for a valid ASCII digit, and returns with 
; the N flag reset if it is a valid digit, or set if it is not. 
;
; X=Address of number to convert
; B=01 for X -> single precision
; B=02 for X -> double precision
;
; Noe: Many 2-byte values in this program are in LSB:MSB ofter

BINDEC      STX         PNTR1       ; Save pointer temporarily
            LDX         PDG1ST      ; Set pointer to start of decimal table
            CLR         $00,X       ; Clear digit table...
            CLR         $01,X 
            CLR         $02,X 
            CLR         $03,X 
            CLR         $04,X 
            LDX         PNTR1       ; Set pointer to binary value
            LDAA        0,X         ; Get LSB
            DECB                    ; Single precision ?
            BEQ         BNDC        ; Yes: most significanl half = 0
            LDAB        $01,X       ; No: get most significant hals
BNDC        STAA        STORE1      ; Store LSB
            STAB        STORE1+$1   ; Store MSB
            LDX         #$1027      ; Set up value for 10K
            STX         STORE2      ; Store for subtract routine
            BSR         BD          ; Calculate 5th digit 
            STAB        DGT5TH      ; Store value of 5th digit
            LDX         #$E803      ; Binary value for 1K
            STX         STORE2      ; Store for subtract routine
            BSR         BD          ; Calculate 4th digit
            STAB        DGT4TH      ; Store value of 4th digit
            LDX         #$6400      ; Binary value for 100
            STX         STORE2      ; Store for subtract routine
            BSR         BD          ; Calculate 3rd digit
            STAB        DGT3RD      ; Store value of 3rd digit
            LDAA        #$0A        ; LS half value of 10 decimal
            STAA        STORE2      ; Store for subtract routine
            BSR         BD          ; Calculate 2nd digit
            STAB        DGT2ND      ; Store value of 2nd digit
            LDAA        STORE1      ; Get unit value
            STAA        DGT1ST      ; Store value of 1st digit
            RTS                     ; Return to calling program

BD          CLRB                    ; Clear decimal digit counter
BD1         INCB                    ; Increment decimal digit
            LDAA        STORE1      ; Fetch the least significant half 
            SUBA        STORE2      ; Subtract LS half of constant
            STAA        STORE1      ; Save LS half of result
            LDAA        STORE1+$1   ; Fetch most significant half
            SBCA        STORE2+$1   ; Subtract MS half of constant
            STAA        STORE1+$1   ; Save MS half of result
            BCC         BD1         ; If greater than 0, continue subtraction
            LDAA        STORE1      ; Else, restore binary value
            ADDA        STORE2      ; Add LS half back to result
            STAA        STORE1      ; Restore result in memory
            LDAA        STORE1+$1   ; Fetch MS half of result
            ADCA        STORE2+$1   ; Add MS half back to result
            STAA        STORE1+$1   ; Restore result in memory
            DECB                    ; Decrement decimal digit to correct
            RTS                     ; Return

DCBN        CLR         STORE2+$1   ; Clear MS half of result 
            LDAA        DGT1ST      ; Fetch units digit
            STAA        STORE2      ; Store in work area
            LDAB        DGT2ND      ; Fetch ten’s digit
            BEQ         DC1         ; Digit = 0? Yes, do 100’s digit
            LDX         #$0A00      ; Binary value of 10
            STX         STORE1      ; To be added B times
            BSR         TOBN        ; Add 10’s digit

DC1         LDAB        DGT3RD      ; Get 3rd digit
            BEQ         DC2         ; Digit = 0? Yes, do 1000’s digit
            LDX         #$6400      ; Binary value of 100
            STX         STORE1      ; To be added B times
            BSR         TOBN        ; Add 100’s digit
DC2         LDAB        DGT4TH      ; Get 4th digit
            BEQ         DC3         ; Digit = 0? Yes, finished
            LDX         #$E803      ; Binary value of 1000
            STX         STORE1      ; To be added B times
            BSR         TOBN        ; Add 1000’s digit
DC3         RTS                     ; Return, binary value in STORE1

TOBN        LDX         #STORE2     ; Set pointer to binary value
            JSR         TO1         ; Add value to STORE1
            DECB                    ; Multiplier =0?
            BNE         TOBN        ; No, continue
            RTS                     ; Yes, return 

FNUM        LDAA        0,X         ; Fetch ASCII character
            CMPA        #'0         ; Is character a number? ( was $B0 )
            BMI         FNUM1       ; No, return with N flag set
            SUBA        #$3A        ; Valid number, return with ( was $BA )
            ADDA        #$80        ; N flag reset ( was $80 )
FNUM1       RTS                     ; Return


NWQD        LDX         PSOLSS      ; Set pointer to star table
            LDAA        #$C0        ; Clear code in A
            LDAB        #$0B        ; Counter in B
CLR1        STAA        0,X         ; Clear object location table
            INX                     ; Increment table pointer
            DECB                    ; Decrement counter
            BNE         CLR1        ; Not done? Clear more

            LDAB        CQC         ; Else get quadrant contents
            ANDB        #$07        ; Get number of stars 
            BEQ         NWQD1       ; If none, check space station
            LDX         PSOLSS      ; Set pointer to star table 
            BSR         LOCSET      ; Set up star locations 

NWQD1       LDAA        CQC         ; Get quadrant contents 
            JSR         ROTR3       ; Move to space station position
            TAB                     ; Set up for LOCSET
            ANDB        #$01        ; Any space stations?
            BEQ         NWQD2       ; No, check alien ships
            LDX         PSLSS       ; Fetch space station table location
            BSR         LOCSET      ; Set position if present

NWQD2       LDAA        CQC         ; Get quadrant contents 
            JSR         ROTR4       ; Position alien count
            TAB                     ; Put count in B
            ANDB        #$03        ; Mask for count
            BEQ         LLAS        ; No aliens, skip positioning
            LDX         PSLAS1      ; Set pointer to alien ship location
            BSR         LOCSET      ; Assign alien ship locations

LDAS        BSR         LLAS        ; Get random numbers  
            LDX         PVASE1      ; Pointer to alien ship no. 1 shields
            BSR         LAS         ; Store alien ship no. 1 energy
            LDX         PVASE2      ; Pointer to alien ship no. 2 shields
            BSR         LAS         ; Store alien ship no. 2 energy
            LDX         PVASE3      ; Pointer to alien ship no. 3 shields

LAS         STAA        0,X         ; Store least significant half value
            ANDA        #$03        ; Mask for most significant half 
            STAA        $01,X       ; Store most significant half 
LLAS        JMP         RN          ; Get random and return 

LOCSET      STX         PNTR1       ; Store table pointer 
            BSR         LLAS        ; Fetch random location 
            ANDA        #$3F        ; Mask off most significant bits 
            BSR         MATCH       ; New location match others? 
            BEQ         LOCSET+$2   ; Yes, find new location (recode***)
            LDX         PNTR1       ; Fetch table pointer 
            STAA        0,X         ; Store random location 
            INX                     ; Table pointer to next object 
            DECB                    ; Decrement object counter 
            BNE         LOCSET      ; Counter not =0, do next 
            RTS 

MATCH       LDX         PSOLSS      ; Set pointer to star table 
MATCH2      CMPA        0,X         ; Same sector location? 
            BEQ         MATCH1      ; Yes, match, return 
            INX                     ; Advance table pointer 
            CPX         PDVME       ; End of table? 
;x          BNE         MATCH2      ; No, check next 
;x          INX                     ; 
;x          DEX                     ; Yes, reset Z flag 
            JMP         PATCH       ; (in listing, chapter 5... p.87)
MATCH1      RTS                     ; Return 


QCNT        LDAA        CQLSS       ; Fetch current quadrant 
            ORAA        #$C0        ; Form pointer to galaxy 
            JSR         ATINX1      ; Set pointer to quadrant 
            LDAA        0,X         ; Fetch quadrant contents 
            STAA        CQC         ; Store new quadrant contents 
            RTS                     ; Return 

LOAD        LDX         #$8813      ; Store double precision value 5000 (LowByteFirst))
            STX         DVME        ; In main energy store 
            LDX         #$0000      ; Set shields to zero 
            STX         DVSE        ; 
            LDAA        #$0A        ; Load ten torpedoes on board 
            STAA        NTR         ; 
            RTS                     ; Return 
;---

TIME        LDX         #MSG16      ; Stardates time run out - player loses 

DONE        JSR         MSG         ; 
            JMP         GALAXY      ; Print message and start a new game
;                                   ; STRANGE: Original list has 7E 09 72
;                                   ; as code for this JMP GALAXY !!!!!!!

LOST        LDX         #MSG18      ; Out of known galaxy (was $02C8)
            BRA         DONE        ; Player loses 

WPOUT       LDX         #MSG17      ; Smashed into star 
            BRA         DONE        ; Player loses 

EOUT        LDX         #MSG34      ; Out of energy 
            BRA         DONE        ; Abandon ship 

;---

DIGPRT      STX         PNTR1       ; Save message digit location pointer 
            STS         PNTR2       ; Save stack pointer temporarily 
            LDS         PNTR1       ; Set stack pointer to 1st digit location 
            LDX         PDG1ST      ; Set index to 1st digit 
DGPRT1      LDAA        0,X         ; Get digit from storage 
            INX                     ; Advance index to next digit 
            ORAA        #$30        ; Form ASCII code (was $B0)
            PSHA                    ; Store in message 
            DECB                    ; Decrement digit counter 
            BNE         DGPRT1      ; Not =0? Continue 
            LDS         PNTR2       ; Equals 0, restore stack pointer 
            RTS                     ; And return 

;---

ROWSET      LDX         #Msg04b     ; Set pointer to row message 
            LDAA        #$20        ; Clear with ASCII space (was $A0)
RCLR        STAA        0,X         ; Store space character 
            INX                     ; Advance pointer 
            CPX         #End04     ; Message cleared? 
            BNE         RCLR        ; No, clear next 
            TBA                     ;  
            ORAA        #$30        ; Form ASCII code for row (was $B0)
            STAA        Msg04a      ; Store in message (was $018E)
            DECB                    ; Set up row number for checkout 
            LDX         PSLOSS      ; Set pointer to object location table 
            BSR         RWPNT       ; Fetch space ship location 
            BNE         STR         ; In this row? 
            LDAA        #cShip1     ; Yes, store space ship (was $BC)
            STAA        0,X         ;
            LDAA        #cShip2     ;  (was $AA)
            STAA        $01,X       ; 
            LDAA        #cShip3     ;  (was $BE)
            STAA        $02,X       ; Code for printout 

STR         LDX         PSOLSS 
            STX         PNTR2       ; Set a star table pointer 
STR1        BSR         RWPNT       ; Is star in this row? 
            BNE         NXSTR       ; No, pointer to next star 
            LDAA        #cStar      ; Yes, store star code  (was $AA)
            STAA        $01,X       ; In proper location 
NXSTR       INC         PNTR2+$1    ; Increment star table pointer 
            LDX         PNTR2       ; Put new pointer in index 
            CPX         PSLSS       ; End of star table? 
            BNE         STR1        ; No, check next star 
            BSR         RWPNT       ; Space station in this row? 
            BNE         AS          ; No, look for alien ships 
            LDAA        #cStation1  ; Yes, store space station (was $BE)
            STAA        0,X         ; 
            LDAA        #cStation2  ; (was $B1)
            STAA        $01,X       ; 
            LDAA        #cStation3  ; (was $BC) 
            STAA        $02,X       ; Code for printout 
AS          LDX         PSLAS1 
            STX         PNTR2       ; Set alien ship table pointer 
AS1         BSR         RWPNT       ; Alien ship in this row? 
            BNE         NXAS        ; No, look for next ship 
            LDAA        #cAlien     ; Yes, store code for alien  (was $AB)
            STAA        0,X
            STAA        $01,X 
            STAA        $02,X       ; Ship printout 
NXAS        INC         PNTR2+$1    ; Advance alien ship table pointer 
            LDX         PNTR2       ; Get new pointer 
            CPX         PDVME       ; End of table? 
            BNE         AS1         ; No, try next alien 
            LDX         #MSG04      ; Set pointer to print short range scan & 
            JMP         MSG         ; Return 

RWPNT       LDAA        0,X         ; Fetch entry location 
            BMI         RWPNT1      ; No, return 
            JSR         ROTR3       ; Position row entry 
            ANDA        #$07        ; Separate row entry 
            CBA                     ; Is row = current row? 
            BNE         RWPNT1      ; No, return 
            LDAA        0,X         ; Yes, fetch column location 
            ANDA        #$07        ; Separate column location 
            STAA        STORE1      ; Save column 
            ASLA                    ; Multiply by two 
            ADDA        STORE1      ; 
            ADDA        #$8F        ; Form pointer to row message 
            CLR         PNTR1 
            INC         PNTR1       ; Set up pointer storage to page 01 
            JSR         ATINX       ; Set index pointer from A 
            CLRA                    ; Set zero flag 
RWPNT1      RTS                     ; Return 

;---

QUAD        LDX         #Msg07a     ; Store temp, quadrant 
            STX         PNTR1       ; Message pointer 
            LDX         #CQLSS      ; Index to quadrant location storage 
            BSR         TWO         ; Put digits in message 
            LDX         #MSG07      ; Index to quadrant message 
            JMP         MSG         ; Print quadrant message and return 

TWO         LDAA        0,X         ; Fetch row and column 
            TAB                     ; Save row and column 
            LDX         PNTR1       ; Get message pointer 
T1          JSR         ROTR3       ; Position row number 
            ANDA        #$07        ; Mask off other bits 
            ADDA        #$31        ; Form ASCII code (was $B1)
            STAA        0,X         ; Store in message 
            ANDB        #$07        ; Separate column number 
            ADDB        #$31        ; Form ASCII code (was $B1)
            STAB        $02,X       ; 
            RTS 

;---

NTN         LDAB        #$13        ; Set counter 19 dashes 
NT1         LDAA        #$0D        ; ( was $8D ) 
            BSR         NT3         ; Print carriage return
            LDAA        #$0A        ; ( was $8A )
            BSR         NT3         ; Print line feed 
NT2         LDAA        #'-         ; Dash ( was $AD )
            BSR         NT3         ; Print 
            DECB                    ; Decrement counter. =0? 
            BNE         NT2         ; No, print more dashes 
            RTS                     ; Yes, return 
NT3         JMP         PRINT       ; Print and RETURN

QDSET       TAB                     ; Fetch quadrant contents 
            JSR         ROTR4       ; Position alien ship number 
            ANDA        #$03        ; Mask alien ship number 
            ORAA        #$30        ; Form ASCII digit ( was $B0 )
            STAA        0,X         ; Store in message 
            TBA                     ; Fetch quadrant contents 
            JSR         ROTR3       ; Position space ship number 
            ANDA        #$01        ; Mask space ship number 
            ORAA        #$30        ; Form ASCII digit ( was $B0 )
            STAA        $01,X       ; Store space ship in message 
            ANDB        #$07        ; Mask star number 
            ORAB        #$30        ; Form ASCII digit ( was $B0 )
            STAB        $02,X       ; Store in message 
            RTS                     ; Return 

CLC1        CLRA                    ; Clear column contents 
            BRA         LR3         ; Print 000 quadrant 

CLC2        CLRA                    ; Clear column contents 
            BRA         LR4         ; Print 000 quadrant 

LR5         JMP         ATINX1 
LRR         ORAA        #$C0 
            TAB                     ; Set pointer to galaxy 
            STAA        STORE1      ; Save pointer 
            ANDB        #$07        ; First column? 
            BEQ         CLC1        ; Yes, first column zero 
            DECA                    ; No, back one column 
            BSR         LR5         ; Set quadrant pointer 
            LDAA        0,X         ; Fetch quadrant contents 
LR3         LDX         #Msg36a     ; Set pointer to left quadrant  (was $04C9)
            BSR         QDSET       ; Set quadrant contents 
            LDAA        STORE1      ; Get pointer 
            BSR         LR5         ; Set quadrant pointer 
            LDAA        0,X         ; Fetch quadrant contents 
            LDX         #Msg36b     ; Set pointer to middle quadrant (was $04CF)
            BSR         QDSET       ; Set quadrant contents 
            LDAA        STORE1 
            TAB                     ; Fetch quadrant location 
            ANDB        #$07 
            CMPB        #$07        ; Is quadrant in last column? 
            BEQ         CLC2        ; Yes, right column =0 
            INCA                    ; Set to right quadrant 
            BSR         LR5         ; Set quadrant pointer 
            LDAA        0,X         ; Fetch quadrant contents 
LR4         LDX         #Msg36c     ; Index to right quadrant  (was $04D5)
            JSR         QDSET       ; Set quadrant contents 
LRP         LDX         #MSG36      ; Set pointer to long range row message 
LR6         JMP         MSG         ; Print and return 

; The depletion of energy from the space ship’s main storage bank 
; and its shields is an important function in this program. The following
; group of subroutines is called to delete the energy from the ship, 
; and to check the energy level of the ship. The subroutine labeled 
; ELOS deletes the amount of energy contained in the index register 
; from the ship’s protective shields. The least significant half of the 
; energy to be deleted must be stored in the most significant half of 
; the index register, and the most significant half of the energy must 
; be stored in the least significant half of the index register. By switching
; the two eight bit values around in this manner, the STX instruction
; will store the energy in the desired order in memory (the least 
; significant half in the lower address of the pair of memory locations). 
; The amount of energy deleted is first output to the display device to 
; inform the operator of the loss. The shield energy level is checked, 
; and if sufficient, the energy is removed from the shield. If the level 
; is not high enough to absorb the loss, the remaining shield energy is 
; transferred to the main supply, and the loss is taken from the main 
; storage bank. If at this time the main supply is not enough, the ship 
; is out of energy, and the game is over. Otherwise, since the shield 
; energy is zero, the warning message is output and an additional 25 
; percent of the energy loss is depleted from the main supply as a 
; penalty. The listing of ELOS and its supporting subroutines is shown 
; next. 

ELOS        STX         STORE3      ; Save energy value 
            LDX         #STORE3     ; Set pointer to value to be converted
            LDAB        #$02        ; Double precision conversion
            JSR         BINDEC      ; Convert to BCD for message
            LDX         #Msg19a+3   ; Set pntr to least signif digit of energy 
            LDAB        #$04        ; Set digit counter
            JSR         DIGPRT      ; Put digit in message
            LDX         #MSG19      ; Set pointer to energy loss message
            BSR         LR6         ; Print energy loss message
            LDX         STORE3      ; Restore value for routines
            STX         STORE1      ; To follow

ELS1        BSR         CKSD        ; Is shield energy sufficient?
            BCC         FMSD        ; Yes, delete from shields and return 

SDO1        LDX         DVSE        ; Move shield energy to main storage
            STX         STORE1      ; Remove energy from shields
            BSR         FMSD        ; Fetch energy to be deleted
            BSR         TOMN        ; Move shield energy to main storage
            LDX         STORE3      ; 
            STX         STORE1      ; Store for routines

SDO         BSR         CKMN        ; Energy enough?
            BCS         EOUT1       ; No, ship out of energy
            BSR         FMMN        ; Yes, take from main
            LDX         #MSG20      ; Print WARNING!
            BSR         LR6         ; DANGER - SHIELD ENERGY 000
            LDAB        #$02        ; Divide energy loss by 2 twice
            BSR         DVD         ; To divide by 4
            BSR         CKMN        ; Enough main energy for penalty?
            BCS         EOUT1       ; No, out of energy message
            BRA         FMMN        ; Yes, take penalty and return

CKSD        LDX         PDVSE       ; Check shield energy level
            BRA         CK1         ; Against requested level

CKMN        LDX         PDVME       ; Check main energy level 

CK1         LDAA        $01,X       ; Fetch most significant half
            CMPA        STORE1+$1   ; Is most significant half =0?
            BNE         ELOS1       ; No, return with flags set up
CK2         LDAA        0,X         ; If > =, return with C flag set
            CMPA        STORE1      ; If less than, C flag reset
            RTS                     ; Return

FMSD        LDX         PDVSE       ; Set pointer to shield energy
            BRA         FM1         ; Subtract energy from shields

FMMN        LDX         PDVME       ; Set pointer to main storage 

FM1         LDAA        0,X         ; Fetch least significant half of energy
            SUBA        STORE1      ; Subtract least significant half of loss
            STAA        0,X         ; Return to storage
            LDAA        $01,X       ; Fetch most significant half of energy
            SBCA        STORE1+$1   ; Subtract most significant half of loss 
            STAA        $01,X       ; Return to storage
            RTS                     ;  
 
TOSD        LDX         PDVSE       ; Set pointer to shield energy
            BRA         TO1         ; Add energy to shields

TOMN        LDX         PDVME       ; Set pointer to main energy 
TO1         LDAA        0,X         ; Fetch least significant half of energy 
            ADDA        STORE1      ; Add least significant half of loss
            STAA        0,X         ; Return to storage
            LDAA        $01,X       ; Fetch most significant half of energy 
            ADCA        STORE1+$1   ; Add most significant half of loss
            STAA        $01,X       ; Return to storage
            RTS                     ; 

DVD         TSTB                    ; Divide the double
            ROR         STORE1+$1   ;  precision value
            ROR         STORE1      ;   by two the number
            DECB                    ;    of times indicated in B
            BNE         DVD         ; 
ELOS1       RTS                     ; Return
EOUT1       JMP         EOUT        ; 


; The removal of energy from the main supply for the execution of 
; commands, firing phasors and torpedoes, and moving through the 
; galaxy is provided by the ELOM subroutine. The amount of energy 
; to be removed is stored in the index register (as described in the 
; ELOS subroutine) when the ELOM subroutine is called. If the main 
; energy bank contains enough energy, the energy is deleted, and the 
; subroutine returns to the calling program. If there is not enough 
; energy, the shield energy is transferred to the main storage bank in 
; an effort to provide for the loss. If this does not provide sufficient 
; energy, the game is over. However, if the transfer does produce the 
; energy needed in the main supply, the energy will be removed; and 
; since the shield energy has been reduced to zero, an additional 25 
; percent of the energy loss will be deleted from the main supply as a 
; penalty.

ELOM        BSR         CKMN        ; Enough energy in main?
            BCC         FMMN        ; Yes, take from main and return
            LDX         STORE1      ; No, save value of energy loss
            STX         STORE3      ; Transfer shield energy and try again
            JMP         SDO1        ; 


; The amount of energy transferred to or from the shields and the 
; energy to be fired by the phasor is entered by the operator. The EIN 
; subroutine is called to input these energy values. The first entry is 
; checked to determine whether it is a minus sign, used in the shield 
; entry. Location 55 on page 00 will be all zeros if the value is to be 
; positive, and non-zero for a negative entry. Each digit entered is 
; checked for validity, and then the ASCII code is masked off, resulting
; in the BCD digits being stored in locations 54 through 51. The 
; units digit is stored in location 51. Four digits must be entered by 
; the operator when this routine is called. If the input is found to be 
; invalid, the routine returns with the N flag set to T.’ If the input is 
; valid, the N flag is reset upon returning to the calling program. 

EIN         LDX         PDG5TH      ; Set pointer to start of digit store
            CLR         0,X         ; Clear sign indicator 
            JSR         INPUT       ; Get first character 
            CMPA        #'-         ; Negative sign?  (was $AD)
            BNE         EN2         ; No, check digit 
            STAA        0,X         ; Make negative indicator not =0 
EN1         JSR         INPUT       ; Get next character 
EN2         DEX                     ; Advance storage pointer 
            STAA        0,X         ; Store digit 
            JSR         FNUM        ; Valid digit? 
            BMI         EIN1        ; No, return with N flag set 
            LDAA        0,X         ; Yes, fetch digit 
            ANDA        #$0F        ; Mask off ASCII bits 
            STAA        0,X         ; Save BCD value 
            CPX         PDG1ST      ; End of input? 
            BNE         EN1         ; No, fetch next digit 
EIN1        RTS                     ; Yes, return 


; When the space ship destroys an alien ship or space station, the 
; result is the elimination of the alien ship or space station from the 
; galaxy. The subroutine DLET is called to perform this function. 
; First, the sector location of the object is cleared by storing a CO in 
; the data table at the location indicated by the index register. From 
; this location, the identity of the object to be deleted is ascertained. 
; A pointer is then formed indicating the location of the quadrant in 
; the galaxy content table from which the object is to be removed. If 
; the object was a space station, it is removed from the galaxy and the 
; number of space stations is decremented. If this value goes to zero, a 
; warning message is output to inform the operator that the last space 
; station has been destroyed. If an alien ship is destroyed, it is removed 
; from the galaxy and its count is decremented. When the number of 
; alien ships reaches zero, the game is over and the operator has successfully
; completed the mission.

DLET        LDAA        #$C0        ; Load with clear character 
            STAA        0,X         ; Clear object from table
            STX         PNTR2       ; Save table location
            LDAA        CQLSS       ; Get quadrant location
            ADDA        #$C0        ; Form galaxy table pointer
            JSR         ATINX1      ; Place pointer in index
            STX         PNTR3       ; Set table pointer
            LDX         PNTR2       ; Fetch table location
            JSR         COMPAR      ; Space station hit? 
            BNE         DLAS        ; No, delete alien ship 
            LDX         PNTR3       ; Fetch galaxy pointer
            LDAA        0,X         ; Get quadrant contents
            ANDA        #$37        ; Delete space station
            STAA        0,X         ; Restore quadrant in galaxy 
            STAA        CQC         ; Place new contents
            DEC         NSS         ; Decrement number of space stations
            BNE         DLET1       ; If more left, return
            LDX         #MSG37      ; If number of space stations =0,
            JMP         MSG         ;  print warning message & return

DLAS        LDX         PNTR3       ; Fetch galaxy pointer 
            LDAA        0,X         ; Get quadrant contents
            SUBA        #$10        ; Delete 1 alien ship from quadrant
            STAA        0,X         ; Restore to galaxy
            STAA        CQC         ; Save new contents
            DEC         NAS         ; Decrement number of alien ships 
            BNE         DLET1       ; More aliens, return
            LDX         #MSG27      ; All aliens destroyed!
            JMP         DONE        ; Print CONGRATULATIONS,
DLET1       RTS                     ; Start new game


; The final group of subroutines to be presented deals with the 
; movement of the space ship through the galaxy, and the tracking of 
; the torpedo within the quadrant. Moving an object through the 
; galaxy is performed with the use of a table referred to as the 
; COURSE TABLE. The course table, presented next, is located at the 
; beginning of page 00, and contains 16 pairs of row and column dis¬ 
; placement values. There is one pair of displacement values for each 
; possible direction of movement. The first value of each pair is the 
; column displacement; the second value is the row displacement. 
; The entries in the course table are made up of the binary values 2, 1, 
; 0, -1, and -2. A displacement of 1 advances the object one half of a 
; sector for each sector move made. So, for example, if the course was 
; chosen as 8.5, the displacement value for the column is two, and for 
; the row is one. This means that for every column moved to the right, 
; the object would move one half of a row down. A move is made by 
; the program by separating the row and column location of the object 
; to be moved, rotating each to the left once, and using the adjusted 
; values to calculate the move. Then, for each sector move made, the 
; row and column displacement is added to the adjusted row and 
; column location. When the move is completed, the adjusted values 
; are rotated to the right once, and then combined to give a new sector 
; location to the object. By using this method it is possible for the 
; direction of travel to be broken down to every 22 l A degrees. 

;---

; The subroutine DRCT is called to input the course direction from 
; the operator through the input device. The two digits defining the 
; move are checked for validity when entered, and then used to form a 
; pointer to the course table. If the input is valid, the routine returns 
; with the Z flag reset, and the pointer stored in location 20 on page 
; 00. If invalid, the Z flag is set before returning. The ACTV subroutine
; is then called to fetch the displacement values from the course 
; table, and store the column displacement in location 2D and the row 
; displacement in location 2C. It then sets up the adjusted row and 
; column values, and stores them in locations 2E and 2F respectively. 
;
; The subroutine labeled TRK is called to make the individual sector
; moves. First, the quadrant crossing flag is cleared. The column 
; displacement is then added to the adjusted column location, and a 
; quadrant crossing to the left or right is checked. If the crossing did 
; occur, the crossing flag is set, and the adjusted column is corrected to 
; indicate the new column value. The crossing is then checked for a 
; move out of the galaxy, which would be indicated by the TRK subroutine
; returning with the Z flag set. If the move is not out of the 
; galaxy, the new quadrant location is stored at location 4C on page 
; 00. The row displacement is then added to the adjusted row location, 
; and a quadrant crossing up and down is checked. If a quadrant is 
; crossed, the crossing flag is set and a move out of the galaxy is 
; checked. If the crossing is out of the galaxy, the routine returns with 
; the Z flag set. Otherwise, the new quadrant location is stored at location
; 4C, and the routine returns with the Z flag reset. The final subroutine
; of this group is called RWCM, and is called to restore the adjusted row
; and column locations to the single byte used to define the 
; final location of the object moved.

            
DRCT        JSR         INPUT       ; Input first course number 
            CMPA        #$31        ; Is input less than 1? (was $B1)
;x        x BCS         ZRET        ; ***************replaced...        
            BLT         ZRET        ; Yes, illegal input 
            CMPA        #$39        ; Is input greater than 8? (was $B9)
;x        x BCC         ZRET        ; *************** replaced...
            BGE         ZRET        ; Yes, illegal input 
            ANDA        #$0F        ; No, mask off ASCII bits 
            ASLA                    ; If good times 2 
            TAB                     ; And save in B
            LDAA        #'.         ; (was $AE)
            JSR         PRINT       ; Print decimal point 
            JSR         INPUT       ; Input second course number 
            CMPA        #'0         ; Is digit zero? (was $B0)
            BEQ         CR1         ; Yes, continue process 
            CMPA        #'5         ; No, is digit =5? (was $B5)
            BNE         ZRET        ; No, return with Z flag set 
CR1         ANDA        #$01        ; Mask off all but first bit 
            ABA                     ; Add first number input 
            ASLA                    ; 
            SUBA        #$04        ; And form pointer to course table 
            STAA        PNTR1+$1    ; Save pointer in temporary storage
            CLRA                    ;  
            STAA        PNTR1       ; Clear least significant byte of pointer
            INCA                    ; Reset Z flag 
            RTS                     ; Before returning 
ZRET        CLRA                    ; Set Z flag 
            RTS                     ; And return 

ACTV        STS         PNTR2       ; Save stack pointer temporarily 
            LDS         PSTR51      ; Set stack to storage area 
            LDAA        SLOSS       ; Get present location 
            TAB                     ; Save temporarily 
            ANDB        #$07        ; Mask out column 
            ASLB                    ; Multiply by 2 
            PSHB                    ; Store adjusted column 
            ANDA        #$38        ; Mask out row 
            LSRA                    ; 
            LSRA                    ; Set up times 2 value 
            PSHA                    ; Save adjusted row 
            LDX         PNTR1       ; Get displacement table pointer 
            LDAA        0,X         ; Get column movement 
            PSHA                    ; Store column displacement < 
            LDAA        $01,X       ; Get row movement 
            PSHA                    ; Store row displacement 
            LDS         PNTR2       ; Restore stack pointer
            RTS                     ; 

TRK         CLR         CF          ; Clear quadrant crossing flag 
            LDAA        STORE5+$1   ; Get adjusted column 
            ADDA        STORE4+$1   ; Add column move 
            STAA        STORE5+$1   ; Save temporarily current column 
            BPL         NOBK        ; If no left crossing, branch 
            ANDA        #$0F        ; Left crossing correction 
            STAA        STORE5+$1   ; And save new adjusted column 
            INC         CF          ; Indicate left crossing 
            LDAA        CQLSS       ; And decrement current column 
            ANDA        #$07        ; Is CQC =0? 
            BEQ         TRK1        ; Yes, return with Z set 
            DEC         CQLSS       ; No, decrement CQC 
            BRA         RMV         ; Do row move 

NOBK        CMPA        #$10        ; Quadrant crossing right 
            BCS         RMV         ; No, do row move 
            ANDA        #$0F        ; Yes, correct and 
            STAA        STORE5+$1   ; Save new adjusted column 
            INC         CF          ; Indicate crossing by making 
;                                   ; Crossing flag non-zero 
            LDAA        CQLSS       ; Fetch current quadrant location 
            ANDA        #$07        ; Separate column entry 
            INCA                    ; Increment column entry 
            CMPA        #$08        ; Move out of galaxy 
            BEQ         TRK1        ; Yes, return with flags set 
            INC         CQLSS       ; No, increment quadrant column 

RMV         LDAA        STORE5      ; Get adjusted row value 
            ADDA        STORE4      ; Add movement 
            STAA        STORE5      ; Save new adjusted row 
            BPL         NOUP        ; If not up, jump 
            ANDA        #$0F        ; Move up one quadrant, correct 
            STAA        STORE5      ; And save new adjusted value 
            INC         CF          ; Make crossing flag non-zero 
            LDAA        CQLSS       ; Decrement quadrant row 
            TAB                     ; Save temporarily 
            ANDA        #$38        ; Is quadrant row =0? 
            BEQ         TRK1        ; Yes, return with Z flag set 
            SUBB        #$08        ; No, decrement current quadrant row 
            STAB        CQLSS       ; Save new current quadrant 
            BRA         CKX         ; Then perform crossing logic 


NOUP        CMPA        #$10        ; Quadrant crossing down? 
            BCS         CKX         ; No, check for crossing flag 
            ANDA        #$0F        ; Yes, correct and 
            STAA        STORE5      ; Save new adjusted row 
            INC         CF          ; Indicate crossing 
            LDAA        CQLSS       ; Then increment quadrant row
            TAB                     ; Save temporarily
            ANDA        #$38        ; Separate row entry
            ADDA        #$08        ; Increment row value 
            CMPA        #$40        ; Out of galaxy?
            BEQ         TRK1        ; Yes, return with Z flag set
            ADDB        #$08        ; No, increment row
            STAB        CQLSS       ; Save new current quadrant

CKX         BNE         TRK1        ; Return with Z flag reset
            LDAA        #$01        ; If not, reset it
TRK1        RTS                     ; 

RWCM        LDAA        STORE5+$1   ; Fetch adjusted column 
            LSRA                    ; Adjust position
            ANDA        #$07        ; Form column value
            LDAB        STORE5      ; Fetch row
            ASLB                    ; Position row value
            ASLB                    ; 
            ANDB        #$38        ; Form row value
            ABA                     ; Form row and column byte
            RTS                     ; Return
 
ATINX1      CLR         PNTR1       ; Clear M.S. half of pointer for page 00 
ATINX       STAA        PNTR1+$1    ; Store A in least significant half of pntr 
            LDX         PNTR1       ; Load pointer into index register 
            RTS                     ; Return

COMPAR      STX         PNTR1       ; Store index value 
            LDAA        PNTR1+$1    ; Fetch low portion of the address 
            CMPA        #$3E        ; Set flags for address relative to SLSS
            RTS                     ; Return with results

WASTE       LDAA        CQC         ; Fetch quadrant contents
            ANDA        #$30        ; Mask out alien ship count
            BEQ         WASTE1      ; If none, wasted shot
            RTS                     ; Otherwise, return
WASTE1      PULB                    ; Remove unwanted address
            PULB                    ; From stack
            LDX         #MSG33      ; Set pointer to wasted shot message
            JSR         MSG         ; Print message
            JMP         CMND        ; Input new command

;---------

START       LDX         #MSG01      ; Set pointer to initial message 
            JSR         MSG         ; Print introduction
            JSR         RN          ; Increment random number 
            JSR         INPUT       ; Input character
            STAA        RNM+$1      ; Store input to randomize
            CMPA        #'N         ; Character = N? Yes, stop game (was $CE)
            BNE         OVER        ; No, set up galaxy

            LDX         #MSG38      ; Print “CHICKEN" (was at $04E2)
            JSR         MSG         ; 

; User defined end of program...    ; ( 3 x NOP in original listing )...
            JSR         USREXIT     ; Call user exit code
;---
OVER        LDAB        #$C0        ; Set pointer to galaxy storage
            STAB        STORE1      ; Save in temporary storage

GLXSET      JSR         RN          ; Fetch random number
            ANDA        #$7F        ; Form pointer to 
            LDAB        #$0F        ; Galaxy table from
            STAB        PNTR1       ; Random number
            JSR         ATINX       ; Set index to galaxy table
            LDAB        0,X         ; Get galaxy entry
            LDAA        STORE1      ; 
            JSR         ATINX1      ; Set index to galaxy content table
            STAB        0,X         ; Set index to galaxy content table
            INC         STORE1      ; Galaxy contents complete?
            BNE         GLXSET      ; No, fetch more sectors

GLXCK       CLR         NSS         ; Clear space station count
            CLR         NAS         ; Clear alien ship count
            LDX         #GALSTART   ; Pointer to galaxy content table ( was $00C0 )

GLXCK1      LDAA        0,X         ; Fetch quadrant contents
            TAB                     ; Save in ‘B’ accumulator
            ANDA        #$08        ; Mask space station
            ADDA        NSS         ; Add to space station total
            STAA        NSS         ; Save space station total
            ANDB        #$30        ; Mask alien ship
            LSRB                    ;  position 
            LSRB                    ; 
            ADDB        NAS         ; Add to alien ship total 
            STAB        NAS         ; Save alien ship total 
            INX                     ; Increment galaxy content pointer 
            CPX         #GALAFTER   ; End of table? ( was $0100 )
            BNE         GLXCK1      ; No, continue adding 
            LDAA        NSS         ; Fetch space station total 
            LSRA                    ; 
            LSRA                    ; 
            LSRA                    ; Position total to right 
            STAA        NSS         ; Store total 
            CMPA        #$07        ; Too many space stations? 
            BPL         SSPLS       ; Yes, delete 1 
            CMPA        #$02        ; Too few? 
            BPL         CAS         ; No, O.K., check alien ships 
SSMNS       LDAB        #$08        ; Yes, form mask to 
            STAB        STORE1      ; 
            BRA         MNS         ; Add one space station 

SSPLS       LDAB        #$F7        ; Form and store mask to 
            STAB        STORE1      ; 
            BRA         PLS         ; Delete one space station 
ASPLS       LDAB        #$CF        ; Form mask to delete 
            STAB        STORE1      ; One alien ship 
            
PLS         JSR         RN          ; Fetch random number 
            ORAA        #$C0        ; Form galaxy table pointer 
            JSR         ATINX1      ; Place pointer in index 
            LDAA        STORE1      ; Fetch mask 
            ANDA        0,X         ; Delete from galaxy 
PLS1        STAA        0,X         ; Store new quadrant contents 
            JMP         GLXCK       ; Check galaxy again 

ASMNS       LDAB        #$10        ; Form mask to add 
            STAB        STORE1      ; One alien ship 

MNS         JSR         RN          ; Fetch random number 
            ORAA        #$C0        ; Form galaxy table pointer 
            JSR         ATINX1      ; Place pointer in index 
            LDAA        STORE1      ; Fetch mask 
            ORAA        0,X         ; Add one alien ship to quadrant 
            BRA         PLS1        ; Check galaxy again 

CAS         LDAA        NAS         ; Fetch alien ship total 
            LSRA                    ; 
            LSRA                    ; Position 
            STAA        NAS         ; Save total 
            CMPA        #$20        ; Too many alien ships? 
            BPL         ASPLS       ; Yes, delete one alien ship 
            CMPA        #$0A        ; Too few? 
            BMI         ASMNS       ; Yes, add one alien ship 
            LDAA        #$05        ; Set up five more stardates
            ADDA        NAS         ; Than alien ships 
            STAA        NSR         ; Save number of stardates
            LDX         #NSR        ; Convert binary value
            LDAB        #$01        ; Set precision counter 
            JSR         BINDEC      ; Convert stardate value
            LDX         #Msg02b+1   ; Pointer to stardate count right ( was $014E )
            LDAB        #$02        ; Set precision counter
            JSR         DIGPRT      ; Put digits in starting message
            LDX         #NAS        ; Pointer to alien ship value
            LDAB        #$01        ; Set precision counter 
            JSR         BINDEC      ; Convert alien ship value
            LDX         #Msg02a+1   ; Pointer to alien ship count right ( was $013C )
            LDAB        #$02        ; Set precision counter 
            JSR         DIGPRT      ; Put digits in starting message
            LDAA        NSS         ; Get number of space stations
            ORAA        #$30        ; Form ASCII digit (was $B0)
            STAA        Msg02c      ; Store in starting message ( was $015F )
            LDX         #MSG02      ; Pointer to start of message
            JSR         MSG         ; Print starting message
            JSR         RN          ; Fetch starting quadrant
            ANDA        #$3F        ; Mask off MSB’s 
            STAA        CQLSS       ; Save current quadrant location 
            JSR         QCNT        ; Fetch current quadrant contents
            JSR         LOAD        ; Set initial conditions
            JSR         NWQD        ; Set quadrant contents location
            LDX         PSLOSS      ; Pointer to sector location storage
            LDAB        #$01        ; Set precision counter
            JSR         LOCSET      ; Set initial space ship location


; The next routine, which immediately follows the galaxy setup 
; routine, is the short range scan. The location of each of the objects 
; contained in the current quadrant is displayed as illustrated in the 
; sample short range scan in Chapter One. By the use of the ROWSET, 
; BINDEC, DIGPRT, and MSG subroutines, each line of the scan is 
; prepared and output to the display device. This routine is entered 
; following the galaxy setup to display the initial quadrant; then after 
; each move by the space ship either within the quadrant or when a 
; new quadrant is entered, and in response to a command to display 
; a short range scan. 

SRSCN       LDX         #MSG03      ; Set pointer for short range scan 
            JSR         MSG         ; Print initial row
            LDAB        #$01        ; Set row number one
            JSR         ROWSET      ; Set up row for printout
            LDAA        #$32        ; 
            SUBA        NSR         ; Calculate stardate number
            STAA        STORE1      ; Save temporarily
            LDX         PSTR1       ; Set pointer to binary value
            LDAB        #$01        ; Set precision counter
            JSR         BINDEC      ; Convert to current stardate 
            LDX         #Msg05a+1   ; Set pointer to stardate message (was $01B6)
            LDAB        #$02        ; Set counter to number of digits 
            JSR         DIGPRT      ; Put digits in stardate message
            LDX         #MSG05      ; Set pointer to message
            BSR         SRSCN1      ; Print stardate message

            LDAB        #$02        ; Set row number two
            JSR         ROWSET      ; Set up row for printout
            LDAA        CQC         ; Fetch current quadrant contents
            LDX         #Msg06a     ; Set pointer to condition message ( was $01C3 )
            ANDA        #$30        ; Alien ship in quadrant? 
            BNE         RED         ; Yes, condition red
            LDAA        #'G        ; No, condition green (was $C7)
            STAA        0,X         ; Fill in ‘GREEN’ in
            LDAA        #'R         ;  condition message  ( was $D2 )
            STAA        $01,X       ; 
            LDAA        #'E         ; (was $C5)
            STAA        $02,X       ; 
;x          LDAA        #'E         ; (was $C5)
            NOP                     ; 2nd E is
            NOP                     ;  Same as previous char, so no need to reload
            STAA        $03,X       ; 
            LDAA        #'N         ; (was $CE)
            STAA        $04,X       ; 
            BRA         CND         ; Output condition message
SRSCN1      JMP         MSG         ; 

RED         LDAA        #'R         ; Condition red (was $D2)
            STAA        0,X         ; 
            LDAA        #'E         ; Fill in ‘RED’ in (was $C5)
            STAA        $01,X       ;  condition message 
            LDAA        #'D         ; (was $C4)
            STAA        $02,X       ; 
            CLR         $03,X       ; 

CND         LDX         #MSG06      ; Set pointer to condition message
            BSR         SRSCN1      ; Print condition message

            LDAB        #$03        ; Set row number three 
            JSR         ROWSET      ; Set up for printout
            JSR         QUAD        ; Print current quadrant

            LDAB        #$04        ; Set row number four
            JSR         ROWSET      ; Set up for printout
            LDX         #Msg08a     ; Set up sector message (was $01E3)
            STX         PNTR1       ; Pointer in storage
            LDX         PSLOSS      ; Pointer to current sector
            JSR         TWO         ; Put two digits in message
            LDX         #MSG08      ; Set pointer to sector message
            BSR         SRSCN1      ; Print sector message

            LDAB        #$05        ; Set row number five 
            JSR         ROWSET      ; Set up row for printout
            LDX         PDVME       ; Set pointer to main energy 
            LDAB        #$02        ; Set precision counter 
            JSR         BINDEC      ; Convert to decimal 
            LDX         #Msg09a+3   ; Message pointer 
            LDAB        #$04        ; Counter for four digits 
            JSR         DIGPRT      ; Put digits in message 
            LDX         #MSG09      ; Set pointer to energy message 
            BSR         SRSCN1      ; Print energy message 
            LDAB        #$06        ; Set row number six 
            JSR         ROWSET      ; Set up for printout 
            LDX         #NTR        ; Pointer to torpedo count 
            LDAB        #$01        ; Precision =1 
            JSR         BINDEC      ; Convert to decimal 
            LDX         #Msg10a+1   ; Set pointer to torpedo message 
            LDAB        #$02        ; Counter to number of digits 
            JSR         DIGPRT      ; Put number of torpedoes in message 
            LDX         #MSG10      ; 
            JSR         SRSCN1      ; Print torpedo message 

            LDAB        #$07        ; Set row number seven 
            JSR         ROWSET      ; Set up row for printout 
            LDX         PDVSE       ; Set pointer to shield energy 
            LDAB        #$02        ; And set precision for 
            JSR         BINDEC      ;  binary to decimal conversion
            LDX         #Msg11a+3   ; Set pointer to shield energy message (was $0213)
            LDAB        #$04        ; Set digit count 
            JSR         DIGPRT      ; Put digits in memory 
            LDX         #MSG11      ; Set pointer to shield message 
            JSR         MSG         ; Print shield message 

            LDAB        #$08        ; Set row number eight 
            JSR         ROWSET      ; Set up row for printout 
            LDX         #MSG03      ; Set pointer to final row 
            JSR         MSG         ; Print final row 


; The commands, input by the operator to direct the operation of 
; the space ship, are controlled by the COMMAND INPUT routine, 
; labeled CMND. This routine (which immediately follows the short 
; range scan) begins by deleting ten units of energy from the main 
; storage bank to simulate the loss of energy resulting from the operation
; of the ship’s control panel. The second byte of the random number
; storage is then decremented to increase the random number 
; generator’s overall randomness. The command request message is 
; then output to the display device, followed by a call to the input 
; routine to receive the command from the input device. If the character
; input matches one of the ASCII codes (indicating a valid command),
; the proper routine is entered to perform the command. If the 
; character is not a valid command entry, the program simply requests 
; the command input again.

CMND        LDX         #$0A00      ; Delete ten units of energy 
            STX         STORE1      ; For each command
            JSR         ELOM        ;
            DEC         RNM+$1      ; Randomize random number 

CMD         LDX         #MSG12      ; Set pointer to command message 
            JSR         MSG         ; Request command input 
            JSR         INPUT       ; Input command 

            CMPA        #'0         ; Ship movement? ( was $B0 )
            BNE         NCRSE       ; No, try next
            JMP         CRSE        ; Yes, input course
NCRSE       CMPA        #'1         ; Short range scan? ( was $B1 )
            BNE         NSRSCN      ; No, try next
            JMP         SRSCN       ; Yes, display quadrant 
NSRSCN      CMPA        #'2         ; Long range scan? ( was $B2 )
            BNE         NLRSCN      ; No, try next 
            JMP         LRSCN       ; Yes, print long range scan 
NLRSCN      CMPA        #'3         ; Galaxy printout?( was $B3 )
            BNE         NGXPRT      ; No, try next 
            JMP         GXPRT       ; Yes, print galaxy
NGXPRT      CMPA        #'4         ; Shield energy? ( was $B4 )
            BNE         NSHEN       ; No, try next
            JMP         SHEN        ; Yes, adjust shields
NSHEN       CMPA        #'5         ; Phasor control? ( was $B5 )
            BNE         NPHSR       ; No, try next 
            JMP         PHSR        ; Yes, fire phasors
NPHSR       CMPA        #'6         ; Torpedo shot? ( was $B6 )
            BNE         CMD         ; No, illegal command, try again
            JMP         TRPD        ; Yes, shoot torpedo


; The long range scan routine outputs the contents of the current 
; quadrant and the eight quadrants which immediately surround it. 
; The number of alien ships, space stations, and stars in each of these 
; quadrants is displayed as described in the first chapter. A message 
; is output first indicating the current quadrant location of the space ship.
; The contents of the three quadrants in the row above the 
; current quadrant are then output by calling the LRR subroutine. 
; If this top row is outside the galaxy, the contents will be output as 
; all zeros by use of the RWC routine. The row containing the current 
; quadrant is then output, followed by the row below the current 
; quadrant. If this bottom row is outside the galaxy, its contents will 
; be displayed as all zeros. A dividing line of dashes is output between 
; each row. At the completion, the routine returns to input a new 
; command. The long range scan routine begins at the label LRSCN. 

LRSCN       LDX         #MSG15      ; Set pointer to long range message 
            JSR         MSG         ; Print long range scan 
            JSR         QUAD        ; Print quadrant location 
            BSR         LRSCN1      ; Print row of dashes 
            LDAA        CQLSS       ; Fetch current quadrant 
            TAB                     ; Save temporarily 
            ANDB        #$38        ; Current quadrant in row no. 1? 
            BEQ         RWC1        ; Yes, top row clear 
            SUBA        #$08        ; Indicate row -1 
            JSR         LRR         ; Set up and print top row 

LR1         BSR         LRSCN1      ; Print separating row 
            LDAA        CQLSS       ; Fetch current quadrant 
            JSR         LRR         ; Set up and print middle row 
            BSR         LRSCN1      ; Print separating row 
            LDAA        CQLSS       ; Fetch current quadrant 
            CMPA        #$38        ; Current quadrant in row no. 8? 
            BCC         RWC2        ; Yes, bottom row clear 
            ADDA        #$08        ; No, set quadrant row +1 
            JSR         LRR         ; Set and print bottom row 
LR2         BSR         LRSCN1      ; Print bottom border 
            JMP         CMND        ; Input next command 
LRSCN1      JMP         NTN         ; 

RWC1        BSR         RWC         ; Print clear row 
            JMP         LR1         ; Continue long range scan 

RWC2        BSR         RWC         ; Print clear row 
            JMP         LR2         ; Finish long range scan 

RWC         LDX         #Msg36a     ; Set pointer to left quadrant (was $04C9)
            CLRA                    ; Set zero entry 
            JSR         QDSET       ; Set quadrant contents 
            LDX         #Msg36b     ; Set pointer to middle quadrant (was $04CF)
            CLRA                    ; Set zero entry 
            JSR         QDSET       ; Set quadrant contents 
            LDX         #Msg36c     ; Set pointer to right quadrant (was $04D5)
            CLRA                    ; Set zero entry 
            JSR         QDSET       ; Set quadrant contents 
            JMP         LRP         ; Print long range row 

 
; The galaxy display routine produces an output of the entire galaxy 
; contents to the display device in a format similar to that of the long 
; range scan. The display is used to provide the operator with a map 
; from which a course may be charted for the mission. The contents of 
; a complete row are set up in the galaxy printout message on page 00 
; by calling the QDSET subroutine, and then the row is output to the 
; display device. A dividing line of dashes is output between each row. 
; When the output is finished, the routine returns to the command input
; routine.

GXPRT       LDX         #MSG29      ; 
            JSR         MSG         ; Print GALAXY DISPLAY
            LDAB        #$31        ; Set number chars to print
            JSR         NT1         ; Print border 
            LDX         #GALSTART   ; Set pointer to galaxy ( was $00C0 )
            STX         PNTR1       ; Store temporarily
GL1         LDX         #MSGGAL+4   ; Set up message pointer ( was $0084 )
            STX         PNTR2       ; Store temporarily
GL2         LDX         PNTR1       ; Fetch galaxy pointer
            CPX         #GALAFTER   ; End of printout? ( was $0100 )
            BEQ         GL3         ; Yes, input next command
            LDAA        0,X         ; Get quadrant contents 
            INX                     ; Advance pointer
            STX         PNTR1       ; Restore to memory
            LDX         PNTR2       ; Set up message pointer
            JSR         QDSET       ; Set quadrant contents in MSG
            LDAA        #$06        ; 
            ADDA        PNTR2+$1    ; Advance message pointer
            STAA        PNTR2+$1    ; Restore to memory
            CMPA        #MsgGalEnd+1; This end of line? (was $B4)
            BNE         GL2         ; No, set next quadrant 

            LDX         #MSGGAL     ; ( was $0080 )
            JSR         MSG         ; Print current line of galaxy
            LDAB        #$31        ; 
            JSR         NT1         ; Print border
            BRA         GL1         ; Set up next line

GL3         JMP         CMND        ; End, return to command input

 
; The shield routine transfers energy between the main energy 
; supply and the protective shields as designated by the operator. The 
; routine begins by requesting the operator to enter the amount of 
; energy to be transferred. The EIN routine is called to input the 
; energy from the input device. The input is then converted to its 
; binary value and the sign of the input is checked. If a minus sign was 
; entered preceeding the energy input, the energy is transferred from 
; the shield energy to the main energy storage. If only the four digits 
; are entered, the transfer of energy goes from the main supply to the 
; shields by jumping to the routine labeled POS. In either case, the 
; supply from which the energy is to be taken is checked to determine 
; whether there is enough energy for the transfer. If there is not 
; enough, a message is output to inform the operator, and the routine 
; returns to the command input routine. If there is sufficient energy, 
; the transfer will be completed and the program will return to the 
; command input routine. This routine begins at the label SHEN.

SHEN        LDX         #MSG21      ; Print SHIELD ENERGY 
            JSR         MSG         ;  TRANSFER =
            JSR         EIN         ; Input energy amount
            BMI         SHEN        ; Invalid input, try again 

            JSR         DCBN        ; Convert to binary
            LDX         STORE2      ; Transfer binary amount for
            STX         STORE1      ;  routines to follow 
            LDAA        DGT5TH      ; Test if have sign
            BEQ         POS         ; No, transfer main to shields
            JSR         CKSD        ; Check shield energy
            BCS         NE          ; Not enough, print message
            JSR         FMSD        ; Subtract from shields
            JSR         TOMN        ; Add to main
            BRA         SHEN1       ; Input new command

POS         JSR         CKMN        ; Check main energy
            BCS         NE          ; Not enough, display message
            JSR         FMMN        ; Subtract from main 
            JSR         TOSD        ; Add to shields 
            BRA         SHEN1       ; Input new command 

NE          LDX         #MSG22      ; Print NOT ENOUGH 
            JSR         MSG         ;  ENERGY 
SHEN1       JMP         CMND        ; Input new command 

;----

CRSE        LDX         #MSG13      ; Set pointer to course message
            JSR         MSG         ; Request course input
            JSR         DRCT        ; Input course direction
            BEQ         CRSE        ; Input error, try again

WRP         LDX         #MSG14      ; Index to WARP message
            JSR         MSG         ; Request warp input
            JSR         INPUT       ; Input warp factor digit 1
            CMPA        #'0         ; Is digit less than 0? (was $B0)
            BCS         WRP         ; Yes, request input again
            CMPA        #'8         ; Is digit greater than 7? (was $B8)
            BCC         WRP         ; Yes, try again
            ANDA        #$07        ; Mask off ASCII code
            ASLA                    ; Position to 3rd bit
            ASLA                    ; 
            ASLA                    ; 
            TAB                     ; Store temporarily in B
            LDAA        #$AE        ; Print decimal point
            JSR         PRINT       ; 
            JSR         INPUT       ; Input 2nd warp factor digit 
            CMPA        #'0         ; Is digit less than 0? (was $B0)
            BCS         WRP         ; Yes, request input again
            CMPA        #'8         ; Is input greater than 7? (was $B8)
            BCC         WRP         ; Yes, no good, try again
            ANDA        #$07        ; Mask off ASCII code
            ABA                     ; Add warp digit 1
            BEQ         WRP         ; If 0, no good, try again
            STAA        CNTR        ; Store warp factor as counter
            JSR         ACTV        ; Fetch adjusted row and column
            CLR         CI          ; Clear crossing indicator

MOV         JSR         TRK         ; Track one sector 
            BNE         MOV1        ; Out of galaxy? No 
            JMP         LOST        ; Yes, lost in space 

MOV1        LDAA        CF          ; No, quadrant crossed? 
            BEQ         CLSN        ; No, check for collision 
            STAA        CI          ; Make crossing indicator non-zero 
            LDX         #$1900      ; Delete 25 units of energy 
            STX         STORE1      ; 
            JSR         ELOM        ; From main supply 
            JSR         QCNT        ; Fetch new quadrant contents 
            JSR         NWQD        ; Set up new quadrant 

CLSN        JSR         RWCM        ; Form row and column byte 
            JSR         MATCH       ; Collision? 
            BNE         MVDN        ; No, complete move 
            JSR         COMPAR      ; What was hit? 
            BEQ         SSOUT       ; Space ship collision! 
            BCC         ASOUT       ; Alien ship collision! 
            LDAA        CI          ; Star, initial quadrant? 
            BNE         MVDN        ; No, ignore collision 
            JMP         WPOUT       ; Yes, ship wiped out! 

MVDN        DEC         CNTR        ; Decrement warp factor 
            BNE         MOV         ; Not zero, continue move 

            LDAA        CI          ; Fetch crossing indicator 
            BEQ         NOX         ; Quadrant not crossed, continue move 
            DEC         NSR         ; Decrement stardate counter 
            BNE         NOX         ; Not zero, continue 
            JMP         TIME        ; Ran out of time, start new game 

NOX         JSR         RWCM        ; Form row and column byte 
            STAA        SLOSS       ; Save new sector 
            JSR         MATCH       ; Was last move a collision? 
            BNE         NOX1        ; No, check for docking 
            JSR         CHNG        ; Yes, change object location 
    
NOX1        JSR         DKED        ; Check for docking 
            JMP         SRSCN       ; Do short range scan 

SSOUT       LDAA        CI          ; Test if initial quadrant 
            BNE         MVDN        ; No, no loss 
            JSR         DLET        ; Remove space station from galaxy 
            LDX         #MSG26      ; 
            JSR         MSG         ; Indicate loss of space station 
            LDX         #$5802      ; Then delete 600 units 
            STX         STORE1      ;  of energy from sheilds 
SSO1        JSR         ELOS        ; Delete energy 
            JMP         MVDN        ; Finish move 

ASOUT       LDAA        CI          ; Test if initial quadrant 
            BNE         MVDN        ; No, no loss 
            JSR         DLET        ; Yes, delete alien ship 
            LDX         #MSG24      ; 
            JSR         MSG         ; Print alien ship destroyed message 
            LDX         #$DC05      ; Delete 1500 units of 
            STX         STORE1      ;  
            BRA         SSO1        ;  energy from space ship 

CHNG        LDAB        #$01        ; Set number of objects counter 
            JMP         LOCSET      ; Move object and return 

DKED        LDAA        SLSS        ; Is space station in quadrant? 
            BPL         DKED1       ; Yes, continue 
            RTS                     ; No, complete move 

DKED1       ANDA        #$38        ; Mask out row 
            LDAB        SLOSS       ; Fetch space ship location 
            ANDB        #$38        ; Mask out row 
            CBA                     ; Same row? 
            BNE         DKED2       ; No, return 
            LDAA        SLSS        ; Fetch space station location 
            LDAB        SLOSS       ; Fetch space ship location 
            ADDB        #$01        ; 
            CBA                     ; Docked on right? 
            BEQ         DKED3       ; Yes, reload 
            SUBB        #$02        ; No, check left docking 
            CBA                     ; Docked on left? 
            BEQ         DKED3       ; Yes, reload 
DKED2       RTS                     ; No, return 
DKED3       JMP         LOAD        ; Reload space ship and return 


; The torpedo routine fires a torpedo in the direction specified by 
; the operator in an attempt to destroy an alien ship. This routine first 
; checks the number of torpedoes available. If there are no torpedoes 
; remaining, a message in output to inform the operator, and the routine
; returns to the command routine. If there is a torpedo available, 
; the torpedo count is decremented, and 250 units of energy are depleted
; from the main storage bank. The DRCT subroutine is then 
; called to input the direction of fire for the torpedo. The ACTV subroutine
; then sets the adjusted row and column values for tracking the torpedo. 
;
; Once the trajectory is set up, the torpedo is moved one sector at 
; a time, using the TRK subroutine. If the torpedo moves out of the 
; quadrant, it has missed its intended target and the alien ship retaliates
; by firing 200 units of phasor energy back at the space ship. 
; Otherwise, the sector location of the torpedo is output in the tracking
; message so that the operator can follow the torpedo’s path. The 
; MATCH subroutine checks for a collision after each sector 
; moved. If there is no collision at this sector, the torpedo will be 
; tracked another sector by returning to the TR2 label in this routine. 
; If an alien ship has been hit, it is removed from the galaxy. If it is 
; the last alien ship, the mission is complete, and the program begins a 
; new game. If a space station is hit, it is eliminated and the alien ship 
; will retaliate as mentioned above. If a star is hit, the torpedo has 
; missed its mark and the alien ship will again retaliate for the 
; attempted attack. The program then returns to the command input 
; routine.

TRPD        LDAA        NTR         ; Any torpedoes left? 
            BEQ         NTPD        ; No, print no torpedo message 
            DEC         NTR         ; Yes, delete one 
            LDX         #$FA00      ; Setup 250 units 
            STX         STORE1      ; Of energy to delete 
            JSR         CKMN        ; Enough in main supply? 
            BCC         TRPD1       ; Yes, continue 
            JMP         NE          ; No, report not enough energy 

TRPD1       JSR         FMMN        ; Delete from main 

TR1         LDX         #MSG23      ; 
            BSR         TR3         ; Print TORPEDO TRAJECTORY = 
            JSR         DRCT        ; Input direction 
            BEQ         TR1         ; Input invalid, try again 
            JSR         ACTV        ; Form adjusted row and column 
            LDAA        CQLSS       ; Save current quadrant 
            STAA        CNTR        ; Location in temporary storage 

TR2         JSR         TRK         ; Move torpedo one sector 
            BEQ         QOUT        ; Out of galaxy? Yes, missed 
            LDAA        CF          ; Quadrant crossed? 
            BNE         QOUT        ; Yes, missed 
            JSR         RWCM        ; 
            TAB                     ; No, form row and column byte 
            STAA        STORE1      ; Move to temporary storage 
            LDX         #Msg28a     ; Set up tracking message (was $041E)
            JSR         T1          ; Print TRACKING: R,C 
            LDX         #MSG28      ; Form message pointer 
            BSR         TR3         ; Print message 
            LDAA        STORE1      ; Fetch row and column byte
            JSR         MATCH       ; Torpedo hit anything?
            BEQ         HIT         ; Yes, analyze
            JMP         TR2         ; No, continue tracking

HIT         JSR         COMPAR      ; What was hit? A star?
            BCS         QOUT        ; Yes, missed alien ship 
            BEQ         SSTA        ; Space station? Yes, delete space station
            JSR         DLET        ; No, delete alien ship
            LDX         #MSG24      ; Print alien ship hit message
            BSR         TR3         ; 
            BRA         CMND1       ; Input new command
TR3         JMP         MSG         ; Print message and return 

SSTA        JSR         DLET        ; Delete space station from galaxy
            LDX         #MSG26      ; Print message of loss of
            BSR         TR3         ;  space station
 
QOUT        LDAA        CNTR        ; Restore current quadrant location
            STAA        CQLSS       ;  of the space ship
            JSR         WASTE       ; See if any alien ships in quadrant 
            LDX         #MSG25      ; No, print missed message
            JSR         MSG         ; 
            LDX         #$C800      ; Set up loss of 200 units of energy
            JSR         ELOS        ; Due to alien ship retaliating
            BRA         CMND1       ; Input new command

NTPD        LDX         #MSG35      ; 
            JSR         MSG         ; Print no torpedo message 
CMND1       JMP         CMND        ; Input new command 


; The phasor routine fires a designated amount of phasor energy at 
; the alien ships in the quadrant. The EIN subroutine is called to input 
; the energy to be fired. The amount of energy entered is then deleted 
; from the main storage bank. The number of alien ships in the immediate
; quadrant is then determined to calculate the amount of 
; energy to be fired at each. If there are no alien ships, a message is 
; output indicating the energy fired was wasted. The amount of phasor 
; energy to be fired at the alien ships is calculated and saved for use by 
; the ASPH subroutine. 
;
; The ASPH subroutine is called to fire the phasor at each of the 
; three possible alien ships in the quadrant. It first ascertains the 
; presence of the particular alien ship by looking for its row and 
; column location in the data table. If this location contains a CO, no 
; alien ship is located here and the routine simply returns. Otherwise, 
; this row and column location is output to inform the operator which 
; alien ship is about to be attacked. The distance between the space 
; ship and the alien ship, as defined in Chapter One, is then calculated 
; and the distance factor is used to determine how much of the phasor 
; energy actually reaches the alien ship. This energy is subtracted from 
; the alien ship’s shield energy, and if the result is zero or less, the alien 
; ship is destroyed. A message is output to inform the operator of its 
; destruction. If the alien ship is not destroyed, the new energy level of 
; the alien ship’s shields is output and, in retaliation, the alien ship 
; fires a phasor equal to one quarter of its shield energy at the space 
; ship. When the ASPH subroutine has completed its operation, it returns
; to the phasor routine. After all alien ships in the quadrant have 
; been fired upon, the phasor routine returns to the command input routine.

PHSR        LDX         #MSG30      ; Print ‘PHASOR ENERGY TO FIRE=’
            BSR         TR3         ; 
            JSR         EIN         ; Input energy amount
            BMI         PHSR        ; Input error? Try again
            JSR         DCBN        ; Convert decimal to binary
            LDX         STORE2      ; Move binary energy value to proper
            STX         STORE1      ; Storage for ELOM routine
            JSR         ELOM        ; Delete energy from main supply
            JSR         WASTE       ; Check for presence of alien ships
PHS1        JSR         ROTR4       ; Position alien ship number 
            SUBA        #$01        ; 1 alien ship, full energy
            BEQ         PH1         ; 2 alien ships, half energy
            TAB                     ; 3 alien ships, Vt energy
            JSR         DVD         ; Divide energy accordingly

PH1         LDX         STORE1      ; Fetch energy amount
            STX         STORE4      ; Save energy amount
            LDX         PVASE1      ; Fetch pointer to alien ship no. 1 energy
            STX         PNTR3       ; Save pointer for ASPH routine
            LDX         PSLAS1      ; Pointer to alien ship no. 1 position 
            JSR         ASPH        ; Fire phasor at alien ship no. 1
            LDX         PVASE2      ; Fetch pointer to alien ship no. 2 energy 
            STX         PNTR3       ; Save pointer for ASPH routine 
            LDX         PSLAS2      ; Pointer to alien ship no. 2 position 
            JSR         ASPH        ; Fire phasor at alien ship no. 2 
            LDX         PVASE3      ; Fetch pointer to alien ship no. 3 energy 
            STX         PNTR3       ; Save pointer for ASPH routine 
            LDX         PSLAS3      ; Pointer to alien ship no. 3 position 
            JSR         ASPH        ; Fire phasor at alien ship no. 3 
            BRA         CMND1       ; Input new command 

ASPH        STX         PNTR2       ; Save position pointer 
            LDAA        0,X         ; Fetch alien ship location 
            BPL         ASPH1       ; Any alien ship in location? 
            RTS                     ; No, return 
ASPH1       LDX         STORE4      ; Restore energy value 
            STX         STORE1      ; Move to temporary storage 
            LDX         #Msg31a     ; Set up pointers (was at $0465)
            STX         PNTR1       ; To fill in alien ship location 
            LDX         PNTR2       ;  in message 
            JSR         TWO         ; Set sector coordinates 
            LDX         #MSG31      ; 
            JSR         MSG         ; Print ’ALIEN SHIP AT SECTOR X,Y:’ 
            LDX         #SLOSS      ; Fetch sector location of the space ship 
            BSR         SPRC        ; Separate row and column values 
            STAA        STORE2      ; Save row of space ship 
            STAB        STORE2+$1   ; Save column of space ship 
            LDX         PNTR2       ; Fetch pointer to alien ship location 
            BSR         SPRC        ; Separate row and column values 
            SUBA        STORE2      ; Create row difference 
            BPL         PH2         ; Make absolute difference 
            NEGA                    ; By negating a negative value 

PH2         SUBB        STORE2+$1   ; Create column difference 
            BPL         PH3         ; Make absolute difference 
            NEGB                    ; By negating a negative value 
PH3         ABA                     ; Add absolute differences 
            LSRA                    ; Divide by 4 to 
            LSRA                    ;  form the distance factor 
            ANDA        #$03        ;   of energy to reach alien ship 
            TAB                     ; Store in B 
            BEQ         PH4         ; Make sure not zero 
            JSR         DVD         ; Calculate energy that reached alien ship 
    
PH4         LDX         PNTR3       ; Subtract from shield energy 
            JSR         FM1         ;  of alien ship 
            BMI         DSTR        ; If negative, alien ship is destroyed 
            BNE         ALOS        ; If non-zero, print alien ship energy 
            TST         0,X         ; Alien ship energy = 0? 
            BEQ         DSTR        ; Yes, remove from galaxy 
        
ALOS        LDAB        #$02        ; Set precision counter 
            JSR         BINDEC      ; Convert alien ship energy to decimal 
            LDX         #Msg32a+3   ; Set digits in message (was $0477)
            LDAB        #$04        ; Set number of digits counter
            JSR         DIGPRT      ; Put digits in message 
            LDX         #MSG32      ; Print energy of alien ship
            JSR         MSG         ; 
            LDX         PNTR3       ; Set pointer to alien ship energy
            LDAA        0,X         ; Transfer alien ship energy
            STAA        STORE1      ;  to STORE1 for calculating
            LDAA        $01,X       ;  
            STAA        STORE1+$01  ; Retaliation amount
            LDAB        #$02        ; Divide energy by 4 as
            JSR         DVD         ;  retaliation by alien ship
            LDX         STORE1      ; Place energy into index register
            JMP         ELOS        ; Remove from shield energy, return

DSTR        LDX         #$03CA      ; Print ‘DESTROYED’ 
            JSR         MSG         ; 
            LDX         PNTR2       ; Fetch alien ship location 
            JMP         DLET        ; Remove alien ship from galaxy, return 

SPRC        LDAA        0,X         ; Fetch row and column byte 
            TAB                     ; Save for column value 
            JSR         ROTR3       ; Position row to right 
            ANDA        #$07        ; Mask out row value 
            ANDB        #$07        ; Mask out column value 
            RTS                     ; Return 

;---

PATCH       BNE         PATCH1
            INX
            DEX
            RTS
PATCH1      JMP         MATCH2



;------------------------------------------
; I/O - System (h/w and monitor) specific
;------------------------------------------
; For CDC DEMON monitor SWI calls... (mostly in I/O stuff at end)
D_RESTART       EQU     $00     ; Reset Monitor (& Stack)
D_RD_BYTE       EQU     $01     ; Get char into A from ACIA
D_PR_BYTE       EQU     $04     ; Output char in A

            ORG     IOIF_BASE   ; Set address to match original listing

INPUT       SWI                 ; Call DEMON
            FCB     D_RD_BYTE   ; to read a char into A
            CMPA    #cCtrlC     ; Is it Control+C
            BEQ     USREXIT     ; Yes: QUIT back to monitor
            BSR     PRINT       ; Echo it
            RTS

;-------

PRINT       EQU     *
            SWI                 ; Call DEMON
            FCB     D_PR_BYTE   ; to print char in A
            RTS

;-------

; User-defined EXIT ( Note values from JSR to get here are on stack )...
USREXIT     SWI                   ; Call DEMON (resets stack )
            FCB       D_RESTART   ;  Go back to DEMON prompt
            RTS                   ; (should not get here !)

;----------------------------
;x Original code from book (for MIKBUG ?)...
;x INPUT   JSR      $E1AC 
;x         ORAA     #$80 
;x         RTS 
;x PRINT   PSHA 
;x         JSR     $E1D1 
;x         PULA 
;x         RTS 

;----------------------------
; and for USREXIT, this *should* work for all monitors...
;x USREXIT LDX     $FFFE        ; Load restart address
;x         JMP     0,X          ; Jump to it
;------------------------------------------
; The end
;------------------------------------------

