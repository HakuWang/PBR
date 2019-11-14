/***************************************************************************************************
*
* UV 动画相关代码
*
***************************************************************************************************/


#ifndef _TA_UV_ANIMATION_CGINC__
#define _TA_UV_ANIMATION_CGINC__

#include "UnityShaderVariables.cginc"


/*********************************
 * Property
 *********************************/

// Must Declare in Property
float4 _UVFactor;

#define     UV_ANIM_SPEED     _UVFactor.xy
#define     UV_ANIM_SCALE     _UVFactor.zw



/*********************************
* Anim Function
*********************************/

inline half2 UVAnimation(half2 originUV, float currentTime)
{
    return originUV + sin(UV_ANIM_SPEED * currentTime) * UV_ANIM_SCALE;
}

#endif
