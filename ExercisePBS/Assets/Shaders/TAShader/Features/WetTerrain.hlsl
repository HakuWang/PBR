/***************************************************************************************************
 * 
 * 特性：积水地形
 *
 *  混合
 *  1. 使用顶点色的 w 通道和 normal 贴图的 w 通道进行混合控制
 *
 ***************************************************************************************************/


#ifndef __FEATURE_WET_TERRAIN_HLSL__
#define __FEATURE_WET_TERRAIN_HLSL__

#include "../TACGInclude/TAUtils.hlsl"
#include "../TACGInclude/TAPBS.hlsl"



#define WetBlendInfo half



inline WetBlendInfo CalculateWetBlendInfo(float4 tNormal, float4 color, float wetHardness)
{
    float controlValue = color.w;
    half blendInfo = lerp(-tNormal.w, 0.5, controlValue);
    blendInfo = saturate(blendInfo * wetHardness) * step(0.01, controlValue);
    return blendInfo;
}


inline half3 ApplyWetToTerrainNormal(WetBlendInfo blendInfo, float4 tNormal, TAV2F v2fData)
{
    half3 tNormalDisturb = -(tNormal.xyz - half3(0, 0, 1)) * 0.96 * blendInfo;
    tNormal.xyz += tNormalDisturb;
    return TangentToWorld(v2fData, tNormal.xyz);
}


inline half4 ApplyWetToTerrainAlbedo(WetBlendInfo blendInfo, float4 albedo, float3 wetColor)
{
    float3 blendScalar = lerp(1, wetColor, blendInfo);
    return half4(albedo.xyz * blendScalar, albedo.w);
}



inline void ApplyWetToTerrainPBRParam(WetBlendInfo blendInfo, float rainSmoothness, inout PBSSurfaceParam param)
{
    // apply wet to smoothness
    half originSmoothness = 1 - param.roughness;
    half wetSmoothnewss   =  lerp(originSmoothness, rainSmoothness, blendInfo);
    param.roughness = 1 - wetSmoothnewss;

    // apply wet to AO
    param.AO += blendInfo;
}


#endif