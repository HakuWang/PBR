Shader "Exercises/PBS/SplitSumApply"
{
	Properties
	{
		[KeywordEnum(SPEC,BOTH)]_IBLMode("IBL Mode",Float) = 0

		_SpecularColor("Specular Color F0",Color) = (1,1,1,1)
		_LDEnviromentMap("LD Term Enviroment Cube Map",2D) = "white"{}
		_Roughness("Roughness",Range(0.02,1)) = 0.5
		_LUT("LUT",2D) = "white"{}
	}
		SubShader
		{

			Tags { "RenderType" = "Opaque" }

			Pass
			{
				Tags{"LightMode" = "ForwardBase"}

				CGPROGRAM
				#pragma multi_compile_fwdbase	
				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile _IBLMODE_SPEC _IBLMODE_BOTH

				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#include "AutoLight.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float4 texcoord : TEXCOORD0;
				#ifdef LIGHTMAP_ON
					float4 texcoord2 : TEXCOORD1;
				#endif
					float4 normal:NORMAL;
					float4 tangent:TANGENT;
				};

				struct v2f
				{
					float4 pos : SV_POSITION;
					half4 uv : TEXCOORD0;

					#ifdef LIGHTMAP_ON
						half2 uv2 : TEXCOORD6;
					#endif

					fixed4 TtoW0 : TEXCOORD2;
					fixed4 TtoW1 : TEXCOORD3;
					fixed4 TtoW2 : TEXCOORD4;
					fixed3 worldRefl : TEXCOORD5;
				};

				sampler2D _Diffuse, _Normal, _Specular, _LUT;
				float4 _Diffuse_ST, _Normal_ST;
				fixed4  _SpecularColor;
				float _Roughness;
				sampler2D _LDEnviromentMap;
				float _F0;

				#include "Utils.cginc"

				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv.xy = v.texcoord.xy*_Diffuse_ST.xy + _Diffuse_ST.zw;
					o.uv.zw = v.texcoord.xy*_Normal_ST.xy + _Normal_ST.zw;

					#ifdef LIGHTMAP_ON
						o.uv2 = v.texcoord2.xy * unity_LightmapST.xy + unity_LightmapST.zw;
					#endif

					fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
					float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
					fixed3 worldBinormal = cross(worldNormal, worldTangent)*v.tangent.w;

					o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
					o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
					o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
					fixed3 worldViewDir = UnityWorldSpaceViewDir(worldPos);
					o.worldRefl = reflect(-worldViewDir,worldNormal);

					return o;

				}

				half4 frag(v2f i) : SV_Target
				{
					float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
					fixed3 worldLight = normalize(UnityWorldSpaceLightDir(worldPos));
					fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
					fixed3 worldNormal = normalize(float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));
					float3 reflDir = reflect(-worldViewDir, worldNormal);


					// indirect specular 
					half3 specularF0 = _SpecularColor;

					float3 f90 = 1.0;
					half ndotv = dot(worldNormal, worldViewDir);

					//PrefilteringSum*EnvBrdf

					int mipCount = 8;
					int mipLevel = sqrt(_Roughness) * mipCount;

					float smoothness = saturate(1 - _Roughness);
					float lerpFactor = smoothness * (sqrt(smoothness) + _Roughness);
					float3 specDominantR = lerp(worldNormal, reflDir, lerpFactor);

					half4 uvlod = half4(specDominantR, mipLevel);
					//float3 PrefilteringSum = texCUBElod(_LDEnviromentMap, uvlod);
					float3 PrefilteringSum = samplePanoramicLOD(_LDEnviromentMap, uvlod.xyz, uvlod.w); 

					ndotv = clamp(ndotv, 0.05, 1.0);

					float2 uv = float2(ndotv, _Roughness);
					float3 sampleLUT = tex2D(_LUT, uv).rgb;

					float3 EnvBrdf = sampleLUT.r * specularF0 + sampleLUT.g;

					half3 indirectSpec = PrefilteringSum * EnvBrdf;

					#ifdef _IBLMODE_SPEC
						return  half4(indirectSpec, 1.0);
					#endif

					#ifdef _IBLMODE_BOTH
						
						//indirect diffuse
						float a = 1.02341f * _Roughness - 1.51174f;
						float b = -0.511705f * _Roughness + 0.755868f;
						lerpFactor = saturate((ndotv * a + b) * _Roughness);
						float3 diffDominantR = lerp(worldNormal, worldViewDir, lerpFactor);

						uvlod = half4(diffDominantR, mipLevel);
						//float3 indirectDiffLD = texCUBElod(_LDEnviromentMap, uvlod);
						float3 indirectDiffLD = samplePanoramicLOD(_LDEnviromentMap, uvlod.xyz, uvlod.w);


						half3 indirectDiffDFG = sampleLUT.b;
						half3 indirectDiff = indirectDiffDFG * indirectDiffLD;



						half3 indirectCol = indirectDiff  + indirectSpec;

						return half4(indirectCol,1.0);
					#endif
					}
					ENDCG
				}
		}

			FallBack "Specular"
}
