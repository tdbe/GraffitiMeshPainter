// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

#ifndef UBER_STANDARD_INPUT_INCLUDED
#define UBER_STANDARD_INPUT_INCLUDED

#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "Tessellation.cginc"

//---------------------------------------

#if !defined(DISTANCE_MAP) && (defined(_POM_DISTANCE_MAP) || defined(_POM_DISTANCE_MAP_ZWRITE) || defined(_POM_DISTANCE_MAP_SHADOWS))
	#define DISTANCE_MAP
#endif

#if !defined(EXTRUSION_MAP) && (defined(_POM_EXTRUSION_MAP) || defined(_POM_EXTRUSION_MAP_ZWRITE) || defined(_POM_EXTRUSION_MAP_SHADOWS))
	#define EXTRUSION_MAP
#endif

#if !defined(POM) && (defined(_PARALLAX_POM) || defined(_PARALLAX_POM_ZWRITE) || defined(_PARALLAX_POM_SHADOWS))
	#define POM
#endif

#if !defined(TRIPLANAR) && (defined(TRIPLANAR_SELECTIVE))
 	#define TRIPLANAR
#endif

// Directional lightmaps & Parallax require tangent space too
#if (_NORMALMAP || DIRLIGHTMAP_COMBINED || DIRLIGHTMAP_SEPARATE || !DIRLIGHTMAP_OFF || _PARALLAXMAP || _PARALLAXMAP_2MAPS || _PARALLAX_POM || _PARALLAX_POM_ZWRITE || _PARALLAX_POM_SHADOWS || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP) || !defined(_WETNESS_NONE) || defined(_SNOW))
	#define _TANGENT_TO_WORLD 1 
#endif

// we can configure it in UBER_StandardConfig.cginc or in shader (to customize/overwrite config value)
//#if (_DETAIL_MULX2 || _DETAIL_MUL || _DETAIL_ADD || _DETAIL_LERP)
#if defined(_DETAIL_TEXTURED) || defined(_DETAIL_TEXTURED_WITH_SPEC_GLOSS)
	#define _DETAIL 1
#endif

// wetness state
//#if defined(_WETNESS_SIMPLE) || defined(_WETNESS_RIPPLES) || defined(_WETNESS_DROPLETS) || defined(_WETNESS_FULL)
#if !defined(_WETNESS_NONE)
	#define _WETNESS 1
#endif

#if (defined(_PARALLAX_POM_ZWRITE) || defined(_POM_DISTANCE_MAP_ZWRITE) || defined(_POM_EXTRUSION_MAP_ZWRITE)) && !defined(ZWRITE)
	#define ZWRITE 1
#endif

float4 UBER_Time; // custom time
uniform float _Occlusion_from_albedo_alpha; // bool feature flag (used float for d3d9 compatibility)
uniform float _Smoothness_from_albedo_alpha;

#if defined(_TWO_LAYERS)
half4		_Color2;
sampler2D	_MainTex2;
sampler2D	_BumpMap2;
float4		_BumpMap2_TexelSize;
float4		bumpMap2TexelSize;
half		_BumpScale2;
half4		_SpecColor2;
sampler2D	_SpecGlossMap2;
sampler2D	_MetallicGlossMap2;
half		_Metallic2;
half		_Glossiness2;
sampler2D	_ParallaxMap2;
half		_Parallax2;
half		_OcclusionStrength2;
half4		_DiffuseScatteringColor2;
half4		_GlitterColor2;
half4		_TranslucencyColor2;
#if defined(TRIPLANAR_SELECTIVE)
half4		_MainTex2AverageColor;
#endif
#endif



//---------------------------------------
half4		_Color;
half		_Cutoff;

sampler2D	_MainTex;
float4		_MainTex_ST;

sampler2D	_DetailAlbedoMap;
float4		_DetailAlbedoMap_ST;

sampler2D	_BumpMap;
float4		_BumpMap_TexelSize;
float4		bumpMapTexelSize;
half		_BumpScale;

sampler2D	_DetailMask;
sampler2D	_DetailNormalMap;
half		_DetailNormalMapScale;

sampler2D	_SpecGlossMap;

sampler2D	_MetallicGlossMap;
half		_Metallic;
half		_Glossiness;

sampler2D	_OcclusionMap;
half		_OcclusionStrength;
half		_SecOcclusionStrength;

sampler2D	_ParallaxMap;
float4		_ParallaxMap_TexelSize;
float4		heightMapTexelSize;

half		_Parallax;
half		_UVSec; // flag (detail from UV0/UV1/World switch)
half		_UVSecOcclusion; // flag (occlusion from UV0/UV1 switch)
half		_UVSecOcclusionLightmapPacked; // flag ( !=0 apply lightmap UV transform for 2ndary occlusion taken from UV1)

half4 		_EmissionColor;
half4		_CutoffEdgeGlow;
sampler2D	_EmissionMap;

bool		_DiffuseScatter;
half4		_DiffuseScatteringColor;
half		_DiffuseScatteringExponent;
half		_DiffuseScatteringOffset;
half		_GlossMin;
half		_GlossMax;
// bend normals
half		_BendNormalsFreq;
half		_BendNormalsStrength;

// Detail
half		_DetailUVMult;
half		_DetailNormalLerp;
half4		_DetailColor;
half		_DetailSpecLerp;
half        _DetailEmissiveness;
sampler2D	_SpecularRGBGlossADetail;
half4		_DetailSpecGloss;
// detail metallic workflow
sampler2D	_MetallicGlossMapDetail;
half		_DetailMetalness;
half		_DetailGloss;

// Emission
#if defined(_EMISSION_ANIMATED)
bool		_PanEmissionMask;
half        _PanUSpeed;
half        _PanVSpeed;
bool		_PulsateEmission;
half        _EmissionPulsateSpeed;
half        _MinPulseBrightness;
#endif

