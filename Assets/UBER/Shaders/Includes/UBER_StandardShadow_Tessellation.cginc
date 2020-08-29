#ifndef UBER_STANDARD_SHADOW_TESSELLATION_INCLUDED
#define UBER_STANDARD_SHADOW_TESSELLATION_INCLUDED

// NOTE: had to split shadow functions into separate file,
// otherwise compiler gives trouble with LIGHTING_COORDS macro (in UnityStandardCore.cginc)


#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityInstancing.cginc"
#include "../UBER_StandardConfig.cginc"

// UBER - wetness state
#if !defined(_WETNESS_NONE) && (defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON))
	// we care about wetness only in transparent mode (opaque wetness), wetness doesn't influence object shape
	#define _WETNESS 1
#endif

#if !defined(DISTANCE_MAP) && (defined(_POM_DISTANCE_MAP) || defined(_POM_DISTANCE_MAP_ZWRITE) || defined(_POM_DISTANCE_MAP_SHADOWS))
	#define DISTANCE_MAP
#endif

#if !defined(EXTRUSION_MAP) && (defined(_POM_EXTRUSION_MAP) || defined(_POM_EXTRUSION_MAP_ZWRITE) || defined(_POM_EXTRUSION_MAP_SHADOWS))
	#define EXTRUSION_MAP
#endif

#if !defined(POM) && (defined(_PARALLAX_POM) || defined(_PARALLAX_POM_ZWRITE) || defined(_PARALLAX_POM_SHADOWS))
	#define POM
#endif

#if (defined(_PARALLAX_POM_ZWRITE) || defined(_POM_DISTANCE_MAP_ZWRITE) || defined(_POM_EXTRUSION_MAP_ZWRITE)) && !defined(ZWRITE)
	#define ZWRITE 1
#endif

#if !defined(TRIPLANAR) && (defined(TRIPLANAR_SELECTIVE))
 	#define TRIPLANAR
#endif

// Do dithering for alpha blended shadows on SM3+/desktop;
// on lesser systems do simple alpha-tested shadows
#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
	#if !((SHADER_TARGET < 30) || defined (SHADER_API_MOBILE) || defined(SHADER_API_GLES) || defined(SHADER_API_D3D11_9X) || defined (SHADER_API_PSP2) || defined (SHADER_API_PSM))
	#define UNITY_STANDARD_USE_DITHER_MASK 1
	#endif
#endif

#if !((SHADER_TARGET < 30) || defined (SHADER_API_MOBILE) || defined(SHADER_API_GLES) || defined(SHADER_API_D3D11_9X) || defined (SHADER_API_PSP2) || defined (SHADER_API_PSM))
	#define LOD_CROSSFADE_AVAILABLE 1
#endif

// Need to output UVs in shadow caster, since we need to sample texture and do clip/dithering based on it
#if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON) || defined(_TESSELLATION) || defined(_SNOW) || defined(ZWRITE)
#define UNITY_STANDARD_USE_SHADOW_UVS 1
#endif

// Has a non-empty shadow caster output struct (it's an error to have empty structs on some platforms...)
#if !defined(V2F_SHADOW_CASTER_NOPOS_IS_EMPTY) || defined(UNITY_STANDARD_USE_SHADOW_UVS)
#define UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT 1
#endif


half4		_Color;
half		_Cutoff;
sampler2D	_MainTex;
float4		_MainTex_ST;
#ifdef UNITY_STANDARD_USE_DITHER_MASK
sampler3D	_DitherMaskLOD;
#endif
		
struct VertexInput
{
	float4 vertex	: POSITION;
	float3 normal	: NORMAL;
	float2 uv0		: TEXCOORD0;
	#if defined(_TESSELLATION) || defined(_WETNESS) || defined(_SNOW) || defined(ZWRITE)
	float2 uv1		: TEXCOORD1;
	float4 tangent : TANGENT;
	#endif
	#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
	float2 uv3		: TEXCOORD3; // texture UV to object space ratio, quadratic curvature (along u, v)
	#endif	
	fixed4 color	: COLOR0;	
	UNITY_VERTEX_INPUT_INSTANCE_ID
};


float		_TessDepth;
float		_TessOffset;
float		_Tess;
float		_TessEdgeLengthLimit;
float		minDist;
float		maxDist;
float		_Phong;
float		_PhongStrength;

half		_Parallax;
sampler2D	_ParallaxMap;

#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
	float4		_ParallaxMap_TexelSize;
	float4		heightMapTexelSize;
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

#if defined(_PARALLAX_POM_SHADOWS)
// not actually used (self Shadowing function is not called here)
float		_ShadowStrength;
float		_DistStepsShadows;
float		_ShadowMIPbias;
float		_DepthReductionDistance;
float		_Softness;
float		_SoftnessFade;
#endif

half		_UVSec; // flag (detail from UV0/UV1 switch)
half		_UVSecOcclusion; // flag (occlusion from UV0/UV1 switch)
half		_UVSecOcclusionLightmapPacked; // flag ( !=0 apply lightmap UV transform for 2ndary occlusion taken from UV1)
//sampler2D	_DetailAlbedoMap;
float4		_DetailAlbedoMap_ST;
sampler2D	_RippleMap;

#if defined(_SNOW)
half		_UBER_GlobalSnowDamp;
//half		_UBER_GlobalBumpMicro;
//half4		_UBER_GlobalSnowSpecGloss;
//half4		_UBER_GlobalSnowGlitterColor;
half		_UBER_GlobalSnowDissolve;

bool		_SnowLevelFromGlobal;
//bool		_SnowBumpMicroFromGlobal;
//bool		_SnowDissolveFromGlobal;
//bool		_SnowSpecGlossFromGlobal;
//bool		_SnowGlitterColorFromGlobal;

half4		_SnowColorAndCoverage;
//half4		_SnowSpecGloss;
half		_SnowSlopeDamp;
//bool		_DiffuseScatter;
//half4		_SnowDiffuseScatteringColor;
//half		_SnowDiffuseScatteringExponent;
//half		_SnowDiffuseScatteringOffset;
half		_SnowDeepSmoothen;
//half3		 _SnowEmissionTransparency;

//half		_SnowMicroTiling;
half		_SnowMacroTiling;
//half		_SnowBumpMicro;
half		_SnowBumpMacro;
//float		_SnowWorldMapping;

//half		_SnowDissolve;
//half		_SnowDissolveMaskOcclusion;
//half4		_SnowTranslucencyColor;

half		_SnowHeightThreshold;
half		_SnowHeightThresholdTransition;

//sampler2D	_SparkleMap;
//float4		_SparkleMap_TexelSize;
#endif

#if defined(_SNOW) || defined(EXTRUSION_MAP)
// needed in extrusion mapping
sampler2D	_BumpMap;
float4		_BumpMap_TexelSize;
float4		bumpMapTexelSize;
half		_BumpScale;
#endif

#if defined(_TWO_LAYERS)
half4		_Color2;
sampler2D	_MainTex2;
sampler2D	_BumpMap2;
float4		_BumpMap2_TexelSize;
float4		bumpMap2TexelSize;
half		_BumpScale2;
//half4		_SpecColor2;
//sampler2D	_SpecGlossMap2;
//sampler2D	_MetallicGlossMap2;
//half		_Metallic2;
//half		_Glossiness2;
sampler2D	_ParallaxMap2;
half		_Parallax2;
//half		_OcclusionStrength2;
//half4		_DiffuseScatteringColor2;
//half4		_GlitterColor2;
//half4		_TranslucencyColor2;
#endif

// wetness
#if defined(_WETNESS)
half		_UBER_GlobalDry;

half		_WetnessLevel;
half4		_WetnessColor; // for opacity
half		_WetnessNormalInfluence; // for coverage
half		_WetnessUVMult; // for coverage
sampler2D	_DetailMask;

bool		_WetnessMergeWithSnowPerMaterial;
bool		_WetnessLevelFromGlobal;
//bool		_WetnessFlowGlobalTime;
#endif

