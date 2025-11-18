*----------------------------------------------------------
* 32 byte Boot rom code for MON1 board of Newbear 77-68
* from MON1 board manual
*
* This ROM is switched in via the `boot` switch
* so that mem.read from these locations reads the ROM
* but write go to the underlying RAM so a 1k progam
* can be loaded from FC00 to FFFF (including RESET vector)
*
* This program puts the first 1024 bytes to be received
* by ACIA(a) into the top 1k of RAM
*
* To start : hit `RESET` with system set to `BOOT`
* When finished, `RUN` lamp goes out
*
* As the 1k loaded should overwrite the RESET vector with
* the start addreess of the new code,
* then pressing RESET should start that program.
*
*----------------------------------------------------------
        ORG     $FFE0   * Start address for code
*
START   LDAA    #$03    * Reset
        STAA    $F401   *  ACIA(a)
        LDAA    #$11    * Set up ACIA
        STAA    $F401   *  control register
        LDX     #$FC00  * Point to start of 1k RAM
        TXS             * Point stack to $FBFF ( SP=X-1 )
LOOP    LDAA    $F401   * Read ACIA(a) control register
        BITA    #$01    * If no data ready...
        BEQ     LOOP    *  look again
        LDAA    $F400   * Get the data byte to A
        STAA    0,X     * Store it
        INX             * Point to next RAM location
        BNE     LOOP    * If not done, then get next byte
        WAI             * Done ( 1K loaded ) kill RUN lamp
        FDB     #START  * Put start address in RESET vector
*
*       The end
*----------------------------------------------------------
