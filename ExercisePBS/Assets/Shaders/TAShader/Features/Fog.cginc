/***************************************************************************************************
*
* 雾效相关代码
* 
*

——base_on
_TERRAIN_ON
_MIX_ON
ALPHATEST
ONE_TERRAIN

_VERTEXFOG_ON
_VERTEXAMINATION_ON
_EFFECTLIGHT_ON
SELFSHADOW

_IBR_ON
_EMISSION_ON
_UVANIMATION_ON
SSS_ON
_HIGHLIGHT_ON

todo:
_DYNAMIC_WEATHER
_BASEWET_ON

***************************************************************************************************/


#ifndef _TA_FOG_CGINC__
#define _TA_FOG_CGINC__




/*********************************
* Vertex Fog
*********************************/

// Parameter declare
#ifdef _VERTEXFOG_ON
    half    _m_FogHeight;
    half    _m_FogDensity;
    half    _m_FogHeightFallOff;
    half    _m_FogMaxOpacity;
    half    _m_FogStartDistance;
    half    _m_FogCutoffDistance;
    fixed4  _m_FogColor;



// TODO: ugly code
// for vs
half4 CalculateVertexFog(float3 _cameraToReceiver)
{
    _m_FogColor.w = 1.0 - _m_FogMaxOpacity;

    float collapsedFogParameterPower = clamp(-(_m_FogHeightFallOff / 1000) * (_WorldSpaceCameraPos.y - _m_FogHeight) * 100, -125, 126);
    float collapsedFogParameter = (_m_FogDensity / 1000) * pow(2.0, collapsedFogParameterPower);
    float4 _FogParams2;
    float4 _FogParams3;

    _FogParams2.x = collapsedFogParameter;
    _FogParams2.y = _m_FogHeightFallOff / 1000;
    _FogParams2.w = _m_FogStartDistance * 100;

    _FogParams3.x = _m_FogDensity / 1000;
    _FogParams3.y = _m_FogHeight * 100;
    _FogParams3.w = _m_FogCutoffDistance * 100;

    float4 result;
    result.xyz = _m_FogColor.rgb;
    float minFogOpacity = _m_FogColor.w;

    float3 cameraToReceiver = _cameraToReceiver;
    float  cameraToReceiverLengthSqr = dot(cameraToReceiver, cameraToReceiver);
    float  cameraToReceiverLengthInv = rsqrt(cameraToReceiverLengthSqr);
    float  cameraToReceiverLength = cameraToReceiverLengthSqr * cameraToReceiverLengthInv;
    float3 cameraToReceiverNormalized = cameraToReceiver * cameraToReceiverLengthInv;

    float rayOriginTerms = _FogParams2.x;
    float rayLength = cameraToReceiverLength;
    float rayDirectionY = cameraToReceiver.y;

    float excludeDistance = max(0, _FogParams2.w);

    if (excludeDistance > 0)
    {
        float excludeIntersectionTime = excludeDistance * cameraToReceiverLengthInv;
        float cameraToExclusionIntersectionY = excludeIntersectionTime * cameraToReceiver.y;
        float exclusionIntersectionY = _WorldSpaceCameraPos.y * 100 + cameraToExclusionIntersectionY;
        float exclusionIntersectionToReceiverY = cameraToReceiver.y - cameraToExclusionIntersectionY;

        rayLength = (1.0 - excludeIntersectionTime) * cameraToReceiverLength;
        rayDirectionY = exclusionIntersectionToReceiverY;

        float exponent = max(-127.0, _FogParams2.y * (exclusionIntersectionY - _FogParams3.y));
        rayOriginTerms = _FogParams3.x * exp2(-exponent);
    }

    float fallOff = max(-127, _FogParams2.y * rayDirectionY);
    float lineIntegral = (1 - exp2(-fallOff)) / fallOff;
    float lineIntegralTaylor = log(2) - (0.5 * log(2) * log(2)) * fallOff;
    float exponentialHeightLineIntegralShared = rayOriginTerms * (abs(fallOff) > 0.01 ? lineIntegral : lineIntegralTaylor);
    float exponentialHeightLineIntegral = exponentialHeightLineIntegralShared * rayLength;

    result.w = max(saturate(exp2(-exponentialHeightLineIntegral)), minFogOpacity);

    if (_FogParams3.w > 0 && cameraToReceiverLength > _FogParams3.w)
    {
        result.w = 1;
    }
    //return _FogParams3;
    return result;
}

inline half3 GetVertexFogFColor(half3 originCol, float4 fog)
{
    half3 color = lerp(originCol, half3(fog.xyz * (1 - fog.w)), (1 - fog.w));
    return color;
}

#endif   // _VERTEXFOG_ON



#endif
