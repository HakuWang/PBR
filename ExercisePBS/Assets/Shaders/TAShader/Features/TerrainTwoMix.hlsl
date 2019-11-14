/***************************************************************************************************
 * 
 * 特性：地形
 *
 *  混合
 *  1. 需要两种细节材质及其法线贴图，使用顶点色进行混合
 *  2. 混合中使用顶点色的 G 通道，可以通过调整 TERRAIN_MIX_CHANNEL 来进行修改
       混合受 _TerrainHardness 影响
 *
 *  对于 Albedo 贴图
    1. xyz 通道作为固有色，受 _TerrainTint 影响
    2. w 通道的平方，作为材质 smoothness 参数，受 _SmoothnessFactor 影响

 *  Usage:
 *
 ***************************************************************************************************/


#ifndef __FEATURE_TERRAIN_CGINC__
#define __FEATURE_TERRAIN_CGINC__

#include "../TACGInclude/TAUtils.hlsl"
#include "../TACGInclude/TAPBS.hlsl"

/*********************************
 * Config Define
 *********************************/

#define TERRAIN_MIX_CHANNEL(color)  (color).g



/*********************************
 * Struct Define
 *********************************/

#define TerrainBlendInfo half

struct TerrainNormalInfo
{
    half4 tNormal;
    half3 wNormal;
};


inline TerrainBlendInfo UnpackTerrainBlendParam(float4 vertexColor, float terrainHardness)
{
    half blendChannelValue = TERRAIN_MIX_CHANNEL(vertexColor);
    return saturate((2 * blendChannelValue - 1) * terrainHardness + 0.5);
}


inline TerrainBlendInfo UnpackTerrainBlendParam(TAV2F v2fData, float terrainHardness)
{
    return UnpackTerrainBlendParam(v2fData.color, terrainHardness);
}



inline half4 GetTerrainAlbedo(half4 tex1Color, half4 tex2Color, TerrainBlendInfo blendInfo, half4 tint1, half4 tint2)
{
    tex1Color = tex1Color * tint1;
    tex2Color = tex2Color * tint2;
    return lerp(tex2Color, tex1Color, blendInfo);
}



inline half4 GetTerrainAlbedo(sampler2D tex1, half2 uvForTex1,
                              sampler2D tex2, half2 uvForTex2,
                              TerrainBlendInfo blendInfo,
                              half4 tint1,    half4 tint2)
{
    return GetTerrainAlbedo(TA_TEX2D(tex1, uvForTex1), TA_TEX2D(tex2, uvForTex2), blendInfo, tint1, tint2);
}



inline TerrainNormalInfo GetTerrainNormalInfo(sampler2D normalTex1, half2 uvForTex1,
                                              sampler2D normalTex2, half2 uvForTex2,
                                              TerrainBlendInfo blendInfo,
                                              TAV2F v2fData)
{
    half4 normal1Raw = TA_TEX2D(normalTex1, uvForTex1);
    half4 normal2Raw = TA_TEX2D(normalTex2, uvForTex2);
    half4 tNormalRaw = lerp(normal2Raw, normal1Raw, blendInfo);

    TerrainNormalInfo info = (TerrainNormalInfo)0;
    info.tNormal = float4(normalize(tNormalRaw.xyz - 0.5), tNormalRaw.w);
    info.wNormal = TangentToWorld(v2fData, info.tNormal.xyz);
    return info;
}



inline PBSSurfaceParam ExtractPBRSurfaceParamForTerrain(TerrainNormalInfo normal, float4 albedo)
{
    float smoothness = albedo.w * albedo.w;
    float rawAO      = normal.tNormal.x + 0.5;

    PBSSurfaceParam param = (PBSSurfaceParam)0;
    param.roughness     = 1 - smoothness;
    param.metallic      = 0.05;
    param.AO            = rawAO * rawAO;
    param.indirectAO    = 1;
    param.specularColor = 0.015;
    param.diffuseColor  = albedo.xyz;

    return param;
}




half3 TerrrainIndirect(half3 ambientLight, half3 ambientSky, half3 ambientGround, TerrainNormalInfo normal)
{
    half  ambientBlendParam = normal.wNormal.y * 0.5 + 0.5;
    half3 ambientEnviroment = lerp(ambientGround, ambientSky, ambientBlendParam);
    return ambientLight + ambientEnviroment;
}




#endif