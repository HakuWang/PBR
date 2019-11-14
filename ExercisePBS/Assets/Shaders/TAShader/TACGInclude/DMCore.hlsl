/***************************************************************************************************
 * 
 * 盗墓的通用部分
 *
 *  Rely:
 *      1. DMDataCore.cginc (for TAAppData / TAV2F)
        2. TADataStructureUtils
 *
 ***************************************************************************************************/


#ifndef __DM_CORE__
#define __DM_CORE__

#include "TAPipelineDataUtils.hlsl"
#include "TAPBS.hlsl"
#include "TAUtils.hlsl"

inline TAV2F CreateV2FData(TAAppData appData, const float3 wCamPos, float4 st1, float4 st2) {
    TAV2F o = (TAV2F)0;

    UNITY_SETUP_INSTANCE_ID(appData);
    UNITY_TRANSFER_INSTANCE_ID(appData, o);


    o.vertex = TransformObjectToHClip(appData.vertex.xyz);
    o.color = appData.color;
    UV0(o) = appData.uv0 * st1.xy + st1.zw;
    UV2(o) = appData.uv2 * st2.xy + st2.zw;
    PackLightMapUV(o, appData);


    half4 wPos = float4(TransformObjectToWorld(appData.vertex.xyz), 1);
    o.viewDir = wCamPos.xyz - wPos.xyz;

    GetPackedT2W(appData, o.tToW);

    return o;
}


inline void UnpackV2FData(inout TAV2F data) {
    RenormalizeT2W(data.tToW);
    data.viewDir = normalize(data.viewDir);
}


inline half3 DMDiffuse(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs, float3 lightColor, float3 cameraLightColor)
{
    half3 normalDiffuse = CalculateLambertDiffuse(fresnel, dirs.nDotL, lightColor);
    half3 cameraDiffuse = CalculateLambertDiffuse(fresnel, dirs.nDotV, cameraLightColor);
    return lerp(normalDiffuse, cameraDiffuse, 0.3) * surface.diffuseColor;
}


inline half3 DMSpecular(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs, half3 lightColor)
{
#if _GRAPHIC_HIGH || _GRAPHIC_MEDIUM
    return CalculateUnity2018GGXBRDF(fresnel, surface, dirs) * dirs.nDotL * lightColor;
#else
    return CalculateBlinnPhongBRDF(fresnel, surface, dirs)   * dirs.nDotL * lightColor * surface.specularColor;
#endif
}


// TODO: is it need to multiply specularColor?
inline half3 DMInSpecular(PBSSurfaceParam surface, PBSDirections dirs)
{
#if _GRAPHIC_HIGH
    return UnrealIBLApproximation(surface, dirs);
#elif _GRAPHIC_MEDIUM
    return CoDIBLApproximation(surface, dirs);
#else
    return 0;
#endif
}


// Debug




// custom debug



#ifdef BLEND_ON
    #define DEBUG_BLEND(finalColor, albedo, emission, transparent)  ADD_COLOR_TO_DEBUG(finalColor.xyz + albedo.xyz * emission, albedo.w * transparent);
#else
    #define DEBUG_BLEND(finalColor, albedo, emission, transparent)
#endif


// not containt blend
#define DebugDMColor(finalColor, lightMapColor, diffuse, specular, indirectDiffuse, indirectSpecular, AO)   \
    DEBUG_COLOR_BEGIN(finalColor, lightMapColor, diffuse, specular, indirectDiffuse, indirectSpecular, AO); \
    DEBUG_COLOR_END


#endif