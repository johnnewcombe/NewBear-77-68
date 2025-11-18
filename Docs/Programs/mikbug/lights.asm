; ------------------------------------------------------
       NAM    LIGHTS
; ------------------------------------------------------
; CDC 08-Mar-2018 :-
;
; Playing with the 77/68 switches and lights
;
; ------------------------------------------------------
;
; ------------------------------------------------------
; Some name prefixes
;
; O_ = ORG
; M_ = MIKBUG
; H_ = Hardware addresses
; S_ = Sproggy routines
; D_ = Data (RAM)
; c  = Constants
; 
;
; ------------------------------------------------------
; - ORG addresses...
; ------------------
O_ROM   EQU     $F400   ; Base of ROM in 77/68 (NT)
O_RAM   EQU     $0000   ; Base of RAM in 77/68 (NT)

; ------------------------------------------------------
; Hardware
;
H_PANEL EQU     $F0FF   ; Switches / Lights

; ------------------------------------------------------
; MIKBUG Routine addresses for interaction with MIKBUG
;
M_START  EQU    $FED0


; ------------------------------------------------------
; ------------------------------------------------------
        ORG     O_ROM   ; ROM code
; ------------------------------------------------------

S_START EQU     *
        STAA    SAVE_A
        STAB    SAVE_B

        LDAB    #$FFFF  ; Send all-off
        STAB    H_PANEL ; to the lights
        
Main    EQU     *
        LDAB    H_PANEL ; Get switches
        STAB    H_PANEL ; Put on to lights
        CMPB    #05     ; 00000101 on switches = return to monitor
        BEQ     Quit
        BMI     Main    ; Keep looping

Quit    EQU     *
        CLRB            ; Turn off...
        STAB    H_PANEL ; ...the lights

        LDAB    SAVE_B
        LDAA    SAVE_A 
        RTS

; ------------------------------------------------------
; ------------------------------------------------------
        ORG     O_RAM
; ------------------------------------------------------

        JMP     S_START ; So program can be started by 
                        ; jumping to $0000
;
; Data...
;
SAVE_A  FCB     1
SAVE_B  FCB     1
        END    
