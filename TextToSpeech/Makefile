NAME=text2speech
#ASSEMBLER=../Tools/as6800
CCS19 = ../Tools/ccs19

# consider using one of the cross compilers located in
#  /home/john/Dropbox/Repositories/asxv5p50p5/asxv5pxx/asxmak/linux/exe
# these are very current i.e. 2026 and support most CPUs
# https://shop-pdp.net/ashtml/asxdoc.htm
ASSEMBLER=../Tools/asxv5p50p5/as6800

build:
	../Tools/asxv5p50p5/as6800 -ls -o $(NAME).asm
	../Tools/asxv5p50p5/aslink -i $(NAME).rel

	# -data-only removes the S022 record and -line-length=46 ensures s113 data records
	# -disable=header can be used if just the header should be removed
	srec_cat -data-only $(NAME).hex -Intel -o $(NAME).s19 -Motorola -line-length=46 -execution-start-address 0x0000
	srec_cat -data-only $(NAME).hex -Intel -o $(NAME).bin -Binary

	# the following utility creates a C type data file for use in emulators etc.
	$(CCS19) $(NAME).s19 $(NAME).c -ofc


#	$(ASSEMBLER) $(NAME).asm # Motorola Hex
#	$(ASSEMBLER) $(NAME).asm -h # Intel Hex
#	$(ASSEMBLER) $(NAME).asm -b # 64k binary
#	$(ASSEMBLER) $(NAME).asm -l > $(NAME).lst # list

#	$(CCS19) $(NAME).s19 $(NAME).c -ofc
#	$(CCS19) $(NAME).s19 $(NAME).bin -ofb
#	unix2dos -r $(NAME).s19 $(NAME).s19

	# Split the .S19 file as some terminals such as GTKTerm cant handle large files.
	#srec_cat $(NAME).s19 -crop 0x0200 0x0600 -o $(NAME)_part1.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	#srec_cat $(NAME).s19 -crop 0x0600 0x0A00 -o $(NAME)_part2.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	#srec_cat $(NAME).s19 -crop 0x0A00 0x0E00 -o $(NAME)_part3.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	#srec_cat $(NAME).s19 -crop 0x0E00 0x1300 -o $(NAME)_part4.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	#srec_cat $(NAME).s19 -crop 0x1300 0x1700 -o $(NAME)_part5.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	#srec_cat $(NAME).s19 -crop 0x1700 0x1B00 -o $(NAME)_part6.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000
	#srec_cat $(NAME).s19 -crop 0x1B00 0x1F00 -o $(NAME)_part7.s19 -Output_Block_Size=16 -Execution_Start_Address 0x0000

	# Multiple ORGs in source so .ptp version not valid
	echo -n "" > $(NAME).ptp
	cat  $(NAME).bin >> $(NAME).ptp

	cp $(NAME).s19 ../Releases

clean:
	rm $(NAME).lst
	rm *.s19
	rm $(NAME).c
	rm $(NAME).bin
	rm $(NAME).ptp
	rm $(NAME).hex
	rm $(NAME).sym
	rm $(NAME).hlr
	rm $(NAME).rel

