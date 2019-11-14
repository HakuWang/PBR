/***************************************************************************************************
 * 
 * 对 TAPipelineData 中的数据结构，提供常用的复合工具
 *
 Rely 
    TAPipelineData

 ***************************************************************************************************/


#ifndef __TA_PIPELINE_DATA_UTILS_CGINC__
#define __TA_PIPELINE_DATA_UTILS_CGINC__


#include "TAUtils.hlsl"



 /*********************************
 * Extract World Normal from TAV2F
 *********************************/

inline half3 CalculateWorldNormal(half3 tNormal, TAV2F v2fData)
{
    half3 wNormal = TangentToWorld(v2fData, tNormal);
    return normalize(wNormal);
}

inline half3 CalculateWorldNormal(sampler2D normalTex, half2 normalMapUV, TAV2F v2fData)
{
    half3 tNormal = UnpackNormal(tex2D(normalTex, normalMapUV));
    return CalculateWorldNormal(tNormal, v2fData);
}

inline float3 CalculateWorldNormal(sampler2D normalTex, half2 normalMapUV, half bumpScale, TAV2F v2fData)
{
    half3 tNormal = UnpackScaleNormal(tex2D(normalTex, normalMapUV).xyz, bumpScale);
    return CalculateWorldNormal(tNormal, v2fData);
}


/*********************************
* Extract Surface PBR Param
*********************************/





#endif