//Translucency
#if defined(_TRANSLUCENCY)
half4		_TranslucencyColor;
half		_TranslucencyStrength;
half		_TranslucencyConstant;
half		_TranslucencyNormalOffset;
half		_TranslucencyExponent;
half		_TranslucencyOcclusion;
half		_TranslucencyPointLightDirectionality;
half		_TranslucencySuppressRealtimeShadows;
half		_TranslucencyDeferredLightIndex;

half		_TranslucencyNDotL;
#endif

// POM
#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
	float		_Depth;
	int			_DistSteps;
	float		_ReliefMIPbias;
	float 		_DepthReductionDistance;
	float4		_CurvatureMultOffset;
	float4		_Tan2ObjectMultOffset;

	bool		_UV_Clip;
	float4		_UV_Clip_Borders;
	float		_POM_BottomCut;
	bool		_POM_MeshIsVolume;
	bool		_POM_ExtrudeVolume;
	
	#if defined(SILHOUETTE_CURVATURE_MAPPED)
		sampler2D	_ObjectNormalsTex;
		sampler2D	_ObjectTangentsTex;
	#endif
#endif    

#if defined(_PARALLAX_POM_SHADOWS) || defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS)
float		_ShadowStrength;
float		_DistStepsShadows;
float		_ShadowMIPbias;
float		_Softness;
float		_SoftnessFade;
#endif
float4		_WorldSpaceLightPosCustom;

// refraction
sampler2D	_GrabTexture;
float		_Refraction;
float		_RefractionBumpScale;
float		_RefractionChromaticAberration;

// wetness
#if !defined(_WETNESS_NONE)
half		_UBER_GlobalDry;
half		_UBER_GlobalDryConst;

half		_WetnessLevel;
half		_WetnessConst;
half4		_WetnessColor;
half4		_WetnessSpecGloss;
half		_WetnessEmissiveness;
half		_WetnessNormalInfluence;
half		_WetnessUVMult;

half		_WetnessDarkening;
bool		_WetnessEmissivenessWrap;
bool		_WetnessMergeWithSnowPerMaterial;

bool		_WetnessLevelFromGlobal;
bool		_WetnessConstFromGlobal;
bool		_WetnessFlowGlobalTime;
#endif

#if defined(_WETNESS_RIPPLES) || defined(_WETNESS_FULL) || defined(_SNOW)
sampler2D	_RippleMap;
float4		_RippleMap_TexelSize;
#endif

#if defined(_WETNESS_RIPPLES) || defined(_WETNESS_FULL)
half		_UBER_RippleStrength;

bool		_WetRipples;
half		_RippleStrength;
bool		_RippleStrengthFromGlobal;
half		_RippleTiling;
half		_RippleSpecFilter;
half		_RippleAnimSpeed;
half		_FlowCycleScale;
half		_WetnessNormMIP;
half		_WetnessNormStrength;
#endif

#if defined(_WETNESS_RIPPLES) || defined(_WETNESS_DROPLETS) || defined(_WETNESS_FULL)
half		_RippleRefraction;
#endif

#if defined(_WETNESS_DROPLETS) || defined(_WETNESS_FULL)
bool		_WetDroplets;
sampler2D	_DropletsMap;
half		_DropletsTiling;
half		_UBER_GlobalRainDamp;
half		_RainIntensity;
bool		_RainIntensityFromGlobal;
half		_DropletsAnimSpeed;
#endif

// tessellation
#if defined(_TESSELLATION)
float		_TessDepth;
float		_TessOffset;
float		_Tess;
float		_TessEdgeLengthLimit;
float		minDist;
float		maxDist;
float		_Phong;
float		_PhongStrength;
#endif

// snow
#if defined(_SNOW)
half		_UBER_GlobalSnowDamp;
half		_UBER_GlobalSnowBumpMicro;
half4		_UBER_GlobalSnowSpecGloss;
half4		_UBER_GlobalSnowGlitterColor;
half		_UBER_GlobalSnowDissolve;
half		_UBER_Frost;
        
bool		_SnowLevelFromGlobal;
bool		_SnowBumpMicroFromGlobal;
bool		_SnowDissolveFromGlobal;
bool		_SnowSpecGlossFromGlobal;
bool		_SnowGlitterColorFromGlobal;

half4		_SnowColorAndCoverage;
half		_Frost;
bool		_FrostFromGlobal;
half4		_SnowSpecGloss;
half		_SnowSlopeDamp;
half4		_SnowDiffuseScatteringColor;
half		_SnowDiffuseScatteringExponent;
half		_SnowDiffuseScatteringOffset;
half		_SnowDeepSmoothen;
half3		 _SnowEmissionTransparency;

half		_SnowMicroTiling;
half		_SnowMacroTiling;
half		_SnowBumpMicro;
half		_SnowBumpMacro;
bool		_SnowBumpMicro2Used;
half		_SnowMicroTiling2;
half		_SnowBumpMicro2;
bool		_SnowWorldMapping;

half		_SnowDissolve;
half		_SnowDissolveMaskOcclusion;
half4		_SnowTranslucencyColor;

half		_SnowHeightThreshold;
half		_SnowHeightThresholdTransition;
#endif

// glitter
#if defined(_GLITTER)
half4		_GlitterColor;
half4		_SnowGlitterColor;
half		_GlitterColorization;
half		_GlitterDensity;
half		_GlitterTiling;
float		_GlitterAnimationFrequency;
float		_GlitterFilter;
half		_GlitterMask;
#endif

#if defined(_SNOW) || defined(_GLITTER)
sampler2D	_SparkleMap;
float4		_SparkleMap_TexelSize;
#endif

// RTP - geom blend
#if defined(GEOM_BLEND)
sampler2D	_TERRAIN_HeightMap;
sampler2D	_TERRAIN_Control;
float4		_TERRAIN_PosSize;
float4		_TERRAIN_Tiling;
#endif

