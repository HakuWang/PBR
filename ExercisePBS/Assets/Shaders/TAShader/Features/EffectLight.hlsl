/***************************************************************************************************
*
* EffectLight 相关代码
*

rely
 TAPipelineData (included)
 TALighting(included)


 需要按照如下方式使用：
 *
 *      HLSLPROGRAM
 *      #include "Features/EffectLight.hlsl"
 *      half4 frag(TAV2F i) : SV_Target
 *      {
 *          ...
 *          TAAlphaTestSurfData surfData	= TAGetAlphaTestSurfData(i, tintColorIns, _MainTex);
 *          #ifdef _EFFECTLIGHT_ON
 *		        half3 effectLightCol = TAEffectLight(worldPos, surfData.wNormal.xyz, surfData.diffuseCol.rgb);
 *
 *          #endif
 *          ...
 *      }
 *
 *
 *
***************************************************************************************************/

#ifndef _TA_EffectLight_CGINC__
#define _TA_EffectLight_CGINC__

#include "TACGInclude/TAPipelineData.hlsl"
#include "TACGInclude/TALighting.hlsl"

inline half3 GetAlphaTestEffectLight(float3 posWorld, half3 normalWorld)
{
    half3 color = half3(0.0, 0.0, 0.0);

    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, posWorld);
        color += light.color * light.distanceAttenuation;
    }
    return color;
}

inline half3 TAEffectLight(half3 effectLightPos, half3 worldNoraml, half3 diffuseCol)
{
    half3 effectLight = GetAlphaTestEffectLight(effectLightPos, worldNoraml);
    effectLight = diffuseCol * effectLight;

    return effectLight;
}

#endif