//
// after change and save to this file - REIMPORT actual shaders subfolders (_Specular, _Metallic, etc.)
//
#ifndef UNITY_STANDARD_CONFIG_INCLUDED
#define UNITY_STANDARD_CONFIG_INCLUDED

// Define Specular cubemap constants
#ifndef UNITY_SPECCUBE_LOD_EXPONENT
#define UNITY_SPECCUBE_LOD_EXPONENT (1.5)
#endif
#ifndef UNITY_SPECCUBE_LOD_STEPS
// tweak a bit to have perfect mirror reflections a bit quicker (for roughness>0)
// NOTE: mipmapLevelToPerceptualRoughness will give wrong results ! (but is not used yet in shaders)
#define UNITY_SPECCUBE_LOD_STEPS (6.4) - 0.4
#endif

// Energy conservation for Specular workflow is Monochrome. For instance: Red metal will make diffuse Black not Cyan
#ifndef UNITY_CONSERVE_ENERGY
#define UNITY_CONSERVE_ENERGY 1
#endif
#ifndef UNITY_CONSERVE_ENERGY_MONOCHROME
#define UNITY_CONSERVE_ENERGY_MONOCHROME 1
#endif

// "platform caps" defines that were moved to editor, so they are set automatically when compiling shader
// UNITY_SPECCUBE_BOX_PROJECTION
// UNITY_SPECCUBE_BLENDING

// still add safe net for low shader models, otherwise we might end up with shaders failing to compile
#if SHADER_TARGET < 30
	#undef UNITY_SPECCUBE_BOX_PROJECTION
	#define UNITY_SPECCUBE_BOX_PROJECTION 0
	#undef UNITY_SPECCUBE_BLENDING
	#define UNITY_SPECCUBE_BLENDING 0
#endif

#ifndef UNITY_SAMPLE_FULL_SH_PER_PIXEL
//If this is enabled then we should consider Light Probe Proxy Volumes(SHEvalLinearL0L1_SampleProbeVolume) in ShadeSH9
#define UNITY_SAMPLE_FULL_SH_PER_PIXEL 0
#endif

#ifndef UNITY_GLOSS_MATCHES_MARMOSET_TOOLBAG2
#define UNITY_GLOSS_MATCHES_MARMOSET_TOOLBAG2 0
#endif

// note that this is valid globally in forward lighting
// for deferred - change UNITY_BRDF_GGX to 1 in Internal-DeferredShading_UBER.shader
#ifndef UNITY_BRDF_GGX
#define UNITY_BRDF_GGX 1
#endif

// Orthnormalize Tangent Space basis per-pixel
// Necessary to support high-quality normal-maps. Compatible with Maya and Marmoset.
// However xNormal expects oldschool non-orthnormalized basis - essentially preventing good looking normal-maps :(
// Due to the fact that xNormal is probably _the most used tool to bake out normal-maps today_ we have to stick to old ways for now.
// 
// Disabled by default, until xNormal has an option to bake proper normal-maps.
#ifndef UNITY_TANGENT_ORTHONORMALIZE
#define UNITY_TANGENT_ORTHONORMALIZE 0
#endif

#ifndef UNITY_ENABLE_REFLECTION_BUFFERS
#define UNITY_ENABLE_REFLECTION_BUFFERS 1
#endif

// Some extra optimizations

// On PVR GPU there is an extra cost for dependent texture readback, especially hitting texCUBElod
// These defines should be set as keywords or smth (at runtime depending on GPU).
// for now we keep the code but disable it, as we want more optimization/cleanup passes

#ifndef UNITY_OPTIMIZE_TEXCUBELOD
#define UNITY_OPTIMIZE_TEXCUBELOD 0
#endif

// Simplified Standard Shader is off by default and should not be used for Legacy Shaders
#ifndef UNITY_STANDARD_SIMPLE
#define UNITY_STANDARD_SIMPLE 0
#endif

//======================================================================================================//
//
// UBER
//
//
// set to 1 if you want UBER shaders react to the same light falloff in forward
#define UBER_MATCH_ALLOY_LIGHT_FALLOFF 0
//
// define when you like to control translucency power per light (its color alpha channel)
// note, that this can interfere with solutions that uses light color.a for different purpose (like Alloy)
// (affects only FORWARD lighting path, for deferred look into Internal-DeferredShading_UBER.shader or UBER2AlloyDeferred.cginc)
//#define UBER_TRANSLUCENCY_PER_LIGHT_ALPHA	
// you can gently turn it up (like 0.3, 0.5) if you find front facing geometry overbrighten (esp. for point lights),
// but suppresion can negate albedo for high translucency values (they can become badly black)
// (affects only FORWARD lighting path, for deferred look into Internal-DeferredShading_UBER.shader or UBER2AlloyDeferred.cginc)
#define TRANSLUCENCY_SUPPRESS_DIFFUSECOLOR 0.0

