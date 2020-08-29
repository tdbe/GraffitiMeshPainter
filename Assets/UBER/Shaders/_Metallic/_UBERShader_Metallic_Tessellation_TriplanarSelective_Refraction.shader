Shader "UBER - Metallic Setup/Tessellation/Refraction/Triplanar Selective"
{
	Properties
	{
		[HDR] _Color("Color", Color) = (1,1,1,1)
		[HDR] _Color2("Color2", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_MainTex2("Albedo2", 2D) = "white" {}

		[Enum(Hide Layers A and B,0, Show Layer A,1, Show Layer B,2, Show all decals,3)]_DecalMaskGUI("Decal mask (GUI)", Float) = 3
		_DecalMask("Decal Mask", Float) = 1 // 0, 0.3, 0.8, 1 
		[NoKeywordToggle] _Pierceable("Pierceable", Float) = 0		
		
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		_CutoffEdgeGlow("Edge glow", Color) = (0,0,0,0.02)

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 1.0
		_Glossiness2("Smoothness2", Range(0.0, 1.0)) = 1.0
		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 1.0
		[Gamma] _Metallic2("Metallic2", Range(0.0, 1.0)) = 1.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_MetallicGlossMap2("Metallic2", 2D) = "white" {}
		
		_BumpScale("Scale", Float) = 1.0
		_BumpScale2("Scale2", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpMap2("Normal Map2", 2D) = "bump" {}

		_Parallax ("Height Scale", Range (0.0, 0.2)) = 0.04
		_Parallax2 ("Height Scale2", Range (0.0, 0.2)) = 0.04
		_ParallaxMap ("Height Map", 2D) = "black" {}
		_ParallaxMap2 ("Height Map2", 2D) = "black" {}

		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 0
		_OcclusionStrength2("Strength2", Range(0.0, 1.0)) = 0
		_SecOcclusionStrength("Strength (secondary)", Range (0.0, 1.0)) = 0
		_OcclusionMap("Occlusion", 2D) = "white" {}

		_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		
		_DetailMask("Detail Mask", 2D) = "white" {}

		_DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
		_DetailNormalMapScale("Scale", Float) = 1.0
		_DetailNormalMap("Normal Map", 2D) = "bump" {}

		[Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0
		[Enum(UV0,0,UV1,1)] _UVSecOcclusion ("UV Set for occlusion", Float) = 0
		[NoKeywordToggle] _UVSecOcclusionLightmapPacked ("2ndary occlusion from UV1 - apply lightmap transform", Float) = 0

		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
		
		//
		// UBER
		//
		_DiffuseScatter("Diffuse Scatter", Float) = 1
		_DiffuseScatteringColor("Diffuse scattering", Color) = (0,0,0,0)
        _DiffuseScatteringColor2 ("Diffuse scattering2", Color) = (0,0,0,0)
		_DiffuseScatteringExponent("Diffuse scattering exponent", Range(2,20)) = 8
		_DiffuseScatteringOffset("Diffuse scattering offset", Range(-0.5,0.5)) = 0
		_GlossMin("Gloss Min", Range(0,1)) = 0
		_GlossMax("Gloss Max", Range(0,1)) = 1
		
		// bend normals
		_BendNormalsFreq("Bend normals frequency", Float) = 4
		_BendNormalsStrength("Bend normals strangth", Range(0,0.2)) = 0.05

		// detail		
		_DetailUVMult("Detail mask tiling mult", Float) = 1
		_DetailNormalLerp("Detail normalmap override", Range(0,1)) = 0
		
        _DetailColor ("Tint (RGB+A - opacity)", Color) = (1,1,1,1)
        _DetailEmissiveness ("Detail emissiveness", Range(0,1)) = 0
        // spec setup
        _SpecularRGBGlossADetail ("Specular(RGB) Gloss(A)", 2D) = "white" {}
        _DetailSpecLerp ("Spec/Gloss override", Range(0,1)) = 1
        _DetailSpecGloss ("Spec/gloss Tint (RGB,A)", Color) = (1,1,1,1)
        // metal setup
        _MetallicGlossMapDetail ("Metallic(R) Gloss(A)", 2D) = "white" {}
        _DetailMetalness ("Detail metallic", Range(0,1)) = 1
        _DetailGloss ("Detail smoothness", Range(0,1)) = 1
        
        
        // emission (animated)
        [NoKeywordToggle] _PanEmissionMask ("Pan Emission Mask", Float ) = 0 
        _PanUSpeed ("   Pan U Speed", Float ) = 0
        _PanVSpeed ("   Pan V Speed", Float ) = 0
        [NoKeywordToggle] _PulsateEmission ("Pulsate Emission", Float ) = 0
        _EmissionPulsateSpeed ("   Emission Pulsate Frequency", Float ) = 0 
        _MinPulseBrightness ("   Min Pulse Brightness", Range(0, 1)) = 0        
        
        // translucency
        [NoKeywordToggle] _Translucency ("Translucency", Float ) = 0 
		[Foldout] _TranslucencyShown ("", Float) = 1                
        _TranslucencyColor ("Translucency color", Color) = (1,1,1,1)
        _TranslucencyColor2 ("Translucency color2", Color) = (1,1,1,1)
        _TranslucencyStrength ("Translucency strength", Float) = 4
        _TranslucencyPointLightDirectionality ("Point lights directionality", Range(0,1)) = 0.7
        _TranslucencyConstant ("Translucency constant", Range(0,0.5)) = 0.1
        _TranslucencyNormalOffset ("Translucency normal offset", Range(0, 0.3)) = 0.05
        _TranslucencyExponent ("Translucency exponent", Range(2,100)) = 30
        _TranslucencyOcclusion ("Translucency occlusion", Range(0,1)) = 0
        _TranslucencySuppressRealtimeShadows ("Translucency shadows suppression", Range(0,20)) = 0.5
		_TranslucencyNDotL ("Translucency NdotL", Range(0,1)) = 0
		  [Enum(Translucency Setup 1, 0, Translucency Setup 2, 1, Translucency Setup 3, 2, Translucency Setup 4, 3)] _TranslucencyDeferredLightIndex ("Translucency deferred light index", Float) = 0
        
        // POM
        [NoKeywordToggle] _POM ("POM", Float) = 0
		[Foldout] _POMShown ("", Float) = 1        
		[NoKeywordToggle] _DepthWrite ("Zwrite", Float) = 0
        _Depth ("Depth", Range(0.001, 2) ) = 0.1
        _DistSteps ("Max relief steps", Float) = 64
        _ReliefMIPbias ("Relief MIP offset", Range(0,2)) = 0

        _ObjectNormalsTex ("Object normals tex", 2D) = "grey" {}
        _ObjectTangentsTex ("Object tangents tex", 2D) = "grey" {}
        _CurvatureMultOffset ("Curvature", Vector) = (1,1,0,0)
        _Tan2ObjectMultOffset ("Tex2Object", Vector) = (1,1,0,0)
		_UV_Clip_Borders ("UV clip borders", Vector) = (0,0,1,1)
		_POM_BottomCut ("Bottom cut value", Range(0,1)) = 0
		[NoKeywordToggle] _POM_MeshIsVolume ("Depth per vertex", Float) = 0
		[NoKeywordToggle] _POM_ExtrudeVolume ("Extruded mesh", Float) = 0
        // UI props
        [NoKeywordToggle] _POMPrecomputedFlag ("POM precomputed", Float) = 0
		[Enum(Basic,0,Mapped,1)] _POMCurvatureType ("Type of curvature mapping", Float) = 0
		_DepthReductionDistance ("Depth reduction distance", Range(1,100)) = 20
        _CurvatureCustomU ("Curvature custom U", Float) = 0
        _CurvatureCustomV ("Curvature custom V", Float) = 0
        _CurvatureMultU ("Curvature mult U", Float) = 1
        _CurvatureMultV ("Curvature mult V", Float) = 1
        _Tan2ObjCustomU ("Tex U to Object space", Float) = 1
        _Tan2ObjCustomV ("Tex V to Object space", Float) = 1
        _Tan2ObjMultU ("Tex U to Object space mult", Float) = 1
        _Tan2ObjMultV ("Tex V to Object space mult", Float) = 1
        [NoKeywordToggle] _UV_Clip ("UV Clip", Float) = 0
        
        [NoKeywordToggle] _POMShadows ("Self-shadowing", Float) = 0
        _ShadowStrength ("   Self-shadow strength", Range(0,1)) = 1
        _DistStepsShadows ("   Max shadow steps", Float) = 64
        _ShadowMIPbias ("   Shadow MIP offset", Range(0,2)) = 0
        _Softness ("   Softness", Range(6,0)) = 2
        _SoftnessFade ("   Softness fade", Range(0.2,1.5)) = 0.4        
        
        // refraction
        _Refraction ("Refration", Range(0,0.5)) = 0.02
        _RefractionBumpScale ("Refraction bump scale", Range(0,2)) = 0.5
        _RefractionChromaticAberration ("Chromatic Aberration", Range(0,0.1)) = 0
        
        // wetness
        [NoKeywordToggle] _Wetness ("Wetness", Float) = 0
		[Foldout] _WetnessShown ("", Float) = 1        
        // you can control wetness globally by setting Shader.SetGlobalFloat("_UBER_GlobalDry", val); (val=1 means full dry - depends also on _WetnessLevelFromGlobal)
        _WetnessLevel ("Level (Height Map dependent)", Range(0,1.25) ) = 1
		_WetnessConst ("Const (Height Map independent)", Range(0,1) ) = 0
        _WetnessColor ("Wetness Color (RGB Tint, A Opacity)", Color) = (0,0,0,0)
		_WetnessDarkening ("Wetness darkening", Range(0,8)) = 2
        _WetnessSpecGloss ("Wetness Specular (RGB) Gloss (A)", Color) = (0.05,0.05,0.05,0.7)
        _WetnessEmissiveness ("Wetness emissiveness", Range(0,20)) = 0
        _WetnessNormalInfluence ("Wetness normal override", Range(0,1)) = 0.5
        _WetnessUVMult ("Wetness - Detail mask tiling",  Float) = 1
        
        // shared with snow macro bumps
        _RippleMap ("Ripple Map", 2D) = "bump" {}
        
        [NoKeywordToggle]_WetRipples ("Ripples (vertex color B)", Float ) = 0
        _RippleMapWet ("Ripple Map wet (UI)", 2D) = "bump" {} // UI only prop
        _RippleStrength ("Strength", Range(0.01,2)) = 0.5
        _RippleTiling ("Tiling", Float) = 1
        _RippleSpecFilter ("Spec filtering", Float) = 0.02
        _RippleAnimSpeed ("Anim speed", Float) = 0.5
        _FlowCycleScale ("Cycle scale", Float) = 2
        _RippleRefraction ("Refraction", Range(0, 2)) = 0.3   
             
        _WetnessNormMIP ("Flow normal MIP level", Range(1,8)) = 5
        _WetnessNormStrength ("Flow normal strength", Range(0,4)) = 2
        [NoKeywordToggle] _WetnessEmissivenessWrap  ("Emissiveness normal wrap", Float) = 0
        [NoKeywordToggle] _WetnessLevelFromGlobal  ("Water level controlled globally", Float) = 0
		[NoKeywordToggle] _WetnessConstFromGlobal  ("Water const controlled globally", Float) = 0
        [NoKeywordToggle] _WetnessFlowGlobalTime  ("Water flow global time", Float) = 1
		  [NoKeywordToggle] _WetnessMergeWithSnowPerMaterial ("Water level from snow level (per material)", Float) = 0
		[NoKeywordToggle] _RippleStrengthFromGlobal ("Flow ripple normal strength controlled globally", Float) = 0
		[NoKeywordToggle] _RainIntensityFromGlobal ("Rain Intensity controlled globally (multiplied)", Float) = 0
             
         [NoKeywordToggle]_WetDroplets ("Droplets (vertex color B)", Float ) = 0
        _DropletsMap ("Droplets Map", 2D) = "bump" {}
        // you can control rain globally by setting Shader.SetGlobalFloat("_UBER_GlobalRainDamp", val); (val=1 means no rain)
        _RainIntensity ("Rain Intensity", Range(0,1)) = 1
        _DropletsTiling ("Tiling", Float) = 1
        _DropletsAnimSpeed ("Anim speed", Float) = 10
		[NoKeywordToggle] _RainIntensityFromGlobal ("Rain Intensity controlled globally (multiplied)", Float) = 0
        
        // tessellation
        _TessDepth ("Depth", Float ) = 0.05
        _TessOffset ("Offset", Range(0,1) ) = 0.1
        _Tess ("Tessellation", Range(1,60)) = 9
		  _TessEdgeLengthLimit ("Tessellation edge limit", Range(2,50)) = 5
        minDist ("Min camera disance", Float) = 1.0
        maxDist ("Max camera disance", Float) = 10.0
        _Phong ("Phong", Range(0,1)) = 0.0
       
        // snow
        [NoKeywordToggle] _Snow ("Snow", Float) = 0
		[Foldout] _SnowShown ("", Float) = 1
        _RippleMapSnow ("Ripple Map snow (UI)", 2D) = "bump" {} // UI only prop
        // you can control wetness globally by setting Shader.SetGlobalFloat("_UBER_GlobalSnowDamp", val); (val=1 means no snow)
        _SnowColorAndCoverage ("Color (RGB Tint, A Level)", Color) = (1,1,1,1)
		_Frost ("Frost", Range(0,1)) = 0
        _SnowSpecGloss ("Specular (RGB) Gloss (A)", Color) = (0.1,0.1,0.1, 0.15)
        _SnowSlopeDamp ("Slope damp", Range(0,6)) = 2
        _SnowDiffuseScatteringColor ("Diffuse scattering", Color) = (1,1,1,0)
		_SnowDiffuseScatteringExponent("Diffuse scattering exponent", Range(2,20)) = 6
		_SnowDiffuseScatteringOffset("Diffuse scattering offset", Range(-0.5,0.5)) = 0.4
        _SnowDeepSmoothen ("Deep smoothen", Range(0,8)) = 4
        _SparkleMapSnow ("Snow detail (UI)", 2D) = "black" {} // UI only prop - shared with glitter feature
        _SnowEmissionTransparency ("Snow emission transparency", Color) = (0.1,0.1,0.1)
        
		_SnowMicroTiling ("Micro tiling", Float) = 4
		_SnowBumpMicro ("  Bumps micro", Range(0.001, 0.2)) = 0.08
		_SnowMacroTiling ("Macro tiling", Float) = 1
		_SnowBumpMacro ("  Bumps macro", Range(0.001, 0.5)) = 0.1
		[NoKeywordToggle] _SnowWorldMapping ("Snow World mapping", Float) = 0

		_SnowDissolve ("Dissolve", Range(0, 4)) = 2
		_SnowDissolveMaskOcclusion ("Dissolve mask occlusion", Range(0, 1)) = 0
        _SnowTranslucencyColor ("Translucency color", Color) = (0.75,1,1,1)
		_SnowGlitterColor ("Glitter Color", Color) = (0.8, 0.8, 0.8, 0.2)
		
		_SnowHeightThreshold ("Height threshold", Float) = -10000
		_SnowHeightThresholdTransition ("Height threshold transition", Range(10,4000)) = 1000
		
        [NoKeywordToggle] _SnowLevelFromGlobal ("Snow level controlled globally", Float) = 0
		[NoKeywordToggle] _FrostFromGlobal ("Frost controlled globally", Float) = 0
        [NoKeywordToggle] _SnowBumpMicroFromGlobal ("Snow bumps micro controlled globally", Float) = 0
        [NoKeywordToggle] _SnowDissolveFromGlobal ("Snow dissolve controlled globally", Float) = 0
        [NoKeywordToggle] _SnowSpecGlossFromGlobal ("Snow spec/gloss controlled globally", Float) = 0
        [NoKeywordToggle] _SnowGlitterColorFromGlobal ("Snow glitter color controlled globally", Float) = 0
		
		// glitter
        [NoKeywordToggle] _Glitter ("Glitter", Float) = 0
		[Foldout] _GlitterShown ("", Float) = 1
		_SparkleMap ("Sparkle & snow detail", 2D) = "black" {} // R used when snow is present, RGB is used when glitter is used w/o snow
		_SparkleMapGlitter ("Glitter map (UI)", 2D) = "black" {} // UI only prop - shared with snow feature
		_GlitterColor ("Glitter Color", Color) = (0.8, 0.8, 0.8, 0.2)
		_GlitterColor2 ("Glitter Color2", Color) = (0.8, 0.8, 0.8, 0.2)
		_GlitterColorization ("Random colorization", Range(0,1)) = 0.2
		_GlitterDensity ("Density", Range(0,1)) = 0.2
		_GlitterTiling ("Tiling", Float) = 1
		_GlitterAnimationFrequency ("Animation frequency", Float) = 0.02 // defined as constant in UBER_StandardConfig.cginc
		_GlitterFilter ("Filtering", Range(-4,4)) = -1
		_GlitterMask ("Masking", Range(0,1)) = 0
		
		// triplanar
		[Foldout] _TriplanarShown ("", Float) = 1
		_MainTexAverageColor ("Albdeo texture average color", Color) = (0.5, 0.5, 0.5, 0)
		_MainTex2AverageColor ("Albdeo 2 texture average color", Color) = (0.5, 0.5, 0.5, 0)
		_TriplanarBlendSharpness ("Blend sharpness", Range(1,100)) = 10
		_TriplanarNormalBlendSharpness ("Blend sharpness normal", Range(0,1)) = 0
		_TriplanarHeightmapBlendingValue ("Heightmap blending value", Range(0,1)) = 0.3
		_TriplanarBlendAmbientOcclusion ("Ambient occlusion", Range(0,1.0)) = 0.5
		[NoKeywordToggle] _TriplanarWorldMapping ("World mapping", Float) = 0
				
		[HideInInspector] _ShadowCull ("__shadowcull", Float) = 2.0
		[Foldout] _MainShown ("", Float) = 1
		[Foldout] _SecondaryShown ("", Float) = 1
		[Foldout] _PresetsShown ("", Float) = 0

		_Occlusion_from_albedo_alpha ("", Float) = 0
		[NoKeywordToggle]_Smoothness_from_albedo_alpha("", Float) = 0

		// substance fix
		heightMapTexelSize ("heightMap TexelSize fix for substance", Vector) = (1,1,1,1)
		bumpMapTexelSize ("bumpMap TexelSize fix for substance", Vector) = (1,1,1,1)
		bumpMap2TexelSize ("bumpMap2 TexelSize fix for substance", Vector) = (1,1,1,1)		
		
	}

	CGINCLUDE
		#define UNITY_SETUP_BRDF_INPUT MetallicSetup
		
		//
		// UBER
		//		
		
		// it works OK only when we've got NO u/v ratio biased
		//#define DISPLACE_IN_TEXTURE_UNITS
		
		// when enabled you can control level of maximum tessellaion per vertex
		// vertex color channel == 1 - full amount, comment out when not used
		//#define VERTEX_COLOR_CHANNEL_TESELLATION_AMOUNT r
		
		// when enabled you can control displacement strength per vertex
		// vertex color channel == 1 - full displace, comment out when not used
		// helpful to solve tearing problem on edges that has different normals/UVs for displace
		//#define VERTEX_COLOR_CHANNEL_TESELLATION_DISPLACEMENT_AMOUNT g
				
		// you can override global blend mode here (per shader - it's globally set in UBER_StandardConfig.cginc)
		// available modes - _DETAIL_MULX2 _DETAIL_MUL _DETAIL_ADD _DETAIL_LERP
		// default mode - _DETAIL_LERP
		//#define _DETAIL_MULX 1
		
		// uncomment if you want to save one sampler on platforms with limited texture (Dx9/OpenGL)
		// this will disable cubemap blending, be we gain one additional texture sampler for a feature
		//#define UNITY_SPECCUBE_BLENDING 0	
		
		// if defined you can control translucency by vertex color channel
		//#define TRANSLUCENCY_VERTEX_COLOR_CHANNEL g
		
		// if defined we can control occlusion by vertex color
		//#define OCCLUSION_VERTEX_COLOR_CHANNEL a
		
		// available r, g, b, a, comment out if you don't want to control it via vertex color
		#define VERTEX_COLOR_CHANNEL_DETAIL r

		// 1st layer coverage in _TWO_LAYERS mode
		#define VERTEX_COLOR_CHANNEL_LAYER r

		// wet coverage
		#define VERTEX_COLOR_CHANNEL_WETNESS a
			
		// ripples strength (when enabled in material inspector and WET_FLOW above IS NOT defined)
		//#define VERTEX_COLOR_CHANNEL_WETNESS_RIPPLES b

		// flow strength (when enabled in material inspector and WET_FLOW above IS defined)
		//#define VERTEX_COLOR_CHANNEL_WETNESS_FLOW b

		// wet droplets strength (when enabled in material)
		#define VERTEX_COLOR_CHANNEL_WETNESS_DROPLETS b
		
		// snow coverage (when enabled in material)
		#define VERTEX_COLOR_CHANNEL_SNOW g		

		// glitter mask - used from vertex only if defined below
		//#define VERTEX_COLOR_CHANNEL_GLITTER g

		// you can use below switch as diffuse color (albedo) tint
		//#define VERTEX_COLOR_RGB_TO_ALBEDO
		// when above enabled DIFFUSE_ALPHA_MASKING allow to mask tinting via alpha channel of diffuse texture
		//#define DIFFUSE_ALPHA_MASKING

		// ============================ don't touch below (it's already configured) unless you know what you're doing ==========================
		// when active we don't have secondary map details but shader works in 2-layers mode (vertex color controlled)
		// (need to match material tag below TWO_LAYERS "On" or "Off")
		// (remove shader features keywords on detail, we have no POM on 2 layers, but only shader_feature _PARALLAXMAP _PARALLAXMAP_2MAPS)
		//#define _TWO_LAYERS
		
		// (need to match material tag below RERF "On" or "Off")
		// for refraction to work - uncomment GrabPass { } below
		// remove alpha blending modes (#pragma shader_feature) and uncomment define for _ALPHAPREMULTIPLY_ON alone + CHROMATIC_ABERRATION shader feature
		#define _REFRACTION	
		
		#define TRIPLANAR_SELECTIVE

		// shader features turned on statically to save shader keywords and variants used
		#define _NORMALMAP 1
		#define _METALLICGLOSSMAP 1

	ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" "TESS"="On" "REFR"="On" "TWO_LAYERS"="Off" "TRIPLANAR"="On"}
		LOD 700
		
		// UBER - used in refraction
		GrabPass { }
		
		/*
		//uncomment if you'd like to hide back geometry - will write into depth though
		Pass
		{
			ColorMask 0
			ZWrite On

			CGPROGRAM
			//#pragma target 5.0
			#pragma exclude_renderers gles
			#pragma multi_compile_instancing
			
			#pragma shader_feature _SNOW	
			#pragma shader_feature _TRIPLANAR_WORLD_MAPPING		
				
			#pragma fragment fragForwardBase
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma vertex tessvert_surf
			#pragma hull hs_surf
			#pragma domain ds_surf			
			//#pragma vertex vertForwardBase
			#define v2f_struct VertexOutputForwardBase
			#define VERT_SURF vertForwardBase
			
			#define _TESSELLATION
			#pragma shader_feature _TESSELLATION_DISPLACEMENT
			#include "Tessellation.cginc"
			#include "../Includes/UBER_StandardCore.cginc"
			ENDCG
		}		
		*/
				
		// ------------------------------------------------------------------
		//  Base forward pass (directional light, emission, lightmaps, ...)
		Pass
		{
			Name "FORWARD" 
			Tags { "LightMode" = "ForwardBase" }

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]

			CGPROGRAM
			//#pragma target 5.0
			// TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers gles
			#pragma multi_compile_instancing
			
			// -------------------------------------
					
			//#pragma shader_feature _NORMALMAP
			
			//#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			// transparency turned on permanently for refraction shader
			#define _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _CHROMATIC_ABERRATION
			

						
			#pragma shader_feature ___ _EMISSION_TEXTURED _EMISSION_ANIMATED

			//#pragma shader_feature _METALLICGLOSSMAP
			
			// we don't have it in 2-layers mode
			#pragma shader_feature ___ _DETAIL_SIMPLE _DETAIL_TEXTURED _DETAIL_TEXTURED_WITH_SPEC_GLOSS
			// regular mode (1 layer) - no parallax, only tessellation			
			
			// in 2 layers mode we've got two options to take height values of layers
			//#pragma multi_compile _PARALLAXMAP _PARALLAXMAP_2MAPS
			#pragma shader_feature _TRIPLANAR_WORLD_MAPPING

			#pragma shader_feature _WETNESS_NONE _WETNESS_SIMPLE _WETNESS_RIPPLES _WETNESS_DROPLETS _WETNESS_FULL
			#pragma shader_feature _SNOW			
			#pragma shader_feature _TRANSLUCENCY
			//#pragma shader_feature _DIFFUSE_SCATTER
			#define _DIFFUSE_SCATTER
			#pragma shader_feature _GLITTER

			#pragma multi_compile_fwdbase
			//#pragma multi_compile_fog
			#include "../UBER_ForwardFogType.cginc"
				
			#pragma fragment fragForwardBase
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma vertex tessvert_surf
			#pragma hull hs_surf
			#pragma domain ds_surf			
			//#pragma vertex vertForwardBase
			#define v2f_struct VertexOutputForwardBase
			#define VERT_SURF vertForwardBase
			
			#define _TESSELLATION
			#pragma shader_feature _TESSELLATION_DISPLACEMENT
			#include "Tessellation.cginc"
			#include "../Includes/UBER_StandardCore.cginc"
			ENDCG
		}
		// ------------------------------------------------------------------
		//  Additive forward pass (one light per pass)
		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend [_SrcBlend] One
			Fog { Color (0,0,0,0) } // in additive pass fog should be black
			ZWrite Off
			ZTest LEqual

			CGPROGRAM
			//#pragma target 5.0
			// GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers gles
			#pragma multi_compile_instancing

			// -------------------------------------

			
			//#pragma shader_feature _NORMALMAP
			//#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			// transparency turned on permanently for refraction shader
			#define _ALPHAPREMULTIPLY_ON
			
			//#pragma shader_feature _METALLICGLOSSMAP
			
			// we don't have it in 2-layers mode
			#pragma shader_feature ___ _DETAIL_SIMPLE _DETAIL_TEXTURED _DETAIL_TEXTURED_WITH_SPEC_GLOSS
			// regular mode (1 layer) - no parallax, only tessellation			
			
			// in 2 layers mode we've got two options to take height values of layers
			//#pragma multi_compile _PARALLAXMAP _PARALLAXMAP_2MAPS
			#pragma shader_feature _TRIPLANAR_WORLD_MAPPING

			#pragma shader_feature _WETNESS_NONE _WETNESS_SIMPLE _WETNESS_RIPPLES _WETNESS_DROPLETS _WETNESS_FULL
			#pragma shader_feature _SNOW
			#pragma shader_feature _TRANSLUCENCY
			//#pragma shader_feature _DIFFUSE_SCATTER
			#define _DIFFUSE_SCATTER			
			#pragma shader_feature _GLITTER
			
			#pragma multi_compile_fwdadd_fullshadows
			//#pragma multi_compile_fog
			#include "../UBER_ForwardFogType.cginc"
				
			#pragma fragment fragForwardAdd
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma vertex tessvert_surf
			#pragma hull hs_surf
			#pragma domain ds_surf			
			//#pragma vertex vertForwardAdd
			#define v2f_struct VertexOutputForwardAdd
			#define VERT_SURF vertForwardAdd
			
			#define _TESSELLATION
			#pragma shader_feature _TESSELLATION_DISPLACEMENT
			#include "Tessellation.cginc"
			#include "../Includes/UBER_StandardCore.cginc"
			ENDCG
		}
		// ------------------------------------------------------------------
		//  Shadow rendering pass
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			
			ZWrite On ZTest LEqual
			Cull [_ShadowCull]

			CGPROGRAM
			//#pragma target 5.0
			// TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers gles
			#pragma multi_compile_instancing
			
			// -------------------------------------

			//#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			// transparency turned on permanently for refraction shader
			#define _ALPHAPREMULTIPLY_ON

			#pragma shader_feature _SNOW
			// anything other than _WETNESS_NONE means we've got wetness enabled
			#pragma shader_feature _WETNESS_NONE
			//#pragma shader_feature _NORMALMAP

			#pragma multi_compile_shadowcaster

			// regular mode (1 layer) - no parallax, only tessellation
			
			// in 2 layers mode we've got two options to take height values of layers
			//#pragma multi_compile _PARALLAXMAP _PARALLAXMAP_2MAPS
			#pragma shader_feature _TRIPLANAR_WORLD_MAPPING			

			#define _TESSELLATION
			#pragma shader_feature _TESSELLATION_DISPLACEMENT
			#pragma fragment fragShadowCaster
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma vertex tessvert_surf
			#pragma hull hs_surf
			#pragma domain ds_surf	
					
			#include "Tessellation.cginc"
			#include "../Includes/UBER_StandardShadow_Tessellation.cginc"
			ENDCG
		}
		// ------------------------------------------------------------------
		//  Deferred pass
		Pass
		{
			Name "DEFERRED"
			Tags { "LightMode" = "Deferred" }

			CGPROGRAM
			//#pragma target 5.0
			// TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers nomrt gles
			#pragma multi_compile_instancing
			

			// -------------------------------------

			//#pragma shader_feature _NORMALMAP
			//#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			// transparency turned on permanently for refraction shader
			#define _ALPHAPREMULTIPLY_ON
			

			
			#pragma shader_feature ___ _EMISSION_TEXTURED _EMISSION_ANIMATED

			//#pragma shader_feature _METALLICGLOSSMAP
			
			// we don't have it in 2-layers mode
			#pragma shader_feature ___ _DETAIL_SIMPLE _DETAIL_TEXTURED _DETAIL_TEXTURED_WITH_SPEC_GLOSS
			// regular mode (1 layer) - no parallax, only tessellation
			
			// in 2 layers mode we've got two options to take height values of layers
			//#pragma multi_compile _PARALLAXMAP _PARALLAXMAP_2MAPS
			#pragma shader_feature _TRIPLANAR_WORLD_MAPPING

			#pragma shader_feature _WETNESS_NONE _WETNESS_SIMPLE _WETNESS_RIPPLES _WETNESS_DROPLETS _WETNESS_FULL
			#pragma shader_feature _SNOW
			#pragma shader_feature _TRANSLUCENCY
			//#pragma shader_feature _DIFFUSE_SCATTER
			#define _DIFFUSE_SCATTER		
			#pragma shader_feature _GLITTER

			#pragma multi_compile_prepassfinal
			
			#pragma fragment fragDeferred
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma vertex tessvert_surf
			#pragma hull hs_surf
			#pragma domain ds_surf			
			//#pragma vertex vertDeferred
			#define v2f_struct VertexOutputDeferred
			#define VERT_SURF vertDeferred
			
			#define _TESSELLATION
			#pragma shader_feature _TESSELLATION_DISPLACEMENT
			#include "Tessellation.cginc"
			#include "../Includes/UBER_StandardCore.cginc"			
	ENDCG
		}

		// ------------------------------------------------------------------
		// Extracts information for lightmapping, GI (emission, albedo, ...)
		// This pass it not used during regular rendering.
		Pass
		{
			Name "META" 
			Tags { "LightMode"="Meta" }

			Cull Off

			CGPROGRAM
			#pragma vertex vert_meta
			#pragma fragment frag_meta
			#pragma target 3.0
			
			// keywords available (_PARALLAXMAP_2MAPS in 2 layers mode only)
			
			//#pragma shader_feature ___ _PARALLAXMAP _PARALLAXMAP_2MAPS
			// we don't have it in 2-layers mode
			#pragma shader_feature ___ _DETAIL_SIMPLE _DETAIL_TEXTURED _DETAIL_TEXTURED_WITH_SPEC_GLOSS
			#pragma shader_feature _TRIPLANAR_WORLD_MAPPING

			// anything other than _WETNESS_NONE means we've got wetness enabled
			#pragma shader_feature _WETNESS_NONE
			#pragma shader_feature _SNOW
			//#pragma shader_feature _NORMALMAP
			
			#pragma shader_feature ___ _EMISSION_TEXTURED _EMISSION_ANIMATED
			//#pragma shader_feature _METALLICGLOSSMAP
			
			// meta code moved to core
			#define UNITY_PASS_META 1
			#include "../Includes/UBER_StandardCore.cginc"	ENDCG
		}
	}

	FallBack "UBER - Metallic Setup/Refraction/Triplanar Selective"
	CustomEditor "UBER_StandardShaderGUI"
}
