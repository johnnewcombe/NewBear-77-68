*----------------------------------------------------------
* Tiny flasher code for MON1 board of Newbear 77-68
* from MON1 board manual
*
* Modified to use $F0FF for display LEDs
*
DISPLAY EQU     $F0FF

        ORG     $FF00   * Start address in RAM
*
START   INX
        BNE     START
        INCA
        STAA    DISPLAY
        BRA     START

        ORG     $FFFE   * Address of RESET vector
        FDB     #START  * Put start address in RESET vector
*
*       The end
*----------------------------------------------------------
