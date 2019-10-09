Shader "Exercises/PBS/CubeMapping"
{
	Properties
	{
		_Enviroment("Enviroment Cube Map",CUBE)="_SkyBox"{}
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

				samplerCUBE _Enviroment;

				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);

					fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
					float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

					fixed3 worldViewDir = UnityWorldSpaceViewDir(worldPos);
					o.worldRefl = reflect(-worldViewDir,worldNormal);

					return o;

				}

				fixed4 frag(v2f i) : SV_Target
				{

					//environment Reflection
					fixed3 envReflection = texCUBE(_Enviroment, i.worldRefl).rgb;
					
					fixed4 col = fixed4(envReflection, 1.0);

					return col;
				}
				ENDCG
			}
		}
			FallBack "Specular"
}
