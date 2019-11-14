Shader "Hidden/DEPipeline/GammaToLinear"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "DEPipeline"}
        LOD 100

        Pass
        {
            Name "Default"
            Tags { "LightMode" = "DEForward"}

            ZTest Always ZWrite Off
			Blend One OneMinusSrcAlpha

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex Vertex
            #pragma fragment Fragment

			#include "./Library/Core.hlsl"

            struct VertexInput
            {
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
            };

            struct VertexOutput
            {
                half4 pos       : SV_POSITION;
                half2 uv        : TEXCOORD0;
            };

            TEXTURE2D(_UIColorTexture);
            SAMPLER(sampler_UIColorTexture);

            VertexOutput Vertex(VertexInput i)
            {
                VertexOutput o;
                o.pos = TransformObjectToHClip(i.vertex.xyz);
                o.uv = i.uv;
                return o;
            }

			inline half3 GammaToLinearSpace(half3 sRGB)
			{
				// Approximate version from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
				return sRGB * (sRGB * (sRGB * 0.305306011h + 0.682171111h) + 0.012522878h);

				// Precise version, useful for debugging.
				//return half3(GammaToLinearSpaceExact(sRGB.r), GammaToLinearSpaceExact(sRGB.g), GammaToLinearSpaceExact(sRGB.b));
			}

            half4 Fragment(VertexOutput i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_UIColorTexture, sampler_UIColorTexture, i.uv);
				col.rgb = GammaToLinearSpace(col.rgb);
                return col;
            }
            ENDHLSL
        }
    }
}
