#if !defined cMISC_C && defined cPROJ_ALLOW_CPP_COMPILE
#define cMISC_C

void fvOutputHex2( Stream * objStream, int32_t i32Value ) {
  if ( (i32Value & 0xFF) < 0x10 ) objStream->print("0");
  objStream->print(i32Value & 0xFF,HEX);
}

void fvOutputHex4( Stream * objStream, int32_t i32Value ) {
  if ( i32Value < 0x10 ) objStream->print("0");
  if ( i32Value < 0x100 ) objStream->print("0");
  if ( i32Value < 0x1000 ) objStream->print("0");
  objStream->print(i32Value & 0xFFFF,HEX);
}

int32_t fi32HexCharToInt( char chrDigit ) {
  static char* strHexChar={"0123456789ABCDEF"};
  char chrUcase;
  chrUcase = toupper(chrDigit);
  for (int iAt=0; iAt<16; iAt++) {
    if (chrUcase == strHexChar[iAt]) return(iAt);
  }
  return(-1);
}


char fcInputChar(Stream * objRealDevice) {
  char chrIn;
  while(true) {
    // Any chars available ?...
    if (objRealDevice->available() > 0) {
      // Read character...
      chrIn = objRealDevice->read();
      Serial.write(chrIn);
      return( chrIn );
    }
#if cDEV_SETUP_C
    // This input routine is only called in HALT mode...
#if cDEV_PANEL_SWITCHES
    if ( gi32_Panel_Switch_Changed ) {
      gi32_Panel_Switch_Changed = false;
      objPANEL.vReadSwitchPins();
    }
#endif
    // Look for RUN/HALT going to RUN(=true)...
    if ( objPANEL.readSwRun() ) {
      return( cSWRUN );
    }
#endif        
  delay( 100 ); // Delay 1/10 sec  
  } // End: while()
}


int32_t fi32ReadHex2(Stream * objRealDevice) {
  char chrIn;
  int32_t i32Value;
  int32_t i32Digit;
  chrIn = fcInputChar( objRealDevice );
  // Special case for EMU> 'M' command in M6800...
  if (chrIn == ' ') return(-2);
  i32Digit = fi32HexCharToInt( chrIn );
  if (i32Digit < 0) return(-1);
  i32Value = i32Digit << 4;
  chrIn = fcInputChar( objRealDevice );
  i32Digit = fi32HexCharToInt( chrIn );
  if (i32Digit < 0) return(-1);
  i32Value += i32Digit;
  return(i32Value);
}  

int32_t fi32ReadHex4(Stream * objRealDevice) {
  int32_t i32Value;
  int32_t i32Byte;
  i32Byte = fi32ReadHex2( objRealDevice );
  if (i32Byte < 0) return(-1);
  i32Value = i32Byte << 8;
  i32Byte = fi32ReadHex2( objRealDevice );
  if (i32Byte < 0) return(-1);
  i32Value += i32Byte;
  return(i32Value);
}  

#if 000

#define cCR     13
#define cTAB     9
#define cENDSTR  0
#define cBS      8

int32_t fi32InputLine( char * strLine, int32_t i32EndLine ) {
  int iAt = 0;  
  char chrIn;
  while(true) {
    // Check BS (etc ?) have not decremented to far...
    if (iAt < 0 ) iAt = 0;
    // Put End-String char in byte for now...
    strLine[iAt] = cENDSTR;
    // Check line is not too long...
    if (iAt >= i32EndLine) return(-1);
    // Any chars available ?...
    if (Serial.available() > 0) {
      // Read character...
      chrIn = Serial.read();
      // c/r ends line
      if ( chrIn == cCR) return( iAt );
      // Convert TAB to space...
      if ( chrIn == cTAB) chrIn = ' ';
      // BackSpace deletes previous character...
      if ( chrIn == cBS) iAt--;
      // Only add SPACE and higher chars, so control chars ignored...
      if ( chrIn >= ' ' ) {
        // Place character in caller's buffer...
        strLine[iAt] = chrIn;
        // Point to next character...
        iAt++;
      }
    }
  }
  return( iAt );
}
#endif //000

#endif
