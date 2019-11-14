/***************************************************************************************************
*
* AlphaTest 相关代码
*

rely
 TAPipelineData (included)
 TAPipelineDataUtils(included)
 TALighting(included)
***************************************************************************************************/


#ifndef _TA_ALPHATEST_CGINC__
#define _TA_ALPHATEST_CGINC__

#include "TACGInclude/TAPipelineData.hlsl"
#include "TACGInclude/TAPipelineDataUtils.hlsl"
#include "TACGInclude/TALighting.hlsl"

/***************************************************************************************************
 * Region : AlphaTest Related Data Structure
 ***************************************************************************************************/

struct TAAlphaTestSurfData
{
    half4 albedo;
    half4 diffuseCol;
    half4 specularCol;
    half4 wNormal;
};

struct TAAlphaTestDirData
{
    half3 halfDir;
    half3 viewDir;
    half dot_nl;
    half dot_hn;
    half dot_nv;
};

struct TAAlphaTestLightData
{
    half indirectAO;
    half4 lightDir;
    half4 lightCol;
};

/***************************************************************************************************
 * Region : AlphaTest PackV2F Related Functions
 ***************************************************************************************************/


inline half3 TAPackV2FForAlphaTestWindProb(TAAppData v)
{
  
    half3 viewDir = normalize(TransformObjectToWorldNormal(v.normal.xyz));

    return viewDir;
}

/***************************************************************************************************
 * Region : AlphaTest Get Surf Data Related Functions
 ***************************************************************************************************/


inline TAAlphaTestSurfData TAGetAlphaTestSurfData(in TAV2F i, half4 tintColor, sampler2D mainTex)
{
    TAAlphaTestSurfData data;
    data.albedo = TA_TEX2D(mainTex, i.uv02.xy);

    data.diffuseCol.xyz = data.albedo.xyz * tintColor.xyz;
    data.wNormal.xyz = i.tToW[2].xyz;

    return data;
}


inline TAAlphaTestSurfData TAGetAlphaTestSurfDataHQ(in TAV2F i,half4 tintColor, sampler2D mainTex, sampler2D normalTex, half4 specColor)
{
    TAAlphaTestSurfData data;
    data.albedo = TA_TEX2D(mainTex, i.uv02.xy);

    data.diffuseCol.xyz = data.albedo.xyz * tintColor.xyz;

    #if _HASNORMAL_ON
        data.specularCol.xyz = specColor.xyz;
        half4 tNormal = 2 * TA_TEX2D(normalTex, i.uv02.xy) - 1;
        data.wNormal.xyz = CalculateWorldNormal(tNormal.xyz, i);

        #ifdef _TANSPARENCY_ON
            #ifdef _DEBUG_HQ
                float3 wnormal = i.tToW[2].xyz;
                float3 wbinormal = i.tToW[1].xyz;
                float3 wTangent = i.tToW[0].xyz;
                data.wNormal.xyz = wnormal;
            #else
                half ndotv = dot(data.wNormal.xyz, i.viewDir.xyz);
                if (ndotv <= 0.0)
                {
                    i.tToW[2].xyz *= -1;
                    data.wNormal.xyz = CalculateWorldNormal(tNormal.xyz, i);
                }
            #endif
        #endif
    #else
        data.wNormal.xyz = i.tToW[2].xyz;
    #endif
    
    return data;

}

/***************************************************************************************************
 * Region :AlphaTest Get Light Data Related Function
 ***************************************************************************************************/

inline TAAlphaTestLightData TAGetAlphaTestLightData(in TAV2F i,half lightmapOffset)
{
    TAAlphaTestLightData data;
    data.indirectAO = 1;

    data.lightDir = half4(1, 1, 1, 0.9);
    #ifdef _HASNORMAL_ON
        #ifdef _LIGHTMAP_ON
            data.lightDir = TA_TEX2D_LIGHTMAP_DIR(i.uv1.xy) - half4(0.5, 0.5, 0.5, 0.0);
            data.lightDir = half4(normalize(data.lightDir.xyz), data.lightDir.w);
        #else
            data.lightDir = half4(normalize(_MainLightPosition.xyz), 0.9);
        #endif
    #endif
            
    


    //get light color
    #ifdef _LIGHTMAP_ON
        half4 lightCol = TA_TEX2D_LIGHTMAP(i.uv1.xy);
        data.lightCol.xyz = lightCol.xyz * lightCol.w * lightCol.w * 6;
        data.lightCol.xyz = data.lightCol.xyz * data.lightDir.w;
    #else
        data.lightCol = half4(1, 1, 1, 1);
    #endif 
    data.lightCol.xyz = data.lightCol.xyz + lightmapOffset;

    return data;
}

