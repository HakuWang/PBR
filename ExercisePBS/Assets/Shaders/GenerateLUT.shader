Shader "Exercises/PBS/GenerateLUT"
{

	Properties{
		_Enviroment("Enviroment Cube Map",2D) = "white"{}
		_MaxSampleCountMonteCarlo("Max Sample Count of Monte Carlo",Range(1,5000)) = 32
	}
	SubShader{
		CGINCLUDE

		#include "UnityCG.cginc"

					#include "Lighting.cginc"
			#include "AutoLight.cginc"



		sampler2D _Enviroment;
		int _MaxSampleCountMonteCarlo;
#include "PBSUtils.cginc"

#include "ImportanceSampleFrosbiteSplitSum.cginc"


		ENDCG

		ZTest Always
		ZWrite Off
		Cull Off

		Pass
		{


			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag

			struct v2f
			{
				float4 pos : SV_POSITION;
				half4 uv : TEXCOORD0;
			};

			v2f vert(appdata_img v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.texcoord;
				

				return o;
			}

			half4 frag(v2f i) :SV_Target
			{
				half4 lutCol = half4(0,0,0,1);

				lutCol.rgb = FrosibiteLUT(_MaxSampleCountMonteCarlo, i.uv.x, i.uv.y);

				return lutCol;
			}

			ENDCG
		}
	}
			FallBack Off
}
