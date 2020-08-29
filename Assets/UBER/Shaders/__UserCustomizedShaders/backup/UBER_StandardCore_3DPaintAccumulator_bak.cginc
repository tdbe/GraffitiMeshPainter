#ifndef UBER_STANDARD_CORE_INCLUDED
#define UBER_STANDARD_CORE_INCLUDED

#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityInstancing.cginc"
#include "../../UBER_StandardConfig.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityMetaPass.cginc"
#include "UnityStandardBRDF.cginc"
#include "UnityGBuffer.cginc"

#include "../../Includes/UBER_StandardInput.cginc"
#include "../../Includes/UBER_StandardUtils2.cginc"

//#include "AutoLight.cginc"
// replace AutoLight.cginc LIGHT_ATTENUATION() macros to get independent control over shadows
#include "../../Includes/UBER_AutoLightMOD.cginc"

/* _Paint3DAccumulator_ */
struct appdata_P3DA
{
	half4 vertex : POSITION;
	#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
	half3 normal : NORMAL;
	#endif
	half2 uv : TEXCOORD0;
};

struct v2f_P3DA
{
	half4 vertex : SV_POSITION;
	half2 uv : TEXCOORD0;

	#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
	half3 worldPos : TEXCOORD1;
	#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
	half3 normal : TEXCOORD2;
	#endif
	#endif
	
	#if !defined(UNITY_REQUIRE_FRAG_WORLDPOS) && defined(_CUSTOM_VERTEX_DISPLACEMENT_)
	half3 normal : TEXCOORD1;
	#endif
};


struct ControllerData
{
	//half3 position;
	half3 brushMode;//.x: 0 = normal, 1 = blend between 2 textures
	//half3 targetPos;
	//half3 normal;
	//half3 paintingParams;//0 or 1 or -10 if inactve
	half3 color;

};



half4 _Color_P3DA;
half4 _EraserColor_P3DA;
sampler2D _MainTex_P3DA;
half4 _MainTex_P3DA_ST;
half _HeightMapStrength_P3DA;

#ifdef _BLEND_2_TEXTURES_WITH_PAINT_
sampler2D _OverlayTex_Before_P3DA;
half4 _OverlayTex_Before_P3DA_ST;
sampler2D _OverlayTex_After_P3DA;
#endif


//sampler2D _MainTexInternal_P3DA;

/// Contains the accumulated paint data
uniform RWTexture2D<half4> _MainTexInternal_P3DA : register(u3);
//uniform Texture2D<half4> _MainTexScreen_P3DA_Reader;// : register(u2);	
//uniform sampler2D _MainTexScreen_P3DA_Reader;// : register(u2);	
//half4 _MainTexInternal_P3DA_ST;
//sampler2D _MainTexInternal_P3DA_Sampler;

//sampler2D _MainTexScreen_P3DA;
//SamplerState samplerInput;
/// Contains the accumulated paint data + everything not painted on, like color picker, tooltips etc.
uniform RWTexture2D<half4> _MainTexScreen_P3DA : register(u2);
//half4 _MainTexScreen_P3DA_ST;

sampler2D _BgTex_P3DA;
half4 _BgTex_P3DA_ST;

half _BrushScaleMod_P3DA;
half _BrushScaleOffset_P3DA;
//half _DistanceFadeOffset;
//half _DistanceFadeScale;
half4 _PlayParams_P3DA;
//half4 _BrushPosWS[2];
//half4 _BrushNormal[2];
//half4 _ControllerScale;
//half4 _ControllerOffset;
static const int BRUSH_COUNT_P3DA = 2;
//StructuredBuffer<ControllerData> _BrushBuffer_P3DA;
uniform RWStructuredBuffer<ControllerData> _BrushBuffer_P3DA : register(u1);
uniform half4 _PositionWS_P3DA[BRUSH_COUNT_P3DA];
uniform half4 _PositionSS_P3DA[BRUSH_COUNT_P3DA];
uniform half4 _PaintingParams_P3DA[BRUSH_COUNT_P3DA];
uniform half4x4 _Matrix_iTR_P3DA[BRUSH_COUNT_P3DA];
half _Init_P3DA;

half4 _ConeShapeXY_P3DA;
//half _SprayCentreHardness;
half _ConeScale_P3DA;
half _ConeScale2_P3DA;
half _ConeScalePow_P3DA;
half _ConeClamp_P3DA;

half4 _FadeShapeXY_P3DA;
half _FadeScalePow_P3DA;
half4 _FadeScale_P3DA;

half _BlendSubtraction_P3DA;
half _BlendAddition_P3DA;

half _TargetRingLocation_P3DA;
half _TargetRingThickness_P3DA;

half _SprayBlend_P3DA;
half _EraseBlend_P3DA;

#ifdef _GPU_COLOR_PICKER_
	half _ColorSampleThresh_P3DA;

	//<only used by passes with color picker>
	sampler2D _ColorPicker_P3DA;
	half4 _ColorPicker_P3DA_ST;
	half _ColorSampleDist_P3DA;
	half4 _ColorSampleDist_P3DA_ST;

	sampler2D _ColorPickerDisplay_P3DA;
	//half4 _ColorPickerDisplay_P3DA_ST;
#endif

sampler2D _ToolOutlineTex_P3DA;
half4 _ToolOutlineTex_P3DA_ST;

half4 _ColorSamplerVolume_P3DA;
//</only used by passes with color picker>


struct FragmentOutput
{
	half4 color : SV_Target0;
	half4 colorInternal : SV_Target1;

};

half sdCylinder(half3 p, half3 c)
{
	return length(p.xz - c.xy) - c.z;
}

half sdCone(half3 p, half2 c, half zStop)// iq
{
	// c must be normalized
	half q = length(p.xy);
	if (p.z > zStop)
		return dot(c, half2(q, p.z));
	else return 0;
}

