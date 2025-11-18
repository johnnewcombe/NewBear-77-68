; ---------------------------------------------------------------
; DEMON v4 CDC June 2018
; ---------------------------------------------------------------
; DJ & CD Carter 2018  :  www.cmas-net.co.uk/vintage
; ---------------------------------------------------------------
; WARNING
; Changing code could mean that the jump vectors at O_ORG_GV
; need moving as they are put into the DEMON code at a suitable
; place so they can start at address FC00 - which is mid-ROM
;
; This vector list may be removed later when DJC applications
; have been changed to have SWI based replacements for the
; calls made via these vectors:-
;
;   Like:
;
;   INEEE   SWI     ; Call DEMON...
;           FCB $01 ; Read byte to A
;           RTS
;
;   INEEEE  SWI     ; Call DEMON...
;           FCB $03 ; Read byte to A, with echo
;           RTS
;
;   OUTEEE  SWI     ; Call DEMON...
;           FCB $04 ; Output byte from A
;           RTS
;
;   PDATA1  SWI     ; Call DEMON...
;           FCB $05 ; Output string pointed to by X
;           RTS
;
; or by changing calls in code like:-
;           BSR     INEEE   ; 2.byte BranchSR
; to        SWI
;           FCB $01
; or
;           JSR     INEEE   ; 3.byte JumpSR
; to        SWI
;           FCB $01
;           NUL     ; Add NULL if keeping rest
;                   ; of code in same place
;
;-----------------------------------------------------------------
; MOD HISTORY:-
; -----------
; Note: When making changes, update date in `?` command response
; ----  as well as in the notes below.
;
; Nov-2019...       =>              <--<< NEEDS TESTING
     . Added register dump to `?`
     . Add corruption check in SWI call handling
; Oct-2019...       =>
;    . Modded `Z` and `Y` to use switch value for memory value
;    . Added `X` to look for a value on switches in memory range
;    . Added `T` to test a memory range (values 0 to 255)
; Oct-2019...       ~>
;    . Added `?` command for version and help
;    . CMPB   #D_END    logic changed, now
;    . CMPB   D_CNTV    where D_CNTV is an FCB not an EQU
;    . ... now with added Grunt !....
;    . Added Minimon/Gruntmon compatible calls at FC00
;
; Aug-2019...       ~>
;    . Some tidying
;    . Changed stack overflow warning to `!stack!`
;
; Sept-2018...      :>
;    . Forces UI to 2nd ACIA on RESET
;      but address can be changed in RAM
;    . Support for some SWI based calls
;    . Stack overflow produces "!" then Demon RESET
;
; ---------------------------------------------------------------
; RESET address is same as ROM base address
;
; ---------------------------------------------------------------
; Command character lookup table based on SWTBUG code
; Commands read from ACIA.B
;
; Commands:-                                        Based on code from
;   B = Block Move                                      Minimon
;   M = Modify                                          Minimon
;   D = Dump                                            Minimon
;   L = S19 format file load                            Mikbug
;   P = File : `punch` S19 format                       Mikbug
;   G = Go <addr>
;
;   ? = Show version /  Help
;   Z = Set memory to <switches>        /__  For debugging
;   Y = Check memory for <switches>     \    corrupted memory
;   X = Find byte on <switches>
;   T = Test memory (R/W 0 to 255)
;
; ---------------------------------------------------------------
; Set up system-specific addresses

H_VECT      EQU     $FFF8       ; Interrup Vector List Address

O_ROM       EQU     $F800       ; Start of ROM ( 2K monitor )
O_ROMGV     EQU     $FC00       ; Special `Grunt Vector` area !

H_PANEL     EQU     $F0FF       ; Switches / Lights
O_RAM       EQU     $F000       ; Start of our RAM usage (F000->F00FE)

O_RAM_TOP   EQU     $F0FD       ; RAM TOP for variable and stack
                                ; Note: This leaves F0FE `unused`
                                ; in case any apps use S or X reg
                                ; to write to F0FE/F0FF to set
                                ; lights ( eg: Newbear tune program )

; ---------------------------------------------------------------
; 2 x ACIAs :-  Hardware addresses
;
H_AciaA     EQU     $F400       ; Address of 1st ACIA (I/O port)
H_AciaB     EQU     H_AciaA+2   ; Address of 2nd ACIA (I/O port)
;
H_DataA     EQU     H_AciaA     ; ACIA.A Data register
H_CtrlA     EQU     H_AciaA+1   ; ACIA.A Ctrl/Status
H_DataB     EQU     H_AciaB     ; ACIA.B Data register
H_CtrlB     EQU     H_AciaB+1   ; ACIA.B Ctrl/Status

;--------------------------------------------------------
;- ACIA setting values
;--------------------------------------------------------

A_Reset   EQU  $03       ; Value: ACIA Reset

; Bits...

A_Got     EQU  $01       ; Value: ACIA `Has Data` bit
A_Busy    EQU  $02       ; Value: ACIA `Busy` bit

; MODE definitions:-

A_M7_D_16 EQU  $01       ; Value: ACIA Mode: 7 data, 2 stop,
                         ;             Odd Parity, Clk/16

A_M8_D_16 EQU  $11       ; Value: ACIA Mode: 8.data, 2.stop,
                         ;             No Parity,  Clk/16

A_M8_D_1  EQU  $10       ; Value: ACIA Mode: 8.data, 2.stop,
                         ;             No Parity,  Clk/1
; DEFAULT MODE...
;
A_AciaMode EQU A_M8_D_16 ; Default for both ACIAs

; ---------------------------------------------------------------
; Target-machine-specific settings...

A_AciaUI   EQU     H_AciaB     ; Use ACIA.B for UI     *

; -----------------------------------------------------
; General constants
;
; Our lowest ASCII char allowed within a string is $07=BELL
; anything *below* this can act as a string terminator
C_ASC_low  EQU   $07    ; BELL
; Using Zero as our teminator here (as in `c`)...
C_EOS      EQU   $00    ; End-Of-String, for PR_STR_JSR

C_CR       EQU   $0D    ; C/R ( carriage-return )
C_LF       EQU   $0A    ; L/F ( line-feed )


; -----------------------------------------------------
; -----------------------------------------------------
; - RAM -
; -------
            ORG     O_RAM

; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Variables: b_ = BYTE,  d_ = Double Byte
;
b_AciaAM    RMB     1       ; Mode for ACIA.A ( UI )
b_AciaBM    RMB     1       ; Mode for ACIA.B ( UI )
d_AciaUI    RMB     2       ; ACIA addr for UI ( Console )
d_AciaGO    RMB     2       ; ACIA addr for CURRENT i/o
d_START     RMB     2       ; For ASK_Start `Start:`
d_STOP      RMB     2       ;  "  ASK_Addrs `Stop:`
d_NEW       RMB     2       ;  "  Block move `To:`
q_XY        EQU     *       ; For addressing X & Y as quad byte
d_X         RMB     2       ;  "  Block move (SUB) \_These 2 must
d_Y         RMB     2       ;  "  Block move (SUB) /  be together
d_BolX      RMB     2       ;  "  Modify (Begining Of Line)
d_Hx4X      RMB     2       ;  "  RDX4 PRX4
d_RdPrX     RMB     2       ;  "  RD_BYTE, PR_BYTE X
d_RdFstX    RMB     2       ;  "  RD_ByteFast X
;
d_PrStrR    EQU     *       ;  "  PR_STR_... : Return addr: WORD
b_PrStrRhi  RMB     1       ;  "  PR_STR_... : Return addr: High byte
b_PrStrRlo  RMB     1       ;  "  PR_STR_... : Return addr: Low byte
;
d_PrStrX    RMB     2       ;  "  PR_STR_... : X
d_PrStkX    RMB     2       ;  "  PR_STK_... : X
d_PrStrRAD  RMB     2       ;  "  PR_STR_... : Addr of Return Addr
d_RcCmdX    RMB     2       ;  "  Stack check in RD_BYTE_CMD
d_TW        RMB     2       ;  "  S19
b_Csum      RMB     1       ;  "  S19
b_Count     RMB     1       ;  "  S19
b_Temp      RMB     1       ;  "  S19
b_PrStrA    RMB     1       ;  "  PR_STR_... : A
b_PrStkA    RMB     1       ;  "  PR_STK_... : A
b_LEDa      RMB     1       ;  "  LED display work
b_LEDs      RMB     1       ;  "  LED display work
b_Q         RMB     1       ;  "  ZIN,DUMP
b_PrCnt     RMB     1       ;  "  PR

; SWI RAM variables
b_SwiB      RMB     1       ; Save B
b_SwiFunc   RMB     1       ; Our SWI Function code
;
; JMP <addr> ...
; JMP ...
b_SwiJMP    RMB     1       ; JMP Instruction for SWI
; <addr> ...
d_SwiAddr   EQU     *       ; JMP address - 16.bit value via X
b_SwiAdHi   RMB     1       ; JMP address - High byte
b_SwiAdLo   RMB     1       ; JMP address - Low byte
;
d_SwiStk    RMB     2       ; Save SP
;
d_SwiX      EQU     *       ; Save X - 16.bit value for STX,LDX
b_SwiXhi    RMB     1       ; Save X - High byte
b_SwiXlo    RMB     1       ; Save X - low byte
;
d_SwiRet    EQU     *       ; Return PC - 16.bit value for STX
b_SwiRetHi  RMB     1       ; Return PC - High byte
b_SwiRetLo  RMB     1       ; Return PC - low byte


VAR_LAST    EQU     *-1
VARS_USE    EQU     VAR_LAST-O_RAM  ; for lisitng

; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; STACK: The rest of our 256 byte RAM area is stack

S_BASE      EQU     *                 ; Bottom of stack
S_TOP       EQU     O_RAM_TOP         ; Top of our stack
S_SIZE      EQU     S_TOP-VAR_LAST    ; for listing

; -----------------------------------------------------
; -----------------------------------------------------
; - ROM -
; -------
            ORG     O_ROM       ; Start of ROM based code

Do_RESET    EQU     *           ; Main RESET point
            CLI                 ; Clear interrupt bit - for SWI func.0
            LDS     #S_TOP      ; Set up stack for DEMON

            CLR     H_PANEL     ; Clear lights (data)

                                ; Initialise ACIA modes in RAM...

            LDAA    #A_Reset    ; RESET ACIAs...
            STAA    H_CtrlA     ;   ACIA.A
            STAA    H_CtrlB     ;   ACIA.B

            LDX     #A_AciaUI   ; Get addr of ACIA for UI
            STX     d_AciaUI    ; Save this as Cmd UI device
            STX     d_AciaGO    ; Set it as our CURRENT device

            LDAA    #A_AciaMode ; Get default mode for ACIAs
            STAA    b_AciaAM    ; Save it in RAM for ACIA.A
            STAA    b_AciaBM    ; Save it in RAM for ACIA.B
;            v
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
;            v
ReSTART     EQU     *           ; SOFT RESET point
            LDS     #S_TOP      ; Set up stack for DEMON
            BSR     INI_ACIAS   ; Set CURRENT for UI and mode
            JSR     PR_STR_JSR   ; Print string...
            FCB     C_CR,C_LF   ; c/r l/f
            FCC     "=> "
            FCB     C_EOS       ;
RsGetCmd    JSR     RD_BYTE_CMD ; Read a byte (test for `.`)
            LDX     #C_STRT     ; Point to start of CMD table
.rsChkCmd   CMPA    0,X         ; Is this the command ?
            BNE     .rsIncIdx   ; No: skip past it
            JSR     PR_SP       ; Yes: Output a space
            LDX     1,X         ; Load associated address
            JMP     0,X         ;  to X and jump to it
.rsIncIdx   INX                 ; Increment X
            INX                 ;  to get to
            INX                 ;   next command byte
            CPX     #C_END      ; Are we at end of list ?
            BEQ     ReSTART     ; Yes: Go back to start point
            BRA     .rsChkCmd   ;  No: Go check this one

; - - - - - - - - - - - - - - - - - - - - - - - - - - -
INI_ACIAS   EQU     *
            LDAA    b_AciaAM    ; Set up UI modes...
            STAA    H_CtrlA     ;   ACIA.A
            LDAA    b_AciaBM    ;    and
            STAA    H_CtrlB     ;     ACIA.B
            LDX     d_AciaUI    ; This is Cmd UI device
            STX     d_AciaGO    ; Set it as our CURRENT device
            RTS

; -----------------------------------------------------
; Check A contains a HEX character,  Set C.bit on fail

VFY_HEX     CMPA    #$2F        ; A < 30 ?
            BLE     .vNoHex     ;  not hex
            CMPA    #$39        ; A > 39 ?
            BHI     .vNoNum     ;  Not a Numeral
.vIsHex     CLC                 ; It's OK (clear C bit)
            RTS                 ; RETURN
.vNoNum     CMPA    #$40        ; A < 41 ?
            BLE     .vNoHex     ;  not hex
            CMPA    #$46        ; A <= 46
            BLE     .vIsHex     ;  then it is hex
.vNoHex     SEC                 ; Set C bit
            RTS                 ; RETURN

; -----------------------------------------------------
; A and B have 2 x hex digits, convert to binary and return in A

