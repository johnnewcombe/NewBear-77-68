# MiniMon Routines

The following is a list of routines within MINIMON.

```text
RD_CMD  FC00 - Inputs a character from the MiniMon prompt and echos the character. The routine restarts MiniMon if a
                full stop is entered. The value is returned in A.
PR_A    FC0F - Sends the character in A to ACIA(a). Address T_R contains the number of characters printed.character
VHEX    FC1D - Checks that A contains a HEX character
BINARY  FC31 - Converts A:B to binary?
    Q Is this correct?
ZIN     FC49 - Reads a 4 digit hex value from ACIA(a) and puts it into A.
    Q Is this correct or is it 2 digit hex value?
RD_X    FC65 - Read 4 hex digits value from ACIA(a) and put value into X.
STRING  FC76 - Prints a string. The string should follow JSR and be terminated with $FF.
GETADD  FC89 - Get Address, read 4 digit hex value.
ASCII   FC9E - Convert value in A to 2 x ASCII hex digits in A and B.
PRX     FCBB - Print value in X as 4 hex digits.
ZOUT    FCC9 - Print value in A as 2 hex digits.
PUNCH   FCD8 - Invokes the PUNCH command use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
LOAD    FD07 - Invokes the LOAD command use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
BIN     FD01 - Inistialise ACIA(a) to 8N2 (MiniMon terminal originally used 7E1 for normal interaction).
RD_A    FD2B - Read byte from ACIA.A to A.
REGPRT  FD36 - Invoke the REGISTER PRINT Command, use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
PRSP    FD4D - Prints a space.
BLKMOV  FD62 - Invokes the BLOCK MOVE command.
SUB     FDD6 - Subtract uses T_X 16 bit data area at F0E6.
CMD_Z   FDE2 - Invokes the 8 bit RELATIVE OFFSET CALCULATION, use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
CMD_X   FE1C - Invokes the 16 bit RELATIVE OFFSET CALCULATION, use JMP as THIS IS NOT A SUBROUTINE but restarts MiniMon.
PRP     FE33 - Prints he string " P ".
PRD     FE3B - Prints he string " D ".
MODIFY  FE43 - Invokes the MODIFY command.
ALTER   FEA8 - Invokes the ALTER command.
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

1. The Load and Punch commands re-inits the ACIA to set 8N2 See BIN subroutine. With the terminal now on 8N2, this space could be used to set up ACIA(b) for 8N2 also. There is also two bytes free at FD29 and one free at FFF7.
1. With some minor optimisation, it should be possible to have the Terminal on ACIA(b) at 1200,8,N,2 (via RD and PR routines) and ACIA(b) used for Punch and Load at 9600,8,N,2. This should allow for fast loading of monitor and the ability to control the speech unit.
1. A further option could be to remove the Relative offset Calc CMD_Z, CMD_X, PRP and PRD as they are not used by the monitor and implement an S19 load and save routines instead.