//cone section
half sdCone2(half3 p, half r1, half h)//, half r2)
{
	half d1 = -p.y - h;
	half q = p.y - h;
	//half si = 0.5*(r1 - r2) / h;
	half si = 0.5*(r1) / h;
	//half d2 = max(sqrt(dot(p.xz, p.xz)*(1.0 - si*si)) + q*si - r2, q);
	half d2 = max(sqrt(dot(p.xz, p.xz)*(1.0 - si*si)) + q*si, q);
	return length(max(half2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

// Cone with correct distances to tip and base circle. Y is up, 0 is in the middle of the base.
half sdCone3(half3 p, half radius, half height)
{
	half2 q = half2(length(p.xz), p.y);
	half2 tip = q - half2(0, height);
	half2 mantleDir = normalize(half2(height, radius));
	half mantle = dot(tip, mantleDir);
	half d = max(mantle, -q.y);
	half projected = dot(tip, half2(mantleDir.y, -mantleDir.x));

	// distance to tip
	if ((q.y > height) && (projected < 0)) {
		d = max(d, length(tip));
	}

	// distance to base ring
	if ((q.x > radius) && (projected > length(half2(height, radius)))) {
		d = max(d, length(q - half2(radius, 0)));
	}
	return d;
}

half sdSphere(half3 p, half s)
{
	return length(p) - s;
}

half2 opU(half d1, half d2)
{
	return (d1<d2) ? d1 : d2;
}

half opI(half d1, half d2)
{
	return max(d1, d2);
}

half map(half s, half a1, half a2, half b1, half b2)
{
	return b1 + (s - a1)*(b2 - b1) / (a2 - a1);
}

// power smooth min (k = 8);
half2 smin(half2 a, half2 b, half k)
{

	a.x = pow(a.x, k);
	b.x = pow(b.x, k);
	half2 res;

	res.x = pow((a.x*b.x) / (a.x + b.x), 1.0 / k);


	res.y = (a.x < b.x) ? a.y : b.y;


	return res;
}

// power smooth min (k = 8);
half smax(half a, half b, half k)
{
	return a.x + b.x - pow(a.x*a.x + b.x*b.x, -k); // http://www.hyperfun.org/HOMA08/48890118.pdf


}


half2 opBlendSmin(half2 d1, half2 d2, half k)
{
	return smin(d1, d2, k);
}

half opBlendSmax(half d1, half d2, half k)
{
	return smax(d1, d2, k);
}

half3 opRotateTranslate(half4 p, half4x4 m)
{
	//half3 q = invert(m)*p;
	half3 q = mul(m,p).xyz;
	return q;
}

//subtraction
half opS(half d1, half d2)
{
	return max(-d1, d2);
}

/* _Paint3DAccumulator_ */

half4 ReadFromPaintAccumulationRT(half2 inuv){
	half4 textureVals = half4(0,0,0,0);
	#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
	half2 uv = inuv*_MainTex_P3DA_ST.xy + _MainTex_P3DA_ST.zw;
	//half4 textureVals = tex2Dlod(_MainTexInternal_P3DA_Sampler, half4(uv, 0.0, 0.0));
	int coordx = int((uv.x)*2048);
	int coordy = int((uv.y)*2048);
	int2 mainUVRWT = int2(coordx,coordy);
	textureVals = _MainTexInternal_P3DA[mainUVRWT];
	#endif
	return textureVals;
}

v2f_P3DA Paint3DAccumulatorVertexLogic_P0(appdata_P3DA v, out half vertexHeight){
	v2f_P3DA o;

	#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
	half2 uv = v.uv*_MainTex_P3DA_ST.xy + _MainTex_P3DA_ST.zw;
	//half4 textureVals = tex2Dlod(_MainTexInternal_P3DA_Sampler, half4(uv, 0.0, 0.0));
	int coordx = int((uv.x)*2048);
	int coordy = int((uv.y)*2048);
	int2 mainUVRWT = int2(coordx,coordy);
	half4 textureVals = _MainTexInternal_P3DA[mainUVRWT];
	half height = (textureVals.x + textureVals.y + textureVals.z) / 3;
	vertexHeight = height;
	half3 normal = v.normal;
	if(textureVals.a < 1.0)
		normal = -normal;
	v.vertex.xyz += normal * height;
	o.normal =  mul(unity_ObjectToWorld, v.normal).xyz;
	#endif


	//o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	// Tranforms position from object to homogenous space https://forum.unity3d.com/threads/unityobjecttoclippos.400520/
	//o.vertex = UnityObjectToClipPos(v.vertex);
	//o.uv = TRANSFORM_TEX(v.uv, _MainTexInternal_P3DA);
	//o.uv = TRANSFORM_TEX(v.uv, _MainTex_);
	#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
	o.worldPos = half3(0,0,0);
	#endif
	o.vertex = half4(0,0,0,0);
	o.uv = half2(0,0);
	
	
	return o;
}

/* _Paint3DAccumulator_ */

half4 Paint3DAccumulatorFragmentLogic_P0(v2f_P3DA i){
	#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
	half3 normalws = i.normal;		
	#endif
	//half4 prevColor = tex2D(_MainTexInternal_P3DA, i.uv*_MainTexInternal_P3DA_ST.xy + _MainTexInternal_P3DA_ST.zw);
	half2 mainUV = i.uv;//*_MainTexInternal_P3DA_ST.xy + _MainTexInternal_P3DA_ST.zw;
	int coordx = int((mainUV.x)*2048);
	int coordy = int((mainUV.y)*2048);
	int2 mainUVRWT = int2(coordx,coordy);
	
	half4 prevColor = _MainTexInternal_P3DA[mainUVRWT];
	//half4 prevScreenColor = _MainTexScreen_P3DA[mainUVRWT];
	
	half3 temprgb = prevColor.rgb;
	half2 uv2 = i.uv*_BgTex_P3DA_ST.xy + _BgTex_P3DA_ST.zw;
	//half4 outColor = half4(0, 0, 0, 1);
	half4 outColor = tex2D(_BgTex_P3DA, uv2);
	outColor.a = prevColor.a;
	//half r_g_b_max = max(outColor.r,max(outColor.g,outColor.b));


	#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
	half3 pxPosWorld = (i.worldPos.xyz);
	#else
	half3 pxPosWorld = half3(1,0,1);// this shader branch should not be reached
	#endif

	//half4 output = tex2D(_MainTex_P3DA, i.uv*_MainTex_P3DA_ST.xy + _MainTex_P3DA_ST.zw);
	//output.b = 1;
	//output.r = 1;

	half2 outdf = half2(1,1);

	for (int i = 0; i < BRUSH_COUNT_P3DA; i++)
	{
		
		half3 pos = pxPosWorld;

		half2 dims = _ConeShapeXY_P3DA.xy;

		//pos = opRotateTranslate(half4(pos.x, pos.y, pos.z, 1), _Matrix_iTR[i]).xyz;
		//pos = pos - _PositionWS_P3DA[i];
		pos = pos - _PositionWS_P3DA[i];
		half3 toolToPixelDirWS = normalize(pos);

		pos = opRotateTranslate(half4(pos.x, pos.y, pos.z, 1), _Matrix_iTR_P3DA[i]).xyz;// - _PositionWS_P3DA[i].xyz;

		pos.z += _ConeShapeXY_P3DA.z;
		half fadeDist = pos.z * _ConeShapeXY_P3DA.w - pos.z;

		half coneDFv = sdCone(pos / _ConeScale_P3DA, dims / _ConeScale_P3DA, _ConeClamp_P3DA)*_ConeScale_P3DA*_ConeScale2_P3DA;
		coneDFv = pow(coneDFv, _ConeScalePow_P3DA);


		half3 spherePos = pos;
		spherePos.z += _FadeShapeXY_P3DA.w;
		spherePos *= _FadeScale_P3DA;
		half sphereDFv = sdSphere(spherePos / _FadeShapeXY_P3DA.x, _FadeShapeXY_P3DA.z / _ConeScale_P3DA)*_FadeShapeXY_P3DA.x*_FadeShapeXY_P3DA.y;
		sphereDFv = pow(sphereDFv, _FadeScalePow_P3DA);

		//half blend = opBlendSmin(coneDFv, sphereDFv, _FadeScale_P3DA.w);
		half blend = opBlendSmax(coneDFv, sphereDFv, _BlendSubtraction_P3DA);




		//outdf = opBlendSmin(half2(outdf.x,1), half2(blend,2), _BlendAddition_P3DA);// opI(coneDFv, sphereDFv);
		//outdf.x = 1 - max(outdf.x, 0.1);
		//outdf.x = saturate(blend.x);

		blend.x = 1 - max(blend.x, 0.1);
		blend.x = saturate(blend.x);


		//half a = blend.x;
		//temprgb.xyz = _BrushBuffer_P3DA[i].color.xyz * a + temprgb.rgb * (1 - a);

		if (_PaintingParams_P3DA[i].y > 0)
		{
			// erase (paint black)
			blend.x /= _EraseBlend_P3DA;
			half a = saturate(blend.x);
			temprgb.xyz = _EraserColor_P3DA.rgb * a + temprgb.rgb * (1.0 - a);
			
			//No need to erase custom modes here if they're based on rgb color
			
			if(a>0.0)
			{
				outColor.a = 0.0;
				//outColor.a = 1-a;
			}
			
			
		}
		else
		if (_PaintingParams_P3DA[i].x > 0)
		{
			/*
			//_BrushBuffer_P3DA[i].color = _Color_P3DA;
			//half a = outdf.x;
			blend.x /= _SprayBlend_P3DA;
			half a = saturate(blend.x);
			temprgb.xyz = _BrushBuffer_P3DA[i].color.xyz * a + temprgb.rgb * (1.0 - a);
			//temprgb.xyz = _Color_P3DA * a + temprgb.rgb * (1.0 - a);
			*/

			blend.x /= _SprayBlend_P3DA;
			half a = saturate(blend.x);
			
			if(a>0.0)
			{
				//float alphaFlag = outColor.a;
				//outColor.a = a;// crystals of displacement
				//outColor.a = .0;

				//if(prevScreenColor.a >-0.5){// don't paint on erasure, unless you erase on erasure, or you displace vertices.
				//if( !(prevScreenColor.a > .3 && prevScreenColor.a <.7) ){// don't paint on erasure, unless you erase on erasure, or you displace vertices.
					
					// just paint
					if( (prevColor.a == 0.0 || prevColor.a ==.8) &&
						_BrushBuffer_P3DA[i].brushMode.x == .8)
					{
						
						outColor.a = 0.80;// + packedAlpha;
						temprgb.xyz = _BrushBuffer_P3DA[i].color.xyz * a + temprgb.rgb * (1.0 - a);
					}
			

					#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
					else
					if(// (prevColor.a == 0.0 || prevColor.a ==.4) &&
						_BrushBuffer_P3DA[i].brushMode.x == .4)
					{
						//TODO: you might want to vertex displace without overriding the .a
						outColor.a = .40;// + packedAlpha;
						temprgb.x = _BrushBuffer_P3DA[i].color.x * a + temprgb.r * (1.0 - a);
						//temprgb.xyz = _BrushBuffer_P3DA[i].color.xyz * a + temprgb.rgb * (1.0 - a);
					}
					#endif
					

					//int alphaFlag = (int)(floor(output.a*10)/10);
					//half r_g_b_mean = (output.r + output.g + output.b)/3;
					//half packedAlpha = 0;//floor(outColor.a)/100 + frac(outColor.a)/1000;
					#ifdef _BLEND_2_TEXTURES_WITH_PAINT_
						/*
						flags:
							.8 = just paint
							.7 = none
							.6 = blend 2 textures mode
							.5 = nothing
							.4 = vertex heightmap + paint
							.3 = none
							.2 = erase mesh mode

							.xyyyyyyyyy -> y = alpha
						*/
						//if(_PaintingParams_P3DA[i].w == .6 || _BrushBuffer_P3DA[i].brushMode.x == .6)
						else
						if(//	!(alphaFlag > .1 && alphaFlag < .9) &&
							//prevScreenColor.a >0.5 &&
							(	tex2D(_OverlayTex_Before_P3DA, mainUV).a > 0.0 ||
								prevColor.a == 0.0 || prevColor.a ==.6) &&
							_BrushBuffer_P3DA[i].brushMode.x == .6)
						{
							outColor.a = 0.60;// + packedAlpha;
							temprgb.xyz = _BrushBuffer_P3DA[i].color.xyz * a + temprgb.rgb * (1.0 - a);
						}	
					#endif

					#ifdef _ERASE_MESH_WITH_PAINT_
						//if(_PaintingParams_P3DA[i].w == .5 || _BrushBuffer_P3DA[i].brushMode.x == .5)
						else
						//if((prevScreenColor.a == 0 || prevScreenColor.a >.38 && prevScreenColor.a <.59) &&
						if(//(prevColor.a <.19) &&
							_BrushBuffer_P3DA[i].brushMode.x == .2)
						{
							outColor.a = 0.20;// + packedAlpha;

							temprgb.xyz = _BrushBuffer_P3DA[i].color.xyz * a + temprgb.rgb * (1.0 - a);
						}
					#endif
				//}


	
			
			}
		}

		/*
		#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
		half dott = dot(toolToPixelDirWS, normalws);
		if(dott < 0){
			outColor.a += 0.01;// 0.01 means this was painted on a backface
		}
		else{
			outColor.a = 0.02;// 0.02 means this was painted on a frontface
		}
		#endif
		*/


	}


	prevColor.rgb = temprgb;
	// TODO: have lerp _Init_P3DA????
	outColor.rgb = lerp(prevColor.rgb, max(outColor.rgb, prevColor.rgb), _Init_P3DA);
	///outColor.rgb = prevColor.rgb;
	///outColor = half4(0,0,1,1);

	//outColor.x = 0;
	//outColor.y = outdf.x;		
	//outColor.z = 0;
	//outColor = _PositionWS_P3DA[0]+_PositionWS_P3DA[1];
	
	
	_MainTexInternal_P3DA[mainUVRWT] = outColor;
	
	///_MainTexScreen_P3DA
	///clip(-1);
	///outColor = half4(0,0,1,1);
	return outColor;
	///return _MainTexInternal_P3DA[mainUVRWT];

}

half4 Paint3DAccumulatorFragmentLogic_P1(v2f_P3DA i){
	#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
	half3 pxPosWorld = (i.worldPos.xyz);
	#else
	half3 pxPosWorld = half3(1,0,1);// this shader branch should not be reached
	#endif


	half2 uv = i.uv;
	half2 mainUV = uv*_MainTex_P3DA_ST.xy + _MainTex_P3DA_ST.zw;
	int coordx = int((mainUV.x)*2048);
	int coordy = int((mainUV.y)*2048);
	int2 mainUVRWT = int2(coordx,coordy);
	half4 mainTex = tex2D(_MainTex_P3DA, mainUV);
	half4 output = _MainTexInternal_P3DA[mainUVRWT];

	half alphaFlag = frac(floor(output.a*10)/10);
	//output.a = 1;
	//#if defined(_BLEND_2_TEXTURES_WITH_PAINT_) || defined(_ERASE_MESH_WITH_PAINT_)
	//half r_g_b_mean = (output.r + output.g + output.b)/3;
	half r_g_b_max = max(output.r,max(output.g,output.b));
	//half r_g_b_add = output.r+output.g+output.b;
	
	//output.a = frac(floor(output.a*10)/10)*10 + (frac(output.a*10));
	//output = lerp(mainTex,_MainTexInternal_P3DA[mainUVRWT],clamp(((output.x+output.y+output.z)/3)*4,0,1));
	//output = lerp(mainTex,_MainTexInternal_P3DA[mainUVRWT], max(output.x,max(output.y,output.z)));
	output = lerp(mainTex,output, r_g_b_max);
	//half alpha = output.a;

	//half4 output = _MainTexInternal_P3DA[mainUVRWT];
	
	//#endif
	#ifdef _BLEND_2_TEXTURES_WITH_PAINT_
		/*
		flags:
			.8 = just paint
			.7 = none
			.6 = blend 2 textures mode
			.5 = nothing
			.4 = vertex heightmap + paint
			.3 = none
			.2 = erase mesh mode

			.xyyyyyyyyy -> y = alpha
		*/
		half4 overlayTexBefore = tex2D(_OverlayTex_Before_P3DA, mainUV);
		output.rgb = lerp(output.rgb, overlayTexBefore.rgb, overlayTexBefore.a);

		if(alphaFlag == .6)
		{
			half4 overlayTexAfter = tex2D(_OverlayTex_After_P3DA, mainUV);
			
			output.rgb = lerp(output.rgb, overlayTexAfter, saturate(r_g_b_max*overlayTexAfter.a)+_PaintingParams_P3DA[0].w);
			//r_g_b_max = max(output.r,max(output.g,output.b));
		}

	#endif

	#ifdef _ERASE_MESH_WITH_PAINT_
		//if(alphaFlag >= .41 && alphaFlag <= .59)//TODO: THIS IS SUPPOSED TO ALWAYS BE .5 DA FUQ. For .6 it works.
		//if(alphaFlag != .6 && alphaFlag > .10 && alphaFlag < .59)
		//if(alphaFlag > .38 && alphaFlag < .59)
		if(alphaFlag > 0.0 && 
		alphaFlag <= .22)
		//if(alphaFlag > .41 && alphaFlag < .59)
		{
			//output.a = 1-(r_g_b_add+_PaintingParams_P3DA[0].w);//r_g_b_max;
			//output.a = alpha = 1-r_g_b_max;
			//alpha = 0;
			output.rgba*= saturate(1-r_g_b_max*1.5);
			//output.a = 0.0;
			//output.a = alpha = 0;

			//alphaFlag = 0;
		}
		else if(alphaFlag == 0.0 ){
			output.a = 1;
		}
	#else

		if(alphaFlag == 0.0 ){
			output.a = 1;
		}
	#endif

	
	half3 temprgb = half3(0, 0, 0);// output.rgb;
	//half3 temprgb = _MainTexInternal_P3DA[mainUVRWT];
	half2 outdf = half2(1,0);

	#ifdef _GPU_COLOR_PICKER_ 
	half4 sampledColor = tex2D(_ColorPicker_P3DA, uv*_ColorPicker_P3DA_ST.xy + _ColorPicker_P3DA_ST.zw);
	#endif
	
	#ifdef _DISPLAY_BRUSH_VOLUME_
	for (int i = 0; i < BRUSH_COUNT_P3DA; i++)
	{

		half3 pos = pxPosWorld;

		half2 dims = _ConeShapeXY_P3DA.xy;

		//pos = opRotateTranslate(half4(pos.x, pos.y, pos.z, 1), _Matrix_iTR_P3DA[i]).xyz;// - _PositionWS_P3DA[i].xyz;
		//pos = pxPosWorld - _PositionWS_P3DA[i].xyz;//opRotateTranslate(half4( _PositionWS_P3DA[i].x,  _PositionWS_P3DA[i].y,  _PositionWS_P3DA[i].z, 0), _Matrix_iTR_P3DA[i]).xyz;
		//pos = pxPosWorld - opRotateTranslate(half4( _PositionWS_P3DA[i].x,  _PositionWS_P3DA[i].y,  _PositionWS_P3DA[i].z, 1), _Matrix_iTR_P3DA[i]).xyz;
		pos = pos - _PositionWS_P3DA[i];
		pos = opRotateTranslate(half4(pos.x, pos.y, pos.z, 1), _Matrix_iTR_P3DA[i]).xyz;// - _PositionWS_P3DA[i].xyz;
		//pos = opRotateTranslate(half4(1,1,1, 1), _Matrix_iTR_P3DA[i]).xyz;


		pos.z += _ConeShapeXY_P3DA.z;
		half fadeDist = pos.z * _ConeShapeXY_P3DA.w - pos.z;

		half coneDFv = sdCone(  pos / _ConeScale_P3DA, dims / _ConeScale_P3DA, _ConeClamp_P3DA)*_ConeScale_P3DA*_ConeScale2_P3DA;
		coneDFv = pow(coneDFv, _ConeScalePow_P3DA);


		half3 spherePos = pos;
		spherePos.z += _FadeShapeXY_P3DA.w;
		spherePos *= _FadeScale_P3DA;
		half sphereDFv = sdSphere( spherePos / _FadeShapeXY_P3DA.x, _FadeShapeXY_P3DA.z / _ConeScale_P3DA)*_FadeShapeXY_P3DA.x*_FadeShapeXY_P3DA.y;
		//sphereDFv = pow(sphereDFv, _FadeScalePow_P3DA);

		half3 cylinderPos = half3(pos.x, pos.z, pos.y);
		half cylinderDFv = sdCylinder( cylinderPos, _ColorSamplerVolume_P3DA.xyz)*_ColorSamplerVolume_P3DA.w;



		//half blend = opBlendSmin(coneDFv, sphereDFv, _FadeScale_P3DA.w);
		half2 blend = half2(opBlendSmax(coneDFv, sphereDFv, _BlendSubtraction_P3DA), i);



		blend = opS(blend - _TargetRingLocation_P3DA, blend);
		blend = (blend*blend* _TargetRingThickness_P3DA);


		outdf = opBlendSmin(outdf, blend, _BlendAddition_P3DA);// opI(coneDFv, sphereDFv);

		blend.x = 1 - max(blend.x, 0.1);
		blend.x = saturate(blend.x);

		#ifdef _GPU_COLOR_PICKER_
		if (
			sampledColor.a > 0.0
			)
		{
			half blendS = max(blend.x, (-cylinderDFv)*sampledColor.a);
			blend.x = blendS;

			half dist = distance(half2(_PositionSS_P3DA[i].x*_ColorSampleDist_P3DA_ST.z, _PositionSS_P3DA[i].y*_ColorSampleDist_P3DA_ST.w), _ColorSampleDist_P3DA_ST.xy);

			if ((cylinderDFv) < _ColorSampleThresh_P3DA
				&& (_PaintingParams_P3DA[i].y > 0 || _PaintingParams_P3DA[i].x > 0)
				&& dist < _ColorSampleDist_P3DA
				)
			{
			
				_BrushBuffer_P3DA[i].color.xyz = sampledColor.rgb;
				
			}
		}
		#endif

		half a = pow(blend.x, 0.8);
		half lv = a;// *0.5 + 0.5;
						//lv = pow(lv,0.85);
						//half3 ringCol = lerp(half3(1, 1, 1) - _BrushBuffer_P3DA[i].color.xyz, _BrushBuffer_P3DA[i].color.xyz, lv);
						//half3 ringCol = lerp(half3(1,1,1), _BrushBuffer_P3DA[i].color.xyz, lv);

		half4 ringCol = tex2D(_ToolOutlineTex_P3DA, lv.xx*_ToolOutlineTex_P3DA_ST.xy + _ToolOutlineTex_P3DA_ST.zw);
		ringCol.xyz = ringCol.xyz * ringCol.a + _BrushBuffer_P3DA[i].color * (1 - ringCol.a);

		/*
		if (distance(half2(_PositionSS_P3DA[0].x*_ColorSampleDist_P3DA_ST.z, _PositionSS_P3DA[0].y*_ColorSampleDist_P3DA_ST.w), _ColorSampleDist_P3DA_ST.xy) < _ColorSampleDist_P3DA)
		{
			ringCol.xyz = half3(1, 0, 0);
			//visible feedback for when you can sample?
		}
		*/
		temprgb.xyz = ringCol * a + temprgb.rgb * (1 - a);
		//half debug = distance(pxPosWorld,_PositionWS_P3DA[i]);
		//temprgb.xyz += debug*debug*debug*0.1;


		
	}
	#endif

	#ifdef _GPU_COLOR_PICKER_
	half4 colorPickerDisplayTex = tex2D(_ColorPickerDisplay_P3DA, uv*_ColorPicker_P3DA_ST.xy + _ColorPicker_P3DA_ST.zw);
	//dicolorPickerDisplayTexspTex = half4(0,0,0,1);
	//temprgb.xyz = colorPickerDisplayTex.rgb * colorPickerDisplayTex.a + temprgb.xyz * (1 - colorPickerDisplayTex.a);
	temprgb.xyz = (output.rgb*(1 - colorPickerDisplayTex.a) + colorPickerDisplayTex.rgb*colorPickerDisplayTex.a) + temprgb;
	#else
	temprgb.xyz = output.rgb + temprgb;
	#endif




	output.rgb = temprgb.xyz;
	//output.rgba = 1;
	//output.a = alpha;
	//output.rgb = pxPosWorld.xyz;
	//output.rgb = _MainTexInternal_P3DA[mainUV];


	//_MainTexInternal_P3DA[mainUV] = outColor;
	
	

	//output.r = 0;
	//output.g = distance(pxPosWorld, _PositionWS_P3DA[0]);
	//output.b = distance(pxPosWorld, _PositionWS_P3DA[1]);
	//output.r = outdf;
	_MainTexScreen_P3DA[mainUVRWT] = output;//_PositionWS_P3DA[0]+_PositionWS_P3DA[1];//output.rgba;
	//_MainTexScreen_P3DA[int2(coordx,coordy)] += half4(0.1,0.1,0.1,1);//_PositionWS_P3DA[0]+_PositionWS_P3DA[1];//output.rgba;
	//output = _MainTexScreen_P3DA[int2(coordx,coordy)];
	
	// _MainTexScreen_P3DA[int2(0,0)] = output.rgba;
	// _MainTexScreen_P3DA[int2(1,1)] = output.rgba;
	// _MainTexScreen_P3DA[int2(2,2)] = output.rgba;
	// _MainTexScreen_P3DA[int2(3,3)] = output.rgba;
	// _MainTexScreen_P3DA[int2(4,4)] = output.rgba;
	// _MainTexScreen_P3DA[int2(5,5)] = output.rgba;
	// _MainTexScreen_P3DA[int2(1,2)] = output.rgba;
	// _MainTexScreen_P3DA[int2(1,3)] = output.rgba;

	//clip(-1);
	//output = half4(mainUV.x, mainUV.y, 0,1);
	//uint2 temp = half2(0,0);
	//_MainTexScreen_P3DA.GetDimensions(temp.x, temp.y);
	//output = half4(temp.x, temp.y, 0, 1);
	//output = _MainTexScreen_P3DA[int2(coordx,coordy)];

	//_BrushBuffer_P3DA[i].color.xyz =  _Color_P3DA;
	//output = alphaFlag;
	
	return output;
}


//-------------------------------------------------------------------------------------

// UBER
inline half3 DeferredLightDir( in half3 worldPos )
{
	#ifndef USING_LIGHT_MULTI_COMPILE
		return _WorldSpaceLightPosCustom.xyz - worldPos.xyz * _WorldSpaceLightPosCustom.w;
	#else
		#ifndef USING_DIRECTIONAL_LIGHT
		return _WorldSpaceLightPosCustom.xyz - worldPos.xyz;
		#else
		return _WorldSpaceLightPosCustom.xyz;
		#endif
	#endif
}

//-------------------------------------------------------------------------------------
UnityLight MainLight ()
{
	UnityLight l = (UnityLight)0;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;

	return l;
}

UnityLight AdditiveLight (half3 lightDir, half atten)
{
	UnityLight l = (UnityLight)0;

	l.color = _LightColor0.rgb;
	l.dir = lightDir;
	l.dir = normalize(l.dir);

	// shadow the light
	l.color *= atten;
	return l;
}

UnityLight DummyLight ()
{
	UnityLight l = (UnityLight)0;
	l.color = 0;
	l.dir = half3 (0,1,0);

	return l;
}


UnityIndirect ZeroIndirect ()
{
	UnityIndirect ind;
	ind.diffuse = 0;
	ind.specular = 0;
	return ind;
}

//-------------------------------------------------------------------------------------

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

#if (defined(_PARALLAX_POM_ZWRITE) || defined(_POM_DISTANCE_MAP_ZWRITE) || defined(_POM_EXTRUSION_MAP_ZWRITE)) && !defined(ZWRITE)
	#define ZWRITE 1
#endif

// UBER
#if UNITY_SPECCUBE_BOX_PROJECTION || UNITY_LIGHT_PROBE_PROXY_VOLUME || defined(POM) || defined(_TRANSLUCENCY) || defined(_GLITTER) || defined(_SNOW) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP) || defined(_WETNESS) || defined(TRIPLANAR_SELECTIVE)
	#pragma multi_compile __ UNITY_REQUIRE_FRAG_WORLDPOS
	// 1
#else
	#pragma multi_compile __ UNITY_REQUIRE_FRAG_WORLDPOS
	// 0
#endif

#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
	#define IN_WORLDPOS(i) i.posWorld.xyz
	#define IN_WORLDPOSADD(i) i.posWorld.xyz
#else
	#define IN_WORLDPOS(i) half3(0,0,0)
	#define IN_WORLDPOSADD(i) half3(0,0,0)
#endif

#if ( defined(ZWRITE) || (defined(_SNOW) && (defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP))) ) && !defined(TRIPLANAR_SELECTIVE)
	#if !defined(RAYLENGTH_AVAILABLE)
		#define RAYLENGTH_AVAILABLE
	#endif
#endif

#if !defined(DEPTH_SEMANTIC)
	#if defined(SHADER_API_D3D11) && (SHADER_TARGET>=50) && CONSERVATIVE_DEPTH_WRITE
		#define DEPTH_SEMANTIC SV_DepthGreaterEqual
	#else
		#define DEPTH_SEMANTIC SV_Depth
	#endif
#endif

#define FRAGMENT_SETUP(x) FragmentCommonData x = \
	FragmentSetup(i.tex, eyeVec, worldNormal, i_viewDirForParallax, _TBN, IN_WORLDPOS(i), i.vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, tangentBasisScaled, SclCurv, blendFade, actH, diffuseTint, diffuseTint2); // UBER - additional params added

#define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
	FragmentSetup(i.tex, eyeVec, worldNormal, i_viewDirForParallax, _TBN, IN_WORLDPOSADD(i), i.vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, tangentBasisScaled, SclCurv, blendFade, actH, diffuseTint, diffuseTint2); // UBER - additional params added

struct FragmentCommonData
{
	half3 diffColor, specColor;
	// Note: smoothness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
	// Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
	// (UBER - comment: oneMinusReflectivity is like shader forge "1-specular monochrome")
	half oneMinusReflectivity, smoothness;
	half3 normalWorld, eyeVec, posWorld;
	half alpha;
	// UBER
	half3 pureAlbedo; // used for translucency (w/o energy conservation)
	half3 additionalEmission;
	// needed for SS
	#if defined(_PARALLAX_POM_SHADOWS) || defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS)
	half4 rayPos;
	half3x3 tanToWorld;
	#endif
	half2 texture2ObjectRatio;
	#if defined(_WETNESS)
	half Wetness;
	#endif	
	#if defined(_SNOW)
	half snowVal;
	half dissolveMaskValue;
	#endif	
	#if defined(ZWRITE)
	half rayLength;
	#endif
};

#ifndef UNITY_SETUP_BRDF_INPUT
	#define UNITY_SETUP_BRDF_INPUT SpecularSetup
#endif

void SetupUBER_VertexData_TriplanarWorld(half3 normalWorld, inout half4 i_tangentToWorldAndParallax0, inout half4 i_tangentToWorldAndParallax1, inout half4 i_tangentToWorldAndParallax2) {
	i_tangentToWorldAndParallax0.xyz = cross(normalWorld,cross(normalWorld, half3(0,0,1))); // tangents in world space
	i_tangentToWorldAndParallax0.xyz *= normalWorld.x<0 ? -1:1;
	i_tangentToWorldAndParallax1.xyz = cross(normalWorld,cross(normalWorld, half3(1,0,0)));
	i_tangentToWorldAndParallax1.xyz *= normalWorld.y<0 ? -1:1;
	i_tangentToWorldAndParallax2.xyz = cross(normalWorld,cross(normalWorld, half3(0,1,0)));
	i_tangentToWorldAndParallax2.xyz *= normalWorld.z>0 ? 1:-1;
}

void SetupUBER_VertexData_TriplanarLocal(half3 normalObject, inout half4 i_tangentToWorldAndParallax0, inout half4 i_tangentToWorldAndParallax1, inout half4 i_tangentToWorldAndParallax2, out half scaleX, out half scaleY, out half scaleZ) {
	scaleX = length(half3(unity_ObjectToWorld[0][0], unity_ObjectToWorld[1][0], unity_ObjectToWorld[2][0]));
	scaleY = length(half3(unity_ObjectToWorld[0][1], unity_ObjectToWorld[1][1], unity_ObjectToWorld[2][1]));
	scaleZ = length(half3(unity_ObjectToWorld[0][2], unity_ObjectToWorld[1][2], unity_ObjectToWorld[2][2]));

	i_tangentToWorldAndParallax0.xyz = cross(normalObject, cross(normalObject, half3(0,0,1))); // tangents in obj space
	i_tangentToWorldAndParallax0.xyz *= normalObject.x<0 ? -1:1;
	i_tangentToWorldAndParallax1.xyz = cross(normalObject, cross(normalObject, half3(1,0,0)));
	i_tangentToWorldAndParallax1.xyz *= normalObject.y<0 ? -1:1;
	i_tangentToWorldAndParallax2.xyz = cross(normalObject, cross(normalObject, half3(0,1,0)));
	i_tangentToWorldAndParallax2.xyz *= normalObject.z>0 ? 1:-1;
}

void SetupUBER(half4 i_SclCurv, half3 i_eyeVec, half3 i_posWorld, half3 i_posObject, inout half4 i_tex, inout half4 i_tangentToWorldAndParallax0, inout half4 i_tangentToWorldAndParallax1, inout half4 i_tangentToWorldAndParallax2, inout fixed4 vertex_color, out half actH, out half4 SclCurv, out half3 eyeVec, out half3 tangentBasisScaled, out half2 _ddx, out half2 _ddy, out half2 _ddxDet, out half2 _ddyDet, out half blendFade, out half3 i_viewDirForParallax, out half3x3 _TBN, out half3 worldNormal, out half4 texcoordsNoTransform) {
	
	// (out) compiled out when not used
	#if defined(GEOM_BLEND)
		actH=1; // for geom blend - default h is ceil value (but is supposed to be set later in parallax computation or triplanar init setup below)
	#else
		actH=0; // wetness
	#endif

	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			half3 normBlend=i_tex.xyz; // world normal
			half3 posUVZ=i_posWorld.xyz;
			half3 blendVal = abs(normBlend);
		#else
			half3 objScale=half3(i_tangentToWorldAndParallax0.w, i_tangentToWorldAndParallax1.w, i_tangentToWorldAndParallax2.w);
			half3 normObj=i_tex.xyz;
			half3 normBlend=normObj;
			half3 normObjScaled=normalize(normObj/objScale);
			half3 posUVZ=i_posObject.xyz*objScale;
			half3 blendVal = abs(normObjScaled);
		#endif
		half3 uvz = posUVZ.xyz*_MainTex_ST.xxx;
		#if RESOLVE_TRIPLANAR_HEIGHT_SEAMS
			half3 hVal = half3(tex2Dgrad(_ParallaxMap, (normBlend.x>0) ? uvz.zy : half2(-uvz.z,uvz.y) RESOLVE_SEAMS_X).PARALLAX_CHANNEL, tex2Dgrad(_ParallaxMap, (normBlend.y>0) ? uvz.xz : half2(-uvz.x,uvz.z) RESOLVE_SEAMS_Y).PARALLAX_CHANNEL, tex2Dgrad(_ParallaxMap, (normBlend.z>0) ? uvz.yx : half2(-uvz.y,uvz.x) RESOLVE_SEAMS_Z).PARALLAX_CHANNEL);
			#if defined(_TWO_LAYERS)
				half3 uvz2 = posUVZ.xyz*_DetailAlbedoMap_ST.xxx;
				#if defined(_PARALLAXMAP_2MAPS)
					half3 hVal2 = half3(tex2Dgrad(_ParallaxMap2, (normBlend.x>0) ? uvz2.zy : half2(-uvz2.z,uvz2.y) RESOLVE_SEAMS_X).PARALLAX_CHANNEL, tex2Dgrad(_ParallaxMap2, (normBlend.y>0) ? uvz2.xz : half2(-uvz2.x,uvz2.z) RESOLVE_SEAMS_Y).PARALLAX_CHANNEL, tex2Dgrad(_ParallaxMap2, (normBlend.z>0) ? uvz2.yx : half2(-uvz2.y,uvz2.x) RESOLVE_SEAMS_Z).PARALLAX_CHANNEL);
				#else
					half3 hVal2 = half3(tex2Dgrad(_ParallaxMap2, (normBlend.x>0) ? uvz2.zy : half2(-uvz2.z,uvz2.y) RESOLVE_SEAMS_X).PARALLAX_CHANNEL_2ND_LAYER, tex2Dgrad(_ParallaxMap2, (normBlend.y>0) ? uvz2.xz : half2(-uvz2.x,uvz2.z) RESOLVE_SEAMS_Y).PARALLAX_CHANNEL_2ND_LAYER, tex2Dgrad(_ParallaxMap2, (normBlend.z>0) ? uvz2.yx : half2(-uvz2.y,uvz2.x) RESOLVE_SEAMS_Z).PARALLAX_CHANNEL_2ND_LAYER);
				#endif
				hVal = lerp( hVal2, hVal, __VERTEX_COLOR_CHANNEL_LAYER);
			#endif
		#else
			half3 hVal = half3(tex2D(_ParallaxMap, (normBlend.x>0) ? uvz.zy : half2(-uvz.z,uvz.y) ).PARALLAX_CHANNEL, tex2D(_ParallaxMap, (normBlend.y>0) ? uvz.xz : half2(-uvz.x,uvz.z) ).PARALLAX_CHANNEL, tex2D(_ParallaxMap, (normBlend.z>0) ? uvz.yx : half2(-uvz.y,uvz.x) ).PARALLAX_CHANNEL);
			#if defined(_TWO_LAYERS)
				half3 uvz2 = posUVZ.xyz*_DetailAlbedoMap_ST.xxx;
				#if defined(_PARALLAXMAP_2MAPS)
					half3 hVal2 = half3(tex2D(_ParallaxMap2, (normBlend.x>0) ? uvz2.zy : half2(-uvz2.z,uvz2.y) ).PARALLAX_CHANNEL, tex2D(_ParallaxMap2, (normBlend.y>0) ? uvz2.xz : half2(-uvz2.x,uvz2.z) ).PARALLAX_CHANNEL, tex2D(_ParallaxMap2, (normBlend.z>0) ? uvz2.yx : half2(-uvz2.y,uvz2.x) ).PARALLAX_CHANNEL);
				#else
					half3 hVal2 = half3(tex2D(_ParallaxMap2, (normBlend.x>0) ? uvz2.zy : half2(-uvz2.z,uvz2.y) ).PARALLAX_CHANNEL_2ND_LAYER, tex2D(_ParallaxMap2, (normBlend.y>0) ? uvz2.xz : half2(-uvz2.x,uvz2.z) ).PARALLAX_CHANNEL_2ND_LAYER, tex2D(_ParallaxMap2, (normBlend.z>0) ? uvz2.yx : half2(-uvz2.y,uvz2.x) ).PARALLAX_CHANNEL_2ND_LAYER);
				#endif
				hVal = lerp( hVal2, hVal, __VERTEX_COLOR_CHANNEL_LAYER);
			#endif
		#endif
		
		blendVal += _TriplanarHeightmapBlendingValue*hVal;
		blendVal /= dot(blendVal,1);
		
		half maxXY = max(blendVal.x,blendVal.y);
		half3 tri_mask = (blendVal.x>blendVal.y) ? half3(1,0,0) : half3(0,1,0);
		tri_mask = (blendVal.z>maxXY) ? half3(0,0,1) : tri_mask;
		
		// inited here, reused in parallax function		
		#if defined(_TWO_LAYERS)
			// need to call GetH to set height blending between layers
			{
			half2 control=half2(__VERTEX_COLOR_CHANNEL_LAYER, 1-__VERTEX_COLOR_CHANNEL_LAYER);
			half2 hgt=half2(dot(hVal2, blendVal), dot(hVal, blendVal));
			control*=hgt+0.01;			// height evaluation
			control*=control; 			// compress
			control/=dot(control,1);	// normalize
			control*=control;			// compress
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
			half3 tangent_flip = tri_mask * ((normBlend.xyz<0) ? half3(1,1,1) : half3(-1,-1,-1));
		#else
			half3 tangent_flip = tri_mask * ((normBlend.xyz>0) ? half3(1,1,1) : half3(-1,-1,-1));
		#endif
		i_tex.xy = half2(tangent_flip.x, tri_mask.x)*posUVZ.zy + half2(tangent_flip.y, tri_mask.y)*posUVZ.xz + half2(tangent_flip.z, tri_mask.z)*posUVZ.yx;
		i_tex.zw = i_tex.xy*_DetailAlbedoMap_ST.xx;
		i_tex.xy *= _MainTex_ST.xx;
		texcoordsNoTransform=0; // secondary occlusion, not used - we have no real texcoords
	#else
		blendFade=0; // not used
		texcoordsNoTransform=i_tex;
		i_tex.zw = TRANSFORM_TEX(((_UVSec == 0) ? i_tex.xy : i_tex.zw), _DetailAlbedoMap);
		if (_UVSec == 2) {
			half3 posUVZ = i_posWorld.xyz;
			half3 blendVal = abs(i_tangentToWorldAndParallax2.xyz);

			half maxXY = max(blendVal.x, blendVal.y);
			half3 tri_mask = (blendVal.x>blendVal.y) ? half3(1, 0, 0) : half3(0, 1, 0);
			tri_mask = (blendVal.z>maxXY) ? half3(0, 0, 1) : tri_mask;

			half2 uv2World = tri_mask.x*posUVZ.zy + tri_mask.y*posUVZ.xz + tri_mask.z*posUVZ.yx;
			i_tex.zw = TRANSFORM_TEX(uv2World, _DetailAlbedoMap);
		}
		i_tex.xy = TRANSFORM_TEX(i_tex.xy, _MainTex); // Always source from uv0
	#endif
	
	// UBER
	#if defined(TRIPLANAR_SELECTIVE)
		half3 _ddx3=ddx(uvz);
		_ddx = tri_mask.xx*_ddx3.zy + tri_mask.yy*_ddx3.xz + tri_mask.zz*_ddx3.yx;
		
		half3 _ddy3=ddy(uvz);
		_ddy = tri_mask.xx*_ddy3.zy + tri_mask.yy*_ddy3.xz + tri_mask.zz*_ddy3.yx;
		
		_ddxDet=_ddx/_MainTex_ST.xx*_DetailAlbedoMap_ST.xx;
		_ddyDet=_ddy/_MainTex_ST.xx*_DetailAlbedoMap_ST.xx;
	#elif defined(POM) || defined(_SNOW) || defined(_GLITTER) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		_ddx=ddx(i_tex.xy);
		_ddy=ddy(i_tex.xy);
		_ddxDet=ddx(i_tex.zw);
		_ddyDet=ddy(i_tex.zw);
	#else
		_ddx=0;
		_ddy=0;
		_ddxDet=0;
		_ddyDet=0;
	#endif	

	#if defined(RAYLENGTH_AVAILABLE)
		// we need to go from tangent to world space for zwrite and parallaxed snow (actually when snow is mapped in worldspace)
		tangentBasisScaled=half3(length(i_tangentToWorldAndParallax0.xyz), length(i_tangentToWorldAndParallax1.xyz), length(i_tangentToWorldAndParallax2.xyz));
		i_tangentToWorldAndParallax0.xyz/=tangentBasisScaled.x; // here we can normalize it
		i_tangentToWorldAndParallax1.xyz/=tangentBasisScaled.y;
		i_tangentToWorldAndParallax2.xyz/=tangentBasisScaled.z;
//		tangentBasisScaled=0.4;
	#else
		tangentBasisScaled=1; // not used
	#endif

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
			
			eyeVec = normalize(i_eyeVec);
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
				i_viewDirForParallax=normalize( mul(rotation, ObjSpaceViewDir(half4(i_posObject,1)) ) );
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
	#else
		#if defined(_PARALLAXMAP) || defined(_PARALLAXMAP_2MAPS) || defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
			i_viewDirForParallax=normalize( half3(i_tangentToWorldAndParallax0.w, i_tangentToWorldAndParallax1.w, i_tangentToWorldAndParallax2.w));
		#else
			i_viewDirForParallax=half3(0,0,0);
		#endif	
		_TBN=ExtractTangentToWorldPerPixel(i_tangentToWorldAndParallax0, i_tangentToWorldAndParallax1, i_tangentToWorldAndParallax2);
		worldNormal=i_tangentToWorldAndParallax2.xyz;
	#endif
}

inline FragmentCommonData SpecularSetup (half4 i_tex, fixed4 vertex_color, half2 _ddx, half2 _ddy, half2 _ddxDet, half2 _ddyDet, half Wetness, half blendFade, half3 diffuseTint, half3 diffuseTint2) // UBER (params added)
{ 
	half4 specGloss = SpecularGloss(i_tex, vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, Wetness); // UBER - pass 4 components (zw for detail tiling)
	half3 specColor = specGloss.rgb;
	half smoothness = specGloss.a;

	half oneMinusReflectivity;

	half3 additionalEmission=0;
	half3 pureAlbedo=Albedo(i_tex, vertex_color, Wetness, _ddx, _ddy, _ddxDet, _ddyDet, /* inout */ additionalEmission, blendFade, diffuseTint, diffuseTint2);
	half3 diffColor = EnergyConservationBetweenDiffuseAndSpecular (pureAlbedo, specColor, /*out*/ oneMinusReflectivity);

	FragmentCommonData o = (FragmentCommonData)0;
	o.diffColor = diffColor;
	o.specColor = specColor;
	o.pureAlbedo = pureAlbedo;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.smoothness = smoothness;
	o.additionalEmission = additionalEmission;
	return o;
}

inline FragmentCommonData MetallicSetup (half4 i_tex, fixed4 vertex_color, half2 _ddx, half2 _ddy, half2 _ddxDet, half2 _ddyDet, half Wetness, half blendFade, half3 diffuseTint, half3 diffuseTint2) // UBER - vertex_color, derivatives
{
	half2 metallicGloss = MetallicGloss(i_tex, vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, Wetness); // UBER - pass 4 components (zw for detail tiling)
	half metallic = metallicGloss.x;
	half smoothness = metallicGloss.y;

	half oneMinusReflectivity;
	half3 specColor;

	half3 additionalEmission=0;
	half3 pureAlbedo=Albedo(i_tex, vertex_color, Wetness, _ddx, _ddy, _ddxDet, _ddyDet, /* inout */ additionalEmission, blendFade, diffuseTint, diffuseTint2);
	half3 diffColor = DiffuseAndSpecularFromMetallic (pureAlbedo, metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

	FragmentCommonData o = (FragmentCommonData)0;
	o.pureAlbedo = pureAlbedo;
	o.diffColor = diffColor;
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.smoothness = smoothness;
	o.additionalEmission = additionalEmission;
	return o;
} 

// UBER - Translucency
#if defined(_TRANSLUCENCY)
half3 Translucency(FragmentCommonData s, UnityLight light, half translucency_thickness, fixed4 vertex_color) {

	half4 TranslucencyColor=_TranslucencyColor;
	#if defined(_TWO_LAYERS)
		TranslucencyColor=lerp(_TranslucencyColor2, _TranslucencyColor, __VERTEX_COLOR_CHANNEL_LAYER);
	#endif

	#if defined(_SNOW)
		half4 translucencyColor=lerp(TranslucencyColor,_SnowTranslucencyColor, s.snowVal);
	#else
		half4 translucencyColor=TranslucencyColor;
	#endif
	#ifdef USING_DIRECTIONAL_LIGHT
		half tLitDot=saturate(dot( (light.dir + s.normalWorld*_TranslucencyNormalOffset), s.eyeVec) );
	#else
		half3 lightDirectional=normalize(_WorldSpaceLightPos0.xyz - _WorldSpaceCameraPos.xyz);
		light.dir=normalize(lerp(light.dir, lightDirectional, _TranslucencyPointLightDirectionality));
		half tLitDot=saturate( dot( (light.dir + s.normalWorld*_TranslucencyNormalOffset), s.eyeVec) );
	#endif
	
	tLitDot = exp2( -_TranslucencyExponent*(1-tLitDot) ) * _TranslucencyStrength;
	half NDotL = abs(dot(light.dir, s.normalWorld));
	tLitDot *= lerp( 1, NDotL, _TranslucencyNDotL );
	
	half3 pureAlbedo;
	#if defined(_SNOW)
		pureAlbedo=lerp(s.pureAlbedo.rgb, _SnowColorAndCoverage.rgb, s.snowVal);
	#else
		pureAlbedo=s.pureAlbedo.rgb;
	#endif
	half translucencyOcclusion = lerp( 1, translucency_thickness, _TranslucencyOcclusion );
	#if defined(TRANSLUCENCY_VERTEX_COLOR_CHANNEL)
		translucencyOcclusion*=vertex_color.TRANSLUCENCY_VERTEX_COLOR_CHANNEL;
	#endif
	half translucencyAtten = (tLitDot+_TranslucencyConstant*(NDotL+0.1))*translucencyOcclusion;
	#if defined(UBER_TRANSLUCENCY_PER_LIGHT_ALPHA)
	translucencyAtten*=_LightColor0.a;
	#endif
	
	return translucencyAtten * pureAlbedo.rgb * translucencyColor.rgb;
}
#endif

// UBER - Glitter
#if defined(_GLITTER) 
void Glitter(inout FragmentCommonData s, half2 _uv, half2 _ddxDet, half2 _ddyDet, half3 posWorld, fixed4 vertex_color, half glitter_thickness) {
	half2 glitterUV_Offset = (_WorldSpaceCameraPos.xz+posWorld.zx+_WorldSpaceCameraPos.yy+posWorld.yy)*GLITTER_ANIMATION_FREQUENCY*_GlitterTiling;
	half MIP_filterVal = _GlitterTiling*exp2(_GlitterFilter);
	half2 _ddxDetBias=_ddxDet*MIP_filterVal;
	half2 _ddyDetBias=_ddyDet*MIP_filterVal;
	half sparkle=tex2Dgrad(_SparkleMap, _uv*_GlitterTiling + glitterUV_Offset, _ddxDetBias, _ddyDetBias).r;
	half sparkle2=tex2Dgrad(_SparkleMap, _uv*_GlitterTiling - glitterUV_Offset, _ddxDetBias, _ddyDetBias).r;
	sparkle*=lerp(sparkle, 1, _GlitterDensity);
	half sparkleDenseVal=sparkle*sparkle2;// depends on density of sparkle mask
	sparkle2*=lerp(sparkle2, 1, _GlitterDensity);
	
	half3 _color=lerp( half3(0.9,0.9,0.9), abs(frac(s.normalWorld*4)*2-1), _GlitterColorization) + half3(0.5,0.5,0.5);
	_color*=_color;
	
	half sparkleStrengh=sparkle2*sparkle*GLITTER_AMPLIFY; // GLITTER_AMPLIFY defined in UBER_StandardConfig.cginc
	#if defined(_SNOW)
		sparkleStrengh*=s.dissolveMaskValue;
	#endif
	#if defined(VERTEX_COLOR_CHANNEL_GLITTER)
		sparkleStrengh*=vertex_color.VERTEX_COLOR_CHANNEL_GLITTER;
	#endif
	
	_color*=sparkleStrengh*glitter_thickness;
	
	half4 GlitterColor=_GlitterColor;
	#if defined(_TWO_LAYERS)
		GlitterColor=lerp(_GlitterColor2, GlitterColor, __VERTEX_COLOR_CHANNEL_LAYER);	
	#endif
	#if defined(_SNOW)
		half4 SnowGlitterColor = _SnowGlitterColorFromGlobal ? _UBER_GlobalSnowGlitterColor : _SnowGlitterColor;
		_color*=lerp(GlitterColor.rgb, SnowGlitterColor.rgb, s.snowVal);
		half GlitterSmoothnessStrength=lerp(GlitterColor.a, SnowGlitterColor.a, s.snowVal);
	#else
		_color*=GlitterColor.rgb;
		half GlitterSmoothnessStrength=GlitterColor.a;
	#endif
	
	#if defined(VERTEX_COLOR_CHANNEL_GLITTER)
		GlitterSmoothnessStrength*=vertex_color.VERTEX_COLOR_CHANNEL_GLITTER;
	#endif
	
	GlitterSmoothnessStrength*=glitter_thickness;
		
	s.smoothness+=min(GLITTER_SMOOTHNESS_GAIN_LIMIT, sparkleDenseVal*GLITTER_AMPLIFY*GlitterSmoothnessStrength); // GLITTER_SMOOTHNESS_GAIN_LIMIT defined in UBER_StandardConfig.cginc
	s.smoothness=saturate(s.smoothness);
	s.specColor+=_color;
}
#endif

// UBER: inout added (parallaxed i_tex is not propagated outside FragmentSetup function thus emission/occlusion calculated was not parallaxed
inline FragmentCommonData FragmentSetup (inout half4 i_tex, half3 i_eyeVec, half3 i_normalWorld, inout half3 i_viewDirForParallax, inout half3x3 i_tanToWorld, half3 i_posWorld, inout fixed4 vertex_color, half2 _ddx, half2 _ddy, half2 _ddxDet, half2 _ddyDet, half3 tangentBasisScaled, half4 SclCurv, half blendFade, half actH, half3 diffuseTint, half3 diffuseTint2) // UBER - additional params added
{
	half4 rayPos=0; // rayPos from POM parallax (the place we hit the surface in tangent space)
	half2 texture2ObjectRatio=0; // computed in Parallax() we need it for self-shadowing too
	half rayLength=0;
	
	// UBER - snow level - set in NormalInTangentSpace() (might be compiled out when not used)
	// (compiled out when not used)
	half _snow_val = 0;
	half _snow_val_nobump = 0;
	half dissolveMaskValue=0;
	#if defined(_SNOW)
		_snow_val = _SnowColorAndCoverage.a*__VERTEX_COLOR_CHANNEL_SNOW;
		_snow_val *= saturate((i_posWorld.y-_SnowHeightThreshold)/_SnowHeightThresholdTransition);
		_snow_val_nobump = saturate( _snow_val - (1-i_normalWorld.y)*_SnowSlopeDamp );
		
		half snowMaskLargeScale=tex2D(_RippleMap, i_posWorld.xz*SNOW_LARGE_MASK_TILING).g*0.3;
		_snow_val_nobump -= lerp(snowMaskLargeScale, 0, _snow_val_nobump);
		_snow_val_nobump = saturate(_snow_val_nobump);
		half _snow_val_nobump_per_material=_snow_val_nobump; // used later for wet coverage with snow (melting snow)
		_snow_val_nobump *= _SnowLevelFromGlobal ? (1-_UBER_GlobalSnowDamp) : 1;
		_snow_val=_snow_val_nobump;
	#endif		
	
	#if defined(_WETNESS_RIPPLES) || defined(_WETNESS_DROPLETS) || defined(_WETNESS_FULL)
		half2 i_tex_wet=i_posWorld.xz;
		//half3 viewDir=normalize(i_posWorld-_WorldSpaceCameraPos);
		//i_tex_wet-=(1-_WetnessLevel/1.25)*viewDir.xz/viewDir.y; // tutaj b. trudno przeliczyc z world do tangent aby mnoznik po lewej sie zgadzal
		half2 wetUV=i_tex_wet.xy;
		half2 wetDDX=ddx(wetUV);
		half2 wetDDY=ddy(wetUV);
	#endif

	#if defined(DISTANCE_MAP)
		half3 _norm=half3(0,0,1); // will be set in ParallaxPOMDistance() function
		i_tex = ParallaxPOMDistance(i_tex, i_viewDirForParallax, i_posWorld, vertex_color, _ddx, _ddy, _snow_val_nobump, /* inout */ actH, /* inout */ rayPos, /* inout */ texture2ObjectRatio, /* inout */ rayLength, tangentBasisScaled, SclCurv, /* inout */ _norm);
	#elif defined(EXTRUSION_MAP)
		half3 _norm=half3(0,0,1); // will be set in ParallaxPOMExtrusion() function
		i_tex = ParallaxPOMExtrusion(i_tex, i_viewDirForParallax, i_posWorld, vertex_color, _ddx, _ddy, _snow_val_nobump, /* inout */ actH, /* inout */ rayPos, /* inout */ texture2ObjectRatio, /* inout */ rayLength, tangentBasisScaled, SclCurv, /* inout */ _norm);
	#else
		// (i_tanToWorld can be modified by silhouette tracing)
		// NOTE: i_viewDirForParallax is object space view dir here when SILHOUETTE_CURVATURE_MAPPED is defined, will be put into tan space inside parallax function
		i_tex = Parallax(i_tex, /* inout */ i_viewDirForParallax, /* inout */ i_tanToWorld, i_posWorld, /* inout */ vertex_color, _ddx, _ddy, _snow_val_nobump, /* inout */ actH, /* inout */ rayPos, /* inout */ texture2ObjectRatio, /* inout */ rayLength, tangentBasisScaled, SclCurv, blendFade); // UBER - i_tanToWorld, i_posWorld, vertex_color, ddx, ddy, actH, ... added
	#endif
	
	// UBER
	#if defined(_SNOW)
		// needed later in case of snow covering wet surface
		half2 uvDet_no_refr=i_tex.zw;
	#else
		half2 uvDet_no_refr=0;
	#endif
	
	// wet ripples normalmap
	#if defined(_WETNESS)
		half3 wetNorm=half3(0,0,1); 
		half rippleMIPsel = 0;
		half Wetness = 0;
		half WetnessConst = 0;
		half deepWetFct = 0;
		half wetMask = 0;
		#if _DETAIL || defined(_DETAIL_SIMPLE)		
			#if defined(_TWO_LAYERS)
				//wetMask=0; // no detail mask available
			#else
				wetMask=0.1-tex2Dp(_DetailMask, i_tex.zw*_WetnessUVMult, _ddx*_WetnessUVMult, _ddy*_WetnessUVMult).r*0.1;
			#endif
		#endif
		#if defined(_SNOW)
			half additionalWetDamp=_WetnessMergeWithSnowPerMaterial ? _snow_val_nobump_per_material : 1;
			wetMask=wetMask*0.7+snowMaskLargeScale*0.3;
		#else
			half additionalWetDamp=1;
		#endif
		Wetness=saturate( (__VERTEX_COLOR_CHANNEL_WETNESS*additionalWetDamp*_WetnessLevel*(_WetnessLevelFromGlobal ? (1-_UBER_GlobalDry) : 1)-actH-wetMask) * 4 );
		WetnessConst = saturate( (__VERTEX_COLOR_CHANNEL_WETNESS*additionalWetDamp*_WetnessConst*(_WetnessConstFromGlobal ? (1 - _UBER_GlobalDryConst) : 1) + 0.2*_WetnessConst - wetMask * 2) );

		#if defined(_SNOW)
			// snow override wetness
			// (we skip it - let user controll it via vertex colors or global controller)
			//Wetness*=saturate(1-_snow_val*2);
			half refrSnowDamp=1;//saturate(1-_snow_val*8);
		#endif	
		deepWetFct=saturate((Wetness-0.5)*2);	
		
		UBER_Time = _WetnessFlowGlobalTime ? UBER_Time : _Time;
		
		#if defined(_WETNESS_RIPPLES) || defined(_WETNESS_FULL)
		half RippleStrength = _RippleStrengthFromGlobal ? _UBER_RippleStrength*_RippleStrength : _RippleStrength;
		{
			half2 rippleUV=wetUV*_RippleTiling;
			half2 rippleDDX=wetDDX*_RippleTiling;
			half2 rippleDDY=wetDDY*_RippleTiling;

			half animSpeed=_RippleAnimSpeed;
			
			#if WET_FLOW
				// hi freq
				half2 timeOffset = UBER_Time.yy*animSpeed;
				half4 wetVal = tex2Dgrad(_RippleMap, rippleUV + timeOffset, rippleDDX, rippleDDY);
				wetVal += tex2Dgrad(_RippleMap, rippleUV - timeOffset*1.2, rippleDDX, rippleDDY);
				wetVal -= 1; // -1..1
				// lo freq
				rippleUV *= 0.25;
				rippleDDX *= 0.25;
				rippleDDY *= 0.25;
				timeOffset *= 0.5;
				timeOffset.x = -timeOffset.x; // lo freq waves animates across
				half4 wetVal2 = tex2Dgrad(_RippleMap, rippleUV + timeOffset, rippleDDX, rippleDDY);
				wetVal2 += tex2Dgrad(_RippleMap, rippleUV - timeOffset*1.3, rippleDDX, rippleDDY);
				wetVal2 -= 1; // -1..1
				// combine hi+lo freq
				wetVal = (0.5*wetVal + 0.5*wetVal2)*0.5+0.5; // 0..1 for unpack
				wetNorm = UnpackScaleNormal(wetVal, RippleStrength*__VERTEX_COLOR_CHANNEL_WETNESS_RIPPLES);
				half slopeRippleDamp = abs(i_normalWorld.y);
				slopeRippleDamp *= slopeRippleDamp;
				wetNorm.xy *= slopeRippleDamp;
				//wetNorm=normalize(wetNorm);
			#else
				half _Tim=frac(UBER_Time.x*_FlowCycleScale)*2;
				half ft=abs(frac(_Tim)*2 - 1);
				
				#if defined(WATER_FLOW_DIRECTION_FROM_NORMALMAPS)
					#if defined(_TWO_LAYERS)
						half FlowNormStrength = _WetnessNormStrength*saturate(1-i_normalWorld.y*0.5)*saturate(actH*2.5-_WetnessLevel);
						half3 mainBumpsInTangentSpace =  UnpackScaleNormal( tex2Dlod(_BumpMap, half4(i_tex.xy,_WetnessNormMIP.xx)) , FlowNormStrength ) ;
						half3 mainBumpsInTangentSpace2 =  UnpackScaleNormal( tex2Dlod(_BumpMap, half4(i_tex.xy,_WetnessNormMIP.xx)) , FlowNormStrength ) ;
						mainBumpsInTangentSpace = lerp( mainBumpsInTangentSpace2, mainBumpsInTangentSpace, __VERTEX_COLOR_CHANNEL_LAYER );
						mainBumpsInTangentSpace = normalize(mainBumpsInTangentSpace);
					#else
						half3 mainBumpsInTangentSpace = normalize( UnpackScaleNormal( tex2Dlod(_BumpMap, half4(i_tex.xy,_WetnessNormMIP.xx)) , _WetnessNormStrength*saturate(1-i_normalWorld.y*0.5)*saturate(actH*2.5-_WetnessLevel) ) );
					#endif
					half2 slopeXZ = mul(mainBumpsInTangentSpace, i_tanToWorld).xz;
				#else
					half2 slopeXZ = i_normalWorld.xz;
				#endif
				
				half2 flowSpeed=clamp((i_normalWorld.y>0 ? -4:4) * slopeXZ+0.04,-1,1)/_FlowCycleScale;
				flowSpeed*=animSpeed*_RippleTiling;
				
				wetNorm = UnpackScaleNormal(tex2Dgrad(_RippleMap, rippleUV+frac(_Tim.xx)*flowSpeed, rippleDDX, rippleDDY) , RippleStrength*__VERTEX_COLOR_CHANNEL_WETNESS_FLOW);
				wetNorm = lerp(wetNorm, UnpackScaleNormal(tex2Dgrad(_RippleMap, rippleUV+frac(_Tim.xx+0.5)*flowSpeed*1.25, rippleDDX, rippleDDY) , RippleStrength*__VERTEX_COLOR_CHANNEL_WETNESS_FLOW), ft);
				wetNorm.xy*=abs(i_normalWorld.y);//1-exp2(-12*abs(i_normalWorld.y));
				//wetNorm=normalize(wetNorm);
			#endif
			#if defined(_SNOW)
//				wetNorm.xy*=refrSnowDamp;
			#endif
						
			rippleDDX*=_RippleMap_TexelSize.zw*16;
			rippleDDY*=_RippleMap_TexelSize.zw*16;
			half rippleD = max( dot( rippleDDX, rippleDDX ), dot( rippleDDY, rippleDDY ) );
			rippleMIPsel = max(0, log2(rippleD)); // uzyte ponizej do filtrowania IBL
			// additional grazing angle filtering
			half _Fresnel=exp2(-8.65*i_viewDirForParallax.z); // (1-x)^5 aprrox.
			rippleMIPsel += _Fresnel*10;
			
			half rippleReduceRef=saturate(1-(rippleMIPsel*_WetnessSpecGloss.a*RippleStrength*_RippleSpecFilter)*0.5);
			half2 ripple_refraction_offset=rippleReduceRef*_RippleRefraction*wetNorm.xy*0.05*deepWetFct;
			 
			i_tex.xy+=ripple_refraction_offset;
			i_tex.zw+=ripple_refraction_offset*_DetailAlbedoMap_ST.xy/_MainTex_ST.xy;
		}
		#endif

		#if defined(_WETNESS_DROPLETS) || defined(_WETNESS_FULL)
		half2 droplets_refraction_offset;	
		{
			half RainIntensity=_RainIntensityFromGlobal ? (1-_UBER_GlobalRainDamp)*_RainIntensity : _RainIntensity;
		
			half2 rippleUV=wetUV*_DropletsTiling;
			half2 rippleDDX=wetDDX*_DropletsTiling;
			half2 rippleDDY=wetDDY*_DropletsTiling;
		
			fixed4 Ripple = tex2Dp(_DropletsMap, rippleUV, rippleDDX, rippleDDY);
			Ripple.xy = Ripple.xy * 2 - 1;
		
			half DropFrac = frac(Ripple.w + _Time.x*_DropletsAnimSpeed);
			half TimeFrac = DropFrac - 1.0f + Ripple.z;
			half DropFactor = saturate(RainIntensity - DropFrac);
			half FinalFactor = DropFactor * Ripple.z * sin( clamp(TimeFrac * 9.0f, 0.0f, 3.0f) * 3.1415);
			half2 droplets_refraction_offset = Ripple.xy * FinalFactor;
			
			rippleUV+=half2(0.25,0.25);
			Ripple = tex2Dp(_DropletsMap, rippleUV, rippleDDX, rippleDDY);
			Ripple.xy = Ripple.xy * 2 - 1;
		
			DropFrac = frac(Ripple.w + _Time.x*_DropletsAnimSpeed);
			TimeFrac = DropFrac - 1.0f + Ripple.z;
			DropFactor = saturate(RainIntensity - DropFrac);
			FinalFactor = DropFactor * Ripple.z * sin( clamp(TimeFrac * 9.0f, 0.0f, 3.0f) * 3.1415);
			droplets_refraction_offset += Ripple.xy * FinalFactor;
			
			droplets_refraction_offset*=__VERTEX_COLOR_CHANNEL_WETNESS_DROPLETS*(deepWetFct*1.0+WetnessConst*0.0) * 0.1f * abs(i_normalWorld.y);
			wetNorm.xy+=droplets_refraction_offset*10;
			//wetNorm=normalize(wetNorm);
			droplets_refraction_offset*=_RippleRefraction;
			
			#if defined(_SNOW)
				droplets_refraction_offset*=refrSnowDamp;
			#endif
			i_tex.xy+=droplets_refraction_offset;
			i_tex.zw+=droplets_refraction_offset*_DetailAlbedoMap_ST.xy/_MainTex_ST.xy;
		}
		#endif
		
	#else
		// wetness not used
		half Wetness = 0; // compiled out (not used, even if passed to functions)
		half deepWetFct = 0;
		half3 wetNorm = 0;
		half rippleMIPsel = 0;
	#endif	
			
	half3 eyeVec = i_eyeVec;
	#if defined(TRIPLANAR_SELECTIVE) && defined(_TRIPLANAR_WORLD_MAPPING)
		// already normalized
	#else
		{
		eyeVec = Unity_SafeNormalize(eyeVec);
		}
	#endif			
			
	//
	#if _NORMALMAP
		// _snow_val_nobump, i_tanToWorld - needed for snow in NormalInTangentSpace()
		#if defined(_SNOW) && ENABLE_SNOW_WORLD_MAPPING
			#if defined(RAYLENGTH_AVAILABLE)
				half2 snowUV=rayLength*eyeVec.xz + i_posWorld.xz;
			#else
				half2 snowUV=i_posWorld.xz;
			#endif
			half2 _ddxSnow=ddx(snowUV);
			half2 _ddySnow=ddy(snowUV);
			if (_SnowWorldMapping) {
				uvDet_no_refr=snowUV;
			} else {
				_ddxSnow=_ddxDet;
				_ddySnow=_ddyDet;
			}
		#else
			half2 _ddxSnow=_ddxDet;
			half2 _ddySnow=_ddyDet;
		#endif
		#if defined(DISTANCE_MAP)
			half3 normalWorld = mul(BlendNormals(_norm, NormalInTangentSpace(i_tex, uvDet_no_refr, i_viewDirForParallax, _snow_val_nobump, i_tanToWorld, vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, _ddxSnow, _ddySnow, wetNorm, deepWetFct, /* inout */ _snow_val, /* inout */ dissolveMaskValue, blendFade, i_posWorld)), i_tanToWorld);
			#if defined(_SNOW)
				_snow_val = saturate( _snow_val - (1-normalWorld.y)*_SnowSlopeDamp );
			#endif
		#elif defined(EXTRUSION_MAP)
			// take main normal from _norm that has been set in specialised parallax function (we needed normal there for texturing sidewalls)
			half3 normalWorld = mul(NormalInTangentSpace(_norm, i_tex, uvDet_no_refr, i_viewDirForParallax, _snow_val_nobump, i_tanToWorld, vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, _ddxSnow, _ddySnow, wetNorm, deepWetFct, /* inout */ _snow_val, /* inout */ dissolveMaskValue, blendFade, i_posWorld), i_tanToWorld);
		#else
			#if defined(TRIPLANAR_SELECTIVE)
				half blendFadeWithNormalSharpness = lerp(blendFade, 1-exp2(-9*blendFade), _TriplanarNormalBlendSharpness);
				half3 normInTangentSpace=NormalInTangentSpace(i_tex, uvDet_no_refr, i_viewDirForParallax, _snow_val_nobump, i_tanToWorld, vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, _ddxSnow, _ddySnow, wetNorm, deepWetFct, /* inout */ _snow_val, /* inout */ dissolveMaskValue, blendFade, i_posWorld);
				#if defined(_SNOW) 
					// we don't interpolate normals towards (0,0,1) in case of snow coverage in world space - simply we don't have seams there, so no "blendFade" process is needed out there
					blendFadeWithNormalSharpness = _SnowWorldMapping ? lerp(blendFadeWithNormalSharpness, 1, _snow_val) : blendFadeWithNormalSharpness;
				#endif
				normInTangentSpace = lerp(half3(0,0,1), normInTangentSpace, blendFadeWithNormalSharpness );
				half3 normalWorld = mul(normInTangentSpace, i_tanToWorld);
			#else
				half3 normalWorld = mul(NormalInTangentSpace(i_tex, uvDet_no_refr, i_viewDirForParallax, _snow_val_nobump, i_tanToWorld, vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, _ddxSnow, _ddySnow, wetNorm, deepWetFct, /* inout */ _snow_val, /* inout */ dissolveMaskValue, blendFade, i_posWorld), i_tanToWorld);
			#endif
		#endif
		normalWorld = normalize(normalWorld);
	#else
		// Should get compiled out, isn't being used in the end.
		half3 normalWorld = i_normalWorld;
		#if defined(DISTANCE_MAP)
			normalWorld=mul(_norm, i_tanToWorld);
		#endif
	#endif
	
	
	// alpha
	#if defined(GEOM_BLEND)
		// RTP's geom blend
		half alpha;
		#if defined(BLENDING_HEIGHT)
			half2 globalUV=i_posWorld.xz-_TERRAIN_PosSize.xy;
			globalUV/=_TERRAIN_PosSize.zw;	
			half2 aux=i_posWorld.xz-_TERRAIN_PosSize.xy+_TERRAIN_Tiling.zw;
			aux.xy/=_TERRAIN_Tiling.xy;
			
			half4 terrain_coverage=tex2D(_TERRAIN_Control, globalUV);
			half4 splat_control1=terrain_coverage * tex2D(_TERRAIN_HeightMap, aux.xy) * vertex_color.VERTEX_COLOR_CHANNEL_GEOM_BLEND;
			half4 splat_control2=half4( (actH+0.01) , 0, 0, 0) * (1-vertex_color.VERTEX_COLOR_CHANNEL_GEOM_BLEND);
			
			half blend_coverage=dot(terrain_coverage, 1);
			if (blend_coverage>0.1) {
			
				splat_control1*=splat_control1;
				splat_control1*=splat_control1;
				splat_control2*=splat_control2;
				splat_control2*=splat_control2;
				
				half normalize_sum=dot(splat_control1, half4(1,1,1,1))+dot(splat_control2, half4(1,1,1,1));
				splat_control1 /= normalize_sum;
				splat_control2 /= normalize_sum;		
				
				alpha=dot(splat_control2,1);
				alpha=lerp(1-vertex_color.VERTEX_COLOR_CHANNEL_GEOM_BLEND, alpha, saturate((blend_coverage-0.1)*4) );
			} else {
				alpha=1-vertex_color.VERTEX_COLOR_CHANNEL_GEOM_BLEND;
			}
		#else
			alpha=(1-vertex_color.VERTEX_COLOR_CHANNEL_GEOM_BLEND);
		#endif	
	#else
		// alpha computed regular way (in opposite to geom blend)
		half alpha = Alpha(i_tex, _ddx, _ddy, _ddxDet, _ddyDet, vertex_color); // UBER - ddx, ddy, vertex_color (2 layers)

		#if defined(_ALPHATEST_ON)
				clip(alpha - _Cutoff);
		#endif

		#if defined(_SNOW)
			alpha=lerp(alpha, 1, _snow_val);
		#endif	
		#if defined(_WETNESS)
			alpha=lerp(alpha, 1, Wetness*_WetnessColor.a);
		#endif	
	#endif
	
	FragmentCommonData o = UNITY_SETUP_BRDF_INPUT (i_tex, vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, Wetness, blendFade, diffuseTint, diffuseTint2); // UBER - params added (vertex colors, derivateves)
	o.normalWorld = normalWorld;
	o.eyeVec = eyeVec;
	o.posWorld = i_posWorld;

	#if defined(_ALPHATEST_ON)
		o.additionalEmission+=saturate(_Cutoff - alpha + _CutoffEdgeGlow.a-0.004)*10000*_CutoffEdgeGlow.rgb;
	#endif

//	o.diffColor*=blendFade;
	
	#if defined(_WETNESS)
		half Wetness_with_Const=saturate(Wetness+WetnessConst);
		// wetness specularity (wetness has always "specular" setup)
		o.specColor = lerp(o.specColor, lerp(max(o.specColor, _WetnessSpecGloss.rgb), _WetnessSpecGloss.rgb, _WetnessColor.a), Wetness);
		// wetness darkening (for non emissive water, non opaque water and rough underlying surface)
		o.diffColor *= saturate(1.3-saturate(Wetness_with_Const*_WetnessDarkening*(1-_WetnessEmissiveness)*(1-_WetnessColor.a)*(1-o.smoothness)));
		// wetness gloss
		#if defined(_WETNESS_RIPPLES) || defined(_WETNESS_FULL)
			half wetGloss=saturate(_WetnessSpecGloss.a-rippleMIPsel*_WetnessSpecGloss.a*RippleStrength*_RippleSpecFilter);
		#else
			half wetGloss=_WetnessSpecGloss.a;
		#endif
		
		//wetMask=tex2D(_DetailMask, i_tex.xy*_WetnessUVMult*3).g;
		//wetGloss=0.9+wetMask*wetMask*0.3;
		//wetMask=0.1+tex2D(_DetailMask, i_tex.xy*_WetnessUVMult*5).g*0.5;
		//o.specColor=wetMask.xxx*wetMask.xxx;//lerp(o.specColor, wetMask, Wetness);//wetMask.xxx*o.specColor*10;
		//o.normalWorld=i_normalWorld;
		
		o.smoothness = lerp(o.smoothness, lerp(max(o.smoothness,wetGloss), wetGloss, _WetnessColor.a), Wetness_with_Const); // filtrowanie po rippleMIPsel (usuwa artefakty hi-freq z ripli)
		// wetness emissiveness
		#if defined(_WETNESS_RIPPLES) || defined(_WETNESS_FULL)
			half norm_fluid_val=_WetnessEmissivenessWrap ? (saturate(dot(wetNorm.xy*4, wetNorm.xy*4))*4+0.1) : (wetNorm.x+wetNorm.y+1);
		#else
			half norm_fluid_val=1;
		#endif
		o.additionalEmission += norm_fluid_val*_WetnessColor.rgb*_WetnessEmissiveness*Wetness*deepWetFct; // (8x HDR on emission)
		o.Wetness=Wetness;
	#endif
	
	
	#if defined(_TWO_LAYERS)
		half4 DiffuseScatteringColor=lerp(_DiffuseScatteringColor2, _DiffuseScatteringColor, __VERTEX_COLOR_CHANNEL_LAYER);
	#else
		half4 DiffuseScatteringColor=_DiffuseScatteringColor;
	#endif
	#if defined(_SNOW)
		// conserve energy (snow has specular setup)
		half oneMinusReflectivitySnow;

		half4 SnowSpecGloss = _SnowSpecGlossFromGlobal ? _UBER_GlobalSnowSpecGloss : _SnowSpecGloss;
		half3 diffColorSnow = EnergyConservationBetweenDiffuseAndSpecular( _SnowColorAndCoverage.rgb, SnowSpecGloss.rgb, /* out */ oneMinusReflectivitySnow );

		// simple frost - constant color & diffuse scatter
		half Frost=_FrostFromGlobal ? (1-_UBER_Frost)*_Frost : _Frost;
		#if defined(_WETNESS)
			half frost=Frost*Wetness_with_Const;
		#else
			half frost=Frost;
		#endif
		o.diffColor = lerp(o.diffColor, diffColorSnow, frost*0.05);

		o.specColor = lerp(o.specColor, SnowSpecGloss.rgb, _snow_val);
		o.diffColor = lerp(o.diffColor, diffColorSnow, _snow_val);
		o.smoothness = lerp(o.smoothness, SnowSpecGloss.a, _snow_val);
		o.oneMinusReflectivity=lerp(o.oneMinusReflectivity, oneMinusReflectivitySnow, _snow_val);
		o.snowVal=_snow_val;
		o.dissolveMaskValue=dissolveMaskValue;

		// diffuse scatter
		#if !defined(UNITY_PASS_META)
		half _snow_val_with_frost=max(_snow_val, frost*0.5);
		if (_DiffuseScatter>0) {
		// uniform branching - close to free on modern hardware (anyway - that's what experts like Aras say)
		//#if defined(_DIFFUSE_SCATTER)
			DiffuseScatteringColor=lerp(DiffuseScatteringColor, _SnowDiffuseScatteringColor, _snow_val_with_frost);
			half scatterNdotV=(dot(normalWorld, eyeVec)+lerp(_DiffuseScatteringOffset, _SnowDiffuseScatteringOffset, _snow_val_with_frost));
			half scatter=exp2(-scatterNdotV*scatterNdotV*lerp(_DiffuseScatteringExponent, _SnowDiffuseScatteringExponent, _snow_val_with_frost));
			scatter*=scatter;
			o.diffColor+=lerp(o.diffColor*DiffuseScatteringColor.rgb, DiffuseScatteringColor.rgb, DiffuseScatteringColor.a)*scatter*4;
		//#else
		} else {
			// currently not used part of code (_DIFFUSE_SCATTER is not a feature)
			DiffuseScatteringColor=_SnowDiffuseScatteringColor*_snow_val_with_frost;
			half scatterNdotV=(dot(normalWorld, eyeVec)+_SnowDiffuseScatteringOffset);
			half scatter=exp2(-scatterNdotV*scatterNdotV*_SnowDiffuseScatteringExponent);
			scatter*=scatter;
			o.diffColor+=lerp(o.diffColor*DiffuseScatteringColor.rgb, DiffuseScatteringColor.rgb, DiffuseScatteringColor.a)*scatter*4;
		}
		//#endif
		#endif
	#else
		// diffuse scatter
		#if !defined(UNITY_PASS_META)
		if (_DiffuseScatter>0) {
		// uniform branching - close to free on modern hardware (anyway - that's what experts like Aras say)
		//#if defined(_DIFFUSE_SCATTER)
		#if defined(FAKE_RETROREFLECTION)
			half scatterNdotV = (1 - dot(normalWorld, -eyeVec) + _DiffuseScatteringOffset);
			half scatter = exp2(-scatterNdotV*scatterNdotV*(_DiffuseScatteringExponent - 0.5) * 1000);
			scatter *= scatter;
			o.diffColor += lerp(o.diffColor*DiffuseScatteringColor.rgb, DiffuseScatteringColor.rgb, DiffuseScatteringColor.a)*scatter * 4;
		#else
			half scatterNdotV = (dot(normalWorld, eyeVec) + _DiffuseScatteringOffset);
			half scatter = exp2(-scatterNdotV*scatterNdotV*_DiffuseScatteringExponent);
			scatter *= scatter;
			o.diffColor += lerp(o.diffColor*DiffuseScatteringColor.rgb, DiffuseScatteringColor.rgb, DiffuseScatteringColor.a)*scatter * 4;
		#endif
		//#endif
		}
		#endif
	#endif	
	
	// UBER - SS
	#if defined(_PARALLAX_POM_SHADOWS) || defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS)
	o.rayPos = rayPos;
	o.tanToWorld=i_tanToWorld;
	#endif
	o.texture2ObjectRatio = texture2ObjectRatio;
	#if defined(ZWRITE)
	o.rayLength=rayLength;
	#endif

	// NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
	o.diffColor = PreMultiplyAlpha (o.diffColor, alpha, o.oneMinusReflectivity, /*out*/ o.alpha);

	return o;
}

inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light, bool reflections)
{
	UnityGIInput d;
	d.light = light;
	d.worldPos = s.posWorld;
	d.worldViewDir = -s.eyeVec;
	d.atten = atten;
	#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
		d.ambient = 0;
		d.lightmapUV = i_ambientOrLightmapUV;
	#else
		d.ambient = i_ambientOrLightmapUV.rgb;
		d.lightmapUV = 0;
	#endif

	d.probeHDR[0] = unity_SpecCube0_HDR;
	d.probeHDR[1] = unity_SpecCube1_HDR;
	#if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
	  d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
	#endif
	#if UNITY_SPECCUBE_BOX_PROJECTION
	  d.boxMax[0] = unity_SpecCube0_BoxMax;
	  d.probePosition[0] = unity_SpecCube0_ProbePosition;
	  d.boxMax[1] = unity_SpecCube1_BoxMax;
	  d.boxMin[1] = unity_SpecCube1_BoxMin;
	  d.probePosition[1] = unity_SpecCube1_ProbePosition;
	#endif

	if(reflections)
	{
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.smoothness, -s.eyeVec, s.normalWorld, s.specColor);
		// Replace the reflUVW if it has been compute in Vertex shader. Note: the compiler will optimize the calcul in UnityGlossyEnvironmentSetup itself
		#if UNITY_OPTIMIZE_TEXCUBELOD || UNITY_STANDARD_SIMPLE
			g.reflUVW = s.reflUVW;


		#endif

		return UnityGlobalIllumination (d, occlusion, s.normalWorld, g);
	}
	else
	{
		return UnityGlobalIllumination (d, occlusion, s.normalWorld);
	}
}


inline UnityGI FragmentGI(FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light)
{
	return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, true);
}


//-------------------------------------------------------------------------------------
half4 OutputForward (half4 output, half alphaFromSurface)
{
	#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
		output.a = alphaFromSurface;
	#else
		UNITY_OPAQUE_ALPHA(output.a);
	#endif
	return output;
}

inline half4 VertexGIForward(VertexInput v, half3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
#ifdef LIGHTMAP_ON
	ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	ambientOrLightmapUV.zw = 0;
	// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
#elif UNITY_SHOULD_SAMPLE_SH
#if UNITY_SAMPLE_FULL_SH_PER_PIXEL  // TODO: remove this path
	ambientOrLightmapUV.rgb = 0;
#elif (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
	ambientOrLightmapUV.rgb = ShadeSH9(half4(normalWorld, 1.0));
#else
	// Optimization: L2 per-vertex, L0..L1 per-pixel
	ambientOrLightmapUV.rgb = ShadeSH3Order(half4(normalWorld, 1.0));
#endif
	// Add approximated illumination from non-important point lights
#ifdef VERTEXLIGHT_ON
	ambientOrLightmapUV.rgb += Shade4PointLights(
		unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
		unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
		unity_4LightAtten0, posWorld, normalWorld);
#endif
#endif

#ifdef DYNAMICLIGHTMAP_ON
	ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
#endif

	return ambientOrLightmapUV;
}


// ------------------------------------------------------------------
//  Base forward pass (directional light, emission, lightmaps, ...)

struct VertexOutputForwardBase
{
	UNITY_POSITION(pos);
	half4 tex							: TEXCOORD0; // normal in triplanar (.w means UV1 - u coord for triplanar - needed for secondary occlusion)
	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		half4 posObject				: TEXCOORD1; // .w means UV1 - v coord for triplanar (needed for secondary occlusion)
	#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		half4 SclCurv					: TEXCOORD1;
	#else
		half4 eyeVec 					: TEXCOORD1; // .w means UV1 - v coord for triplanar (needed for secondary occlusion)
	#endif
	half4 tangentToWorldAndParallax0	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:viewDirForParallax] - note: tangents+obj scale in triplanar (tangents in world space when mapping in world space)
	half4 tangentToWorldAndParallax1	: TEXCOORD3;	// (array fails in GLSL optimizer)
	half4 tangentToWorldAndParallax2	: TEXCOORD4;
	half4 ambientOrLightmapUV			: TEXCOORD5;	// SH or Lightmap UV
	fixed4 vertex_color					: COLOR0;		// UBER
	UNITY_SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)

	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
	#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
		#if defined(ZWRITE)
		half4 posWorld					: TEXCOORD8;
		#else
		half3 posWorld					: TEXCOORD8;
		#endif
	#endif
	#if defined(_REFRACTION) || DECAL_PIERCEABLE
		half4 screenPos				: TEXCOORD9;
	#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

VertexOutputForwardBase vertForwardBase (VertexInput v)
{
	UNITY_SETUP_INSTANCE_ID(v);
	VertexOutputForwardBase o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
	
	#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		half2 Curv=frac(v.uv3);
		half2 Scl=(v.uv3-Curv)/100; // scale represented with 0.01 resolution (fair enough)
		Scl=Scl*_Tan2ObjectMultOffset.xy+_Tan2ObjectMultOffset.zw;
		//Scl=10;
		#if defined(VERTEX_COLOR_CHANNEL_POMZ)
			v.vertex.xyz+=_POM_ExtrudeVolume ? v.normal.xyz*v.color.VERTEX_COLOR_CHANNEL_POMZ*_Depth*max(Scl.x, Scl.y)/max(_MainTex_ST.x, _MainTex_ST.y) : half3(0,0,0);
			// Curv.x==0 - extruded bottom flag
			v.color.VERTEX_COLOR_CHANNEL_POMZ = Curv.x==0 || (!_POM_ExtrudeVolume) ? v.color.VERTEX_COLOR_CHANNEL_POMZ : 1-v.color.VERTEX_COLOR_CHANNEL_POMZ;
			//Curv=0; // no curvature on extruded volumes (we need bottom flag info in parallax function though - so DON'T zero Curv here !)
			// if we don't handle the volume set the curvature data to desired range
			Curv = _POM_ExtrudeVolume ? Curv : Curv*20-10;
		#else
			Curv=Curv*20-10; // Curv=(Curv-0.5)*10; // we assume curvature won't be higher than +/- 10
		#endif
	#endif

	half4 posWorld = mul(unity_ObjectToWorld, v.vertex);

	#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
		o.posWorld.xyz = posWorld.xyz;
		#if defined(ZWRITE)
			COMPUTE_EYEDEPTH(o.posWorld.w);
		#endif
	#endif

	o.vertex_color = v.color; // UBER
	o.pos = UnityObjectToClipPos(v.vertex);

	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		//o.posObject set below
	#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		o.SclCurv=half4(half2(1.0,1.0)/Scl, Curv);
	#else
		o.eyeVec.xyz = posWorld.xyz - _WorldSpaceCameraPos;
		#if defined(TRIPLANAR_SELECTIVE)
			// world mapping
			o.eyeVec.w = v.uv1.y;
		#endif
	#endif

	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			half3 normalWorld = UnityObjectToWorldNormal(v.normal);
			SetupUBER_VertexData_TriplanarWorld(normalWorld, /* inout */ o.tangentToWorldAndParallax0, /* inout */ o.tangentToWorldAndParallax1, /* inout */ o.tangentToWorldAndParallax2);
		#else
			half scaleX, scaleY, scaleZ;
			SetupUBER_VertexData_TriplanarLocal(v.normal, /* inout */ o.tangentToWorldAndParallax0, /* inout */ o.tangentToWorldAndParallax1, /* inout */ o.tangentToWorldAndParallax2, /* out */ scaleX, /* out */ scaleY, /* out */ scaleZ);
			half3 normalWorld = UnityObjectToWorldNormal(v.normal);
			o.posObject.xyz = v.vertex.xyz;
			o.posObject.w = v.uv1.y; // pack it here
		#endif		
	#elif defined(_TANGENT_TO_WORLD)
		half3x3 tangentToWorld;

		// we need to go from tangent to world space for zwrite and parallaxed snow (actually when snow is mapped in worldspace)
		#if defined(RAYLENGTH_AVAILABLE)
			half3 normalWorld = mul((half3x3)unity_ObjectToWorld, v.normal.xyz);
			half3 tangentWorld = mul((half3x3)unity_ObjectToWorld, v.tangent.xyz);
			half3 binormalWorld = mul((half3x3)unity_ObjectToWorld, cross(v.normal.xyz, v.tangent.xyz)*v.tangent.w);
			#ifdef SHADER_TARGET_GLSL
			binormalWorld*=0.9999; // dummy op to cheat HLSL2GLSL optimizer to not be so smart (and buggy) here... It probably tries to make some fancy matrix by matrix calculation
			#endif
			// not normalized basis (we need it for texture 2 worldspace ratio calculations)
			tangentToWorld=half3x3(tangentWorld, binormalWorld, normalWorld);
			normalWorld = normalize(normalWorld); // we need it below for lighting
		#else
			half3 normalWorld = UnityObjectToWorldNormal(v.normal);
			half4 tangentWorld = half4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
			tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, v.tangent.w);
		#endif

		o.tangentToWorldAndParallax0.xyz = tangentToWorld[0];
		o.tangentToWorldAndParallax1.xyz = tangentToWorld[1];
		o.tangentToWorldAndParallax2.xyz = tangentToWorld[2];
	#else
		half3 normalWorld = UnityObjectToWorldNormal(v.normal);
		o.tangentToWorldAndParallax0.xyz = 0;
		o.tangentToWorldAndParallax1.xyz = 0;
		o.tangentToWorldAndParallax2.xyz = normalWorld;
	#endif
	//We need this for shadow receving
	UNITY_TRANSFER_SHADOW(o, v.uv1);
	
	o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);

	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			// .w component not used
		#else
			o.tangentToWorldAndParallax0.w=scaleX;
			o.tangentToWorldAndParallax1.w=scaleY;
			o.tangentToWorldAndParallax2.w=scaleZ;
		#endif
	#elif defined(_PARALLAXMAP) || defined(_PARALLAXMAP_2MAPS) || defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		#if ((defined(POM)) && defined(SILHOUETTE_CURVATURE_MAPPED))
			half3 viewDirForParallax = ObjSpaceViewDir(v.vertex);
		#else
			// vertex normal, tangent are not guaranteed to be normalized (!)
			// try - 2 simple planes on the scene using the same material, anchored and parent has decreased scale, Unity makes kind of batch (vertices seems to be transformed to world space) ? Anyway mesh tangents, normals get scaled, too and makes total mess with TBN matrices (view direction...)
			v.normal=normalize(v.normal);
			v.tangent.xyz=normalize(v.tangent.xyz);
			half3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
			half3x3 rotation = half3x3( v.tangent.xyz, binormal, v.normal );
			half3 viewDirForParallax = mul(rotation, ObjSpaceViewDir(v.vertex));
		#endif
		o.tangentToWorldAndParallax0.w = viewDirForParallax.x;
		o.tangentToWorldAndParallax1.w = viewDirForParallax.y;
		o.tangentToWorldAndParallax2.w = viewDirForParallax.z;
	#endif
	#if defined(_REFRACTION) || DECAL_PIERCEABLE
		o.screenPos = ComputeScreenPos (o.pos);
		COMPUTE_EYEDEPTH(o.screenPos.z); // used for pierceables
	#endif
	
	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			o.tex = half4(normalWorld, v.uv1.x); // pack UV1 here
		#else
			o.tex = half4(v.normal, v.uv1.x); // pack UV1 here
		#endif
	#else
		o.tex = TexCoordsNoTransform(v);
	#endif
	
	UNITY_TRANSFER_FOG(o,o.pos);
	return o;
}

