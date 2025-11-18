;------------------------------------------------------------------------
; TUNER / miTunes
; BASED ON SOFTWARE IN 7768 CONSTRUCTION MANUAL
;
; Modified to run under DEMON monitor,
; using SWI to call DEMON routines
; -----------------------------------------------------------------------
; DJC & CDC : Carter brothers 2018  :  www.cmas-net.co.uk/vintage
;------------------------------------------------------------------------

; SWI equivalent...
CALL_DEMON    EQU     $3F  ; Define SWI instruction

; DEMON SWI $nn call function codes
D_RESET     EQU     $00     ; Reset monitor
D_PR_HEX2   EQU     $09     ; O/P 2hex char value from A
D_PR_HEX4   EQU     $0A     ; O/P 4hex char value from X
D_PRINT_STR EQU     $06     ; Print string following SWI $06

C_EOS   EQU     $00     ; End-Of-String
C_CR    EQU     $0D     ; Carriage Return
C_LF    EQU     $0A     ; Line Feed

; Notes:-
;
; Demon is called via SWI, with the byte following
; containing a function code to identify which
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
; eg: FCB  CALL_DEMON,D_PR_HEX2  ; to print char from A as 2 hex chars
;
;------------------------------------------------------------------------

H_PANEL EQU     $F0FF   ; Switches / Lights

;------------------------------------------------------------------------

O_CODE  EQU     $0100   ; Address to place program
O_RAM   EQU     $0000   ; Address for variables

;------------------------------------------------------------------------
        ORG     O_CODE

START   EQU     *
        STS     SAVES       ; Save stack ptr

        SWI                 ; Call DEMON...
        FCB     D_PRINT_STR
        FCB     C_CR,C_LF
        FCC     "miTunes program:"
        FCB     C_CR,C_LF
        FCC     "Select tune(s) via low 4 switches:-"
        FCB     C_CR,C_LF
        FCC     "[1] = Colonel Bogie"
        FCB     C_CR,C_LF
        FCC     "[2] = I'm forever blowing bubbles"
        FCB     C_CR,C_LF
        FCC     "[4] = Greensleeves"
        FCB     C_CR,C_LF
        FCC     "[8] = Auld Lang Syne"
        FCB     C_CR,C_LF
        FCC     "Turn LEFTMOST data switch on to repeat "
        FCB     C_CR,C_LF
        FCC     "Turn ALL data switches off to quit "
        FCB     C_CR,C_LF
        FCB     C_EOS

RESTART EQU     *
        LDAB    H_PANEL     ; Get switches
        STAB    H_PANEL     ; Write to LEDs
        LDX     #LIST       ; X = Start of tune list
        STX     TUNEADDR    ; Save tune address
        LDAA    #$01        ; Start with tune.1
        STAA    TUNEID      ; Save tune number

CHKLIST EQU     *

        LDX     0,X         ; X = Start of tune
        BEQ     ENDED       ; If zero, end of list
        LDAB    H_PANEL     ; Read switches
        BITB    TUNEID      ; Compare swtiches with tune ID
        BEQ     NXTLIST     ; Not wanted, go to next in list
        BRA     DOTUNE      ; Play the tune

NXTLIST EQU     *
        LDAA    TUNEID      : Get last tune ID
        ASLA                ; Move up to next bit value
        STAA    TUNEID      ; Save it
        LDX     TUNEADDR    ; Get address of last tune list item
        INX                 ; Add 1  \ Move to next
        INX                 ; Add 1  /  in list
        STX     TUNEADDR    ; Save tune address
        BRA     CHKLIST

ENDED   EQU     *
        LDAB    H_PANEL     ; Read switches
        BITB    #$80        ; If left switch is ON, then loop
        BNE     RESTART     ; If not zero - restart
                            ; Otherwise, bit is set so QUIT...
DONE    EQU     *
        LDS     SAVES       ; Restore stack pointer
        SWI                 ; Call DEMON...
        FCB     D_RESET     ;  Go back to DEMON

DOTUNE  CLR     H_PANEL     ; Turn all lights off
        DEX                 ; Subtract 1 from X
        DEX                 ; Subtract 1 from X

