***************************************************************
*        LOONY LANDER - By J.A.Diamond
*    NewBear Computing Store 2nd&3rd Newsletter April 1978
*    Adapted - from single board (8 Bit addressing)
*            - To developed 7768 (16 bit addressing)
*                   By T.MEISTER
*
***************************************************************
; Modified to run under DEMON monitor,
; using SWI to call DEMON routines
; -----------------------------------------------------------------------
; DJC & CDC : Carter brothers 2018  :  www.cmas-net.co.uk/vintage
;------------------------------------------------------------------------

; SWI equivalent...
CALL_DEMON    EQU     $3F  ; Define SWI instruction

; DEMON SWI $nn call function codes
D_RESET       EQU     $00 * Reset monitor
D_RD_BYTE     EQU     $01 * Get char into A from ACIA
D_RD_BYTE_TST EQU     $02 * Get char, test for . + LEDs
D_RD_PR_BYT   EQU     $03 * Get char into A from ACIA and output it
D_PR_BYTE     EQU     $04 * Output char in A
D_PR_FROM_X   EQU     $05 * Print string pointed to by X
D_PR_STRING   EQU     $06 * Print string following SWI $06
D_RD_HEX2     EQU     $07 * Read 2hex char value into A
D_RD_HEX4     EQU     $08 * Read 4hex char value into X
D_PR_HEX2     EQU     $09 * O/P 2hex char value from A
D_PR_HEX4     EQU     $0A * O/P 4hex char value from X
D_PR_STK      EQU     $0B * Print data put on stack by SWI
D_PR_REPEAT   EQU     $0C * Print char in A no. of times in B
D_PR_SPACE    EQU     $0D * Print a space
D_PR_AND_SP   EQU     $0E * Print char in A then a space


C_EOS   EQU     $00     ; End-Of-String
C_CR    EQU     $0D     ; Carriage Return
C_LF    EQU     $0A     ; Line Feed

; Notes:-
;
; Demon is called via SWI, with the byte following
; containing a function code to identify which
; subroutine to call, like:-
;
;   FCB CALL_DEMON      ; SWI to get to Demon
;   FCB D_PR_HEX2       ; Func.code to print char from A as 2 hex chars
;
; Another way to arrange the `call` is to use the SWI
; machine code instruction value and the function code
; in *one* FCB statement, like:-
;
; CALL_DEMON EQU $3F  ; Define SWI instruction (as above )
;
; eg: FCB  CALL_DEMON,D_PR_HEX2  ; to print char from A as 2 hex chars
;
;------------------------------------------------------------------------

H_PANEL EQU     $F0FF   ; Switches / Lights

O_RAM   EQU     $0000   ; Start of workspace
O_CODE  EQU     $0100   ; Code start address

;------------------------------------------------------------------------
; Starting values       ; Set at original defaults
C_FUEL  EQU     $1000
C_HGHT  EQU     $8000
C_VELO  EQU     $8000

C_DELAY EQU     $FF     ; Time in loop for height display
;------------------------------------------------------------------------

   *DEFINE DISPLAY AND TEMP. STORAGE

DISPLAY EQU     H_PANEL

        ORG     O_RAM

FUEL    RMB     2
HEIGHT  RMB     2
VELOSTY RMB     2


   * MAIN PROGRAM *

        ORG     O_CODE

RESTART EQU     *

        LDX     #C_FUEL     ; Reset
        STX     FUEL        ;  the start point
        LDX     #C_HGHT     ;   fuel,
        STX     HEIGHT      ;    height and
        LDX     #C_VELO     ;     velocity
        STX     VELOSTY     ;      values


        LDX     #M_MSG      ; Startup message
        FCB     CALL_DEMON
        FCB     D_PR_FROM_X

NULOOP  LDAA    DISPLAY     ; Get data switch settings into A
        ANDA    #$01        ; Mask off all but rightmost switch
        BEQ     NOTHR       * IS ROCKET ENGINE ON or OFF ?
        TST     FUEL        * IF ON TEST FOR REMAINING FUEL
        BNE     THRUST
        TST     FUEL+1
        BNE     THRUST
NOTHR   LDX     VELOSTY     * IF THE ENGINE IS OFF
        INX                 * INCREMENT VELOCITY
        STX     VELOSTY
        BRA     MODH

