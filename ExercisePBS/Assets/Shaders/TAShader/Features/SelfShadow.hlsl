/***************************************************************************************************
*
* EffectLight 相关代码
*

rely
 TAPipelineData (included)
 TAPipelineDataUtils(included)
 TALighting(included)


 需要按照如下方式使用：todo
 *
 *      HLSLPROGRAM
 *      #include "Features/EffectLight.hlsl"
 *      ...
 *		TAV2F vert(TAAppData i)
 *		{
 *		    TAV2F o = CreateV2FData(v, _WorldSpaceCameraPos, _MainTex_ST, float4(0, 0, 0, 0)); //常规 v2f 数据打包
 *          #ifdef _EFFECTLIGHT_ON
 *		        o.effectLight = TAPackV2FForEffectLight(v); //计算effectLight数据
 *          #endif
 *		    ...
 *		}

 *      half4 frag(TAV2F i) : SV_Target
 *      {
 *          ...
 *          TAAlphaTestSurfData surfData = TAGetAlphaTestSurfDataHQ(i, tintColorIns, _MainTex, _NormalTex, _SpecularColor);
 *
 *          #ifdef _EFFECTLIGHT_ON
 *		        half3 effectLightCol = TAAlphaTestEffectLight(i, surfData); 
 *          #endif
 *          ...
 *      }
 *
 *
 *
***************************************************************************************************/

#ifndef _TA_SelfShadow_CGINC__
#define _TA_SelfShadow_CGINC__

#include "TACGInclude/TAPipelineData.hlsl"
#include "TACGInclude/TALighting.hlsl"





#endif