NUNOTE  INX                 ; Add 1 to X \_/  point to
        INX                 ; Add 1 to X / \  next note
        LDAA    0,X         ; Load length of note
        BEQ     NXTLIST     ; If zero, end of this tune
        STAA    TIME        ; Store duration
        CLRA                ; A = 0
NUCYCLE LDAB    1,X         ; Get frequency
        BEQ     QUIET       ; If zero:- Quiet

;----                       ; Toggle low bit of data register...
        INS                 ; Increment Stack ptr ( using it as data only )
        STS     H_PANEL-1   ; Store it so low byte goes on lights
;----

CYCLE   DECA                ; \  Next
        BNE     FREQ        ;  \  note if
        DEC     TIME        ;  /   time has
        BEQ     NUNOTE      ; /     run out
FREQ    DECB                ; \ End of
        BNE     CYCLE       ;  > half
        BRA     NUCYCLE     ; /   cycle

QUIET   LDAB    H_PANEL     ; Read switches   : 4 cycles
        BEQ     DONE        ; Quit if all OFF : 2 cycles

QCYCL   NOP                 ; NOP= 2 cycles
        NOP
        NOP
        DECA
        BNE     QCYCL
        DEC     TIME
        BEQ     NUNOTE      ; End of silent item
        BRA     QCYCL

LIST    EQU     *           ; List of tunes
        FDB     BOGIE       ; [01] Colonel Bogie
        FDB     BUBBLES     ; [02] I'm forever blowing bubbles
        FDB     GRNSLV      ; [04] Greensleeves
        FDB     AULD        ; [08] Auld Lang Syne
        FDB     NUTUNE1     ; [10] ?
        FDB     NUTUNE2     ; [20] ?
        FDB     #$0000      ; End List

BOGIE   EQU     *                   ; Colonel Bogie
        FCB     $20,$42,$20,$51
        FCB     $60,$00,$20,$51
        FCB     $20,$4B,$20,$42
        FCB     $20,$27,$20,$00
        FCB     $20,$27,$20,$00
        FCB     $58,$31,$08,$00
        FCB     $20,$42,$20,$51
        FCB     $60,$00,$20,$51
        FCB     $20,$4B,$20,$51
        FCB     $20,$42,$20,$00
        FCB     $20,$42,$20,$00
        FCB     $58,$4B,$08,$00
        FCB     $20,$4B,$20,$59
        FCB     $60,$00,$20,$3B
        FCB     $20,$34,$20,$3B
        FCB     $20,$31,$20,$42
        FCB     $60,$00,$20,$42
        FCB     $20,$4B,$20,$51
        FCB     $20,$59,$20,$3B
        FCB     $20,$00,$20,$64
        FCB     $20,$6A,$20,$42
        FCB     $20,$00,$20,$42
        FCB     $FF,$64,$FF,$00
        FCB     $00,$00             ; End Tune

BUBBLES EQU     *
        FCB     $60,$86,$20,$77
        FCB     $20,$86,$20,$8E
        FCB     $80,$97,$40,$77
        FCB     $40,$86,$FF,$64
        FCB     $41,$00,$60,$64
        FCB     $20,$59,$20,$64
        FCB     $20,$6A,$80,$64
;xCut   FCB     $40,$77,$C0,$86     ;x Correction to published notes
        FCB     $40,$77             ;< One $C0,$86 removed
        FCB     $C0,$86,$40,$77
        FCB     $60,$64,$20,$77
        FCB     $C0,$86,$20,$77
        FCB     $20,$6A,$40,$64
        FCB     $40,$77,$C0,$86
        FCB     $40,$8E,$40,$77
        FCB     $40,$6A,$80,$64
        FCB     $40,$77,$80,$6A
        FCB     $40,$64,$20,$59
        FCB     $20,$B4,$20,$97
        FCB     $20,$86,$20,$6A
        FCB     $20,$59,$80,$50
        FCB     $40,$55,$80,$50
        FCB     $40,$64,$40,$59
        FCB     $E0,$6A,$20,$A0
        FCB     $20,$7E,$20,$6A
        FCB     $80,$64,$40,$59
        FCB     $80,$64,$40,$77
        FCB     $E0,$6A,$40,$77
        FCB     $40,$7E,$60,$86
        FCB     $20,$77,$20,$86
        FCB     $20,$8E,$80,$97
        FCB     $40,$77,$40,$86
        FCB     $C0,$64,$40,$6A
        FCB     $40,$64,$40,$50
        FCB     $80,$59,$80,$77
        FCB     $40,$6A,$FF,$64
        FCB     $FF,$00
        FCB     $00,$00             ; End Tune