HEX2BIN     BITA    #$30        ; Is A a letter ?
            BEQ     .hNumA      ; Yes: Got to handle it
.hShftA     ASLA                ;  No: It is a number, so
            ASLA                ;      shift
            ASLA                ;       left
            ASLA                ;            4 bits
            BITB    #$30        ; Is B a letter ?
            BEQ     .hNumB      ; Yes: Go handle it
.hMaskB     ANDB    #$0F        ; Clear 4 high bits in B
            ABA                 ; Form binary character (A=A+B)
            RTS                 ; RETURN
.hNumA      ADDA    #$09        ; Make A a binary
            BRA     .hShftA     ;  as before
.hNumB      ADDB    #$09        ; Make B a binary
            BRA     .hMaskB     ;  as before

; -----------------------------------------------------
CMD_G       EQU     *           ; G = GO : Jump to address
            JSR     ASK_Start   ; Prompt for "Start:" (to X)
            JMP     0,X         ; Jump to it

; -----------------------------------------------------
; Read a 2 digit HEX value, put result into X

RD_HEX2     EQU     *
            JSR     RD_ByteFast ; Read a character
            BSR     VFY_HEX     ; Is it a hex character ?
            BCS     .rxPrQM     ; No: go to print `?`
            STAA    b_Q         ; Save it
            JSR     RD_ByteFast ; Read 2nd character
            BSR     VFY_HEX     ; Is it a hex character ?
            BCS     .rxPrQM     ; No: go to print `?`
            TAB                 ; Yes: Put it into B
            LDAA    b_Q         ; Retrieve 1st hex char to A
            BSR     HEX2BIN     ; Convert A:B to binary to A
            TAB                 ; B=A
            ADDB    b_Csum      ; Add this value
            STAB    b_Csum      ; to the Checksum (for S19)
            RTS                 ; RETURN
.rxPrQM     JSR     PR_QM       ; Print "?"
            BRA     RD_HEX2     ; Go back to start of hex input

; -----------------------------------------------------
; Read 4 hex digits and put value into X
;
; RD_HEX4   = Read 4.hex digit address value into X
; RD_HEX4_S = As above, but print a SPACE first

RD_HEX4_S   JSR     PR_SP       ; Print a space
RD_HEX4     BSR     RD_HEX2     ; Read 2 digit hex val into A
            STAA    d_Hx4X      ; Save high.byte
            BSR     RD_HEX2     ; Read 2 digit hex val into A
            STAA    d_Hx4X+1    ; Save low.byte
            LDX     d_Hx4X      ; Load 4 digit hex val into X
            RTS                 ; RETURN

; -----------------------------------------------------
; Print string FOLLOWING JSR/BSR ( terminated by a C_EOS )
;  IE: It starts at the `return addr` put onto the stack by JSR
;  So actual return address needed is past the string
;  It is popped off the stack, and the new one pushed on
;  before RTS
;  A,B and X are PRESERVED
;
PR_STR_JSR  STX     d_PrStrX    ; Save X
            STAA    b_PrStrA    ; Save A
            TSX                 ; Get addr of return to X (X=S+1)
            BRA     PR_STR_cmn  ; Go to common print string code

;- - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; As PR_STR_JSR, but using stack as set when called via SWI
; Note: We have to take account of, and ignore, the last 2 bytes
;       on the stack from the JSR which got us here
;
PR_STR_SWI  STX     d_PrStrX    ; Save X
            STAA    b_PrStrA    ; Save A
            TSX                 ; Get addr of return to X (X=S+1)
            INX                 ; 1: Move pointer
            INX                 ; 2:  7 bytes
            INX                 ; 3:   up
            INX                 ; 4:    the
            INX                 ; 5:     `stack`
            INX                 ; 6:      to get to
            INX                 ; 7:       SWI return address

PR_STR_cmn  STX     d_PrStrRAD  ; Save Retrun Address pointer
            LDX     0,X         ; Get return addr to X
            JSR     PR_FROM_X   ; Print string, addr in X

            INX                 ; X = return address
            STX     d_PrStrR    ; Put it back on stack, so RTI returns to right place...

            LDX     d_PrStrRAD  ; Get address of return address
            LDAA    b_PrStrRhi  ; Get high byte of return address
            STAA    0,X         ; Put back Pc High byte into stack
            LDAA    b_PrStrRlo  ; Get low byte of return address
            STAA    1,X         ; Put back Pc Low byte into stack

            LDAA    b_PrStrA    ; Retrieve original A at entry
            LDX     d_PrStrX    ; Retrieve original X at entry
            RTS                 ; RETURN to addr on stack
; - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Print string pointed to by X
; At end, X points to the string terminator byte
PR_FROM_X   EQU     *
            PSHA                ; Preserve A on STACK
.prNext     LDAA    0,X         ; Get byte to be printed
            CMPA    #C_ASC_low  ; less than lowest val allowed
            BLT     .prx_rts      ; Yes: Go to finish up
            JSR     PR_BYTE     ; Print the byte
            INX                 ; Point to next byte
            BRA     .prNext     ; Go back for next byte
.prx_rts    PULA                ; Restore A from STACK
            RTS                 ; RETURN to addr on stack

; -----------------------------------------------------
; Prompt for Start and Stop addresses
; Put results in d_STARTand d_STOP
; A and B preserved by called routines
; X = STOP address

ASK_Addrs   BSR     ASK_Start
ASK_Stop    BSR     PR_STR_JSR   ; Print string...
            FCC     " Stop:"
            FCB     C_EOS       ;
            BSR     RD_HEX4_S   ; Read 4 digit HEX addr value
            STX     d_STOP      ; Save it
            RTS                 ; RETURN

ASK_Start   BSR     PR_STR_JSR   ; Print string...
            FCC     " Start:"
            FCB     C_EOS       ;
            JSR     RD_HEX4_S   ; Read 4 digit HEX addr value
            STX     d_START     ; Save it
            RTS

; -----------------------------------------------------
; Read byte from ACIA(current) to A.  B and X preserved

RD_BYTE     EQU     *           ; Read from ACIA to A
            CLR     b_LEDs
            PSHB                ; Save B on STACK
            STX     d_RdPrX     ; Save X
            LDX     d_AciaGO    ; X = addr of current ACIA
.rdChk      INCB                ; Add one to B
            BEQ     .rdLED
.rdGet      LDAA    1,X         ; Get ACIA status byte
            ASRA                ; Shift low order bit to C
            BCC     .rdChk      ; Loop until C set
            LDAA    0,X         ; Get the data byte to A
            LDX     d_RdPrX     ; Restore X
            PULB                ; Restore B from STACK
            TSTA                ; Set status bits for A
            RTS                 ; RETURN
