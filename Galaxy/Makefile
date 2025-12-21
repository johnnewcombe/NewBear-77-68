
NAME=galaxy
ASSEMBLER=../Tools/as6800
CCS19 = ../Tools/ccs19

build:

	$(ASSEMBLER) $(NAME).asm # Motorola Hex
	$(ASSEMBLER) $(NAME).asm -s > $(NAME).sym # Symbol Table
	$(ASSEMBLER) $(NAME).asm -h # Intel Hex
	$(ASSEMBLER) $(NAME).asm -b # 64k binary
	$(ASSEMBLER) $(NAME).asm -l > $(NAME).lst # list

	$(CCS19) $(NAME).s19 $(NAME).c -ofc
	$(CCS19) $(NAME).s19 $(NAME).bin -ofb

	unix2dos -r $(NAME).s19 $(NAME).s19
	echo -n "SS" > $(NAME).ptp
	cat  $(NAME).bin >> $(NAME).ptp


clean:
	rm $(NAME).bin
	rm $(NAME).c
	rm $(NAME).hex
	rm $(NAME).lst
	rm $(NAME).obj
	rm $(NAME).ptp
	rm $(NAME).s19
	rm $(NAME).sym
