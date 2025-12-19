# JMON


Created by GlassTTY, Jan. 2026, using MINIMON (ACH, Dec. 1978) as a base
with additional code from Motorola's MIKBUG.

Special thanks to Chris Carter for inspiration and help.

This is a MINIMON compatible monitor for the 77-68 Bear/Newbear system with
the LOAD and PUNCH commands replaced for versions that support the
Motorola S Record Format (.s19) files.

All entry points and source code labels as published in the MINIMON
documentation have been preserved with the exception of the LOAD and PUNCH
commands.

In order to make space for the additional code required, the ALTER and
OFFSET CALCULATION commands have been removed. This has been justified as
the MODIFY command has very similar functionality to ALTER making ALTER
unnecessary, and the OFFSET CALCULATION routines (commands X and Y) are
rarely used as all cross-assemblers perform these calculations
automatically. In addition BLOCKMOVE command (Cmd 'B') has been removed
to allow for a memory test command to be added (Cmd 'T')'.

One other minor change is that the terminal along with any devices sending
S19 format files have been configured for 8 Data Bits, No Parity, 2 Stop
Bits.

The following is a list of routines within MINIMON.

```text
RD_CMD  FC00 - Inputs a character from the JMON prompt and echos the character. The routine restarts JMON if a
               full stop is entered. The value is returned in A.
PR_A    FC0F - Sends the character in A to ACIA(a). Address T_R contains the number of characters printed.character
VHEX    FC1D - Checks that A contains a HEX character
BINARY  FC31 - Converts ASCII hex digits in A and B to binary?
ZIN     FC49 - Reads a 2 digit hex value from ACIA(a) and puts it into A.
RD_X    FC65 - Read 4 hex digits alue from ACIA(a) and put value into X.
STRING  FC76 - Prints a string. The string should follow JSR and be terminated with $FF.
GETADD  FC89 - Get Address, read 4 digit hex value.
ASCII   FC9E - Convert value in A to 2 x ASCII hex digits in A and B.
PRX     FCBB - Print value in X as 4 hex digits.
ZOUT    FCC9 - Print value in A as 2 hex digits.
PUNCH   FDE2 - Invokes the PUNCH command use JMP as THIS IS NOT A SUBROUTINE but restarts JMON.
LOAD    FCE3 - Invokes the LOAD command use JMP as THIS IS NOT A SUBROUTINE but restarts JMON.
RD_A    FD2B - Read byte from ACIA.A to A.
REGPRT  FD36 - Invoke the REGISTER PRINT Command, use JMP as THIS IS NOT A SUBROUTINE but restarts JMON.
PRSP    FD4D - Prints a space.
MEMTEST FD62 - Invokes the MEMORY TEST command.
VERSION FDC3 - Reports JMON version.
SUB     FDD6 - Subtract uses T_X 16 bit data area at F0E6.
PRP     FE33 - Prints he string " P ".
PRD     FE3B - Prints he string " D ".
MODIFY  FE43 - Invokes the MODIFY command.
GO      FEC2 - Invokes the GO command, This is an SW1 call.
CONTNU  FED9 - Invokes the CONTINUE command, as THIS IS NOT A SUBROUTINE but restarts JMON.
DUMP    FF07 - Invokes the DUMP command.
BRPTSET FF39 - Invokes the SET BREAKPOINT command.terminal
HEADER  FF63 - Prints the header used for the register display.
RESET   FF81 - Resets ACIAs saves the callers stack pointer and restarts JMON.
SWI     FF8C - Saves callers stack pointer and restarts JMON.
START   FF8F - Restarts MniMon.
```

**Notes:**

## S Record Format

```text
Record structure
S  Type  Byte Count  Address  Data  Checksum
```

An SREC format file consists of a series of ASCII text records. The records have the following structure from left to right:

* Record start - each record begins with an uppercase letter "S" character (ASCII 0x53) which stands for "Start-of-Record".
* Record type - single numeric digit "0" to "9" character (ASCII 0x30 to 0x39), defining the type of record. See table below.
* Byte count - two hex digits ("00" to "FF"), indicating the number of bytes (hex digit pairs) that follow in the rest of the record (address + data + checksum). This field has a minimum value of 3 (2 for 16-bit address field plus 1 checksum byte), and a maximum value of 255 (0xFF). "00" / "01" / "02" are illegal values.
* Address - four / six / eight hex digits as determined by the record type. The address bytes are arranged in big-endian format.
* Data - a sequence of 2n hex digits, for n bytes of the data. For S1/S2/S3 records, a maximum of 32 bytes per record is typical since it will fit on an 80 character wide terminal screen, though 16 bytes would be easier to visually decode each byte at a specific address.
* Checksum - two hex digits, the least significant byte of ones' complement of the sum of the values represented by the two hex digit pairs for the Byte Count, Address and Data fields. In the C programming language, the sum is converted into the checksum by: 0xFF - (sum & 0xFF)

Note that the S9 terminating record is ignored by the SREC parser within the monitor and can be removed from the file if so desired. Similarly the terminating record is not created by the PUNCH command.
