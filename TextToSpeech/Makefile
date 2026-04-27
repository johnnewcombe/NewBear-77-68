NAME=text2speech
ASSEMBLER=../Tools/as6800
CCS19 = ../Tools/ccs19

build:
	$(ASSEMBLER) $(NAME).asm # Motorola Hex
	$(ASSEMBLER) $(NAME).asm -h # Intel Hex
	$(ASSEMBLER) $(NAME).asm -b # 64k binary
	$(ASSEMBLER) $(NAME).asm -l > $(NAME).lst # list

	$(CCS19) $(NAME).s19 $(NAME).c -ofc
	$(CCS19) $(NAME).s19 $(NAME).bin -ofb
	unix2dos -r $(NAME).s19 $(NAME).s19

	# Split the .S19 file as some terminals such as GTKTerm cant handle large files.
	srec_cat $(NAME).s19 -crop 0x0200 0x0600 -o $(NAME)_part1.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	srec_cat $(NAME).s19 -crop 0x0600 0x0A00 -o $(NAME)_part2.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	srec_cat $(NAME).s19 -crop 0x0A00 0x0E00 -o $(NAME)_part3.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	srec_cat $(NAME).s19 -crop 0x0E00 0x1300 -o $(NAME)_part4.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	srec_cat $(NAME).s19 -crop 0x1300 0x1700 -o $(NAME)_part5.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	srec_cat $(NAME).s19 -crop 0x1700 0x1B00 -o $(NAME)_part6.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	srec_cat $(NAME).s19 -crop 0x1B00 0x1F00 -o $(NAME)_part7.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000

	# Multiple ORGs in source so .ptp version not valid
	echo -n "" > $(NAME).ptp
	cat  $(NAME).bin >> $(NAME).ptp

	cp $(NAME).s19 ../Releases

clean:
	rm $(NAME).lst
	rm $(NAME).s19
	rm $(NAME).obj
	rm $(NAME).c
	rm $(NAME).bin
	rm $(NAME).ptp
	rm $(NAME).hex