// you can redefine texture channel that's used for height
#define PARALLAX_CHANNEL a
// primary heightmap channel used for 2nd layer (takes effect only when 2nd heightmap is empty)
#define PARALLAX_CHANNEL_2ND_LAYER g

// define below if you experience unexpected behavior or crash on Macs (seams to work now)
// if you don't get parallax on DX9 with INTEL HD GPUs you can uncomment below as well - I've noticed it resist to work
#define SAFE_LOOPS

#if !defined(ENABLE_SNOW_WORLD_MAPPING)
	// when turned off (= 0) you can gain some extra performance on snow, but snow mapping in world space will be permanently disabled
	// remember that you can also put this define per shader at its beginning in defines section
	#define ENABLE_SNOW_WORLD_MAPPING 1
#endif

// when you target DX11 only you can try below define, but this is experimental
// when writing into depth in POM shaders you can get some extra performance due to early-z culling (with front to back opaque geometry drawing)
// you need also to change pragma target 3.0 to 5.0 in all shaders to get it working
// then - however it got compiled on my HD4600 SM5.0 GPU it didn't work (thrown junks into depth buffer - might be matter of my GPU drivers though)
#define CONSERVATIVE_DEPTH_WRITE 0

// turn off (0) if you don't need flow direction from normalmaps, but from mesh normals only - will gain some performance
#define WATER_FLOW_DIRECTION_FROM_NORMALMAPS 1

// don't touch it unless we know Unity fixed bug in substances that don't output right texelSize vector...
#define FIX_SUBSTANCE_BUG 0

// set to 1 if you can't resolve height values in triplanar (might be exposed visible on wetness)
// don't touch w/o reason - it's more expensive
#define RESOLVE_TRIPLANAR_HEIGHT_SEAMS 0

// you can set this flag per shader (some of your UBER shaders might be pierceable while other not - remember that pierceable shader needs yet another 1 texture sampler)
// currently prepared for further usage only so leave it set to 0
#if !defined(DECAL_PIERCEABLE)
	// 0 - piercing of this shader is disabled, 1 - pierceable
	#define DECAL_PIERCEABLE 0
#endif

//
//
//
// texture channels used for occlusion
//
//
//
// ======= SPECULAR SETUP ========
//
// ambient occlusion is taken from this channel of occlusion texture
// note that it's used only when occlusion is actually taken from texture (i.e. occlusion texture is present in material)
#if !defined(AMBIENT_OCCLUSION_CHANNEL)
#define AMBIENT_OCCLUSION_CHANNEL g
#endif
// channel for 2nd layer
#if !defined(AMBIENT_OCCLUSION_CHANNEL2)
#define AMBIENT_OCCLUSION_CHANNEL2 a
#endif

// translucency/glitter occlusion texture channel
// note that it's used only when occlusion is actually taken from texture (i.e. occlusion texture is present in material)
#if !defined(AUX_OCCLUSION_CHANNEL)
#define AUX_OCCLUSION_CHANNEL r
#endif
#if !defined(AUX_OCCLUSION_CHANNEL2)
#define AUX_OCCLUSION_CHANNEL2 b
#endif
//
//
//
// ======= METALLIC SETUP ========
//
// ambient occlusion is taken from this channel of occlusion texture
// note that it's used only when occlusion is actually taken from texture (i.e. occlusion texture is present in material)
#define METALLIC_SETUP__AMBIENT_OCCLUSION_CHANNEL g
// channel for 2nd layer
#define METALLIC_SETUP__AMBIENT_OCCLUSION_CHANNEL2 a

// translucency/glitter occlusion texture channel
// note that it's used only when occlusion is actually taken from texture (i.e. occlusion texture is present in material)
#define METALLIC_SETUP__AUX_OCCLUSION_CHANNEL b
#define METALLIC_SETUP__AUX_OCCLUSION_CHANNEL2 r



// constants for glitter
#define GLITTER_AMPLIFY 40000.0
#define GLITTER_SMOOTHNESS_GAIN_LIMIT 0.3
#define GLITTER_ANIMATION_FREQUENCY 0.12

// constants for snow
// tiling for large coverage mask taken from ripplemap (large scale bumps tex of snow) - default 20 units in world space
#define SNOW_LARGE_MASK_TILING (1.0/20)

#if !defined(_SOFT_SHADOWS)
	// POM self-shadows
	#define _SOFT_SHADOWS
#endif

#if !defined(_UBER_SHADOWS_FORWARDADD)
	// every additional light in forward can generate its own self-shadows in POM
	#define _UBER_SHADOWS_FORWARDADD
#endif

// perturb normals a bit (will add wavy distortions on mirrors so they don't look that synthetic)
// this feature can be achieved by wavying normalmap, so it's probably unusable at all...
// if you change this to 1 you need to add "BEND_NORM"="On" tag into your shaders
#if !defined(BEND_NORMALS)
	#define BEND_NORMALS 0
