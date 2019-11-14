/***************************************************************************************************
*
* IncludeVertexColor 相关代码, 包含顶点色时的相关计算
*
*使用示例
*       #include "Features/IncludeVertexColor.hlsl"
*
*
*       TAV2F vert(TAAppData appdata)
*       {
*           TAV2F o = CreateV2FData(...);
*           o.color = TAPackV2FIncludeVertCol(appdata.color, _Color);
*           return o;
*       }
*
*
*       float4 frag(TAV2F i) : SV_Target
*      {
*           ...
*           SurfaceParam surface = ExtractPBRSurfaceParam(...);
*           surface.diffuseColor = TASurfDataIncludeVertCol(surface.diffuseColor, i.color);
*           ...
*       }

***************************************************************************************************/


#ifndef _TA_INCLUDE_VERTEX_COLOR_CGINC__
#define _TA_INCLUDE_VERTEX_COLOR_CGINC__

inline half4 TAPackV2FIncludeVertCol(half4 appDataCol, half4 colorProp) {
    half4 vcolor = appDataCol * appDataCol * colorProp;
    vcolor.xyz = vcolor.xyz * appDataCol.xyz;

    return vcolor;
}

inline half3 TASurfDataIncludeVertCol(half3 diffCol, half4 v2fCol)
{
    return diffCol * v2fCol.rgb;

}

#endif
