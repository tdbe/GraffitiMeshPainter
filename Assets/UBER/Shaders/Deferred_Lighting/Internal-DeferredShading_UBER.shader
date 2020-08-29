Shader "Hidden/Internal-DeferredShading_UBER" {
	Properties{
		_LightTexture0("", any) = "" {}
		_LightTextureB0("", 2D) = "" {}
		_ShadowMapTexture("", any) = "" {}
		_SrcBlend("", Float) = 1
		_DstBlend("", Float) = 1
	}

		// =================================== BEGIN UBER SUPPORT ===================================
		CGINCLUDE
			// when using both features check UBER_StandardConfig.cginc to configure Gbuffer channels
			// by default translucency is passed in diffuse (A) gbuffer and self-shadows are passed in normal (A) channel
			//
			// NOTE that you're not supposed to use Standard shader with occlusion data together with UBER translucency in deferred, because Standard Shader writes occlusion velue in GBUFFER0 alpha as the translucency does !
			//
			#define UBER_TRANSLUCENCY_DEFERRED
			#define UBER_POM_SELF_SHADOWS_DEFERRED
			//
			// comment this out when you'd like to have translucency in deferred not influenced by diffuse/base object color
			#define UBER_TRANSLUCENCY_DEFERRED_MULT_DIFFUSE
			//
			// define when you like to control translucency power per light (its color alpha channel)
			// note, that this can interfere with solutions that uses light color.a for different purpose (like Alloy)
			//#define UBER_TRANSLUCENCY_PER_LIGHT_ALPHA	
			//
			// you can gently turn it up (like 0.3, 0.5) if you find front facing geometry overbrighten (esp. for point lights),
			// but suppresion can negate albedo for high translucency values (they can become badly black)
			#define TRANSLUCENCY_SUPPRESS_DIFFUSECOLOR 0.0	

			// change to 1 to get GGX specularity model in deferred
			#define UNITY_BRDF_GGX 1
		ENDCG
		// ==================================== END UBER SUPPORT ====================================

		SubShader{

		// Pass 1: Lighting pass
		//  LDR case - Lighting encoded into a subtractive ARGB8 buffer
		//  HDR case - Lighting additively blended into floating point buffer
		Pass{
		ZWrite Off
		Blend[_SrcBlend][_DstBlend]

		CGPROGRAM

	#pragma target 3.0
	#pragma vertex vert_deferred
	#pragma fragment frag
	#pragma multi_compile_lightpass
	#pragma multi_compile ___ UNITY_HDR_ON

	#pragma exclude_renderers nomrt

	#include "UnityCG.cginc"
	#include "../UBER_StandardConfig.cginc"
	#include "../Includes/UBER_UnityDeferredLibrary.cginc"
	#include "UnityPBSLighting.cginc"
	#include "UnityStandardBRDF.cginc"

	#ifdef UNITY_GLOSS_MATCHES_MARMOSET_TOOLBAG2
		#undef UNITY_GLOSS_MATCHES_MARMOSET_TOOLBAG2
		#define UNITY_GLOSS_MATCHES_MARMOSET_TOOLBAG2 0
	#endif

	sampler2D _CameraGBufferTexture0;
	sampler2D _CameraGBufferTexture1;
	sampler2D _CameraGBufferTexture2;

	// =================================== BEGIN UBER SUPPORT ===================================

	// UBER - POM self-shadowing (for one realtime light)
	#if defined(UBER_POM_SELF_SHADOWS_DEFERRED)
		float4		_WorldSpaceLightPosCustom;
	#endif

		// UBER - Translucency, POM self-shadowing, wetness values encoded
	#if defined(UBER_POM_SELF_SHADOWS_DEFERRED) || defined(UBER_TRANSLUCENCY_DEFERRED)
		sampler2D _UBERPropsBuffer;
	#endif

		// UBER - Translucency
	#if defined(UBER_TRANSLUCENCY_DEFERRED)
		sampler2D _UBERTranslucencySetup;
		struct TranslucencyParams {
			half3 _TranslucencyColor;
			half _TranslucencyStrength;
			half _TranslucencyConstant;
			half _TranslucencyNormalOffset;
			half _TranslucencyExponent;
			half _TranslucencyPointLightDirectionality;
			half _TranslucencySuppressRealtimeShadows;
			half _TranslucencyNDotL;
		};

		inline half Translucency(half3 normalWorld, UnityLight light, half3 eyeVec, TranslucencyParams translucencyParams) {
	#ifdef USING_DIRECTIONAL_LIGHT
			half tLitDot = saturate(dot((light.dir + normalWorld*translucencyParams._TranslucencyNormalOffset), eyeVec));
	#else
			float3 lightDirectional = normalize(_LightPos.xyz - _WorldSpaceCameraPos.xyz);
			light.dir = normalize(lerp(light.dir, lightDirectional, translucencyParams._TranslucencyPointLightDirectionality));
			half tLitDot = saturate(dot((light.dir + normalWorld*translucencyParams._TranslucencyNormalOffset), eyeVec));
	#endif
			tLitDot = exp2(-translucencyParams._TranslucencyExponent*(1 - tLitDot))*translucencyParams._TranslucencyStrength;
			float NDotL = abs(dot(light.dir, normalWorld));
			tLitDot *= lerp(1, NDotL, translucencyParams._TranslucencyNDotL);

			half translucencyAtten = (tLitDot + translucencyParams._TranslucencyConstant*(NDotL + 0.1));
	#if defined(UBER_TRANSLUCENCY_PER_LIGHT_ALPHA)
			translucencyAtten *= _LightColor.a;
	#endif

			return translucencyAtten;
		}
	#endif
	// ==================================== END UBER SUPPORT ====================================

	half4 CalculateLight(unity_v2f_deferred i)
	{
		float3 wpos;
		float2 uv;
		float atten, shadow_atten, fadeDist;
		UnityLight light;
		UNITY_INITIALIZE_OUTPUT(UnityLight, light);
		UnityDeferredCalculateLightParams(i, wpos, uv, light.dir, atten, shadow_atten, fadeDist);

		half4 gbuffer0 = tex2D(_CameraGBufferTexture0, uv);
		half4 gbuffer1 = tex2D(_CameraGBufferTexture1, uv);
		half4 gbuffer2 = tex2D(_CameraGBufferTexture2, uv);

		// =================================== BEGIN UBER SUPPORT ===================================
		#if defined(UBER_POM_SELF_SHADOWS_DEFERRED) || defined(UBER_TRANSLUCENCY_DEFERRED)
			// buffer decoded from _CameraGBufferTexture3.a in command buffer
			half Wetness = 0;
			half SS = 1;
			half translucencySetupIndex = 0;
			half translucency_thickness = 0;
			float encoded = tex2D(_UBERPropsBuffer, uv).r;
			if (encoded < 0) {
				encoded = -encoded;

				// wetness (not used currently so below line should get compiled out)
				encoded /= 8.0; // 3 bits
				Wetness = frac(encoded) * (8.0 / 7.0); // to 0..1 range
				encoded = floor(encoded);

				// self shadowing
				encoded /= 4.0; // 2 bits
				SS = 1 - frac(encoded) * (4.0 / 3.0); // to 0..1 range
				encoded = floor(encoded);

				// translucency color index
				encoded /= 4.0; // 2 bits
				translucencySetupIndex = frac(encoded); // directly decoded as U coord in lookup texture
				encoded = floor(encoded);

				// translucency thickness
				encoded /= 15.0; // 4 bits (divide by 15 instead of 16 to bring it immediately to 0..1 range)
				translucency_thickness = encoded;
			} // else - no prop used for this pixel (no translucency, self-shadowing and surface is considered to be dry)
			//translucencySetupIndex = 0;
			//translucency_thickness = 1;
		#endif

		// UBER - POM self-shadowing (for one realtime light)
		#if defined(UBER_POM_SELF_SHADOWS_DEFERRED)
			// conditional to attenuate only the selected realtime light
			#if defined (DIRECTIONAL) || defined (DIRECTIONAL_COOKIE)
				atten = (abs(dot((_LightDir.xyz + _WorldSpaceLightPosCustom.xyz), float3(1,1,1))) < 0.01) ? min(atten, SS) : atten;
			#else
				atten = (abs(dot((_LightPos.xyz - _WorldSpaceLightPosCustom.xyz), float3(1,1,1))) < 0.01) ? min(atten, SS) : atten;
			#endif
		#endif
		// ==================================== END UBER SUPPORT ====================================

		light.color = _LightColor.rgb * atten;
		half3 baseColor = gbuffer0.rgb;
		half3 specColor = gbuffer1.rgb;
		half oneMinusRoughness = gbuffer1.a;
		half3 normalWorld = gbuffer2.rgb * 2 - 1;
		normalWorld = normalize(normalWorld);
		float3 eyeVec = normalize(wpos - _WorldSpaceCameraPos);
		half oneMinusReflectivity = 1 - SpecularStrength(specColor.rgb);
		light.ndotl = LambertTerm(normalWorld, light.dir);

		UnityIndirect ind;
		UNITY_INITIALIZE_OUTPUT(UnityIndirect, ind);
		ind.diffuse = 0;
		ind.specular = 0;

		// =================================== BEGIN UBER SUPPORT ===================================
		#if defined(UBER_TRANSLUCENCY_DEFERRED)
			half setupIndex = translucencySetupIndex; // [0..1] to [0..1) range

			half4 val;
			val = tex2D(_UBERTranslucencySetup, float2(setupIndex, 0));
			TranslucencyParams translucencyParams;
			translucencyParams._TranslucencyColor = val.rgb;
			translucencyParams._TranslucencyStrength = val.a;
			val = tex2D(_UBERTranslucencySetup, float2(setupIndex, 0.4));
			translucencyParams._TranslucencyPointLightDirectionality = val.r;
			translucencyParams._TranslucencyConstant = val.g;
			translucencyParams._TranslucencyNormalOffset = val.b;
			translucencyParams._TranslucencyExponent = val.a;
			val = tex2D(_UBERTranslucencySetup, float2(setupIndex, 0.8));
			translucencyParams._TranslucencySuppressRealtimeShadows = val.r;
			translucencyParams._TranslucencyNDotL = val.g;

			half3 TL = Translucency(normalWorld, light, eyeVec, translucencyParams)*translucencyParams._TranslucencyColor;
			#if defined(UBER_TRANSLUCENCY_DEFERRED_MULT_DIFFUSE)
				TL *= baseColor;
			#endif
			TL *= translucency_thickness;
			baseColor *= saturate(1 - max(max(TL.r, TL.g), TL.b)*TRANSLUCENCY_SUPPRESS_DIFFUSECOLOR);
			// suppress shadows
			shadow_atten = lerp(shadow_atten, 1, saturate(dot(TL,1)*translucencyParams._TranslucencySuppressRealtimeShadows));
		#endif

		// apply shadows here (possibly suppressed by translucency or forward decal)
		light.color *= shadow_atten;
		// ==================================== END UBER SUPPORT ====================================

		half4 res = UNITY_BRDF_PBS(baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normalWorld, -eyeVec, light, ind);

		// =================================== BEGIN UBER SUPPORT ===================================
		#if defined(UBER_TRANSLUCENCY_DEFERRED)
				res.rgb += TL*light.color;
				//res.rgb = Wetness;
		#endif		
		// ==================================== END UBER SUPPORT ====================================

		return res;
	}

#ifdef UNITY_HDR_ON
	half4
#else
	fixed4
#endif
		frag(unity_v2f_deferred i) : SV_Target
	{
		half4 c = CalculateLight(i);
#ifdef UNITY_HDR_ON
		return c;
#else
		return exp2(-c);
#endif

	}

		ENDCG
	}


		// Pass 2: Final decode pass.
		// Used only with HDR off, to decode the logarithmic buffer into the main RT
		Pass{
		ZTest Always Cull Off ZWrite Off
		ColorMask RGB
		Stencil{
			ref[_StencilNonBackground]
			readmask[_StencilNonBackground]
			// Normally just comp would be sufficient, but there's a bug and only front face stencil state is set (case 583207)
			compback equal
			compfront equal
		}

		CGPROGRAM
#pragma target 3.0
#pragma vertex vert
#pragma fragment frag
#pragma exclude_renderers nomrt

#include "UnityCG.cginc"

		sampler2D _LightBuffer;
	struct v2f {
		float4 vertex : SV_POSITION;
		float2 texcoord : TEXCOORD0;
	};

	v2f vert(float4 vertex : POSITION, float2 texcoord : TEXCOORD0)
	{
		v2f o;
		o.vertex = UnityObjectToClipPos(vertex);
		o.texcoord = texcoord.xy;
#ifdef UNITY_SINGLE_PASS_STEREO
	o.texcoord = TransformStereoScreenSpaceTex(o.texcoord, 1.0f);
#endif

		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		return -log2(tex2D(_LightBuffer, i.texcoord));
	}
		ENDCG
	}

	}
		Fallback Off
}
