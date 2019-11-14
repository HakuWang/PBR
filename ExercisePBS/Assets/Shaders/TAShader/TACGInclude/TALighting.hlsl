#ifndef __TA_LIGHTING_CORE_HLSL__
#define __TA_LIGHTING_CORE_HLSL__



/************************************************************
 * 提供普适的光照模型
 * 1. 直接光照模型
 * 2. LightMap AHD 模型
 * 3. SH9 模型
 * 4. SH9 AHD 模型

 ************************************************************/



#include "RoninSH.hlsl"
#include "UnitySH.hlsl"
#include "TAUtils.hlsl"
#include "SRP/Library/Lighting.hlsl"
struct AHDLightInfo
{
    float3 directionalLightDir;
    float3 directionalLightCol;
    float3 ambientLightCol;
};



/*********************************
 * Extract AHD
 *********************************/


inline AHDLightInfo DirectionalLightmapToAHD(float2 lightmapUV, float3 vertexWorldNormal)
{
    float4 lightDirInTex = TA_TEX2D_LIGHTMAP_DIR(lightmapUV);
    float4 lightDir      = float4(2 * lightDirInTex - 1);

    float4 lightColInTex = TA_TEX2D_LIGHTMAP(lightmapUV);
    float3 lightCol      = lightColInTex.rgb * lightColInTex.w * lightColInTex.w * 6;            // decode


    float  mainLightFactor = length(lightDir.xyz);
    float3 mainLightDir    = normalize(lightDir.xyz);
    float  nDotL           = max(lightDir.w, dot(mainLightDir, vertexWorldNormal));

    AHDLightInfo ahdInfo = (AHDLightInfo)0;
    ahdInfo.directionalLightDir = mainLightDir;
    ahdInfo.directionalLightCol = mainLightFactor * lightCol / max(0.001, nDotL);
    ahdInfo.ambientLightCol     = lightCol * (1 - mainLightFactor);

    return ahdInfo;
}



inline AHDLightInfo RuntimeLightInfoWrapToAHD(float3 lightColor, float3 lightDir)
{
    AHDLightInfo info = (AHDLightInfo)0;
    info.directionalLightCol = lightColor;
    info.directionalLightDir = lightDir;
    return info;
}



// use sh9 as ambient
inline AHDLightInfo RuntimeLightInfoWrapToAHD(float3 lightColor, float3 lightDir, float3 wNormal)
{
    AHDLightInfo info = RuntimeLightInfoWrapToAHD(lightColor, lightDir);
    info.ambientLightCol = ShadeSH9(float4(wNormal, 1));
    return info;
}


// todo: add ronin sh9
#define SH9ToAHD(props, info)     \
            ACCESS_SH_INSTANCED_PROP(props)                 \
            info.directionalLightCol = RoninSHLight0Col;    \
            info.directionalLightDir = RoninSHLight0Dir;    \
            info.ambientLightCol     = RoninSHAmbient;




#endif