GRNSLV  EQU     *                   ; Greensleeves
        FCB     $40,$74,$80,$61
        FCB     $40,$57,$60,$4D
        FCB     $20,$49,$40,$4D
        FCB     $80,$57,$40,$67
        FCB     $60,$83,$20,$74
        FCB     $40,$67,$80,$61
        FCB     $30,$74,$10,$00
        FCB     $60,$74,$20,$7B
        FCB     $40,$74,$80,$67
        FCB     $40,$7B,$80,$9C
        FCB     $40,$74,$80,$61
        FCB     $40,$57,$60,$4D
        FCB     $20,$49,$40,$4D
        FCB     $80,$57,$40,$67
        FCB     $60,$83,$20,$74
        FCB     $40,$67,$60,$61
        FCB     $20,$67,$40,$74
        FCB     $60,$7B,$20,$8B
        FCB     $40,$7B,$B0,$74
        FCB     $10,$00,$FF,$74
        FCB     $B0,$40,$10,$00
        FCB     $60,$40,$20,$44
        FCB     $40,$4D,$80,$57
        FCB     $40,$67,$60,$83
        FCB     $20,$74,$40,$67
        FCB     $80,$61,$30,$74
        FCB     $10,$00,$60,$74
        FCB     $20,$7B,$40,$74
        FCB     $80,$67,$40,$7B
        FCB     $C0,$9C,$B0,$40
        FCB     $10,$00,$60,$40
        FCB     $20,$44,$40,$4D
        FCB     $80,$57,$40,$67
        FCB     $60,$83,$20,$74
        FCB     $40,$67,$60,$61
        FCB     $20,$67,$40,$74
        FCB     $60,$7B,$20,$8B
        FCB     $40,$7B,$B0,$74
        FCB     $10,$00,$FF,$74
        FCB     $FF,$00
        FCB     $00,$00             ; End Tune

AULD    EQU     *                   ; Auld Lang Syne
        FCB     $60,$CA,$78,$97
        FCB     $08,$00,$30,$97
        FCB     $08,$00,$60,$97
        FCB     $60,$77,$78,$86
        FCB     $30,$77,$60,$86
        FCB     $60,$77,$30,$97
        FCB     $08,$00,$78,$97
        FCB     $60,$77,$60,$64
        FCB     $D8,$59,$08,$00
        FCB     $60,$59,$78,$64
        FCB     $30,$77,$08,$00
        FCB     $60,$77,$60,$97
        FCB     $78,$86,$30,$97
        FCB     $60,$86,$60,$77
        FCB     $78,$97,$30,$B4
        FCB     $08,$00,$60,$B4
        FCB     $60,$CA,$D8,$97
        FCB     $60,$59,$78,$64
        FCB     $30,$77,$08,$00
        FCB     $60,$77,$60,$97
        FCB     $78,$86,$30,$97
        FCB     $60,$86,$60,$59
        FCB     $78,$64,$30,$77
        FCB     $08,$00,$60,$77
        FCB     $60,$64,$D8,$59
        FCB     $60,$4B,$78,$64
        FCB     $30,$77,$08,$00
        FCB     $60,$77,$60,$97
        FCB     $78,$86,$30,$97
        FCB     $60,$86,$30,$77
        FCB     $30,$86,$78,$97
        FCB     $30,$B4,$08,$00
        FCB     $60,$B4,$60,$CA
        FCB     $D8,$97,$60,$59
        FCB     $78,$64,$30,$77
        FCB     $08,$00,$60,$77
        FCB     $60,$97,$78,$86
        FCB     $30,$97,$60,$86
        FCB     $60,$59,$78,$64
        FCB     $30,$77,$08,$00
        FCB     $60,$77,$60,$64
        FCB     $D8,$59,$60,$4B
        FCB     $78,$64,$30,$77
        FCB     $08,$00,$60,$77
        FCB     $60,$97,$78,$86
        FCB     $30,$97,$60,$86
        FCB     $30,$77,$30,$86
        FCB     $78,$97,$30,$B4
        FCB     $08,$00,$60,$B4
        FCB     $60,$CA,$D8,$97
        FCB     $FF,$00
        FCB     $00,$00             ; End Tune

