Shader "Exercises/PBS/PureColor"
{
	Properties
	{
		_MainColor("Main Color",Color)=(1,1,1,1)
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
			

				struct appdata
				{
					float4 vertex : POSITION;

				};

				struct v2f
				{
					float4 pos : SV_POSITION;
				};

				float4 _MainColor;
				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);

				
					return o;

				}

				fixed4 frag(v2f i) : SV_Target
				{

					
					fixed4 col = _MainColor;

					return col;
				}
				ENDCG
			}
		}
			FallBack "Specular"
}
