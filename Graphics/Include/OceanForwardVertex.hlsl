uniform sampler2D _HeightMap;
uniform float4 _HeightMap_ST;
uniform float _Height;
uniform float _Fade;


void VertexFunc(Attribs input, out Varyings outVaryings)
{
    float4 position_ws = mul(UNITY_MATRIX_M, input.position_os);
    float2 uv_ws = position_ws.xz * _HeightMap_ST.xy + _HeightMap_ST.zw;

    float2 dir = position_ws.xz - GetCameraPositionWS().xz;
    float fade = 1.0 - saturate((dot(dir, dir) - 100) / (_Fade * _Fade));

    float height = tex2Dlod(_HeightMap, float4(uv_ws, 1, 1)).r * _Height * fade;
    position_ws.y = height;

    outVaryings.position_ws = position_ws.xyz;
    outVaryings.uv_ws = uv_ws;
    outVaryings.viewVector_ws = _WorldSpaceCameraPos - position_ws.xyz;
    outVaryings.position_cs = mul(UNITY_MATRIX_VP, position_ws);
    outVaryings.position_ss = ComputeScreenPos(outVaryings.position_cs);
}