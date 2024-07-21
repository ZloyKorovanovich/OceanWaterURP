
Shader "Water/OceanSurface"
{
    Properties
    {
        [Header(Height)]
        _HeightMap ("Map", 2D) = "black" {}
        _Height ("Height", float) = 1

        [Header(Color)]
        _Color ("Color", color) = (0.1, 0.1, 0.5, 1)
        _Refraction ("Refraction", float) = 0.02
        _Depth ("Depth", float) = 1.5
        _DepthPower ("DepthPower", float) = 1
        _Smoothness ("Smoothness", float) = 0.85
        _Specular ("Specular", float) = 1
        _CoatRadius ("Coat", float) = 0.5

        [Header(Ambient)]
        _Ambient ("Ambient", range(0, 1)) = 0.85
        _Fresnel ("Fresnel", float) = 1

        [Header(SSS)]
        _SSSIntensity ("Intensity", float) = 10
        _SSSPower ("Power", float) = 4
        _SSSNormal ("Normal", range(0, 1)) = 0.5

        [Header(Distant)]
        _FadeColor ("Color", color) = (0.1, 0.1, 0.5, 1)
        _Fade ("Fade", float) = 150

        [Header(Absorption)]
        _AbsorptionLevel ("Level", range(0, 1)) = 0.5
        _AbsorptionPower ("Power", float) = 2.5
        _AbsorptionContrast ("Contrast", float) = 100

        [Header(Back)]
        _BackIntensity ("Intensity", float) = 1

        [Header(Foam)]
        _FoamMask ("Mask", 2D) = "white" {}
        _FoamAmount ("Amount", range(0, 1)) = 0.2
        _FoamColor ("Color", color) = (0.9, 1, 1, 1)
        _FoamCutoff ("Cutoff", float) = 2
        _FoamSpeed ("Speed", float) = 0.01

        [Header(Normal)]
        [Normal] [NoScaleOffset]_NormalMap_0 ("C0", 2D) = "bump" {}
        [Normal] [NoScaleOffset]_NormalMap_1 ("C1", 2D) = "bump" {}
        [Normal] [NoScaleOffset]_NormalMap_2 ("C2", 2D) = "bump" {}
        [Normal] [NoScaleOffset]_NormalMap_3 ("C3", 2D) = "bump" {}

        [Header(Animation)]
        _Speed ("Speed", vector) = (0, 0, 0, 0)
        _TimeValue ("Time", float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "OceanForward"
            
            ZWrite On
            Cull[_Cull]
            AlphaToMask[_AlphaToMask]

            HLSLPROGRAM
            
            #pragma target 4.6

            #pragma vertex VertexFunc
            #pragma fragment FragmentFunc

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attribs
            {
                float4 position_os : POSITION;
            };

            struct Varyings
            {
                float2 uv_ws        : TEXCOORD0;
                float3 position_ws   : TEXCOORD1;
                float3 viewVector_ws : TEXCOORD2;
                float4 position_ss  : TEXCOORD3;
                
                float4 position_cs  : SV_POSITION;
            };

            #include "Include/OceanForwardVertex.hlsl"
            #include "Include/OceanForwardFragment.hlsl"

            ENDHLSL
        }
    }
}
