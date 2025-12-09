; ---------------------------------------------------------------
; DEMON v6 CDC : JAN 2025 
; was SIMON v1 CDC : DEC 2023 
; which was trimmed DEMON v5 to get 
; SWI handling, Load and Modify into 1K
; with all other commands in 2nd 1K called EXTRAS
; hence new name: Software Interrupt MONitor
;
; Set version number...
C_VERSION   EQU     6
C_SUBVER    EQU     1
;
; History...
;
; Jan-2025 : Minor mods
;
; Sep-2024 : ? shows name as DEMON as this command is only in 2kb version
;
; Jun-2024 : Bug fix in Block Move
;
; Feb-2023...
;   Change Pdelay (Punch delay) from 5 to 8
;
; Jan-2023...
;   Change `S`=Switches to Leds cmd to `R` ( coz we want the S )...
;
;   If `S` met as command, jump into LOAD at point after `S` 
;   received so just starting to send an S19 file will 
;   automagically invoke the LOAD process
;
; Dec-2023...  ver 1.1
;   Code base taken from Demon v5
;   Trimmed to just SWI handling, Load and Modify cmds
;   Prompt suffix changed to >> from ->
;   Some (more) JSR calls in CMD_M changed to SWI
;   to save one byte each.
;
; ---------------------------------------------------------------
; CD & DJ Carter  :  www.cmas-net.co.uk/vintage
; ---------------------------------------------------------------
; RESET address is same as ROM base address
;
; SIMON (Top 1KB) Commands:-                   Based on code from
;   M = Modify                                          Minimon
;   L = S19 format file load                            Mikbug
;   G = Go <addr>
; DEMON Extra (optional 2nd KB) Commands:-
;   B = Block Move                                      Minimon
;   P = File : `punch` S19 format                       Mikbug
;   D = Dump                                            Minimon
;   ? = Show version /  Help
;   I = On/Off toggle for LED count during input wait
;   Z = Set memory to <switches>        /__  For debugging
;   Y = Check memory for <switches>     \    corrupted memory
;   X = Find byte on <switches>
;   S = <switches> to LEDs
;   * = Bounce LEDs
;   T = Test memory (R/W 0 to 255)  (error bit detect based on
;       code by Ben Zotto ... https://sphere.computer)
;
; ---------------------------------------------------------------
; Set up system-specific addresses

H_VECT      EQU     $FFF8       ; Interrup Vector List Address

O_JMPS      EQU     H_VECT-24   ; Calc start of JMP list...
                                ; For 8 JMPs, 3 bytes per JMP
                                ; This is for entry points for
                                ; INEEE, OUTEEE equivalents etc
                                ; So these are at fixed positions
                                ; just before normal interrupt vectors

O_EXTRA     EQU     $F800       ; Start of DEMON, optional part.2 of SIMON
O_ROM       EQU     $FC00       ; Start of ROM ( 1K monitor )

D_MARK_1    EQU     $12         ; Marker byte for O_2NDKB, if used
D_MARK_2    EQU     $21         ; Marker byte for O_2NDKB+1, if used

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
; SIMON/DEMON SWI $nn call function codes for 
; 1st data bye after SWI instruction...
D_RESET       EQU     $00 ; Reset Monitor SOFT (& Stack)
D_RD_BYTE     EQU     $01 ; Get char into A from ACIA
D_RD_CMD      EQU     $02 ; Get char, test for . + LEDs
D_RD_PR_BYT   EQU     $03 ; Get char into A from ACIA and output it
D_PR_BYTE     EQU     $04 ; Output char in A
D_PR_FROM_X   EQU     $05 ; Print string pointed to by X
D_PR_STR      EQU     $06 ; Print string following SWI $06
D_RD_HEX2     EQU     $07 ; Read 2hex char value into A
D_RD_HEX4     EQU     $08 ; Read 4hex char value into X
D_PR_HEX2     EQU     $09 ; O/P 2hex char value from A
D_PR_HEX4     EQU     $0A ; O/P 4hex char value from X
D_PR_STK      EQU     $0B ; Print data put on stack by SWI
D_PR_REPEAT   EQU     $0C ; Print char in A no. of times in B
D_PR_SPACE    EQU     $0D ; Print char in A no. of times in B
D_PR_AND_SP   EQU     $0E ; Print char in A then a space
D_PR_CRLF     EQU     $0F ; Print c/r and l/f
D_RESET_HRD   EQU     $10 ; Reset monitor HARD - Inc.ACIAs
D_RD_IFRDY    EQU     $11 ; Read Kbd char if one is ready,else A=0
D_GET_RANDOM  EQU     $12 ; Put pseudo random number into X
D_GET_VERSION EQU     $13 ; Return version Ver.Sub in A and B
D_ASK_START   EQU     $14 ; Prompt for "Start:", value in X
D_ASK_STOP    EQU     $15 ; Prompt for "Stop:", value in X

; -----------------------------------------------------
; Flag bits ( in b_Flag byte ) etc...
Flag_I      EQU     $01         ; `Idle` flag
FlgAll      EQU     $7F         ; All possible flag bits ON

; -----------------------------------------------------
; Delay after `P` issued, before o/p starts (0 to 255)...
Pdelay      EQU     $08         ; = times delay loop is run

; -----------------------------------------------------
DumpBPL     EQU     16          ; Dump Bytes Per Line default

; -----------------------------------------------------
; -----------------------------------------------------
; - RAM -
; -------
            ORG     O_RAM

; - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Variables: b_ = BYTE,  d_ = Double Byte
;
d_AciaGO    RMB     2       ; ACIA addr for UI ( Console )
b_AciaID    RMB     1       ; '1'=ACIA.A, '2'=ACIA.B

b_Wait      RMB     1       ; Delay for `Wait` after `P` (0 to 255) 
b_Flag      RMB     1       ; Flag bits

b_dbpl      RMB     1       ; For Dump Bytes Per Line - User can change via 'M' cmd
b_Q         RMB     1       ; For ZIN, DUMP, MODIFY

d_START     RMB     2       ; For ASK_Start `Start:`
d_STOP      RMB     2       ;  "  ASK_Addrs `Stop:`
d_NEW       RMB     2       ;  "  Block move `To:`

q_XY        EQU     *       ; For addressing X & Y as quad byte
d_X         RMB     2       ;  "  Block move (SUB) \_These 2 must
d_Y         RMB     2       ;  "  Block move (SUB) /  be together

d_BolX      RMB     2       ;  "  Modify, Dump (Begining Of Line)
d_Hx4X      RMB     2       ;  "  RDX4 PRX4
d_RdPrX     RMB     2       ;  "  RD_BYTE, PR_BYTE X, RD_IFRDY
d_RdFstX    RMB     2       ;  "  RD_ByteFast X
;
d_PrStrR    EQU     *       ;  "  PR_STR_... : Return addr: WORD
b_PrStrRhi  RMB     1       ;  "  PR_STR_... : Return addr: High byte
b_PrStrRlo  RMB     1       ;  "  PR_STR_... : Return addr: Low byte
;
d_PrStrX    RMB     2       ;  "  PR_STR_... : X  and DumpAsc
d_PrStkX    RMB     2       ;  "  PR_STK_... : X
d_PrStrRAD  RMB     2       ;  "  PR_STR_... : Addr of Return Addr
d_TW        RMB     2       ;  "  S19
b_Csum      RMB     1       ;  "  S19
b_Count     RMB     1       ;  "  S19
b_Temp      RMB     1       ;  "  S19 and T(test)
b_PrStrA    RMB     1       ;  "  PR_STR_... : A
b_PrStkA    RMB     1       ;  "  PR_STK_... : A
b_LEDa      RMB     1       ;  "  LED display work and CMD_T
b_LEDs      RMB     1       ;  "  LED display work and CMD_T
d_Random    EQU     *       ; For grabbing next 2 bytes in GET_RANDOM
b_PrCnt     RMB     1       ;  "  PR and GET_RANDOM
b_RndCnt    RMB     1       ;  "  Incremented lots, mainly in ACIA waits

; SWI RAM variables
b_SwiTmp    RMB     1       ; Save B reg and to set CCs before RTI
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

; ------------------------------------------------------------------
; FOR SIMON 1KB monitor ONLY :
; ------------------------------------------------------------------
; SIMON START 
; -----------------------------------------------------
; - ROM -
; -------
            ORG     O_ROM       ; Start of ROM based code

Do_RESET    EQU     *           ; Main RESET point
            CLI                 ; Clear interrupt bit - for SWI func.0
            LDS     #S_TOP      ; Set up stack for SIMON

            LDAA    #DumpBPL    ; Dump Bytes Per Line    ...
            STAA    b_dbpl      ;  User can change via 'M' cmd

            LDAA    #$55        ; Put 01010101 on the LEDs
            STAA    H_PANEL     ; Put on LEDs

            LDAA    #FlgAll     ; A = All flag bits set ON
            STAA    b_Flag      ; Set into flag byte

            LDAA    #Pdelay     ; Default delay
            STAA    b_Wait      ; Set into RAM byte, where user can modify it

                                ; Initialise ACIA modes in RAM...

            LDAA    #A_Reset    ; RESET ACIAs...
            STAA    H_CtrlA     ;   ACIA.A
            STAA    H_CtrlB     ;   ACIA.B

            LDAA    #A_AciaMode ; Get default mode for ACIAs
            STAA    H_CtrlA     ;   ACIA.A
            STAA    H_CtrlB     ;   ACIA.B

            LDX     #H_AciaA    ; Get addr of ACIA.A for UI
            STX     d_AciaGO    ; Set A as our CURRENT device
            LDAA    #'1         ; Set ACIA ID char
            STAA    b_AciaID    ;     for prompt

WaitChr     EQU     *
;            v
            LDX     #H_AciaA    ; X = addr of ACIA.A
            LDAA    1,X         ; Get ACIA status byte
            ASRA                ; Shift low order bit to C
            BCS     .ReadChr    ; Got char on A, already set, so GO
;            v
.NoChrA     LDX     #H_AciaB    ; X = addr of ACIA.B
            LDAA    1,X         ; Get ACIA status byte
            ASRA                ; Shift low order bit to C
            BCC     WaitChr     ; C not set, no char waiting
;            v                  ; Set B as i/o tty device
            STX     d_AciaGO    ; Set B as our CURRENT device
            LDAA    #'2         ; Set ACIA ID char
            STAA    b_AciaID    ;     for prompt
.ReadChr    BSR     RD_BYTE     ; Get rid of keystroke
;            v
; - - - - - - - - - - - - - - - - - - - - - - - - - - -
;            v
ReSTART     EQU     *           ; SOFT RESET point
            LDS     #S_TOP      ; Set up stack for SIMON

            JSR     PR_CRLF     ; c/r l/f
            LDAA    b_AciaID    ; Get ACIA.ID char (A or B)
            JSR     PR_BYTE     ; Output it
            JSR     PR_STR_JSR  ; Print string...
            FCC     ">> "       ; PROMPT
            FCB     C_EOS       ;

RsGetCmd    BSR     RD_CMD      ; Read a byte (test for `.`)
            BSR     UPPER       ; Change Cmd byte to uppercase
            LDX     #C_STRT     ; Point to start of CMD table
.rsChkCmd   EQU     *
            CMPA    0,X         ; Is this the command ?
            BNE     .rsIncIdx   ; No: skip past it
            JSR     PR_SPACE    ; Yes: Output a space
            LDX     1,X         ; Load address associated with
            JMP     0,X         ;  this CMD to X and JUMP to it
.rsIncIdx   INX                 ; Increment X
            INX                 ;  to get to
            INX                 ;   next command byte
            CPX     #C_END      ; Are we at end of list ?
            BNE     .rsChkCmd   ; No: Go check this one
            LDAB    O_EXTRA     ; Look at 1st byte of SIMON extras
            CMPB    #D_MARK_1   ; Does it match 1st marker byte ?            
            BNE     .rsChkEnd   ; No: quit
            LDAB    O_EXTRA+1   ; Look at 2nd byte of SIMON extras
            CMPB    #D_MARK_2   ; Does it match 2nd marker byte ?
            BNE     .rsChkEnd   ; No: quit
            JSR     O_EXTRA+2   ; Got extras... JSR to them           
.rsChkEnd   BRA     ReSTART     ; Go back to start point

; -----------------------------------------------------
; READ COMMAND BYTE ...
;  Read a character into A
;  : if `.` then soft START
;  : Ignore NULLS ( =0 )

RD_CMD      EQU     *           ; Read ONE Character
            BSR     RD_BYTE     ; Input one character
            ANDA    #$7F        ; Strip off `parity` bit, if present
            BSR     PR_BYTE     ; Echo character
            CMPA    #'.         ; Was it '.' ?
            BNE     .cDone      ;  If not, go to return
.cReStart   BRA     ReSTART     ; Yes: Go to START
.cDone      RTS                 ; RETURN

; -----------------------------------------------------
; Convert Reg.A to UPPERCASE

UPPER       CMPA    #'a         ; Is it below lowercase a-z ?
            BLT     .CaseOK    
            CMPA    #'z         ; Is it above lowercase a-z ?
            BGT     .CaseOK    
            SUBA    #$20        ; Convert lowercase alpha to upper
.CaseOK     RTS

; -----------------------------------------------------
; Read byte from ACIA(current) to A.  B and X preserved

RD_BYTE     EQU     *           ; Read from ACIA to A
            CLR     b_LEDs
            PSHB                ; Save B on STACK
            STX     d_RdPrX     ; Save X
            LDX     d_AciaGO    ; X = addr of current ACIA
.rdChk      INC     b_RndCnt    ; Bump random number
            INCB                ; Add one to B
            BEQ     .rdLED
.rdGet      LDAA    1,X         ; Get ACIA status byte
            ASRA                ; Shift low order bit to C
            BCC     .rdChk      ; Loop until C set
            LDAA    0,X         ; Get the data byte to A
            LDX     d_RdPrX     ; Restore X
            PULB                ; Restore B from STACK
            TSTA                ; Set status bits for A
            RTS                 ; RETURN
.rdLED      LDAB    b_Flag      ; Load flag bits
            ANDB    #Flag_I     ; Is the Flag_I bit set ?
            BEQ     .rdGet      ; No: Skip LED display
            INC     b_LEDa      ; Delay: Count through
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
            BRA     PR_BYTE     ; Output it and return via its BSR
;..dummy..  RTS                 ; BRA used instead of BSR (above)

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
.prChk      INC     b_RndCnt    ; Bump random number
            LDAB    1,X         ; B = ACIA.status byte
            BITB    #A_Busy     ; Is it busy ?
            BEQ     .prChk      ; Yes: Try again
            STAA    0,X         ; ACIA.data = A
            LDX     d_RdPrX     ; Restore X
            PULB                ; Restore B from STACK
            RTS                 ; RETURN

; -----------------------------------------------------
RD_ByteFast EQU     *           ; Read ONE Character (fast)
            STX     d_RdFstX    ; Save X
            LDX     d_AciaGO    ; X = addr of current ACIA
.rdChkF     LDAA    1,X         ; Get ACIA status byte
            ASRA                ; Shift low order bit to C
            BCC     .rdChkF     ; Loop until C set
            LDAA    0,X         ; Get the data byte to A
            BSR     PR_BYTE     ; Echo character ...echo...
;xxx CUT    ANDA    #$7F        ; Strip off `parity` bit, if present
;xxx CUT    BEQ     .rdChkF     ; Ignore paper tape follower
            CMPA    #'.         ; Was it
            BNE     .rfDone      ;  a fullstop ?
            JMP     ReSTART     ; Yes: Go to START
.rfDone     LDX     d_RdFstX    ; Restore X
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
CMD_S       BSR     RD_ByteFast ; Read+Echo, test for '.'
            CMPA    #'9         ; Is it `9` ?  ( `S9` record )
            BEQ     .sDone      ; Yes: End-data, Back to START
            CMPA    #'1         ; Is it `1` ?  ( `S1` record )
            BNE     .sRead      ; No: Wait for next `S`
            CLR     b_Csum      ; Clear checksum
            BSR     RD_HEX2     ; Read 2xHex = data.byte count to A
            SUBA    #2          ; Subtract 2 (to get bytes left in line)
            STAA    b_Count     ; Store byte count
            BSR     RD_HEX4     ; Read 4xHex digit address to X
.sDoByt     BSR     RD_HEX2     ; Read 2xHex digits, value to A
            DEC     b_Count     ; Decrement our byte count
            BEQ     .sChk       ; If end-of-line, go look at checksum
            STAA    0,X         ; Save byte where X points
            INX                 ; Point X at next byte
            BRA     .sDoByt     ; Go get next byte
.sChk       LDAA    #C_CR       ; Print a
            BSR     PR_BYTE     ;  carriage-return
            INC     b_Csum      ; Add 1 to checksum
            BEQ     .sRead      ; OK: Go read next record
            BSR     PR_QM       ; Print "?"
.sDone      EQU     *
            JMP     ReSTART     ; Go to START

; -----------------------------------------------------
; Check A contains a HEX character,  Set C.bit on fail
; If it fails, try converting to uppercase and retry
; Trying to keep hex data reads fast.

VFY_HEX     EQU     *
            BSR     .vTry       ; 1st try
            BCC     .vIsHex     ; OK
            JSR     UPPER       ; Convert to uppercase
            BRA     .vTry       ; 2nd try
;..dummy..  RTS                 ; BRA used instead of BSR (above)
;           ---
.vTry       CMPA    #$2F        ; A < 30 ?
            BLE     .vNoHex     ;  not hex
            CMPA    #$39        ; A > 39 ?
            BHI     .vNoNum     ;  Not a Numeral
.vIsHex     CLC                 ; It's OK (clear C bit)
            RTS                 ; RETURN
;           ---
.vNoNum     CMPA    #$40        ; A < 41 ?
            BLE     .vNoHex     ;  not hex
            CMPA    #$46        ; A <= 46
            BLE     .vIsHex     ;  then it is hex
.vNoHex     SEC                 ; Set C bit
            RTS                 ; RETURN

; -----------------------------------------------------
; A and B have 2 x hex digits, convert to binary and return in A

HEX2BIN     BITA    #$30        ; Is A a letter ?
            BEQ     .hNumA      ; Yes: Go to handle it
.hShftA     ASLA                ;  No: It is a number, so
            ASLA                ;      shift
            ASLA                ;       left
            ASLA                ;        4 bits
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

RD_HEX4_S   BSR     PR_SPACE    ; Print a space
RD_HEX4     BSR     RD_HEX2     ; Read 2 digit hex val into A
            STAA    d_Hx4X      ; Save high.byte
            BSR     RD_HEX2     ; Read 2 digit hex val into A
            STAA    d_Hx4X+1    ; Save low.byte
            LDX     d_Hx4X      ; Load 4 digit hex val into X
            RTS                 ; RETURN

; -----------------------------------------------------
PR_AND_SP   JSR     PR_BYTE     ; Print from A
PR_SPACE    JSR     PR_STR_JSR  ; Print string...
            FCC     " "         ; space
            FCB     C_EOS       ;
            RTS                 ; RETURN

; -----------------------------------------------------
; Prompt for Start and Stop addresses
; Put results in d_STARTand d_STOP
; A and B preserved by called routines
; X = STOP address

ASK_Addrs   BSR     ASK_Start
ASK_Stop    JSR     PR_STR_JSR  ; Print string...
            FCC     " Stop:"
            FCB     C_EOS       ;
            BSR     RD_HEX4_S   ; Read 4 digit HEX addr value
            STX     d_STOP      ; Save it
            RTS                 ; RETURN

ASK_Start   JSR     PR_STR_JSR  ; Print string...
            FCC     " Start:"
            FCB     C_EOS       ;
            BSR     RD_HEX4_S   ; Read 4 digit HEX addr value
            STX     d_START     ; Save it
            RTS

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
            JSR     PR_BYTE     ; Print byte in A
            PULA                ; Get 2nd byte into A from STACK
            JSR     PR_BYTE     ; Print byte in A
            PULA                ; Recover A from STACK
            PULB                ; Recover B from STACK
            RTS                 ; RETURN

;------------------------------------------------------
; Output data on stack after SWI...
; IE: Dump registers at point of SWI call
;
PR_STK_SWI  EQU     *
            STX     d_PrStkX    ; Save X
            STAA    b_PrStkA    ; Save A

            BSR     PR_STR_JSR  ; Output <newline>`SP=`
            FCB     C_CR,C_LF   ; <newline>
            FCC     "SP="
            FCB     C_EOS
            TSX                 ; get stack ptr + 1

                                ; Note *a*:-
            INX                 ; Move past PC put on stack
            INX                 ; by call to get here from
                                ; SWI handling
            BSR     PR_HEX4

            BSR     PR_STR_JSR  ; Output ` CC=`
            FCC     " CC="
            FCB     C_EOS
            TSX                 ; get stack ptr + 1
            LDAA    2,X         ; +2 as per *a*
            BSR     PR_HEX2

            BSR     PR_STR_JSR  ; Output ` B=`
            FCC     " B="
            FCB     C_EOS
            TSX                 ; get stack ptr + 1
            LDAA    3,X         ; +2 as per *a*
            BSR     PR_HEX2

            BSR     PR_STR_JSR  ; Output ` A=`
            FCC     " A="
            FCB     C_EOS
            TSX                 ; get stack ptr + 1
            LDAA    4,X         ; +2 as per *a*
            BSR     PR_HEX2

            BSR     PR_STR_JSR  ; Output ` X=`
            FCC     " X="
            FCB     C_EOS
            TSX                 ; get stack ptr + 1
            LDX     5,X         ; +2 as per *a*
            BSR     PR_HEX4

            BSR     PR_STR_JSR  ; Output ` PC=`
            FCC     " PC="
            FCB     C_EOS
            TSX
            LDX     7,X         ; +2 as per *a*
            BSR     PR_HEX4

            LDAA    b_PrStkA
            LDX     d_PrStkX
            RTS

;-
SZ_PSTK     EQU     *-PR_STK_SWI     ; Show size of PR_STK_SWI code

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
            BSR     PR_FROM_X   ; Print string, addr in X

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
            BLT     .prx_rts    ; Yes: Go to finish up
            JSR     PR_BYTE     ; Print the byte
            INX                 ; Point to next byte
            BRA     .prNext     ; Go back for next byte
.prx_rts    PULA                ; Restore A from STACK
            RTS                 ; RETURN to addr on stack

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
PR_CRLF     JSR     PR_STR_JSR  ; Print string...
            FCB     C_CR,C_LF   ; c/r l/f
            FCB     C_EOS
            RTS

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

Do_SWI  EQU     *           ; SWI Handling -- NOTE: uses CALLERS STACK, not SIMONs
;...                        ; A value at call not saved as it is not changed
;...                        ; before the call to the SIMON routine
;...                        ; And A, B and X are all set to their values after
;...                        ; that call before return to caller...
        INC     b_RndCnt    ; Bump random number
        STAB    b_SwiTmp    ; Save B value at SWI call
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

.SwiCmd LDAB    b_SwiTmp    ; Restore B to value at SWI call
        CLR     b_SwiTmp    ; Clear ready to hold `C` bit on RTI
        LDX     d_SwiX      ; Restore X to value at SWI call
        JSR     b_SwiJMP    ; JSR to required function, via JMP in RAM
;       ...
;       ...                 ; Return from SIMON function to `user` program
;       ...
.SwiEnd EQU     *           ; Tidy up and return to caller
        BCC     .SwiCC      ; Is C bit clear
        INC     b_SwiTmp    ; Set C bit in CCs
.SwiCC  STX     d_SwiX      ; Save X value set by our routine
        LDS     d_SwiStk    ; Recover Stack pointer to state before function call
                            ; Replace A,B,X on stack with values from SIMON call
        TSX                 ; Get Stack Ptr+1 to X
        STAB    1,X         ; Put B back on stack to go back to caller
        STAA    2,X         ;  and A
        LDAA    b_SwiTmp    ; Get our CCs containing C bit into A
        STAA    0,X         ;  and put back on stack
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
        FDB     RD_CMD      ; $02 - Get char, test for `.` + cycle LEDs
        FDB     RD_PR_BYTE  ; $03 - Get char into A from ACIA and output it
        FDB     PR_BYTE     ; $04 - Output char in A
        FDB     PR_FROM_X   ; $05 - Print string pointed to by X to (End=ANY <= $06)
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
        FDB     RD_IFRDY    ; $11 - Read Kbd char if one is ready,else A=0
        FDB     GET_RANDOM  ; $12 - Put pseudo random number into X
        FDB     GET_VERSION ; $13 - Return s/w version number in A & B
        FDB     ASK_Start   ; $14 - Prompt for Start:, value into X
        FDB     ASK_Stop    ; $15 - Prompt for Stop:, value into X
D_CNTV  FCB     *-D_LIST/2  ; Count of call vectors in 1 byte

;-
SZ_SWI  EQU     *-Do_SWI    ; Show size of SWI code

; ------------------------------------------------------------------
GET_VERSION EQU     *
            LDAA    #C_VERSION
            LDAB    #C_SUBVER
            RTS

; ------------------------------------------------------------------
; Fetch a pseudo random number into X
GET_RANDOM  EQU     *
            LDX     d_Random
            RTS

; ------------------------------------------------------------------
; Test for a char waiting in ACIA...
; If present return A=1, else A=0
RD_IFRDY    EQU     *
            STX     d_RdPrX     ; Save X
;           ....                ; Check for keystroke...
            LDX     d_AciaGO    ; X = addr of current ACIA 
            LDAA    1,X         ; Get ACIA status byte
            ASRA                ; Shift low order bit to C
            BCC     .NoChr      ; C not set, no char waiting
            LDAA    #$01        ; A=1
            BRA     .GotChr     ; Done
.NoChr      CLRA                ; No char, so set A=0
.GotChr     LDX     d_RdPrX     ; Recover X
            RTS                 ; RETURN


; ------------------------------------------------------------------
; COMMAND TABLE
; ------------------------------------------------------------------
C_STRT      EQU     *
            FCB     'G      ; G = Go = Jump to address
            FDB     CMD_G
            FCB     'L      ; L = Load S format
            FDB     CMD_L
            FCB     'M      ; M = Modify
            FDB     CMD_M
            FCB     'S      ; S = Trap S19 loading (jump to Load routine)
            FDB     CMD_S
C_END       EQU     *

; ------------------------------------------------------------------
; G = Go to <addr>...
; ------------------------------------------------------------------
CMD_G       EQU     *           ; G = GO : Jump to address
            SWI                 ; Call via SWI...
            FCB     D_ASK_START ; Prompt for "Start:" (to X)
            JMP     0,X         ; Jump to it

; ------------------------------------------------------------------
; Built-in `M` (Modify) command ...
; ------------------------------------------------------------------
CMD_M       EQU     *           ; M = MODIFY
            SWI                 ; Call via SWI...
            FCB     D_ASK_START ; Prompt for "Start:" (to X)
.mStrt      SWI                 ; Call via SWI...
            FCB     D_PR_SPACE  ; to print a space
            CLR     b_PrCnt     ; d_R = 0
.mNewC      LDAA    0,X         ; Get byte pointed to by X to A
            SWI                 ; Call via SWI...
            FCB     D_PR_HEX2   ;  to print it as 2.hex digits
.mRead      SWI                 ; Call via SWI...
            FCB     D_RD_CMD    ;  to read byt, test for `.` etc
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
            SWI                 ; Call via SWI...
            FCB     D_RD_CMD    ; Get 2nd character
            JSR     VFY_HEX     ; Is it a valid hex character ?
            BCS     .mIsSP      ; No: then see what it is
            TAB                 ; B = A
            LDAA    b_Q         ; A = b_Q
            JSR     HEX2BIN     ; Convert to binary value
            STAA    0,X         ; Store it
            SWI                 ; Call via SWI...
            FCB     D_PR_SPACE  ; to print a space
            BRA     .mNext      ; Loop back

.mPrQM      JSR     PR_QM       ; Print "?"
            BRA     .mRead      ; Loop back

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Beginning Of Line
M_BOL       EQU     *           ; print l/f c/r and X in hex
            STX     d_BolX      ; Save X
            SWI                 ; Call via SWI...
            FCB     D_PR_CRLF   ; Print c/r  l/f
            LDX     d_BolX      ; Restore X
            JMP     PR_HEX4     ; Print X .. JMP instead of JSR
;..dummy..  RTS                 ; RETURN  .. to save this RTS

; -----------------------------------------------------
; NEED TO PAD TO FFF8 for 1KB SIMON BINARY suitable for 
; 32yte rom loader on MON1...
; .lst file shows the above JMP xxxx at FFE8/9/A, so...
 NOP ; Pad FFEB
 NOP ; Pad FFEC
 NOP ; Pad FFED
 NOP ; Pad FFEE
 NOP ; Pad FFEF
 NOP ; Pad FFF0
 NOP ; Pad FFF1
 NOP ; Pad FFF2
 NOP ; Pad FFF3
 NOP ; Pad FFF4
 NOP ; Pad FFF5
 NOP ; Pad FFF6
 NOP ; Pad FFF7

;x LAST_BYTE   EQU     *-1       ; Show last SIMON code address on listing
;x SZ_FREE     EQU     H_VECT-*  ; Show free space left on listing

; NOW CHECK (visually on lisitng) VECTOR LIST IS FROM FFF8 to FFFF...
; ------------------------------------------------------------------
; ------------------------------------------------------------------
;x            ORG     H_VECT   ; 6800 interrupt vectors
;                            ;-----------------------------
            FDB     Do_RTI   ; IRQ not used
            FDB     Do_SWI   ; SWI handling
            FDB     Do_RTI   ; NMI not used
            FDB     Do_RESET ; Hardware Restart
; ------------------------------------------------------------------
;       End of 1K SIMON   ( eg: FC00 to FFFF )
; ------------------------------------------------------------------
; ------------------------------------------------------------------
;

; The End