#endif

#if !defined(_DETAIL_MULX2) && !defined(_DETAIL_MUL) && !defined(_DETAIL_ADD) && !defined(_DETAIL_LERP)
	// define global detail blending mode
	#define _DETAIL_MULX2 1
#endif

#if !defined(WET_FLOW)
	// default setting for animated ripples that don't follow surface slope direction
	#define WET_FLOW 0
#endif

// increase to gain performance in ZWRITE (shadow casting/collecting) at cost of  quality
#define DEPTH_PASS_MIP_ADD 0

// leave it undefined for better performance
//#define SECONDARY_OCCLUSION_PARALLAXED

// max number of steps to resolve POM with distance map
#define DISTANCEMAP_STEPS 4
// set to zero when you don't want texturing sidewalls for some reason
#define DISTANCEMAP_TEXTURING_SIDEWALLS 1

// number of binary search steps in POM extrusion mapping
#define EXTRUSIONMAP_BINARY_SEARCH_STEPS 4
// increase for better performance (larger raycast steps)
// decreease if you would like to improve corners quality
#define EXTRUSION_MAP_WAVELENGTH 1.0
// set to zero when you don't want texturing sidewalls for some reason
#define EXTRUSIONMAP_TEXTURING_SIDEWALLS 1

// vertex color channel using for RTP's geom blend
#define VERTEX_COLOR_CHANNEL_GEOM_BLEND a

//
//
//======================================================================================================//

#if defined(_2SIDED)
	#undef UNITY_SAMPLE_FULL_SH_PER_PIXEL
	#define UNITY_SAMPLE_FULL_SH_PER_PIXEL 1
#endif

#if RESOLVE_TRIPLANAR_HEIGHT_SEAMS
	#define RESOLVE_SEAMS_X ,ddx(uvz.zy),ddy(uvz.zy)
	#define RESOLVE_SEAMS_Y ,ddx(uvz.xz),ddy(uvz.xz)
	#define RESOLVE_SEAMS_Z ,ddx(uvz.yx),ddy(uvz.yx)
#else
	#define RESOLVE_SEAMS_X
	#define RESOLVE_SEAMS_Y
	#define RESOLVE_SEAMS_Z
#endif

#if defined(VERTEX_COLOR_CHANNEL_DETAIL)
	#define __VERTEX_COLOR_CHANNEL_DETAIL vertex_color.VERTEX_COLOR_CHANNEL_DETAIL
#else
	#define __VERTEX_COLOR_CHANNEL_DETAIL 1
#endif

#if defined(VERTEX_COLOR_CHANNEL_LAYER)
	#define __VERTEX_COLOR_CHANNEL_LAYER vertex_color.VERTEX_COLOR_CHANNEL_LAYER
#else
	#define VERTEX_COLOR_CHANNEL_LAYER r
	#define __VERTEX_COLOR_CHANNEL_LAYER vertex_color.r
#endif

#if defined(VERTEX_COLOR_CHANNEL_WETNESS)
	#define __VERTEX_COLOR_CHANNEL_WETNESS vertex_color.VERTEX_COLOR_CHANNEL_WETNESS
#else
	#define __VERTEX_COLOR_CHANNEL_WETNESS 1
#endif

#if defined(VERTEX_COLOR_CHANNEL_WETNESS_RIPPLES)
	#define __VERTEX_COLOR_CHANNEL_WETNESS_RIPPLES vertex_color.VERTEX_COLOR_CHANNEL_WETNESS_RIPPLES
#else
	#define __VERTEX_COLOR_CHANNEL_WETNESS_RIPPLES 1
#endif

#if defined(VERTEX_COLOR_CHANNEL_WETNESS_FLOW)
	#define __VERTEX_COLOR_CHANNEL_WETNESS_FLOW vertex_color.VERTEX_COLOR_CHANNEL_WETNESS_FLOW
#else
	#define __VERTEX_COLOR_CHANNEL_WETNESS_FLOW 1
#endif

#if defined(VERTEX_COLOR_CHANNEL_WETNESS_DROPLETS)
	#define __VERTEX_COLOR_CHANNEL_WETNESS_DROPLETS vertex_color.VERTEX_COLOR_CHANNEL_WETNESS_DROPLETS
#else
	#define __VERTEX_COLOR_CHANNEL_WETNESS_DROPLETS 1
#endif

#if defined(VERTEX_COLOR_CHANNEL_SNOW)
	#define __VERTEX_COLOR_CHANNEL_SNOW vertex_color.VERTEX_COLOR_CHANNEL_SNOW
#else
	#define __VERTEX_COLOR_CHANNEL_SNOW 1
#endif


#endif // UNITY_STANDARD_CONFIG_INCLUDED
