Shader "Exercises/PBS/PBSSphere"
{
	Properties
	{
		_SpecularColor("Specular Color F0",Color) = (1,1,1,1)
		_Enviroment("Enviroment Cube Map",2D) = "white"{}

		[Space(30)]

		_Roughness("Roughness",Range(0.02,1)) = 0.5
		_Metallic("Metallic",Range(0,1)) = 1

		//_DisneyDiffuseRoughness("Roughness for Disney diffuse ",Range(0,1)) = 0.5

		[Header(Direct Light Settings)]
		[KeywordEnum(NONE,GGX)]_DirectSpec("Direct Specular mode",Float) = 0
		[KeywordEnum(NONE,SIMPLIFIED_DISNEY_DIFFUSE,FULL_DISNEY_DIFFUSE,LAMBERT_DIFFUSE,LAMBERT_MODIFIDED_DIFFUSE)]_DirectDiff("Direct Diffuse mode",Float) = 0

		[Header(Indirect Light Settings)]

		[Space(20)]

		[Toggle(ENABLE_INDIRECT_LIGHTING)] _EnableIndirectLighting("Enable Indirect Lighting?", Float) = 0

		[Toggle(ENABLE_REALTIME_SAMPLING)] _EnableRealtimeSampling("Enable Realtime Sampling?", Float) = 0

		[Header(Realtime Sampling Settings)]
		[KeywordEnum(NONE,IMPORTANCE_SAMPLING,UNIFORM_SAMPLING,PERFECT_REFLECTION,SPLITSUM)]_IndirectSpecIBL("Indirect Specular mode",Float) = 0
		[KeywordEnum(NONE,IMPORTANCE_SAMPLING,SPLITSUM,UNIFORM_SAMPLING)]_IndirectIBL("Indirect mode (will make Indirect Specular mode not used)",Float) = 0
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
			#pragma multi_compile _DIRECTSPEC_NONE _DIRECTSPEC_GGX
			#pragma multi_compile _DIRECTDIFF_NONE  _DIRECTDIFF_SIMPLIFIED_DISNEY_DIFFUSE _DIRECTDIFF_FULL_DISNEY_DIFFUSE _DIRECTDIFF_LAMBERT_DIFFUSE _DIRECTDIFF_LAMBERT_MODIFIDED_DIFFUSE
			#pragma multi_compile _INDIRECTSPECIBL_NONE _INDIRECTSPECIBL_IMPORTANCE_SAMPLING _INDIRECTSPECIBL_UNIFORM_SAMPLING _INDIRECTSPECIBL_PERFECT_REFLECTION _INDIRECTSPECIBL_SPLITSUM
			#pragma multi_compile _INDIRECTIBL_NONE _INDIRECTIBL_IMPORTANCE_SAMPLING _INDIRECTIBL_SPLITSUM _INDIRECTIBL_UNIFORM_SAMPLING
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
				half4 uv : TEXCOORD0;
				half2 uv2 : TEXCOORD6;
				fixed4 TtoW0 : TEXCOORD2;
				fixed4 TtoW1 : TEXCOORD3;
				fixed4 TtoW2 : TEXCOORD4;
				fixed3 worldRefl : TEXCOORD5;
				half3 vlight: TEXCOORD7;
			};

			sampler2D _Diffuse, _Normal, _Specular, _LUT;
			float4 _Diffuse_ST, _Normal_ST;
			fixed4  _SpecularColor;
			float _Gloss, _Roughness,_DisneyKss , _DisneyDiffuseRoughness, _Metallic;

			sampler2D _Enviroment;
			int _MaxSampleCountMonteCarlo;

			#include "MonteCarloUniformSample.cginc"
			#include "ImportanceSample.cginc"
#include "ImportanceSampleFrosbiteSplitSum.cginc"

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

				o.vlight = ShadeSH9(v.normal);


				return o;

			}

			half4 frag(v2f i) : SV_Target
			{
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 worldNormal = normalize(float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));

				half3 specular = 0;
				half3 specularF0 = lerp(unity_ColorSpaceDielectricSpec,_SpecularColor, _Metallic);


				half ndotl = dot(worldNormal, worldLight);
				half3 h = normalize((worldLight + worldViewDir));
				half ndoth = dot(worldNormal, h);
				half ndotv = dot(worldNormal, worldViewDir);
				half vdoth = dot(worldViewDir, h);
				float hdotl = dot(h, worldLight);

				//direct specular
				
				//Fresnel coefficient
				half3 specFresnel = specularF0 + (1 - specularF0) * pow(1 - dot(h, worldLight), 5);//_F0 is 0.5 or above for metal

				#ifdef _DIRECTSPEC_GGX

					ndotl = clamp(ndotl,0.001,1.0);
					ndotv = clamp(ndotv, 0.001, 1.0);;

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
				



				//direct diffuse 
				fixed3 albedo = 1;// tex2D(_Diffuse, i.uv.xy).rgb;
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
				

				half3 directCol = (diffuseTerm * albedo + specular)* saturate(ndotl) * _LightColor0.rgb;

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

				   #ifdef _INDIRECTSPECIBL_UNIFORM_SAMPLING
					   //option3 : specIBL --- uniform sampling
					   indirectSpec = IndirectSpecularUniformSampling(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, _Roughness, _IndirectSpecFactor);
				   #endif

					#ifdef _INDIRECTSPECIBL_SPLITSUM
					   //option4 : specIBL ---sPLIT SUM 
					   indirectSpec = IndirectSpecularImportanceSamplingFrosibite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);

					#endif



				   indirectCol = indirectSpec;

				   //indirect IBL including specular and diffuse

				   float3 diffCol = albedo * (1 - _Metallic);
				   #ifdef	_INDIRECTIBL_UNIFORM_SAMPLING
					   indirectCol = IndirectUniformSampling(diffCol,_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, _Roughness, diffCol );
				   #endif

				   #ifdef	_INDIRECTIBL_IMPORTANCE_SAMPLING
					   
					   indirectCol = IndirectImportanceSampling(diffCol, _MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);

					  // indirectCol +=  i.vlight*  diffCol * (1 - specularF0); 
				   #endif