/***************************************************************************************************
 * Region :AlphaTest Get Dir Data Related Function
 ***************************************************************************************************/


inline TAAlphaTestDirData TAGetAlphaTestDirData(in TAV2F i, TAAlphaTestSurfData surfData, TAAlphaTestLightData lightData)
{
    TAAlphaTestDirData data;
    data.viewDir = i.viewDir;
    data.dot_nl = max(dot(surfData.wNormal.xyz, lightData.lightDir.xyz), 0.0);
    #ifdef _HASNORMAL_ON
        data.halfDir = normalize(lightData.lightDir.xyz + data.viewDir.xyz);
        data.dot_hn = max(dot(data.halfDir.xyz, surfData.wNormal.xyz), 0.001);

        #ifdef _TANSPARENCY_ON
            data.dot_nl = dot(surfData.wNormal.xyz, lightData.lightDir.xyz);
        #endif

    #endif
    data.dot_nv = dot(surfData.wNormal.xyz, data.viewDir.xyz);

    return data;
}

/***************************************************************************************************
 * Region : AlphaTest Calculate Color Related Functions
 ***************************************************************************************************/

inline half3 TADiffuseForAlphaTestBase(half3 lightCol, half3 diffuseCol)
{
    return diffuseCol * lightCol;

}

inline half3 TADiffuseForAlphaTest(TAAlphaTestSurfData surfData, TAAlphaTestLightData lightData)
{
    half3 diffuse = TADiffuseForAlphaTestBase(lightData.lightCol.xyz, surfData.diffuseCol.xyz);
    return diffuse;

}

inline half3 TADiffuseForAlphaTestHQBase(half3 lightCol, half3 diffuseCol,half ndotl, half4 scatterColor, half scatterOffset)
{
    #ifndef _TANSPARENCY_ON
        return diffuseCol * lightCol;
    #else
        //half dot_lv = dot(lightDir, viewDir);
        if (ndotl <= 0)
        {
            half3 scatter = max(abs(ndotl), scatterOffset) * lightCol * diffuseCol;
            return scatter * scatterColor.xyz;
        }
        else
            return diffuseCol * lightCol;
    #endif

}

inline half3 TADiffuseForAlphaTestHQ(TAAlphaTestSurfData surfData, TAAlphaTestLightData lightData, TAAlphaTestDirData dirData, half4 scatterColor, half scatterOffset)
{
    half3 diffuse = TADiffuseForAlphaTestHQBase(lightData.lightCol.rgb, surfData.diffuseCol.rgb, dirData.dot_nl, scatterColor, scatterOffset);
    return diffuse;

}

inline half3 TADiffuseForAlphaTestWindProb(half3 lightCol, half3 lightDir, half3 worldNormal, half dirLightingScale)
{
    return max(dot(lightDir, worldNormal) * 0.5 + 0.5, 0) * lightCol * dirLightingScale;

}

inline half3 TADiffuseForAlphaTestWindProb(TAAlphaTestSurfData surfData, half3 lightCol, half3 lightDir, half dirLightingScale)
{
    half3 diffuse = TADiffuseForAlphaTestWindProb(lightCol.rgb,lightDir.xyz, surfData.wNormal.xyz, dirLightingScale);
    return diffuse;

}


/***************************************************************************************************
 * Region :  Light Probe Related Functions todo extract
 ***************************************************************************************************/

half3 LightProbe(TAAlphaTestLightData lightData, TAAlphaTestSurfData surfData)
{
    return surfData.diffuseCol.xyz * SampleSH(surfData.wNormal.xyz) * lightData.indirectAO;
}

#endif
