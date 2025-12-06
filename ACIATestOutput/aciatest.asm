DATAA   EQU     $F400   ; ACIA.A Data register
CTRLA   EQU     $F401   ; ACIA.A Ctrl/Status
DATAB   EQU     $F402   ; ACIA.B Data register
CTRLB   EQU     $F403   ; ACIA.B Ctrl/Status
DISPLAY EQU     $F0FF   ; LEDs

        ORG     $FF00

INIT    LDAA    #$03
        STAA    CTRLA
        LDAA    #$11
        STAA    CTRLA

START   INCA
        STAA    DISPLAY
LOOP    LDAB    CTRLA   ; get ACIA status
        BITB    #2      ; wait for TX buffer empty
        BEQ     LOOP

        STAA    DATAA   ; send char to port
        BRA     START   ; repeat

        ORG     $FFFE

        FDB     START

        END
