

CTRLA   EQU     $F401   ; ACIA.A Ctrl/Status
CTRLB   EQU     $F403   ; ACIA.B Ctrl/Status
DATAA   EQU     $F400   ; ACIA.A Data register
DATAB   EQU     $F402   ; ACIA.B Data register

        ORG     $F000

        LDAA    #'@'    ; load A with a char
LOOP    LDAB    CTRLA   ; get ACIA status
        BITB    #2      ; wait for TX buffer empty
        BEQ     LOOP
        STAA    DATAA   ; send char to port
        BRA     LOOP    ; repeat

        END
