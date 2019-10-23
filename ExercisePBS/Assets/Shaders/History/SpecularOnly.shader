Shader "Exercises/PBS/SpecularOnly"
{
	Properties
	{
		_Specular("Specular Color F0",2D) = "white"{}
		_Diffuse("Diffuse Map",2D) = "white"{}
		_Normal("Normal Map",2D)="white"{}
		_Enviroment("Enviroment Cube Map",CUBE)="_SkyBox"{}
		_Roughness("Roughness",Range(0,1)) = 0.5
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
				#define HALF_LAMBERT
			    #define GGX_SPECULAR
				#define DISNEY_DIFFUSE

				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#include "AutoLight.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float4 texcoord : TEXCOORD0;
					float4 normal:NORMAL;
					float4 tangent:TANGENT;
				};

				struct v2f
				{
					float4 pos : SV_POSITION;
					fixed4 uv : TEXCOORD0;
					fixed4 TtoW0 : TEXCOORD2;
					fixed4 TtoW1 : TEXCOORD3;
					fixed4 TtoW2 : TEXCOORD4;
					fixed3 worldRefl : TEXCOORD5;
				};

				sampler2D _Diffuse, _Normal, _Specular;
				float4 _Diffuse_ST, _Normal_ST;
				fixed4 _SpecularCol;
				float _Gloss, _Roughness;

				samplerCUBE _Enviroment;
				float _F0;

				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv.xy = v.texcoord.xy*_Diffuse_ST.xy + _Diffuse_ST.zw;
					o.uv.zw = v.texcoord.xy*_Normal_ST.xy + _Normal_ST.zw;

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

				fixed4 frag(v2f i) : SV_Target
				{
					float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
					fixed3 worldLight = normalize(UnityWorldSpaceLightDir(worldPos));
					fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));


					fixed3 bump = UnpackNormal(tex2D(_Normal, i.uv.zw));
					bump = normalize(half3(dot(i.TtoW0.xyz,bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));					

					//diffuse 
					fixed3 diffuseTexCol = tex2D(_Diffuse, i.uv.xy).rgb;
					half ndotl = dot(bump, worldLight);
					fixed3 diffuse;

					#ifdef HALF_LAMBERT
						ndotl = ndotl * 0.5 + 0.5;
						diffuse = _LightColor0.rgb * diffuseTexCol * ndotl;
					#else
						diffuse = _LightColor0.rgb * diffuseTexCol;
					#endif		
					
					#ifdef DISNEY_DIFFUSE
						diffuse = _LightColor0.rgb * diffuseTexCol;
					#endif
					
					half fresnel;
					fixed3 specFresnel;

					//specular
					fixed3 specular = 0;
					#ifdef GGX_SPECULAR

						half3 h = normalize((worldLight + worldViewDir));
						half ndoth = dot(bump, h);
						half ndotv = saturate(dot(bump, worldViewDir));
						half vdoth = dot(worldViewDir, h);
						ndotl = saturate(ndotl);

						//Fresnel coefficient
						fixed3 specularF0 = tex2D(_Specular, i.uv.xy);
						specFresnel = specularF0 + (1 - specularF0) * pow(1 - dot(h, worldLight), 5);//_F0 is 0.5 or above for metal

						half alpha_tr = _Roughness * _Roughness; //_Roughness =  1 表示越光滑
						half Dm =/* ndoth * */alpha_tr * alpha_tr / (UNITY_PI * pow(( ndoth * ndoth * (alpha_tr * alpha_tr - 1) + 1), 2));

						half Gmv = 2 * ndoth * ndotv / vdoth; 
						half Gml= 2 * ndoth * ndotl / vdoth;
						half Gm = min(1, min(Gmv, Gml));
						
						specular = specFresnel * Dm * Gm / (4 * ndotl * ndotv) * ndotl * _LightColor0.rgb;
					#endif


					//environment Reflection
					fixed3 envReflection = texCUBE(_Enviroment, i.worldRefl).rgb;
					
					fixed4 col = fixed4(diffuse + specular /*+ envReflection * fresnel*/, 1.0);

					return col;
				}
				ENDCG
			}
		}
			FallBack "Specular"
}