// triplanar
#if defined(TRIPLANAR_SELECTIVE)
//half4		_MainTexAverageColor;
half		_TriplanarBlendSharpness;
//half		_TriplanarNormalBlendSharpness;
half		_TriplanarHeightmapBlendingValue;
//half		_TriplanarBlendAmbientOcclusion;
#endif

// used for zwrite and snow coverage
#define _TANGENT_TO_WORLD
#include "../Includes/UBER_StandardUtils2.cginc"

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

void SetupUBER(float4 i_SclCurv, half3 i_eyeVec, float3 i_posWorld, float3 i_posObject, inout float4 i_tex, inout half4 i_tangentToWorldAndParallax0, inout half4 i_tangentToWorldAndParallax1, inout half4 i_tangentToWorldAndParallax2, inout fixed4 vertex_color, out half actH, out float4 SclCurv, out half3 eyeVec, out float3 tangentBasisScaled, out float2 _ddx, out float2 _ddy, out float2 _ddxDet, out float2 _ddyDet, out float blendFade, out half3 i_viewDirForParallax, out half3x3 _TBN, out half3 worldNormal, out float4 texcoordsNoTransform) {
	
	// (out) compiled out when not used
	#if defined(GEOM_BLEND)
		actH=1; // for geom blend - default h is ceil value (but is supposed to be set later in parallax computation or triplanar init setup below)
	#else
		actH=0; // wetness
	#endif

	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			float3 normBlend=i_tex.xyz; // world normal
			float3 posUVZ=i_posWorld.xyz;
			float3 blendVal = abs(normBlend);
		#else
			float3 objScale=float3(i_tangentToWorldAndParallax0.w, i_tangentToWorldAndParallax1.w, i_tangentToWorldAndParallax2.w);
			float3 normObj=i_tex.xyz;
			float3 normBlend=normObj;
			float3 normObjScaled=normalize(normObj/objScale);
			float3 posUVZ=i_posObject.xyz*objScale;
			float3 blendVal = abs(normObjScaled);
		#endif
		float3 uvz = posUVZ.xyz*_MainTex_ST.xxx;
		half3 hVal = float3(tex2D(_ParallaxMap, (normBlend.x>0) ? uvz.zy : float2(-uvz.z,uvz.y)).PARALLAX_CHANNEL, tex2D(_ParallaxMap, (normBlend.y>0) ? uvz.xz : float2(-uvz.x,uvz.z)).PARALLAX_CHANNEL, tex2D(_ParallaxMap, (normBlend.z>0) ? uvz.yx : float2(-uvz.y,uvz.x)).PARALLAX_CHANNEL);
		#if defined(_TWO_LAYERS)
			float3 uvz2 = posUVZ.xyz*_DetailAlbedoMap_ST.xxx;
			#if defined(_PARALLAXMAP_2MAPS)
				half3 hVal2 = float3(tex2D(_ParallaxMap2, (normBlend.x>0) ? uvz2.zy : float2(-uvz2.z,uvz2.y)).PARALLAX_CHANNEL, tex2D(_ParallaxMap2, (normBlend.y>0) ? uvz2.xz : float2(-uvz2.x,uvz2.z)).PARALLAX_CHANNEL, tex2D(_ParallaxMap2, (normBlend.z>0) ? uvz2.yx : float2(-uvz2.y,uvz2.x)).PARALLAX_CHANNEL);
			#else
				half3 hVal2 = float3(tex2D(_ParallaxMap2, (normBlend.x>0) ? uvz2.zy : float2(-uvz2.z,uvz2.y)).PARALLAX_CHANNEL_2ND_LAYER, tex2D(_ParallaxMap2, (normBlend.y>0) ? uvz2.xz : float2(-uvz2.x,uvz2.z)).PARALLAX_CHANNEL_2ND_LAYER, tex2D(_ParallaxMap2, (normBlend.z>0) ? uvz2.yx : float2(-uvz2.y,uvz2.x)).PARALLAX_CHANNEL_2ND_LAYER);
			#endif
			hVal = lerp( hVal2, hVal, __VERTEX_COLOR_CHANNEL_LAYER);
		#endif
		
		blendVal += _TriplanarHeightmapBlendingValue*hVal;
		blendVal /= dot(blendVal,1);
		
		float maxXY = max(blendVal.x,blendVal.y);
		float3 tri_mask = (blendVal.x>blendVal.y) ? float3(1,0,0) : float3(0,1,0);
		tri_mask = (blendVal.z>maxXY) ? float3(0,0,1) : tri_mask;
		
		// inited here, reused in parallax function		
		#if defined(_TWO_LAYERS)
			// need to call GetH to set height blending between layers
			{
			float2 control=float2(__VERTEX_COLOR_CHANNEL_LAYER, 1-__VERTEX_COLOR_CHANNEL_LAYER);
			float2 hgt=float2(dot(hVal2, blendVal), dot(hVal, blendVal));
			control*=hgt+0.01;			// height evaluation
			control*=control; 			// compress
			control/=dot(control,1);	// normalize
			control*=control;			// compress
			control*=control;			// compress
			control/=dot(control,1);	// normalize
			
			__VERTEX_COLOR_CHANNEL_LAYER=control.x; // write blending value back into the right vertex_color channel variable
			actH = lerp(hgt.x, hgt.y, __VERTEX_COLOR_CHANNEL_LAYER);
			}
		#else
			actH = dot(hVal, blendVal);
		#endif
		
		blendVal.xy = blendVal.y > blendVal.x ? blendVal.yx : blendVal.xy;
		blendVal.yz = blendVal.z > blendVal.y ? blendVal.zy : blendVal.yz;
		blendVal.xy = blendVal.y > blendVal.x ? blendVal.yx : blendVal.xy;
		// now blendVal.x = max , blendVal.y = mid, blendVal.z = min from initial blendVal.xyz components
		blendFade = saturate( (blendVal.x-blendVal.y)/blendVal.x*_TriplanarBlendSharpness );
		
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			float3 tangent_flip = tri_mask * ((normBlend.xyz<0) ? float3(1,1,1) : float3(-1,-1,-1));
		#else
			float3 tangent_flip = tri_mask * ((normBlend.xyz>0) ? float3(1,1,1) : float3(-1,-1,-1));
		#endif
		i_tex.xy = float2(tangent_flip.x, tri_mask.x)*posUVZ.zy + float2(tangent_flip.y, tri_mask.y)*posUVZ.xz + float2(tangent_flip.z, tri_mask.z)*posUVZ.yx;
		i_tex.zw = i_tex.xy*_DetailAlbedoMap_ST.xx;
		i_tex.xy *= _MainTex_ST.xx;
		texcoordsNoTransform=0; // secondary occlusion, not used - we have no real texcoords and occlusion doesn't influence shadows
	#endif
	
	// UBER
	#if defined(TRIPLANAR_SELECTIVE)
		float3 _ddx3=ddx(uvz);
		_ddx = tri_mask.xx*_ddx3.zy + tri_mask.yy*_ddx3.xz + tri_mask.zz*_ddx3.yx;
		
		float3 _ddy3=ddy(uvz);
		_ddy = tri_mask.xx*_ddy3.zy + tri_mask.yy*_ddy3.xz + tri_mask.zz*_ddy3.yx;
		
		_ddxDet=_ddx/_MainTex_ST.xx*_DetailAlbedoMap_ST.xx;
		_ddyDet=_ddy/_MainTex_ST.xx*_DetailAlbedoMap_ST.xx;
	#endif	

	tangentBasisScaled=1; // not used

	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		SclCurv = 0; // not used
		eyeVec = i_posWorld.xyz - _WorldSpaceCameraPos; // will be normalized in FRAGMENT_SETUP()
	#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		eyeVec = i_posWorld.xyz - _WorldSpaceCameraPos; // will be normalized in FRAGMENT_SETUP()
		SclCurv = i_SclCurv;
	#else
		SclCurv = 0; // not used
		eyeVec = i_eyeVec;
	#endif

	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
		
			// TBN in world space
			worldNormal=normBlend; // world normal
			half3 _tangent=tri_mask.xxx*i_tangentToWorldAndParallax0.xyz + tri_mask.yyy*i_tangentToWorldAndParallax1.xyz + tri_mask.zzz*i_tangentToWorldAndParallax2.xyz;
			half3 _binormal=cross(worldNormal, _tangent);
			_TBN = half3x3(_tangent, _binormal, worldNormal);
			
			//eyeVec = normalize(i_eyeVec);
			eyeVec /= max(0.0000001, length(i_eyeVec)); // get rid of floating point div by zero warning
			#if defined(_PARALLAXMAP) || defined(_PARALLAXMAP_2MAPS)
				i_viewDirForParallax=mul(_TBN, eyeVec);
				i_viewDirForParallax.z=-i_viewDirForParallax.z;
			#else
				i_viewDirForParallax=half3(0,0,0);
			#endif
			
		#else
		
			half3 _normal=normObj;
			half3 _tangent=tri_mask.xxx*i_tangentToWorldAndParallax0.xyz + tri_mask.yyy*i_tangentToWorldAndParallax1.xyz + tri_mask.zzz*i_tangentToWorldAndParallax2.xyz;
			half3 _binormal=cross(_normal, _tangent);
			
			#if defined(_PARALLAXMAP) || defined(_PARALLAXMAP_2MAPS)
				// TBN in object space
				half3x3 rotation=half3x3(_tangent, -_binormal, _normal);
				i_viewDirForParallax=normalize( mul(rotation, ObjSpaceViewDir(float4(i_posObject,1)) ) );
			#else
				i_viewDirForParallax=half3(0,0,0);
			#endif
			// TBN in world space
			_normal = UnityObjectToWorldNormal(_normal);
			_binormal = UnityObjectToWorldNormal(_binormal);
			_tangent = cross(_normal, _binormal); // basis is orthonormalized
			
			_TBN = half3x3(_tangent, _binormal, _normal);
			worldNormal=_normal;
			
		#endif	
	#endif
}

