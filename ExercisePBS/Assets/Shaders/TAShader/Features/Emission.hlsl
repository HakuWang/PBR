/***************************************************************************************************
*
* 自发光相关代码
*
*使用示例
*       #include "Features/Emission.hlsl"
*       ...
*
*       float4 frag(TAV2F i) : SV_Target
*      {
*           ...
*           half4 finalColor = RegularCalculation(...);//常规着色计算
*           finalColor += Emission(emissionTex, uv, diffuseCol, emissionCol);
*
*           ...
*       }
*
*
* reply
*     TAUtils(include) TA_TEX2D方法
***************************************************************************************************/


#ifndef _TA_INCLUDE_EMISSION_CGINC__
#define _TA_INCLUDE_EMISSION_CGINC__

#include "../TACGInclude/TAUtils.hlsl"

half3 Emission(sampler2D emissionTex, half2 uv,  half3 diffuseCol, half3 emissionCol)
{
    half3 emission = TA_TEX2D(emissionTex, uv).xyz;
    emission = emission * emissionCol * diffuseCol;
    return emission;

}

#endif