.rdLED      INC     b_LEDa      ; Delay: Count through
            LDAB    b_LEDa      ; another byte
            BNE     .rdGet      ; If not zero, go back
            INC     b_LEDs      ; Now increment LEDs value
            LDAB    b_LEDs      ; and load to B
                                ; Speaker attached to low bit...
            ASLB                ; Shift B left to zero low bit
                                ; This stops blips on speaker
            STAB    H_PANEL     ; Show B on LEDs
            BRA     .rdGet      ; go back to work

; -----------------------------------------------------
; Read a byte and echo it to ACIA...

RD_PR_BYTE  BSR     RD_BYTE     ; Read a byte from ACIA
            BRA     PR_BYTE     ; Output it and return
;..dummy..  RTS                 ; BRA used instead of BSR (above)

; -----------------------------------------------------
; Convert value in A to 2 x ASCII hex digits in A and B
; X unchanged

BIN2HEX     TAB                 ; Copy A to B
            BSR     .bxNibble   ; Convert B.nibble to hex in A
            PSHA                ; Push A as B result to STACK
            TBA                 ; Get original back to A from B
            PULB                ; Pop B result from Stack
            LSRA                ; Shift A
            LSRA                ;  Right
            LSRA                ;   4
            LSRA                ;    bits
            BRA     .bxNibble   ; Convert A.nibble to hex in A
;..dummy..  RTS                 ; BRA used instead of BSR (above)

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Convert value in low 4.bits of A to Hex char in A

.bxNibble   ANDA    #$0F        ; Clear high order bits
            CMPA    #$09        ; Letter or number ?
            BHI     .bxAscHi    ;
            ADDA    #$30        ; Make it an ASCII number
            RTS                 ; RETURN
.bxAscHi    ADDA    #$37        ; Make it an ASCI letter
            RTS                 ; RETURN

; -----------------------------------------------------
PR_QM       LDAA    #'?         ;  Question mark
;             v
; - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Print byte in A, Preserve B and X

PR_BYTE     EQU     *           ; From A to ACIA(current)
            INC     b_PrCnt     ; Characters printed + One
            PSHB                ; Preserve B on STACK
            STX     d_RdPrX     ; Save X
            LDX     d_AciaGO    ; X = addr of current ACIA
.prChk      LDAB    1,X         ; B = ACIA.status byte
            BITB    #A_Busy     ; Is it busy ?
            BEQ     .prChk      ; Yes: Try again
            STAA    0,X         ; ACIA.data = A
            LDX     d_RdPrX     ; Restore X
            PULB                ; Restore B from STACK
            RTS                 ; RETURN

; -----------------------------------------------------
; Print value in X as 4 hex digits

PR_HEX4     PSHA
            STX     d_Hx4X      ; Save X
            LDAA    d_Hx4X      ; Get high order byte to A
            BSR     PR_HEX2     ; Print A as 2 hex digits
            LDAA    d_Hx4X+1    ; Get low order byte to A
            BSR     PR_HEX2     ; Print A as 2 hex digits
            PULA
            RTS                 ; RETURN

; -----------------------------------------------------
; Print value in A as 2 hex digits, Preserve B
; X unchanged by called routines

PR_HEX2     PSHB                ; Save B to STACK
            PSHA                ; Save A to STACK
            BSR     BIN2HEX     ; Convert A to ASCII in A & B
            PSHB                ; Save B (2nd byte) to STACK
            BSR     PR_BYTE     ; Print byte in A
            PULA                ; Get 2nd byte into A from STACK
            BSR     PR_BYTE     ; Print byte in A
            PULA                ; Recover A from STACK
            PULB                ; Recover B from STACK
            RTS                 ; RETURN

; -----------------------------------------------------
CMD_B       EQU     *           ; B = Block Move
            JSR     ASK_Addrs   ; Prompt for "Start:","Stop:"
            JSR     PR_STR_JSR  ; Print string...
            FCC     " To:"      ;  "To:"
            FCB     C_EOS       ; End-Of-String
            JSR     RD_HEX4_S   ; Read 4 hex digit value into X
            STX     d_NEW       ; Store it as NEW start address
            STX     d_X         ;   "    "
            LDX     d_START     ; Put start address into X
            STX     d_Y         ; Store it
            BSR     .bSUB       ; Perform d_X minus d_Y
            BPL     .bDown      ; Go to Move downwards
            LDX     d_STOP      ; Get the STOP stop address
            INX                 ; Add 1 to it
            STX     d_STOP      ; and save it
.bNxtByt    LDX     d_START     ; Get START address
            CPX     d_STOP      ; Compare it with STOP
            BNE     .bCont      ; Finished ?
.bQuit      JMP     ReSTART     ; Yes: back to ReSTART
.bCont      EQU     *
            LDAA    0,X         ; No: Get data
            INX                 ; Point X to next `old` address
            STX     d_START     ; and store it
            LDX     d_NEW       ; get address of NEW location
            STAA    0,X         ; Store the data at NEW address
            INX                 ; Point X to next `new` address
            STX     d_NEW       ; and store it
            BRA     .bNxtByt    ; loop back for next byte
.bDown      LDX     d_STOP      ; Get end address
            STX     d_X         ; Store it
            BSR     .bSUB       ; Perform d_X minus d_Y
            ADDA    d_NEW+1     ; Add NEW (low.byte) to A
            ADDB    d_NEW       ; Add NEW (high.byte) to B
            STAA    d_NEW+1     ; Save NEW (low.byte)
            STAB    d_NEW       ;          (high.byte)
            LDX     d_START     ; Get START address
            DEX                 ; subract 1 from X
            STX     d_START     ; Store it
.bNxtChr    LDX     d_STOP      ; Get STOP address
            CPX     d_START     ; Compare it with START address
            BEQ     .bQuit      ; Effecively `JMP START`
            LDAA    0,X         ; Get data
            DEX                 ; Subract 1 from X
            STX     d_STOP      ; Store it
            LDX     d_NEW       ; Load NEW loc address into X
            STAA    0,X         ; Store the data as NEW address
            DEX                 ; Point X to next `new` address
            STX     d_NEW       ; Store it
            BRA     .bNxtChr    ; Loop back for next byte
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
.bSUB       LDX     #q_XY       ; Point X to start of d_X & d_Y data
            LDAA    1,X         ; A = d_X (low)
            LDAB    0,X         ; B = d_X (high)
            SUBA    3,X         ; A = A - d_Y (low)
            SUBB    2,X         ; B = B - d_Y (high)
            RTS                 ; RETURN

; -----------------------------------------------------
CMD_M       EQU     *           ; M = MODIFY
            JSR     ASK_Start   ; Prompt for "Start:" (to X)