#if DECAL_PIERCEABLE
	// piercing depth mask buffer (for pierceable deferred) or mask additive forward decals
	sampler2D_half _PiercingBuffer;
	// depth on which decal has been placed
	sampler2D_half _PiercingDepthBuffer;
	// uniform bool to save keyword, we need also to #define DECAL_PIERCEABLE to get this part of code actually compiled
	bool _Pierceable;
	half _PiercingThreshold; // Piercing threshold (forward)
#endif


/* _Paint3DAccumulator_ */
void fragPaint3DAccumulator (VertexOutputForwardBase i, out half4 outColor : SV_Target
#if defined(_2SIDED)
,half facing : VFACE
#endif
//#if defined(ZWRITE)
//,out half outDepth : DEPTH_SEMANTIC
//#endif
)
{
	/*
	struct VertexOutputForwardBase
	{
		UNITY_POSITION(pos);
		half4 tex							: TEXCOORD0; // normal in triplanar (.w means UV1 - u coord for triplanar - needed for secondary occlusion)
		#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
			half4 posObject				: TEXCOORD1; // .w means UV1 - v coord for triplanar (needed for secondary occlusion)
		#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
			half4 SclCurv					: TEXCOORD1;
		#else
			half4 eyeVec 					: TEXCOORD1; // .w means UV1 - v coord for triplanar (needed for secondary occlusion)
		#endif
		half4 tangentToWorldAndParallax0	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:viewDirForParallax] - note: tangents+obj scale in triplanar (tangents in world space when mapping in world space)
		half4 tangentToWorldAndParallax1	: TEXCOORD3;	// (array fails in GLSL optimizer)
		half4 tangentToWorldAndParallax2	: TEXCOORD4;
		half4 ambientOrLightmapUV			: TEXCOORD5;	// SH or Lightmap UV
		fixed4 vertex_color					: COLOR0;		// UBER
		UNITY_SHADOW_COORDS(6)
		UNITY_FOG_COORDS(7)

		// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
		#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
			#if defined(ZWRITE)
			half4 posWorld					: TEXCOORD8;
			#else
			half3 posWorld					: TEXCOORD8;
			#endif
		#endif
		#if defined(_REFRACTION) || DECAL_PIERCEABLE
			half4 screenPos				: TEXCOORD9;
		#endif

		UNITY_VERTEX_INPUT_INSTANCE_ID
		UNITY_VERTEX_OUTPUT_STEREO
	};
	*/
	/*
	struct v2f_P3DA
	{
		half2 uv : TEXCOORD0;
		half3 worldPos : TEXCOORD1;
		half4 vertex : SV_POSITION;
		#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
		half3 normal : TEXCOORD2;
		#endif
	};
	*/
	v2f_P3DA iP3DA;
	iP3DA.uv = i.tex.xy;
	#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
	iP3DA.worldPos = i.posWorld;
	#endif
	iP3DA.vertex = i.pos;
	#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
	iP3DA.normal = i.tex.rgb;
	#endif
	outColor = Paint3DAccumulatorFragmentLogic_P0(iP3DA);	

}


	

