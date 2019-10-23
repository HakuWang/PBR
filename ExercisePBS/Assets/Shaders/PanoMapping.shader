Shader "Exercises/PBS/PanoMapping"
{
	Properties
	{
		_Enviroment("Enviroment Cube Map",2D)="white"{}
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
				
				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#include "AutoLight.cginc"
				#include "Utils.cginc"
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
					fixed3 worldNormal : TEXCOORD5;
				};
				
				

				sampler2D _Enviroment;

				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv= v.texcoord;

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



					return o;

				}

				fixed4 frag(v2f i) : SV_Target
				{
					float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
					fixed3 worldLight = normalize(UnityWorldSpaceLightDir(worldPos));
					fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
					fixed3 worldNormal = normalize(float3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z));
					float3 reflDir = reflect(-worldViewDir, worldNormal);

					half3 col = samplePanoramicLOD(_Enviroment, reflDir, 0);
					return half4(col,1.0);


				}
				ENDCG
			}
		}
			FallBack "Specular"
}