#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
struct VertexOutputShadowCaster
{
	V2F_SHADOW_CASTER_NOPOS
	#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
		#if defined(TRIPLANAR_SELECTIVE)
			float4 tex : TEXCOORD1; // triplanar normal
		#else
			#if defined(_SNOW) || defined(_TWO_LAYERS)
				float4 tex : TEXCOORD1; // snow coverage depends on detail uv (tex.zw), 2nd layer has tiling from detail uv as well
			#else
				float2 tex : TEXCOORD1;
			#endif		
		#endif
		#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
			float4 SclCurv : TEXCOORD2;
		#endif		
		#if defined(ZWRITE) || defined(_SNOW) || defined(TRIPLANAR_SELECTIVE)
			// we need tangent calculations for POM with ZWRTIE and snow coverage (snow damping on slope)
			half4 tangentToWorldAndParallax0	: TEXCOORD3;	// [3x3:tangentToWorld | 1x3:viewDirForParallax] - note: tangents+obj scale in triplanar (tangents in world space when mapping in world space)
			half4 tangentToWorldAndParallax1	: TEXCOORD4;	// 3x3 matrix doesn't work here in GLSL optimizer...
			half4 tangentToWorldAndParallax2	: TEXCOORD5;
			float4 posWorld	: TEXCOORD6; // .w - eyeDepth, snow coverage depends on posWorld (.y) and normalWorld (snow damping on slope)
		#endif
		#if defined(TRIPLANAR_SELECTIVE)
			#if !defined(_TRIPLANAR_WORLD_MAPPING)
				float3 posObject : TEXCOORD7;
			#endif
		#endif
		#if defined(_SNOW) || defined(_WETNESS) || defined(_TWO_LAYERS) || defined(VERTEX_COLOR_CHANNEL_POMZ) || defined(TRIPLANAR_SELECTIVE)
			fixed4 vertex_color : COLOR0; // used for snow/wet coverage and 2 layers mode, volume initial position is also used
		#endif
		#if defined(SHADER_API_D3D9)
			float vpos_w:TEXCOORD8;
		#endif
	#endif
};
#endif



// We have to do these dances of outputting SV_POSITION separately from the vertex shader,
// and inputting VPOS in the pixel shader, since they both map to "POSITION" semantic on
// some platforms, and then things don't go well.


