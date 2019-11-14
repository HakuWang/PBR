#ifndef __TA_PBS_CORE_CGINC__
#define __TA_PBS_CORE_CGINC__



/************************************************************
 * 提供 PBS 计算相关模型

 rely 
 TAPipelineData
 Unity_PBRCommon (included)
 ************************************************************/

#include "SRP/Library/Core.hlsl"
#include "TAUtils.hlsl"


/***************************************************************************************************
 *
 * Region : PBR Related Data Structure
 *
 ***************************************************************************************************/


struct PBSDirections
{
    half3 lightDir;
    half3 viewDir;
    half3 halfVec;
    half3 normal;

    half nDotL;
    half nDotV;
    half nDotH;
    half hDotL;
    half hDotV;
};



struct PBSSurfaceParam
{
// Surface Material Param

    // corresponding to GGX roughness4 fomula
    // 0 for totally smooth, 1 for totally rough
    half roughness;

    // 0 for totally non-metal(will to 0.04), 1 for totally metal
    half metallic;

    half AO;

    half indirectAO;


// Surface Color Param

    half3 specularColor;


    half3 diffuseColor;
};





/***************************************************************************************************
 *
 * Region : Struct Construct
 *
 ***************************************************************************************************/


// input must be normalized
inline PBSDirections CreatePBSDirections(half3 lightDir, half3 viewDir, half3 normal)
{
    PBSDirections directions = (PBSDirections)0;

    directions.lightDir = lightDir;
    directions.viewDir  = viewDir;
    directions.halfVec  = normalize(lightDir + viewDir);
    directions.normal   = normal;

    directions.nDotL = max(dot(directions.normal,   directions.lightDir),   0.0001);
    directions.nDotV = max(dot(directions.normal,   directions.viewDir),    0.0001);
    directions.nDotH = max(dot(directions.normal,   directions.halfVec),    0.0001);
    directions.hDotL = max(dot(directions.halfVec,  directions.lightDir),   0.0001);
    directions.hDotV = max(dot(directions.halfVec,  directions.viewDir),    0.0001);

    return directions;
}



inline PBSSurfaceParam ExtractPBRSurfaceParam(sampler2D paramTex, float2 paramMapUV, float metalScale, float roughScale, float3 albedo)
{
    float4 pbrParamInTex = tex2D(paramTex, paramMapUV);

    PBSSurfaceParam param = (PBSSurfaceParam)0;
    param.roughness     = pbrParamInTex.y * roughScale + 0.04;
    param.metallic      = pbrParamInTex.x * metalScale;
    param.AO            = pbrParamInTex.z;
    param.indirectAO    = pbrParamInTex.w;

    param.specularColor = lerp(unity_ColorSpaceDielectricSpec.xyz, albedo, param.metallic);
    param.diffuseColor  = albedo * (1 - param.metallic);

    return param;
}



/***************************************************************************************************
 *
 * Region : Fresnel Term
 *
 ***************************************************************************************************/


inline float3 TAFresnelTerm(float3 f0, float sDotL)
{
    return f0 + (1 - f0) * pow(1 - sDotL, 5);
}





/***************************************************************************************************
 *
 * Region : PBS Diffuse Model
 *
 ***************************************************************************************************/


inline half3 CalculateLambertDiffuse(float3 fresnel, float nDotL, float3 lightColor)
{
    return nDotL * lightColor * (1 - fresnel);
}


inline half3 CalculateHalfLambertDiffuse(float3 fresnel, float nDotL, float3 lightColor)
{
    float halfnDotL = nDotL * 0.5 + 0.5;
    return halfnDotL * lightColor  * (1 - fresnel);
}




/***************************************************************************************************
 *
 * Region : PBS Specular Model
 *
 ***************************************************************************************************/


///////////////////////////////////////////
// Blinn-Phong Model

inline half3 CalculateBlinnPhongBRDF(half roughness, half nDotH)
{
    half shinness = max(1 - roughness, 0.04);
    return 5 * shinness * pow(nDotH, 100 * shinness);
}

inline half3 CalculateBlinnPhongBRDF(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs)
{
    return CalculateBlinnPhongBRDF(surface.roughness, dirs.nDotH);
}



///////////////////////////////////////////
// Unity 2015 SigGrash GGX Specular Model
// Slide 26

inline half3 CalculateUnity2015GGXBRDF(half roughness, half nDotH, half lDotH)
{
    half r2 = roughness * roughness;
    half r4 = r2 * r2;

    half invD = (nDotH * r4 - nDotH) * nDotH + 1; // 2 mad, equals : nh^2 * (r4 - 1) + 1
    invD = invD * lDotH * 2;
    half halfinvD = 0.5 * invD;
    half invBRDF = (invD * roughness + halfinvD) * invD + 0.0001;
    return r4 / invBRDF;
}

