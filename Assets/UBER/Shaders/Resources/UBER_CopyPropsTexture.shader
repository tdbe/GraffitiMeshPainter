﻿Shader "Hidden/UBER_CopyPropsTexture" {

	Properties {
		_MainTex ("", 2D) = "white" {} // gbuffer3 (light/emission buffer)
	}
	
	CGINCLUDE
	
	#include "UnityCG.cginc"
	 
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};
	
	sampler2D _MainTex;
	float4 _MainTex_ST;
	
	v2f vert( appdata_img v ) 
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		return o;
	} 

	// simply copy this for further usage
	half4 frag(v2f i) : SV_Target
	{
		float2 correctedUv = UnityStereoScreenSpaceUVAdjust(i.uv, _MainTex_ST);
		return tex2D(_MainTex, correctedUv).a;
	}
	
	ENDCG 
	
Subshader {
 Pass {
	  ZTest Always Cull Off ZWrite Off

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      ENDCG
  }
}

Fallback off
	
} // shader