.mStrt      JSR     PR_SP       ; Print a space
            CLR     b_PrCnt     ; d_R = 0
.mNewC      LDAA    0,X         ; Get byte pointed to by X to A
            JSR     PR_HEX2     ; Print it as 2.hex digits
.mRead      BSR     RD_BYTE_CMD ; Get command character
.mIsSP      CMPA    #$20        ; Is it a space ?
            BNE     .mIsSL      ; No: go test for slash
.mNext      INX                 ; Increment X
            LDAA    b_PrCnt     ; A = b_PrCnt
            CMPA    #$16        ; At end of line ?
            BLE     .mNewC      ; No: Loop back to continue
.mNewL      BSR     M_BOL       ; Print c/r l/f XXXX
            BRA     .mStrt      ; Loop back

.mIsSL      CMPA    #'/         ; Is it a slash ?
            BNE     .mIsCR      ; No: go test for c/r
            DEX                 ; X = X - 1
            BRA     .mNewL      ; Loop back (print newline)

.mIsCR      CMPA    #C_CR       ; Is it a c/r ?
            BNE     .mIsHx      ; No: go test for valid Hex
            INX                 ; X = X + 1
            BRA     .mNewL      ; Loop back (print newline)

.mIsHx      JSR     VFY_HEX     ; Is it a valid hex character ?
            BCS     .mPrQM      ; No: print `?` and ignore
            STAA    b_Q         ; b_Q = A : Save it
            BSR     RD_BYTE_CMD ; Get 2nd character
            JSR     VFY_HEX     ; Is it a valid hex character ?
            BCS     .mIsSP      ; No: then see what it is
            TAB                 ; B = A
            LDAA    b_Q         ; A = b_Q
            JSR     HEX2BIN     ; Convert to binary value
            STAA    0,X         ; Store it
            JSR     PR_SP       ; Print a space
            BRA     .mNext      ; Loop back

.mPrQM      JSR     PR_QM       ; Print "?"
            BRA     .mRead      ; Loop back

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Beginning Of Line
M_BOL       EQU     *           ; print l/f c/r and X in hex
            STX     d_BolX      ; Save X
            JSR     PR_STR_JSR   ; Print string...
            FCB     C_CR,C_LF   ; c/r  l/f
            FCB     C_EOS       ; End-Of-String
            LDX     d_BolX      ; Restore X
            JMP     PR_HEX4     ; Print X .. JMP instead of JSR
;..dummy..  RTS                 ; RETURN  .. to save this RTS

; -----------------------------------------------------
; Read a character into A
;  : if `.` then soft START
;  : Ignore NULLS ( =0 )
; Preserve X, B unused
;

RD_BYTE_CMD EQU     *           ; Read ONE Character
            STX     d_RcCmdX    ; Save X
            TSX                 ; Stack Ptr+1 to X
            CPX     #S_BASE     ; Compare with base address
            BGE     .cGet       ; OK: Carry on
            LDS     #S_TOP      ; Reset STACK
            JSR     PR_STR_JSR  ; Print...
            FCC     "!stack!"   ;  Stack warning
            FDB     C_CR,C_LF
            FDB     C_EOS       ;
            BRA     .cReStart   ; Go to START
.cGet       JSR     RD_BYTE     ; Input one character
            ANDA    #$7F        ; Strip off `parity` bit, if present
            BEQ     .cGet       ; Ignore paper tape follower
            JSR     PR_BYTE     ; Echo character
            CMPA    #'.         ; Was it
            BNE     .cDone      ;  a fullstop ?
.cReStart   JMP     ReSTART     ; Yes: Go to START
.cDone      LDX     d_RcCmdX    ; Recover X
            RTS                 ; RETURN

; -----------------------------------------------------
RD_ByteFast EQU     *           ; Read ONE Character (fast)
            STX     d_RdFstX    ; Save X
            LDX     d_AciaGO    ; X = addr of current ACIA
.rdChkF     LDAA    1,X         ; Get ACIA status byte
            ASRA                ; Shift low order bit to C
            BCC     .rdChkF     ; Loop until C set
            LDAA    0,X         ; Get the data byte to A
            JSR     PR_BYTE     ; Echo character ...echo...
            ANDA    #$7F        ; Strip off `parity` bit, if present
            BEQ     .rdChkF     ; Ignore paper tape follower
            CMPA    #'.         ; Was it
            BNE     .rfDone      ;  a fullstop ?
            JMP     ReSTART     ; Yes: Go to START
.rfDone     LDX     d_RdFstX    ; Restore X
            RTS                 ; RETURN

; -----------------------------------------------------
CMD_D       EQU     *           ; D = DUMP
            JSR     ASK_Addrs   ; Prompt for "Start:","Stop:"
            LDX     d_START     ;
.dNew       JSR     M_BOL       ; Print c/r l/f nul [X in Hex]
            LDAA    #$08        ;
            STAA    b_Q         ; b_Q = 8
            DEX                 ; X = X - 1
.dNxt       INX                 ; X = X + 1
            BSR     PR_SP       ; Print a space
            LDAA    0,X         ; Get a byte
            JSR     PR_HEX2     ; Print it as 2.hex digits
            CPX     d_STOP      ; Finished ?
            BNE     .dCnt       ; No: Carry on
.dEnd       LDAA    H_DataB     ; Get a byte from ACIA (clear)
            BRA     STARTS      ; Back to ReSTART
.dCnt       LDAA    H_CtrlB     ; Read ACIA status
            BITA    #A_Got      ; Stop dump ?
            BNE     .dEnd       ; Yes; go clear ACIA etc
            DEC     b_Q         ; New line needed ?
            BNE     .dNxt       ; No: Loop back
            INX                 ; Print next byte
            BRA     .dNew       ;  on a new line

; -----------------------------------------------------
PR_SP       JSR     PR_STR_JSR   ; Print...
            FCB     $20,C_EOS   ;  SPACE
            RTS                 ; RETURN

; -----------------------------------------------------
; -----------------------------------------------------
; S format data load : Modded version of Mikbug code
;                      S1<addr><len><data><crc>
;                      S9<...> = end
;
CMD_L       EQU     *           ; L = Load = Input an S19 file
.sRead      EQU     *
            BSR     RD_ByteFast ; Read+Echo, test for '.'
            CMPA    #'S         ; Is it `S` ?
            BNE     .sRead      ; No: Keep waiting for `S`
            BSR     RD_ByteFast ; Read+Echo, test for '.'
            CMPA    #'9         ; Is it `9` ?  ( `S9` record )
            BEQ     .sDone      ; Yes: End-data, Back to START
            CMPA    #'1         ; Is it `1` ?  ( `S1` record )
            BNE     .sRead      ; No: Wait for next `S`
            CLR     b_Csum      ; Clear checksum
            JSR     RD_HEX2     ; Read 2xHex = data.byte count to A
            SUBA    #2          ; Subtract 2 (to get bytes left in line)
            STAA    b_Count     ; Store byte count
            JSR     RD_HEX4     ; Read 4xHex digit address to X