NUTUNE1 EQU     *
        FCB     $30,$93,$30,$83,$30,$74,$30,$61
        FCB     $20,$6E,$10,$00,$30,$6E,$30,$57
        FCB     $20,$61,$10,$00,$30,$61,$30,$49
        FCB     $30,$4D,$30,$49,$30,$61,$30,$74
        FCB     $30,$93,$30,$83,$30,$74,$30,$6E
        FCB     $30,$61,$30,$57,$30,$61,$30,$6E
        FCB     $30,$74,$30,$83,$30,$74,$30,$93
        FCB     $30,$9C,$30,$93,$30,$83,$30,$C5
        FCB     $30,$9C,$30,$83,$30,$6E,$30,$74
        FCB     $30,$83,$30,$74,$30,$93,$30,$83
        FCB     $30,$74,$30,$61,$20,$6E,$10,$00
        FCB     $30,$6E,$30,$57,$20,$61,$10,$00
        FCB     $30,$61,$30,$49,$30,$4D,$30,$49
        FCB     $30,$61,$30,$74,$30,$93,$30,$83
        FCB     $30,$74,$30,$AF,$30,$61,$30,$6E
        FCB     $30,$74,$30,$83,$30,$93,$30,$C5
        FCB     $30,$93,$30,$9C,$30,$93,$30,$74
        FCB     $30,$61,$30,$49,$30,$61,$30,$74
        FCB     $30,$93,$30,$74,$30,$6E,$30,$61
        FCB     $10,$00,$30,$61,$30,$6E,$30,$74
        FCB     $30,$83,$30,$C5,$30,$AF,$30,$9C
        FCB     $30,$83,$30,$93,$30,$83,$30,$6E
        FCB     $30,$74,$30,$6E,$30,$83,$30,$9C
        FCB     $30,$C5,$30,$9C,$30,$83,$30,$6E
        FCB     $30,$74,$30,$83,$30,$74,$80,$64
        FCB     $FF,$00
        FCB     $00,$00             ; End Tune

NUTUNE2 EQU     *
        FCB     $20,$50,$20,$42,$20,$59,$20,$42
        FCB     $20,$64,$20,$42,$20,$6A,$20,$86
        FCB     $20,$8E,$20,$86,$20,$77,$20,$86
        FCB     $20,$8E,$20,$86,$20,$6A,$20,$42
        FCB     $20,$4B,$20,$42,$20,$50,$20,$42
        FCB     $20,$59,$20,$42,$20,$64,$20,$86
        FCB     $20,$8E,$20,$86,$20,$77,$20,$86
        FCB     $20,$8E,$20,$86,$20,$64,$20,$77
        FCB     $20,$86,$20,$A0,$20,$CA,$20,$A0
        FCB     $20,$86,$20,$64,$FF,$6A,$21,$6A
        FCB     $20,$77,$20,$97,$20,$B4,$20,$D6
        FCB     $20,$B4,$20,$97,$20,$77,$FF,$86
        FCB     $41,$86,$20,$50,$20,$42,$20,$59
        FCB     $20,$42,$20,$64,$20,$42,$20,$6A
        FCB     $20,$86,$20,$8E,$20,$86,$20,$77
        FCB     $20,$86,$20,$8E,$20,$86,$20,$6A
        FCB     $20,$50,$20,$59,$20,$50,$20,$64
        FCB     $20,$50,$20,$6A,$20,$50,$20,$77
        FCB     $20,$50,$20,$55,$20,$50,$20,$4B
        FCB     $20,$50,$20,$59,$20,$50,$30,$64
        FCB     $FF,$00
        FCB     $00,$00             ; End Tune

;------------------------------------------------------------------------
            ORG     O_RAM

TIME        RMB     1   ; Duration
TUNEID      RMB     1   ; Tune number we are checking
TUNEADDR    RMB     2   ; Addr of current tune in list
SAVES       RMB     2   ; Incoming stack

            END


