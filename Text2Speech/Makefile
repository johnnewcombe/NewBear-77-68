NAME=text2speech
#ASSEMBLER=../Tools/as6800
CCS19 = ../Tools/ccs19
VERSION = 1.0.18

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
	#srec_cat $(NAME).hex -Intel -o $(NAME).s19 -Motorola -line-length=46 -execution-start-address 0x0000
	srec_cat -data-only $(NAME).hex -Intel -header "Version: $(VERSION)" -o $(NAME).s19 -Motorola -line-length=46 -execution-start-address 0x0200
	srec_cat -data-only $(NAME).hex -Intel -o $(NAME).bin -Binary

	# the following utility creates a C type data file for use in emulators etc.
	$(CCS19) $(NAME).s19 $(NAME).c -ofc

	# Multiple ORGs in source so .ptp version not valid
	echo -n "" > $(NAME).ptp
	cat  $(NAME).bin >> $(NAME).ptp



install: build
	cp $(NAME).s19 ../Releases/$(NAME)_$(VERSION).s19
	chmod 0444 ../Releases/$(NAME)_$(VERSION).s19
	srec_info ../Releases/$(NAME)_$(VERSION).s19

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
	rm -f ../Releases/$(NAME)_$(VERSION).s19