.sDoByt     JSR     RD_HEX2     ; Read 2xHex digits, value to A
            DEC     b_Count     ; Decrement our byte count
            BEQ     .sChk       ; If end-of-line, go look at checksum
            STAA    0,X         ; Save byte where X points
            INX                 ; Point X at next byte
            BRA     .sDoByt     ; Go get next byte
.sChk       LDAA    #C_CR       ; Print a
            JSR     PR_BYTE     ;  carriage-return
            INC     b_Csum      ; Add 1 to checksum
            BEQ     .sRead      ; OK: Go read next record
            JSR     PR_QM       ; Print "?"
.sDone      EQU     *
STARTS      JMP     ReSTART     ; Go to START

; -----------------------------------------------------
; S format data output : Modded version of Mikbug code
;
CMD_P       EQU     *           ; P = Punch : Output an S19 file
            JSR     ASK_Addrs   ; Prompt for "Start:","Stop:"
            LDX     d_START     ; Get start address
            STX     d_TW        ; save it to work area
.fOut1      LDAA    d_STOP+1    ; get low order of end address
            SUBA    d_TW+1      ; Subtract low order start
            LDAB    d_STOP      ; ( carry not affected by LDA )
            SBCB    d_TW        ; Subtract with Carry
            BNE     .fOut2
            CMPA    #16
            BCS     .fOut3
.fOut2      LDAA    #15
.fOut3      ADDA    #4
            STAA    b_Count     ; FRAME COUNT THIS RECORD
            SUBA    #3
            STAA    b_Temp      ; BYTE COUNT THIS RECORD
            JSR     PR_STR_JSR   ; Output `S1` record start...
            FCB     C_CR,C_LF   ; c/r l/f
            FCB     'S,'1
            FCB     C_EOS       ; End-Of-String
            CLRB                ; Clear checksum

; Output frame count...
            LDX     #b_Count    ; X = Address of Framecount
            BSR     .fOutHx2    ; O/P byte <-X and inc X

; Output address...
            LDX     #d_TW
            BSR     .fOutHx2    ; O/P byte <-X and inc X
            BSR     .fOutHx2    ; O/P byte <-X and inc X

; Output data...
            LDX     d_TW
.fOut4      BSR     .fOutHx2    ; O/P byte <-X and inc X
            DEC     b_Temp      ; Decrement `bytes left` count
            BNE     .fOut4      ; Loop back if any left
            STX     d_TW
            COMB
            PSHB
            TSX                 ; X = S + 1
            BSR     .fOutHx2    ; PUNCH CHECKSUM
            PULB
            LDX     d_TW
            DEX
            CPX     d_STOP
            BNE     .fOut1

            JSR     PR_STR_JSR   ; Output `S9` record...
            FCB     C_CR,C_LF   ; c/r l/f
            FCB     'S,'9       ; S9 = <eof>
            FCB     C_EOS       ; End-Of-String

            BSR     STARTS      ;Go to START

;- - - - - - - - - - - - - - - - - - - - - - - - -
; 1) Update checksum
; 2) Output byte pointed to by X as 2 x hex chars
; 3) Increment X
;
.fOutHx2    ADDB    0,X         ; Update checksum
            PSHA                ; Push A to STACK
            LDAA    0,X         ; Load byte to be o/p
            JSR     PR_HEX2     ; O/P byte <- X
            PULA                ; Pull A off STACK
            INX                 ; Increment X
            RTS                 ; RETURN

; -----------------------------------------------------
; Print char from A the number of times held in B
PR_REPEAT   PSHB                ; Push B to stack
            INCB                ; Add one to count
.prr_loop   DECB                ; subtract one fom count
            BLE     .prr_end    ; If <=0 then finished
            JSR     PR_BYTE     ; Print from A
            BRA     .prr_loop   ; back for next one
.prr_end    PULB                ; Restore B
            RTS                 ; RETURN

; -----------------------------------------------------
PR_AND_SP   JSR     PR_BYTE     ; Print from A
PR_SPACE    PSHA                ; Push A onto stack
            LDAA    #$20        ; Load SPACE into A
            JSR     PR_BYTE     ; Print from A
            PULA                ; Restore A
            RTS                 ; RETURN
; -----------------------------------------------------
PR_CRLF     JSR     PR_STR_JSR  ; Print string...
            FCB     C_CR,C_LF   ; c/r l/f
            FCB     C_EOS
            RTS

; -----------------------------------------------------
; ------------------------------------------------------
; MINIMON / Gruntmon equivalent calls...
;
            ORG     O_ROMGV     ; Call vector list start address

            JMP     Do_RESET    ; RESET:  Main H/W RESET entry point
            JMP     RD_BYTE     ; INEEE:  Read char to A, with NO echo
            JMP     PR_BYTE     ; OUTEEE: Print char from A
            JMP     PR_FROM_X   ; PDATA1: Print string, addr in X
            JMP     RD_PR_BYTE  ; INEEEE: Read char to A, with ECHO
            JMP     Do_RESET    ; dummy (spare)
            JMP     Do_RESET    ; dummy (spare)

; ------------------------------------------------------
; -----------------------------------------------------

;... now carry on with DEMON ...

; Output data on stack after SWI...
; IE: Dump registers at point of SWI call

PR_STK_SWI  EQU     *
            STX     d_PrStkX    ; Save X
            STAA    b_PrStkA    ; Save A

            JSR     PR_STR_JSR  ; Output <newline>`SP=`
            FCB     C_CR,C_LF   ; <newline>
            FCC     "SP="
            FCB     C_EOS
            TSX                 ; get stack ptr + 1

                                ; Note *a*:-
            INX                 ; Move past PC put on stack
            INX                 ; by call to get here from
                                ; SWI handling
            JSR     PR_HEX4

            JSR     PR_STR_JSR  ; Output ` CC=`
            FCC     " CC="
            FCB     C_EOS
            TSX                 ; get stack ptr + 1
            LDAA    2,X         ; +2 as per *a*
            JSR     PR_HEX2

            JSR     PR_STR_JSR  ; Output ` B=`
            FCC     " B="
            FCB     C_EOS
            TSX                 ; get stack ptr + 1
            LDAA    3,X         ; +2 as per *a*
            JSR     PR_HEX2

            JSR     PR_STR_JSR  ; Output ` A=`
            FCC     " A="
            FCB     C_EOS
            TSX                 ; get stack ptr + 1
            LDAA    4,X         ; +2 as per *a*
            JSR     PR_HEX2

            JSR     PR_STR_JSR  ; Output ` X=`
            FCC     " X="
            FCB     C_EOS
            TSX                 ; get stack ptr + 1
            LDX     5,X         ; +2 as per *a*
            JSR     PR_HEX4

            JSR     PR_STR_JSR  ; Output ` PC=`
            FCC     " PC="
            FCB     C_EOS
            TSX
            LDX     7,X         ; +2 as per *a*
            JSR     PR_HEX4

            LDAA    b_PrStkA
            LDX     d_PrStkX
            RTS

