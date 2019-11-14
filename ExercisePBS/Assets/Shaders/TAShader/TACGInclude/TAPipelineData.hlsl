/***************************************************************************************************
 * 
 * 定义主要数据结构，并给出基本打包和访问方式
 *
 * 宏开关
    _LIGHTMAP_ON        影响是否启用 UV1 作为 lightmap uv
    _PRECISE_TBN        影响是否启用精准的 TBN（否则可能是非标准化的）


 * Rely:
 *      1. Core.hlsl  (Contained, for UNITY_VERTEX_INPUT_INSTANCE_ID define)
 *      2. TAUtils    (Contained, for UnityObjectToWorldNormal / UnityObjectToWorldDir)
 *
 ***************************************************************************************************/


#ifndef __TA_PIPELINE_DATA_HLSL__
#define __TA_PIPELINE_DATA_HLSL__


#include "SRP/Library/Core.hlsl"
#include "TAUtils.hlsl"





/***************************************************************************************************
 *
 * Region : App Data
 *
 ***************************************************************************************************/

struct TAAppData
{
    UNITY_VERTEX_INPUT_INSTANCE_ID

    half4  color    : COLOR;
    half4  vertex   : POSITION;
    half3  normal   : NORMAL;
    half4  tangent  : TANGENT;
    half2  uv0      : TEXCOORD0;

#ifdef _LIGHTMAP_ON
    half2  uv1      : TEXCOORD1;
#endif

    half2  uv2      : TEXCOORD2;
};




/***************************************************************************************************
 *
 * Region : v2f Data
 *
 ***************************************************************************************************/



/*********************************
 * v2f 数据结构定义
 *********************************/

 // Light Map UV
#ifdef _LIGHTMAP_ON
#define DATA_LIGHTMAP_UV_TEXCOORD1      float2 uv1 : TEXCOORD1;
#else
#define DATA_LIGHTMAP_UV_TEXCOORD1      // no light map, nothing
#endif


/**
 * Tagnet To World Matrix, and World Position
 * will use TEXCOORD i. i+1. i+2
 *
 * 1. In _PRECISE_TBN pattern, contains wtangent, wnormal, wbinormal
 *    xyz is tbn, w is world position
 * 2. In NOT _PRECISE_TBN pattern, contains wtangent, wnormal, tangent.sign
 *
 * TODO: this pack is not very good, since wpos can be very large while tbn very small (in [-1, 1])
 * now we use half4, but be caution that for really large world, 'half' may not be sufficiant for wpos
 */
#define DATA_TtoW_WPos(i)      half4 tToW[3] : TEXCOORD##i;



/**
 * 数据结构定义，用法如下：
 *  V2F_BEGEIN
 *      half4 viewDir : TEXCOORD2;
 *      DATA_TtoW_WPos(3)
 *  V2F_END
 */
#define V2F_BEGEIN      \
    struct TAV2F {                              \
        UNITY_VERTEX_INPUT_INSTANCE_ID          \
        half4 color         : COLOR;            \
        half4 vertex        : SV_POSITION;      \
        half4 uv02          : TEXCOORD0;        \
        DATA_LIGHTMAP_UV_TEXCOORD1


#define V2F_END };




/*********************************
* Data Pack/Access Utils -- TBN
*********************************/

// 将 TBN 和 WorldPos 压缩到 3 个 float4 中
inline void GetPackedT2W(TAAppData inData, out half4 tToW[3])
{
    // from CreateTangentToWorldPerVertex to calc TBN
    half3 wNormal  = TransformObjectToWorldNormal(inData.normal);
    half3 wTangent = TransformObjectToWorldDir(inData.tangent.xyz);
    half  sign     = unity_WorldTransformParams.w * inData.tangent.w;

    #ifndef _PRECISE_TBN
        half3 wBiNormal = cross(wNormal, wTangent.xyz) * sign;
    #else
        half3 wBiNormal = sign;
    #endif

    // get worldPos
    half4 wPos = mul(UNITY_MATRIX_M, inData.vertex);

    // Pack Data
    tToW[0] = half4(wTangent.xyz, wPos.x);
    tToW[1] = half4(wBiNormal.xyz, wPos.y);
    tToW[2] = half4(wNormal.xyz, wPos.z);


  
}


inline void RenormalizeT2W(inout half4 tToW[3])
{
#ifdef _PRECISE_TBN
    float3 tangent  = normalize(tToW[0].xyz);
    float3 normal   = normalize(tToW[2].xyz);
    float3 binormal = cross(normal, tangent) * tToW[1].x;
    tToW[0] = half4(tangent,  tToW[0].w);
    tToW[1] = half4(binormal, tToW[1].w);
    tToW[2] = half4(normal,   tToW[2].w);
#else
    // do nothing, just leave as it is
#endif
}



// 将压缩数据的各分量提取出来
#define GetWorldPos(v2fData) (half4((v2fData).tToW[0].w, (v2fData).tToW[1].w, (v2fData).tToW[2].w, 1))
#define GetWorldTangent(v2fData) ((v2fData).tToW[0].xyz)
#define GetWorldNormal(v2fData)  ((v2fData).tToW[2].xyz)



// 将压缩数据的 TBN 矩阵使用起来
#define MatrixWorldToTangent(v2fData) float3x3((v2fData).tToW[0].xyz, (v2fData).tToW[1].xyz, (v2fData).tToW[2].xyz)

// T 和 W 之间的转换
#define WorldToTangent(v2fData, dir) ( mul(MatrixWorldToTangent(v2fData), (dir)) )
#define TangentToWorld(v2fData, dir) ( mul((dir), MatrixWorldToTangent(v2fData)) )



/*********************************
 * Data Access Utils  -- UV02
 *********************************/

 // 获取打包的 UV0 和 UV2
#define UV0(v2fData)            ((v2fData).uv02.xy)
#define UV2(v2fData)            ((v2fData).uv02.zw)
#define LightMapUV(v2fData)     ((v2fData).uv1.xy)


/*********************************
* Data Pack/Access Utils -- LightMap UV
*********************************/

#ifdef _LIGHTMAP_ON
#define PackLightMapUV(v2fData, appData)        (LightMapUV(o) = appData.uv1 * unity_LightmapST.xy + unity_LightmapST.zw)
#else
#define PackLightMapUV(v2fData, appData)        // no light map, nothing to do
#endif




#endif