void fragForwardBase (VertexOutputForwardBase i, out half4 outCol : SV_Target
#if defined(_2SIDED)
,half facing : VFACE
#endif
#if defined(ZWRITE)
,out half outDepth : DEPTH_SEMANTIC
#endif
)
{
	UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
	UNITY_SETUP_INSTANCE_ID(i);

	#if defined(_2SIDED)
		#if UNITY_VFACE_FLIPPED
			facing = -facing;
		#endif
		#if UNITY_VFACE_AFFECTED_BY_PROJECTION
			facing *= _ProjectionParams.x; // take possible upside down rendering into account
		#endif	
		#if defined(TRIPLANAR_SELECTIVE)
			i.tex.xyz *= facing>0 ? 1 : -1;
		#else
			i.tangentToWorldAndParallax2 *= facing>0 ? 1 : -1;
		#endif
	#endif
	
	#if defined(TRIPLANAR_SELECTIVE)
		// unpack UV1
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			half2 secUV=half2(i.tex.w, i.eyeVec.w);
		#else
			half2 secUV=half2(i.tex.w, i.posObject.w);
		#endif		
	#endif

	// ------
	half actH;
	half4 SclCurv;
	half3 eyeVec;
	
	half3 tangentBasisScaled;
	
	half2 _ddx;
	half2 _ddy;
	half2 _ddxDet;
	half2 _ddyDet;
	half blendFade;
	
	half3 i_viewDirForParallax;
	half3x3 _TBN;
	half3 worldNormal;
	
	half4 texcoordsNoTransform;
	
	// void	SetupUBER(half4 i_SclCurv, half3 i_eyeVec, half3 i_posWorld, half3 i_posObject, inout half4 i_tex, inout half4 i_tangentToWorldAndParallax0, inout half4 i_tangentToWorldAndParallax1, inout half4 i_tangentToWorldAndParallax2, inout fixed4 vertex_color, out half actH, out half4 SclCurv, out half3 eyeVec, out half3 tangentBasisScaled, out half2 _ddx, out half2 _ddy, out half2 _ddxDet, out half2 _ddyDet, out half blendFade, out half3 i_viewDirForParallax, out half3x3 _TBN, out half3 worldNormal) {
	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		SetupUBER(half4(0,0,0,0), half3(0,0,0), IN_WORLDPOS(i), i.posObject.xyz, /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		SetupUBER(i.SclCurv, half3(0,0,0), IN_WORLDPOS(i), half3(0,0,0), /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#else
		SetupUBER(half4(0,0,0,0), i.eyeVec.xyz, IN_WORLDPOS(i), half3(0,0,0), /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#endif
	// ------	

//#if defined(VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED)
//		half3 diffuseTint = i.diffuseTint;
//#else
		half3 diffuseTint = half3(0.5, 0.5, 0.5); // n/u
		half3 diffuseTint2 = half3(0.5, 0.5, 0.5);
//#endif

	FRAGMENT_SETUP(s)	
	#ifdef _3D_PAINT_ACCUMULATOR_
		v2f_P3DA iP3DA;
		iP3DA.uv = i.tex.xy;
		iP3DA.worldPos = i.posWorld;
		iP3DA.vertex = i.pos;
		#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
			iP3DA.normal = i.tex.rgb;
		#endif
		// tried to assigned the RT directly to the albedo of uber every frame but was black and transparent
		half4 paintColor = Paint3DAccumulatorFragmentLogic_P1(iP3DA);
		half3 paintColorrgbSmall = paintColor.rgb*0.05;
		s.diffColor.rgb += paintColor.rgb*0.95;
		s.alpha *= paintColor.a;
		//s.alpha = 0; // EVEN with this to 0, it draws the diffColor.
		//s.alpha = 1;
		//outCol.a = 0;
	#endif

	
	UnityLight mainLight = MainLight ();
	UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld, shadow_atten); // atten is not used (for main directional light shadow_atten is the only atten present)
	
	half2 occ=Occlusion(i.tex, _ddx, _ddy, _ddxDet, _ddyDet, i.vertex_color); // y - translucency/glitter
	half occlusion = occ.x;
	#if defined(OCCLUSION_VERTEX_COLOR_CHANNEL)
		occlusion*=i.vertex_color.OCCLUSION_VERTEX_COLOR_CHANNEL;
	#endif
	#if defined(_TWO_LAYERS)
		occlusion = LerpOneTo(occlusion, lerp(_OcclusionStrength2, _OcclusionStrength, i.__VERTEX_COLOR_CHANNEL_LAYER));
	#else
		occlusion = LerpOneTo(occlusion, _OcclusionStrength);
	#endif

	#if defined(_TRANSLUCENCY)
		half translucency_thickness_fromOccMap = 1;
	#endif
	if (_Occlusion_from_albedo_alpha) { // uniform bool (half for sake of d3d9 compatibility)
		// possible 2ndary occlusion
		// primary occlusion from diffuse A, secondary from _OcclusionMap
		#if defined(TRIPLANAR_SELECTIVE)
			// already unpacked secUV
		#else
			#if defined(SECONDARY_OCCLUSION_PARALLAXED)
				half2 secUV=((i.tex.xy-_MainTex_ST.zw)/_MainTex_ST.xy - texcoordsNoTransform.xy) + texcoordsNoTransform.zw;
			#else
				half2 secUV=texcoordsNoTransform.zw; // actually we don't need parallax applied as we assume secondary occlusion is low freq maybe
			#endif
		#endif
		secUV = _UVSecOcclusionLightmapPacked==1 ? (secUV * unity_LightmapST.xy + unity_LightmapST.zw) : secUV;
		half4 occVal = tex2Dp(_OcclusionMap, secUV,  ddx(secUV),  ddy(secUV));
		half2 occ2 = half2(occVal.AMBIENT_OCCLUSION_CHANNEL, occVal.AUX_OCCLUSION_CHANNEL);
		// UV0 / UV1 occlusion switch
		occlusion *= (_UVSecOcclusion==0) ? 1 : lerp(1, occ2.x, _SecOcclusionStrength);
		#if defined(_TRANSLUCENCY)
			// translucency mask from UV1
			translucency_thickness_fromOccMap = occ2.y;
		#endif
	}

	#if defined(_SNOW)
		occlusion*=lerp(1, s.dissolveMaskValue, s.snowVal*_SnowDissolveMaskOcclusion);
	#endif
	#if defined(TRIPLANAR_SELECTIVE)
		occlusion*=lerp(1, blendFade, _TriplanarBlendAmbientOcclusion);
	#endif
	#if defined(_SNOW)
		occlusion=lerp(occlusion, 1, saturate(s.snowVal*_SnowDeepSmoothen*0.15));
	#endif

	#if defined(_TRANSLUCENCY)
		// UV0 / UV1 occlusion switch	
		half translucency_thickness = _UVSecOcclusion==0 ? occ.y : translucency_thickness_fromOccMap;
	#endif	

	#if defined(_REFRACTION) || DECAL_PIERCEABLE
		half2 screenUV = (i.screenPos.xy / i.screenPos.w);
		#if !defined(SHADER_API_OPENGL) && !defined(SHADER_API_GLCORE) && !defined(SHADER_API_GLES3)
			screenUV.y = _ProjectionParams.x>0 ? 1 - screenUV.y : screenUV.y;
		#endif
	#endif

	// translucency
	#if defined(_TRANSLUCENCY)
		half3 TL=Translucency(s, mainLight, translucency_thickness, i.vertex_color);
		s.diffColor*=saturate(1-max(max(TL.r, TL.g), TL.b)*TRANSLUCENCY_SUPPRESS_DIFFUSECOLOR);
		shadow_atten =lerp(shadow_atten, 1, saturate( dot(TL,1)*_TranslucencySuppressRealtimeShadows ) );
	#endif	
	
	UnityGI gi = FragmentGI(s, occlusion, i.ambientOrLightmapUV, shadow_atten, mainLight);

	#if defined(_PARALLAX_POM_SHADOWS) || defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS)
		#if defined(_SNOW) && !defined(_POM_DISTANCE_MAP_SHADOWS) && !defined(_POM_EXTRUSION_MAP_SHADOWS)
			bool SS_flag = (saturate(s.snowVal*_SnowDeepSmoothen)<0.98);
		#else
			bool SS_flag = true;
		#endif
		if (SS_flag) {
			half3 lightDirInTanSpace=mul(s.tanToWorld, gi.light.dir);  // named tanToworld but this mul() actually works the opposite (as I swapped params in mul)
			#if defined(_SNOW) && !defined(_POM_DISTANCE_MAP_SHADOWS) && !defined(_POM_EXTRUSION_MAP_SHADOWS)
				gi.light.color *= SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, s.snowVal);
			#else
				#if defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS)
					gi.light.color *= lerp( SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, 0), 1, saturate( distance(i.posWorld, _WorldSpaceCameraPos) / _DepthReductionDistance ) );
				#else
					gi.light.color *= SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, 0);
				#endif
			#endif
		}
	#endif
	
	#if defined(_GLITTER)
		Glitter(/* inout */ s, i.tex.zw, _ddxDet, _ddyDet, i.posWorld.xyz, i.vertex_color, lerp(1, occ.y, _GlitterMask));
	#endif	

	half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);

	#if defined(_TRANSLUCENCY)
		c.rgb += TL*gi.light.color;
	#endif	

	#if defined(_SNOW)
		half snowBlur=_SnowDeepSmoothen*4*s.snowVal; // currently not used
		half3 snowEmissionDamp=LerpWhiteTo(_SnowEmissionTransparency, s.snowVal);
	#else
		half snowBlur=0; // not used
		half3 snowEmissionDamp=1;
	#endif

	#if defined(EMISSION_AT_THE_OTHER_SIDE)
		snowEmissionDamp *= saturate(dot(-i.tangentToWorldAndParallax2, DeferredLightDir(i.posWorld.xyz))*4.);
	#endif

	c.rgb += Emission(i.tex.xyzw, i.vertex_color, _ddx, _ddy, snowBlur)*snowEmissionDamp; // UBER - 4 components (main uv, detail uv) + vertex color (for masking), under snow blurring
	c.rgb += s.additionalEmission*snowEmissionDamp; // UBER - detail/wet emission

	UNITY_APPLY_FOG(i.fogCoord, c.rgb);

	#if DECAL_PIERCEABLE
		if (_Pierceable == true) {
			half2 screenUV = (i.screenPos.xy / i.screenPos.w);
			#if !defined(SHADER_API_OPENGL) && !defined(SHADER_API_GLCORE) && !defined(SHADER_API_GLES3)
				screenUV.y = _ProjectionParams.x>0 ? 1 - screenUV.y : screenUV.y;
			#endif

			//half piercingDepthBuffer = tex2D(_PiercingDepthBuffer, screenUV).r; // linear depth stored in Rhalf buffer (depth of surface where piercing decal is placed with small offset to prevent fighting)
			//half ldepth = i.screenPos.z; // linear eye depth passed from vertex program
			//half depthFade = 1 - saturate(abs(piercingDepthBuffer - ldepth) * 16);

			half2 piercingBuffer = tex2D(_PiercingBuffer, screenUV).rg;
			half forwardDecalAlpha = piercingBuffer.g * 4;
			half piercingValue = saturate((_PiercingThreshold - piercingBuffer.r) * 20);
			forwardDecalAlpha = 1 - saturate(forwardDecalAlpha); 
			forwardDecalAlpha *= piercingValue;
			s.alpha *= forwardDecalAlpha; // fadeout pixels written by piercing decal
			//s.alpha *= piercingValue; // fadeout pixels written by piercing decal
			c.rgb *= forwardDecalAlpha; // fadeout specular highlights
			//c.rgb *= piercingValue; // remove completely the hole
		}
	#endif

	#if defined(LOD_FADE_CROSSFADE) && (defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON))
		s.alpha *= unity_LODFade.x;
	#endif

	#if defined(_REFRACTION)
		half3 worldViewDir = s.posWorld - _WorldSpaceCameraPos.xyz;
		worldViewDir=normalize(worldViewDir);
		//UNITY_MATRIX_V[1].xyz // cam up
		//UNITY_MATRIX_V[0].xyz // cam right
		half NdotV=dot(_RefractionBumpScale*s.normalWorld+_TBN[2], s.eyeVec);
		//half2 offset=_Refraction*half2(dot(s.normalWorld, UNITY_MATRIX_V[0].xyz*dot(worldViewDir,UNITY_MATRIX_V[2].xyz)), dot(s.normalWorld, UNITY_MATRIX_V[1].xyz*dot(worldViewDir,UNITY_MATRIX_V[2].xyz)))*(NdotV*NdotV);
		half2 offset=_Refraction*half2(dot(_TBN[2], UNITY_MATRIX_V[0].xyz*dot(worldViewDir,UNITY_MATRIX_V[2].xyz)), dot(_TBN[2], UNITY_MATRIX_V[1].xyz*dot(_TBN[2],UNITY_MATRIX_V[2].xyz)))*(NdotV*NdotV);
		half2 dampUV=abs(screenUV*2-1);
		half borderDamp=saturate(1 - max ( (dampUV.x-0.9)/(1-0.9) , (dampUV.y-0.85)/(1-0.85) ));
		offset*=borderDamp;
		half3 centerCol=tex2D(_GrabTexture, screenUV+offset).rgb;
		#if defined(_CHROMATIC_ABERRATION) 
			half abberrationG=1-_RefractionChromaticAberration;
			half abberrationB=1+_RefractionChromaticAberration;
			half _R=centerCol.r;
			half3 sceneColor = half3(_R, tex2D(_GrabTexture, screenUV+offset*lerp(abberrationG, 1, NdotV)).g, tex2D(_GrabTexture, screenUV+offset*lerp(abberrationB, 1, NdotV)).b);
		#else
			half3 sceneColor = centerCol;
		#endif
		c.rgb+=sceneColor*(1-s.alpha);
		outCol=half4(c.rgb, 1);
	#else
		outCol=OutputForward (c, s.alpha);
	#endif
	
	#if defined(ZWRITE)
		//half depthWithOffset = i.posWorld.w+s.rayLength;
		half depthWithOffset = i.posWorld.w*(1+s.rayLength/distance(i.posWorld.xyz, _WorldSpaceCameraPos)); // Z-DEPTH perspective correction
		outDepth = (1.0 - depthWithOffset * _ZBufferParams.w) / (depthWithOffset * _ZBufferParams.z);
	#endif
	
	
	#if defined(DISTANCE_MAP)
		//outCol.rgb += i_viewDirForParallax.xyz;// i.vertex_color.a;//s.rayPos.z;
		//outCol.rgba = 1;// s.normalWorld*0.5 + 0.5;
	#endif
	
	#ifdef _3D_PAINT_ACCUMULATOR_
		outCol.rgb += paintColorrgbSmall;
	#endif