void vertShadowCaster (VertexInput v,
    #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
    out VertexOutputShadowCaster o,
    #endif
    #ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
    out VertexOutputStereoShadowCaster os,
    #endif
    out float4 opos : SV_POSITION)
{

	UNITY_SETUP_INSTANCE_ID(v);
    #ifdef UNITY_STANDARD_USE_STEREO_SHADOW_OUTPUT_STRUCT
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(os);
    #endif

	#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		float2 Curv=frac(v.uv3);
		float2 Scl=(v.uv3-Curv)/100; // scale represented with 0.01 resolution (fair enough)
		Scl=Scl*_Tan2ObjectMultOffset.xy+_Tan2ObjectMultOffset.zw;
		#if defined(VERTEX_COLOR_CHANNEL_POMZ)
			v.vertex.xyz+=_POM_ExtrudeVolume ? v.normal.xyz*v.color.VERTEX_COLOR_CHANNEL_POMZ*_Depth*max(Scl.x, Scl.y)/max(_MainTex_ST.x, _MainTex_ST.y) : float3(0,0,0);
			// Curv.x==0 - extruded bottom flag
			v.color.VERTEX_COLOR_CHANNEL_POMZ = Curv.x==0 || (!_POM_ExtrudeVolume) ? v.color.VERTEX_COLOR_CHANNEL_POMZ : 1-v.color.VERTEX_COLOR_CHANNEL_POMZ;
			//Curv=0; // no curvature on extruded volumes (we need bottom flag info in parallax function though - so DON'T zero Curv here !)
			// if we don't handle the volume set the curvature data to desired range
			Curv = _POM_ExtrudeVolume ? Curv : Curv*20-10;
		#else
			Curv=Curv*20-10; // Curv=(Curv-0.5)*10; // we assume curvature won't be higher than +/- 10
		#endif
	#endif

    #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
		o = (VertexOutputShadowCaster)0;
    #endif
	TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
	#if defined(UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT) && defined(UNITY_STANDARD_USE_SHADOW_UVS) && defined(SHADER_API_D3D9)
		o.vpos_w = opos.w; // missing component on d3d9
	#endif
	#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
	
		#if defined(_SNOW) || defined(_WETNESS) || defined(_TWO_LAYERS) || defined(VERTEX_COLOR_CHANNEL_POMZ)
			o.vertex_color = v.color;
		#endif		
		
		#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
			o.SclCurv=float4(float2(1.0,1.0)/Scl, Curv);
		#endif
			
		#if defined(ZWRITE) || defined(_SNOW) || defined(TRIPLANAR_SELECTIVE)
			o.posWorld = mul(unity_ObjectToWorld, v.vertex);
			#if defined(ZWRITE)
				COMPUTE_EYEDEPTH(o.posWorld.w);
			#endif
		#endif
			
		#if defined(TRIPLANAR_SELECTIVE)
			#if defined(_TRIPLANAR_WORLD_MAPPING)
				half3 normalWorld = UnityObjectToWorldNormal(v.normal);
				o.tangentToWorldAndParallax0.xyz = cross(normalWorld,cross(normalWorld, float3(0,0,1))); // tangents in world space
				o.tangentToWorldAndParallax0.xyz *= normalWorld.x<0 ? -1:1;
				o.tangentToWorldAndParallax1.xyz = cross(normalWorld,cross(normalWorld, float3(1,0,0)));
				o.tangentToWorldAndParallax1.xyz *= normalWorld.y<0 ? -1:1;
				o.tangentToWorldAndParallax2.xyz = cross(normalWorld,cross(normalWorld, float3(0,1,0)));
				o.tangentToWorldAndParallax2.xyz *= normalWorld.z>0 ? 1:-1;				
			#else
				half3 normalObject=v.normal;
				o.tangentToWorldAndParallax0.xyz = cross(normalObject, cross(normalObject, float3(0,0,1))); // tangents in obj space
				o.tangentToWorldAndParallax0.xyz *= normalObject.x<0 ? -1:1;
				o.tangentToWorldAndParallax1.xyz = cross(normalObject, cross(normalObject, float3(1,0,0)));
				o.tangentToWorldAndParallax1.xyz *= normalObject.y<0 ? -1:1;
				o.tangentToWorldAndParallax2.xyz = cross(normalObject, cross(normalObject, float3(0,1,0)));
				o.tangentToWorldAndParallax2.xyz *= normalObject.z>0 ? 1:-1;			
				
				float scaleX = length(float3(unity_ObjectToWorld[0][0], unity_ObjectToWorld[1][0], unity_ObjectToWorld[2][0]));
				float scaleY = length(float3(unity_ObjectToWorld[0][1], unity_ObjectToWorld[1][1], unity_ObjectToWorld[2][1]));
				float scaleZ = length(float3(unity_ObjectToWorld[0][2], unity_ObjectToWorld[1][2], unity_ObjectToWorld[2][2]));
				o.tangentToWorldAndParallax0.w = scaleX;
				o.tangentToWorldAndParallax1.w = scaleY;
				o.tangentToWorldAndParallax2.w = scaleZ;
				
				o.posObject.xyz = v.vertex.xyz;
			#endif			
		#else
			#if defined(ZWRITE) || defined(_SNOW)
				half3x3 tangentToWorld;
				#if defined(ZWRITE)
					float3 normalWorld = mul((float3x3)unity_ObjectToWorld, v.normal.xyz);
					float3 tangentWorld = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz);
					float3 binormalWorld = mul((float3x3)unity_ObjectToWorld, cross(v.normal.xyz, v.tangent.xyz)*v.tangent.w);
					#ifdef SHADER_TARGET_GLSL
					binormalWorld*=0.9999; // dummy op to cheat HLSL2GLSL optimizer to not be so smart (and buggy) here... It probably tries to make some fancy matrix by matrix calculation
					#endif
					// not normalized basis (we need it for texture 2 worldspace ratio calculations)
					tangentToWorld=half3x3(tangentWorld, binormalWorld, normalWorld);
				#else
					float3 normalWorld = UnityObjectToWorldNormal(v.normal);
					float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
					tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, v.tangent.w);
				#endif			
				o.tangentToWorldAndParallax0.xyz = tangentToWorld[0];
				o.tangentToWorldAndParallax1.xyz = tangentToWorld[1];
				o.tangentToWorldAndParallax2.xyz = tangentToWorld[2];
			
				#if defined(ZWRITE)					
					#if !defined(SILHOUETTE_CURVATURE_MAPPED)
						// vertex normal, tangent are not guaranteed to be normalized (!)
						// try - 2 simple planes on the scene using the same material, anchored and parent has decreased scale, Unity makes kind of batch (vertices seems to be transformed to world space) ? Anyway mesh tangents, normals get scaled, too and makes total mess with TBN matrices (view direction...)
						v.normal=normalize(v.normal);
						v.tangent.xyz=normalize(v.tangent.xyz);
						float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
						float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal );					
					#endif
					#if defined(SHADOWS_CUBE)
						// point light shadow caster
						#if (defined(POM)) && defined(SILHOUETTE_CURVATURE_MAPPED)
							half3 viewDirForParallax = ObjSpaceLightDir(v.vertex);
						#else
							half3 viewDirForParallax = mul (rotation, ObjSpaceLightDir(v.vertex));
						#endif					
					#elif defined(SHADOWS_DEPTH)
						// spot / directional light shadow caster
						#if (defined(POM)) && defined(SILHOUETTE_CURVATURE_MAPPED)
							half3 viewDirForParallax = ObjSpaceLightDir(v.vertex);
						#else
							half3 viewDirForParallax = mul (rotation, ObjSpaceLightDir(v.vertex));
						#endif					
						viewDirForParallax = (_WorldSpaceLightPos0.w!=0) ? viewDirForParallax : -viewDirForParallax;
						
						// regular depth (needed in forward)
						#if (defined(POM)) && defined(SILHOUETTE_CURVATURE_MAPPED)
							half3 viewDirForParallax_Depth = ObjSpaceViewDir(v.vertex);
						#else
							half3 viewDirForParallax_Depth = mul (rotation, ObjSpaceViewDir(v.vertex));
						#endif					
						
						// a bit insane method of detecting whether we're rendering from camera perspective or light for shadow depth...
						//float3 _ObjectSpaceCameraPos=mul(_World2Object, float4(_WorldSpaceCameraPos,1)).xyz;
						//bool isRenderingCameraDepth = abs(mul(UNITY_MATRIX_MVP, float4(_ObjectSpaceCameraPos,0)).z/mul(UNITY_MATRIX_MVP, float4(_ObjectSpaceCameraPos,0)).w-1)<0.001;
						bool isRenderingCameraDepth = dot(unity_LightShadowBias,1) == 0.0; // this works the same good but is simplier - thanks Aras :)
						viewDirForParallax = isRenderingCameraDepth ? viewDirForParallax_Depth : viewDirForParallax;
						o.posWorld.w=isRenderingCameraDepth ? -o.posWorld.w : o.posWorld.w; // transfer the flag value in eyedepth sign
					#endif
					o.tangentToWorldAndParallax0.w = viewDirForParallax.x;
					o.tangentToWorldAndParallax1.w = viewDirForParallax.y;
					o.tangentToWorldAndParallax2.w = viewDirForParallax.z;									
				#else
					o.tangentToWorldAndParallax0.w = 0;
					o.tangentToWorldAndParallax1.w = 0;
					o.tangentToWorldAndParallax2.w = 0;
				#endif
			#endif		
		#endif
		
		#if defined(TRIPLANAR_SELECTIVE)
			#if defined(_TRIPLANAR_WORLD_MAPPING)
				o.tex = float4(normalWorld,0);
			#else
				o.tex = float4(v.normal,0);
			#endif
		#else
			o.tex.xy = TRANSFORM_TEX(v.uv0, _MainTex);
			#if defined(_SNOW) || defined(_TWO_LAYERS)
				#if defined(_TESSELLATION) || defined(_WETNESS) || defined(_SNOW) || defined(ZWRITE)
					o.tex.zw = TRANSFORM_TEX(((_UVSec == 0) ? v.uv0 : v.uv1), _DetailAlbedoMap);
				#else
					o.tex.zw = TRANSFORM_TEX(v.uv0, _DetailAlbedoMap);
				#endif
			#endif
		#endif		
				
	#endif

}

#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
half4 shadowOutputHelper(VertexOutputShadowCaster i, float rayLength) {
#if defined(SHADOWS_CUBE) && !defined(SHADOWS_CUBE_IN_DEPTH_TEX)
	// Rendering into point light (cubemap) shadows
	return UnityEncodeCubeShadowDepth((length(i.vec) + rayLength + unity_LightShadowBias.x) * _LightPositionRange.w);
#else
	SHADOW_CASTER_FRAGMENT(i)
#endif
}
#endif

#if !defined(DEPTH_SEMANTIC)
	#if defined(SHADER_API_D3D11) && (SHADER_TARGET>=50) && CONSERVATIVE_DEPTH_WRITE
		#define DEPTH_SEMANTIC SV_DepthGreaterEqual
	#else
		#define DEPTH_SEMANTIC SV_Depth
	#endif
#endif

