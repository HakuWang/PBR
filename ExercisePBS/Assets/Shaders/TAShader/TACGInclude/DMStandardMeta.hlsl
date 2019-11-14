// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef DM_STANDARD_META_INCLUDED
#define DM_STANDARD_META_INCLUDED

// Functionality for Standard shader "meta" pass
// (extracts albedo/emission for lightmapper etc.)

#include "UnityCG.cginc"
#include "UnityStandardInput.cginc"
#include "UnityMetaPass.cginc"
#include "UnityStandardCore.cginc"

float4 MetaVertexPosition(float4 vertex, float2 uv1, float2 uv2, float4 lightmapST)
{
#if !defined(EDITOR_VISUALIZATION)
    if (unity_MetaVertexControl.x)
    {
        vertex.xy = uv1 * lightmapST.xy + lightmapST.zw;
        // OpenGL right now needs to actually use incoming vertex position,
        // so use it in a very dummy way
        vertex.z = vertex.z > 0 ? 1.0e-4f : 0.0f;
    }
    return mul(UNITY_MATRIX_VP, float4(vertex.xyz, 1.0));
#else
    return UnityObjectToClipPos(vertex);
#endif
}

struct v2f_meta
{
    float4 pos      : SV_POSITION;
    float4 uv       : TEXCOORD0;
#ifdef EDITOR_VISUALIZATION
    float2 vizUV        : TEXCOORD1;
    float4 lightCoord   : TEXCOORD2;
#endif
};

v2f_meta vert_meta (VertexInput v)
{
    v2f_meta o;
    o.pos = MetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST);
    o.uv = TexCoords(v);
#ifdef EDITOR_VISUALIZATION
    o.vizUV = 0;
    o.lightCoord = 0;
    if (unity_VisualizationMode == EDITORVIZ_TEXTURE)
        o.vizUV = UnityMetaVizUV(unity_EditorViz_UVIndex, v.uv0.xy, v.uv1.xy, v.uv2.xy, unity_EditorViz_Texture_ST);
    else if (unity_VisualizationMode == EDITORVIZ_SHOWLIGHTMASK)
    {
        o.vizUV = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
        o.lightCoord = mul(unity_EditorViz_WorldToLight, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1)));
    }
#endif
    return o;
}

float4 _DiffuseTex_ST;
sampler2D _DiffuseTex;
sampler2D _SpecularTex;

float4 frag_meta (v2f_meta i) : SV_Target
{
    UnityMetaInput o;
    UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);

#ifdef EDITOR_VISUALIZATION
	half3 albedo = _Color.rgb * tex2D(_DiffuseTex, i.uv.xy);
	half metallic = tex2D(_SpecularTex, i.uv.xy).x;
	half3 diffColor = albedo * OneMinusReflectivityFromMetallic(metallic);
    o.Albedo = diffColor;
    o.VizUV = i.vizUV;
    o.LightCoord = i.lightCoord;
	o.SpecularColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
#else
    float4 albedo = tex2D(_DiffuseTex, i.uv.xy);
	float4 gloss = tex2D(_SpecularTex, i.uv.xy);
	gloss.y = gloss.y;
	float metallic = gloss.x;
	float3 specularCol = GammaToLinearSpace(lerp(0.2209, albedo.xyz, metallic));

	o.Albedo = albedo.xyz * _Color.xyz;
	o.SpecularColor = specularCol;
#endif

	o.Emission = 0;// albedo.xyz * _Color.xyz;

    return UnityMetaFragment(o);
}

#endif // DM_STANDARD_META_INCLUDED