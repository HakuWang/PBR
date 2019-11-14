/***************************************************************************************************
 * 
 * 提供数学工具
 * 包含常用数学工具，和矩阵向量运算工具（ 如果后续矩阵太多，可以考虑移出单列 ）
 *
 ***************************************************************************************************/


#ifndef __TA_UTILS_MATH_HLSL__
#define __TA_UTILS_MATH_HLSL__


#define E 2.71828f

inline half Pow3(half x)
{
    return x*x*x;
}

inline half Pow4(half x)
{
    return x*x*x*x;
}

inline half Pow5(half x)
{
    return x*x*x*x*x;
}


inline half3 PerPixelWorldNormal(half3 normalTangent, half4 tangentToWorld[3])
{
    half3 tangent  = normalize(tangentToWorld[0].xyz);
    half3 binormal = normalize(tangentToWorld[1].xyz);
    half3 normal   = normalize(tangentToWorld[2].xyz);

    tangent = normalize(tangent - normal * dot(tangent, normal));
    float3 newB = cross(tangent, normal);
    binormal = newB * sign(dot(newB, binormal));

    return normalize(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z);
}


#endif