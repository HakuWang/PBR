/***************************************************************************************************
 * 
 * 常用纹理处理工具
 *
 * 支持的宏：
 * 1. USE_LOW_TEXTURE : 会使用高一级的 mipmap （即更模糊的图）
 ***************************************************************************************************/


#ifndef __TA_UTILS_TEXTURE_HLSL__
#define __TA_UTILS_TEXTURE_HLSL__




inline half4 TA_TEX2D(sampler2D tex, half2 uv)
{
    return tex2D(tex, uv);
}


inline half4 TA_TEX2D_LIGHTMAP(half2 uv)
{
    return SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, uv);
}

inline half4 TA_TEX2D_LIGHTMAP_DIR(half2 uv)
{
    return SAMPLE_TEXTURE2D(unity_LightmapInd, samplerunity_Lightmap, uv);
}



inline half3 GammaToLinearSpace(half3 sRGB)
{
    // Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
    return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);

    // Precise version, useful for debugging.
    //return half3(GammaToLinearSpaceExact(sRGB.r), GammaToLinearSpaceExact(sRGB.g), GammaToLinearSpaceExact(sRGB.b));
}


half3 DecodeHDREnvironment(half4 encodedIrradiance, half4 decodeInstructions)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    half alpha = max(decodeInstructions.w * (encodedIrradiance.a - 1.0) + 1.0, 0.0);
    // If Linear mode is not supported we can skip exponent part
    return (decodeInstructions.x * pow(abs(alpha), decodeInstructions.y)) * encodedIrradiance.rgb;
}


// Decodes HDR textures
// handles dLDR, RGBM formats
inline half3 DecodeHDR(half4 data, half4 decodeInstructions)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    half alpha = decodeInstructions.w * (data.a - 1.0) + 1.0;

    // If Linear mode is not supported we can skip exponent part
#if defined(UNITY_COLORSPACE_GAMMA)
    return (decodeInstructions.x * alpha) * data.rgb;
#else
#   if defined(UNITY_USE_NATIVE_HDR)
    return decodeInstructions.x * data.rgb; // Multiplier for future HDRI relative to absolute conversion.
#   else
    return (decodeInstructions.x * pow(alpha, decodeInstructions.y)) * data.rgb;
#   endif
#endif
}


inline half4 EncodeRGBE8(float3 rgb)
{
    half4 vEncoded;
    float maxComponent = max(max(rgb.r, rgb.g), rgb.b);
    float fExp = ceil(log2(maxComponent));
    vEncoded.rgb = rgb / exp2(fExp);
    vEncoded.a = (fExp + 128) / 255;
    return vEncoded;
}

inline float3 DecodeRGBE8(half4 rgbe)
{
    float3 vDecoded;
    float fExp = rgbe.a * 255 - 128;
    vDecoded = rgbe.rgb * exp2(fExp);
    return vDecoded;
}

inline half4 EncodeRGBM(float3 rgb, float perc)
{
    rgb *= 1.0 / perc;
    float a = saturate(max(max(rgb.r, rgb.g), max(rgb.b, 1e-5)));
    a = ceil(a * 255.0) / 255.0;
    return half4(rgb / a, a);
}

inline float3 DecodeRGBM(half4 rgbm, half perc)
{
    return perc * rgbm.rgb * rgbm.a;
}


inline half3 UnpackNormal(half3 packedNormal)
{
    return packedNormal * 2 - 1;
}



inline half3 UnpackScaleNormal(half3 packedNormal, half bumpScale)
{
    half3 normal = UnpackNormal(packedNormal);
    normal.xy *= bumpScale;
    return normal;
}


//-----------------------------------------------------------------------------
// Util image based lighting
//-----------------------------------------------------------------------------

// The *approximated* version of the non-linear remapping. It works by
// approximating the cone of the specular lobe, and then computing the MIP map level
// which (approximately) covers the footprint of the lobe with a single texel.
// Improves the perceptual roughness distribution.
half PerceptualRoughnessToMipmapLevel(half perceptualRoughness, uint mipMapCount)
{
    perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);

    return perceptualRoughness * mipMapCount;
}


#define UNITY_SPECCUBE_LOD_STEPS 6
half PerceptualRoughnessToMipmapLevel(half perceptualRoughness)
{
    return PerceptualRoughnessToMipmapLevel(perceptualRoughness, UNITY_SPECCUBE_LOD_STEPS);
}



#endif