/***************************************************************************************************
 * 
 * 盗墓数据结构部分
 * 需要按照如下方式使用：
 *
 *      CGPROGRAM
 *      #include "TACGInclude/DMCore.cginc"
 *      DM_STRUCT_COMMON        // declare data struct
 *
 *      #include "TACGInclude/other.cginc"      // other file depends on DM_STRUCT_COMMON
 *      ... ...
 *
 * Rely:
 *      1. TAPipelineData  ( For DataStruct Macro Define)
 *
 *
 * Caution:
 *      1. Should not be include by any other cginc
 *
 ***************************************************************************************************/


#ifndef __DM_CORE_DATA__
#define __DM_CORE_DATA__


#include "TAPipelineData.hlsl"


//#ifdef _VERTEXFOG_ON
//float4 fog          : TEXCOORD6;
//#endif
//
//#ifdef SELFSHADOW
//float4 shadowCoord  : TEXCOORD7;
//#endif 
//
//#ifdef _TRANSMITTANCE_ON
//float4 wVertexNormal: TEXCOORD8;
//#endif
//
//#ifdef _MIRROR_ON
//float4 screenPos    : TEXCOORD9;
//#endif
//
//#ifdef _DYNAMIC_WEATHER
//half3 vertexNormal  : TEXCOORD10;
//half2 rainUV        : TEXCOORD11;
//#endif


#define DM_STRUCT_COMMON                                    \
                            V2F_BEGEIN                      \
                                half3 viewDir : TEXCOORD2;  \
                                DATA_TtoW_WPos(3)           \
                            V2F_END

#define ALPHATEST_STRUCT                                    \
                            V2F_BEGEIN                      \
                                half3 viewDir : TEXCOORD2;  \
                                DATA_TtoW_WPos(3)           \
                            V2F_END

#endif