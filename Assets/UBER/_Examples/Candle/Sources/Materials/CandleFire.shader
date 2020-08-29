Shader "UBER - Bonus/CandleFire" {
Properties {
	_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
	_ColorMultiplier ("Color multiplier", Float) = 100
	_MainTex ("Particle Texture", 2D) = "white" {}
	_InvFade ("Soft Particles Factor", Range(0.01,3.0)) = 1.0
	_FresnelExponent ("Fresnel exponent side", Float) = 4
	_FresnelOffset ("   Fresnel offset side", Range(-1,1)) = 0
	_FresnelExponentTop ("Fresnel exponent top", Float) = 1
	_FresnelOffsetTop ("   Fresnel offset top", Range(-1,1)) = 0
	_FresnelTextureOffset ("Fresnel texture offset", Float) = 0.3
	
	_WavingTex ("Wave tex", 2D) = "grey" {}
	_YBottomOffset ("Y bottom offset", Float) = 0
	_Freq ("Wave frequency", Vector) = (0.1,0.1,0.1,0)
	_Amp ("Wave amplitude", Vector) = (0.1,0.1,0.1,0)
	_AmpVertex ("  Amp along Z", Vector) = (0,0,1,0.1)
	_AnimSpeed ("Anim speed", Vector) = (0.1,0.1,0.1,0)
}

Category {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	Blend SrcAlpha OneMinusSrcAlpha
	AlphaTest Greater .01
	ColorMask RGB
	Cull Off Lighting Off ZWrite On
	
	SubShader {
		Pass {
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_particles
			#pragma multi_compile_fog

			#pragma target 3.0

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			fixed4 _TintColor;
			half _ColorMultiplier;
			half _FresnelExponent;
			half _FresnelOffset;
			half _FresnelExponentTop;
			half _FresnelOffsetTop;
			half _FresnelTextureOffset;
			
			sampler2D _WavingTex;
			half3 _Freq;
			half3 _Amp;
			half4 _AmpVertex;
			half3 _AnimSpeed;
			half _YBottomOffset;
					
			struct appdata_t {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0; 
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float3 eyeDir : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				UNITY_FOG_COORDS(3)
				#ifdef SOFTPARTICLES_ON
				float4 projPos : TEXCOORD4;
				#endif
			};
			
			float4 _MainTex_ST;

			v2f vert (appdata_t v)
			{
				v2f o;
				float distAlong=v.vertex.y+_YBottomOffset;
				v.vertex.x += (tex2Dlod(_WavingTex, float4((distAlong.xx+_Time.xx*_AnimSpeed.xx)*_Freq.xx,distAlong,0)).x*2-1)*_Amp.x*saturate(_AmpVertex.x*distAlong)*_AmpVertex.a;
				v.vertex.y += (tex2Dlod(_WavingTex, float4((distAlong.xx+_Time.xx*_AnimSpeed.yy)*_Freq.yy,distAlong,0)).x*2-1)*_Amp.y*saturate(_AmpVertex.y*distAlong)*_AmpVertex.a;
				v.vertex.z += (tex2Dlod(_WavingTex, float4((distAlong.xx+_Time.xx*_AnimSpeed.zz)*_Freq.zz,0,0)).x*2-1)*_Amp.z*saturate(_AmpVertex.z*distAlong)*_AmpVertex.a;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float3 worldPos=mul(unity_ObjectToWorld, v.vertex).xyz;
				o.eyeDir = normalize(worldPos-_WorldSpaceCameraPos);
				o.worldNormal = UnityObjectToWorldNormal(v.normal.xyz);
				#ifdef SOFTPARTICLES_ON
				o.projPos = ComputeScreenPos (o.vertex);
				COMPUTE_EYEDEPTH(o.projPos.z);
				#endif
				o.color = v.color;
				o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			sampler2D_float _CameraDepthTexture;
			float _InvFade;
			
			half4 frag (v2f i) : SV_Target
			{
				#ifdef SOFTPARTICLES_ON
				float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
				float partZ = i.projPos.z;
				float fade = saturate (_InvFade * (sceneZ-partZ));
				i.color.a *= fade;
				#endif
				
				half fresnelSide=saturate(1-exp2(_FresnelExponent*(dot(i.eyeDir, i.worldNormal)+_FresnelOffset)));
				half fresnelTop=saturate(1-exp2(_FresnelExponentTop*(dot(i.eyeDir, i.worldNormal)+_FresnelOffsetTop)));
				half fresnel=lerp(fresnelSide, fresnelTop, saturate((abs(i.eyeDir.y)-0.5)*4));
				half4 col = i.color * _TintColor * tex2D(_MainTex, i.texcoord.xy+float2(0,-fresnel*_FresnelTextureOffset*saturate((-i.texcoord.y*2+1))));
				col.rgb*=_ColorMultiplier;
				col.a*=fresnel;
				UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(0,0,0,0)); // fog towards black due to our blend mode
				return col;
			}
			ENDCG 
		}
	}	
}
}
