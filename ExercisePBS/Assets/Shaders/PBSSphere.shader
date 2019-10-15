Shader "Exercises/PBS/PBSSphere"
{
	Properties
	{
		_Specular("Specular Color F0",2D) = "white"{}
		_SpecularColor("Specular Color F0",Color) = (1,1,1,1)
		_Diffuse("Diffuse Map",2D) = "white"{}
		_Normal("Normal Map",2D)="white"{}
		_Enviroment("Enviroment Cube Map",CUBE)="_SkyBox"{}
		_Roughness("Roughness",Range(0.02,1)) = 0.5
		_DisneyDiffuseRoughness("Roughness for Disney diffuse ",Range(0,1)) = 0.5
		_MaxSampleCountMonteCarlo("Max Sample Count of Monte Carlo",Range(1,5000)) = 32
		_IndirectDiffFactor("Indirect Diffuse L factor",Range(0,1)) = 0.5
		_IndirectSpecFactor("Indirect Specular L factor",Range(0,1)) = 0.5

		[KeywordEnum(NONE,GGX)]_DirectSpec("Direct Specular mode",Float) = 0
		[KeywordEnum(NONE,SIMPLIFIED_DISNEY_DIFFUSE,FULL_DISNEY_DIFFUSE,LAMBERT_DIFFUSE,LAMBERT_MODIFIDED_DIFFUSE)]_DirectDiff("Direct Diffuse mode",Float) = 0
		[KeywordEnum(NONE,IMPORTANCE_SAMPLING,UNIFORM_SAMPLING,PERFECT_REFLECTION)]_IndirectSpecIBL("Indirect Specular mode",Float) = 0
		[KeywordEnum(NONE,IMPORTANCE_SAMPLING,UNIFORM_SAMPLING)]_IndirectIBL("Indirect mode (will make Indirect Specular mode not used)",Float) = 0

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
			#pragma multi_compile LIGHTMAP_ON LIGHTMAP_OFF
			#pragma multi_compile _DIRECTSPEC_NONE _DIRECTSPEC_GGX
			#pragma multi_compile _DIRECTDIFF_NONE  _DIRECTDIFF_SIMPLIFIED_DISNEY_DIFFUSE _DIRECTDIFF_FULL_DISNEY_DIFFUSE _DIRECTDIFF_LAMBERT_DIFFUSE _DIRECTDIFF_LAMBERT_MODIFIDED_DIFFUSE
			#pragma multi_compile _INDIRECTSPECIBL_NONE _INDIRECTSPECIBL_IMPORTANCE_SAMPLING _INDIRECTSPECIBL_UNIFORM_SAMPLING _INDIRECTSPECIBL_PERFECT_REFLECTION
			#pragma multi_compile _INDIRECTIBL_NONE _INDIRECTIBL_IMPORTANCE_SAMPLING _INDIRECTIBL_UNIFORM_SAMPLING

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
			};

			sampler2D _Diffuse, _Normal, _Specular;
			float4 _Diffuse_ST, _Normal_ST;
			fixed4  _SpecularColor;
			float _Gloss, _Roughness,_DisneyKss , _DisneyDiffuseRoughness, _IndirectDiffFactor, _IndirectSpecFactor;

			samplerCUBE _Enviroment;
			float _F0;
			int _MaxSampleCountMonteCarlo;

			#include "MonteCarloUniformSample.cginc"
			#include "ImportanceSample.cginc"


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
				fixed3 worldNormal =normalize( float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));
	
				fixed3 bump = UnpackNormal(tex2D(_Normal, i.uv.zw));
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));


				// indirect specular 
				half3 specularF0 = tex2D(_Specular, i.uv.xy) * _SpecularColor;
				half3 indirectSpec = fixed3(0, 0, 0);

				float3 f90 = 1.0;
				
				#ifdef _INDIRECTSPECIBL_PERFECT_REFLECTION
					//option1 : environment mapping - cubemap , too mirror-like
					half3 fnr = specularF0 + (1 - specularF0) * pow(1 - dot(worldNormal, i.worldRefl), 5);
					fixed3 envReflection = texCUBE(_Enviroment, i.worldRefl).rgb;
					indirectSpec = fnr * envReflection;
				#endif

				#ifdef _INDIRECTSPECIBL_IMPORTANCE_SAMPLING
					//option2 : specIBL --- importance sampling ,to be continued
					indirectSpec = IndirectSpecularImportanceSampling(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness, _IndirectSpecFactor);
				#endif
				
				#ifdef _INDIRECTSPECIBL_UNIFORM_SAMPLING
					//option3 : specIBL --- uniform sampling
					indirectSpec = IndirectSpecularUniformSampling(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, _Roughness, _IndirectSpecFactor);
				#endif
				




				//direct specular

			
				half ndotl = dot(worldNormal, worldLight);
				half3 h = normalize((worldLight + worldViewDir));
				half ndoth = dot(worldNormal, h);
				half ndotv = dot(worldNormal, worldViewDir);
				half vdoth = dot(worldViewDir, h);
				float hdotl = dot(h, worldLight);

				half3 specular = 0;

				//Fresnel coefficient
				half3 specFresnel = specularF0 + (1 - specularF0) * pow(1 - dot(h, worldLight), 5);//_F0 is 0.5 or above for metal

				#ifdef _DIRECTSPEC_GGX
				
					ndotl = clamp(ndotl,0.001,1.0);
					ndotv = clamp(ndotv, 0.001, 1.0);;
					
					half alpha_tr = _Roughness * _Roughness; //_Roughness =  1 表示越光滑
					half Dm = /* ndoth * */alpha_tr * alpha_tr / (UNITY_PI * pow((ndoth * ndoth * (alpha_tr * alpha_tr - 1) + 1), 2)); //Q  

					half Gmv = 2 * ndoth * ndotv / vdoth;
					half Gml = 2 * ndoth * ndotl / vdoth;
					half Gm = min(1, min(Gmv, Gml));

					specular = specFresnel * Dm * Gm / (4 * ndotl * ndotv) * UNITY_PI;
					
				#endif

				//direct diffuse 
				fixed3 albedo = tex2D(_Diffuse, i.uv.xy).rgb;
				half  diffuseTerm = 0;

				#ifdef _DIRECTDIFF_LAMBERT_DIFFUSE

				   diffuseTerm = 1;
				#endif	

				#ifdef _DIRECTDIFF_LAMBERT_MODIFIDED_DIFFUSE

				   diffuseTerm = 1  - specFresnel;

				#endif	

				#ifdef _DIRECTDIFF_SIMPLIFIED_DISNEY_DIFFUSE
						
					float Fss90 = sqrt(_DisneyDiffuseRoughness/*_Roughness*/)* hdotl * hdotl;
					float FD90 = 0.5 + 2 * Fss90;
					float fd = (1 + (FD90 - 1) * pow(1 - ndotl, 5)) * (1 + (FD90 - 1) * pow(1 - ndotv, 5));

					diffuseTerm =  saturate(ndotl) * saturate(ndotv) * fd;
				#endif
				
				#ifdef _DIRECTDIFF_FULL_DISNEY_DIFFUSE

					float Fss90 = sqrt(_DisneyDiffuseRoughness)* hdotl * hdotl;
					float Fss = (1 + (Fss90 - 1) * pow(1 - ndotl, 5)) * (1 + (Fss90 - 1) * pow(1 - ndotv, 5));
					float fss = (1 / (ndotl * ndotv) - 0.5) * Fss + 0.5;
					float FD90 = 0.5 + 2 * Fss90;
					float fd = (1 + (FD90 - 1) * pow(1 - ndotl, 5)) * (1 + (FD90 - 1) * pow(1 - ndotv, 5));

					diffuseTerm = saturate(ndotl) * saturate(ndotv) /*/ UNITY_PI*/ * ((1 - _DisneyKss) * fd + 1.25 * _DisneyKss * fss);
				#endif

				half3 directCol = (diffuseTerm * albedo + specular)* saturate(ndotl) * _LightColor0.rgb ;
				
				half3 indirectCol = indirectSpec;
				#ifdef	_INDIRECTIBL_UNIFORM_SAMPLING
					indirectCol = IndirectUniformSampling(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, _Roughness,albedo, _IndirectSpecFactor, _IndirectDiffFactor);
				#endif

				#ifdef	_INDIRECTIBL_IMPORTANCE_SAMPLING
					indirectCol = IndirectImportanceSampling(_MaxSampleCountMonteCarlo, worldViewDir, worldNormal, specularF0, f90, _Roughness, _IndirectSpecFactor, _IndirectDiffFactor);
				#endif
				
				fixed3 finalCol = directCol + indirectCol;

				return fixed4(finalCol,1.0);
			}
			ENDCG
		}
	}
			
	FallBack "Specular"
}