inline half3 CalculateUnity2015GGXBRDF(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs)
{
    return CalculateUnity2015GGXBRDF(surface.roughness, dirs.nDotH, dirs.hDotL);
}



float SmithG1ForGGX(float ndots, float alpha)
{
    return 2.0 * ndots / (ndots * (2.0 - alpha) + alpha);
}


///////////////////////////////////////////
// Reference : Unity 2018 BRDF1
// almost same as SmithG1
// much better than 2015

inline float3 CalculateUnity2018GGXBRDF(float3 fresnel, float roughness, float nDotL, float nDotV, float nDotH, float hDotL)
{
    float a2 = roughness * roughness;
    float a4 = a2 * a2;
    float invD = nDotH * nDotH * (a4 - 1) + 1;
    invD = /*PI * */invD * invD;
    float d = a4 / invD;

    float gv = SmithG1ForGGX(nDotV, a2);
    float gl = SmithG1ForGGX(nDotL, a2);
    float v = gv * gl / (4 * nDotL * nDotV);// *3.1415;


    //float gl = nDotV * lerp(nDotL, 1, roughness);
    //float gv = nDotL * lerp(nDotV, 1, roughness);
    //float v = 0.5 / (gl + gv) *3.1415;

    return min(fresnel * d * v, 6);
}


inline float3 CalculateUnity2018GGXBRDF(float3 fresnel, PBSSurfaceParam surface, PBSDirections dirs)
{
    return CalculateUnity2018GGXBRDF(
        fresnel, surface.roughness,
        dirs.nDotL, dirs.nDotV, dirs.nDotH, dirs.hDotL);
}







/***************************************************************************************************
 *
 * Region : PBS IBL Model
 *
 ***************************************************************************************************/

// almost same as Unity_GlossyEnvironment
inline half3 GetIBLLight(float roughness, float3 viewDir, float3 wNormal)
{
    half3 reflectDir = reflect(-viewDir, wNormal);
    half  mip        = PerceptualRoughnessToMipmapLevel(roughness) * 2;

    half4 IBLCol = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, mip);
    return DecodeHDREnvironment(IBLCol, unity_SpecCube0_HDR);
}



///////////////////////////////////////////
// Unreal IBL Model

inline half3 UnrealIBLBRDFApprox(half3 specular, half roughness, half nDotV)
{
    const half4 c0 = half4(   -1, -0.0275, -0.572,  0.022);
    const half4 c1 = half4(    1,  0.0425,  1.04,  -0.04);
    const half2 c2 = half2(-1.04,  1.04);

    half4 r     = roughness * c0 + c1;
    half  a004  = min(r.x * r.x, exp2(-9.28 * nDotV)) * r.x + r.y;
    half2 AB    = c2 * a004 + r.zw;
    return specular * AB.x + AB.y;
}


half3 UnrealIBLApproximation(half3 specular, float roughness, float nDotV, float3 viewDir, float3 wNormal)
{
    half3 brdf   = UnrealIBLBRDFApprox(specular, roughness, nDotV);

#ifdef _DEBUG_IBL_ON
    return  roughness.xxx;
#endif

    half3 iblCol = GetIBLLight(roughness, viewDir, wNormal).xyz;
    return brdf * iblCol;
}


half3 UnrealIBLApproximation(PBSSurfaceParam surface, PBSDirections dirs)
{
    // hack roughness to make it smaller
    return UnrealIBLApproximation(surface.specularColor, (surface.roughness), dirs.nDotV, dirs.viewDir, dirs.normal);
}




///////////////////////////////////////////
// COD IBL Model
// don't know the proximation, only optimazation is not use exp2

half3 CodIBLBRDFApprox(half3 specular, half roughness, half metallic, half nDotV)
{
    half3 brdf   = lerp(0.45, 1, metallic) * specular * max(1 - roughness, 0.5);
    half  frenel = 1 - nDotV;
    frenel = max(frenel * frenel, 0.2);
    return 5 * brdf * frenel;
}


half3 CoDIBLApproximation(half3 specular, float roughness, half metallic, float nDotV, float3 viewDir, float3 wNormal)
{
    half3 brdf   = CodIBLBRDFApprox(specular, roughness, metallic, nDotV);
    half3 iblCol = GetIBLLight(roughness, viewDir, wNormal).xyz;
    return brdf * iblCol;
}


half3 CoDIBLApproximation(PBSSurfaceParam surface, PBSDirections dirs)
{
    // hack roughness to make it smaller
    return CoDIBLApproximation(surface.specularColor, sqrt(surface.roughness), surface.metallic, dirs.nDotV, dirs.viewDir, dirs.normal);
}



#endif