;	.ORG FOR 6811 ASSEMBLER
	
GETADD	EQU	$FC89
GETAD1	EQU	$F0EF
GETAD2	EQU	$F0F1
NEWLINE	EQU	$FE97
PR1HEX	EQU	$FCC9
PRBLNK	EQU	$FD4D
MINIMON	EQU	$FF8F

ACIACD	EQU	$F403

TEMP	EQU	$F05F

	ORG	$0000 	


START	JSR	GETADD  ; Get addr from user
	LDX	GETAD1  ; Get addr value
LOOP 	JSR	NEWLINE ; Print Newline 
 	JSR	PRBLNK  ; 
 	LDAA	0,X     ; Get byte pointed to by X
	STAA	TEMP    ; Save it
 	JSR	PR1HEX  ; Print the byte in A in Hex
 	JSR	PRBLNK  ; 
 	LDAA	TEMP    ; Ge the byte back into A
 	CMPA	#$8C    ; \ If it is 
 	BEQ	THREE   ;  \ any of
 	CMPA	#$8E    ;   \ these
 	BEQ	THREE   ;    \ codes
 	CMPA	#$CE    ;     \ then treat as
 	BEQ	THREE   ;      \ 3 byte instruction

	ANDA	#$F0    ; Mask off bottom 4 bits

 	CMPA	#$20	; \ If this bit is set
 	BEQ	 TWO    ;  \ treat as 2 byte instruction
 	CMPA	#$60    ; \ If this bit is set
 	BCS	ONE     ;  \ treat as 1 byte instruction

 	ANDA	#$30    ; Mask off top 2 bits (and bottom 4)

 	CMPA	#$30	; \ If this bit is set
 	BNE	TWO     ;  \ treat as 2 byte instruction

;       ...             ; Otherwise, treat as 3 byte instruction

THREE	INX             ; Point to next byte
 	CPX	GETAD2  ; If at end address
 	BEQ	MON     ;  back to MINIMON	
 	LDAA	0,X     ; Get byte pointed to by X
 	JSR	PR1HEX  ; Print the byte in A in Hex

TWO	INX             ; Point to next byte
 	CPX	GETAD2  ; If at end address
 	BEQ	MON     ;  back to MINIMON	
 	LDAA	0,X     ; Get byte pointed to by X
 	JSR	PR1HEX  ; Print the byte in A in Hex

ONE	INX             ; Point to next byte
 	CPX	GETAD2  ; If at end address
 	BEQ	MON     ;  back to MINIMON	

 	LDAA	ACIACD  ; Read the ACIA status
	BITA	#$01    ; If a character has been typed
 	BNE	MON     ;  back to MINIMON
 	BRA	LOOP    ; Process next byte

MON	JMP MINIMON     ; Back to MINIMON
 