// triplanar
#if defined(TRIPLANAR_SELECTIVE)
half4		_MainTexAverageColor;
half		_TriplanarBlendSharpness;
half		_TriplanarNormalBlendSharpness;
half		_TriplanarHeightmapBlendingValue;
half		_TriplanarBlendAmbientOcclusion;
#endif

//
#include "../Includes/UBER_StandardUtils2.cginc"

//-------------------------------------------------------------------------------------
// Input functions

// UBER - helper
half4 tex2Dp(sampler2D _Tex, float2 _uv, float2 _ddx, float2 _ddy) {
	#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP) || defined(TRIPLANAR_SELECTIVE)
		return tex2Dgrad(_Tex, _uv, _ddx, _ddy);
	#else
		return tex2D(_Tex, _uv); // ignore derivatives, they will be compiled-out
	#endif
}

// UBER - helper for snow
half4 tex2Db(sampler2D _Tex, float2 _uv, float2 _ddx, float2 _ddy, half bias) {
	//#if defined(POM) || defined(_PARALLAXMAP) || defined(_PARALLAXMAP_2MAPS) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		return tex2Dgrad(_Tex, _uv, _ddx*exp2(bias), _ddy*exp2(bias));
	//#else
	//	return tex2Dbias(_Tex, float4(_uv, bias.xx));
	//#endif
}


struct VertexInput
{
	float4 vertex	: POSITION;
	half3 normal	: NORMAL;
	float2 uv0		: TEXCOORD0;
	float2 uv1		: TEXCOORD1;
#if defined(_TESSELLATION) || defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
	float2 uv2		: TEXCOORD2;
#endif
#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
	float2 uv3		: TEXCOORD3; // texture UV to object space ratio, quadratic curvature (along u, v)
#endif

#if defined(_TESSELLATION) || defined(_TANGENT_TO_WORLD)
	half4 tangent	: TANGENT;
#endif
	fixed4 color	: COLOR0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
};

#if defined(_TESSELLATION)

	float4 tessDistanceWithEdgeLimit (VertexInput v0, VertexInput v1, VertexInput v2) {
	
		// vertices in world space
		float3 wpos0 = mul(unity_ObjectToWorld,v0.vertex).xyz;
		float3 wpos1 = mul(unity_ObjectToWorld,v1.vertex).xyz;
		float3 wpos2 = mul(unity_ObjectToWorld,v2.vertex).xyz;
		
		// distance from edges center to camera
		float3 edgeDist = float3( distance(_WorldSpaceCameraPos, 0.5*(wpos1+wpos2)), distance(_WorldSpaceCameraPos, 0.5*(wpos0+wpos2)), distance(_WorldSpaceCameraPos, 0.5*(wpos0+wpos1)) );
		
		float4 tess;		
		float fadeLengthInv = 1.0/(maxDist - minDist);
		tess.xyz = clamp(1.0 - (edgeDist - minDist) * fadeLengthInv, 0.01, 1.0) * _Tess;
		
		// limit amount of tessellation by vertex color
		#if defined(VERTEX_COLOR_CHANNEL_TESELLATION_AMOUNT)
			tess.x = max(1, tess.x * 0.5*(v1.color.VERTEX_COLOR_CHANNEL_TESELLATION_AMOUNT+v2.color.VERTEX_COLOR_CHANNEL_TESELLATION_AMOUNT) );
			tess.y = max(1, tess.y * 0.5*(v0.color.VERTEX_COLOR_CHANNEL_TESELLATION_AMOUNT+v2.color.VERTEX_COLOR_CHANNEL_TESELLATION_AMOUNT) );
			tess.z = max(1, tess.z * 0.5*(v0.color.VERTEX_COLOR_CHANNEL_TESELLATION_AMOUNT+v1.color.VERTEX_COLOR_CHANNEL_TESELLATION_AMOUNT) );
		#endif
		
		// limit edge length in screen space
		float3 edgesLength = float3(distance(wpos1, wpos2), distance(wpos0, wpos2), distance(wpos0, wpos1));
		tess.xyz = min(edgesLength * _ScreenParams.y / (_TessEdgeLengthLimit * edgeDist), tess.xyz);		
		
		tess.w = dot(tess.xyz, 0.333333f);
		
		return tess;	
	}	
	
#endif

float4 TexCoords(VertexInput v)
{
	float4 texcoord;
	texcoord.xy = TRANSFORM_TEX(v.uv0, _MainTex); // Always source from uv0
	texcoord.zw = TRANSFORM_TEX(((_UVSec == 0) ? v.uv0 : v.uv1), _DetailAlbedoMap);
	return texcoord;
}		
float4 TexCoordsNoTransform(VertexInput v)
{
	float4 texcoord;
	texcoord.xy = v.uv0;
	texcoord.zw = v.uv1;
	return texcoord;
}		

half DetailMask(float2 uv, fixed4 vertex_color, float2 _ddx, float2 _ddy) // UBER - mask per vertex, ddx,ddy
{
	return tex2Dp( _DetailMask, uv*_DetailUVMult, _ddx*_DetailUVMult, _ddy*_DetailUVMult ).a*__VERTEX_COLOR_CHANNEL_DETAIL;
}

