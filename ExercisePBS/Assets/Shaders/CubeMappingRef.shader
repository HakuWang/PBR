Shader "Exercises/PBS/CubeMappingRef"
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
				};

				struct v2f
				{
					float4 pos  : SV_POSITION;
					float4 vPos : TEXCOORD0;
				};

				samplerCUBE _Enviroment;

				v2f vert(appdata v)
				{
					v2f o;
					o.pos  = UnityObjectToClipPos(v.vertex);
					o.vPos = v.vertex;
					return o;

				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = texCUBE(_Enviroment, i.vPos);
					return col;
				}
				ENDCG
			}
		}
			FallBack "Specular"
}
