#if !defined cDEVICE_CPP && defined cPROJ_ALLOW_CPP_COMPILE
#define cDEVICE_CPP

#include "device.h"

// Parent class for emulated 77-68 devices, such as RAM, ACIA, PIA

#if 1
int classMemoryMappedDevice::mine( int32_t i32Addr ) {
      if ( ( i32Addr >= _mmd_i32StartAddr )
       &&  ( i32Addr <= _mmd_i32EndAddr ) ) {
        return( true );
      }  
      return( false );
    } // End: mine(...)

    // ShowInformation(...) 
    //  Output an identity string
    // ( Base class, non-virtual function - cannot be overriden in sub-class )...
void classMemoryMappedDevice::ShowInformation( Stream * objStream ) {
      objStream->print( "Devce: " );
      objStream->print( _mmd_sType );
      objStream->print( " : " );

//x   objStream->print( _mmd_i32StartAddr, HEX );
      fvOutputHex4( objStream, _mmd_i32StartAddr );
      if ( _mmd_i32StartAddr != _mmd_i32EndAddr ) {
        objStream->print( " to " );
//x     objStream->print( _mmd_i32EndAddr, HEX );
        fvOutputHex4( objStream, _mmd_i32EndAddr );
      }
      objStream->println();
      return;
    } // End: ShowInformation(...)


#endif

#endif