void fragShadowCaster (
	out float4 output : SV_Target,
	#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
	VertexOutputShadowCaster i,
	#endif
	#if defined (ZWRITE) && (!defined(SHADOWS_CUBE) || defined(SHADOWS_CUBE_IN_DEPTH_TEX))
	out float outDepth : DEPTH_SEMANTIC,
	#endif	
	UNITY_POSITION(vpos)
	)
{

	//#if defined(UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT) && defined(UNITY_STANDARD_USE_SHADOW_UVS)
	//#if defined(LOD_FADE_CROSSFADE) && defined(LOD_CROSSFADE_AVAILABLE)
	//	#if defined(SHADER_API_D3D9)
	//		half3 ditherScreenPos = half3(vpos.xy, i.vpos_w);
	//	#else
	//		half3 ditherScreenPos = vpos.xyw;
	//	#endif
	//	ditherScreenPos.xy *= _ScreenParams.xy * 0.25;
	//	half2 projUV = ditherScreenPos.xy / ditherScreenPos.z;
	//	projUV.y = frac(projUV.y) * 0.0625 /* 1/16 */ + unity_LODFade.y; // quantized lod fade by 16 levels
	//	clip(tex2D(_DitherMaskLOD2D, projUV).a - 0.5);
	//#endif
	//#endif


	output = 0.5;
	#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
	
		// compiled out when variables not used
		half rayLength=0;
		float4 rayPos=0;
		float2 texture2ObjectRatio=0;
		half _snow_val_nobump=0;
	
		#if defined(TRIPLANAR_SELECTIVE)
			// compiled out when not used
			half actH;
			float4 SclCurv;
			half3 eyeVec;
			
			float3 tangentBasisScaled;
			
			float2 _ddx;
			float2 _ddy;
			float2 _ddxDet;
			float2 _ddyDet;
			half blendFade;
			
			half3 i_viewDirForParallax;
			half3x3 _TBN;
			half3 worldNormal;
			
			float4 texcoordsNoTransform;
			
			half4 i_tangentToWorldAndParallax0;
			half4 i_tangentToWorldAndParallax1;
			half4 i_tangentToWorldAndParallax2;
			i_tangentToWorldAndParallax0=i.tangentToWorldAndParallax0;
			i_tangentToWorldAndParallax1=i.tangentToWorldAndParallax1;
			i_tangentToWorldAndParallax2=i.tangentToWorldAndParallax2;
			
			// void	SetupUBER(float4 i_SclCurv, half3 i_eyeVec, float3 i_posWorld, float3 i_posObject, inout float4 i_tex, inout half4 i_tangentToWorldAndParallax0, inout half4 i_tangentToWorldAndParallax1, inout half4 i_tangentToWorldAndParallax2, inout fixed4 vertex_color, out half actH, out float4 SclCurv, out half3 eyeVec, out float3 tangentBasisScaled, out float2 _ddx, out float2 _ddy, out float2 _ddxDet, out float2 _ddyDet, out float blendFade, out half3 i_viewDirForParallax, out half3x3 _TBN, out half3 worldNormal) {
			#if defined(_TRIPLANAR_WORLD_MAPPING)
				SetupUBER(float4(0,0,0,0), half3(0,0,0), i.posWorld.xyz, float3(0,0,0), /* inout */ i.tex, /* inout */ i_tangentToWorldAndParallax0, /* inout */ i_tangentToWorldAndParallax1, /* inout */ i_tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
			#else
				SetupUBER(float4(0,0,0,0), half3(0,0,0), i.posWorld.xyz, i.posObject, /* inout */ i.tex, /* inout */ i_tangentToWorldAndParallax0, /* inout */ i_tangentToWorldAndParallax1, /* inout */ i_tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
			#endif
		
		#else
			// compiled out when not used
			half actH=0;
			float2 _ddx=ddx(i.tex.xy);
			float2 _ddy=ddy(i.tex.xy);
			half blendFade=0;
			#if defined(ZWRITE)
				float3 tangentBasisScaled=float3(length(i.tangentToWorldAndParallax0.xyz), length(i.tangentToWorldAndParallax1.xyz), length(i.tangentToWorldAndParallax2.xyz));
				i.tangentToWorldAndParallax0.xyz/=tangentBasisScaled.x; // here we can normalize it
				i.tangentToWorldAndParallax1.xyz/=tangentBasisScaled.y;
				i.tangentToWorldAndParallax2.xyz/=tangentBasisScaled.z;
			#else
				float3 tangentBasisScaled=1; // not used
			#endif
		#endif
		
		#if defined(_SNOW) || defined(_WETNESS) || defined(_TWO_LAYERS) || defined(VERTEX_COLOR_CHANNEL_POMZ)
			fixed4 vertex_color = i.vertex_color;
		#else
			fixed4 vertex_color = 1;
		#endif	
		
		#if defined(ZWRITE) || defined(_SNOW)
			#if defined(TRIPLANAR_SELECTIVE)
				half3 i_normalWorld=worldNormal;
			#else
				half3 i_normalWorld=i.tangentToWorldAndParallax2.xyz;
			#endif
		#endif
		
		#if defined(_SNOW)
			half _snow_val = _SnowColorAndCoverage.a*__VERTEX_COLOR_CHANNEL_SNOW;
			_snow_val *= saturate((i.posWorld.y-_SnowHeightThreshold)/_SnowHeightThresholdTransition);
			_snow_val_nobump = saturate( _snow_val - (1-i_normalWorld.y)*_SnowSlopeDamp );
			
			half snowMaskLargeScale=tex2D(_RippleMap, i.posWorld.xz*SNOW_LARGE_MASK_TILING).g*0.6;
			_snow_val_nobump -= lerp(snowMaskLargeScale, 0, _snow_val_nobump);
			_snow_val_nobump = saturate(_snow_val_nobump);
			half _snow_val_nobump_per_material=_snow_val_nobump; // used later for wet coverage with snow (melting snow)
			_snow_val_nobump *= _SnowLevelFromGlobal ? (1-_UBER_GlobalSnowDamp) : 1;
			_snow_val = _snow_val_nobump;
		#endif	
		
		#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
			float4 SclCurv = i.SclCurv;
		#else
			#if defined(TRIPLANAR_SELECTIVE)
				// SclCurv already inited (not used anyway)
			#else
				float4 SclCurv = 0; // not used
			#endif
		#endif		
		
		#if defined(ZWRITE) || defined(_SNOW)
			//using array failed here in GLSL optimizer...
			//ExtractTangentToWorldPerPixel(i.tangentToWorldAndParallax);
			#if defined(TRIPLANAR_SELECTIVE)
				half3x3 i_tan2World=_TBN; // already inited
			#else
				half3x3 i_tan2World=half3x3(i.tangentToWorldAndParallax0.xyz, i.tangentToWorldAndParallax1.xyz, i.tangentToWorldAndParallax2.xyz);
			#endif
		#endif

		#if defined(ZWRITE)
			half3 i_viewDirForParallax=normalize(half3(i.tangentToWorldAndParallax0.w,i.tangentToWorldAndParallax1.w,i.tangentToWorldAndParallax2.w));
			
			#if defined(DISTANCE_MAP)
				half3 _norm=0; // set in function below but not used later in this depth/shadow pass
				i.tex.xy = ParallaxPOMDistance(i.tex.xyxy, i_viewDirForParallax, i.posWorld.xyz, vertex_color, _ddx, _ddy, _snow_val_nobump, /* inout */ actH, /* inout */ rayPos, /* inout */ texture2ObjectRatio, /* inout */ rayLength, tangentBasisScaled, SclCurv, _norm).xy;
			#elif defined(EXTRUSION_MAP)
				half3 _norm=0; // set in function below but not used later in this depth/shadow pass
				i.tex.xy = ParallaxPOMExtrusion(i.tex.xyxy, i_viewDirForParallax, i.posWorld.xyz, vertex_color, _ddx, _ddy, _snow_val_nobump, /* inout */ actH, /* inout */ rayPos, /* inout */ texture2ObjectRatio, /* inout */ rayLength, tangentBasisScaled, SclCurv, _norm).xy;
			#else
				i.tex.xy=Parallax(i.tex.xyxy, /* inout */ i_viewDirForParallax, /* inout */ i_tan2World, i.posWorld.xyz, /* inout */ vertex_color, _ddx, _ddy, _snow_val_nobump, /* inout */ actH, /* inout */ rayPos, /* inout */ texture2ObjectRatio, /* inout */ rayLength, tangentBasisScaled, SclCurv, blendFade).xy;
			#endif			
		#elif defined(_TESSELLATION) && defined(_WETNESS)
			// we need only actH for wetness
			#if defined(TRIPLANAR_SELECTIVE)
				// i_viewDirForParallax already inited (not used anyway)
				i_viewDirForParallax=0;
			#else
				float3 i_viewDirForParallax=0; // n/u
			#endif
			#if !defined(_SNOW)
				half3x3 i_tan2World=0; // n/u
			#endif
			i.tex.xy=Parallax(i.tex.xyxy, i_viewDirForParallax, i_tan2World, 0, /* inout */ vertex_color, 0, 0, 0, /* inout */ actH, /* inout */ rayPos, /* inout */ texture2ObjectRatio, /* inout */ rayLength, 0, 0, blendFade).xy;
		#endif
				
		// alpha (may be modified below by opaque wetness and snow coverage)
		#if defined(_TWO_LAYERS)
			half alpha = lerp( tex2D(_MainTex2, i.tex.zw).a * _Color2.a, tex2D(_MainTex, i.tex.xy).a * _Color.a, __VERTEX_COLOR_CHANNEL_LAYER);
		#else
			half alpha = tex2D(_MainTex, i.tex.xy).a * _Color.a;
		#endif			
		
		
		#if defined(_WETNESS)
			float3 wetNorm=float3(0,0,1); 
			half Wetness = 0;
			#if defined(_TWO_LAYERS)
				half wetMask=0; // no detail mask available
			#else
				half wetMask=0.1-tex2D(_DetailMask, i.tex.xy*_WetnessUVMult).r*0.1;
			#endif
			#if defined(_SNOW)
				half additionalWetDamp=_WetnessMergeWithSnowPerMaterial ? _snow_val_nobump_per_material : 1;
			#else
				half additionalWetDamp=1;
			#endif			
			Wetness=saturate( (__VERTEX_COLOR_CHANNEL_WETNESS*additionalWetDamp*_WetnessLevel*(_WetnessLevelFromGlobal ? (1-_UBER_GlobalDry) : 1)-actH-wetMask) * 4 );
			#if defined(_SNOW)
				// snow override wetness
				Wetness*=saturate(1-_snow_val*2);
			#endif	
		#endif		
			
		#if defined(_SNOW) && _NORMALMAP
			half4 bumpTexValRegular=tex2D(_BumpMap, i.tex.xy);
			
			#if FIX_SUBSTANCE_BUG
				float4 BumpMap_TexelSize=bumpMapTexelSize;
			#else
				float4 BumpMap_TexelSize=_BumpMap_TexelSize;
			#endif
			
			float2 snwDDX = _ddx * BumpMap_TexelSize.zw;
			float2 snwDDY = _ddy * BumpMap_TexelSize.zw;
			float d = max( dot( snwDDX, snwDDX ), dot( snwDDY, snwDDY ) );
			float bumpMapMIP = max(_SnowDeepSmoothen, 0.5*log2(d));
			half4 bumpTexValSnow=tex2Dlod(_BumpMap, float4(i.tex.xy, bumpMapMIP.xx)); // regular normals under the snow won't have aniso filtering, but they are smoothen anyway in most cases
			
			#if defined(_TWO_LAYERS)
				bumpTexValRegular=lerp( tex2D(_BumpMap2, i.tex.xy), bumpTexValRegular, __VERTEX_COLOR_CHANNEL_LAYER );
				
				#if FIX_SUBSTANCE_BUG
					float4 BumpMap2_TexelSize=bumpMap2TexelSize;
				#else
					float4 BumpMap2_TexelSize=_BumpMap2_TexelSize;
				#endif
		
				snwDDX = _ddx * BumpMap2_TexelSize.zw;
				snwDDY = _ddy * BumpMap2_TexelSize.zw;
				d = max( dot( snwDDX, snwDDX ), dot( snwDDY, snwDDY ) );
				bumpMapMIP = max(_SnowDeepSmoothen, 0.5*log2(d));
				bumpTexValSnow=lerp( tex2Dlod(_BumpMap2, float4(i.tex.xy, bumpMapMIP.xx)), bumpTexValSnow, __VERTEX_COLOR_CHANNEL_LAYER ); // regular normals under the snow won't have aniso filtering, but they are smoothen anyway in most cases
			#endif

			half3 normalTangent = UnpackScaleNormal( lerp(bumpTexValRegular, bumpTexValSnow, _snow_val_nobump), _BumpScale);
			
			half3 normalTangentUnderSnow = UnpackScaleNormal( bumpTexValRegular, _BumpScale);
			half slope=exp2(-8*dot(normalTangentUnderSnow,float3(i_tan2World[0].y, i_tan2World[1].y, i_tan2World[2].y)));
			_snow_val=saturate(_snow_val_nobump-slope*_SnowSlopeDamp);			
		
			//half dissolveMaskValue=tex2D(_SparkleMap, i.tex.zw*_SnowMicroTiling).g;
			//half dissolveMask=1.08-dissolveMaskValue;
			//dissolveMask=lerp(0.15, dissolveMask, _SnowDissolve);
			half dissolveMask=0.15; // no dissolve on shadow (would effect on transparency and snow coverage, but that's no problem in most cases)
			_snow_val=_snow_val*6>dissolveMask ? saturate(_snow_val*6-dissolveMask):0;			
		#endif

		#if defined(_SNOW)
			alpha=lerp(alpha, 1, _snow_val);
		#endif	
		#if defined(_WETNESS)
			alpha=lerp(alpha, 1, Wetness*_WetnessColor.a);
		#endif			
		
		#if defined(_ALPHATEST_ON)
			clip (alpha - _Cutoff);
		#endif
		#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
			#if defined(UNITY_STANDARD_USE_DITHER_MASK)
				// Use dither mask for alpha blended shadows, based on pixel position xy
				// and alpha level. Our dither texture is 4x4x16.
                #ifdef LOD_FADE_CROSSFADE
                    #define _LOD_FADE_ON_ALPHA
                    alpha *= unity_LODFade.y;
                #endif
				half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25,alpha*0.9375)).a;
				clip (alphaRef - 0.01);
			#else
				clip (alpha - _Cutoff);
			#endif
		#endif
	#endif // #if defined(UNITY_STANDARD_USE_SHADOW_UVS)

	#if defined(UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT) && defined(UNITY_STANDARD_USE_SHADOW_UVS)
		#ifdef LOD_FADE_CROSSFADE
			#ifdef _LOD_FADE_ON_ALPHA
				#undef _LOD_FADE_ON_ALPHA
			#else
				UnityApplyDitherCrossFade(vpos.xy);
			#endif
		#endif
	#endif


	#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
		// used for point lights (depth value encoded into float cube texture)
		// (rayLength + constant bias added)
		#if defined(ZWRITE)
			output=shadowOutputHelper(i, rayLength);
		#else
			output=shadowOutputHelper(i, 0);
		#endif
	#endif
	#if defined (ZWRITE)
		#if defined(SHADOWS_CUBE)
			//
			//shader part not currently used on tested platforms (DX9, OGL desktop) - for point light it's casted to the cube texture above)
			//	
			// point light shadow caster 
			//float depthWithOffset = length(i.vec)+rayLength;
			//
			//// _ZBufferParams are unreliable here, we need to derive them manually here
			//float m_FarClip=_ProjectionParams.z;
			//float m_NearClip=0.01; // blind guess (_ProjectionParams.y is not reliable and seems to be not valid here)
			//float zc0 = 1.0 - m_FarClip / m_NearClip;
			//float zc1 = m_FarClip / m_NearClip;
			//float2 _ZBufferParams_lightCamera=float2(zc0, zc1)*_ProjectionParams.w;
			//outDepth = (1.0 - depthWithOffset * _ZBufferParams_lightCamera.y) / (depthWithOffset * _ZBufferParams_lightCamera.x);	
		#elif defined(SHADOWS_DEPTH)
			// spot / directional switch
			half3 lDir = (_WorldSpaceLightPos0.w!=0) ? normalize(i.posWorld.xyz-_WorldSpaceLightPos0.xyz) : _WorldSpaceLightPos0.xyz;
			float3 wPos=i.posWorld.xyz+rayLength*lDir;
			float4 clipPos = mul(UNITY_MATRIX_VP, float4(wPos,1));
			clipPos = UnityApplyLinearShadowBias(clipPos);
			float outDepthShadowCaster = clipPos.z/clipPos.w;
			#if defined(SHADER_API_OPENGL) || defined(SHADER_API_GLCORE) || defined(SHADER_API_GLES3)
				outDepthShadowCaster=outDepthShadowCaster*0.5+0.5; // in openGL calculated value range is -1..1 - we need to map it to 0..1 (Aras, you're black pearl in shader industry)
			#endif

			// regular depth (needed in forward)
			//float depthWithOffset = abs(i.posWorld.w)+rayLength;
			float depthWithOffset = abs(i.posWorld.w)*(1+rayLength/distance(i.posWorld.xyz, _WorldSpaceCameraPos)); // Z-DEPTH perspective correction
			float outDepthCamera = (1.0 - depthWithOffset * _ZBufferParams.w) / (depthWithOffset * _ZBufferParams.z);			
			
			bool isRenderingCameraDepth = i.posWorld.w<0;

			outDepth = isRenderingCameraDepth ? outDepthCamera : outDepthShadowCaster;
		#endif	
	#endif
}			

