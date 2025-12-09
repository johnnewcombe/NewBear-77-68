
NAME=minimon-2025
ASSEMBLER=../Tools/as6800
CCS19 = ../Tools/ccs19

build:
	$(ASSEMBLER) $(NAME).asm # Motorola Hex
	$(ASSEMBLER) $(NAME).asm -h # Intel Hex
	$(ASSEMBLER) $(NAME).asm -b # 64k binary
	$(ASSEMBLER) $(NAME).asm -l > $(NAME).lst # list

	$(CCS19) $(NAME).s19 $(NAME).c -ofc
	$(CCS19) $(NAME).s19 $(NAME).bin -ofb

	echo -n "SS" > $(NAME).ptp
	cat  $(NAME).bin >> $(NAME).ptp

