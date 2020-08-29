Shader "UBER - Bonus/Skybox button" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_SpecGloss ("Spec (RGB) Gloss (A)", Color) = (0.2, 0.2, 0.2, 0.8)
	_Cube ("Reflection Cubemap", Cube) = "_Skybox" {}
}
SubShader {
	LOD 300
	Tags { "RenderType"="Opaque" }

CGPROGRAM
#pragma surface surf Lambert

#pragma target 3.0

samplerCUBE _Cube;

fixed4 _Color;
fixed4 _SpecGloss;

struct Input {
	float3 worldRefl;
};

void surf (Input IN, inout SurfaceOutput o) {
//	fixed4 tex = 0;//tex2D(_MainTex, IN.uv_MainTex);
//	fixed4 c = tex * _Color;
//	o.Albedo = c.rgb;
//	o.Gloss = tex.a;
//	o.Specular = _SpecGloss.a;
	
	half4 reflcol = texCUBElod(_Cube, float4(IN.worldRefl,(1-_SpecGloss.a)*8));
	reflcol.rgb*=reflcol.a*6;
//	reflcol *= tex.a;
	o.Emission = reflcol.rgb * _SpecGloss.rgb;
	o.Alpha = 1;
}
ENDCG
}

FallBack Off
}