// ------------------------------------------------------------------------------------
//
// pierceable depth pass
//
half _Mode; // BlendMode
struct v2fPierceable {
	float4 pos : SV_POSITION;
	float2 depth : TEXCOORD0;
};


v2fPierceable vertPierceable(
						appdata_base v
						) {
	v2fPierceable o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.depth = o.pos.zw;
	return o;
}

float4 fragPierceable(v2fPierceable i) : SV_Target {
	return (_Mode<2 ? 1:-1) * (i.depth.x / i.depth.y); // mark depth as negative for transparent (forward) objects
}
// ------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------
//
// tessellation
//
#if defined(_TESSELLATION) && defined(UNITY_CAN_COMPILE_TESSELLATION)

	struct UnityTessellationFactors {
	    float edge[3] : SV_TessFactor;
	    float inside : SV_InsideTessFactor;
	};

	// tessellation vertex shader
	struct InternalTessInterp_appdata {
	  float4 vertex : INTERNALTESSPOS;
	  float3 normal : NORMAL;
	  #if !defined(TRIPLANAR_SELECTIVE)	  
	  float2 uv0 : TEXCOORD0;
	  #endif
	  #if defined(_TESSELLATION) || defined(_WETNESS) || defined(_SNOW) || defined(ZWRITE)
	  		float2 uv1 : TEXCOORD1;
	  		#if !defined(TRIPLANAR_SELECTIVE)	  		
	  		float4 tangent : TANGENT;
	  		#endif
	  #endif	 
	  float4 color : COLOR;	 
	  #if defined(UNITY_SUPPORT_INSTANCING) && defined(INSTANCING_ON)
		uint instanceID : TEXCOORD2;
	  #endif
	};
	InternalTessInterp_appdata tessvert_surf (VertexInput v) {
	  InternalTessInterp_appdata o;
	  o.vertex = v.vertex;
	  o.normal = v.normal;
	  #if !defined(TRIPLANAR_SELECTIVE)
	  o.uv0 = v.uv0;
	  #endif
	  o.color = v.color;	
  	  #if defined(_TESSELLATION) || defined(_WETNESS) || defined(_SNOW) || defined(ZWRITE)
		o.uv1 = v.uv1;
		#if !defined(TRIPLANAR_SELECTIVE)
		o.tangent=v.tangent;
		#endif
	  #endif	
	  UNITY_TRANSFER_INSTANCE_ID(v, o);
	  return o;
	}

	// tessellation hull constant shader
	UnityTessellationFactors hsconst_surf (InputPatch<InternalTessInterp_appdata,3> v) {
	  UnityTessellationFactors o;
	  float4 tf;
	  VertexInput vi[3];
	  vi[0].vertex = v[0].vertex;
	  vi[0].normal = v[0].normal;
 	  #if !defined(TRIPLANAR_SELECTIVE)
	  vi[0].uv0 = v[0].uv0;
	  #endif
	  vi[0].color = v[0].color;	
  		#if defined(_TESSELLATION) || defined(_WETNESS) || defined(_SNOW) || defined(ZWRITE)
		  vi[0].uv1 = v[0].uv1;
		  #if !defined(TRIPLANAR_SELECTIVE)		  
		  vi[0].tangent = v[0].tangent;
		  #endif
		#endif
	  vi[1].vertex = v[1].vertex;
	  vi[1].normal = v[1].normal;
 	  #if !defined(TRIPLANAR_SELECTIVE)
	  vi[1].uv0 = v[1].uv0;
	  #endif
	  vi[1].color = v[1].color;
  		#if defined(_TESSELLATION) || defined(_WETNESS) || defined(_SNOW) || defined(ZWRITE)
		  vi[1].uv1 = v[1].uv1;
		  #if !defined(TRIPLANAR_SELECTIVE)		  
		  vi[1].tangent = v[1].tangent;
		  #endif
		#endif
	  vi[2].vertex = v[2].vertex;
	  vi[2].normal = v[2].normal;
 	  #if !defined(TRIPLANAR_SELECTIVE)
	  vi[2].uv0 = v[2].uv0;
	  #endif
	  vi[2].color = v[2].color;
  	  #if defined(_TESSELLATION) || defined(_WETNESS) || defined(_SNOW) || defined(ZWRITE)
		vi[2].uv1 = v[2].uv1;
		#if !defined(TRIPLANAR_SELECTIVE)		  
		vi[2].tangent = v[2].tangent;
		#endif
	  #endif
	  UNITY_TRANSFER_INSTANCE_ID(v[0], vi[0]); // v[0].instanceID is actually the same as v[1].instanceID and v[2].instanceID (uniform for whole mesh)
	  UNITY_TRANSFER_INSTANCE_ID(v[1], vi[1]);
	  UNITY_TRANSFER_INSTANCE_ID(v[2], vi[2]);
	  tf = tessDistanceWithEdgeLimit(vi[0], vi[1], vi[2]);
	  o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
	  return o;
	}

	// tessellation hull shader
	[UNITY_domain("tri")]
	[UNITY_partitioning("fractional_odd")]
	[UNITY_outputtopology("triangle_cw")]
	[UNITY_patchconstantfunc("hsconst_surf")]
	[UNITY_outputcontrolpoints(3)]
	InternalTessInterp_appdata hs_surf (InputPatch<InternalTessInterp_appdata,3> v, uint id : SV_OutputControlPointID) {
	  return v[id];
	}
	
	// tessellation domain shader
	[UNITY_domain("tri")]
	void ds_surf (UnityTessellationFactors tessFactors, const OutputPatch<InternalTessInterp_appdata,3> vi, float3 bary : SV_DomainLocation, 
					#if defined(PIERCEABLE_DEPTH)
						out v2fPierceable o)
					#else
						#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
						out VertexOutputShadowCaster o,
						#endif
						out float4 opos : SV_POSITION)
					#endif
	{
	VertexInput v;
	v.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
	v.normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
	#if !defined(TRIPLANAR_SELECTIVE)		  
		v.uv0 = vi[0].uv0*bary.x + vi[1].uv0*bary.y + vi[2].uv0*bary.z;
	#endif
	v.color = vi[0].color*bary.x + vi[1].color*bary.y + vi[2].color*bary.z;	  
	#if defined(_TESSELLATION) || defined(_WETNESS) || defined(_SNOW) || defined(ZWRITE)
		v.uv1 = vi[0].uv1*bary.x + vi[1].uv1*bary.y + vi[2].uv1*bary.z;
		#if !defined(TRIPLANAR_SELECTIVE)		  
			v.tangent = vi[0].tangent*bary.x + vi[1].tangent*bary.y + vi[2].tangent*bary.z;	  
		#endif
	#endif
	UNITY_TRANSFER_INSTANCE_ID(vi[0], v); // all vi[n] has the same instanceID transferred

	//
	// compute displacement
	//
	#if defined(_TESSELLATION_DISPLACEMENT)
		fixed4 vertex_color=v.color;
		float3 normalWorld = UnityObjectToWorldNormal(v.normal);
		
		float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
		
		#if defined(_SNOW)
			half _snow_val = _SnowColorAndCoverage.a*__VERTEX_COLOR_CHANNEL_SNOW;
			_snow_val *= saturate((posWorld.y-_SnowHeightThreshold)/_SnowHeightThresholdTransition);
			_snow_val = saturate( _snow_val - (1-normalWorld.y)*_SnowSlopeDamp );
			_snow_val *= _SnowLevelFromGlobal ? (1-_UBER_GlobalSnowDamp) : 1;
		#endif
	  
		float d=0; // displacement value
		#if defined(TRIPLANAR_SELECTIVE)
			#if defined(_TRIPLANAR_WORLD_MAPPING)
				float3 normBlend=normalWorld;
				float3 posUVZ=posWorld.xyz;
				float3 blendVal = abs(normBlend);
			#else
				float scaleX = length(float3(unity_ObjectToWorld[0][0], unity_ObjectToWorld[1][0], unity_ObjectToWorld[2][0]));
				float scaleY = length(float3(unity_ObjectToWorld[0][1], unity_ObjectToWorld[1][1], unity_ObjectToWorld[2][1]));
				float scaleZ = length(float3(unity_ObjectToWorld[0][2], unity_ObjectToWorld[1][2], unity_ObjectToWorld[2][2]));
				
				float3 objScale=float3(scaleX, scaleY, scaleZ);
				float3 normObj=v.normal;
				float3 normBlend=normObj;
				float3 normObjScaled=normalize(normObj/objScale);
				float3 posUVZ=v.vertex.xyz*objScale;
				float3 blendVal = abs(normObjScaled);
			#endif	
			
			#if defined(_SNOW)
				float level=_SnowDeepSmoothen*saturate(_snow_val-0.3);
			#else
				float level=0;
			#endif
						
			float3 uvz = posUVZ.xyz*_MainTex_ST.xxx;
			half3 hVal = float3(tex2Dlod(_ParallaxMap, (normBlend.x>0) ? float4(uvz.zy, level.xx) : float4(-uvz.z,uvz.y, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap, (normBlend.y>0) ? float4(uvz.xz, level.xx) : float4(-uvz.x,uvz.z, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap, (normBlend.z>0) ? float4(uvz.yx, level.xx) : float4(-uvz.y,uvz.x, level.xx)).PARALLAX_CHANNEL);
			#if defined(_TWO_LAYERS)
				float3 uvz2 = posUVZ.xyz*_DetailAlbedoMap_ST.xxx;
				#if defined(_PARALLAXMAP_2MAPS)
					half3 hVal2 = float3(tex2Dlod(_ParallaxMap2, (normBlend.x>0) ? float4(uvz2.zy, level.xx) : float4(-uvz2.z,uvz2.y, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap2, (normBlend.y>0) ? float4(uvz2.xz, level.xx) : float4(-uvz2.x,uvz2.z, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap2, (normBlend.z>0) ? float4(uvz2.yx, level.xx) : float4(-uvz2.y,uvz2.x, level.xx)).PARALLAX_CHANNEL);
				#else
					half3 hVal2 = float3(tex2Dlod(_ParallaxMap2, (normBlend.x>0) ? float4(uvz2.zy, level.xx) : float4(-uvz2.z,uvz2.y, level.xx)).PARALLAX_CHANNEL_2ND_LAYER, tex2Dlod(_ParallaxMap2, (normBlend.y>0) ? float4(uvz2.xz, level.xx) : float4(-uvz2.x,uvz2.z, level.xx)).PARALLAX_CHANNEL_2ND_LAYER, tex2Dlod(_ParallaxMap2, (normBlend.z>0) ? float4(uvz2.yx, level.xx) : float4(-uvz2.y,uvz2.x, level.xx)).PARALLAX_CHANNEL_2ND_LAYER);
				#endif
				hVal = lerp( hVal2, hVal, __VERTEX_COLOR_CHANNEL_LAYER);
			#endif
			
			blendVal += _TriplanarHeightmapBlendingValue*hVal;
			blendVal /= dot(blendVal,1);
			blendVal*=blendVal;
			blendVal*=blendVal;
			blendVal /= dot(blendVal,1);
			
			#if defined(_TWO_LAYERS)
				// need to call GetH to set height blending between layers
				{
				float2 control=float2(__VERTEX_COLOR_CHANNEL_LAYER, 1-__VERTEX_COLOR_CHANNEL_LAYER);
				float2 hgt=float2(dot(hVal2, blendVal), dot(hVal, blendVal));
				control*=hgt+0.01;			// height evaluation
				control*=control; 			// compress
				control/=dot(control,1);	// normalize
				// no more compression to get smoother cross layer displacement blend
//				control*=control;			// compress
//				control*=control;			// compress
//				control/=dot(control,1);	// normalize
				
				__VERTEX_COLOR_CHANNEL_LAYER=control.x; // write blending value back into the right vertex_color channel variable
				d = lerp(hgt.x, hgt.y, __VERTEX_COLOR_CHANNEL_LAYER);
				}
			#else
				d = dot(hVal, blendVal);
			#endif
			
		#else
			float4 texcoords;
			texcoords.xy=TRANSFORM_TEX(v.uv0, _MainTex);
			texcoords.zw=TRANSFORM_TEX(((_UVSec == 0) ? v.uv0 : v.uv1), _DetailAlbedoMap);
			#if defined(_SNOW)
				d=GetH(vertex_color, texcoords, true, _SnowDeepSmoothen*saturate(_snow_val-0.3)); // true - we're sampling tex2Dlod in per vertex on the _SnowDeepSmoothen*_snow_val level
			#else
				d=GetH(vertex_color, texcoords, true, 0);
			#endif
		#endif
	  
	  #if defined(_SNOW)
			d = saturate( d + saturate(_snow_val-0.7)*0.05*_SnowDeepSmoothen); // TODO - this offset should be calculated a lot more precise (on the surface normal level and in worldspace, because now it's object scale dependent)
	  #endif	  
	  
	  #if defined(DISPLACE_IN_TEXTURE_UNITS)	  
	  	float approxTan2ObjectRatio=distance(vi[1].vertex, vi[0].vertex) / distance(TRANSFORM_TEX(vi[0].uv0, _MainTex), TRANSFORM_TEX(vi[1].uv0, _MainTex));
	  #else
	  	float approxTan2ObjectRatio=1;
	  #endif
	  d = d - _TessOffset;
	  #if defined(GEOM_BLEND)
		d = lerp(d, 0, vertex_color.VERTEX_COLOR_CHANNEL_GEOM_BLEND);
	  #endif
  	  #if defined(VERTEX_COLOR_CHANNEL_TESELLATION_DISPLACEMENT_AMOUNT)
	  	d = lerp(0, d, vertex_color.VERTEX_COLOR_CHANNEL_TESELLATION_DISPLACEMENT_AMOUNT);
	  #endif
	  d *= saturate( 1.0 - (distance(_WorldSpaceCameraPos,posWorld)-minDist) / (maxDist - minDist) );

	// displacement
	#endif  
	
	if (_Phong) {
		float3 pp[3];
		for (int i = 0; i < 3; ++i)
		pp[i] = v.vertex.xyz - vi[i].normal * (dot(v.vertex.xyz, vi[i].normal) - dot(vi[i].vertex.xyz, vi[i].normal));
		v.vertex.xyz = _Phong * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-_Phong) * v.vertex.xyz;	  	  
	}
	  	  
	#if defined(_TESSELLATION_DISPLACEMENT)
	  v.vertex.xyz += v.normal * d * _TessDepth * approxTan2ObjectRatio;
	#endif	  

//	  v2f_struct o = VERT_SURF(v);
//	  return o;
#if defined(PIERCEABLE_DEPTH)
	  o.pos = UnityObjectToClipPos(v.vertex);
	  o.depth = o.pos.zw;
#else
	  vertShadowCaster(v,
		#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
		o,
		#endif
		opos);	  
#endif
	}

#endif // TESSELLATION

#endif // UBER_STANDARD_SHADOW_TESSELLATION_INCLUDED
