;------------------------------------------------------------------
; memtest_comprehensive.asm
;
; A comprehensive memory test for the MC6800.
;
; Tests included:
; 1. Data Bus Test (Walking 1s) - Checks for stuck bits or shorts.
; 2. Address Bus Test - Checks for address aliasing.
; 3. Pattern Test (Checkerboard) - Checks for cell interference (0x55, 0xAA).
;
; Requires MINIMON/JMON for I/O routines.
;
; Load and run from F000:
; G F000
;------------------------------------------------------------------

; MINIMON/JMON Variables (RAM)
T_STRT  EQU $F0EF ; Temp storage for GETADD (Start Address)
T_STOP  EQU $F0F1 ; Temp storage for GETADD (End Address + 1)
T_TEMP  EQU $F0D3 ; Use T_TEMP from JMON area

; MINIMON/JMON routines (ROM)
STRING  EQU $FC76 ; Prints a string following JSR, ends with $FF.
GETADD  EQU $FC89 ; Prompt for "S <addr> F <addr>"
ZOUT    EQU $FCC9 ; Print value in A as 2 hex digits.
PRX     EQU $FCBB ; Print value in X as 4 hex digits.
PRSP    EQU $FD4D ; Print a space.
NEWLINE EQU $FE97 ; Prints a new line.
START   EQU $FF8F ; Restarts Monitor.

        ORG $F000

MAIN    JSR     STRING
        FCB     $0D, $0A
        FCC     "MEMTEST V2"
        FCB     $0D, $0A, $FF
        
        JSR     GETADD      ; Get start and finish addresses
        
        ; 1. Data Bus Test (at T_STRT address)
        JSR     STRING
        FCB     $0D, $0A
        FCC     "D:"
        FCB     $FF

        LDX     T_STRT
        LDAA    #$01        ; Start with bit 0
.DATALP STAA    0,X         ; Write pattern
        CMPA    0,X         ; Read back
        BNE     .D_ERR      ; Failed
        ASLA                ; Shift to next bit
        BNE     .DATALP     ; Loop until all 8 bits tested
        JSR     PROK

        ; 2. Address Bus Test
        JSR     STRING
        FCC     "A:"
        FCB     $FF
        
        ; Fill memory with its own low-byte address
        LDX     T_STRT
.ADRFL  STX     T_TEMP      ; X -> RAM (Big Endian: T_TEMP=High, T_TEMP+1=Low)
        LDAA    T_TEMP+1    ; Get low byte of address
        STAA    0,X         ; Store low byte of address at that address
        INX
        CPX     T_STOP
        BNE     .ADRFL
        
        ; Verify
        LDX     T_STRT
.ADRVF  STX     T_TEMP
        LDAA    T_TEMP+1    ; Expected
        CMPA    0,X
        BNE     .A_ERR
        INX
        CPX     T_STOP
        BNE     .ADRVF
        JSR     PROK

        ; 3. Checkerboard Test (0x55 then 0xAA)
        JSR     STRING
        FCC     "C:"
        FCB     $FF
        
        LDAA    #$55        ; First pattern
        BSR     DO_PATT
        BCS     .C_ERR
        
        LDAA    #$AA        ; Second pattern
        BSR     DO_PATT
        BCS     .C_ERR
        
        JSR     PROK

        JMP     START

; --- Error Handlers ---

.D_ERR
        ;JSR     STRING
        ;FCC     "FAIL AT "
        ;FCB     $FF
        ;BRA     SHOW_ERR

.A_ERR
        ;JSR     STRING
        ;FCC     "FAIL AT "
        ;FCB     $FF
        ;BRA     SHOW_ERR

.C_ERR
        ;JSR     STRING
        ;FCC     "FAIL AT "
        ;FCB     $FF
        ; fall through

SHOW_ERR
        JSR     PRX         ; Print address in X
        JSR     PRSP
        LDAA    0,X         ; Get actual value
        JSR     ZOUT        ; Print it
        JMP     START

; --- Subroutines ---

; DO_PATT: Fill memory with A, then verify. 
; Returns C=1 on failure, X=failure address.
DO_PATT TAB                 ; Save pattern in B
        LDX     T_STRT
.P_FILL STAA    0,X
        INX
        CPX     T_STOP
        BNE     .P_FILL
        
        LDX     T_STRT
.P_VERI CMPB    0,X         ; Compare with pattern in B
        BNE     .P_FAIL
        INX
        CPX     T_STOP
        BNE     .P_VERI
        CLC                 ; Success
        RTS
.P_FAIL SEC                 ; Failure
        RTS

PROK    JSR     STRING
        FCC     "OK "
        FCB     $FF
        RTS
