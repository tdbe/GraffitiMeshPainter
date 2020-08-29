Shader "UBER - Bonus/CandleFireDepth" {
Properties {
	_WavingTex ("Wave tex", 2D) = "grey" {}
	_YBottomOffset ("Y bottom offset", Float) = 0
	_Freq ("Wave frequency", Vector) = (0.1,0.1,0.1,0)
	_Amp ("Wave amplitude", Vector) = (0.1,0.1,0.1,0)
	_AmpVertex ("  Amp along Z", Vector) = (0,0,1,0.1)
	_AnimSpeed ("Anim speed", Vector) = (0.1,0.1,0.1,0)
}

Category {
	Tags { "Queue"="Geometry+2" "IgnoreProjector"="True" "RenderType"="Opaque" }
	Cull Back
	
	SubShader {

		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 3.0

			#include "UnityCG.cginc"

	
			sampler2D _WavingTex;
			half3 _Freq;
			half3 _Amp;
			half4 _AmpVertex;
			half3 _AnimSpeed;
			half _YBottomOffset;
					
			struct appdata_t {
				float4 vertex : POSITION;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
			};
			
			v2f vert (appdata_t v)
			{
				v2f o;
				float distAlong=v.vertex.y+_YBottomOffset;
				v.vertex.x += (tex2Dlod(_WavingTex, float4((distAlong.xx+_Time.xx*_AnimSpeed.xx)*_Freq.xx,distAlong,0)).x*2-1)*_Amp.x*saturate(_AmpVertex.x*distAlong)*_AmpVertex.a;
				v.vertex.y += (tex2Dlod(_WavingTex, float4((distAlong.xx+_Time.xx*_AnimSpeed.yy)*_Freq.yy,distAlong,0)).x*2-1)*_Amp.y*saturate(_AmpVertex.y*distAlong)*_AmpVertex.a;
				v.vertex.z += (tex2Dlod(_WavingTex, float4((distAlong.xx+_Time.xx*_AnimSpeed.zz)*_Freq.zz,0,0)).x*2-1)*_Amp.z*saturate(_AmpVertex.z*distAlong)*_AmpVertex.a;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				return 0;
			}
			ENDCG 
		}
	}	
}
}
