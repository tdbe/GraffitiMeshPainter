Shader /*ase_name*/ "Custom/3DPaintAccumulator_AmplifyTemplate_Multipass" /*end*/
{



	Properties
	{
		
		_Color_("Color", Color) = (1.000000,1.000000,1.000000,1.000000)
		_EraserColor("Eraser Color", Color) = (0.000000,0.000000,0.000000,0.000000)
		_Color_Picker("Color Picker Color", 2D) = "white" {}
		
		_Color_PickerDisplay("Color Picker Display Texture", 2D) = "white" {}
		_MainTex_("_MainTex_", 2D) = "white" {}
		_MainTex_Screen("_MainTex_Screen (should be a RT)", 2D) = "white" {}
		_MainTex_Internal("_MainTex_Internal (should be a RT)", 2D) = "white" {}
		//_MainTex_Internal_Sampler("_MainTex_Internal_Sampler (should be from RT)", 2D) = "white" {}
		
		_BgTex("_BgTex (black by default)", 2D) = "white" {}
		_ToolOutlineTex("Tool Ring Outline texture", 2D) = "white" {}
		_BrushScaleOffset("Brush Scale Offset", float) = 0.05

		_BrushScaleMod("Brush Scale Mod", float) = 0.05
		//_DistanceFadeOffset("Distance Fade Offset", float) = 1
		//_DistanceFadeScale("Distance Fade Scale", float) = 1
		_PlayParams("Play Params", vector) = (1,1,1,1)
		//_ControllerScale("Controller Scale", vector) = (1,1,1,1)
		//_ControllerOffset("Controller Offset", vector) = (1,1,1,1)

		_Init("Init BGTexture", float) = 1

		_ConeShapeXY("Cone Shape XY, cone Z offset, base fade W", vector) = (1,1,1,1)
		//_SprayCentreHardness("Spray Centre Hardness", float) = 1
		_ConeScale("Cone Scale", float) = 1
		_ConeScale2("Cone Scale 2", float) = 1
		_ConeScalePow("Cone Scale Pow", float) = 1
		//_ConeZStop("Cone Z Stop", float) = 1
		_ConeClamp("Cone Clamp", float) = 0.01

		_FadeShapeXY("Fade Shape XY, fade Z offset, base fade W", vector) = (1,1,1,1)
		_FadeScalePow("Fade Scale Pow", float) = 1
		_FadeScale("Fade Scale", vector) = (1,1,1,1)
		_BlendSubtraction("Blend Subtraction", float) = 2
		_BlendAddition("Blend Addition", float) = 2

		_TargetRingLocation("Target Ring Location", float) = 1
		_TargetRingThickness("Target Ring Thickness", float) = 1

		_SprayBlend("Spray Blend", float) = 1
		_EraseBlend("Erase Blend", float) = 1

		_Color_SampleDist("Color Sample Distance From Centre of Picker", float) = 1
		_Color_SampleDist_ST("Color Sample Distance ST", vector) = (1,1,1,1)
		_Color_SampleThresh("Color Sample Distance Threshold", float) = 1
		_Color_SamplerVolume("Color Sampler Volume XYZ + Scale", vector) = (1,1,1,1)

		/*ase_props*/
		
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		//Tags{ "RenderType" = "Transparent" "Queue" = "Transparent+10" }
		//Tags{ "lightmode" = "deferred" }
		LOD 100
		//Blend SrcAlpha OneMinusSrcAlpha

		CGINCLUDE
		#pragma target 5.0
		#pragma only_renderers d3d11
		#include "UnityCG.cginc"
		/*ase_pragma*/
		#define CUSTOM_VERTEX_DISPLACEMENT 0
		

	struct ControllerData
	{
		float3 position;
		//float3 targetPos;
		//float3 normal;
		//float3 paintingParams;//0 or 1 or -10 if inactve
		float3 color;

	};



	struct appdata
	{
		float4 vertex : POSITION;
		#if CUSTOM_VERTEX_DISPLACEMENT
		float3 normal : NORMAL;
		#endif
		float2 uv : TEXCOORD0;
		/*ase_vdata:p=p;n=n;uv0=tc0.xy*/
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float3 worldPos : TEXCOORD1;
		float4 vertex : SV_POSITION;
		#if CUSTOM_VERTEX_DISPLACEMENT
		float3 normal : TEXCOORD2;
		#endif
		/*ase_interp(0.zw,7):sp=sp.xyzw;uv0=tc0.xy*/
	};



	float4 _Color_;
	float4 _EraserColor;
	sampler2D _MainTex_;
	float4 _MainTex__ST;

	//sampler2D _MainTex_Internal;

	/// Contains the accumulated paint data
	uniform RWTexture2D<float4> _MainTex_Internal : register(u3);
	//uniform Texture2D<float4> _MainTex_Screen_Reader;// : register(u2);	
	//uniform sampler2D _MainTex_Screen_Reader;// : register(u2);	
	//float4 _MainTex_Internal_ST;
	//sampler2D _MainTex_Internal_Sampler;


	//sampler2D _MainTex_Screen;
	//SamplerState samplerInput;
	/// Contains the accumulated paint data + everything not painted on, like color picker, tooltips etc.
	uniform RWTexture2D<float4> _MainTex_Screen : register(u2);
	//float4 _MainTex_Screen_ST;
	


	sampler2D _BgTex;
	float4 _BgTex_ST;




	float _BrushScaleMod;
	float _BrushScaleOffset;
	//float _DistanceFadeOffset;
	//float _DistanceFadeScale;
	float4 _PlayParams;
	//float4 _BrushPosWS[2];
	//float4 _BrushNormal[2];
	//float4 _ControllerScale;
	//float4 _ControllerOffset;
	static const int BRUSH_COUNT = 2;
	//StructuredBuffer<ControllerData> _BrushBuffer;
	uniform RWStructuredBuffer<ControllerData> _BrushBuffer : register(u1);
	uniform float4 _PositionWS[BRUSH_COUNT];
	uniform float4 _PositionSS[BRUSH_COUNT];
	uniform float3 _PaintingParams[BRUSH_COUNT];
	uniform float4x4 _Matrix_iTR[BRUSH_COUNT];
	float _Init;

	float4 _ConeShapeXY;
	//float _SprayCentreHardness;
	float _ConeScale;
	float _ConeScale2;
	float _ConeScalePow;
	float _ConeClamp;

	float4 _FadeShapeXY;
	float _FadeScalePow;
	float4 _FadeScale;

	float _BlendSubtraction;
	float _BlendAddition;

	float _TargetRingLocation;
	float _TargetRingThickness;

	float _SprayBlend;
	float _EraseBlend;

	float _Color_SampleThresh;

	
	/*ase_globals*/


	struct FragmentOutput
	{
		float4 color : SV_Target0;
		float4 colorInternal : SV_Target1;

	};

	float sdCylinder(float3 p, float3 c)
	{
		return length(p.xz - c.xy) - c.z;
	}

	float sdCone(float3 p, float2 c, float zStop)// iq
	{
		// c must be normalized
		float q = length(p.xy);
		if (p.z > zStop)
			return dot(c, float2(q, p.z));
		else return 0;
	}

	//cone section
	float sdCone2(float3 p, float r1, float h)//, float r2)
	{
		float d1 = -p.y - h;
		float q = p.y - h;
		//float si = 0.5*(r1 - r2) / h;
		float si = 0.5*(r1) / h;
		//float d2 = max(sqrt(dot(p.xz, p.xz)*(1.0 - si*si)) + q*si - r2, q);
		float d2 = max(sqrt(dot(p.xz, p.xz)*(1.0 - si*si)) + q*si, q);
		return length(max(float2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
	}

	// Cone with correct distances to tip and base circle. Y is up, 0 is in the middle of the base.
	float sdCone3(float3 p, float radius, float height)
	{
		float2 q = float2(length(p.xz), p.y);
		float2 tip = q - float2(0, height);
		float2 mantleDir = normalize(float2(height, radius));
		float mantle = dot(tip, mantleDir);
		float d = max(mantle, -q.y);
		float projected = dot(tip, float2(mantleDir.y, -mantleDir.x));

		// distance to tip
		if ((q.y > height) && (projected < 0)) {
			d = max(d, length(tip));
		}

		// distance to base ring
		if ((q.x > radius) && (projected > length(float2(height, radius)))) {
			d = max(d, length(q - float2(radius, 0)));
		}
		return d;
	}

	float sdSphere(float3 p, float s)
	{
		return length(p) - s;
	}

	float2 opU(float d1, float d2)
	{
		return (d1<d2) ? d1 : d2;
	}

	float opI(float d1, float d2)
	{
		return max(d1, d2);
	}

	float map(float s, float a1, float a2, float b1, float b2)
	{
		return b1 + (s - a1)*(b2 - b1) / (a2 - a1);
	}

	// power smooth min (k = 8);
	float2 smin(float2 a, float2 b, float k)
	{

		a.x = pow(a.x, k);
		b.x = pow(b.x, k);
		float2 res;

		res.x = pow((a.x*b.x) / (a.x + b.x), 1.0 / k);


		res.y = (a.x < b.x) ? a.y : b.y;


		return res;
	}

	// power smooth min (k = 8);
	float smax(float a, float b, float k)
	{
		return a.x + b.x - pow(a.x*a.x + b.x*b.x, -k); // http://www.hyperfun.org/HOMA08/48890118.pdf


	}


	float2 opBlendSmin(float2 d1, float2 d2, float k)
	{
		return smin(d1, d2, k);
	}

	float opBlendSmax(float d1, float d2, float k)
	{
		return smax(d1, d2, k);
	}

	float3 opRotateTranslate(float4 p, float4x4 m)
	{
		//float3 q = invert(m)*p;
		float3 q = mul(m,p).xyz;
		return q;
	}

	//subtraction
	float opS(float d1, float d2)
	{
		return max(-d1, d2);
	}


	ENDCG



	Pass // 0 - paint to maintexinternal
	{
		/*ase_hide_pass*/
		Name "PaintToMaintexinternal"


		Cull Front
		ZWrite Off
		//ZTest Always
		ColorMask 0

		CGPROGRAM
		#pragma target 5.0
		#pragma only_renderers d3d11
		#pragma vertex vert
		#pragma fragment frag
		//#define BRUSH_COUNT 2
		/*ase_pragma*/
		/*ase_globals*/


	v2f vert(appdata v /*ase_vert_input*/)
	{
		v2f o;

		#if CUSTOM_VERTEX_DISPLACEMENT
		float2 uv = v.uv*_MainTex__ST.xy + _MainTex__ST.zw;
		//float4 textureVals = tex2Dlod(_MainTex_Internal_Sampler, float4(uv, 0.0, 0.0));
		int coordx = int((uv.x)*2048);
		int coordy = int((uv.y)*2048);
		int2 mainUVRWT = int2(coordx,coordy);
		float4 textureVals = _MainTex_Internal[mainUVRWT];
		float height = (textureVals.x + textureVals.y + textureVals.z) / 3;
		float3 normal = v.normal;
		if(textureVals.a < 1.0)
			normal = -normal;
		v.vertex.xyz += normal * height;
		o.normal =  mul(unity_ObjectToWorld, v.normal).xyz;
		#endif

		/*ase_vert_code:v=appdata;o=v2f*/
		v.vertex.xyz += /*ase_vert_out:Local Vertex;Float3;_Vertex*/ float3(0,0,0) /*end*/;


		o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		// Tranforms position from object to homogenous space https://forum.unity3d.com/threads/unityobjecttoclippos.400520/
		o.vertex = UnityObjectToClipPos(v.vertex);
		//o.uv = TRANSFORM_TEX(v.uv, _MainTex_Internal);
		o.uv = TRANSFORM_TEX(v.uv, _MainTex_);
		

		return o;
	}

	//void frag(v2f i, out float4 color : SV_Target0, out float4 colorInternal : SV_Target1)
	float4 frag(v2f i /*ase_frag_input*/) : SV_Target
	{
		#if CUSTOM_VERTEX_DISPLACEMENT
		float3 normalws = i.normal;		
		#endif
		//float4 prevColor = tex2D(_MainTex_Internal, i.uv*_MainTex_Internal_ST.xy + _MainTex_Internal_ST.zw);
		float2 mainUV = i.uv;//*_MainTex_Internal_ST.xy + _MainTex_Internal_ST.zw;
		int coordx = int((mainUV.x)*2048);
		int coordy = int((mainUV.y)*2048);
		int2 mainUVRWT = int2(coordx,coordy);
		
		float4 prevColor = _MainTex_Internal[mainUVRWT];
		float3 temprgb = prevColor.rgb;
		float2 uv2 = i.uv*_BgTex_ST.xy + _BgTex_ST.zw;
		//float4 outColor = float4(0, 0, 0, 1);
		float4 outColor = tex2D(_BgTex, uv2);
		//outColor.a = 1;

		float3 pxPosWorld = (i.worldPos.xyz);

		//float4 output = tex2D(_MainTex_, i.uv*_MainTex__ST.xy + _MainTex__ST.zw);
		//output.b = 1;
		//output.r = 1;

		float2 outdf = float2(1,1);

		for (int i = 0; i < BRUSH_COUNT; i++)
		{
			
			float3 pos = pxPosWorld;

			float2 dims = _ConeShapeXY.xy;

			//pos = opRotateTranslate(float4(pos.x, pos.y, pos.z, 1), _Matrix_iTR[i]).xyz;
			//pos = pos - _PositionWS[i];
			pos = pos - _PositionWS[i];
			float3 toolToPixelDirWS = normalize(pos);

			pos = opRotateTranslate(float4(pos.x, pos.y, pos.z, 1), _Matrix_iTR[i]).xyz;// - _PositionWS[i].xyz;

			pos.z += _ConeShapeXY.z;
			float fadeDist = pos.z * _ConeShapeXY.w - pos.z;

			float coneDFv = sdCone(pos / _ConeScale, dims / _ConeScale, _ConeClamp)*_ConeScale*_ConeScale2;
			coneDFv = pow(coneDFv, _ConeScalePow);


			float3 spherePos = pos;
			spherePos.z += _FadeShapeXY.w;
			spherePos *= _FadeScale;
			float sphereDFv = sdSphere(spherePos / _FadeShapeXY.x, _FadeShapeXY.z / _ConeScale)*_FadeShapeXY.x*_FadeShapeXY.y;
			sphereDFv = pow(sphereDFv, _FadeScalePow);

			//float blend = opBlendSmin(coneDFv, sphereDFv, _FadeScale.w);
			float blend = opBlendSmax(coneDFv, sphereDFv, _BlendSubtraction);




			//outdf = opBlendSmin(float2(outdf.x,1), float2(blend,2), _BlendAddition);// opI(coneDFv, sphereDFv);
			//outdf.x = 1 - max(outdf.x, 0.1);
			//outdf.x = saturate(blend.x);

			blend.x = 1 - max(blend.x, 0.1);
			blend.x = saturate(blend.x);


			//float a = blend.x;
			//temprgb.xyz = _BrushBuffer[i].color.xyz * a + temprgb.rgb * (1 - a);

			if (_PaintingParams[i].y > 0)
			{
				// erase (paint black)
				blend.x /= _EraseBlend;
				float a = saturate(blend.x);
				temprgb.xyz = _EraserColor.rgb * a + temprgb.rgb * (1.0 - a);

			}
			else
			if (_PaintingParams[i].x > 0)
			{
				//_BrushBuffer[i].color = _Color_;
				//float a = outdf.x;
				blend.x /= _SprayBlend;
				float a = saturate(blend.x);
				temprgb.xyz = _BrushBuffer[i].color.xyz * a + temprgb.rgb * (1.0 - a);
				//temprgb.xyz = _Color_ * a + temprgb.rgb * (1.0 - a);
				
			}

			#if CUSTOM_VERTEX_DISPLACEMENT
			float dott = dot(toolToPixelDirWS, normalws);
			if(dott < 0){
				outColor.a = 0.0;// 0.0 means this was painted on a backface
			}
			else{
				outColor.a = 1.0;// 1.0 means this was painted on a frontface
			}
			#endif
		}


		prevColor.rgb = temprgb;
		outColor.rgb = lerp(prevColor.rgb, max(outColor.rgb, prevColor.rgb), _Init);
		///outColor.rgb = prevColor.rgb;
		///outColor = float4(0,0,1,1);

		//outColor.x = 0;
		//outColor.y = outdf.x;		
		//outColor.z = 0;
		//outColor = _PositionWS[0]+_PositionWS[1];
		
		
		_MainTex_Internal[mainUVRWT] = outColor;
		
		///_MainTex_Screen
		///clip(-1);
		///outColor = float4(0,0,1,1);


		/*ase_frag_code:i=v2f*/
		outColor.rgb = /*ase_frag_out:Color;Float3;_Color_*/float3(1,1,1)/*end*/;
		outColor.a = /*ase_frag_out:Alpha;Float;_Alpha*/1/*end*/;
		
		return outColor;
		///return _MainTex_Internal[mainUVRWT];

	}
		ENDCG
	}

	Pass // 0 - paint to maintexinternal
	{

		/*ase_hide_pass*/

		Cull Back
		ZWrite Off
		//ZTest Always
		ColorMask 0

		CGPROGRAM
#pragma target 5.0
#pragma only_renderers d3d11
#pragma vertex vert
#pragma fragment frag
		//#define BRUSH_COUNT 2
		/*ase_pragma*/
		/*ase_globals*/


	v2f vert(appdata v /*ase_vert_input*/)
	{
		v2f o;

		#if CUSTOM_VERTEX_DISPLACEMENT
		float2 uv = v.uv*_MainTex__ST.xy + _MainTex__ST.zw;
		//float4 textureVals = tex2Dlod(_MainTex_Internal_Sampler, float4(uv, 0.0, 0.0));
		int coordx = int((uv.x)*2048);
		int coordy = int((uv.y)*2048);
		int2 mainUVRWT = int2(coordx,coordy);
		float4 textureVals = _MainTex_Internal[mainUVRWT];
		float height = (textureVals.x + textureVals.y + textureVals.z) / 3;
		float3 normal = v.normal;
		if(textureVals.a < 1.0)
			normal = -normal;
		v.vertex.xyz += normal * height;
		o.normal =  mul(unity_ObjectToWorld, v.normal).xyz;
		#endif

		/*ase_vert_code:v=appdata;o=v2f*/
		v.vertex.xyz += /*ase_vert_out:Local Vertex;Float3;_Vertex*/ float3(0,0,0) /*end*/;

		o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		// Tranforms position from object to homogenous space https://forum.unity3d.com/threads/unityobjecttoclippos.400520/
		o.vertex = UnityObjectToClipPos(v.vertex);
		//o.uv = TRANSFORM_TEX(v.uv, _MainTex_Internal);
		o.uv = TRANSFORM_TEX(v.uv, _MainTex_);

		return o;
	}

	//void frag(v2f i, out float4 color : SV_Target0, out float4 colorInternal : SV_Target1)
	float4 frag(v2f i /*ase_frag_input*/) : SV_Target
	{
		#if CUSTOM_VERTEX_DISPLACEMENT
		float3 normalws = i.normal;
		#endif
		//float4 prevColor = tex2D(_MainTex_Internal, i.uv*_MainTex_Internal_ST.xy + _MainTex_Internal_ST.zw);
		float2 mainUV = i.uv;//*_MainTex_Internal_ST.xy + _MainTex_Internal_ST.zw;
		int coordx = int((mainUV.x)*2048);
		int coordy = int((mainUV.y)*2048);
		int2 mainUVRWT = int2(coordx,coordy);
		
		float4 prevColor = _MainTex_Internal[mainUVRWT];
		float3 temprgb = prevColor.rgb;
		float2 uv2 = i.uv*_BgTex_ST.xy + _BgTex_ST.zw;
		//float4 outColor = float4(0, 0, 0, 1);
		float4 outColor = tex2D(_BgTex, uv2);
		//outColor.a = 1;

		float3 pxPosWorld = (i.worldPos.xyz);

		//float4 output = tex2D(_MainTex_, i.uv*_MainTex__ST.xy + _MainTex__ST.zw);
		//output.b = 1;
		//output.r = 1;

		float2 outdf = float2(1,1);

		for (int i = 0; i < BRUSH_COUNT; i++)
		{
			
			float3 pos = pxPosWorld;

			float2 dims = _ConeShapeXY.xy;

			//pos = opRotateTranslate(float4(pos.x, pos.y, pos.z, 1), _Matrix_iTR[i]).xyz;
			//pos = pos - _PositionWS[i];
			pos = pos - _PositionWS[i];
			float3 toolToPixelDirWS = normalize(pos);

			pos = opRotateTranslate(float4(pos.x, pos.y, pos.z, 1), _Matrix_iTR[i]).xyz;// - _PositionWS[i].xyz;

			pos.z += _ConeShapeXY.z;
			float fadeDist = pos.z * _ConeShapeXY.w - pos.z;

			float coneDFv = sdCone(pos / _ConeScale, dims / _ConeScale, _ConeClamp)*_ConeScale*_ConeScale2;
			coneDFv = pow(coneDFv, _ConeScalePow);


			float3 spherePos = pos;
			spherePos.z += _FadeShapeXY.w;
			spherePos *= _FadeScale;
			float sphereDFv = sdSphere(spherePos / _FadeShapeXY.x, _FadeShapeXY.z / _ConeScale)*_FadeShapeXY.x*_FadeShapeXY.y;
			sphereDFv = pow(sphereDFv, _FadeScalePow);

			//float blend = opBlendSmin(coneDFv, sphereDFv, _FadeScale.w);
			float blend = opBlendSmax(coneDFv, sphereDFv, _BlendSubtraction);

			//outdf = opBlendSmin(float2(outdf.x,1), float2(blend,2), _BlendAddition);// opI(coneDFv, sphereDFv);
			//outdf.x = 1 - max(outdf.x, 0.1);
			//outdf.x = saturate(blend.x);

			blend.x = 1 - max(blend.x, 0.1);
			blend.x = saturate(blend.x);


			//float a = blend.x;
			//temprgb.xyz = _BrushBuffer[i].color.xyz * a + temprgb.rgb * (1 - a);

			if (_PaintingParams[i].y > 0)
			{
				// erase (paint black)
				blend.x /= _EraseBlend;
				float a = saturate(blend.x);
				temprgb.xyz = _EraserColor.rgb * a + temprgb.rgb * (1.0 - a);

			}
			else
			if (_PaintingParams[i].x > 0)
			{
				//_BrushBuffer[i].color = _Color_;
				//float a = outdf.x;
				blend.x /= _SprayBlend;
				float a = saturate(blend.x);
				temprgb.xyz = _BrushBuffer[i].color.xyz * a + temprgb.rgb * (1.0 - a);
				//temprgb.xyz = _Color_ * a + temprgb.rgb * (1.0 - a);
				
				
			}

			#if CUSTOM_VERTEX_DISPLACEMENT
			float dott = dot(toolToPixelDirWS, normalws);
			if(dott < 0){
				outColor.a = 0.0;// 0.0 means this was painted on a backface
			}
			else{
				outColor.a = 1.0;// 1.0 means this was painted on a frontface
			}
			#endif
		}


		prevColor.rgb = temprgb;
		outColor.rgb = lerp(prevColor.rgb, max(outColor.rgb, prevColor.rgb), _Init);
		///outColor.rgb = prevColor.rgb;
		///outColor = float4(0,0,1,1);

		//outColor.x = 0;
		//outColor.y = outdf.x;		
		//outColor.z = 0;
		//outColor = _PositionWS[0]+_PositionWS[1];
		
		_MainTex_Internal[mainUVRWT] = outColor;
		
		///_MainTex_Screen
		///clip(-1);
		///outColor = float4(0,0,1,1);


		/*ase_frag_code:i=v2f*/
				
		outColor.rgb = /*ase_frag_out:Color;Float3;_Color_*/float3(1,1,1)/*end*/;
		outColor.a = /*ase_frag_out:Alpha;Float;_Alpha*/1/*end*/;

		return outColor;
		///return _MainTex_Internal[mainUVRWT];

	}
		ENDCG
	}


	Pass // 1 - apply paint, on back faces in case volumetric brush propagates / intersects all the way through the mesh
	{


		Cull Front
		//ZWrite Off
		//ZTest Always


		CGPROGRAM
		#pragma target 5.0
		#pragma vertex vert
		#pragma fragment frag
		/*ase_pragma*/
		/*ase_globals*/

		//#define BRUSH_COUNT 2


	sampler2D _Color_Picker;
	float4 _Color_Picker_ST;
	float _Color_SampleDist;
	float4 _Color_SampleDist_ST;

	sampler2D _Color_PickerDisplay;
	//float4 _Color_PickerDisplay_ST;

	sampler2D _ToolOutlineTex;
	float4 _ToolOutlineTex_ST;

	float4 _Color_SamplerVolume;


	v2f vert(appdata v /*ase_vert_input*/)
	{
		v2f o;

		#if CUSTOM_VERTEX_DISPLACEMENT
		float2 uv = v.uv*_MainTex__ST.xy + _MainTex__ST.zw;
		//float4 textureVals = tex2Dlod(_MainTex_Internal_Sampler, float4(uv, 0.0, 0.0));
		int coordx = int((uv.x)*2048);
		int coordy = int((uv.y)*2048);
		int2 mainUVRWT = int2(coordx,coordy);
		float4 textureVals = _MainTex_Internal[mainUVRWT];
		float height = (textureVals.x + textureVals.y + textureVals.z) / 3;
		float3 normal = v.normal;
		if(textureVals.a < 1.0)
			normal = -normal;
		v.vertex.xyz += normal * height;
		o.normal =  mul(unity_ObjectToWorld, v.normal).xyz;
		#endif

		o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		// Tranforms position from object to homogenous space https://forum.unity3d.com/threads/unityobjecttoclippos.400520/
		
		o.uv = TRANSFORM_TEX(v.uv, _MainTex_);
		

		/*ase_vert_code:v=appdata;o=v2f*/
		v.vertex.xyz += /*ase_vert_out:Local Vertex;Float3;_Vertex*/ float3(0,0,0) /*end*/;

		o.vertex = UnityObjectToClipPos(v.vertex);
		//o.uv = TRANSFORM_TEX(v.uv, _MainTex_Internal);
		

		return o;
	}

	fixed4 frag(v2f i /*ase_frag_input*/) : SV_Target
	{

		float3 pxPosWorld = (i.worldPos.xyz);
		float2 uv = i.uv;
		float2 mainUV = uv*_MainTex__ST.xy + _MainTex__ST.zw;
		int coordx = int((mainUV.x)*2048);
		int coordy = int((mainUV.y)*2048);
		int2 mainUVRWT = int2(coordx,coordy);
		float4 mainTex = tex2D(_MainTex_, mainUV);
		float4 output = _MainTex_Internal[mainUVRWT];
		//output = lerp(mainTex,_MainTex_Internal[mainUVRWT],clamp(((output.x+output.y+output.z)/3)*4,0,1));
		output = lerp(mainTex,_MainTex_Internal[mainUVRWT], max(output.x,max(output.y,output.z)));
		//float4 output = _MainTex_Internal[mainUVRWT];

		float3 temprgb = float3(0, 0, 0);// output.rgb;
		//float3 temprgb = _MainTex_Internal[mainUVRWT];
		float2 outdf = float2(1,0);


		float4 sampledColor = tex2D(_Color_Picker, uv*_Color_Picker_ST.xy + _Color_Picker_ST.zw);
		
		
		for (int i = 0; i < BRUSH_COUNT; i++)
		{

			float3 pos = pxPosWorld;

			float2 dims = _ConeShapeXY.xy;

			//pos = opRotateTranslate(float4(pos.x, pos.y, pos.z, 1), _Matrix_iTR[i]).xyz;// - _PositionWS[i].xyz;
			//pos = pxPosWorld - _PositionWS[i].xyz;//opRotateTranslate(float4( _PositionWS[i].x,  _PositionWS[i].y,  _PositionWS[i].z, 0), _Matrix_iTR[i]).xyz;
			//pos = pxPosWorld - opRotateTranslate(float4( _PositionWS[i].x,  _PositionWS[i].y,  _PositionWS[i].z, 1), _Matrix_iTR[i]).xyz;
			pos = pos - _PositionWS[i];
			pos = opRotateTranslate(float4(pos.x, pos.y, pos.z, 1), _Matrix_iTR[i]).xyz;// - _PositionWS[i].xyz;
			//pos = opRotateTranslate(float4(1,1,1, 1), _Matrix_iTR[i]).xyz;


			pos.z += _ConeShapeXY.z;
			float fadeDist = pos.z * _ConeShapeXY.w - pos.z;

			float coneDFv = sdCone(  pos / _ConeScale, dims / _ConeScale, _ConeClamp)*_ConeScale*_ConeScale2;
			coneDFv = pow(coneDFv, _ConeScalePow);


			float3 spherePos = pos;
			spherePos.z += _FadeShapeXY.w;
			spherePos *= _FadeScale;
			float sphereDFv = sdSphere( spherePos / _FadeShapeXY.x, _FadeShapeXY.z / _ConeScale)*_FadeShapeXY.x*_FadeShapeXY.y;
			//sphereDFv = pow(sphereDFv, _FadeScalePow);

			float3 cylinderPos = float3(pos.x, pos.z, pos.y);
			float cylinderDFv = sdCylinder( cylinderPos, _Color_SamplerVolume.xyz)*_Color_SamplerVolume.w;



			//float blend = opBlendSmin(coneDFv, sphereDFv, _FadeScale.w);
			float2 blend = float2(opBlendSmax(coneDFv, sphereDFv, _BlendSubtraction), i);



			blend = opS(blend - _TargetRingLocation, blend);
			blend = (blend*blend* _TargetRingThickness);


			outdf = opBlendSmin(outdf, blend, _BlendAddition);// opI(coneDFv, sphereDFv);

			blend.x = 1 - max(blend.x, 0.1);
			blend.x = saturate(blend.x);

			if (
				sampledColor.a > 0.0
				)
			{
				float blendS = max(blend.x, (-cylinderDFv)*sampledColor.a);
				blend.x = blendS;

				float dist = distance(float2(_PositionSS[i].x*_Color_SampleDist_ST.z, _PositionSS[i].y*_Color_SampleDist_ST.w), _Color_SampleDist_ST.xy);

				if ((cylinderDFv) < _Color_SampleThresh
					&& (_PaintingParams[i].y > 0 || _PaintingParams[i].x > 0)
					&& dist < _Color_SampleDist
					)
				{
				
					_BrushBuffer[i].color.xyz = sampledColor.rgb;
					
				}
			}
	

			float a = pow(blend.x, 0.8);
			float lv = a;// *0.5 + 0.5;
						 //lv = pow(lv,0.85);
						 //float3 ringCol = lerp(float3(1, 1, 1) - _BrushBuffer[i].color.xyz, _BrushBuffer[i].color.xyz, lv);
						 //float3 ringCol = lerp(float3(1,1,1), _BrushBuffer[i].color.xyz, lv);

			float4 ringCol = tex2D(_ToolOutlineTex, lv.xx*_ToolOutlineTex_ST.xy + _ToolOutlineTex_ST.zw);
			ringCol.xyz = ringCol.xyz * ringCol.a + _BrushBuffer[i].color * (1 - ringCol.a);

			/*
			if (distance(float2(_PositionSS[0].x*_Color_SampleDist_ST.z, _PositionSS[0].y*_Color_SampleDist_ST.w), _Color_SampleDist_ST.xy) < _Color_SampleDist)
			{
				ringCol.xyz = float3(1, 0, 0);
				//visible feedback for when you can sample?
			}
			*/
			temprgb.xyz = ringCol * a + temprgb.rgb * (1 - a);
			//float debug = distance(pxPosWorld,_PositionWS[i]);
			//temprgb.xyz += debug*debug*debug*0.1;
			
			
		}



		float4 dispTex = tex2D(_Color_PickerDisplay, uv*_Color_Picker_ST.xy + _Color_Picker_ST.zw);
		//dispTex = float4(0,0,0,1);
		//temprgb.xyz = dispTex.rgb * dispTex.a + temprgb.xyz * (1 - dispTex.a);
		temprgb.xyz = (output.rgb*(1 - dispTex.a) + dispTex.rgb*dispTex.a) + temprgb;



		output.rgb = temprgb.xyz;
		//output.rgb = pxPosWorld.xyz;
		//output.rgb = _MainTex_Internal[mainUV];


		//_MainTex_Internal[mainUV] = outColor;
		
		

		//output.r = 0;
		//output.g = distance(pxPosWorld, _PositionWS[0]);
		//output.b = distance(pxPosWorld, _PositionWS[1]);
		//output.r = outdf;
		_MainTex_Screen[mainUVRWT] = output;//_PositionWS[0]+_PositionWS[1];//output.rgba;
		//_MainTex_Screen[int2(coordx,coordy)] += float4(0.1,0.1,0.1,1);//_PositionWS[0]+_PositionWS[1];//output.rgba;
		//output = _MainTex_Screen[int2(coordx,coordy)];
		/*
		_MainTex_Screen[int2(0,0)] = output.rgba;
		_MainTex_Screen[int2(1,1)] = output.rgba;
		_MainTex_Screen[int2(2,2)] = output.rgba;
		_MainTex_Screen[int2(3,3)] = output.rgba;
		_MainTex_Screen[int2(4,4)] = output.rgba;
		_MainTex_Screen[int2(5,5)] = output.rgba;
		_MainTex_Screen[int2(1,2)] = output.rgba;
		_MainTex_Screen[int2(1,3)] = output.rgba;
*/
		//clip(-1);
		//output = float4(mainUV.x, mainUV.y, 0,1);
		//uint2 temp = float2(0,0);
		//_MainTex_Screen.GetDimensions(temp.x, temp.y);
		//output = float4(temp.x, temp.y, 0, 1);
		//output = _MainTex_Screen[int2(coordx,coordy)];

		//_BrushBuffer[i].color.xyz =  _Color_;
		
		/*ase_frag_code:i=v2f*/
		output.rgb = /*ase_frag_out:Color;Float3;_Color_*/float3(1,1,1)/*end*/;
		output.a = /*ase_frag_out:Alpha;Float;_Alpha*/1/*end*/;

		return output;

	}
		ENDCG
	}
	
	Pass // 2 - apply paint, on front faces
	{


		/*ase_main_pass*/

		Cull Back
		//ZWrite Off
		//ZTest Always


		CGPROGRAM
		#pragma target 5.0
		#pragma vertex vert
		#pragma fragment frag
		/*ase_pragma*/
		/*ase_globals*/

		//#define BRUSH_COUNT 2


	sampler2D _Color_Picker;
	float4 _Color_Picker_ST;
	float _Color_SampleDist;
	float4 _Color_SampleDist_ST;

	sampler2D _Color_PickerDisplay;
	//float4 _Color_PickerDisplay_ST;

	sampler2D _ToolOutlineTex;
	float4 _ToolOutlineTex_ST;

	float4 _Color_SamplerVolume;


	v2f vert(appdata v /*ase_vert_input*/)
	{
		v2f o;

		#if CUSTOM_VERTEX_DISPLACEMENT
		float2 uv = v.uv*_MainTex__ST.xy + _MainTex__ST.zw;
		//float4 textureVals = tex2Dlod(_MainTex_Internal_Sampler, float4(uv, 0.0, 0.0));
		int coordx = int((uv.x)*2048);
		int coordy = int((uv.y)*2048);
		int2 mainUVRWT = int2(coordx,coordy);
		float4 textureVals = _MainTex_Internal[mainUVRWT];
		float height = (textureVals.x + textureVals.y + textureVals.z) / 3;
		float3 normal = v.normal;
		if(textureVals.a < 1.0)
			normal = -normal;
		v.vertex.xyz += normal * height;
		o.normal =  mul(unity_ObjectToWorld, v.normal).xyz;
		#endif

		o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
		// Tranforms position from object to homogenous space https://forum.unity3d.com/threads/unityobjecttoclippos.400520/
		
		o.uv = TRANSFORM_TEX(v.uv, _MainTex_);

		/*ase_vert_code:v=appdata;o=v2f*/	
		v.vertex.xyz += /*ase_vert_out:Local Vertex;Float3;_Vertex*/ float3(0,0,0) /*end*/;

		o.vertex = UnityObjectToClipPos(v.vertex);
		//o.uv = TRANSFORM_TEX(v.uv, _MainTex_Internal);
		

		return o;
	}

	fixed4 frag(v2f i /*ase_frag_input*/ ) : SV_Target
	{

		float3 pxPosWorld = (i.worldPos.xyz);
		float2 uv = i.uv;
		float2 mainUV = uv*_MainTex__ST.xy + _MainTex__ST.zw;
		int coordx = int((mainUV.x)*2048);
		int coordy = int((mainUV.y)*2048);
		int2 mainUVRWT = int2(coordx,coordy);
		float4 mainTex = tex2D(_MainTex_, mainUV);
		float4 output = _MainTex_Internal[mainUVRWT];
		//output = lerp(mainTex,_MainTex_Internal[mainUVRWT],clamp(((output.x+output.y+output.z)/3)*4,0,1));
		output = lerp(mainTex,_MainTex_Internal[mainUVRWT], max(output.x,max(output.y,output.z)));
		//float4 output = _MainTex_Internal[mainUVRWT];

		float3 temprgb = float3(0, 0, 0);// output.rgb;
		//float3 temprgb = _MainTex_Internal[mainUVRWT];
		float2 outdf = float2(1,0);


		float4 sampledColor = tex2D(_Color_Picker, uv*_Color_Picker_ST.xy + _Color_Picker_ST.zw);
		
		
		for (int i = 0; i < BRUSH_COUNT; i++)
		{
			

			float3 pos = pxPosWorld;

			float2 dims = _ConeShapeXY.xy;

			//pos = opRotateTranslate(float4(pos.x, pos.y, pos.z, 1), _Matrix_iTR[i]).xyz;// - _PositionWS[i].xyz;
			//pos = pxPosWorld - _PositionWS[i].xyz;//opRotateTranslate(float4( _PositionWS[i].x,  _PositionWS[i].y,  _PositionWS[i].z, 0), _Matrix_iTR[i]).xyz;
			//pos = pxPosWorld - opRotateTranslate(float4( _PositionWS[i].x,  _PositionWS[i].y,  _PositionWS[i].z, 1), _Matrix_iTR[i]).xyz;
			pos = pos - _PositionWS[i];
			pos = opRotateTranslate(float4(pos.x, pos.y, pos.z, 1), _Matrix_iTR[i]).xyz;// - _PositionWS[i].xyz;
			//pos = opRotateTranslate(float4(1,1,1, 1), _Matrix_iTR[i]).xyz;


			pos.z += _ConeShapeXY.z;
			float fadeDist = pos.z * _ConeShapeXY.w - pos.z;

			float coneDFv = sdCone(  pos / _ConeScale, dims / _ConeScale, _ConeClamp)*_ConeScale*_ConeScale2;
			coneDFv = pow(coneDFv, _ConeScalePow);


			float3 spherePos = pos;
			spherePos.z += _FadeShapeXY.w;
			spherePos *= _FadeScale;
			float sphereDFv = sdSphere( spherePos / _FadeShapeXY.x, _FadeShapeXY.z / _ConeScale)*_FadeShapeXY.x*_FadeShapeXY.y;
			//sphereDFv = pow(sphereDFv, _FadeScalePow);

			float3 cylinderPos = float3(pos.x, pos.z, pos.y);
			float cylinderDFv = sdCylinder( cylinderPos, _Color_SamplerVolume.xyz)*_Color_SamplerVolume.w;



			//float blend = opBlendSmin(coneDFv, sphereDFv, _FadeScale.w);
			float2 blend = float2(opBlendSmax(coneDFv, sphereDFv, _BlendSubtraction), i);



			blend = opS(blend - _TargetRingLocation, blend);
			blend = (blend*blend* _TargetRingThickness);


			outdf = opBlendSmin(outdf, blend, _BlendAddition);// opI(coneDFv, sphereDFv);

			blend.x = 1 - max(blend.x, 0.1);
			blend.x = saturate(blend.x);

			if (
				sampledColor.a > 0.0
				)
			{
				float blendS = max(blend.x, (-cylinderDFv)*sampledColor.a);
				blend.x = blendS;

				float dist = distance(float2(_PositionSS[i].x*_Color_SampleDist_ST.z, _PositionSS[i].y*_Color_SampleDist_ST.w), _Color_SampleDist_ST.xy);

				if ((cylinderDFv) < _Color_SampleThresh
					&& (_PaintingParams[i].y > 0 || _PaintingParams[i].x > 0)
					&& dist < _Color_SampleDist
					)
				{
				
					_BrushBuffer[i].color.xyz = sampledColor.rgb;
					
				}
			}
	

			float a = pow(blend.x, 0.8);
			float lv = a;// *0.5 + 0.5;
						 //lv = pow(lv,0.85);
						 //float3 ringCol = lerp(float3(1, 1, 1) - _BrushBuffer[i].color.xyz, _BrushBuffer[i].color.xyz, lv);
						 //float3 ringCol = lerp(float3(1,1,1), _BrushBuffer[i].color.xyz, lv);

			float4 ringCol = tex2D(_ToolOutlineTex, lv.xx*_ToolOutlineTex_ST.xy + _ToolOutlineTex_ST.zw);
			ringCol.xyz = ringCol.xyz * ringCol.a + _BrushBuffer[i].color * (1 - ringCol.a);


			// if (distance(float2(_PositionSS[0].x*_Color_SampleDist_ST.z, _PositionSS[0].y*_Color_SampleDist_ST.w), _Color_SampleDist_ST.xy) < _Color_SampleDist)
			// {
			// 	ringCol.xyz = float3(1, 0, 0);
			// 	//visible feedback for when you can sample?
			// }
			
			temprgb.xyz = ringCol * a + temprgb.rgb * (1 - a);
			//float debug = distance(pxPosWorld,_PositionWS[i]);
			//temprgb.xyz += pow(debug,1000)*0.1;
			
			
		}



		float4 dispTex = tex2D(_Color_PickerDisplay, uv*_Color_Picker_ST.xy + _Color_Picker_ST.zw);
		//dispTex = float4(0,0,0,1);
		//temprgb.xyz = dispTex.rgb * dispTex.a + temprgb.xyz * (1 - dispTex.a);
		temprgb.xyz = (output.rgb*(1 - dispTex.a) + dispTex.rgb*dispTex.a) + temprgb;



		output.rgb = temprgb.xyz;
		//output.rgb = pxPosWorld.xyz;
		//output.rgb = _MainTex_Internal[mainUV];


		//_MainTex_Internal[mainUV] = outColor;
		
		

		//output.r = 0;
		//output.g = distance(pxPosWorld, _PositionWS[0]);
		//output.b = distance(pxPosWorld, _PositionWS[1]);
		//output.r = outdf;
		_MainTex_Screen[mainUVRWT] = output;//_PositionWS[0]+_PositionWS[1];//output.rgba;
		//_MainTex_Screen[int2(coordx,coordy)] += float4(0.1,0.1,0.1,1);//_PositionWS[0]+_PositionWS[1];//output.rgba;
		//output = _MainTex_Screen[int2(coordx,coordy)];
		
		// _MainTex_Screen[int2(0,0)] = output.rgba;
		// _MainTex_Screen[int2(1,1)] = output.rgba;
		// _MainTex_Screen[int2(2,2)] = output.rgba;
		// _MainTex_Screen[int2(3,3)] = output.rgba;
		// _MainTex_Screen[int2(4,4)] = output.rgba;
		// _MainTex_Screen[int2(5,5)] = output.rgba;
		// _MainTex_Screen[int2(1,2)] = output.rgba;
		// _MainTex_Screen[int2(1,3)] = output.rgba;

		//clip(-1);
		//output = float4(mainUV.x, mainUV.y, 0,1);
		//uint2 temp = float2(0,0);
		//_MainTex_Screen.GetDimensions(temp.x, temp.y);
		//output = float4(temp.x, temp.y, 0, 1);
		//output = _MainTex_Screen[int2(coordx,coordy)];

		//_BrushBuffer[i].color.xyz =  _Color_;
		
		/*ase_frag_code:i=v2f*/	
		output.rgb = /*ase_frag_out:Color;Float3;_Color_*/float3(1,1,1)/*end*/;
		output.a = /*ase_frag_out:Alpha;Float;_Alpha*/1/*end*/;

		return output;

	}
		ENDCG
	}
	/*a=se_pa=ss_e=nd*/
	}


}