#ifdef _INDIRECTIBL_SPLITSUM

					   indirectSpec = IndirectSplitSumFrosibite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);

#endif

					#else

					/*-------Using LUT for indirect specular and diffuse------ */

						//Specular  LUT IBL PrefilteringSum * EnvBrdf
					    float3 reflDir = reflect(-worldViewDir, worldNormal);

						int mipCount = 8;
						int mipLevel = sqrt(_Roughness) * mipCount;

						float smoothness = saturate(1 - _Roughness);
						float lerpFactor = smoothness * (sqrt(smoothness) + _Roughness);
						float3 specDominantR = lerp(worldNormal, reflDir, lerpFactor);

						half4 uvlod = half4(specDominantR, mipLevel);
						float3 PrefilteringSum = samplePanoramicLOD(_Enviroment, uvlod.xyz, uvlod.w);

					    float3 realtimeLD = SpecLDImportanceSampleFrosbite(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness);

						ndotv = clamp(ndotv, 0.05, 1.0);

						float2 lutUV = float2(ndotv, _Roughness);
						float3 sampleLUT = tex2D(_LUT, lutUV).rgb;
						sampleLUT = pow(sampleLUT, 0.45);
						float3 EnvBrdf = sampleLUT.r * specularF0 + sampleLUT.g;

						indirectSpec = /*PrefilteringSum  */ realtimeLD * EnvBrdf;


						#ifdef _LUTIBLMODE_BOTH

						//indirect diffuse : diffuse  LUT IBL
						float a = 1.02341f * _Roughness - 1.51174f;
						float b = -0.511705f * _Roughness + 0.755868f;
						lerpFactor = saturate((ndotv * a + b) * _Roughness);
						float3 diffDominantR = lerp(worldNormal, worldViewDir, lerpFactor);

						uvlod = half4(diffDominantR, mipLevel);
						float3 indirectDiffLD = samplePanoramicLOD(_Enviroment, uvlod.xyz, uvlod.w);

						half3 indirectDiffDFG = sampleLUT.b;
						half3 indirectDiff = indirectDiffDFG * indirectDiffLD;

						indirectCol = indirectDiff + indirectSpec;

					#endif

					#ifdef _LUTIBLMODE_SPEC
						indirectCol = indirectSpec;
					#endif

					#endif				


					fixed3 finalCol = directCol + indirectCol;

				return half4(finalCol,1.0);
			}
			ENDCG
		}
	}

		FallBack "Specular"
}