//	UNITY_MATRIX_V[3].xyz;//
//Camera position = _WorldSpaceCameraPos = mul(UNITY_MATRIX_V,half4(0,0,0,1)).xyz;
	
//	outCol.rgb=s.normalWorld;

}

// ------------------------------------------------------------------
//  Additive forward pass (one light per pass)
struct VertexOutputForwardAdd
{
	UNITY_POSITION(pos);
	half4 tex							: TEXCOORD0; // normal in triplanar (.w means UV1 - u coord for triplanar - needed for secondary occlusion)
	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		half4 posObject				: TEXCOORD1; // .w means UV1 - v coord for triplanar (needed for secondary occlusion)
	#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		half4 SclCurv					: TEXCOORD1;
	#else
		half4 eyeVec 					: TEXCOORD1; // .w means UV1 - v coord for triplanar (needed for secondary occlusion)
	#endif
	half4 tangentToWorldAndParallax0	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:viewDirForParallax] - note: tangents+obj scale in triplanar (tangents in world space when mapping in world space)
	half4 tangentToWorldAndParallax1	: TEXCOORD3;
	half4 tangentToWorldAndParallax2	: TEXCOORD4;
	fixed4 vertex_color					: COLOR0;
	#if defined(ZWRITE)
		half4 posWorld					: TEXCOORD5;
	#else
		half3 posWorld					: TEXCOORD5;
	#endif
	UNITY_SHADOW_COORDS(6)
	UNITY_FOG_COORDS(7)


	#if DECAL_PIERCEABLE
		half4 screenPos				: TEXCOORD8;
	#endif

	UNITY_VERTEX_OUTPUT_STEREO
};

VertexOutputForwardAdd vertForwardAdd (VertexInput v)
{
	UNITY_SETUP_INSTANCE_ID(v);
	VertexOutputForwardAdd o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAdd, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		half2 Curv=frac(v.uv3);
		half2 Scl=(v.uv3-Curv)/100; // scale represented with 0.01 resolution (fair enough)
		Scl=Scl*_Tan2ObjectMultOffset.xy+_Tan2ObjectMultOffset.zw;
		#if defined(VERTEX_COLOR_CHANNEL_POMZ)
			v.vertex.xyz+=_POM_ExtrudeVolume ? v.normal.xyz*v.color.VERTEX_COLOR_CHANNEL_POMZ*_Depth*max(Scl.x, Scl.y)/max(_MainTex_ST.x, _MainTex_ST.y) : half3(0,0,0);
			// Curv.x==0 - extruded bottom flag
			v.color.VERTEX_COLOR_CHANNEL_POMZ = Curv.x==0 || (!_POM_ExtrudeVolume) ? v.color.VERTEX_COLOR_CHANNEL_POMZ : 1-v.color.VERTEX_COLOR_CHANNEL_POMZ;
			//Curv=0; // no curvature on extruded volumes (we need bottom flag info in parallax function though - so DON'T zero Curv here !)
			// if we don't handle the volume set the curvature data to desired range
			Curv = _POM_ExtrudeVolume ? Curv : Curv*20-10;
		#else
			Curv=Curv*20-10; // Curv=(Curv-0.5)*10; // we assume curvature won't be higher than +/- 10
		#endif
	#endif

	half4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.posWorld.xyz = posWorld.xyz;
	#if defined(ZWRITE)
		COMPUTE_EYEDEPTH(o.posWorld.w);
	#endif		
	o.vertex_color = v.color;
	#if defined(UNITY_SUPPORT_INSTANCING) && defined(INSTANCING_ON)
		o.pos = mul(UNITY_MATRIX_M, v.vertex);
		o.pos = mul(UNITY_MATRIX_VP, o.pos);
	#else
		o.pos = UnityObjectToClipPos(v.vertex);
	#endif

	#if DECAL_PIERCEABLE
		o.screenPos = ComputeScreenPos (o.pos);
		COMPUTE_EYEDEPTH(o.screenPos.z); // used for pierceables
	#endif
	
	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		//o.posObject set below
	#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		o.SclCurv=half4(half2(1.0,1.0)/Scl, Curv);
	#else
		o.eyeVec.xyz = posWorld.xyz - _WorldSpaceCameraPos;
		#if defined(TRIPLANAR_SELECTIVE)
			// world mapping
			o.eyeVec.w = v.uv1.y;
		#endif
	#endif
	
	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			half3 normalWorld = UnityObjectToWorldNormal(v.normal);
			SetupUBER_VertexData_TriplanarWorld(normalWorld, /* inout */ o.tangentToWorldAndParallax0, /* inout */ o.tangentToWorldAndParallax1, /* inout */ o.tangentToWorldAndParallax2);
		#else
			half scaleX, scaleY, scaleZ;
			SetupUBER_VertexData_TriplanarLocal(v.normal, /* inout */ o.tangentToWorldAndParallax0, /* inout */ o.tangentToWorldAndParallax1, /* inout */ o.tangentToWorldAndParallax2, /* out */ scaleX, /* out */ scaleY, /* out */ scaleZ);
			half3 normalWorld = UnityObjectToWorldNormal(v.normal);
			o.posObject.xyz = v.vertex.xyz;
			o.posObject.w = v.uv1.y; // pack it here
		#endif		
	#elif defined(_TANGENT_TO_WORLD)
		half3x3 tangentToWorld;
		
		// we need to go from tangent to world space for zwrite and parallaxed snow (actually when snow is mapped in worldspace)
		#if defined(RAYLENGTH_AVAILABLE)
			half3 normalWorld = mul((half3x3)unity_ObjectToWorld, v.normal.xyz);
			half3 tangentWorld = mul((half3x3)unity_ObjectToWorld, v.tangent.xyz);
			half3 binormalWorld = mul((half3x3)unity_ObjectToWorld, cross(v.normal.xyz, v.tangent.xyz)*v.tangent.w);
			#ifdef SHADER_TARGET_GLSL
			binormalWorld*=0.9999; // dummy op to cheat HLSL2GLSL optimizer to not be so smart (and buggy) here... It probably tries to make some fancy matrix by matrix calculation
			#endif
			// not normalized basis (we need it for texture 2 worldspace ratio calculations)
			tangentToWorld=half3x3(tangentWorld, binormalWorld, normalWorld);
			normalWorld = normalize(normalWorld); // we need it below for lighting
		#else
			half3 normalWorld = UnityObjectToWorldNormal(v.normal);
			half4 tangentWorld = half4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
			tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, v.tangent.w);
		#endif

		o.tangentToWorldAndParallax0.xyz = tangentToWorld[0];
		o.tangentToWorldAndParallax1.xyz = tangentToWorld[1];
		o.tangentToWorldAndParallax2.xyz = tangentToWorld[2];
	#else
		half3 normalWorld = UnityObjectToWorldNormal(v.normal);
		o.tangentToWorldAndParallax0.xyz = 0;
		o.tangentToWorldAndParallax1.xyz = 0;
		o.tangentToWorldAndParallax2.xyz = normalWorld;
	#endif
	//We need this for shadow receving
	UNITY_TRANSFER_SHADOW(o, v.uv1);

	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			// .w component not used
		#else
			o.tangentToWorldAndParallax0.w=scaleX;
			o.tangentToWorldAndParallax1.w=scaleY;
			o.tangentToWorldAndParallax2.w=scaleZ;
		#endif
	#elif defined(_PARALLAXMAP) || defined(_PARALLAXMAP_2MAPS) || defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		#if ((defined(POM)) && defined(SILHOUETTE_CURVATURE_MAPPED)) || defined(TRIPLANAR_SELECTIVE)
			half3 viewDirForParallax = ObjSpaceViewDir(v.vertex);
		#else
			// vertex normal, tangent are not guaranteed to be normalized (!)
			// try - 2 simple planes on the scene using the same material, anchored and parent has decreased scale, Unity makes kind of batch (vertices seems to be transformed to world space) ? Anyway mesh tangents, normals get scaled, too and makes total mess with TBN matrices (view direction...)
			v.normal=normalize(v.normal);
			v.tangent.xyz=normalize(v.tangent.xyz);
			half3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
			half3x3 rotation = half3x3( v.tangent.xyz, binormal, v.normal );
			half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
		#endif
		o.tangentToWorldAndParallax0.w = viewDirForParallax.x;
		o.tangentToWorldAndParallax1.w = viewDirForParallax.y;
		o.tangentToWorldAndParallax2.w = viewDirForParallax.z;
	#endif
	
	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			o.tex = half4(normalWorld, v.uv1.x); // pack UV1 here
		#else
			o.tex = half4(v.normal, v.uv1.x); // pack UV1 here
		#endif
	#else
		o.tex = TexCoordsNoTransform(v);
	#endif
	
	UNITY_TRANSFER_FOG(o,o.pos);
	return o;
}

