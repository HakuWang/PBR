Shader "Exercises/PBS/PBS_SpecularSetup"
{
	Properties
	{
		_SpecularColor("Specular Color F0",Color) = (1,1,1,1)
		_Specular("Specular Color F0",2D) = "white"{}
		_Diffuse("Diffuse Map",2D) = "white"{}
		_Normal("Normal Map",2D) = "white"{}
		_Enviroment("Enviroment Cube Map",2D) = "white"{}

		[Space(30)]

		_Roughness("Roughness",Range(0.02,1)) = 0.5
	
		[Header(Direct Light Settings)]
		[KeywordEnum(NONE,GGX,CODAPPROX)]_DirectSpec("Direct Specular mode",Float) = 0
		[KeywordEnum(NONE,SIMPLIFIED_DISNEY_DIFFUSE,FULL_DISNEY_DIFFUSE,LAMBERT_DIFFUSE,LAMBERT_MODIFIDED_DIFFUSE)]_DirectDiff("Direct Diffuse mode",Float) = 0

		[Header(Indirect Light Settings)]

		[Space(20)]

		[Toggle(ENABLE_INDIRECT_LIGHTING)] _EnableIndirectLighting("Enable Indirect Lighting?", Float) = 0

		[Toggle(ENABLE_REALTIME_SAMPLING)] _EnableRealtimeSampling("Enable Realtime Sampling?", Float) = 0

		[Header(Realtime Sampling Settings)]
		[KeywordEnum(NONE,IMPORTANCE_SAMPLING,PERFECT_REFLECTION,SPLITSUM,CODAPPROX,UEAPPROX,UNITYAPPROX,UNITYACTUALAPPROX)]_IndirectSpecIBL("Indirect Specular mode",Float) = 0
		[KeywordEnum(NONE,IMPORTANCE_SAMPLING,SPLITSUM,CODAPPROX,UEAPPROX,UNITYAPPROX,UNITYACTUALAPPROX)]_IndirectIBL("Indirect mode (will make Indirect Specular mode not used)",Float) = 0
		_MaxSampleCountMonteCarlo("Max Sample Count of Monte Carlo",Range(1,5000)) = 32

		[Header(LUT for Indirect Light  Settings)]
		[KeywordEnum(SPEC,BOTH)]_LutIBLMode("IBL Mode",Float) = 0
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

			#pragma shader_feature ENABLE_REALTIME_SAMPLING
			#pragma shader_feature ENABLE_INDIRECT_LIGHTING
			#pragma multi_compile LIGHTMAP_ON LIGHTMAP_OFF
			#pragma multi_compile _DIRECTSPEC_NONE _DIRECTSPEC_GGX _DIRECTSPEC_CODAPPROX
			#pragma multi_compile _DIRECTDIFF_NONE  _DIRECTDIFF_SIMPLIFIED_DISNEY_DIFFUSE _DIRECTDIFF_FULL_DISNEY_DIFFUSE _DIRECTDIFF_LAMBERT_DIFFUSE _DIRECTDIFF_LAMBERT_MODIFIDED_DIFFUSE
			#pragma multi_compile _INDIRECTSPECIBL_NONE _INDIRECTSPECIBL_IMPORTANCE_SAMPLING  _INDIRECTSPECIBL_PERFECT_REFLECTION _INDIRECTSPECIBL_SPLITSUM _INDIRECTSPECIBL_CODAPPROX _INDIRECTSPECIBL_UEAPPROX  _INDIRECTSPECIBL_UNITYAPPROX  _INDIRECTSPECIBL_UNITYACTUALAPPROX 
			#pragma multi_compile _INDIRECTIBL_NONE _INDIRECTIBL_IMPORTANCE_SAMPLING _INDIRECTIBL_SPLITSUM _INDIRECTIBL_CODAPPROX _INDIRECTIBL_UEAPPROX  _INDIRECTIBL_UNITYAPPROX  _INDIRECTIBL_UNITYACTUALAPPROX
			#pragma multi_compile _LUTIBLMODE_SPEC _LUTIBLMODE_BOTH

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
				half2 uv : TEXCOORD0;
				half2 uv2 : TEXCOORD1;
				fixed4 TtoW0 : TEXCOORD2;
				fixed4 TtoW1 : TEXCOORD3;
				fixed4 TtoW2 : TEXCOORD4;
				fixed3 worldRefl : TEXCOORD5;
				half3 vlight: TEXCOORD6;
			};

			sampler2D _Diffuse, _Normal, _Specular, _LUT;
			float4 _Diffuse_ST, _Normal_ST;
			fixed4  _SpecularColor;
			float _Gloss, _Roughness, _DisneyKss, _DisneyDiffuseRoughness, _Metallic;

			sampler2D _Enviroment;
			int _MaxSampleCountMonteCarlo;

			#include "PBSUtils.cginc"
			#include "ImportanceSample.cginc"
			#include "ImportanceSampleFrosbiteSplitSum.cginc"
			#include "EnvBRDFApprox.cginc"


			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord.xy;

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

				o.vlight = ShadeSH9(v.normal);

				return o;

			}

			half4 frag(v2f i) : SV_Target
			{
				//setup 
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 worldNormal = normalize(float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));

				fixed3 bump = UnpackNormal(tex2D(_Normal, i.uv.xy));
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				worldNormal = bump;


				half3 specular = 0;
				half3 specCol = _SpecularColor * tex2D(_Specular, i.uv.xy).rgb;
				half3 specularF0 = lerp(unity_ColorSpaceDielectricSpec, specCol, _Metallic);
				half reflectivity = SpecularStrength(specularF0);

				float3 albedo = tex2D(_Diffuse, i.uv.xy).rgb;
				float3 diffCol = albedo * (1 - reflectivity);

				half ndotl = max(dot(worldNormal, worldLight), 1e-8);
				half3 h = normalize((worldLight + worldViewDir));
				half ndoth = dot(worldNormal, h);
				half ndotv = max(dot(worldNormal, worldViewDir), 1e-8);
				half vdoth = dot(worldViewDir, h);
				float hdotl = dot(h, worldLight);

				_Roughness = min(_Roughness,0.98);

				//direct specular

				//Fresnel coefficient
				half3 specFresnel = specularF0 + (1 - specularF0) * pow(1 - dot(h, worldLight), 5);//_F0 is 0.5 or above for metal

				#ifdef _DIRECTSPEC_GGX

					half alpha_tr = _Roughness * _Roughness; //_Roughness =  1 表示越光滑
					half Dm = /* ndoth * */alpha_tr * alpha_tr / (UNITY_PI * pow((ndoth * ndoth * (alpha_tr * alpha_tr - 1) + 1), 2)); //Q  

					/*half Gmv = 2 * ndoth * ndotv / vdoth;
					half Gml = 2 * ndoth * ndotl / vdoth;
					half Gm = min(1, min(Gmv, Gml));*/

					float Gv = SmithG1ForGGX(/*vdoth*/ndotv, alpha_tr);
					float Gl = SmithG1ForGGX(/*hDotL*/ndotl, alpha_tr);

					float Gm = Gv * Gl;

					specular = specFresnel * Dm * Gm / (4 * ndotl * ndotv) * UNITY_PI;

				#endif

				#ifdef	_DIRECTSPEC_CODAPPROX

					specular = CODBlackOps2BRDF(specularF0, 1.0 - _Roughness, ndoth, vdoth);

				#endif


					//direct diffuse 
					half  diffuseTerm = 0;

					#ifdef _DIRECTDIFF_LAMBERT_DIFFUSE

						diffuseTerm = 1;
					#endif	

					#ifdef _DIRECTDIFF_LAMBERT_MODIFIDED_DIFFUSE

						diffuseTerm = 1 - specFresnel;

					#endif	

					#ifdef _DIRECTDIFF_SIMPLIFIED_DISNEY_DIFFUSE

						float Fss90 = sqrt(/*_DisneyDiffuseRoughness*/_Roughness)* hdotl * hdotl;
						float FD90 = 0.5 + 2 * Fss90;
						float fd = (1 + (FD90 - 1) * pow(1 - ndotl, 5)) * (1 + (FD90 - 1) * pow(1 - ndotv, 5));

						diffuseTerm = saturate(ndotl) * saturate(ndotv) * fd;
					#endif

					#ifdef _DIRECTDIFF_FULL_DISNEY_DIFFUSE

						float Fss90 = sqrt(/*_DisneyDiffuseRoughness*/_Roughness)* hdotl * hdotl;
						float Fss = (1 + (Fss90 - 1) * pow(1 - ndotl, 5)) * (1 + (Fss90 - 1) * pow(1 - ndotv, 5));
						float fss = (1 / (ndotl * ndotv) - 0.5) * Fss + 0.5;
						float FD90 = 0.5 + 2 * Fss90;
						float fd = (1 + (FD90 - 1) * pow(1 - ndotl, 5)) * (1 + (FD90 - 1) * pow(1 - ndotv, 5));

						diffuseTerm = saturate(ndotl) * saturate(ndotv) /*/ UNITY_PI*/ * ((1 - _DisneyKss) * fd + 1.25 * _DisneyKss * fss);
					#endif


					half3 directCol = (diffuseTerm * /*albedo*/ diffCol + specular)* saturate(ndotl) * _LightColor0.rgb;

					#ifndef ENABLE_INDIRECT_LIGHTING
						return half4(directCol, 1.0);
					#endif

					//indirect lighting
					half3 indirectSpec = fixed3(0, 0, 0);
					half3 indirectCol;
					float3 f90 = 1.0;

					#ifdef ENABLE_REALTIME_SAMPLING 
					
						/*-------real time samping indirect lighting-------------*/

					   // indirect specular ONLY

					   #ifdef _INDIRECTSPECIBL_PERFECT_REFLECTION
						   //option1 : environment mapping - cubemap , too mirror-like
						   half3 fnr = specularF0 + (1 - specularF0) * pow(1 - dot(worldNormal, i.worldRefl), 5);
						   fixed3 envReflection = samplePanoramicLOD(_Enviroment, i.worldRefl,  0);
						   indirectSpec = fnr * envReflection;
					   #endif

					   #ifdef _INDIRECTSPECIBL_IMPORTANCE_SAMPLING
						   //option2 : specIBL --- importance sampling ,to be continued
						   indirectSpec = IndirectSpecularImportanceSampling(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);
					   #endif


						#ifdef _INDIRECTSPECIBL_SPLITSUM
						   //option3 : specIBL ---sPLIT SUM 
						   indirectSpec = IndirectSpecularImportanceSamplingFrosibite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);

						#endif
						half3 frSpecEnvL, envBRDF;
						#ifdef _INDIRECTSPECIBL_CODAPPROX
						   //option4 : specIBL --- cod approx
						   frSpecEnvL = CoDSpecEnvLFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);
						   envBRDF = CODBlackOps2EnvSpecBRDF(specularF0, _Roughness, ndotv);
						   indirectSpec = frSpecEnvL * envBRDF;
						#endif

						#ifdef _INDIRECTSPECIBL_UEAPPROX
						   //option5 : specIBL --- UE approx
						   frSpecEnvL = CoDSpecEnvLFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);
						   envBRDF = UESpecEnvBRDFApprox(specularF0, _Roughness, ndotv);
						   indirectSpec = frSpecEnvL * envBRDF;
						#endif

						#ifdef _INDIRECTSPECIBL_UNITYAPPROX
						   //option6 : specIBL --- Unity Presented approx
						   frSpecEnvL = CoDSpecEnvLFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);
						   envBRDF = UnityPPTSpecEnvBRDFApprox(specularF0, _Roughness, ndotv);
						   indirectSpec = frSpecEnvL * envBRDF;
						#endif

						#ifdef _INDIRECTSPECIBL_UNITYACTUALAPPROX
						   //option7 : specIBL --- Unity actual approx
						   frSpecEnvL = CoDSpecEnvLFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);
						   envBRDF = UnityBRDFSpecEnvBRDFApprox(specularF0, _Roughness, ndotv, _Metallic,false);
						   indirectSpec = frSpecEnvL * envBRDF;
						#endif



					   indirectCol = indirectSpec;

					   //indirect IBL including specular and diffuse

					   #ifdef	_INDIRECTIBL_IMPORTANCE_SAMPLING

						   indirectCol = IndirectImportanceSampling(diffCol, _MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);

					   #endif


						#ifdef _INDIRECTIBL_SPLITSUM

						   indirectCol = IndirectSplitSumBothFrosibite(diffCol,_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);

						#endif


						#ifdef _INDIRECTIBL_CODAPPROX 
						   frSpecEnvL = CoDSpecEnvLFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);
						   half3 codspecEnvbrdf = CODBlackOps2EnvSpecBRDF(specularF0, _Roughness, ndotv);
						   indirectSpec = codspecEnvL * codspecEnvbrdf;

						   float3 reflDir = reflect(-worldViewDir, worldNormal);

						   half4 uvlod = half4(reflDir, 0);
						   float3 sampleEnv = samplePanoramicLOD(_Enviroment, uvlod.xyz, uvlod.w);

						   indirectCol = indirectSpec + i.vlight *  diffCol * (1 - specularF0);/*sampleEnv / i.vlight *  diffCol;*/
						#endif

						#ifdef _INDIRECTIBL_UEAPPROX 
							frSpecEnvL = CoDSpecEnvLFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);
							envBRDF = UESpecEnvBRDFApprox(specularF0, _Roughness, ndotv);
							indirectSpec = frSpecEnvL * envBRDF;
							indirectCol = indirectSpec + i.vlight *  diffCol * (1 - specularF0);
						#endif

						#ifdef _INDIRECTIBL_UNITYAPPROX  
							frSpecEnvL = CoDSpecEnvLFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);
							envBRDF = UnityPPTSpecEnvBRDFApprox(specularF0, _Roughness, ndotv);
							indirectSpec = frSpecEnvL * envBRDF;
							indirectCol = indirectSpec + i.vlight*  diffCol * (1 - specularF0);
						#endif

						#ifdef _INDIRECTIBL_UNITYACTUALAPPROX

							frSpecEnvL = CoDSpecEnvLFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);
							envBRDF = UnityBRDFSpecEnvBRDFApprox(specularF0, _Roughness, ndotv, _Metallic,false);
							indirectSpec = frSpecEnvL * envBRDF;

							indirectCol = indirectSpec + i.vlight*  diffCol * (1 - specularF0);
						#endif

					#else

						/*-------Using LUT for indirect specular and diffuse------ */

							//Specular  LUT IBL PrefilteringSum * EnvBrdf
							float3 reflDir = reflect(-worldViewDir, worldNormal);

							int mipCount = 12;
							int mipLevel = sqrt(_Roughness) * mipCount;

							float smoothness = saturate(1 - _Roughness);
							float lerpFactor = smoothness * (sqrt(smoothness) + _Roughness);
							float3 specDominantR = lerp(worldNormal, reflDir, lerpFactor);

							half4 uvlod = half4(specDominantR, mipLevel);
							//float3 PrefilteringSum = samplePanoramicLOD(_Enviroment, uvlod.xyz, uvlod.w);

							float3 realtimeLD = SpecLDImportanceSampleFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);

							ndotv = clamp(ndotv,0.5 * 1.0 / 256, 1.0 - 1.0 / 256);

							float2 lutUV = float2(ndotv, _Roughness);
							float3 sampleLUT = tex2D(_LUT, lutUV).rgb;
							float3 EnvBrdf = sampleLUT.r * specularF0 + sampleLUT.g;

							indirectSpec = /*PrefilteringSum  */  realtimeLD * EnvBrdf;


							#ifdef _LUTIBLMODE_BOTH

							//indirect diffuse : diffuse  LUT IBL
							float a = 1.02341f * _Roughness - 1.51174f;
							float b = -0.511705f * _Roughness + 0.755868f;
							lerpFactor = saturate((ndotv * a + b) * _Roughness);
							float3 diffDominantR = lerp(worldNormal, worldViewDir, lerpFactor);

							uvlod = half4(diffDominantR, mipLevel);
							float3 indirectDiffLD = samplePanoramicLOD(_Enviroment, uvlod.xyz, uvlod.w);

							float3 realtimeindirectDiffLD = DiffLDImportanceSampleFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);

							half3 indirectDiffDFG = sampleLUT.b;
							half3 indirectDiff = indirectDiffDFG * realtimeindirectDiffLD;

							indirectCol = indirectDiff * diffCol + indirectSpec;

							#endif

							#ifdef _LUTIBLMODE_SPEC
								indirectCol = indirectSpec;
							#endif

						#endif				


							fixed3 finalCol = directCol + indirectCol;

							return  half4(finalCol, 1.0);
					}
					ENDCG
				}
	}

		FallBack "Specular"
}
