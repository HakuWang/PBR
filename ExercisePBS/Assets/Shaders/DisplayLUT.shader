Shader "Exercises/PBS/DisplayLUT"
{
	Properties
	{
		_LUT("LUT",2D)="white"{}
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
				};

				struct v2f
				{
					float4 pos  : SV_POSITION;
					float2 uv : TEXCOORD0;
				};

				sampler2D _LUT;

				v2f vert(appdata v)
				{
					v2f o;
					o.pos  = UnityObjectToClipPos(v.vertex);
					o.uv = v.texcoord.xy;
					return o;

				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = tex2D(_LUT, i.uv);
					return col;
				}
				ENDCG
			}
		}
			FallBack "Specular"
}