void fragForwardAdd (VertexOutputForwardAdd i, out half4 outCol : SV_Target
#if defined(_2SIDED)
,half facing : VFACE
#endif
#if defined(ZWRITE)
,out half outDepth : DEPTH_SEMANTIC
#endif
)
{
	UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

	#if defined(_2SIDED)
		#if UNITY_VFACE_FLIPPED
			facing = -facing;
		#endif
		#if UNITY_VFACE_AFFECTED_BY_PROJECTION
			facing *= _ProjectionParams.x; // take possible upside down rendering into account
		#endif	
		#if defined(TRIPLANAR_SELECTIVE)
			i.tex.xyz *= facing>0 ? 1 : -1;
		#else
			i.tangentToWorldAndParallax2 *= facing>0 ? 1 : -1;
		#endif
	#endif
	
	#if defined(TRIPLANAR_SELECTIVE)
		// unpack UV1
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			half2 secUV=half2(i.tex.w, i.eyeVec.w);
		#else
			half2 secUV=half2(i.tex.w, i.posObject.w);
		#endif		
	#endif
	
	// ------
	half actH;
	half4 SclCurv;
	half3 eyeVec;
	
	half3 tangentBasisScaled;
	
	half2 _ddx;
	half2 _ddy;
	half2 _ddxDet;
	half2 _ddyDet;
	half blendFade;
	
	half3 i_viewDirForParallax;
	half3x3 _TBN;
	half3 worldNormal;
	
	half4 texcoordsNoTransform;
	
	// void	SetupUBER(half4 i_SclCurv, half3 i_eyeVec, half3 i_posWorld, half3 i_posObject, inout half4 i_tex, inout half4 i_tangentToWorldAndParallax0, inout half4 i_tangentToWorldAndParallax1, inout half4 i_tangentToWorldAndParallax2, inout fixed4 vertex_color, out half actH, out half4 SclCurv, out half3 eyeVec, out half3 tangentBasisScaled, out half2 _ddx, out half2 _ddy, out half2 _ddxDet, out half2 _ddyDet, out half blendFade, out half3 i_viewDirForParallax, out half3x3 _TBN, out half3 worldNormal) {
	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		SetupUBER(half4(0,0,0,0), half3(0,0,0), i.posWorld.xyz, i.posObject.xyz, /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		SetupUBER(i.SclCurv, half3(0,0,0), i.posWorld.xyz, half3(0,0,0), /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#else
		SetupUBER(half4(0,0,0,0), i.eyeVec.xyz, i.posWorld.xyz, half3(0,0,0), /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#endif
	// ------	

//#if defined(VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED)
//		half3 diffuseTint = i.diffuseTint;
//#else
		half3 diffuseTint = half3(0.5, 0.5, 0.5); // n/u
		half3 diffuseTint2 = half3(0.5, 0.5, 0.5);
//#endif

	FRAGMENT_SETUP_FWDADD(s)
	
	#if defined(ZWRITE)
		s.posWorld.xyz += s.rayLength*s.eyeVec;
	#endif
	
	half2 occ=Occlusion(i.tex, _ddx, _ddy, _ddxDet, _ddyDet, i.vertex_color); // y - translucency/glitter
	#if defined(_TRANSLUCENCY)
		// translucency occlusion might be taken from UV1
		#if defined(TRIPLANAR_SELECTIVE)
			// already unpacked secUV		
		#else
			#if defined(SECONDARY_OCCLUSION_PARALLAXED)
				half2 secUV=((i.tex.xy-_MainTex_ST.zw)/_MainTex_ST.xy - texcoordsNoTransform.xy) + texcoordsNoTransform.zw;
			#else
				half2 secUV=texcoordsNoTransform.zw; // actually we don't need parallax applied as we assume secondary occlusion is low freq maybe
			#endif
		#endif
		secUV = _UVSecOcclusionLightmapPacked==1 ? (secUV * unity_LightmapST.xy + unity_LightmapST.zw) : secUV;
		// translucency mask from UV1
		half translucency_thickness_fromOccMap = tex2Dp(_OcclusionMap, secUV,  ddx(secUV),  ddy(secUV)).AUX_OCCLUSION_CHANNEL;
		// UV0 / UV1 occlusion switch
		half translucency_thickness = _UVSecOcclusion==0 ? occ.y : translucency_thickness_fromOccMap;
	#endif
	
	// push lighting coords
	#if defined(ZWRITE)
		#if defined (SHADOWS_DEPTH) && defined (SPOT)
			// spot lights - more expensive recast World2Shadow matrix...
			i._ShadowCoord = mul (unity_WorldToShadow[0], half4(s.posWorld.xyz,1));
		#elif defined (SHADOWS_CUBE)
			// point light - easy stuff - just push it towards viewing vector
			i._ShadowCoord+=s.rayLength*s.eyeVec;
		#endif
	#endif
	 
	
	#if defined(DIRECTIONAL)
		half3 lightDir = _WorldSpaceLightPos0.xyz;
		UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld.xyz, shadow_atten)
		UnityLight light = AdditiveLight(lightDir, 1); // no dummy atten applied here, shadow atten applied after translucecy suppressing
	#else
		#if UBER_MATCH_ALLOY_LIGHT_FALLOFF
			//
			// match attenuation falloff of Alloy
			//
			half3 lightDir = (_WorldSpaceLightPos0.xyz - s.posWorld.xyz * _WorldSpaceLightPos0.w);
//			#ifndef ALLOY_DISABLE_AREA_LIGHTS
//				half3 lightDirArea = lightDir;
//				half3 _R=reflect( (s.posWorld.xyz-_WorldSpaceCameraPos), s.normalWorld);
//				half3 centerToRay = dot(lightDir, _R) * _R - lightDir;
//				half light_size = _LightColor0.a / _LightPositionRange.w; // lightColor.a*range
//				lightDirArea += centerToRay * saturate(light_size / length(centerToRay));
//				lightDirArea = normalize(lightDirArea);
//			#endif
			half light_distSqr = dot(lightDir, lightDir);
			half light_dist = sqrt(light_distSqr);
			lightDir/=light_dist;
			#ifdef SPOT
				half rangeInv = length(i._LightCoord.xyz) / light_dist;
			#else
				half rangeInv=_LightPositionRange.w; // seems that this works _LightPositionRange.w=1/range
			#endif
			half ratio = light_dist * rangeInv;
			half ratio2 = ratio * ratio;
			half num = saturate(1.0h - (ratio2 * ratio2));
			half latten = (num * num) / (light_distSqr + 1.0h);
			#ifdef POINT_COOKIE
				latten *= texCUBE(_LightTexture0, i._LightCoord).w;
			#endif
			#ifdef SPOT
				latten *= (i._LightCoord.z > 0) * UnitySpotCookie(i._LightCoord);
			#endif			
//			#ifndef ALLOY_DISABLE_AREA_LIGHTS
//				// dir for lighting - area lights corrected
//				// (TODO - currently doesn't work - area lights are more than light dir correction only)
//				lightDir = lightDirArea;		
//			#endif
			UnityLight light = AdditiveLight (lightDir, latten); // light attenuation calculated by Alloy
			half shadow_atten = UNITY_SHADOW_ATTENUATION(i, s.posWorld.xyz); // while shadow_atten we need to pick ourselves
		#else
			//
			// regular Unity's light with default attenuation (w/o shadows though)
			//
			half3 lightDir = normalize(_WorldSpaceLightPos0.xyz - s.posWorld.xyz * _WorldSpaceLightPos0.w);
			UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld.xyz, shadow_atten)
			UnityLight light = AdditiveLight (lightDir, atten);
		#endif
	#endif

	#if (defined(_PARALLAX_POM_SHADOWS) || defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS)) && defined(_UBER_SHADOWS_FORWARDADD)
		#if defined(_SNOW) && !defined(_POM_DISTANCE_MAP_SHADOWS) && !defined(_POM_EXTRUSION_MAP_SHADOWS)
			bool SS_flag=(saturate(s.snowVal*_SnowDeepSmoothen)<0.98);
		#else
			bool SS_flag=true;
		#endif
		if (SS_flag) {
			half3 lightDirInTanSpace=mul(light.dir, transpose(s.tanToWorld));
			#if defined(_SNOW) && !defined(_POM_DISTANCE_MAP_SHADOWS) && !defined(_POM_EXTRUSION_MAP_SHADOWS)
				light.color *= SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, s.snowVal);
			#else
				#if defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS)
					light.color *= lerp( SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, 0), 1, saturate( distance(s.posWorld.xyz, _WorldSpaceCameraPos) / _DepthReductionDistance ) );
				#else
					light.color *= SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, 0);
				#endif				
			#endif
		}
	#endif
	UnityIndirect noIndirect = ZeroIndirect ();
	
	// translucency
	#if defined(_TRANSLUCENCY)
		half3 TL=Translucency(s, light, translucency_thickness, i.vertex_color);
		s.diffColor*=saturate(1-max(max(TL.r, TL.g), TL.b)*TRANSLUCENCY_SUPPRESS_DIFFUSECOLOR);
		shadow_atten=lerp( shadow_atten, 1, saturate( dot(TL,0.3)*_TranslucencySuppressRealtimeShadows ) );
	#endif	
	
	// apply shadows here (they can be suppressed by translucency)
	light.color*=shadow_atten;
	
	#if defined(_GLITTER)
		Glitter(/* inout */ s, i.tex.zw, _ddxDet, _ddyDet, s.posWorld.xyz, i.vertex_color, lerp(1, occ.y, _GlitterMask));
	#endif	
		
	half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect);
	
	#if defined(_TRANSLUCENCY)
		c.rgb += TL*light.color;
	#endif	
		
	UNITY_APPLY_FOG_COLOR(i.fogCoord, c.rgb, half4(0,0,0,0)); // fog towards black in additive pass

	#if DECAL_PIERCEABLE
		if (_Pierceable == true) {
			half2 screenUV = (i.screenPos.xy / i.screenPos.w);
			#if !defined(SHADER_API_OPENGL) && !defined(SHADER_API_GLCORE) && !defined(SHADER_API_GLES3)
				screenUV.y = _ProjectionParams.x>0 ? 1 - screenUV.y : screenUV.y;
			#endif

			//half piercingDepthBuffer = tex2D(_PiercingDepthBuffer, screenUV).r; // linear depth stored in Rhalf buffer (depth of surface where piercing decal is placed with small offset to prevent fighting)
			//half ldepth = i.screenPos.z; // linear eye depth passed from vertex program
			//half depthFade = 1 - saturate(abs(piercingDepthBuffer - ldepth) * 16);

			half2 piercingBuffer = tex2D(_PiercingBuffer, screenUV).rg;
			half forwardDecalAlpha = piercingBuffer.g * 4;
			half piercingValue = saturate((_PiercingThreshold - piercingBuffer.r) * 20);
			forwardDecalAlpha = 1 - saturate(forwardDecalAlpha); 
			forwardDecalAlpha *= piercingValue;
			s.alpha *= forwardDecalAlpha; // fadeout pixels written by piercing decal
			//s.alpha *= piercingValue; // fadeout pixels written by piercing decal
			c.rgb *= forwardDecalAlpha; // fadeout specular highlights
			//c.rgb *= piercingValue; // remove completely the hole
		}
	#endif

	#if defined(LOD_FADE_CROSSFADE) && (defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON))
		s.alpha *= unity_LODFade.x;
	#endif
	outCol=OutputForward (c, s.alpha);
	
	#if defined(ZWRITE)
		//half depthWithOffset = i.posWorld.w+s.rayLength;
		half depthWithOffset = i.posWorld.w*(1+s.rayLength/distance(i.posWorld.xyz, _WorldSpaceCameraPos)); // Z-DEPTH perspective correction
		outDepth = (1.0 - depthWithOffset * _ZBufferParams.w) / (depthWithOffset * _ZBufferParams.z);
	#endif	
}

// ------------------------------------------------------------------
//  Deferred pass

struct VertexOutputDeferred
{
	UNITY_POSITION(pos);
	half4 tex							: TEXCOORD0; // normal in triplanar (.w means UV1 - u coord for triplanar - needed for secondary occlusion)
	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		half4 posObject				: TEXCOORD1; // .w means UV1 - v coord for triplanar (needed for secondary occlusion)
	#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		half4 SclCurv					: TEXCOORD1;
	#else
		half4 eyeVec 					: TEXCOORD1; // .w means UV1 - v coord for triplanar (needed for secondary occlusion)
	#endif
	half4 tangentToWorldAndParallax0	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:viewDirForParallax] - note: tangents+obj scale in triplanar (tangents in world space when mapping in world space)
	half4 tangentToWorldAndParallax1	: TEXCOORD3;	// (array fails in GLSL optimizer)
	half4 tangentToWorldAndParallax2	: TEXCOORD4;
	half4 ambientOrLightmapUV			: TEXCOORD5;	// SH or Lightmap UVs			
	fixed4 vertex_color					: COLOR0;		// UBER

	#if defined(ZWRITE)
		half4 posWorld					: TEXCOORD6;
	#else
		half3 posWorld					: TEXCOORD6;
	#endif

	half4 screenUV							: TEXCOORD7;

	#if defined(VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED)
		half3 diffuseTint					: TEXCOORD8;
	#elif defined(VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED)
		half3 diffuseTint					: TEXCOORD8;
		half3 diffuseTint2					: TEXCOORD9;
	#endif

	UNITY_VERTEX_OUTPUT_STEREO
};

#if defined(VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED)
uniform half3 diffuseTintArray[16];
#elif defined(VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED)
uniform half3 diffuseTintArray[16];
uniform half3 diffuseTintArrayB[16];
#endif


VertexOutputDeferred vertDeferred (VertexInput v)
{
	UNITY_SETUP_INSTANCE_ID(v);
	VertexOutputDeferred o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputDeferred, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	#if defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		half2 Curv=frac(v.uv3);
		half2 Scl=(v.uv3-Curv)/100; // scale represented with 0.01 resolution (fair enough)
		Scl=Scl*_Tan2ObjectMultOffset.xy+_Tan2ObjectMultOffset.zw;
		#if defined(VERTEX_COLOR_CHANNEL_POMZ)
			v.vertex.xyz+=_POM_ExtrudeVolume ? v.normal.xyz*v.color.VERTEX_COLOR_CHANNEL_POMZ*_Depth*max(Scl.x, Scl.y)/max(_MainTex_ST.x, _MainTex_ST.y) : half3(0,0,0);
			// Curv.x==0 - extruded bottom flag
			v.color.VERTEX_COLOR_CHANNEL_POMZ = Curv.x==0 || (!_POM_ExtrudeVolume) ? v.color.VERTEX_COLOR_CHANNEL_POMZ : 1-v.color.VERTEX_COLOR_CHANNEL_POMZ;
			//Curv=0; // no curvature on extruded volumes (we need bottom flag info in parallax function though - so DON'T zero Curv here !)
			// if we don't handle the volume set the curvature data to desired range
			Curv = _POM_ExtrudeVolume ? Curv : Curv*20-10;
		#else
			Curv=Curv*20-10; // Curv=(Curv-0.5)*10; // we assume curvature won't be higher than +/- 10
		#endif
	#endif
	
	o.pos = UnityObjectToClipPos(v.vertex);
	o.screenUV = ComputeScreenPos(o.pos);
	COMPUTE_EYEDEPTH(o.screenUV.z); // used for pierceables, reused below for zwrite

	half4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.posWorld.xyz = posWorld.xyz; // UBER - there was implicit truncation here
	#if defined(ZWRITE)
		//COMPUTE_EYEDEPTH(o.posWorld.w);
		o.posWorld.w = o.screenUV.z;
	#endif		
	o.vertex_color = v.color; // UBER

	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		//o.posObject set below
	#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		o.SclCurv=half4(half2(1.0,1.0)/Scl, Curv);
	#else
		o.eyeVec.xyz = posWorld.xyz - _WorldSpaceCameraPos;
		#if defined(TRIPLANAR_SELECTIVE)
			// world mapping
			o.eyeVec.w = v.uv1.y;
		#endif
	#endif
	
	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			half3 normalWorld = UnityObjectToWorldNormal(v.normal);
			SetupUBER_VertexData_TriplanarWorld(normalWorld, /* inout */ o.tangentToWorldAndParallax0, /* inout */ o.tangentToWorldAndParallax1, /* inout */ o.tangentToWorldAndParallax2);
		#else
			half scaleX, scaleY, scaleZ;
			SetupUBER_VertexData_TriplanarLocal(v.normal, /* inout */ o.tangentToWorldAndParallax0, /* inout */ o.tangentToWorldAndParallax1, /* inout */ o.tangentToWorldAndParallax2, /* out */ scaleX, /* out */ scaleY, /* out */ scaleZ);
			half3 normalWorld = UnityObjectToWorldNormal(v.normal);
			o.posObject.xyz = v.vertex.xyz;
			o.posObject.w = v.uv1.y; // pack it here
		#endif		
	#elif defined(_TANGENT_TO_WORLD)
		half3x3 tangentToWorld;
		
		// we need to go from tangent to world space for zwrite and parallaxed snow (actually when snow is mapped in worldspace)
		#if defined(RAYLENGTH_AVAILABLE)
			half3 normalWorld = mul((half3x3)unity_ObjectToWorld, v.normal.xyz);
			half3 tangentWorld = mul((half3x3)unity_ObjectToWorld, v.tangent.xyz);
			half3 binormalWorld = mul((half3x3)unity_ObjectToWorld, cross(v.normal.xyz, v.tangent.xyz)*v.tangent.w);
			#ifdef SHADER_TARGET_GLSL
			binormalWorld*=0.9999; // dummy op to cheat HLSL2GLSL optimizer to not be so smart (and buggy) here... It probably tries to make some fancy matrix by matrix calculation
			#endif
			// not normalized basis (we need it for texture 2 worldspace ratio calculations)
			tangentToWorld=half3x3(tangentWorld, binormalWorld, normalWorld);
			normalWorld = normalize(normalWorld); // we need it below for lighting
		#else
			half3 normalWorld = UnityObjectToWorldNormal(v.normal);
			half4 tangentWorld = half4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
			tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, v.tangent.w);
		#endif


		o.tangentToWorldAndParallax0.xyz = tangentToWorld[0];
		o.tangentToWorldAndParallax1.xyz = tangentToWorld[1];
		o.tangentToWorldAndParallax2.xyz = tangentToWorld[2];
	#else
		half3 normalWorld = UnityObjectToWorldNormal(v.normal);
		o.tangentToWorldAndParallax0.xyz = 0;
		o.tangentToWorldAndParallax1.xyz = 0;
		o.tangentToWorldAndParallax2.xyz = normalWorld;
	#endif

	#ifdef LIGHTMAP_ON
		o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		o.ambientOrLightmapUV.zw = 0;
	#elif UNITY_SHOULD_SAMPLE_SH
		#if (SHADER_TARGET < 30)
			o.ambientOrLightmapUV.rgb = ShadeSH9(half4(normalWorld, 1.0));
		#else
			// Optimization: L2 per-vertex, L0..L1 per-pixel
			o.ambientOrLightmapUV.rgb = ShadeSH3Order(half4(normalWorld, 1.0));
		#endif
	#endif
	
	#ifdef DYNAMICLIGHTMAP_ON
		o.ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	#endif
	
	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			// .w component not used
		#else
			o.tangentToWorldAndParallax0.w=scaleX;
			o.tangentToWorldAndParallax1.w=scaleY;
			o.tangentToWorldAndParallax2.w=scaleZ;
		#endif
	#elif defined(_PARALLAXMAP) || defined(_PARALLAXMAP_2MAPS) || defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		#if ((defined(POM)) && defined(SILHOUETTE_CURVATURE_MAPPED)) || defined(TRIPLANAR_SELECTIVE)
			half3 viewDirForParallax = ObjSpaceViewDir(v.vertex);
		#else
			// vertex normal, tangent are not guaranteed to be normalized (!)
			// try - 2 simple planes on the scene using the same material, anchored and parent has decreased scale, Unity makes kind of batch (vertices seems to be transformed to world space) ? Anyway mesh tangents, normals get scaled, too and makes total mess with TBN matrices (view direction...)
			v.normal=normalize(v.normal);
			v.tangent.xyz=normalize(v.tangent.xyz);
			half3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
			half3x3 rotation = half3x3( v.tangent.xyz, binormal, v.normal );
			half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
		#endif
		o.tangentToWorldAndParallax0.w = viewDirForParallax.x;
		o.tangentToWorldAndParallax1.w = viewDirForParallax.y;
		o.tangentToWorldAndParallax2.w = viewDirForParallax.z;
	#endif
	
	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			o.tex = half4(normalWorld, v.uv1.x); // pack UV1 here
		#else
			o.tex = half4(v.normal, v.uv1.x);
		#endif
	#else
		o.tex = TexCoordsNoTransform(v);
	#endif

	#if defined(VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED)
		uint idx = uint(clamp(floor(v.color.VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED*255),0,15));
		o.diffuseTint = diffuseTintArray[idx];
	#elif defined(VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED)
		uint idx = uint(clamp(frac(v.color.VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED * 16)*16, 0, 15));
		o.diffuseTint = diffuseTintArray[idx];
		idx = uint(clamp(floor(v.color.VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED * 16), 0, 15));
		o.diffuseTint2 = diffuseTintArrayB[idx];
	#endif
		
	return o;
}

