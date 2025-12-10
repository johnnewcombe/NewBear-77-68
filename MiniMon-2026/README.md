# MiniMon-2026 Routines

09-12-2025 JN - THIS IS A WORK IN PROGRESS !!! DO NOT USE!!!

This is an updated version of MINIMON with S19 LOAD and PUNCH routines. All entry points and Lables as published in
the MINIMO documentation have been preserved with the exception of the LOAD command which is now at address FCE6.

In order to make space for the additional code required, the ALTER and OFFSET CALCULATION commands have been removed.
The MODIFY command has very similar functionality to ALTER making ALTER unnecessary, and the OFFSET CALCULATION routines
(commands X and Y) have been removed as all cross-assemblers perform this calculation automatically.

The Terminal and any devices sending S19 format files should be configured for 8 Data Bits, No Parity, 2 Stop Bits.

The following is a list of routines within MINIMON.

```text
RD_CMD  FC00 - Inputs a character from the MiniMon prompt and echos the character. The routine restarts MiniMon if a
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
PUNCH   FCD8 - Invokes the PUNCH command use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
LOAD    FCE6 - Invokes the LOAD command use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
BIN     FD01 - Inistialise ACIA(a) to 8N2 (MiniMon terminal originally used 7E1 for normal interaction).
RD_A    FD2B - Read byte from ACIA.A to A.
REGPRT  FD36 - Invoke the REGISTER PRINT Command, use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
PRSP    FD4D - Prints a space.
BLKMOV  FD62 - Invokes the BLOCK MOVE command.
SUB     FDD6 - Subtract uses T_X 16 bit data area at F0E6.
PRP     FE33 - Prints he string " P ".
PRD     FE3B - Prints he string " D ".
MODIFY  FE43 - Invokes the MODIFY command.
GO      FEC2 - Invokes the GO command, This is an SW1 call.
CONTNU  FED9 - Invokes the CONTINUE command, as THIS IS NOT A SUBROUTINE but restarts MiniMon.
DUMP    FF07 - Invokes the DUMP command.
BRPTSET FF39 - Invokes the SET BREAKPOINT command.terminal
HEADER  FF63 - Prints the header used for the register display.
RESET   FF81 - Resets ACIAs saves the callers stack pointer and restarts MiniMon.
SWI     FF8C - Saves callers stack pointer and restarts MiniMon.
START   FF8F - Restarts MniMon.
```

**Notes:**


