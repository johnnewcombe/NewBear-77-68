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

	# Multiple ORGs in source so .ptp vrsion not valid
	echo -n "SS" > $(NAME).ptp
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