// mask for decals to store in gfubber2.a (normals - 2 bits)
fixed _DecalMask;
#if defined(_SNOW)
	fixed _DecalMaskForSnow;
	fixed _DecalMaskForSnowThreshold;
#endif

void fragDeferred (
	VertexOutputDeferred i,
	out half4 outGBuffer0 : SV_Target0,			// RT0: diffuse color (rgb), occlusion (a)
	out half4 outGBuffer1 : SV_Target1,			// RT1: spec color (rgb), smoothness (a)
	out half4 outGBuffer2 : SV_Target2,			// RT2: normal (rgb), Decal mask (a)
	out half4 outEmission : SV_Target3			// RT3: emission (rgb), translucency encoded (a)
#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
	, out half4 outShadowMask : SV_Target4       // RT4: shadowmask (rgba)
#endif
#if defined(_2SIDED)
,half facing : VFACE
#endif
#if defined(ZWRITE)
,out half outDepth : DEPTH_SEMANTIC
#endif	
)
{
    #if (SHADER_TARGET < 30)
        outGBuffer0 = 1;
        outGBuffer1 = 1;
        outGBuffer2 = 0;
        outEmission = 0;
        #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
            outShadowMask = 1;
        #endif
        return;
    #endif

	UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

	#if DECAL_PIERCEABLE
	if (_Pierceable == true) {
		half4 screen_uv = half4(i.screenUV.xy / i.screenUV.w, 0, 0);
		half pierceMaskDepth = tex2Dlod(_PiercingBuffer, screen_uv).r; // linear depth stored in Rhalf buffer (depth of surface where piercing decal is placed with small offset to prevent fighting)
		half ldepth = i.screenUV.z; // linear eye depth passed from vertex program
		clip(pierceMaskDepth > ldepth ? -1 : 1);
	}
	#endif
	
	#if defined(_2SIDED)
		#if UNITY_VFACE_FLIPPED
			facing = -facing;
		#endif
		#if UNITY_VFACE_AFFECTED_BY_PROJECTION
			facing *= _ProjectionParams.x; // take possible upside down rendering into account
		#endif	
		#if defined(TRIPLANAR_SELECTIVE)
			i.tex.xyz *= facing>0 ? 1 : -1;
		#else
			i.tangentToWorldAndParallax2 *= facing>0 ? 1 : -1;
		#endif
	#endif
		
	#if defined(TRIPLANAR_SELECTIVE)
		// unpack UV1
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			half2 secUV=half2(i.tex.w, i.eyeVec.w);
		#else
			half2 secUV=half2(i.tex.w, i.posObject.w);
		#endif		
	#endif
		
	// ------
	half actH;
	half4 SclCurv;
	half3 eyeVec;
	
	half3 tangentBasisScaled;
	
	half2 _ddx;
	half2 _ddy;
	half2 _ddxDet;
	half2 _ddyDet;
	half blendFade;
	
	half3 i_viewDirForParallax;
	half3x3 _TBN;
	half3 worldNormal;
	
	half4 texcoordsNoTransform;
	
	// void	SetupUBER(half4 i_SclCurv, half3 i_eyeVec, half3 i_posWorld, half3 i_posObject, inout half4 i_tex, inout half4 i_tangentToWorldAndParallax0, inout half4 i_tangentToWorldAndParallax1, inout half4 i_tangentToWorldAndParallax2, inout fixed4 vertex_color, out half actH, out half4 SclCurv, out half3 eyeVec, out half3 tangentBasisScaled, out half2 _ddx, out half2 _ddy, out half2 _ddxDet, out half2 _ddyDet, out half blendFade, out half3 i_viewDirForParallax, out half3x3 _TBN, out half3 worldNormal) {
	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		SetupUBER(half4(0,0,0,0), half3(0,0,0), IN_WORLDPOS(i), i.posObject.xyz, /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#elif defined(POM) || defined(DISTANCE_MAP) || defined(EXTRUSION_MAP)
		SetupUBER(i.SclCurv, half3(0,0,0), IN_WORLDPOS(i), half3(0,0,0), /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#else
		SetupUBER(half4(0,0,0,0), i.eyeVec.xyz, IN_WORLDPOS(i), half3(0,0,0), /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#endif
	// ------	
	
#if defined(VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED)
	half3 diffuseTint=i.diffuseTint;
	half3 diffuseTint2 = half3(0.5, 0.5, 0.5);
#elif defined(VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED)
	half3 diffuseTint = i.diffuseTint;
	half3 diffuseTint2 = i.diffuseTint2;
#else
	half3 diffuseTint = half3(0.5, 0.5, 0.5);
	half3 diffuseTint2 = half3(0.5, 0.5, 0.5);
#endif


	FRAGMENT_SETUP(s)

	// no analytic lights in this pass
	UnityLight dummyLight = DummyLight ();
	half atten = 1;

	// only GI
	half2 occ=Occlusion(i.tex, _ddx, _ddy, _ddxDet, _ddyDet, i.vertex_color); // y - translucency/glitter
	half occlusion = occ.x;
	#if defined(OCCLUSION_VERTEX_COLOR_CHANNEL)
		occlusion*=i.vertex_color.OCCLUSION_VERTEX_COLOR_CHANNEL;
	#endif
	#if defined(_TWO_LAYERS)
		occlusion = LerpOneTo(occlusion, lerp(_OcclusionStrength2, _OcclusionStrength, i.__VERTEX_COLOR_CHANNEL_LAYER));
	#else
		occlusion = LerpOneTo(occlusion, _OcclusionStrength);
	#endif

	#if defined(_TRANSLUCENCY)
		half translucency_thickness_fromOccMap = 1;
	#endif
	if (_Occlusion_from_albedo_alpha) { // uniform bool (half for sake of d3d9 compatibility)
		// possible 2ndary occlusion
		// primary occlusion from diffuse A, secondary from _OcclusionMap
		#if defined(TRIPLANAR_SELECTIVE)
			// already unpacked secUV
		#else
			#if defined(SECONDARY_OCCLUSION_PARALLAXED)
				half2 secUV=((i.tex.xy-_MainTex_ST.zw)/_MainTex_ST.xy - texcoordsNoTransform.xy) + texcoordsNoTransform.zw;
			#else
				half2 secUV=texcoordsNoTransform.zw; // actually we don't need parallax applied as we assume secondary occlusion is low freq maybe
			#endif
		#endif
		secUV = _UVSecOcclusionLightmapPacked==1 ? (secUV * unity_LightmapST.xy + unity_LightmapST.zw) : secUV;
		half4 occVal = tex2Dp(_OcclusionMap, secUV,  ddx(secUV),  ddy(secUV));
		half2 occ2 = half2(occVal.AMBIENT_OCCLUSION_CHANNEL, occVal.AUX_OCCLUSION_CHANNEL);
		// UV0 / UV1 occlusion switch
		occlusion *= (_UVSecOcclusion==0) ? 1 : lerp(1, occ2.x, _SecOcclusionStrength);
		#if defined(_TRANSLUCENCY)
			// translucency mask from UV1
			translucency_thickness_fromOccMap = occ2.y;
		#endif
	}
	
	#if defined(_SNOW)
		occlusion*=lerp(1, s.dissolveMaskValue, s.snowVal*_SnowDissolveMaskOcclusion);
	#endif	
	#if defined(TRIPLANAR_SELECTIVE)
		occlusion*=lerp(1, blendFade, _TriplanarBlendAmbientOcclusion);
	#endif
	#if defined(_SNOW)
		occlusion=lerp(occlusion, 1, saturate(s.snowVal*_SnowDeepSmoothen*0.15));
	#endif	
			
	#if defined(_TRANSLUCENCY)
		// UV0 / UV1 occlusion switch
		half translucency_thickness = _UVSecOcclusion==0 ? occ.y : translucency_thickness_fromOccMap;
		translucency_thickness=lerp(1, translucency_thickness, _TranslucencyOcclusion);
	#endif	

#if UNITY_ENABLE_REFLECTION_BUFFERS
	bool sampleReflectionsInDeferred = false;
#else
	bool sampleReflectionsInDeferred = true;
#endif
	UnityGI gi = FragmentGI(s, occlusion, i.ambientOrLightmapUV, atten, dummyLight, sampleReflectionsInDeferred);


	// baked light POM self-shadows
	bool SS_flag;
	#if defined(_POM_BAKED_SELF_SHADOWS) && (defined(_PARALLAX_POM_SHADOWS) || defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS)) && defined(LIGHTMAP_ON) && defined(DIRLIGHTMAP_SEPARATE)
		//half sNdotL=dot(s.tanToWorld[2].xyz, gi.light.dir);
		//if (sNdotL>0) {
		//	half3 lightDirInTanSpace=mul(s.tanToWorld, gi.light.dir);
		//	gi.light.color *= lerp( 1, SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace), saturate(sNdotL*30));
		//}
		#if defined(_SNOW) && !defined(_POM_DISTANCE_MAP_SHADOWS) && !defined(_POM_EXTRUSION_MAP_SHADOWS)
			SS_flag=(saturate(s.snowVal*_SnowDeepSmoothen)<0.98);
		#else
			SS_flag=true;
		#endif
		if (SS_flag) {
			half3 lightDirInTanSpace=mul(s.tanToWorld, gi.light.dir); // named tanToworld but this mul() actually works the opposite (as I swapped params in mul)
			#if defined(_SNOW) && !defined(_POM_DISTANCE_MAP_SHADOWS) && !defined(_POM_EXTRUSION_MAP_SHADOWS)
				gi.light.color *= SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, s.snowVal);
			#else
				#if defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS)
					gi.light.color *= lerp( SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, 0), 1, saturate( distance(i.posWorld, _WorldSpaceCameraPos) / _DepthReductionDistance ) );
				#else
					gi.light.color *= SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, 0);
				#endif				
			#endif
		}
	#endif		
	
	#if defined(_GLITTER)
		Glitter(/* inout */ s, i.tex.zw, _ddxDet, _ddyDet, i.posWorld.xyz, i.vertex_color, lerp(1, occ.y, _GlitterMask));
	#endif
		
	half3 emissiveColor = UNITY_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect).rgb;

	#if defined(_GLITTER) && UNITY_HDR_ON
		emissiveColor += s.specColor * ShadeSH9(half4(s.normalWorld, 1))*occlusion; // in deferred gbuffer for spec is LDR, we need to add it here directly to HDR light/emission gbuffer
	#endif

	// emissiveness always available in UBER
	#if defined(_SNOW)
		half snowBlur=_SnowDeepSmoothen*4*s.snowVal; // currently not used
		half3 snowEmissionDamp=LerpWhiteTo(_SnowEmissionTransparency, s.snowVal);
	#else
		half snowBlur=0; // not used
		half3 snowEmissionDamp=1;
	#endif

	#if defined(EMISSION_AT_THE_OTHER_SIDE)
		snowEmissionDamp *= saturate(dot(-i.tangentToWorldAndParallax2, DeferredLightDir(i.posWorld.xyz))*4);
	#endif

	emissiveColor += Emission(i.tex.xyzw, i.vertex_color, _ddx, _ddy, snowBlur)*snowEmissionDamp; // UBER - 4 components (main uv, detail uv) & vertex colors
	emissiveColor += s.additionalEmission*snowEmissionDamp; // UBER - detail/wet emission
	
	#ifndef UNITY_HDR_ON
		emissiveColor.rgb = exp2(-emissiveColor.rgb);
	#endif
	
	
	// translucency
	#if defined(_TRANSLUCENCY)
		half TranslucencyColor_a=_TranslucencyColor.a;
		#if defined(_TWO_LAYERS)
			TranslucencyColor_a=lerp(_TranslucencyColor2.a, _TranslucencyColor.a, i.__VERTEX_COLOR_CHANNEL_LAYER);
		#endif
		#if defined(_SNOW)
			translucency_thickness*=lerp(TranslucencyColor_a,_SnowTranslucencyColor.a, s.snowVal);
		#else
			translucency_thickness*=TranslucencyColor_a;
		#endif	
	#endif	

	// realtime light POM self-shadows
	half SS=1;
	#if defined(_POM_REALTIME_SELF_SHADOWS) && (defined(_PARALLAX_POM_SHADOWS) || defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS))
		half3 lightDir=(DeferredLightDir(i.posWorld.xyz));
		#if defined(_SNOW) && !defined(_POM_DISTANCE_MAP_SHADOWS) && !defined(_POM_EXTRUSION_MAP_SHADOWS)
			SS_flag=dot(lightDir, s.normalWorld)>0 && (saturate(s.snowVal*_SnowDeepSmoothen)<0.98);
		#else
			SS_flag=dot(lightDir, s.normalWorld)>0;
		#endif
		if (SS_flag) {
			half3 lightDirInTanSpace=mul(s.tanToWorld, lightDir); // named tanToworld but this mul() actually works the opposite (as I swapped params in mul)
			#if defined(_SNOW) && !defined(_POM_DISTANCE_MAP_SHADOWS) && !defined(_POM_EXTRUSION_MAP_SHADOWS)
				SS = SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, s.snowVal);
			#else
				#if defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS)
					SS = lerp( SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, 0), 1, saturate( distance(i.posWorld, _WorldSpaceCameraPos) / _DepthReductionDistance ) );
				#else
					SS = SelfShadows(s.rayPos, s.texture2ObjectRatio, lightDirInTanSpace, 0);
				#endif				
			#endif
		}
	#endif		

	// HDR only (we store 0..2047 2^11 integer value in half precision significand)
	half encoded = 0;
	#if defined(_TRANSLUCENCY)
		encoded = floor(saturate(translucency_thickness*_TranslucencyStrength)*15); // 4 bits - 0..15 translucency levels
		encoded *= 4; // shift left 2 bits to make room for translucency index
		encoded += _TranslucencyDeferredLightIndex; // + 0..3 light color index
	#endif
	encoded *= 4; // shift left 2 bits to make room for self shadowing value
	#if defined(_POM_REALTIME_SELF_SHADOWS) && (defined(_PARALLAX_POM_SHADOWS) || defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS))
		encoded += floor((1 - SS) * 3); // 0..3 integer self-shadowing range
	#endif
	encoded *= 8; // shift left 3 bits to make room for wetness value
	#if defined(_WETNESS)
		// make sure s.Wetness is normalized 0..1 !
		encoded += floor(s.Wetness * 7); // 0..7 integer wetness range
	#elif defined(_SNOW)
//		encoded += floor( saturate((_DecalMaskForSnowThreshold - s.snowVal)/_DecalMaskForSnowThreshold) * 7); // 0..7 integer range
//		encoded += floor(saturate(s.snowVal) * 7); // 0..7 integer range
	#endif
	#if defined(_TRANSLUCENCY) || (defined(_POM_REALTIME_SELF_SHADOWS) && (defined(_PARALLAX_POM_SHADOWS) || defined(_POM_DISTANCE_MAP_SHADOWS) || defined(_POM_EXTRUSION_MAP_SHADOWS))) || defined(_WETNESS)
		// any of above props written
		encoded = -encoded; // negative number means we encoded values, positive value is supposed to be 1 only
	#else
		encoded = 1; // default value written by Unity standard shader which means - we've got all props zeroed (no translucency, SS nor wetness)
	#endif

	#if defined(_SNOW)
		fixed DecalMask = s.snowVal > _DecalMaskForSnowThreshold ? _DecalMaskForSnow : _DecalMask;
	#else
		fixed DecalMask = _DecalMask;
	#endif

	UnityStandardData data;
	data.diffuseColor	= s.diffColor;
	data.occlusion		= occlusion;		
	data.specularColor	= s.specColor;
	data.smoothness		= s.smoothness;	
	data.normalWorld	= s.normalWorld;

	UnityStandardDataToGbuffer(data, outGBuffer0, outGBuffer1, outGBuffer2);

	outGBuffer2.w = DecalMask; // UBER (decal mask)
	outEmission = half4(emissiveColor, encoded); // encoded UBER props

	#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
		outShadowMask = UnityGetRawBakedOcclusions(i.ambientOrLightmapUV.xy, i.posWorld.xyz);
	#endif

	#if defined(ZWRITE)
		//half depthWithOffset = i.posWorld.w+s.rayLength;
		half depthWithOffset = i.posWorld.w*(1+s.rayLength/distance(i.posWorld.xyz, _WorldSpaceCameraPos)); // Z-DEPTH perspective correction
		outDepth = (1.0 - depthWithOffset * _ZBufferParams.w) / (depthWithOffset * _ZBufferParams.z);
	#endif	
}					


