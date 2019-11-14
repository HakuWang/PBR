/************************************************************
 * ��Ĺ��Ŀʹ�õĳ��� Shadow ����
 *
 * �����õĺ�
 * 1. ALPHA_TEST : ֧�� alpha test �� shadow Ͷ��
 *                 ���Զ����� _MainTex �� _Cutoff ��������
 *
 ************************************************************/


#ifndef __DM_SHADOW_INCLUDED__
#define __DM_SHADOW_INCLUDED__

#include "Unity_Shadow.hlsl"

#ifdef ALPHA_TEST
sampler2D _MainTex;
half      _Cutoff;
#endif


// Struct Define For Shadow
struct appdata_shadow
{
    half4 color     : COLOR;
    half4 vertex    : POSITION;
    half3 normal    : NORMAL;
    half4 tangent   : TANGENT;
    half4 texcoord  : TEXCOORD0;
};

struct v2f_shadow
{
    float4 pos  : SV_POSITION;

#ifdef ALPHA_TEST
    float2 tex  : TEXCOORD1;
#endif
};


v2f_shadow vert_shadow(appdata_shadow v)
{
    v2f_shadow o;
    o.pos = ClipSpaceShadowCasterPos(v.vertex, v.normal);

#ifdef ALPHA_TEST
    o.tex = v.texcoord;
#endif

    return o;
}

half4 frag_shadow(v2f_shadow i) : SV_Target
{
#ifdef ALPHA_TEST
    half4 alpha = tex2D(_MainTex, i.tex);
    clip(alpha.a - _Cutoff);
#endif
    return 0;
}


#endif //DM_SHADOW_INCLUDED