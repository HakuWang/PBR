Shader "TA/Lightmap/Base"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _DiffuseTex("MainTex1", 2D) = "white" {}
        _NormalTex("_BumpMap", 2D) = "bump" {}
        _SpecularTex("_SpecularTex", 2D) = "white" {}
        _Roughness("Roughness Factor",Range(0, 1)) = 1
        _Metallic("Metallic Factor", Range(0, 1)) = 1
        [KeywordEnum(LOD0,LOD1)]LODLeveL("LOD Level", Float) = 0
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags{ "LightMode" = "DEForward" }

            HLSLPROGRAM
            #pragma vertex      vert
            #pragma fragment    frag


            #pragma multi_compile_instancing
            #pragma multi_compile   _FINALCOLOR   _DIFFUSE_ON   _SPECULAR_ON   _INDIFFUSE_ON   _INSPECULAR_ON   _AO_ON   _LM_ON   _SPECULAR_IBL_ON   _DIFFUSE_INDIFFUSE_ON  _SPECULAR_RANGE_ON
            #pragma multi_compile   _GRAPHIC_LOW  _GRAPHIC_MEDIUM  _GRAPHIC_HIGH


            // Defines : must be declared at the 1st place
            #define _GRAPHIC_LOW_OR_MEDIUM_OR_HIGH
            #define _LODLEVEL_LOD_1_OR_0
            #include "TACGInclude/GraphicsSettingMacro.hlsl"
            #define _LIGHTMAP_ON
            #ifdef INSTANCING_ON
                #define LIGHTMAP_ON
            #endif

            #if defined(_GRAPHIC_LOW)
                #define _VERTEXFOG_ON 1
                #undef _IBL_ON
            #endif

#define _DEBUG_IBL_ON
            // structure V2F
            // must be declared at the 2nd place
            #include "TACGInclude/DMData.hlsl"
            DM_STRUCT_COMMON


            // other includes
            #include "TACGInclude/DMCore.hlsl"
            #include "TACGInclude/TAPipelineDataUtils.hlsl"
            #include "TACGInclude/TALighting.hlsl"
            #include "TACGInclude/TAPBS.hlsl"
            #include "Features/EffectLight.hlsl"


            // params
            sampler2D   _DiffuseTex;
            sampler2D   _NormalTex;
            sampler2D   _SpecularTex;

            uniform half4   _CameraLightColor;
            uniform float   _GlobalLightScale;
            uniform float4  _ReflectHDRRange;

            CBUFFER_START(UnityPerMaterial)
                float4  _DiffuseTex_ST;
                float   _Metallic;
                float   _Roughness;
                half4   _Color;
            CBUFFER_END


            TAV2F vert(TAAppData appdata)
            {
                TAV2F o = CreateV2FData(appdata, _WorldSpaceCameraPos, _DiffuseTex_ST, float4(0, 0, 0, 0));

                return o;
            }


            float4 frag(TAV2F i) : SV_Target
            {
                UnpackV2FData(i);
                float4 albedo = TA_TEX2D(_DiffuseTex, UV0(i));
                float3 normal = CalculateWorldNormal(_NormalTex, UV0(i), i);

                // get light info
                AHDLightInfo info = DirectionalLightmapToAHD(LightMapUV(i), GetWorldNormal(i));

                // set up brdf params
                PBSSurfaceParam surface = ExtractPBRSurfaceParam(_SpecularTex, UV0(i), _Metallic, _Roughness, albedo.xyz);

                PBSDirections   dirs    = CreatePBSDirections(info.directionalLightDir.xyz, i.viewDir, normal);
                float3          fresnel = TAFresnelTerm(surface.specularColor, dirs.hDotL);

                // calculate color
                float3 diffuse      = DMDiffuse (fresnel, surface, dirs, info.directionalLightCol, _CameraLightColor.xyz);
                float3 worldPos     = float3(i.tToW[0].w, i.tToW[1].w, i.tToW[2].w);
                diffuse += TAEffectLight(worldPos, dirs.normal, surface.diffuseColor);



                float3 specular     = DMSpecular(fresnel, surface, dirs, info.directionalLightCol);
                float3 indiffuse    = info.ambientLightCol * surface.diffuseColor * surface.AO;
                float3 inspecular   = DMInSpecular(surface, dirs);

#ifdef _DEBUG_IBL_ON
                return half4(inspecular,1);
#endif

                // apply indivual scaler
                specular   *= _ReflectHDRRange.y;
                inspecular *= _ReflectHDRRange.x;

                float3 finalColor = diffuse + specular + indiffuse + inspecular;
                finalColor *= _GlobalLightScale;

                DebugDMColor(finalColor, info.directionalLightCol, diffuse, specular, indiffuse, inspecular, surface.AO);

                return float4(finalColor, 1);
            }

            ENDHLSL
        }
        
        //Pass
        //{
        //    Name "META"
        //    Tags{ "LightMode" = "Meta" }

        //    Cull Off

        //    CGPROGRAM
        //    #pragma vertex vert_meta
        //    #pragma fragment frag_meta

        //    #pragma shader_feature EDITOR_VISUALIZATION

        //    #include "TACGInclude/DMStandardMeta.hlsl"
        //    ENDCG
        //}
    }
}