// ------------------------------------------------------------------------------------
//
// tessellation
//
#if defined(_TESSELLATION) && defined(UNITY_CAN_COMPILE_TESSELLATION) && !defined(UNITY_PASS_META)

	struct UnityTessellationFactors {
		half edge[3] : SV_TessFactor;
		half inside : SV_InsideTessFactor;
	};

	// tessellation vertex shader
	struct InternalTessInterp_appdata {
	  half4 vertex : INTERNALTESSPOS;
	  half3 normal : NORMAL;
	  half2 uv1 : TEXCOORD1;
	  half2 uv2 : TEXCOORD2;
	  half4 color : COLOR;
	  #if !defined(TRIPLANAR_SELECTIVE)
	  half4 tangent : TANGENT;
	  half2 uv0 : TEXCOORD0;
	  #endif
	  #if defined(UNITY_SUPPORT_INSTANCING) && defined(INSTANCING_ON)
		uint instanceID : TEXCOORD3;
	  #endif
	};
	InternalTessInterp_appdata tessvert_surf (VertexInput v) {
	  InternalTessInterp_appdata o;
	  o.vertex = v.vertex;
	  o.normal = v.normal;
	  o.uv1 = v.uv1;
	  o.uv2 = v.uv2;
	  o.color = v.color;
	  #if !defined(TRIPLANAR_SELECTIVE)
	  o.tangent = v.tangent;
	  o.uv0 = v.uv0;
	  #endif
	  UNITY_TRANSFER_INSTANCE_ID(v, o);
	  return o;
	}

	// tessellation hull constant shader
	UnityTessellationFactors hsconst_surf (InputPatch<InternalTessInterp_appdata,3> v) {
	  UnityTessellationFactors o;
	  half4 tf;
	  VertexInput vi[3];
	  vi[0].vertex = v[0].vertex;
	  vi[0].normal = v[0].normal;
	  vi[0].uv1 = v[0].uv1;
	  vi[0].uv2 = v[0].uv2;
	  vi[0].color = v[0].color;
	  vi[1].vertex = v[1].vertex;
	  vi[1].normal = v[1].normal;
	  vi[1].uv1 = v[1].uv1;
	  vi[1].uv2 = v[1].uv2;
	  vi[1].color = v[1].color;
	  vi[2].vertex = v[2].vertex;
	  vi[2].normal = v[2].normal;
	  vi[2].uv1 = v[2].uv1;
	  vi[2].uv2 = v[2].uv2;
	  vi[2].color = v[2].color;
	  #if !defined(TRIPLANAR_SELECTIVE)
	  vi[0].tangent = v[0].tangent;
	  vi[0].uv0 = v[0].uv0;
	  vi[1].tangent = v[1].tangent;
	  vi[1].uv0 = v[1].uv0;
	  vi[2].tangent = v[2].tangent;
	  vi[2].uv0 = v[2].uv0;
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

	/* _Paint3DAccumulator_ */
	// tessellation domain shader
	[UNITY_domain("tri")]
	v2f_struct ds_surfPaint3DAccumulator (UnityTessellationFactors tessFactors, const OutputPatch<InternalTessInterp_appdata,3> vi, half3 bary : SV_DomainLocation) {
	  VertexInput v;
	  v.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
	  v.normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
	  v.uv1 = vi[0].uv1*bary.x + vi[1].uv1*bary.y + vi[2].uv1*bary.z;
	  v.uv2 = vi[0].uv2*bary.x + vi[1].uv2*bary.y + vi[2].uv2*bary.z;
	  v.color = vi[0].color*bary.x + vi[1].color*bary.y + vi[2].color*bary.z;
	  #if !defined(TRIPLANAR_SELECTIVE)
	  v.tangent = vi[0].tangent*bary.x + vi[1].tangent*bary.y + vi[2].tangent*bary.z;
	  v.uv0 = vi[0].uv0*bary.x + vi[1].uv0*bary.y + vi[2].uv0*bary.z;
	  #endif
	  UNITY_TRANSFER_INSTANCE_ID(vi[0], v); // all vi[n] has the same instanceID transferred

	  //
	  // compute displacement
	  //
	  #if defined(_TESSELLATION_DISPLACEMENT)
		fixed4 vertex_color=v.color;
		half3 normalWorld = UnityObjectToWorldNormal(v.normal);
		
		half4 posWorld = mul(unity_ObjectToWorld, v.vertex);
		
		#if defined(_SNOW)
			half _snow_val = _SnowColorAndCoverage.a*__VERTEX_COLOR_CHANNEL_SNOW;
			_snow_val *= saturate((posWorld.y-_SnowHeightThreshold)/_SnowHeightThresholdTransition);
			_snow_val = saturate( _snow_val - (1-normalWorld.y)*_SnowSlopeDamp );
			_snow_val *= _SnowLevelFromGlobal ? (1-_UBER_GlobalSnowDamp) : 1;
		#endif
	  
		half d=0; // displacement value
		#if defined(TRIPLANAR_SELECTIVE)
			#if defined(_TRIPLANAR_WORLD_MAPPING)
				half3 normBlend=normalWorld;
				half3 posUVZ=posWorld.xyz;
				half3 blendVal = abs(normBlend);
			#else
				half scaleX = length(half3(unity_ObjectToWorld[0][0], unity_ObjectToWorld[1][0], unity_ObjectToWorld[2][0]));
				half scaleY = length(half3(unity_ObjectToWorld[0][1], unity_ObjectToWorld[1][1], unity_ObjectToWorld[2][1]));
				half scaleZ = length(half3(unity_ObjectToWorld[0][2], unity_ObjectToWorld[1][2], unity_ObjectToWorld[2][2]));
				
				half3 objScale=half3(scaleX, scaleY, scaleZ);
				half3 normObj=v.normal;
				half3 normBlend=normObj;
				half3 normObjScaled=normalize(normObj/objScale);
				half3 posUVZ=v.vertex.xyz*objScale;
				half3 blendVal = abs(normObjScaled);
			#endif	
			
			#if defined(_SNOW)
				half level=_SnowDeepSmoothen*saturate(_snow_val-0.3);
			#else
				half level=0;
			#endif
						

			
			/*
			struct appdata_P3DA
			{
				half4 vertex : POSITION;
				#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
				half3 normal : NORMAL;
				#endif
				half2 uv : TEXCOORD0;
			};

			struct v2f_P3DA
			{
				half2 uv : TEXCOORD0;
				half3 worldPos : TEXCOORD1;
				half4 vertex : SV_POSITION;
				#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
				half3 normal : TEXCOORD2;
				#endif
			};
			*/
			/*
			appdata_P3DA aP3DA;
			aP3DA.vertex = v.vertex;
			#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
			aP3DA.normal = v.normal;
			#endif
			aP3DA.uv = v.uv1;
			half vertexHeight = 0;
			v2f_P3DA ret = Paint3DAccumulatorVertexLogic_P0(aP3DA, vertexHeight);
			#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
			v.normal = ret.normal;
			#endif
			v.uv1 = ret.uv;
			*/
			
			

			half3 uvz = posUVZ.xyz*_MainTex_ST.xxx;
			half3 hVal = half3(tex2Dlod(_ParallaxMap, (normBlend.x>0) ? half4(uvz.zy, level.xx) : half4(-uvz.z,uvz.y, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap, (normBlend.y>0) ? half4(uvz.xz, level.xx) : half4(-uvz.x,uvz.z, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap, (normBlend.z>0) ? half4(uvz.yx, level.xx) : half4(-uvz.y,uvz.x, level.xx)).PARALLAX_CHANNEL);
			#if defined(_TWO_LAYERS)
				half3 uvz2 = posUVZ.xyz*_DetailAlbedoMap_ST.xxx;
				#if defined(_PARALLAXMAP_2MAPS)
					half3 hVal2 = half3(tex2Dlod(_ParallaxMap2, (normBlend.x>0) ? half4(uvz2.zy, level.xx) : half4(-uvz2.z,uvz2.y, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap2, (normBlend.y>0) ? half4(uvz2.xz, level.xx) : half4(-uvz2.x,uvz2.z, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap2, (normBlend.z>0) ? half4(uvz2.yx, level.xx) : half4(-uvz2.y,uvz2.x, level.xx)).PARALLAX_CHANNEL);
				#else
					half3 hVal2 = half3(tex2Dlod(_ParallaxMap2, (normBlend.x>0) ? half4(uvz2.zy, level.xx) : half4(-uvz2.z,uvz2.y, level.xx)).PARALLAX_CHANNEL_2ND_LAYER, tex2Dlod(_ParallaxMap2, (normBlend.y>0) ? half4(uvz2.xz, level.xx) : half4(-uvz2.x,uvz2.z, level.xx)).PARALLAX_CHANNEL_2ND_LAYER, tex2Dlod(_ParallaxMap2, (normBlend.z>0) ? half4(uvz2.yx, level.xx) : half4(-uvz2.y,uvz2.x, level.xx)).PARALLAX_CHANNEL_2ND_LAYER);
				#endif
				hVal = lerp( hVal2, hVal, __VERTEX_COLOR_CHANNEL_LAYER);
			#endif
			/*
			hVal += half3(ReadFromPaintAccumulationRT( (normBlend.x>0) ? half4(uvz.zy, level.xx) : half4(-uvz.z,uvz.y, level.xx)).PARALLAX_CHANNEL, ReadFromPaintAccumulationRT( (normBlend.y>0) ? half4(uvz.xz, level.xx) : half4(-uvz.x,uvz.z, level.xx)).PARALLAX_CHANNEL, ReadFromPaintAccumulationRT( (normBlend.z>0) ? half4(uvz.yx, level.xx) : half4(-uvz.y,uvz.x, level.xx)).PARALLAX_CHANNEL);
			#if defined(_TWO_LAYERS)
				//uvz2 = posUVZ.xyz*_DetailAlbedoMap_ST.xxx;
				#if defined(_PARALLAXMAP_2MAPS)
					hVal2 += half3(ReadFromPaintAccumulationRT( (normBlend.x>0) ? half4(uvz2.zy, level.xx) : half4(-uvz2.z,uvz2.y, level.xx)).PARALLAX_CHANNEL, ReadFromPaintAccumulationRT( (normBlend.y>0) ? half4(uvz2.xz, level.xx) : half4(-uvz2.x,uvz2.z, level.xx)).PARALLAX_CHANNEL, ReadFromPaintAccumulationRT( (normBlend.z>0) ? half4(uvz2.yx, level.xx) : half4(-uvz2.y,uvz2.x, level.xx)).PARALLAX_CHANNEL);
				#else
					hVal2 += half3(ReadFromPaintAccumulationRT( (normBlend.x>0) ? half4(uvz2.zy, level.xx) : half4(-uvz2.z,uvz2.y, level.xx)).PARALLAX_CHANNEL_2ND_LAYER, ReadFromPaintAccumulationRT( (normBlend.y>0) ? half4(uvz2.xz, level.xx) : half4(-uvz2.x,uvz2.z, level.xx)).PARALLAX_CHANNEL_2ND_LAYER, ReadFromPaintAccumulationRT( (normBlend.z>0) ? half4(uvz2.yx, level.xx) : half4(-uvz2.y,uvz2.x, level.xx)).PARALLAX_CHANNEL_2ND_LAYER);
				#endif
				hVal += lerp( hVal2, hVal, __VERTEX_COLOR_CHANNEL_LAYER);
			#endif
			hval *= _HeightMapStrength_P3DA;
			*/
		
			blendVal += _TriplanarHeightmapBlendingValue*hVal;
			blendVal /= dot(blendVal,1);
			blendVal*=blendVal;
			blendVal*=blendVal;
			blendVal /= dot(blendVal,1);
			
			#if defined(_TWO_LAYERS)
				// need to call GetH to set height blending between layers
				{
				half2 control=half2(__VERTEX_COLOR_CHANNEL_LAYER, 1-__VERTEX_COLOR_CHANNEL_LAYER);
				half2 hgt=half2(dot(hVal2, blendVal), dot(hVal, blendVal));
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
			half4 texcoords;
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
		half approxTan2ObjectRatio=distance(vi[1].vertex, vi[0].vertex) / distance(TRANSFORM_TEX(vi[0].uv0, _MainTex), TRANSFORM_TEX(vi[1].uv0, _MainTex));
	  #else
		half approxTan2ObjectRatio=1;
	  #endif
	  d = d - _TessOffset;
	  #if defined(GEOM_BLEND)
		d = lerp(d, 0, vertex_color.VERTEX_COLOR_CHANNEL_GEOM_BLEND);
	  #endif
	  #if defined(VERTEX_COLOR_CHANNEL_TESELLATION_DISPLACEMENT_AMOUNT)
		d = lerp(0, d, vertex_color.VERTEX_COLOR_CHANNEL_TESELLATION_DISPLACEMENT_AMOUNT);
	  #endif
	  d *= saturate( 1.0 - (distance(_WorldSpaceCameraPos,posWorld) - minDist) / ( (maxDist+minDist)*0.5 - minDist) );
	  
	// displacement
	#endif
	  
	if (_Phong>0) {
		half3 pp[3];
		for (int i = 0; i < 3; ++i)
		pp[i] = v.vertex.xyz - vi[i].normal * (dot(v.vertex.xyz, vi[i].normal) - dot(vi[i].vertex.xyz, vi[i].normal));
		v.vertex.xyz = _Phong * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-_Phong) * v.vertex.xyz;
	}
	
	half customVertexDispl = 0;
	#ifdef _CUSTOM_VERTEX_DISPLACEMENT_
	half2 readuv = TexCoords(v);
	//half2 readuv = TexCoordsNoTransform(v);
	half4 vertexDisplPaint = ReadFromPaintAccumulationRT(readuv)*_HeightMapStrength_P3DA;//v.uv1
	half alphaFlag = frac(floor(vertexDisplPaint.a*10)/10);
	if(alphaFlag == .4)
		customVertexDispl = (vertexDisplPaint.x + vertexDisplPaint.y + vertexDisplPaint.z)/3;
	#endif

	#if defined(_CUSTOM_VERTEX_DISPLACEMENT_) && defined(_TESSELLATION_DISPLACEMENT)
	  v.vertex.xyz += v.normal * (d + customVertexDispl) * _TessDepth * approxTan2ObjectRatio;
	#elif defined(_TESSELLATION_DISPLACEMENT)
	  v.vertex.xyz += v.normal * d * _TessDepth * approxTan2ObjectRatio;
	#elif defined(_CUSTOM_VERTEX_DISPLACEMENT_)
	  v.vertex.xyz += v.normal * (d + customVertexDispl)* approxTan2ObjectRatio;	  
	#endif

	

	  v2f_struct o = VERT_SURF(v);
	  return o;
	}

	// tessellation domain shader
	[UNITY_domain("tri")]
	v2f_struct ds_surf (UnityTessellationFactors tessFactors, const OutputPatch<InternalTessInterp_appdata,3> vi, half3 bary : SV_DomainLocation) {
	  VertexInput v;
	  v.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
	  v.normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
	  v.uv1 = vi[0].uv1*bary.x + vi[1].uv1*bary.y + vi[2].uv1*bary.z;
	  v.uv2 = vi[0].uv2*bary.x + vi[1].uv2*bary.y + vi[2].uv2*bary.z;
	  v.color = vi[0].color*bary.x + vi[1].color*bary.y + vi[2].color*bary.z;
	  #if !defined(TRIPLANAR_SELECTIVE)
	  v.tangent = vi[0].tangent*bary.x + vi[1].tangent*bary.y + vi[2].tangent*bary.z;
	  v.uv0 = vi[0].uv0*bary.x + vi[1].uv0*bary.y + vi[2].uv0*bary.z;
	  #endif
	  UNITY_TRANSFER_INSTANCE_ID(vi[0], v); // all vi[n] has the same instanceID transferred

	  //
	  // compute displacement
	  //
	  #if defined(_TESSELLATION_DISPLACEMENT)
		fixed4 vertex_color=v.color;
		half3 normalWorld = UnityObjectToWorldNormal(v.normal);
		
		half4 posWorld = mul(unity_ObjectToWorld, v.vertex);
		
		#if defined(_SNOW)
			half _snow_val = _SnowColorAndCoverage.a*__VERTEX_COLOR_CHANNEL_SNOW;
			_snow_val *= saturate((posWorld.y-_SnowHeightThreshold)/_SnowHeightThresholdTransition);
			_snow_val = saturate( _snow_val - (1-normalWorld.y)*_SnowSlopeDamp );
			_snow_val *= _SnowLevelFromGlobal ? (1-_UBER_GlobalSnowDamp) : 1;
		#endif
	  
		half d=0; // displacement value
		#if defined(TRIPLANAR_SELECTIVE)
			#if defined(_TRIPLANAR_WORLD_MAPPING)
				half3 normBlend=normalWorld;
				half3 posUVZ=posWorld.xyz;
				half3 blendVal = abs(normBlend);
			#else
				half scaleX = length(half3(unity_ObjectToWorld[0][0], unity_ObjectToWorld[1][0], unity_ObjectToWorld[2][0]));
				half scaleY = length(half3(unity_ObjectToWorld[0][1], unity_ObjectToWorld[1][1], unity_ObjectToWorld[2][1]));
				half scaleZ = length(half3(unity_ObjectToWorld[0][2], unity_ObjectToWorld[1][2], unity_ObjectToWorld[2][2]));
				
				half3 objScale=half3(scaleX, scaleY, scaleZ);
				half3 normObj=v.normal;
				half3 normBlend=normObj;
				half3 normObjScaled=normalize(normObj/objScale);
				half3 posUVZ=v.vertex.xyz*objScale;
				half3 blendVal = abs(normObjScaled);
			#endif	
			
			#if defined(_SNOW)
				half level=_SnowDeepSmoothen*saturate(_snow_val-0.3);
			#else
				half level=0;
			#endif
						
			half3 uvz = posUVZ.xyz*_MainTex_ST.xxx;
			half3 hVal = half3(tex2Dlod(_ParallaxMap, (normBlend.x>0) ? half4(uvz.zy, level.xx) : half4(-uvz.z,uvz.y, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap, (normBlend.y>0) ? half4(uvz.xz, level.xx) : half4(-uvz.x,uvz.z, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap, (normBlend.z>0) ? half4(uvz.yx, level.xx) : half4(-uvz.y,uvz.x, level.xx)).PARALLAX_CHANNEL);
			#if defined(_TWO_LAYERS)
				half3 uvz2 = posUVZ.xyz*_DetailAlbedoMap_ST.xxx;
				#if defined(_PARALLAXMAP_2MAPS)
					half3 hVal2 = half3(tex2Dlod(_ParallaxMap2, (normBlend.x>0) ? half4(uvz2.zy, level.xx) : half4(-uvz2.z,uvz2.y, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap2, (normBlend.y>0) ? half4(uvz2.xz, level.xx) : half4(-uvz2.x,uvz2.z, level.xx)).PARALLAX_CHANNEL, tex2Dlod(_ParallaxMap2, (normBlend.z>0) ? half4(uvz2.yx, level.xx) : half4(-uvz2.y,uvz2.x, level.xx)).PARALLAX_CHANNEL);
				#else
					half3 hVal2 = half3(tex2Dlod(_ParallaxMap2, (normBlend.x>0) ? half4(uvz2.zy, level.xx) : half4(-uvz2.z,uvz2.y, level.xx)).PARALLAX_CHANNEL_2ND_LAYER, tex2Dlod(_ParallaxMap2, (normBlend.y>0) ? half4(uvz2.xz, level.xx) : half4(-uvz2.x,uvz2.z, level.xx)).PARALLAX_CHANNEL_2ND_LAYER, tex2Dlod(_ParallaxMap2, (normBlend.z>0) ? half4(uvz2.yx, level.xx) : half4(-uvz2.y,uvz2.x, level.xx)).PARALLAX_CHANNEL_2ND_LAYER);
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
				half2 control=half2(__VERTEX_COLOR_CHANNEL_LAYER, 1-__VERTEX_COLOR_CHANNEL_LAYER);
				half2 hgt=half2(dot(hVal2, blendVal), dot(hVal, blendVal));
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
			half4 texcoords;
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
		half approxTan2ObjectRatio=distance(vi[1].vertex, vi[0].vertex) / distance(TRANSFORM_TEX(vi[0].uv0, _MainTex), TRANSFORM_TEX(vi[1].uv0, _MainTex));
	  #else
		half approxTan2ObjectRatio=1;
	  #endif
	  d = d - _TessOffset;
	  #if defined(GEOM_BLEND)
		d = lerp(d, 0, vertex_color.VERTEX_COLOR_CHANNEL_GEOM_BLEND);
	  #endif
	  #if defined(VERTEX_COLOR_CHANNEL_TESELLATION_DISPLACEMENT_AMOUNT)
		d = lerp(0, d, vertex_color.VERTEX_COLOR_CHANNEL_TESELLATION_DISPLACEMENT_AMOUNT);
	  #endif
	  d *= saturate( 1.0 - (distance(_WorldSpaceCameraPos,posWorld) - minDist) / ( (maxDist+minDist)*0.5 - minDist) );
	  
	// displacement
	#endif
	  
	if (_Phong>0) {
		half3 pp[3];
		for (int i = 0; i < 3; ++i)
		pp[i] = v.vertex.xyz - vi[i].normal * (dot(v.vertex.xyz, vi[i].normal) - dot(vi[i].vertex.xyz, vi[i].normal));
		v.vertex.xyz = _Phong * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-_Phong) * v.vertex.xyz;
	}
			
	#if defined(_TESSELLATION_DISPLACEMENT)
	  v.vertex.xyz += v.normal * d * _TessDepth * approxTan2ObjectRatio;
	#endif
	  
	  v2f_struct o = VERT_SURF(v);
	  return o;
	}

#endif // TESSELLATION

//============================= META ==============================
#if UNITY_PASS_META
struct v2f_meta
{
	UNITY_POSITION(pos);
	half4 tex							: TEXCOORD0; // normal in triplanar
	half4 tangentToWorldAndParallax0	: TEXCOORD1;	// [3x3:tangentToWorld | 1x3:viewDirForParallax] - note: tangents+obj scale in triplanar (tangents in world space when mapping in world space)
	half4 tangentToWorldAndParallax1	: TEXCOORD2;	// (array fails in GLSL optimizer)
	half4 tangentToWorldAndParallax2	: TEXCOORD3;
	half3 eyeVec						: TEXCOORD4;
	fixed4 vertex_color					: COLOR0;
	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
	half3 posObject					: TEXCOORD5;
	#endif	
	#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
		half3 posWorld					: TEXCOORD6;
	#endif	

#if defined(VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED)
		half3 diffuseTint					: TEXCOORD7;
#elif defined(VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED)
		half3 diffuseTint					: TEXCOORD7;
		half3 diffuseTint2					: TEXCOORD8;
#endif

};

v2f_meta vert_meta (VertexInput v)
{
	v2f_meta o;
	UNITY_INITIALIZE_OUTPUT(v2f_meta, o);


	// input v.vertex is actually used for nothing now, but openGL needs such implicit input ?
	o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
	
	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		o.posObject.xyz = v.vertex.xyz;
	#endif
	
	half4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
		o.posWorld.xyz = posWorld.xyz;
	#endif
	o.vertex_color = v.color;
	o.eyeVec = normalize(posWorld.xyz - _WorldSpaceCameraPos);	
	
	#if !defined(TRIPLANAR_SELECTIVE)
		//half3 normalWorld = UnityObjectToWorldNormal(v.normal); // FIXME - for unknown reason normalWorld isn't actually computed here (either _World2Object, _Object2World or v.vnormal has incorrect values here)
		half3 normalWorld = UnityObjectToWorldDir(v.normal.xyz); // still can't tell if this is any better...
	#endif
	
	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			half3 normalWorld = UnityObjectToWorldDir(v.normal.xyz);
			SetupUBER_VertexData_TriplanarWorld(normalWorld, /* inout */ o.tangentToWorldAndParallax0, /* inout */ o.tangentToWorldAndParallax1, /* inout */ o.tangentToWorldAndParallax2);
		#else
			half scaleX, scaleY, scaleZ;
			SetupUBER_VertexData_TriplanarLocal(v.normal, /* inout */ o.tangentToWorldAndParallax0, /* inout */ o.tangentToWorldAndParallax1, /* inout */ o.tangentToWorldAndParallax2, /* out */ scaleX, /* out */ scaleY, /* out */ scaleZ);
			o.posObject.xyz = v.vertex.xyz;
		#endif		
	#elif defined(_TANGENT_TO_WORLD)	
		half4 tangentWorld = half4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

		half3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
		o.tangentToWorldAndParallax0.xyz = tangentToWorld[0];
		o.tangentToWorldAndParallax1.xyz = tangentToWorld[1];
		o.tangentToWorldAndParallax2.xyz = tangentToWorld[2];
	#else
		o.tangentToWorldAndParallax0.xyz = 0;
		o.tangentToWorldAndParallax1.xyz = 0;
		o.tangentToWorldAndParallax2.xyz = normalWorld;
	#endif	
	
	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			// .w component not used
		#else
			o.tangentToWorldAndParallax0.w=scaleX;
			o.tangentToWorldAndParallax1.w=scaleY;
			o.tangentToWorldAndParallax2.w=scaleZ;
		#endif
	#endif
		
	#if defined(TRIPLANAR_SELECTIVE)
		#if defined(_TRIPLANAR_WORLD_MAPPING)
			o.tex = half4(normalWorld,0);
			// o.tangentToWorldAndParallax[n].w component not used
		#else
			o.tex = half4(v.normal,0);
			o.tangentToWorldAndParallax0.w=scaleX;
			o.tangentToWorldAndParallax1.w=scaleY;
			o.tangentToWorldAndParallax2.w=scaleZ;
		#endif
	#else
		o.tex = TexCoords(v);
	#endif	

#if defined(VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED)
		uint idx = uint(clamp(floor(v.color.VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED * 255), 0, 15));
		o.diffuseTint = diffuseTintArray[idx];
#elif defined(VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED)
		uint idx = uint(clamp(frac(v.color.VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED * 16) * 16, 0, 15));
		o.diffuseTint = diffuseTintArray[idx];
		idx = uint(clamp(floor(v.color.VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED * 16), 0, 15));
		o.diffuseTint2 = diffuseTintArrayB[idx];
#endif

	return o;
}

// Albedo for lightmapping should basically be diffuse color.
// But rough metals (black diffuse) still scatter quite a lot of light around, so
// we want to take some of that into account too.
half3 UnityLightmappingAlbedo (half3 diffuse, half3 specular, half smoothness)
{
	half roughness = 1 - smoothness;
	half3 res = diffuse;
	res += specular * roughness * roughness * 0.5;
	return res;
}

half4 frag_meta (v2f_meta i
#if defined(_2SIDED)
,half facing : VFACE
#endif
) : SV_Target
{
	#if defined(_2SIDED)
		#if UNITY_VFACE_FLIPPED
			facing = -facing;
		#endif
		#if UNITY_VFACE_AFFECTED_BY_PROJECTION
			facing *= _ProjectionParams.x; // take possible upside down rendering into account
		#endif	
		#if defined(TRIPLANAR_SELECTIVE)
			i.tex.xyz *= facing>0 ? 1 : -1;
		#else
			i.tangentToWorldAndParallax2 *= facing>0 ? 1 : -1;
		#endif
	#endif
	
	#ifdef UNITY_REQUIRE_FRAG_WORLDPOS
		half3 posWorld=i.posWorld.xyz;
	#else
		half3 posWorld=0;
	#endif
	
	half actH;
	half4 SclCurv;
	half3 eyeVec;
	
	half3 tangentBasisScaled;
	
	half2 _ddx;
	half2 _ddy;
	half2 _ddxDet;
	half2 _ddyDet;
	half blendFade;
	
	half3 i_viewDirForParallax;
	half3x3 _TBN;
	half3 worldNormal;
	
	half4 texcoordsNoTransform;
	
	// void	SetupUBER(half4 i_SclCurv, half3 i_eyeVec, half3 i_posWorld, half3 i_posObject, inout half4 i_tex, inout half4 i_tangentToWorldAndParallax0, inout half4 i_tangentToWorldAndParallax1, inout half4 i_tangentToWorldAndParallax2, inout fixed4 vertex_color, out half actH, out half4 SclCurv, out half3 eyeVec, out half3 tangentBasisScaled, out half2 _ddx, out half2 _ddy, out half2 _ddxDet, out half2 _ddyDet, out half blendFade, out half3 i_viewDirForParallax, out half3x3 _TBN, out half3 worldNormal) {
	#if defined(TRIPLANAR_SELECTIVE) && !defined(_TRIPLANAR_WORLD_MAPPING)
		SetupUBER(half4(0,0,0,0), half3(0,0,0), posWorld, i.posObject.xyz, /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#else
		SetupUBER(half4(0,0,0,0), half3(0,0,0), posWorld, half3(0,0,0), /* inout */ i.tex, /* inout */ i.tangentToWorldAndParallax0, /* inout */ i.tangentToWorldAndParallax1, /* inout */ i.tangentToWorldAndParallax2, /* inout */ i.vertex_color, /* out */ actH, /* out */ SclCurv, /* out */ eyeVec, /* out */ tangentBasisScaled, /* out */ _ddx, /* out */ _ddy, /* out */ _ddxDet, /* out */ _ddyDet, /* out */ blendFade, /* out */ i_viewDirForParallax, /* out */ _TBN, /* out */ worldNormal, /* out */ texcoordsNoTransform);
	#endif
	// ------	
	
	// inline FragmentCommonData FragmentSetup (inout half4 i_tex, half3 i_eyeVec, half3 i_normalWorld, inout half3 i_viewDirForParallax, inout half3x3 i_tanToWorld, half3 i_posWorld, inout fixed4 vertex_color, half2 _ddx, half2 _ddy, half2 _ddxDet, half2 _ddyDet, half3 tangentBasisScaled, half4 SclCurv, half blendFade, half actH) // UBER - additional params added
//	FragmentSetup(i.tex, eyeVec, worldNormal, i_viewDirForParallax, _TBN, IN_WORLDPOS(i), i.vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, tangentBasisScaled, SclCurv, blendFade, actH, diffuseTint, diffuseTint2); // UBER - additional params added
#if defined(VERTEX_COLOR_RGB_TO_ALBEDO_INDEXED)
		half3 diffuseTint = i.diffuseTint;
		half3 diffuseTint2 = half3(0.5, 0.5, 0.5);
#elif defined(VERTEX_COLOR_RGB_TO_ALBEDO_DOUBLE_INDEXED)
		half3 diffuseTint = i.diffuseTint;
		half3 diffuseTint2 = i.diffuseTint2;
#else
		half3 diffuseTint = half3(0.5, 0.5, 0.5);
		half3 diffuseTint2 = half3(0.5, 0.5, 0.5);
#endif
	FragmentCommonData s = FragmentSetup(i.tex, half3(0,0,0), worldNormal, i_viewDirForParallax, _TBN, posWorld, i.vertex_color, _ddx, _ddy, _ddxDet, _ddyDet, tangentBasisScaled, SclCurv, 1, actH, diffuseTint, diffuseTint2);
	#if defined(_SNOW)
		half snowBlur=_SnowDeepSmoothen*4*s.snowVal; // currently not used
		half3 snowEmissionDamp=LerpWhiteTo(_SnowEmissionTransparency, s.snowVal);
	#else
		half snowBlur=0; // not used
		half3 snowEmissionDamp=1;
	#endif

	#if defined(EMISSION_AT_THE_OTHER_SIDE)
		snowEmissionDamp *= saturate(dot(-i.tangentToWorldAndParallax2, DeferredLightDir(i.posWorld.xyz))*4);
	#endif
	
	UnityMetaInput o;
	UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);

	o.Albedo = UnityLightmappingAlbedo (s.diffColor, s.specColor, s.smoothness);
	o.Emission = Emission(i.tex.xyzw, i.vertex_color, _ddx, _ddy, snowBlur)*snowEmissionDamp; // UBER - 4 components (main uv, detail uv) + vertex color (for masking), under snow blurring
	o.Emission += s.additionalEmission*snowEmissionDamp; // UBER - detail/wet emission
	return UnityMetaFragment(o);
}
#endif // META
//============================= META ==============================

#endif // UBER_STANDARD_CORE_INCLUDED
