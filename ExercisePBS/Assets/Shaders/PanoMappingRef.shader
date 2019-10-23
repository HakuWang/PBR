Shader "Exercises/PBS/PanoMappingRef"
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
				};

				struct v2f
				{
					float4 pos  : SV_POSITION;
					float4 vPos : TEXCOORD0;
				};

				sampler2D _Enviroment;

				v2f vert(appdata v)
				{
					v2f o;
					o.pos  = UnityObjectToClipPos(v.vertex);
					o.vPos = v.vertex;
					return o;

				}



				fixed4 frag(v2f i) : SV_Target
				{
					half3 col = samplePanoramicLOD(_Enviroment, i.vPos.xyz, 0);
					return half4(col,1.0);
				}
				ENDCG
			}
		}
			FallBack "Specular"
}