THRUST  LDX     FUEL        * IF THE ENGINE IS ON
        DEX                    * DECREMENT FUEL
        STX     FUEL

        LDX     VELOSTY
        DEX                 * DECREMENT VELOCITY
        STX     VELOSTY
MODH    LDAB    VELOSTY
        SUBB    #$80        * EXPOSE TRUE VELOCITY
        BCC     PLUS        * USE DIFFERENT ROUTINE FOR +ve
        NEGB                * AND -ve VELOCITY
        ADDB    HEIGHT+1    * IF -ve ADD VELOCITY TO HEIGHT
        STAB    HEIGHT+1    * AFTER TAKING 2's COMPLEMENT
        BCC     JUMP
        INC     HEIGHT
JUMP    BRA     DISPH

PLUS    LDAA    HEIGHT+1    * IF +ve SUBTRACT VELOCITY FROM
        SBA                 * HEIGHT
        STAA    HEIGHT+1
        BCC     DISPH
        DEC     HEIGHT
        BEQ     END         * IF IT HAS LANDED GO TO THE END
DISPH   LDAA    HEIGHT      * IF IT HAS NOT LANDED, DISPLAY
        STAA    DISPLAY     * MOST SIGNIFICANT HEIGHT
        LDAA    #$FF        * VARIABLE TIME DELAY
DELAY   DECA                * SUGGESTION    #$FF
        BNE     DELAY
        BRA     NULOOP

RESTRTa BRA     RESTART     ; Cascade BRAs to avoid JMPs

END     LDAA    VELOSTY     * IF YOU HAVE LANDED SLOWLY
        CMPA    #$83        * FLASH REMAINING FUEL
        BCC     CRASH
        LDAA    FUEL
CLOOP   STAA    DISPLAY     * DISPLAY REMAINING FUEL

        FCB     CALL_DEMON
        FCB     D_PR_STRING
        FCB     C_CR,C_LF
        FCC     "Landed OK ! ... Remaining fuel: "
        FCB     C_EOS

        FCB     CALL_DEMON  ; A contains FUEL
        FCB     D_PR_HEX2

        FCB     CALL_DEMON
        FCB     D_PR_STRING
        FCB     C_CR,C_LF,C_EOS

WAITUI  FCB     CALL_DEMON
        FCB     D_PR_STRING
        FCB     C_CR,C_LF
        FCC     "Toggle any switch to start again "
        FCB     C_CR,C_LF,C_EOS

        LDAB    DISPLAY     ; Get switches into B
WAITSW  LDAA    DISPLAY     ; Get switches into A
        CBA                 ; Compare A and B
        BEQ     WAITSW      ; If same, keep waiting
        BRA     RESTRTa     ; Not same - restart

CRASH   LDAA    VELOSTY
        SUBA    #$80
        STAA    DISPLAY     * IF YOU HAVE CRASHED, DISPLAY

        FCB     CALL_DEMON
        FCB     D_PR_STRING
        FCB     C_CR,C_LF
        FCC     "#CRASH#  ... Speed: "
        FCB     C_EOS

        FCB     CALL_DEMON
        FCB     D_PR_HEX2    ; A contains Velocity

        FCB     CALL_DEMON
        FCB     D_PR_STRING
        FCB     C_CR,C_LF,C_EOS
        BRA     WAITUI

M_MSG   EQU     *           ; Start message...
        FCB     C_CR,C_LF
        FCC     "Loony Lander:"
        FCB     C_CR,C_LF
        FCC     "The object is to land an imaginary craft on the Moon"
        FCB     C_CR,C_LF
        FCC     "without crashing and using as little fuel as possible."
        FCB     C_CR,C_LF
        FCC     "The ONLY control you have is the right-most data switch:-"
        FCB     C_CR,C_LF
        FCC     " ON = Engine ON  : You are slowing your fall or ascending faster"
        FCB     C_CR,C_LF
        FCC     "OFF = Engine OFF : You are slowing your ascent or falling faster !"
        FCB     C_CR,C_LF,C_LF
        FCC     "You crash if you hit the moon at more 3 or more units of velocity"
        FCB     C_CR,C_LF,C_EOS

; The end
