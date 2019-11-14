/***************************************************************************************************
*
* UV 动画相关代码
*
***************************************************************************************************/


#ifndef _TA_UV_ANIMATION_CGINC__
#define _TA_UV_ANIMATION_CGINC__


/*********************************
* Anim Function
*********************************/

inline half2 UVAnimation(half2 originUV, float currentTime, half4 uvFactor)
{
    return originUV + sin(uvFactor.xy * currentTime) * uvFactor.zw;
}

inline half2 TAPackV2FForUVAnimation(half2 originUV, half4 uvFactor)
{
    half2 uvAni = UVAnimation(originUV, _Time.y, uvFactor); //UVAnimation(v, o.uv0);
    return uvAni;
}

#endif