; -----------------------------------------------------
CMD_QM      EQU     *           ; ? = Show version/help
            JSR     PR_CR_LF    ; <newline>
            SWI                 ; Call ourself via SWI
            FCB     $0B         ; to show registers etc
            JSR     PR_STR_JSR  ; Output string...
            FCB     C_CR,C_LF   ; <newline>
            FCC     "Demon: Newbear 77-68 monitor program"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "Chris & Dave Carter, Dated:2019.11.01"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "Commands:-"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "B=Block Move"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "M=Modify"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "D=Dump"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "L=Load S19 file"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "P=Punch S19 file"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "G=Go <addr>"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "Z=Set memory to switch value"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "Y=Check memory for switch value"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "X=Search memory for switch value"
            FCB     C_CR,C_LF   ; <newline>
            FCC     "T=Test memory (all values)"
            FCB     C_CR,C_LF   ; <newline>
            FCB     C_EOS
            JMP     ReSTART     ; Back to ReSTART

; -----------------------------------------------------
CMD_Z       EQU     *           ; Z = Set memory to value on switches
            JSR     ASK_Addrs   ; Prompt for "Start:","Stop:"
            LDX     d_START     ; Put start address into X
            LDAA    H_PANEL     ; Get value to write into A from SWITCHES
            STAA    H_PANEL     ; Reflect to LEDs
.zNxtByt    STAA    0,X         ; Put the special value in memory
            CPX     d_STOP      ; Compare address with STOP
            BNE     .zCont      ; Finished ?
            JMP     ReSTART     ; Yes: Back to ReSTART
.zCont      INX                 ;  No: Point X to next address
            BRA     .zNxtByt    ; loop back for next byte

; -----------------------------------------------------
CMD_Y       EQU     *           ; Y = Check memory for value switches (See Z)
            JSR     ASK_Addrs   ; Prompt for "Start:","Stop:"
            LDX     d_START     ; Put start address into X
            LDAB    H_PANEL     ; Get value to check into A from SWITCHES
            STAB    H_PANEL     ; Reflect to LEDs
.yNxtByt    LDAA    0,X         ; Get the value in memory
            CBA                 ; Compare A with B
            BNE     MemError    ; Check they match
            CPX     d_STOP      ; Compare address with STOP
            BNE     .yCont      ; Finished ?
.yQuit      JMP     ReSTART     ; Yes: Back to ReSTART
.yCont      INX                 ;  No: Point X to next address
            BRA     .yNxtByt    ; loop back for next byte
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
MemError     EQU     *
            JSR     PR_STR_JSR  ; Output error message:
            FCB     C_CR,C_LF
            FCC     "Mismatch at "
            FCB     C_EOS
            JSR     PR_HEX4
            JSR     PR_STR_JSR
            FCC     " A="
            FCB     C_EOS
            JSR     PR_HEX2
            TBA
            JSR     PR_STR_JSR
            FCC     " B="
            FCB     C_EOS
            JSR     PR_HEX2
            JSR     PR_STR_JSR
            FCC     " !"
            FCB     C_CR,C_LF,C_EOS
            BRA     .yQuit

; -----------------------------------------------------
CMD_X       EQU     *           ; X = Look for value on switches
            JSR     ASK_Addrs   ; Prompt for "Start:","Stop:"
            LDX     d_START     ; Put start address into X
            LDAB    H_PANEL     ; Get value to check into A from SWITCHES
            STAB    H_PANEL     ; Reflect to LEDs
.xNxtByt    LDAA    0,X         ; Get the value in memory
            CBA                 ; Compare A with B
            BEQ     .xGot       ; Check they match
            CPX     d_STOP      ; Compare address with STOP
            BNE     .xCont      ; Finished ?
.xQuit      JMP     ReSTART     ; Yes: Back to ReSTART
.xCont      INX                 ;  No: Point X to next address
            BRA     .xNxtByt    ; loop back for next byte
.xGot       EQU     *
            JSR     PR_STR_JSR  ; Output message:
            FCB     C_CR,C_LF,C_EOS
            JSR     PR_HEX2     ; Number looked for
            JSR     PR_STR_JSR
            FCC     " found at "
            FCB     C_EOS
            JSR     PR_HEX4
            JSR     PR_STR_JSR
            FCB     C_CR,C_LF,C_EOS
            BRA     .xQuit
; -----------------------------------------------------
CMD_T       EQU     *           ; X = Test all values in range
            JSR     ASK_Addrs   ; Prompt for "Start:","Stop:"
            CLRB                ; B=0
.tNxtVal    STAB    H_PANEL     ; Reflect B to LEDs
            LDX     d_START     ; Put start address into X
.tNxtByt    EQU     *
            STAB    0,X         ; Put the B value to memory
            LDAA    0,X         ; Get the value back to A
            CBA                 ; Compare A with B
            BNE     .tBad       ; Check they match
            CPX     d_STOP      ; Compare address with STOP
            BNE     .tCont      ; Finished ?
            INCB                ; Increment B
            BNE     .tNxtVal    ; Go and check this value
.tQuit      JMP     ReSTART     ; Done: Back to ReSTART
.tCont      INX                 ;  No: Point X to next address
            BRA     .tNxtByt    ; loop back for next byte
.tBad       EQU     *
            JMP     MemError

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; -----------------------------------------------------
; COMMAND TABLE

C_STRT      FCB     'B      ; B = Block Move
            FDB     CMD_B
            FCB     'M      ; M = Modify
            FDB     CMD_M
            FCB     'D      ; D = Dump
            FDB     CMD_D
            FCB     'P      ; P = Punch S format
            FDB     CMD_P
            FCB     'L      ; L = Load S format
            FDB     CMD_L
            FCB     'G      ; G = Go = Jump to address
            FDB     CMD_G
            FCB     '?      ; ? = Show version and help
            FDB     CMD_QM
            FCB     'Z      ; Z = Set memory to switch value
            FDB     CMD_Z
            FCB     'Y      ; Y = Check memory for switch value
            FDB     CMD_Y
            FCB     'X      ; X = Look for switch value
            FDB     CMD_X
            FCB     'T      ; T = Test memory
            FDB     CMD_T
