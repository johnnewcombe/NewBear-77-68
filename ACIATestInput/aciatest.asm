DATAA   EQU     $F400   ; ACIA.A Data register
CTRLA   EQU     $F401   ; ACIA.A Ctrl/Status
DATAB   EQU     $F402   ; ACIA.B Data register
CTRLB   EQU     $F403   ; ACIA.B Ctrl/Status
DISPLAY EQU     $F0FF   ; LEDs

        ORG     $FF00

INIT    LDAA    #$03    ; reset ACIA
        STAA    CTRLA   ;
        LDAA    #$11    ; Set for 8N2
        STAA    CTRLA   ;

        STAA    DISPLAY ; will display $11 first time around and indicate that the software is running

LOOP    LDAB    CTRLA   ; get ACIA status
        BITB    #$01    ; wait for RX buffer full
        BEQ     LOOP    ; nothing there yet
        LDAA    DATAA   ; load char from port
        STAA    DISPLAY ; display the value retrieved
        BRA     LOOP    ; repeat

        ORG     $FFFE
        FDB     INIT

        END
