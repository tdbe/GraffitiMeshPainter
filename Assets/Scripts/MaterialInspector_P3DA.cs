using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class MaterialInspector_P3DA : MonoBehaviour {
	[TextArea(3,3)]
	public string Header = "This is a tessellated paintable shader with lots of customizability. It requires the RenderManager on the camera, the controlManager manager script somewhere in the scene, and this MaterialInspector.cs which is one per mesh/material, and each paintable material must be a unique copy else they overlap (if you want 2 objects with the same material and only one of them is paintable, then remove the MaterialInspector from one of them). And you need to use the _3DPaintAccumulator_UberMetallicTess_Multipass.shader uber shader on the material of this mesh. And leave uber's Albedo texture empty and rgb color black and set the material to Transparent, and maybe set Displacement depth to 0.0005. Assign the main texture to MainTex_P3DA on this script instead. Note that this shader can be modified into one that doesn't need uber (if you don't want tesselaltion and lighting), and jsut renders tha painting, maybe also not drawing anything to screen (ColorMask 0), and then you can just take its result RenderTexture and assign it to an Amplify Shader or Standard Shader or whatever. This shader/system also is atlassable: all MaterialInspector_P3DA objects in the scene will be divided and atlassed onto the RenderTexture you paint on.";

	[Space(15)]

	[TextArea(3,3)]
	public string Note_0 = "The mat below is a reference we can use from the RenderManager to initialize (blit) the Render Textures used by this mat with a specific RGBA color so that they for example don't start off as transparent.";
	public Material RTColorInitializerMat;
	Texture OptionalStampTexture;
	
	[Space(15)]
	[TextArea(3,3)]
	public string Note_1 = "This script assigns the following attributes to the main material of this object.\nIf you have trouble with artifacts or can't fully erase etc, then use uncompressed textures.";
	[TextArea(4,4)]
	public string Note_2 = "The following bools are multicompile switches.\nUse them to enable the support in the shader.\nThe actual activation of whether you paint etc, happens from the brush settings script.";
	public bool use_DISPLAY_BRUSH_VOLUME_ = true;	
	public bool use_3D_PAINT_ACCUMULATOR_ = true;
	bool wasSet_UNITY_REQUIRE_FRAG_WORLDPOS = false;
	public bool use_CUSTOM_VERTEX_DISPLACEMENT = false;
	public bool use_GPU_COLOR_PICKER_ = true;
	public bool use_BLEND_2_TEXTURES_WITH_PAINT_ = false;
	public bool use_ERASE_MESH_WITH_PAINT_ = false;
	
	public enum UV
	{
		UV0 = 0,
		UV1 = 1,
		UV2 = 2
	}
	
	[Space(30)]
	[TextArea(2,3)]
	public string Note2 = "m_whichUVsToUse doesn't work. Leave it at UV0. TODO: need to understand how to use both light baking and also uv2 in Standard or Uber. See this line in UBER_StandardCore_3DPaintAccumulator.cginc: #if defined(LIGHTMAP_ON) //|| defined(_3D_PAINT_ACCUMULATOR_)// <- if you enable this then you get GI artifact colors.";
	public UV m_whichUVsToUse = UV.UV0; 
	public Vector4 _Atlas_ST_PerMaterial_P3DA = new Vector4(1,1,0,0);

	[Space(30)]

	public Texture _OverlayTex_Before_P3DA;
	public Texture _OverlayTex_After_P3DA;
	public Vector4 _OverlayTex_Before_P3DA_ST = new Vector4(1,1,0,0);

	[Space(15)]

	public float _HeightMapStrength_P3DA;


	[Space(30)]
	public Color _Color_P3DA;
	public Color _EraserColor_P3DA;
	public Texture2D _ColorPicker_P3DA;
	
	public Texture2D _ColorPickerDisplay_P3DA;

	[Space(30)]
	public string noteMainTex = "This texture is used in the display pass, not recorded to the render texture. Set it to black by default.";
	public Texture2D _MainTex_P3DA;
	public Vector4 _MainTex_P3DA_ST = new Vector4(1,1,0,0);
	//public Texture2D _MainTexScreen_P3DA("_MainTexScreen_P3DA (should be a RT)", 2D) = "white" {}
	//public Texture2D _MainTexInternal_P3DA("_MainTexInternal_P3DA (should be a RT)", 2D) = "white" {}
	//_MainTexInternal_P3DA_Sampler("_MainTexInternal_P3DA_Sampler (should be from RT)", 2D) = "white" {}
	public string noteBgTex = "This texture is used in the painting pass, so it IS recorded to the render texture. Set it to black by default.";	
	public Texture2D _BgTex_P3DA;
	[Space(30)]
	public Texture2D _ToolOutlineTex_P3DA;
	public float _BrushScaleOffset_P3DA;

	public float _BrushScaleMod_P3DA;
	//_DistanceFadeOffset("Distance Fade Offset", float) = 1
	//_DistanceFadeScale("Distance Fade Scale", float) = 1
	public Vector4 _PlayParams_P3DA;
	//_ControllerScale("Controller Scale", vector) = (1,1,1,1)
	//_ControllerOffset("Controller Offset", vector) = (1,1,1,1)

	public float _Init_P3DA;

	public Vector4 _ConeShapeXY_P3DA;
	//_SprayCentreHardness("Spray Centre Hardness", float) = 1
	public float _ConeScale_P3DA;
	public float _ConeScale2_P3DA;
	public float _ConeScalePow_P3DA;
	//_ConeZStop("Cone Z Stop", float) = 1
	public float _ConeClamp_P3DA;

	public Vector4 _FadeShapeXY_P3DA;
	public float _FadeScalePow_P3DA;
	public Vector4 _FadeScale_P3DA;
	public float _BlendSubtraction_P3DA;
	public float _BlendAddition_P3DA;

	public float _TargetRingLocation_P3DA;
	public float _TargetRingThickness_P3DA;

	public float _SprayBlend_P3DA;
	public float _EraseBlend_P3DA;

	public float _ColorSampleDist_P3DA;
	public Vector4 _ColorSampleDist_P3DA_ST = new Vector4(1,1,0,0);
	public float _ColorSampleThresh_P3DA;
	public Vector4 _ColorSamplerVolume_P3DA;


	
	public static readonly string _StampTex	= "_StampTex";
    public static readonly string _BrushPosWS = "_BrushPosWS_P3DA";
    public static readonly string _BrushBuffer = "_BrushBuffer_P3DA";
    public static readonly string _MainTex = "_MainTex_P3DA";
    public static readonly string _MainTexScreen = "_MainTexScreen_P3DA";
    public static readonly string _MainTexInternal = "_MainTexInternal_P3DA";
    public static readonly string _DisplacementTexInternal = "_DisplacementTexInternal_P3DA";
	
    public static readonly string _MainTexInternal_Sampler = "_MainTexInternal_Sampler_P3DA";
    
    public static readonly string _ReadbackRenderTex = "_ReadbackRenderTex_P3DA";
    public static readonly string _Init = "_Init_P3DA";

    public static readonly string _TMainTex = "_TMainTex_P3DA";
    public static readonly string _TMainTexInternal = "_TMainTexInternal_P3DA";

    public static readonly string _Matrix_iTR = "_Matrix_iTR_P3DA";
    public static readonly string _PositionSS = "_PositionSS_P3DA";
    public static readonly string _PositionWS = "_PositionWS_P3DA";
    
    public static readonly string _PaintingParams = "_PaintingParams_P3DA";


	Renderer m_Renderer;
	public Material getMaterial{get{return m_Renderer.sharedMaterial;}}

	[SerializeField]
	bool m_DebugClearSelfFromPaintableAtlasRTs = false;

	// Use this for initialization
	void Awake () {
		m_Renderer = GetComponent<Renderer>();

		#if !UNITY_EDITOR
		setMaterialValues(m_meshRenderer.sharedMaterial);
		#endif
	}

	void OnEnable(){
		#if UNITY_EDITOR
		setMaterialValues(m_Renderer.sharedMaterial);
		if(Application.isPlaying)
			m_Renderer.sharedMaterial.EnableKeyword("_RUNNING_IN_PLAY_MODE_");
		else
			m_Renderer.sharedMaterial.DisableKeyword("_RUNNING_IN_PLAY_MODE_");
		#else
		m_meshRenderer.sharedMaterial.EnableKeyword("_RUNNING_IN_PLAY_MODE_");		
		#endif
	}

	/*
	void LateUpdate(){
		if(use_3D_PAINT_ACCUMULATOR_){
			Material mat = m_meshRenderer.sharedMaterial;
			// Doesn't work? even when run in update (maybe script exec order)
			mat.SetOverrideTag("RenderType", "Transparent");
			mat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
			mat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
			mat.SetInt("_ZWrite", 0);
			mat.DisableKeyword("_ALPHATEST_ON");
			mat.DisableKeyword("_ALPHABLEND_ON");
			mat.EnableKeyword("_ALPHAPREMULTIPLY_ON");
			mat.renderQueue = 3000;
		}
	}*/
	
	void setMaterialValues(Material mat){
		if(use_3D_PAINT_ACCUMULATOR_){			

			mat.EnableKeyword("_3D_PAINT_ACCUMULATOR_");
			mat.EnableKeyword("UNITY_REQUIRE_FRAG_WORLDPOS");
			wasSet_UNITY_REQUIRE_FRAG_WORLDPOS = true;

			if(use_CUSTOM_VERTEX_DISPLACEMENT){
				mat.EnableKeyword("_CUSTOM_VERTEX_DISPLACEMENT_");
			}

			mat.SetShaderPassEnabled("Always", true);//https://forum.unity.com/threads/5-6-how-to-use-material-setshaderpassenabled.466532/
			//mat.SetShaderPassEnabled("_Paint3DAccumulator_ P0 0", true);
			//mat.SetShaderPassEnabled("_Paint3DAccumulator_ P0 1", true);
			//mat.SetShaderPassEnabled("FORWARD P1 0", true);
			mat.SetInt("_CullInFwdAdd", 0);//Enum(Off,0,Front,1,Back,2)

		}
		else{
			mat.DisableKeyword("_3D_PAINT_ACCUMULATOR_");
			if(wasSet_UNITY_REQUIRE_FRAG_WORLDPOS)
			{
				mat.DisableKeyword("UNITY_REQUIRE_FRAG_WORLDPOS");
				wasSet_UNITY_REQUIRE_FRAG_WORLDPOS = false;
			}
			
			mat.SetShaderPassEnabled("Always", false);//https://forum.unity.com/threads/5-6-how-to-use-material-setshaderpassenabled.466532/
			//mat.SetShaderPassEnabled("_Paint3DAccumulator_ P0 0", false);
			//mat.SetShaderPassEnabled("_Paint3DAccumulator_ P0 1", false);
			//mat.SetShaderPassEnabled("FORWARD P1 0", false);
			mat.SetInt("_CullInFwdAdd", 2);//Enum(Off,0,Front,1,Back,2)
		}

		if(!use_CUSTOM_VERTEX_DISPLACEMENT){
			mat.DisableKeyword("_CUSTOM_VERTEX_DISPLACEMENT_");
		}

		if(use_GPU_COLOR_PICKER_){
			mat.EnableKeyword("_GPU_COLOR_PICKER_");
		}
		else{
			mat.DisableKeyword("_GPU_COLOR_PICKER_");
		}


		if(use_BLEND_2_TEXTURES_WITH_PAINT_){
			mat.EnableKeyword("_BLEND_2_TEXTURES_WITH_PAINT_");
		}
		else{
			mat.DisableKeyword("_BLEND_2_TEXTURES_WITH_PAINT_");
		}

		if(use_ERASE_MESH_WITH_PAINT_){
			mat.EnableKeyword("_ERASE_MESH_WITH_PAINT_");
		}
		else{
			mat.DisableKeyword("_ERASE_MESH_WITH_PAINT_");
		}

		if(use_DISPLAY_BRUSH_VOLUME_){
			mat.EnableKeyword("_DISPLAY_BRUSH_VOLUME_");
		}
		else{
			mat.DisableKeyword("_DISPLAY_BRUSH_VOLUME_");
		}

		

		mat.SetInt("_UVsToUse_P3DA", (int)m_whichUVsToUse);
		mat.SetVector("_Atlas_ST_PerMaterial_P3DA",_Atlas_ST_PerMaterial_P3DA);

		mat.SetTexture("_OverlayTex_Before_P3DA", _OverlayTex_Before_P3DA);
		OptionalStampTexture = _OverlayTex_Before_P3DA;
		mat.SetVector("_OverlayTex_Before_P3DA_ST", _OverlayTex_Before_P3DA_ST);
		mat.SetTexture("_OverlayTex_After_P3DA", _OverlayTex_After_P3DA);

		
		mat.SetFloat("_HeightMapStrength_P3DA",_HeightMapStrength_P3DA);

		mat.SetColor("_Color_P3DA", _Color_P3DA);
		mat.SetColor("_EraserColor_P3DA", _EraserColor_P3DA);
		mat.SetTexture("_ColorPicker_P3DA", _ColorPicker_P3DA);
		
		mat.SetTexture("_ColorPickerDisplay_P3DA", _ColorPickerDisplay_P3DA);
	
		mat.SetTexture("_MainTex_P3DA",_MainTex_P3DA);
		mat.SetVector("_MainTex_P3DA_ST",_MainTex_P3DA_ST);
		
		//mat.SetTexture(_MainTexScreen_P3DA("_MainTexScreen_P3DA (should be a RT)", 2D) = "white" {}
		//mat.SetTexture(_MainTexInternal_P3DA("_MainTexInternal_P3DA (should be a RT)", 2D) = "white" {}
		//_MainTexInternal_P3DA_Sampler("_MainTexInternal_P3DA_Sampler (should be from RT)", 2D) = "white" {}
		
		mat.SetTexture("_BgTex_P3DA",_BgTex_P3DA);
		mat.SetTexture("_ToolOutlineTex_P3DA",_ToolOutlineTex_P3DA);
		mat.SetFloat("_BrushScaleOffset_P3DA",_BrushScaleOffset_P3DA);

		mat.SetFloat("_BrushScaleMod_P3DA",_BrushScaleMod_P3DA);
		//_DistanceFadeOffset("Distance Fade Offset", float) = 1
		//_DistanceFadeScale("Distance Fade Scale", float) = 1
		mat.SetVector("_PlayParams_P3DA",_PlayParams_P3DA);
		//_ControllerScale("Controller Scale", vector) = (1,1,1,1)
		//_ControllerOffset("Controller Offset", vector) = (1,1,1,1)

		mat.SetFloat("_Init_P3DA",_Init_P3DA);

		mat.SetVector("_ConeShapeXY_P3DA",_ConeShapeXY_P3DA);
		//_SprayCentreHardness("Spray Centre Hardness", float) = 1
		mat.SetFloat("_ConeScale_P3DA",_ConeScale_P3DA);
		mat.SetFloat("_ConeScale2_P3DA",_ConeScale2_P3DA);
		mat.SetFloat("_ConeScalePow_P3DA",_ConeScalePow_P3DA);
		//_ConeZStop("Cone Z Stop", float) = 1
		mat.SetFloat("_ConeClamp_P3DA",_ConeClamp_P3DA);

		mat.SetVector("_FadeShapeXY_P3DA",_FadeShapeXY_P3DA);
		mat.SetFloat("_FadeScalePow_P3DA",_FadeScalePow_P3DA);
		mat.SetVector("_FadeScale_P3DA",_FadeScale_P3DA);
		mat.SetFloat("_BlendSubtraction_P3DA",_BlendSubtraction_P3DA);
		mat.SetFloat("_BlendAddition_P3DA",_BlendAddition_P3DA);

		mat.SetFloat("_TargetRingLocation_P3DA",_TargetRingLocation_P3DA);
		mat.SetFloat("_TargetRingThickness_P3DA",_TargetRingThickness_P3DA);

		mat.SetFloat("_SprayBlend_P3DA",_SprayBlend_P3DA);
		mat.SetFloat("_EraseBlend_P3DA",_EraseBlend_P3DA);

		mat.SetFloat("_ColorSampleDist_P3DA",_ColorSampleDist_P3DA);
		mat.SetVector("_ColorSampleDist_P3DA_ST",_ColorSampleDist_P3DA_ST);
		mat.SetFloat("_ColorSampleThresh_P3DA",_ColorSampleThresh_P3DA);
		mat.SetVector("_ColorSamplerVolume_P3DA",_ColorSamplerVolume_P3DA);

		//mat.SetColor("_Color", new Color(Random.Range(0,10),Random.Range(0,10),Random.Range(0,10)));
	}

	public void ClearThisObjectFromRenderTextureAtlasRTs(){
		RenderManager.Instance.ClearTileWithinRenderTextureAtlas(RTColorInitializerMat,_Atlas_ST_PerMaterial_P3DA);
	}

	// Update is called once per frame
	void Update () {
		#if UNITY_EDITOR
			if(m_DebugClearSelfFromPaintableAtlasRTs){
				m_DebugClearSelfFromPaintableAtlasRTs = false;
				RenderManager.Instance.ClearTileWithinRenderTextureAtlas(RTColorInitializerMat,_Atlas_ST_PerMaterial_P3DA);
			}

			if(Application.isPlaying){
				setMaterialValues(m_Renderer.sharedMaterial);
			}
			else{
				setMaterialValues(m_Renderer.sharedMaterial);
			}
		//#else
		//	setMaterialValues(m_meshRenderer.material);
		#endif
	}
}