// helper to take value from _OcclusionMap (unconditionaly) - we need it for secondary occlusion
half2 OcclusionMap(float4 uv, float2 _ddx, float2 _ddy, float2 _ddxDet, float2 _ddyDet, fixed4 vertex_color) {
#if defined(_TWO_LAYERS)
	half4 occ = tex2Dp(_OcclusionMap, uv.xy, _ddx, _ddy);
	half4 occ2 = tex2Dp(_OcclusionMap, uv.zw, _ddxDet, _ddyDet);
	#if _METALLICGLOSSMAP
		return half2(lerp(occ.METALLIC_SETUP__AMBIENT_OCCLUSION_CHANNEL2, occ.METALLIC_SETUP__AMBIENT_OCCLUSION_CHANNEL, __VERTEX_COLOR_CHANNEL_LAYER), lerp(occ.METALLIC_SETUP__AUX_OCCLUSION_CHANNEL2, occ.METALLIC_SETUP__AUX_OCCLUSION_CHANNEL, __VERTEX_COLOR_CHANNEL_LAYER));
	#else
		return half2(lerp(occ.AMBIENT_OCCLUSION_CHANNEL2, occ.AMBIENT_OCCLUSION_CHANNEL, __VERTEX_COLOR_CHANNEL_LAYER), lerp(occ.AUX_OCCLUSION_CHANNEL2, occ.AUX_OCCLUSION_CHANNEL, __VERTEX_COLOR_CHANNEL_LAYER));
	#endif
	//		// no translucency_thickness nor glitter masking in 2 layers mode (would collide with regular occlusion for 2nd layer)
	//		return half2( _UVSecOcclusion == 1 ? occ.g : lerp(occ.b, occ.g, __VERTEX_COLOR_CHANNEL_LAYER), 1 );
#else
	half4 occ = tex2Dp(_OcclusionMap, uv.xy, _ddx, _ddy);
	#if _METALLICGLOSSMAP
		return half2(occ.METALLIC_SETUP__AMBIENT_OCCLUSION_CHANNEL, occ.METALLIC_SETUP__AUX_OCCLUSION_CHANNEL);
	#else
		return half2(occ.AMBIENT_OCCLUSION_CHANNEL, occ.AUX_OCCLUSION_CHANNEL);
	#endif
#endif
}

half3 Albedo(float4 texcoords, fixed4 vertex_color, half Wetness, float2 _ddx, float2 _ddy, float2 _ddxDet, float2 _ddyDet, inout half3 _emission, half blendFade, half3 diffuseTint, half3 diffuseTint2) // UBER - additional params
{
	half4 texColor=tex2Dp(_MainTex, texcoords.xy, _ddx, _ddy);
	#if defined(TRIPLANAR_SELECTIVE)
		half3 albedo = _Color.rgb * lerp( _MainTexAverageColor.rgb, texColor.rgb, saturate(blendFade+_MainTexAverageColor.a) );
	#else
		half3 albedo = _Color.rgb * texColor.rgb; 
	#endif
#if defined(_TWO_LAYERS)
	half4 texColor2=tex2Dp(_MainTex2, texcoords.zw, _ddxDet, _ddyDet);
	#if defined(TRIPLANAR_SELECTIVE)
		albedo = lerp(_Color2.rgb * lerp( _MainTex2AverageColor.rgb, texColor2.rgb, saturate(blendFade+_MainTex2AverageColor.a)), albedo, __VERTEX_COLOR_CHANNEL_LAYER);
	#else
		albedo = lerp(_Color2.rgb * texColor2.rgb, albedo, __VERTEX_COLOR_CHANNEL_LAYER);
	#endif
	// (might be used for vertex color masking below)
	texColor.a = lerp(texColor2.a, texColor.a, __VERTEX_COLOR_CHANNEL_LAYER);
#else
	// no detail in 2-layers mode
#if _DETAIL || defined(_DETAIL_SIMPLE)
	#if (SHADER_TARGET < 30)
		// SM20: instruction count limitation
		// SM20: no detail mask
		half mask = __VERTEX_COLOR_CHANNEL_DETAIL; // UBER - optional detail mask per vertex
	#else
		half mask = DetailMask((_UVSec == 2) ? texcoords.zw : texcoords.xy, vertex_color, _ddx, _ddy); // UBER - vertex color added
	#endif
	#if _DETAIL
		// textured
		half3 detailAlbedo = tex2Dp(_DetailAlbedoMap, texcoords.zw, _ddxDet, _ddyDet).rgb*_DetailColor.rgb;
	#else
		// simple - masked
		half3 detailAlbedo = _DetailColor.rgb;
	#endif


   	#if defined(_WETNESS)
		// detail emission for non opaque water only
		// (8x HDR on detail emission)
		_emission = detailAlbedo*_DetailEmissiveness*mask*8*(1-_WetnessColor.a*Wetness);
	#else
		_emission = detailAlbedo*_DetailEmissiveness*mask*8;
	#endif
#endif

#if defined(_DETAIL_SIMPLE)
	// simple masked - lerp
	albedo = lerp (albedo, detailAlbedo, mask*_DetailColor.a);
#elif _DETAIL		
	// textured
	#if defined(_DETAIL_MULX2)
		albedo *= LerpWhiteTo (detailAlbedo * unity_ColorSpaceDouble.rgb, mask*_DetailColor.a); // *_DetailColor.a means detail albedo opacity
	#elif defined(_DETAIL_MUL)
		albedo *= LerpWhiteTo (detailAlbedo, mask*_DetailColor.a);
	#elif defined(_DETAIL_ADD)
		albedo += detailAlbedo * mask*_DetailColor.a;
	#elif defined(_DETAIL_LERP)
		albedo = lerp (albedo, detailAlbedo, mask*_DetailColor.a);
	#endif
#endif
#if _DETAIL || defined(_DETAIL_SIMPLE)
//	albedo *= (1-_DetailEmissiveness*mask);
#endif

#endif // 2 layers

#if defined(VERTEX_COLOR_RGB_TO_ALBEDO)
	#if defined(DIFFUSE_ALPHA_MASKING)
		albedo *= lerp(1, vertex_color.rgb*2, texColor.a);
	#else
		albedo *= vertex_color.rgb*2;
	#endif
#endif

#if defined(VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED) && !_ALPHA
	albedo *= lerp( 1, diffuseTint.rgb * 2, OcclusionMap(texcoords, _ddx, _ddy, _ddxDet, _ddyDet, vertex_color).y );
#elif defined(VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED)
	half4 occ = tex2Dp(_OcclusionMap, texcoords.xy, _ddx, _ddy);
	albedo *= lerp(1, diffuseTint.rgb * 2, occ.AUX_OCCLUSION_CHANNEL);
	albedo *= lerp(1, diffuseTint2.rgb * 2, occ.AUX_OCCLUSION_CHANNEL2);
#endif

#if defined(_WETNESS)
	albedo=lerp(albedo, _WetnessColor.rgb, Wetness*_WetnessColor.a);
#endif

	return albedo;
}

