/***************************************************************************************************
*
* Wind Vertex Animation 相关代码
*
需要按照如下方式使用：
 *
 *      HLSLPROGRAM
 *      #include "Features/WindVertexAnimation.hlsl"
 *      ...
 *		TAV2F vert(TAAppData i)
 *		{
 *		 TAV2F o;
 *		 v.vertex = TAWindVertexAnimation(v, _WindEdgeFlutter, _Frequence,_Wind);// add wind vertex animation
 *		TAV2F o = CreateV2FData(v, _WorldSpaceCameraPos, _MainTex_ST, float4(0, 0, 0, 0)); //常规 v2f 数据打包
 *		...
 *		}
 *     
 *      
 *

***************************************************************************************************/


#ifndef _TA_WINDVERTEXANIMATION_CGINC__
#define _TA_WINDVERTEXANIMATION_CGINC__

 /***************************************************************************************************
  * Region :  Curve Utils Functions
  ***************************************************************************************************/

float4 SmoothCurve(float4 x) {
	return x * x *(3.0 - 2.0 * x);
}

float4 TriangleWave(float4 x) {
	return abs(frac(x + 0.5) * 2.0 - 1.0);
}

float4 SmoothTriangleWave(float4 x) {
	return SmoothCurve(TriangleWave(x));
}

//Animate Vertex Function
inline float4 AnimateVertex2(float4 pos, half3 normal, half4 animParams, float4 wind, float2 time)
{
	float fDetailAmp = 0.1f;
	float fBranchAmp = 0.3f;

	// Phases (object, vertex, branch)
	float fObjPhase = dot(UNITY_MATRIX_M[3].xyz, 1);
	float fBranchPhase = fObjPhase + animParams.x;

	float fVtxPhase = dot(pos.xyz, animParams.y + fBranchPhase);

	// x is used for edges; y is used for branches
	float2 vWavesIn = time + float2(fVtxPhase, fBranchPhase);

	// 1.975, 0.793, 0.375, 0.193 are good frequencies
	float4 vWaves = (frac(vWavesIn.xxyy * float4(1.975, 0.793, 0.375, 0.193)) * 2.0 - 1.0);

	vWaves = SmoothTriangleWave(vWaves);
	float2 vWavesSum = vWaves.xz + vWaves.yw;

	// Edge (xz) and branch bending (y)
	float3 bend = animParams.y * fDetailAmp * normal.xyz;
	bend.y = animParams.w * fBranchAmp;
	pos.xyz += ((vWavesSum.xyx * bend) * half3(1, 0.2f, 1) + (wind.xyz * vWavesSum.y * animParams.w)) * wind.w;

	// Primary bending
	// Displace position
	pos.xyz += animParams.z * wind.xyz;

	return pos;
}

//Wind Animate Vertex Function
float4 TAWindVertexAnimation(TAAppData v, half windEdgeFlutter, half frequence, float4 wind)
{
	#ifndef _GRAPHIC_LOW
		float4 tempWind;

		// 通过alpha通道判断顶点是否飘动
		half2 blendingFact = v.color.rg;

		// 风的方向
		tempWind.xyz = mul((float3x3)UNITY_MATRIX_I_M, wind.xyz);

		tempWind.w = wind.w * blendingFact.x;

		// 风的参数
		half4 windParams = half4(0, windEdgeFlutter, blendingFact.xy);

		// 风移动 按照_Frequence 放大缩小偏移
		float windTime = _Time.y * frequence;

		float4 mdlPos = AnimateVertex2(v.vertex, v.normal, windParams, tempWind, windTime);

		return mdlPos;

		//float4 wPos = mul(unity_ObjectToWorld, mdlPos);
		//o.vertex = mul(UNITY_MATRIX_VP, wPos);
		//half3 wView = _WorldSpaceCameraPos.xyz - wPos.xyz;
		//o.viewDir = half4(normalize(wView), 0);
		//o.uv0.xy = TRANSFORM_TEX(v.uv0.xy, _MainTex);
		//#ifdef _LIGHTMAP_ON
		//	o.uv1.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		//#endif
		//#if _HASNORMAL_ON
		//	half3 wNormal = normalize(UnityObjectToWorldNormal(v.normal));
		//	half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
		//	half3 wBitangent = cross(wNormal, wTangent)*v.tangent.w*unity_WorldTransformParams.w;
		//	o.t2w0 = half3(wTangent.x, wBitangent.x, wNormal.x);
		//	o.t2w1 = half3(wTangent.y, wBitangent.y, wNormal.y);
		//	o.t2w2 = half3(wTangent.z, wBitangent.z, wNormal.z);
		//#else
		//	o.t2w0 = normalize(UnityObjectToWorldNormal(v.normal));
		//#endif
	#else
		return v.vertex;

	//	o.t2w0 = normalize(UnityObjectToWorldNormal(v.normal));
	//	float4 wPos = mul(unity_ObjectToWorld, v.vertex);
	//	o.vertex = mul(UNITY_MATRIX_VP, wPos);
	//	half3 wView = _WorldSpaceCameraPos.xyz - wPos.xyz;
	//	o.viewDir = half4(normalize(wView), 0);
	//	o.uv0.xy = TRANSFORM_TEX(v.uv0.xy, _MainTex);
	//#ifdef _LIGHTMAP_ON
	//	o.uv1.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	//#endif

	#endif

	//#ifdef _DYNAMIC_WEATHER_RAIN
	//	//o.vertexNormal = wNormal;
	//	o.uv1.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	//	half2 rainUV = RainUV(wPos.xz, 9, 0.4, 14);
	//	o.rainUV = rainUV;
	//#endif
	//#ifdef _DYNAMIC_WEATHER_SNOW
	//	//o.snowrange = dot(wNormal,half3(0,1,0));
	//	o.wPosvs = wPos.xz;
	//#endif
}

#endif
