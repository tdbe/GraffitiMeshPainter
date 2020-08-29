Shader "Hidden/DeferredTranslucencyBlit" {
	Properties {
		_MainTex ("", 2D) = "white" {}
	}
	
	CGINCLUDE
	
	#include "UnityCG.cginc"
	 
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};
	
	sampler2D _MainTex;
	
	v2f vert( appdata_img v ) 
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		return o;
	} 

	float4 frag(v2f i) : SV_Target 
	{
		half val=tex2D(_MainTex, i.uv).a;
		return val.xxxx;
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
