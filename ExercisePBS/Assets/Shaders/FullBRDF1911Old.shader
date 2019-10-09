Shader "Exercises/PBS/FullBRDF1911"
{
	Properties
	{
		_Specular("Specular Color F0",2D) = "white"{}
		_Diffuse("Diffuse Map",2D) = "white"{}
		_Normal("Normal Map",2D)="white"{}
		_Enviroment("Enviroment Cube Map",CUBE)="_SkyBox"{}
		_Roughness("Roughness",Range(0,1)) = 0.5
		_DisneyDiffuseRoughness("Roughness for Disney diffuse ",Range(0,1)) = 0.5
		_MaxSampleCountMonteCarlo("Max Sample Count of Monte Carlo",Range(1,1024)) = 32
		//	_phi("phi", float) = 0
		//_DisneyKss("Disney Rough Diffuse Kss",Range(0,1))=0.5
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
		  //#define LAMBERT_DIFFUSE
		  //#define LAMBERT_MODIFIDED_DIFFUSE
			#define GGX_SPECULAR
		  //#define FULL_DISNEY_DIFFUSE
			#define SIMPLIFIED_DISNEY_DIFFUSE
            #define  UNIFORM_SAMPLING//PERFECT_REFLECTION //IMPORTANCE_SAMPLING //

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
			fixed4 _SpecularCol;
			float _Gloss, _Roughness,_DisneyKss , _DisneyDiffuseRoughness;

			samplerCUBE _Enviroment;
			float _F0;
			int _MaxSampleCountMonteCarlo;

			#include "MonteCarloUniformSample.cginc"

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


			float _phi;


			fixed4 frag(v2f i) : SV_Target
			{
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 worldNormal =normalize( float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));
				
				fixed3 bump = UnpackNormal(tex2D(_Normal, i.uv.zw));
				bump = normalize(half3(dot(i.TtoW0.xyz,bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));					

				half ndotl = dot(bump, worldLight);
				half3 h = normalize((worldLight + worldViewDir));
				half ndoth = dot(bump, h);
				half ndotv =dot(bump, worldViewDir);
				half vdoth = dot(worldViewDir, h);
				float hdotl = dot(h, worldLight);

				//specular
				fixed3 specular = 0;
				half fresnel;
				fixed3 specFresnel;
				fixed3 specularF0 = tex2D(_Specular, i.uv.xy);

				// indirect specular
				fixed3 indirectSpec = fixed3(0, 0, 0);

				half3 fnr = specularF0 + (1 - specularF0) * pow(1 - dot(bump, i.worldRefl), 5);
				
				#ifdef GGX_SPECULAR

					ndotl = saturate(ndotl);
					ndotv = saturate(ndotv);
					//Fresnel coefficient
					specFresnel = specularF0 + (1 - specularF0) * pow(1 - dot(h, worldLight), 5);//_F0 is 0.5 or above for metal

					half alpha_tr = _Roughness * _Roughness; //_Roughness =  1 表示越光滑
					half Dm = /* ndoth * */alpha_tr * alpha_tr / (UNITY_PI * pow((ndoth * ndoth * (alpha_tr * alpha_tr - 1) + 1), 2)); //Q  

					half Gmv = 2 * ndoth * ndotv / vdoth;
					half Gml = 2 * ndoth * ndotl / vdoth;
					half Gm = min(1, min(Gmv, Gml));

					specular = specFresnel * Dm * Gm / (4 * ndotl * ndotv) * UNITY_PI;
				#endif

				//diffuse 
				fixed3 albedo = tex2D(_Diffuse, i.uv.xy).rgb;

				half  diffuseTerm = 1;

				#ifdef LAMBERT_DIFFUSE

				    //ndotl = ndotl * 0.5 + 0.5;
				   diffuseTerm = 1;
				#endif	

				#ifdef LAMBERT_MODIFIDED_DIFFUSE

					half3 diffuseTermLambertVec = 1  - specFresnel;
					fixed3 directCol1 = (diffuseTermLambertVec * albedo + specular)* saturate(ndotl) * _LightColor0.rgb;
					
					fixed3 envReflection1 = texCUBE(_Enviroment, i.worldRefl).rgb;
					
					fixed4 col1 = fixed4(directCol1, 1.0);
					return col1;
				#endif	

				#ifdef SIMPLIFIED_DISNEY_DIFFUSE
						
					float Fss90 = sqrt(_DisneyDiffuseRoughness/*_Roughness*/)* hdotl * hdotl;
					float FD90 = 0.5 + 2 * Fss90;
					float fd = (1 + (FD90 - 1) * pow(1 - ndotl, 5)) * (1 + (FD90 - 1) * pow(1 - ndotv, 5));

					diffuseTerm =  saturate(ndotl) * saturate(ndotv) * fd;
				#endif
				
				#ifdef FULL_DISNEY_DIFFUSE

					float Fss90 = sqrt(_DisneyDiffuseRoughness)* hdotl * hdotl;
					float Fss = (1 + (Fss90 - 1) * pow(1 - ndotl, 5)) * (1 + (Fss90 - 1) * pow(1 - ndotv, 5));
					float fss = (1 / (ndotl * ndotv) - 0.5) * Fss + 0.5;
					float FD90 = 0.5 + 2 * Fss90;
					float fd = (1 + (FD90 - 1) * pow(1 - ndotl, 5)) * (1 + (FD90 - 1) * pow(1 - ndotv, 5));

					diffuseTerm = saturate(ndotl) * saturate(ndotv) /*/ UNITY_PI*/ * ((1 - _DisneyKss) * fd + 1.25 * _DisneyKss * fss);
				#endif

				fixed3 directCol = (diffuseTerm * albedo + specular)* saturate(ndotl) * _LightColor0.rgb ;

			
				#ifdef LIGHTMAP_ON
				
					// diffuse from light map
					fixed3 diffuseLightMapColor = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uv2)).rgb;
					fixed3 indirectDiff = diffuseLightMapColor * albedo;
					
					//option1 : environment mapping - cubemap , too mirror-like
					#ifdef PERFECT_REFLECTION
						fixed3 envReflection = texCUBE(_Enviroment, i.worldRefl).rgb;
					    indirectSpec = fnr * envReflection;
					#endif
                    
					//option2 : specIBL --- importance sampling
					#ifdef IMPORTANCE_SAMPLING
						f90 = 0.5;
						indirectSpec = IndirectSpecularImportanceSampling(_MaxSampleCountMonteCarlo,worldViewDir, bump, specularF0, f90, _Roughness);
					#endif

					#ifdef UNIFORM_SAMPLING
						indirectSpec = IndirectSpecularUniformSampling(_MaxSampleCountMonteCarlo, worldViewDir, bump, specularF0, _Roughness,i.uv.xy);
					#endif

						
					fixed3 indirectCol = indirectSpec;
					//	fixed3 indirectCol=(1- fnr)  * indirectDiff + fnr * indirectSpec;
				#endif

				#ifdef LIGHTMAP_OFF
					fixed3 indirectCol = fixed3(0, 0, 0);
					return fixed4(indirectCol, 1.0);

				#endif


				fixed3 finalCol = directCol + indirectCol;
				
				return fixed4(finalCol,1.0);
			}
			ENDCG
		}
	}
			
	FallBack "Specular"
}