// UBER - ddx,ddy added, vertex_color
half Alpha(float4 uv, float2 _ddx, float2 _ddy, float2 _ddxDet, float2 _ddyDet, fixed4 vertex_color)
{
#if defined(_TWO_LAYERS)
	return lerp(tex2Dp(_MainTex2, uv.zw, _ddxDet, _ddyDet).a * _Color2.a, tex2Dp(_MainTex, uv.xy, _ddx, _ddy).a * _Color.a, __VERTEX_COLOR_CHANNEL_LAYER);
#else
	return tex2Dp(_MainTex, uv.xy, _ddx, _ddy).a * _Color.a;
#endif	
}		

// UBER - derivatives added, returns regular occlusion and translucency occlusion
half2 Occlusion(float4 uv, float2 _ddx, float2 _ddy, float2 _ddxDet, float2 _ddyDet, fixed4 vertex_color)
{
	if (_Occlusion_from_albedo_alpha) { // uniform bool (float for sake of d3d9 compatibility)
		#if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
			return 1; // in transparency modes we can't use occlusion from albedo alpha
		#else
			half2 occ = tex2Dp(_MainTex, uv.xy, _ddx, _ddy).aa;
			#if defined(_TWO_LAYERS)		
				occ = lerp(tex2Dp(_MainTex2, uv.zw, _ddxDet, _ddyDet).aa, occ, __VERTEX_COLOR_CHANNEL_LAYER);
			#endif
			return _Smoothness_from_albedo_alpha ? 1 : occ;
		#endif
	}
	else
	{
		if (_Smoothness_from_albedo_alpha) { // uniform bool 
			return 1;
		} else {
			return OcclusionMap(uv, _ddx, _ddy, _ddxDet, _ddyDet, vertex_color);
		}
	}
}

half4 SpecularGloss(float4 uv, fixed4 vertex_color, float2 _ddx, float2 _ddy, float2 _ddxDet, float2 _ddyDet, half Wetness) // UBER - vertex_color, ddx, ddy, uv.xy - main uv, uv.zw - detail uv, wetness
{
	half4 sg;
#if defined(_TWO_LAYERS)	
	#if _SPECGLOSSMAP
		if (_Smoothness_from_albedo_alpha) { // uniform bool 
			sg = float4(1, 1, 1, tex2Dp(_MainTex, uv.xy, _ddx, _ddy).a)*_SpecColor;
			sg = lerp(float4(1, 1, 1, tex2Dp(_MainTex2, uv.zw, _ddxDet, _ddyDet).a)*_SpecColor2, sg, __VERTEX_COLOR_CHANNEL_LAYER);
		} else {
			sg = tex2Dp(_SpecGlossMap, uv.xy, _ddx, _ddy)*_SpecColor; // UBER - tinted spec/gloss
			sg = lerp(tex2Dp(_SpecGlossMap2, uv.zw, _ddxDet, _ddyDet)*_SpecColor2, sg, __VERTEX_COLOR_CHANNEL_LAYER);
		}
	#else
		// (this #if branch is never taken as we assume _SPECGLOSSMAP to be always defined)
		sg = lerp(half4(_SpecColor2.rgb, _Glossiness2), sg, __VERTEX_COLOR_CHANNEL_LAYER);
	#endif
#else
	#if _SPECGLOSSMAP
		if (_Smoothness_from_albedo_alpha) { // uniform bool 
			sg = float4(1, 1, 1, tex2Dp(_MainTex, uv.xy, _ddx, _ddy).a)*_SpecColor;
		} else {
			sg = tex2Dp(_SpecGlossMap, uv.xy, _ddx, _ddy)*_SpecColor; // UBER - tinted spec/gloss
		}
	#else
		// (this #if branch is never taken as we assume _SPECGLOSSMAP to be always defined)
		sg = half4(_SpecColor.rgb, _Glossiness);
	#endif
#endif

#if !defined(_TWO_LAYERS)
// UBER - detail spec/gloss
#if !defined(SHADER_API_MOBILE) && (SHADER_TARGET >= 30)
	#if _DETAIL || defined(_DETAIL_SIMPLE)
		half mask = DetailMask((_UVSec == 2) ? uv.zw : uv.xy, vertex_color, _ddx, _ddy); // UBER - detail mask per vertex
	#endif
	#if defined(_DETAIL_SIMPLE)
		// simple detail spec (masked only)
		sg = lerp(sg, _DetailSpecGloss, mask*_DetailColor.a*_DetailSpecLerp);
	#elif _DETAIL
	 	#if defined(_DETAIL_TEXTURED_WITH_SPEC_GLOSS)
			// textured detail - notice: no _DetailColor.a opacity applied here (detail specularity controlled by mask value only)
			half4 detailSpecGloss = tex2Dp(_SpecularRGBGlossADetail, uv.zw, _ddxDet, _ddyDet)*_DetailSpecGloss;
			sg = lerp(sg, detailSpecGloss, mask*_DetailSpecLerp);
	 	#else
			// textured detail, but w/o spec gloss - take it from detail albedo (A)
			half4 detailSpecGloss = half4(_DetailSpecGloss.rgb, tex2Dp(_DetailAlbedoMap, uv.zw, _ddxDet, _ddyDet).a*_DetailSpecGloss.a );
			sg = lerp(sg, detailSpecGloss, mask*_DetailSpecLerp);
	 	#endif
	#endif
#endif
#endif

// UBER - spec range when primary spec/gloss map is used or detail spec/gloss map is used
#if _SPECGLOSSMAP || ( _DETAIL )
	// (we assume this #if _SPECGLOSSMAP branch to be always defined)
	sg.a=lerp(_GlossMin, _GlossMax, sg.a);
#endif

	return sg;	
}

