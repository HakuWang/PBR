#ifndef __TA_GRAPHICS_SETTING_MACRO_HLSL__
#define __TA_GRAPHICS_SETTING_MACRO_HLSL__


#ifdef _GRAPHIC_LOW_OR_MEDIUM_OR_HIGH
    #ifndef _GRAPHIC_LOW
        #ifndef _GRAPHIC_MEDIUM
            #define _GRAPHIC_HIGH 1
        #endif
    #endif
#endif

#ifdef _LODLEVEL_LOD_1_OR_0
    #ifndef LODLEVEL_LOD1
        #ifndef LODLEVEL_LOD0
            #define LODLEVEL_LOD0 1
        #endif
    #endif
#endif



#ifndef _GRAPHIC_LOW
    #define _PRECISE_TBN
#endif



#endif