C_END       EQU     *

; -----------------------------------------------------
; SWI handler
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Pushed on stack by SWI call:-
;
;  0: <-- data relative to stack pointer at SWI
;  1: CC       <-- 0,X : After TSX, X points here
;  2: B          = 1,X
;  3: A          = 2,X
;  4: X-high     = 3,X
;  5: X-low      = 4,X
;  6: PC-high    = 5,X
;  7: PC-low     = 6,X
; - - - - - - - - - - - - - - - - - - - - - - - - - - -

Do_SWI  EQU     *           ; SWI Handling -- NOTE: uses CALLERS STACK, not DEMONs
;...                        ; A value at call not saved as it is not changed
;...                        ; before the call to the DEMON routine
;...                        ; And A, B and X are all set to their values after
;...                        ; that call before return to caller...
        STAB    b_SwiB      ; Save B value at SWI call
        STX     d_SwiX      ; Save X value at SWI call
        STS     d_SwiStk    ; Save the callers stack pointer

                            ; Now get our function code from the byte after the
                            ; SWI instruction that got us here.  We use the PC
                            ; left on the stack for this, then incement it so
                            ; our eventual RTI will go back to the byte after
                            ; the function code...
        TSX                 ; Copy stack pointer+1 to index register

        LDX     5,X         ; Put content of address pointed to by X+5 (PC) to X
        LDAB    0,X         ; X now points to function code following SWI, load it into B
        STAB    b_SwiFunc   ; Store it

        INX                 ; Add one to callers PC to get past function code
        STX     d_SwiRet    ; Put it back on stack, so RTI returns to right place...
        TSX                 ; Copy stack pointer+1 to index register
        LDAB    b_SwiRetHi  ;
        STAB    5,X         ; Put back Pc High byte into stack
        LDAB    b_SwiRetLo  ;
        STAB    6,X         ; Put back Pc Low byte into stack

        LDAB    b_SwiFunc   ; Get function code into B
        CMPB    D_CNTV      ; Compare function code with call vector count
        BGE     .SwiEnd     ; Error, if too big (call IDs start at 0, hence BGE, not BGT)

        ASLB                ; Shift B left, to multiply func code by 2
        LDX     #D_LIST     ; Load X with start address of routine list
        STX     d_SwiAddr   ; Store  it in RAM (modifiable JMP instruction)
        ADDB    b_SwiAdLo   ; Add low byte of address to value in B
        STAB    b_SwiAdLo   ; Save it back to low byte of jump address
        BCC     .Swi3       ; If CARRY BIT is set...
        INC     b_SwiAdHi   ; add one to the high byte of the jump address
.Swi3   LDAB    #$7E        ; Put JMP opcode into B
        STAB    b_SwiJMP    ; and write it to RAM

        LDX     d_SwiAddr   ; Get vector address for call
        LDX     0,X         ; Get actual routine address
        STX     d_SwiAddr   ; Put it back, ready for JSR

                            ; Reset vector corruption check !
        LDAB    Do_RESET    ; Load 1st byte
        CMPB    $FFFE       ; Does it match ?
        BNE     .BadVec
        LDAB    Do_RESET+1  ; Load 2nd byte
        CMPB    $FFFF       ; Does it match ?
        BEQ     .SwiCmd
.BadVec JSR     PR_STR_JSR
        FCB     C_CR,C_LF
        FCC     "Error: Reset vector bad !"
        FCB     C_CR,C_LF,C_EOS
        LDX     Do_RESET    ; Repair
        STX     $FFFE       ; RESET vector

.SwiCmd LDAB    b_SwiB      ; Restore B to value at SWI call
        LDX     d_SwiX      ; Restore X to value at SWI call
        JSR     b_SwiJMP    ; JSR to required function, via JMP in RAM
;       ...
;       ...                 ; Return from DEMON function to `user` program
;       ...
.SwiEnd EQU     *           ; Tidy up and return to caller
        STX     d_SwiX      ; Save X value set by our routine
        LDS     d_SwiStk    ; Recover Stack pointer to state before function call
                            ; Replace A,B,X on stack with values from DEMON call
        TSX                 ; Get Stack Ptr+1 to X
        STAB    1,X         ; Put B back on stack to go back to caller
        STAA    2,X         ;  and A
        LDAA    b_SwiXhi    ; Get high byte of X returned by our routine
        STAA    3,X         ;   and put in into stack
        LDAA    b_SwiXlo    ; Get low byte of X returned by our routine
        STAA    4,X         ;   and put in into stack
Do_RTI  RTI                 ; RETURN FROM INTERRUPT

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        ; SWI function call vectors
D_LIST  EQU     *
        FDB     ReSTART     ; $00 - Reset Monitor (& Stack)
        FDB     RD_BYTE     ; $01 - Get char into A from ACIA
        FDB     RD_BYTE_CMD ; $02 - Get char, test for `.` + cycle LEDs
        FDB     RD_PR_BYTE  ; $03 - Get char into A from ACIA and output it
        FDB     PR_BYTE     ; $04 - Output char in A
        FDB     PR_FROM_X   ; $05 - Print string pointed to by X
        FDB     PR_STR_SWI  ; $06 - Print string following SWI $06
        FDB     RD_HEX2     ; $07 - Read 2hex char value into A
        FDB     RD_HEX4     ; $08 - Read 4hex char value into X
        FDB     PR_HEX2     ; $09 - O/P 2hex char value from A
        FDB     PR_HEX4     ; $0A - O/P 4hex char value from X
        FDB     PR_STK_SWI  ; $0B - Print data put on stack by SWI
        FDB     PR_REPEAT   ; $0C - Print char in A no. of times in B
        FDB     PR_SPACE    ; $0D - Print a space
        FDB     PR_AND_SP   ; $0E - Print char in A then a space
        FDB     PR_CRLF     ; $0F - Print c/r and l/f
        FDB     Do_RESET    ; $10 - Reset monitor HARD : Reset ACIAs
D_CNTV  FCB     *-D_LIST/2  ; Count of call vectors in 1 byte

; ------------------------------------------------------------------

LAST_BYTE   EQU     *-1       ; Show last ROM addr and
FREE_BYTES  EQU     H_VECT-*  ; free space left on listing

; ------------------------------------------------------------------
            ORG     H_VECT   ; 6800 interrupt vectors
;                            ;-----------------------------
            FDB     Do_RTI   ; IRQ not used
            FDB     Do_SWI   ; SWI handling
            FDB     Do_RTI   ; NMI not used
            FDB     Do_RESET ; Hardware Restart
; ------------------------------------------------------------------
;       The End