half2 MetallicGloss(float4 uv, fixed4 vertex_color, float2 _ddx, float2 _ddy, float2 _ddxDet, float2 _ddyDet, half Wetness) // UBER - vertex_color, uv.xy - main uv, uv.zw - detail uv
{
	half2 mg;
#if _METALLICGLOSSMAP
	#if defined(_TWO_LAYERS)	
		if (_Smoothness_from_albedo_alpha) { // uniform bool 
			mg = float2(1, tex2Dp(_MainTex, uv.xy, _ddx, _ddy).a);
			// UBER - "tinted" metalness/glossiness
			mg.x *= _Metallic;
			mg.y *= _Glossiness;
			mg = lerp(float2(1, tex2Dp(_MainTex2, uv.zw, _ddxDet, _ddyDet).a) * float2(_Metallic2, _Glossiness2), mg, __VERTEX_COLOR_CHANNEL_LAYER);
		} else {
			mg = tex2Dp(_MetallicGlossMap, uv.xy, _ddx, _ddy).ra;
			// UBER - "tinted" metalness/glossiness
			mg.x *= _Metallic;
			mg.y *= _Glossiness;
			mg = lerp(tex2Dp(_MetallicGlossMap2, uv.zw, _ddxDet, _ddyDet).ra * float2(_Metallic2, _Glossiness2), mg, __VERTEX_COLOR_CHANNEL_LAYER);
		}
	#else
		if (_Smoothness_from_albedo_alpha) { // uniform bool 
			mg = float2(1, tex2Dp(_MainTex, uv.xy, _ddx, _ddy).a);
		} else {
			mg = tex2Dp(_MetallicGlossMap, uv.xy, _ddx, _ddy).ra;
		}
		// UBER - "tinted" metalness/glossiness
		mg.x *= _Metallic;
		mg.y *= _Glossiness;
	#endif
#else
	// (this #if branch is never taken as we assume _SPECGLOSSMAP to be always defined)
	mg = half2(_Metallic, _Glossiness);
	#if defined(_TWO_LAYERS)
		mg = lerp(half2(_Metallic2, _Glossiness2), mg, __VERTEX_COLOR_CHANNEL_LAYER);
	#endif
#endif

#if !defined(_TWO_LAYERS)
// UBER - detail metallic/gloss
#if !defined(SHADER_API_MOBILE) && (SHADER_TARGET >= 30) 
	#if _DETAIL || defined(_DETAIL_SIMPLE)
		half mask = DetailMask((_UVSec == 2) ? uv.zw : uv.xy, vertex_color, _ddx, _ddy); // UBER - detail mask per vertex
	#endif
	#if defined(_DETAIL_SIMPLE)
		// simple detail spec (masked only)
		mg = lerp(mg, half2(_DetailMetalness, _DetailGloss), mask*_DetailColor.a*_DetailSpecLerp);
	#elif _DETAIL
	 	#if defined(_DETAIL_TEXTURED_WITH_SPEC_GLOSS)
			// textured detail - notice: no _DetailColor.a opacity applied here (detail specularity controlled by mask value only)
			half2 detailMetallicGloss = tex2Dp(_MetallicGlossMapDetail, uv.zw, _ddxDet, _ddyDet).ra;
			detailMetallicGloss.x*=_DetailMetalness;
			detailMetallicGloss.y*=_DetailGloss;
			mg = lerp(mg, detailMetallicGloss, mask*_DetailSpecLerp);
	 	#else
			// textured detail - notice: no _DetailColor.a opacity applied here (detail specularity controlled by mask value only)
			half2 detailMetallicGloss = tex2Dp(_MetallicGlossMapDetail, uv.zw, _ddxDet, _ddyDet).ra;
			detailMetallicGloss.x=_DetailMetalness;
			detailMetallicGloss.y=tex2Dp(_DetailAlbedoMap, uv.zw, _ddxDet, _ddyDet).a*_DetailGloss;
			mg = lerp(mg, detailMetallicGloss, mask*_DetailSpecLerp);
	 	#endif
	#endif
#endif
#endif

// UBER - spec range when primary spec/gloss map is used or detail spec/gloss map is used
#if _METALLICGLOSSMAP || ( _DETAIL )
	// (we assume this #if _METALLICGLOSSMAP branch to be always defined)
	mg.y=lerp(_GlossMin, _GlossMax, mg.y);
#endif
#if defined(_WETNESS)
	mg.x*=(1-Wetness); // we're adjusting specColor for wetness separately
#endif

	return mg;
}

half3 Emission(float4 uv, fixed4 vertex_color, float2 _ddx, float2 _ddy, half snowBlur) // UBER - vertex_color, uv.xy - main uv, uv.zw - detail uv, snowBlur bias
{
// UBER
#if defined(_EMISSION_ANIMATED)
    float2 emissionUV = uv.xy + _Time.y*_PanEmissionMask*float2( _PanUSpeed, _PanVSpeed );
//    #if defined(_SNOW)
//	    half3 eCol=tex2Dgrad(_EmissionMap, emissionUV, _ddx*snowBlur, _ddy*snowBlur).a * tex2Dgrad(_EmissionMap, uv.xy, _ddx*snowBlur, _ddy*snowBlur).rgb;
//    #else
	    half3 eCol=tex2Dp(_EmissionMap, emissionUV, _ddx, _ddy).a * tex2Dp(_EmissionMap, uv.xy, _ddx, _ddy).rgb;
//    #endif
	float pulsation=_PulsateEmission ? (_MinPulseBrightness + ( (sin((_Time.y*_EmissionPulsateSpeed)) + 1.0) * (1.0 - _MinPulseBrightness) ) / 2.0) : 1.0;

	return eCol.rgb * _EmissionColor.rgb * pulsation;
#elif defined(_EMISSION_TEXTURED)
//    #if defined(_SNOW)
//		return tex2Dgrad(_EmissionMap, uv.xy, _ddx*snowBlur, _ddy*snowBlur).rgb * _EmissionColor.rgb;
//	#else
		return tex2Dp(_EmissionMap, uv.xy, _ddx, _ddy).rgb * _EmissionColor.rgb;
//	#endif
#else
	return _EmissionColor.rgb; // UBER - we've got emission used - always (but can be zero in EmissionColor.rgb)
#endif
}

