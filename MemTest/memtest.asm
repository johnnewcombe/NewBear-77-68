;------------------------------------------------------------------
; MemTest.asm
; MemTest from MON1 documentation updated to run from F000.
;
; MINIMON is required.
;
; Load and run from F000, e.g.
;
;
; MINIMON Variables
T_STRT  EQU $F0EF ; Temp storage for GETADDRESS
T_STOP  EQU $F0F1 ; Temp storage for GETADDRESS

; 7768 ACIA(a)
CTRLA   EQU $F401 ; ACIA.A Ctrl/Status
DATAA   EQU $F400 ; ACIA.A Data register

; MINIMON routines
STRING  EQU $FC76 ; Prints a string. The string should follow JSR and be terminated with $FF.
GETADD  EQU $FC89 ; Get Address, read 4 digit hex value.
ZOUT    EQU $FCC9 ; Print value in A as 2 hex digits.
NEWLINE EQU $FE97 ; Prints a new line.
START   EQU $FF8F ; Restarts MniMon.

	    ORG $F000

MEMTEST JSR     STRING
        FCC     "MEMTEST"
        FCB     $0D, $0A,$FF
        JSR     GETADD      ; get the start and finish addresses
        JSR     STRING
        FCC     " TESTING..."
        FCB     $FF
        CLRB                ; set up accumulators
.TST    TBA
        LDX     T_STRT      ; put start address in X
        CLRA
.LOOP1  ABA                 ; create the pattern
        STAA    0,X         ; Write to memory
        INX
        CPX     T_STOP      ; Check for end of memory
        BNE     .LOOP1
        LDX     T_STRT
        CLRA
.LOOP2  ABA
        CMPA     0,X        ; Read from memory
        BNE     .FAULT
.NOPR   INX
        CPX     T_STOP
        BNE     .LOOP2
        LDAA    CTRLA       ; Read ACIA status
        BITA    #$01        ; Key waiting?
        BNE     .END        ; Yes so end the test
        INCB                ; change the pattern and repeat
        BNE     .TST        ; we loop the test 256 times
.END    LDAA    DATAA       ; Clear a byte from ACIA
        JSR     STRING
        FCC     " OK"
        FCB     $FF
        JMP     START
.FAULT  JSR     NEWLINE
        JSR     STRING
        FCC     " FLT"
        FCB     $FF
        JMP     START
