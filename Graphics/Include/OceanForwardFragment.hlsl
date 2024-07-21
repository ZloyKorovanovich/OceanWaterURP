#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

uniform Texture2D _NormalMap_0;
uniform Texture2D _NormalMap_1;
uniform Texture2D _NormalMap_2;
uniform Texture2D _NormalMap_3;

uniform half4 _Color;

uniform half _Refraction;
uniform half _Depth;

uniform half _Smoothness;
uniform half _Specular;
uniform half _Ambient;
uniform half _Fresnel;

uniform half _DepthPower;

uniform half _SSSPower;
uniform half _SSSIntensity;
uniform half _SSSNormal;
uniform half _CoatRadius;

uniform half _AbsorptionLevel;
uniform half _AbsorptionPower;
uniform half _AbsorptionContrast;

uniform half _BackIntensity;

uniform float4 _Speed;
uniform float _TimeValue;

uniform SamplerState bilinearRepeatSampler;

//Normals
half3 NormalBlend(half3 A, half3 B)
{
    return normalize(half3(A.rg + B.rg, A.b * B.b));
}

half3 NormalStrength(half3 normal, half strength)
{
    normal.xy *= strength;
    return normalize(normal);
}

half3 SampleNormalMap(Texture2D map, SamplerState ss, float2 uv)
{
    half4 sampleResult = SAMPLE_TEXTURE2D(map, ss, uv);
    return UnpackNormalmapRGorAG(sampleResult);
}

float3 TransformNormalToWS(float3 tangent, float3 normal, float3 bitangent, float3 normal_ts)
{
    return normalize(mul(float3x3(tangent, bitangent, normal), normal_ts));
}

//Effects
half Fresnel(half3 normal, half3 viewDir, half power)
{
    return pow((1.0 - saturate(dot(normalize(normal), normalize(viewDir)))), power);
}

//Surface
float2 GetSSUV(float4 screenPosition)
{
    return screenPosition.xy / screenPosition.w;
}

half3 WaterRefractedScene(float4 baseColor, float4 screenPosition, float2 ssUV, half depth, half depthPower, half3 normal, half refraction)
{
    float2 refract = normal.xz * refraction;

    float d = 1.0 - saturate(Linear01Depth(SampleSceneDepth(ssUV), _ZBufferParams) * _ProjectionParams.z - (_Depth + screenPosition.w - 1));
    float dR = 1.0 - saturate(Linear01Depth(SampleSceneDepth(ssUV + refract), _ZBufferParams) * _ProjectionParams.z - (_Depth + screenPosition.w - 1));

    return lerp(baseColor.rgb, SampleSceneColor(ssUV + refract).rgb, pow(saturate(d * dR/ _Depth), depthPower));
}

half3 WaterSurfaceColor(half3 baseColor, half3 viewDir, half sss, half sssIntensity, half3 normal, half sssNormal)
{
    half3 color = baseColor.rgb * _MainLightColor.rgb;

    half alig = dot(viewDir, _MainLightPosition.xyz);

    half sssSun = 1.0 - saturate(dot(half3(0, 1, 0), _MainLightPosition.xyz));
    half3 sssColor = sqrt(_MainLightColor.rgb * _Color.rgb);

    half viewDot = saturate(-alig);
    half sssMasked = saturate(sss * sssSun + (1 - normal.y) * sssNormal * viewDot);
    half scattering = saturate(sssMasked * (sssIntensity - saturate(alig)));

    return color + scattering * sqrt(_MainLightColor.rgb * baseColor);
}

half3 WaterReflectionModel(half3 surface, half3 normal, half3 viewDir, half smoothness, half specular, half ambientInfuence, half fresnel)
{
    half specFade = saturate(Fresnel(normal, viewDir, fresnel));
    half specMask = 1 - specFade;

    half3 reflection = reflect(-viewDir, normal);

    half3 halfVector = normalize(_MainLightPosition.xyz + viewDir);
    half spec = pow(saturate(dot(normal, halfVector)), smoothness) * specular * specMask;
    half3 specColor = _MainLightColor.rgb;

    half env = specFade * ambientInfuence;
    half3 envColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, bilinearRepeatSampler, reflection, 2).rgb;

    return saturate(lerp(surface + envColor * env , specColor, spec));
}

half Absorption(half3 normal, half3 viewDir, half absorptionPower, half absorptionLevel, half absorptionContrast)
{
    half fresnel = Fresnel(-normal, viewDir, absorptionPower);
    return saturate((fresnel - (1.0 - absorptionLevel)) * absorptionContrast + absorptionLevel);
}


void FragmentFunc(Varyings input, bool IsFacing:SV_IsFrontFace, out half4 outColor : SV_Target)
{
    float3 normal = float3(0, 1, 0);
    float3 tangent = float3(1, 0, 0);
    float3 bitangent = float3(0, 0, 1);

    float3 n_0 = SampleNormalMap(_NormalMap_0, bilinearRepeatSampler, input.uv_ws + _Speed.xy * _TimeValue);
    float3 n_1 = SampleNormalMap(_NormalMap_1, bilinearRepeatSampler, input.uv_ws - _Speed.xy * _TimeValue);
    
    float3 n_2 = SampleNormalMap(_NormalMap_2, bilinearRepeatSampler, input.uv_ws + _Speed.zw * _TimeValue);
    float3 n_3 = SampleNormalMap(_NormalMap_3, bilinearRepeatSampler, input.uv_ws - _Speed.zw * _TimeValue);

    float h = tex2D(_HeightMap, input.uv_ws).r;

    float3 n = NormalBlend(NormalBlend(n_0, n_1), NormalBlend(n_2, n_3));
    n = NormalStrength(n, _Height * 0.25);
    n = TransformNormalToWS(tangent, normal, bitangent, n);

    half3 viewDir = normalize(input.viewVector_ws);
    half3 surface;
    float2 ssUV = GetSSUV(input.position_ss);


    if(IsFacing)
    {
        surface = WaterRefractedScene(_Color, input.position_ss, ssUV, _Depth, _DepthPower, n, _Refraction);
        surface = WaterSurfaceColor(surface, viewDir, pow(abs(h), _SSSPower), _SSSIntensity, n, _SSSNormal);
        surface = WaterReflectionModel(surface, n, viewDir, _Smoothness, _Specular, _Ambient, _Fresnel);
    }
    else
    {
        half absorption = Absorption(n, viewDir, _AbsorptionPower, _AbsorptionLevel, _AbsorptionContrast);
        surface = lerp(SampleSceneColor(ssUV), saturate(_Color.rgb * _MainLightColor.rgb * _BackIntensity), absorption);
        surface = WaterReflectionModel(surface, -n, viewDir, _Smoothness, 0, _Ambient, _Fresnel * 0.5);
    }

    outColor = half4(surface, 1);
}