#if _NORMALMAP
#if defined(EXTRUSION_MAP)
half3 NormalInTangentSpace(half3 _normFromParallaxFunction, float4 texcoords, float2 uvDet_no_refr, half3 i_viewDirForParallax, half _snow_val_nobump, half3x3 tanToWorld, fixed4 vertex_color, float2 _ddx, float2 _ddy, float2 _ddxDet, float2 _ddyDet, float2 _ddxSnow, float2 _ddySnow, half3 wetNorm, half deepWetFct, inout half _snow_val, inout half dissolveMaskValue, half blendFade, float3 posWorld) // UBER - vertex_color, derivatives, wetNorm, deepWetFct
#else
half3 NormalInTangentSpace(float4 texcoords, float2 uvDet_no_refr, half3 i_viewDirForParallax, half _snow_val_nobump, half3x3 tanToWorld, fixed4 vertex_color, float2 _ddx, float2 _ddy, float2 _ddxDet, float2 _ddyDet, float2 _ddxSnow, float2 _ddySnow, half3 wetNorm, half deepWetFct, inout half _snow_val, inout half dissolveMaskValue, half blendFade, float3 posWorld) // UBER - vertex_color, derivatives, wetNorm, deepWetFct
#endif
{

#if defined(EXTRUSION_MAP) && !defined(_SNOW)
	// reuse normalmap - we don't need bumpTexValRegular variable
#else
	half4 bumpTexValRegular=tex2Dp(_BumpMap, texcoords.xy, _ddx, _ddy);
#endif
#if defined(_SNOW)
	#if defined(EXTRUSION_MAP) || defined(DISTANCE_MAP)
		// no snow smoothening with POM that has perpendicular sidewalls extruded
		#if defined(EXTRUSION_MAP)
			// reuse normalmap value calculated in parallax function
			half3 normalTangent = _normFromParallaxFunction;
		#else
			half3 normalTangent = UnpackScaleNormal(bumpTexValRegular, _BumpScale);
		#endif
	#else
	
		#if FIX_SUBSTANCE_BUG
			float4 BumpMap_TexelSize=bumpMapTexelSize;
		#else
			float4 BumpMap_TexelSize=_BumpMap_TexelSize;
		#endif
	
		float2 snwDDX = _ddx * BumpMap_TexelSize.zw;
		float2 snwDDY = _ddy * BumpMap_TexelSize.zw;
		float d = max( dot( snwDDX, snwDDX ), dot( snwDDY, snwDDY ) );
		float bumpMapMIP = max(_SnowDeepSmoothen, 0.5*log2(d));
		half4 bumpTexValSnow=tex2Dlod(_BumpMap, float4(texcoords.xy, bumpMapMIP.xx)); // regular normals under the snow won't have aniso filtering, but they are smoothen anyway in most cases

		#if defined(_TWO_LAYERS)
			bumpTexValRegular=lerp( tex2Dp(_BumpMap2, texcoords.zw, _ddxDet, _ddyDet), bumpTexValRegular, __VERTEX_COLOR_CHANNEL_LAYER );
			
			#if FIX_SUBSTANCE_BUG
				float4 BumpMap2_TexelSize=bumpMap2TexelSize;
			#else
				float4 BumpMap2_TexelSize=_BumpMap2_TexelSize;
			#endif
			
			snwDDX = _ddx * BumpMap2_TexelSize.zw;
			snwDDY = _ddy * BumpMap2_TexelSize.zw;
			d = max( dot( snwDDX, snwDDX ), dot( snwDDY, snwDDY ) );
			bumpMapMIP = max(_SnowDeepSmoothen, 0.5*log2(d));
			bumpTexValSnow=lerp( tex2Dlod(_BumpMap2, float4(texcoords.zw, bumpMapMIP.xx)), bumpTexValSnow, __VERTEX_COLOR_CHANNEL_LAYER ); // regular normals under the snow won't have aniso filtering, but they are smoothen anyway in most cases
		#endif

		half3 normalTangent = UnpackScaleNormal( lerp(bumpTexValRegular, bumpTexValSnow, saturate(_snow_val_nobump*2)), _BumpScale);
	#endif
	
	half3 normalTangentUnderSnow = UnpackScaleNormal( bumpTexValRegular, _BumpScale);
	half slope=exp2(-8*dot(normalTangentUnderSnow,float3(tanToWorld[0].y, tanToWorld[1].y, tanToWorld[2].y)));
	_snow_val=saturate(_snow_val_nobump-slope*_SnowSlopeDamp);
#else
	#if defined(_TWO_LAYERS)
		bumpTexValRegular = lerp( tex2Dp(_BumpMap2, texcoords.zw, _ddxDet, _ddyDet), bumpTexValRegular, __VERTEX_COLOR_CHANNEL_LAYER);
		half3 normalTangent = UnpackScaleNormal( bumpTexValRegular, lerp( _BumpScale2, _BumpScale, __VERTEX_COLOR_CHANNEL_LAYER) );
	#else
		#if defined(EXTRUSION_MAP)
			// reuse normalmap value calculated in parallax function
			half3 normalTangent = _normFromParallaxFunction;
		#else
			half3 normalTangent = UnpackScaleNormal(bumpTexValRegular, _BumpScale);
		#endif
	#endif
#endif

#if !defined(SHADER_API_MOBILE) && (SHADER_TARGET >= 30) && (BEND_NORMALS)
	float2 _sin=sin(texcoords.xy*_BendNormalsFreq);
	float2 _cos=cos(texcoords.xy*_BendNormalsFreq);
	normalTangent.x+=(_sin.x+_cos.y)*_BendNormalsStrength;
	normalTangent.y+=(_cos.x+_sin.y)*_BendNormalsStrength;	
#endif	

#if !defined(_TWO_LAYERS)
	// SM20: instruction count limitation
	// SM20: no detail normalmaps
#if _DETAIL && !defined(SHADER_API_MOBILE) && (SHADER_TARGET >= 30) 
	half mask = DetailMask((_UVSec == 2) ? texcoords.zw : texcoords.xy, vertex_color, _ddx, _ddy); // UBER - detail mask per vertex
	
	#if defined(_SNOW)
		half3 detailNormalTangent = UnpackScaleNormal(tex2Dp(_DetailNormalMap, texcoords.zw, _ddxDet, _ddyDet), _DetailNormalMapScale*(1-_snow_val));
	#else
		half3 detailNormalTangent = UnpackScaleNormal(tex2Dp(_DetailNormalMap, texcoords.zw, _ddxDet, _ddyDet), _DetailNormalMapScale);
	#endif
//	#if _DETAIL_LERP
//		normalTangent = lerp(
//			normalTangent,
//			detailNormalTangent,
//			mask);
//	#else				
		normalTangent = lerp(
			normalTangent,
			BlendNormals(lerp(normalTangent, half3(0,0,1), _DetailNormalLerp), detailNormalTangent), // UBER - _DetailNormalLerp
			mask);
//	#endif
#endif
#endif

//wetNorm = mul(tanToWorld, wetNorm.xzy);

#if defined(_SNOW)
	#if defined(_WETNESS)
		normalTangent = lerp(normalTangent, wetNorm, deepWetFct*_WetnessNormalInfluence*(1-_snow_val));
	#endif

	dissolveMaskValue=tex2Dgrad(_SparkleMap, uvDet_no_refr.xy*_SnowMicroTiling, _ddxSnow*_SnowMicroTiling, _ddySnow*_SnowMicroTiling).g;

	UNITY_BRANCH if (_SnowBumpMicro2Used == true) {
		dissolveMaskValue = lerp(dissolveMaskValue, tex2Dgrad(_SparkleMap, uvDet_no_refr.xy*_SnowMicroTiling2, _ddxSnow*_SnowMicroTiling2, _ddySnow*_SnowMicroTiling2).g, _SnowBumpMicro2*2);
		float dist = distance(_WorldSpaceCameraPos, posWorld);
		float distF = 1 - saturate(dist / 20.0);
		distF *= distF;
		distF *= distF;
		dissolveMaskValue = lerp(dissolveMaskValue*0.1 + 0.7, dissolveMaskValue, distF); // fade mid freq dissole mask to const to hide it's ugly patterns at distance
	}
	half dissolveMask=1.08-dissolveMaskValue;
	dissolveMask=lerp(0.15, dissolveMask, (_SnowDissolveFromGlobal ? _UBER_GlobalSnowDissolve : _SnowDissolve) );
	half sv=_snow_val*6>dissolveMask ? saturate(_snow_val*6-dissolveMask):0;

	// micro bumps
	half3 snowNormal;
	snowNormal.xy = tex2Dgrad(_SparkleMap, uvDet_no_refr.xy*_SnowMicroTiling, _ddxSnow*_SnowMicroTiling, _ddySnow*_SnowMicroTiling).ba*2-1;
	half microStrength = lerp(sv * 20 * dissolveMaskValue, 1, _snow_val);
	snowNormal.xy *= microStrength * (_SnowBumpMicroFromGlobal ? _UBER_GlobalSnowBumpMicro : _SnowBumpMicro);
	snowNormal.z = sqrt(1.0 - saturate(dot(snowNormal.xy, snowNormal.xy)));

	UNITY_BRANCH if (_SnowBumpMicro2Used == true) {
		half3 snowNormal2;
		snowNormal2.xy = tex2Dgrad(_SparkleMap, uvDet_no_refr.xy*_SnowMicroTiling2, _ddxSnow*_SnowMicroTiling2, _ddySnow*_SnowMicroTiling2).ba * 2 - 1;
		snowNormal2.xy *= _SnowBumpMicro2;
		snowNormal2.z = sqrt(1.0 - saturate(dot(snowNormal.xy, snowNormal.xy)));
		snowNormal = BlendNormals(snowNormal, snowNormal2);
	}

	// macro bumps
	snowNormal = BlendNormals( snowNormal, UnpackScaleNormal( tex2Dgrad(_RippleMap, uvDet_no_refr.xy*_SnowMacroTiling, _ddxSnow*_SnowMacroTiling, _ddySnow*_SnowMacroTiling), _snow_val*_SnowBumpMacro ) );
	_snow_val=sv;
	#if ENABLE_SNOW_WORLD_MAPPING
		snowNormal = _SnowWorldMapping ? mul(tanToWorld, snowNormal.xzy) : snowNormal; // bring snow normal to tan space when it was sampled in world space
		snowNormal = lerp(float3(0,0,1), snowNormal, _snow_val*(1-slope)); // bring snow normal to flat on slopes - would be stretched anyway
	#endif
	normalTangent = BlendNormals(normalTangent, snowNormal);
#else
	#if defined(_WETNESS)
		normalTangent = lerp(normalTangent, wetNorm, deepWetFct*_WetnessNormalInfluence);
	#endif
#endif

	return normalTangent;
}
#endif

#endif // UBER_STANDARD_INPUT_INCLUDED
