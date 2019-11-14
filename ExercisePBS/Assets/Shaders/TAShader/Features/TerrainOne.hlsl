/***************************************************************************************************
 * 
 * 特性：地形
 *
 * 不进行混合，部分代码和 TerrainTwoMix 相同
 * wet: lujiacun has a wet
 *  Rely:
 *
 ***************************************************************************************************/


#ifndef __FEATURE_TERRAIN_NOT_MIX_HLSL__
#define __FEATURE_TERRAIN_NOT_MIX_HLSL__


// property declare
// todo: _SmoothnessFactor1 be _TerrainTint1.w
float3 _TerrainTint1;
float _SmoothnessFactor1;


/*********************************
 * Struct Define
 *********************************/


struct TerrainNormalInfo
{
    half4 tNormal;
    half3 wNormal;
};


inline TerrainNormalInfo CalculateWorldNormalForTerrainNotMix(sampler2D normalTex, float2 uv, TAV2F v2fData)
{
    half4 tNormal  = tex2D(normalTex, uv);
    float3 wNormal = TangentToWorld(v2fData, tNormal.xyz);

    TerrainNormalInfo info = (TerrainNormalInfo)0;
    info.tNormal = tNormal;
    info.wNormal = half4(normalize(wNormal), 1);
    return info;
}



// Albedo Calculation
inline half4 GetTerrainAlbedo(sampler2D tex, half2 uv)
{
    return tex2D(tex, uv) * half4(_TerrainTint1.xyz, _SmoothnessFactor1);
}



// same as Terrain Mix
inline PBSSurfaceParam ExtractPBRSurfaceParamForTerrain(TerrainNormalInfo normal, float4 albedo)
{
    float smoothness = albedo.w * albedo.w;
    float rawAO = normal.tNormal.x + 0.5;

    PBSSurfaceParam param = (PBSSurfaceParam)0;
    param.roughness     = 1 - smoothness;
    param.metallic      = 0.05;
    param.AO            = rawAO * rawAO;
    param.indirectAO    = 1;
    param.specularColor = 0.015;
    param.diffuseColor  = albedo.xyz;

    return param;
}



// same as Terrain Mix
half3 TerrrainIndirect(half3 ambientLight, half3 ambientSky, half3 ambientGround, TerrainNormalInfo normal)
{
    half  ambientBlendParam = normal.wNormal.y * 0.5 + 0.5;
    half3 ambientEnviroment = lerp(ambientGround, ambientSky, ambientBlendParam);
    return ambientLight + ambientEnviroment;
}



#endif