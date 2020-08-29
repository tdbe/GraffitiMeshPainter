using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class RenderManager : MonoBehaviourSingleton<RenderManager> {

    int memalloc = 24;//36;//48;// a float3 is 12 bytes. the structure I send to the gpu has 3 float3s
    [SerializeField]
    float m_hdResolutionScale = 1f;
    [SerializeField]
    Vector2 m_rtSizeCustom = new Vector2(2048, 2048);
    int rtWH_x;
    int rtWH_y;

    [SerializeField]
    Camera m_Camera;

    [SerializeField]
    bool alsoAssignRenderTextureOnOtherObjects = false;
    [SerializeField]
    GameObject[] assigneeObjects;
    Renderer[] assigneeObjectRenderers;
    [SerializeField]
    bool alsoAssignInternalRenderTextureOnOtherObjects = false;
    [SerializeField]
    GameObject[] assigneeObjectsForInternalRT;
    Renderer[] assigneeObjectRenderersForInternalRT;
    [SerializeField]
    bool alsoAssignInternalDisplacementRenderTextureOnOtherObjects = false;
    [SerializeField]
    GameObject[] assigneeObjectsForInternalDisplacementRT;
    Renderer[] assigneeObjectRenderersForInternalDisplacementRT;
    
    [SerializeField]
    RenderTexture m_paintAccumulationRT;
    [SerializeField]
    RenderTexture m_DisplacementAccumulationRT;
    [SerializeField]
    RenderTexture m_screenRT;

    //[SerializeField]
    //RenderTexture m_readbackRT;
    //RenderBuffer defaultColorBuffer;
    //RenderBuffer defaultDepthBuffer;

    //RenderBuffer[] renderTargetBuffer;

    ComputeBuffer _BrushComputeBuffer;
    ComputeBuffer m_BrushComputeBuffer { get { if (_BrushComputeBuffer == null) { _BrushComputeBuffer = new ComputeBuffer(SprayCanControlManager.maxPainterToolsForShader, memalloc); } return _BrushComputeBuffer; } set { _BrushComputeBuffer = value; } }

    //Material _assignee_mat;
    //Material m_assignee_mat { get { /*if (_wall_mat == null) { */_assignee_mat = assigneeObjectRenderer.material; /*}*/  return _assignee_mat; } set { _assignee_mat = value; } }
    
    /// <summary>
    /// This is globally referenced through sharedMaterial because it's meant to never be instanced and it's meant to be global, one material reused on multiple meshes
    /// </summary>
    //[SerializeField]
    //Material m_PaintAccumulator_mat;
    //[SerializeField]
    MaterialInspector_P3DA[] m_MaterialInspectorDataArr;
    Vector4[] m_Atlas_ST_PerMaterial;


    //[SerializeField]
    //Transform m_tempMeshToDraw;

    //[SerializeField]
    //Texture m_tempDebugTexture;

    //int mTexPropID1;
    //int mTexPropID2;
    //RenderTargetIdentifier rtID1;
    //RenderTargetIdentifier rtID2;


    //CommandBuffer m_paintAccumulatorCB = null;

    //Mesh m_blitQuad;

    int initRTBg = 0;
    [SerializeField]
    bool m_DebugClearAllTextreAtlasses = false;
    bool m_BlitToErase = false;

    struct MatAndSTPair{
        public Material mat;
        public Vector4 st;
        public MatAndSTPair(Material mat, Vector4 st){
            this.mat = mat;
            this.st = st;
        }
    }
    Queue<MatAndSTPair> erasureFromRTAtlasQueue;

    // Use this for initialization
    void Start ()
    {
        m_MaterialInspectorDataArr = FindObjectsOfType<MaterialInspector_P3DA>();
        erasureFromRTAtlasQueue = new Queue<MatAndSTPair>();
        if(alsoAssignRenderTextureOnOtherObjects){
            int i = 0;
            assigneeObjectRenderers = new Renderer[assigneeObjects.Length];
            foreach(GameObject assigneeObject in assigneeObjects){
                assigneeObjectRenderers[i] = assigneeObject.GetComponent<Renderer>();
                i++;
            }
            //m_assignee_mat = assigneeObjectRenderer.material;
        }

        if(alsoAssignInternalRenderTextureOnOtherObjects){
            int i = 0;
            assigneeObjectRenderersForInternalRT = new Renderer[assigneeObjectsForInternalRT.Length];
            foreach(GameObject assigneeObjectForInternalRT in assigneeObjectsForInternalRT){
                assigneeObjectRenderersForInternalRT[i] = assigneeObjectForInternalRT.GetComponent<Renderer>();
                i++;
            }
            //m_assignee_mat = assigneeObjectRenderer.material;
        }

        bool displacementUsed = false;
        foreach(MaterialInspector_P3DA m_MaterialInspectorData in m_MaterialInspectorDataArr){
            if(m_MaterialInspectorData.use_CUSTOM_VERTEX_DISPLACEMENT){
                displacementUsed = true;
                break;
            }
        }
        if(displacementUsed && alsoAssignInternalDisplacementRenderTextureOnOtherObjects){
            int i = 0;
            assigneeObjectRenderersForInternalDisplacementRT = new Renderer[assigneeObjectsForInternalDisplacementRT.Length];
            foreach(GameObject assigneeObjectForInternalDisplacementRT in assigneeObjectsForInternalDisplacementRT){
                assigneeObjectRenderersForInternalDisplacementRT[i] = assigneeObjectForInternalDisplacementRT.GetComponent<Renderer>();
                i++;
            }
            //m_assignee_mat = assigneeObjectRenderer.material;
        }

        
        
        //m_blitQuad = getQuad();
        CalculateAtlassOffsetAndScale();

        ConstructDataBuffers(SprayCanControlManager.maxPainterToolsForShader);
        //constructCommandBuffers();
        ConstructRenderTargets();
        //RenderCB();
       
    }
	
	// Update is called once per frame
	void Update ()
    {
        //for UBER:
        //m_PaintAccumulator_mat.SetTexture("_MainTex", m_screenRT);

        if(m_DebugClearAllTextreAtlasses){
            m_DebugClearAllTextreAtlasses = false;
            ClearAllTextureAtlasses();
            //ClearRenderTextureAtlasesBlit(true,true,true);
            
        }

        RenderCB();
    }



    void CalculateAtlassOffsetAndScale(){
        float matCount = m_MaterialInspectorDataArr.Length;
        m_Atlas_ST_PerMaterial = new Vector4[(int)matCount];
        float rowLength = Mathf.Ceil(Mathf.Sqrt(matCount));
        float scaleXY = 1/rowLength;
        Debug.Log("There are "+matCount+" paintable materials in the scene, on a paint atlas of "+m_rtSizeCustom*m_hdResolutionScale+" pixels.");
        for(int i = 1; i<=matCount; i++){
            m_Atlas_ST_PerMaterial[i-1] = Vector4.zero;
            m_Atlas_ST_PerMaterial[i-1].x = scaleXY;
            m_Atlas_ST_PerMaterial[i-1].y = scaleXY;

            if(i-1<rowLength){
                m_Atlas_ST_PerMaterial[i-1].z = (i-1)*scaleXY;
                m_Atlas_ST_PerMaterial[i-1].w = 0;
            }
            else{
                float iDivRowLength = Mathf.Floor((i-1)/rowLength);
                float wrappedRowIndex = i - 1 - (iDivRowLength*rowLength);
                m_Atlas_ST_PerMaterial[i-1].z = wrappedRowIndex*scaleXY;
                m_Atlas_ST_PerMaterial[i-1].w = iDivRowLength*scaleXY;
            }

            m_MaterialInspectorDataArr[i-1]._Atlas_ST_PerMaterial_P3DA = m_Atlas_ST_PerMaterial[i-1];
        }
    }

    void ConstructDataBuffers(int maxControllers)
    {
        Debug.Log("Constructing Controller Buffer; SprayCanControlManager.maxPainterToolsForShader: " + SprayCanControlManager.maxPainterToolsForShader+ "; memalloc: "+ memalloc);
        m_BrushComputeBuffer = new ComputeBuffer(maxControllers, memalloc);//stride = sizeof(Particle)
        Graphics.SetRandomWriteTarget(1, m_BrushComputeBuffer, true);
        Material prevMat = null;
        foreach(MaterialInspector_P3DA m_MaterialInspectorData in m_MaterialInspectorDataArr){
            if(m_MaterialInspectorData.getMaterial != prevMat){
                m_MaterialInspectorData.getMaterial.SetBuffer(MaterialInspector_P3DA._BrushBuffer, m_BrushComputeBuffer);
            }
            prevMat = m_MaterialInspectorData.getMaterial;
        }
        //Shader.SetGlobalBuffer(_BrushBuffer, m_BrushBuffer);
    }

    void constructCommandBuffers()
    {
        //m_paintAccumulatorCB = new CommandBuffer();
        //m_paintAccumulatorCB.name = "paintAccumulatorCB";
        
        m_Camera.RemoveAllCommandBuffers();
        //m_wallCam.AddCommandBuffer(CameraEvent.AfterLighting, m_paintAccumulatorCB);

    }

    void ConstructRenderTargets()
    {
        
        //defaultColorBuffer = Graphics.activeColorBuffer;
        //defaultDepthBuffer = Graphics.activeDepthBuffer;

        //rtWH_x = (int)(m_wallCam.pixelWidth * hdResolutionScale);
        //rtWH_y = (int)(m_wallCam.pixelHeight * hdResolutionScale);
        rtWH_x = (int)(m_rtSizeCustom.x * m_hdResolutionScale);
        rtWH_y = (int)(m_rtSizeCustom.y * m_hdResolutionScale);
        Debug.Log("rtWH_x: "+ rtWH_x+ "; rtWH_y: "+ rtWH_y);
        Debug.Log("UnityEngine.XR.XRSettings.eyeTextureWidth: "+UnityEngine.XR.XRSettings.eyeTextureWidth+"; UnityEngine.XR.XRSettings.eyeTextureHeight: "+UnityEngine.XR.XRSettings.eyeTextureHeight);


        //m_paintAccumulationRT = new RenderTexture(rtWH_x, rtWH_y, 24, RenderTextureFormat.ARGB32);//RenderTextureFormat.ARGB32,RenderTextureReadWrite        
        m_paintAccumulationRT = new RenderTexture(rtWH_x, rtWH_y, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);//RenderTextureFormat.ARGB32,RenderTextureReadWrite        
        m_paintAccumulationRT.name = MaterialInspector_P3DA._MainTexInternal;
        m_paintAccumulationRT.enableRandomWrite = true;
        m_paintAccumulationRT.Create();   

        //m_screenRT = new RenderTexture(rtWH_x, rtWH_y, 24, RenderTextureFormat.ARGB32);
        m_screenRT = new RenderTexture(rtWH_x, rtWH_y, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        m_screenRT.name = MaterialInspector_P3DA._MainTexScreen;
        m_screenRT.enableRandomWrite = true;
        m_screenRT.Create();
        //Debug.Log(m_screenRT.width);
        //Debug.Log(m_screenRT.height);

        
        Material prevMat = null;
        bool displacementUsed = false;
        int i = 0;
        /// <summary>
        /// TODO: There's some bullshit happening here: 
        /// On Start, you can blit sourceRT destRT and it works, but shader model 5.0 does can't write to RWTexture2D at this /// <summary>
        /// After start, during any kind of update or onRender or onPreRender or onPostRender, Blit sourceRT destRT doesn't work. It does blit to screen but does not save the RT. But shader model 5.0 CAN write to RenderTexture2D.
        /// </summary>
        foreach(MaterialInspector_P3DA m_MaterialInspectorData in m_MaterialInspectorDataArr){
            if(m_MaterialInspectorData.getMaterial != prevMat){
                m_MaterialInspectorData.RTColorInitializerMat.SetTexture(MaterialInspector_P3DA._StampTex, null);
                m_MaterialInspectorData.RTColorInitializerMat.SetColor("_Color", new Color(0,0,0,1));
                m_MaterialInspectorData.RTColorInitializerMat.SetVector("_Atlas_ST_PerMaterial_P3DA",m_Atlas_ST_PerMaterial[i]);
                m_MaterialInspectorData.RTColorInitializerMat.SetInt("_OnStart", 1);
                
                Graphics.Blit(m_screenRT,m_screenRT,m_MaterialInspectorData.RTColorInitializerMat);
                //m_MaterialInspectorData.RTColorInitializerMat.SetTexture(MaterialInspector_P3DA._StampTex, m_MaterialInspectorData._OverlayTex_Before_P3DA);
                //m_MaterialInspectorData.RTColorInitializerMat.SetColor("_Color", new Color(0,0,0,0));
                Graphics.Blit(m_paintAccumulationRT,m_paintAccumulationRT,m_MaterialInspectorData.RTColorInitializerMat);
                if(m_MaterialInspectorData.use_CUSTOM_VERTEX_DISPLACEMENT){
                    displacementUsed = true;
                    m_MaterialInspectorData.RTColorInitializerMat.SetColor("_Color", new Color(0,0,0,0));                    
                    Graphics.Blit(m_DisplacementAccumulationRT,m_DisplacementAccumulationRT,m_MaterialInspectorData.RTColorInitializerMat);
                }
                i++;
            }
            prevMat = m_MaterialInspectorData.getMaterial;            
        }
        //displacementUsed = ClearRenderTextureAtlasesBlit(true,true,false);

        if(displacementUsed){
            m_DisplacementAccumulationRT = new RenderTexture(rtWH_x, rtWH_y, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);//RenderTextureFormat.ARGB32,RenderTextureReadWrite        
            m_DisplacementAccumulationRT.name = MaterialInspector_P3DA._DisplacementTexInternal;
            m_DisplacementAccumulationRT.enableRandomWrite = true;
            m_DisplacementAccumulationRT.Create();   
        }

        

        //m_readbackRT = new RenderTexture(rtWH_x, rtWH_y, 24, RenderTextureFormat.ARGB32);//RenderTextureFormat.ARGB32,RenderTextureReadWrite        
        //m_readbackRT.name = _ReadbackRenderTex;
        ////m_readbackRT.enableRandomWrite = true;
        //m_readbackRT.Create();   

        
        if(alsoAssignRenderTextureOnOtherObjects){
            //m_assignee_mat.SetTexture(MaterialInspector_P3DA._MainTex, m_screenRT);
            foreach(Renderer assigneeObjectRenderer in assigneeObjectRenderers)
                assigneeObjectRenderer.material.SetTexture("_MainTex", m_screenRT);
        }
        if(alsoAssignInternalRenderTextureOnOtherObjects){
            //m_assignee_mat.SetTexture(MaterialInspector_P3DA._MainTex, m_screenRT);
            foreach(Renderer assigneeObjectRendererForInternalRT in assigneeObjectRenderersForInternalRT)
                assigneeObjectRendererForInternalRT.material.SetTexture("_MainTex", m_paintAccumulationRT);
        }
       
        if(displacementUsed && 
            alsoAssignInternalDisplacementRenderTextureOnOtherObjects){
            //m_assignee_mat.SetTexture(MaterialInspector_P3DA._MainTex, m_screenRT);
            foreach(Renderer assigneeObjectRendererForInternalDisplacementRT in assigneeObjectRenderersForInternalDisplacementRT)
                assigneeObjectRendererForInternalDisplacementRT.material.SetTexture("_MainTex", m_DisplacementAccumulationRT);
        }
    
        // the mat below should automatically get the _MainTex set to the RT when I Blit(), but it doesn't!? so I'm doing it here
        prevMat = null;
        foreach(MaterialInspector_P3DA m_MaterialInspectorData in m_MaterialInspectorDataArr){
            if(m_MaterialInspectorData.getMaterial != prevMat){
                m_MaterialInspectorData.getMaterial.SetTexture(MaterialInspector_P3DA._MainTexScreen, m_screenRT);
                m_MaterialInspectorData.getMaterial.SetTexture(MaterialInspector_P3DA._MainTexInternal, m_paintAccumulationRT);

                m_MaterialInspectorData.RTColorInitializerMat.SetTexture(MaterialInspector_P3DA._MainTexScreen, m_screenRT);
                m_MaterialInspectorData.RTColorInitializerMat.SetTexture(MaterialInspector_P3DA._MainTexInternal, m_paintAccumulationRT);

                if(displacementUsed){
                    m_MaterialInspectorData.getMaterial.SetTexture(MaterialInspector_P3DA._DisplacementTexInternal, m_DisplacementAccumulationRT);
                    m_MaterialInspectorData.RTColorInitializerMat.SetTexture(MaterialInspector_P3DA._DisplacementTexInternal, m_DisplacementAccumulationRT);
               }
            }
            prevMat = m_MaterialInspectorData.getMaterial;

           
        }
       
      
        //renderTargetBuffer = new RenderBuffer[] { m_screenRT.colorBuffer, m_paintAccumulationRT.colorBuffer};
        //m_wallCam.SetTargetBuffers(renderTargetBuffer, m_screenRT.depthBuffer); 
        // https://forum.unity3d.com/threads/mrt-multiple-render-target-in-unity5-how-to-best-practice.383644/
        // https://forum.unity3d.com/threads/how-to-get-screen-buffer-rendertargetidentifier.320410/

        //https://forum.unity.com/threads/problems-trying-to-write-to-rwtextures-from-frag-shaders.478124/
        //https://forum.unity.com/threads/how-to-write-to-an-unordered-access-compute-buffer-from-a-pixel-shader.403783/
        //int mTexPropID1 = Shader.PropertyToID(_MainTexScreen);
        //RenderTargetIdentifier rtID1 = new RenderTargetIdentifier(mTexPropID1);
        //int mTexPropID2 = Shader.PropertyToID(_MainTexInternal);
        //RenderTargetIdentifier rtID2 = new RenderTargetIdentifier(mTexPropID2);
        foreach(MaterialInspector_P3DA m_MaterialInspectorData in m_MaterialInspectorDataArr){
            m_MaterialInspectorData.getMaterial.SetVector("_RT_Resolution", m_rtSizeCustom);
            m_MaterialInspectorData.RTColorInitializerMat.SetVector("_RT_Resolution", m_rtSizeCustom);

            if(m_MaterialInspectorData.use_CUSTOM_VERTEX_DISPLACEMENT)
              Graphics.SetRandomWriteTarget(4, m_DisplacementAccumulationRT);//with `, true);` it doesn't take RTs

        }
        //Graphics.ClearRandomWriteTargets();// only place this before all (command) buffers have been created
        Graphics.SetRandomWriteTarget(3, m_paintAccumulationRT);//with `, true);` it doesn't take RTs
        //Graphics.SetRenderTarget(m_paintAccumulationRT, 0, CubemapFace.Unknown);
        Graphics.SetRandomWriteTarget(2, m_screenRT);//with `, true);` it doesn't take RTs
        //Graphics.SetRenderTarget(m_screenRT, 0, CubemapFace.Unknown);
        //Graphics.ClearRandomWriteTargets();
        
    }


    void RenderCB()
    {
        // enable clear if you run this function every frame. (if you run it once, you just queue the command and it runs on the gpu automatically; if you runit every frame that means you want to update it, so you must clear the commands already on the gpu)
        //m_paintAccumulatorCB.Clear();
        //m_paintAccumulatorCB.ClearRenderTarget(true, true, Color.cyan);
        int point = 10;
        if (initRTBg < point)
        {
            initRTBg++;
            Material prevMat = null;
            foreach(MaterialInspector_P3DA m_MaterialInspectorData in m_MaterialInspectorDataArr){
                if(m_MaterialInspectorData.getMaterial != prevMat){
                    m_MaterialInspectorData.getMaterial.SetFloat(MaterialInspector_P3DA._Init, 1);
                }
                prevMat = m_MaterialInspectorData.getMaterial;
            }
        }
        else if (initRTBg == point)
        {
            initRTBg = point+1;
            Material prevMat = null;
            foreach(MaterialInspector_P3DA m_MaterialInspectorData in m_MaterialInspectorDataArr){
                if(m_MaterialInspectorData.getMaterial != prevMat){
                    m_MaterialInspectorData.getMaterial.SetFloat(MaterialInspector_P3DA._Init, 0);
                }
                prevMat = m_MaterialInspectorData.getMaterial;
            }
        }
/*
        Graphics.ClearRandomWriteTargets();
        Graphics.SetRandomWriteTarget(3, m_paintAccumulationRT);
        Graphics.SetRenderTarget(m_paintAccumulationRT, 0, CubemapFace.Unknown);
        // this sets the shader output to be a RT instead of the screen
        //I want it to render normally and also to the RT, in 2 passes
        Graphics.SetRandomWriteTarget(2, m_screenRT);//, true);
        Graphics.SetRenderTarget(m_screenRT, 0, CubemapFace.Unknown);
        Graphics.ClearRandomWriteTargets();
*/

            //m_2DSprayAccumulator_mat.SetTexture(_MainTex, m_paintAccumulationRT);
            // gotta do this temp RT crap because otherwise unity's Blit will clear the RT every frame: http://answers.unity3d.com/questions/1120403/prevent-render-texture-clearing.html
            //RenderTexture temp = RenderTexture.GetTemporary(m_wallCam.pixelWidth* hdResolutionScale, m_wallCam.pixelHeight* hdResolutionScale, 24, RenderTextureFormat.Default);
            //temp.name = _MainTexInternal;


            //m_paintAccumulatorCB.SetGlobalTexture(_MainTex, m_screenRT);
            //m_paintAccumulatorCB.SetGlobalTexture(_MainTexInternal, m_paintAccumulationRT);

            //m_paintAccumulatorCB.GetTemporaryRT(mTexPropID1, m_wallCam.pixelWidth * hdResolutionScale, m_wallCam.pixelHeight * hdResolutionScale, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
            //m_paintAccumulatorCB.GetTemporaryRT(mTexPropID2, m_wallCam.pixelWidth * hdResolutionScale, m_wallCam.pixelHeight * hdResolutionScale, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

/*
        RenderTexture temp1 = RenderTexture.GetTemporary(rtWH_x, rtWH_y, 24, RenderTextureFormat.ARGB32);
        temp1.name = _MainTexScreen;

        RenderTexture temp2 = RenderTexture.GetTemporary(rtWH_x, rtWH_y, 24, RenderTextureFormat.ARGB32);
        temp2.name = _MainTexInternal;
*/
            // Can't get multiple color render targets to work :( Frame Debugger just says default deferred gbuffer regardless of my SetRenderTarget() call
            //RenderTargetIdentifier[] rti = new RenderTargetIdentifier[] { rtID1, rtID2 };// m_screenRT };
            //m_paintAccumulatorCB.SetRenderTarget(rti, m_paintAccumulationRT.depth);//.Depth
            //RenderBuffer[] rtb = new RenderBuffer[] { temp1.colorBuffer, temp2.colorBuffer };
            //RenderTargetIdentifier[] rti = new RenderTargetIdentifier[] { temp1, temp2 };
            //m_paintAccumulatorCB.SetRenderTarget(rti, new RenderTargetIdentifier(temp1.depth));
            //m_paintAccumulatorCB.SetRenderTarget(rti, BuiltinRenderTextureType.Depth);


            //m_2DSprayAccumulator_mat.SetPass(0);
            //m_paintAccumulatorCB.DrawMesh(m_blitQuad, Matrix4x4.identity, m_2DSprayAccumulator_mat);
/*
        m_paintAccumulatorCB.Blit(m_paintAccumulationRT, temp2, m_2DSprayAccumulator_mat, 0);
        m_paintAccumulatorCB.Blit(temp2, temp1, m_2DSprayAccumulator_mat, 1);


        //m_2DSprayAccumulator_mat.SetTexture(_MainTexScreen, temp1);
        //m_2DSprayAccumulator_mat.SetTexture(_MainTexInternal, temp2);
        m_paintAccumulatorCB.Blit(temp1, m_screenRT);
        m_paintAccumulatorCB.Blit(temp2, m_paintAccumulationRT);
        //m_2DSprayAccumulator_mat.SetTexture(_MainTexScreen, m_screenRT);
        //m_2DSprayAccumulator_mat.SetTexture(_MainTexInternal, m_paintAccumulationRT);
*/

/* 
        //m_paintAccumulatorCB.Blit(m_tempDebugTexture, m_screenRT);
        m_paintAccumulatorCB.DrawMesh(m_tempMeshToDraw.GetComponent<SkinnedMeshRenderer>().sharedMesh, 
                                         Matrix4x4.TRS(m_tempMeshToDraw.position, m_tempMeshToDraw.rotation, m_tempMeshToDraw.localScale),
                                         m_2DSprayAccumulator_mat,
                                         0,
                                         0);
        
        m_paintAccumulatorCB.DrawMesh(m_tempMeshToDraw.GetComponent<SkinnedMeshRenderer>().sharedMesh, 
                                        Matrix4x4.TRS(m_tempMeshToDraw.position, m_tempMeshToDraw.rotation, m_tempMeshToDraw.localScale),
                                        m_2DSprayAccumulator_mat,
                                        0,
                                        1);

 */      
            //

            //m_paintAccumulatorCB.Blit(m_paintAccumulationRT, temp, m_2DSprayAccumulator_mat, 0);
            //m_paintAccumulatorCB.Blit(temp, m_paintAccumulationRT);
            //m_paintAccumulatorCB.Blit(rtID2, m_paintAccumulationRT);

            //temp.name = _MainTex;

            //m_paintAccumulatorCB.Blit(rtID1, m_2DSprayAccumulator_mat, 1);
            //m_paintAccumulatorCB.Blit(rtID1, m_screenRT, m_2DSprayAccumulator_mat,1);
            //m_paintAccumulatorCB.Blit(rtID1, m_screenRT);
/*
        RenderTexture.ReleaseTemporary(temp1);
        RenderTexture.ReleaseTemporary(temp2);
*/
            //m_paintAccumulatorCB.ReleaseTemporaryRT(mTexPropID1);
            //m_paintAccumulatorCB.ReleaseTemporaryRT(mTexPropID2);
            //RenderTexture.ReleaseTemporary(temp);
    }




    /// <summary>
    /// 0 parameter helper function for ClearRenderTextureAtlases(bool clearScreenRT, bool clearInternalRT, bool clearDisplacementRT){
    /// NOTE: The Blit method does not work outside of Start(). Seems like it gets ignored if the object is rendering regularly. 
    /// So I'm creating new RTs. TODO: find better way
    /// </summary>
    private void ClearAllTextureAtlasses(){
        //ConstructRenderTargets();
        m_BlitToErase = true;
        //ClearRenderTextureAtlasesBlit(true,true,true);
    }
    
    
    void OnPostRender(){
        if(m_BlitToErase == true){
            m_BlitToErase = false;
            ClearRenderTextureAtlasesBlit(true,true,true);
        }

        int maxIt = 1000;
        int it = 0;
        do{
            if(it>maxIt){
                Debug.Log("WARNING: Dequeue while maxed out.");
                break;
            }
            if(erasureFromRTAtlasQueue == null || erasureFromRTAtlasQueue.Count==0)
                break;
            MatAndSTPair matAndSTPair = erasureFromRTAtlasQueue.Dequeue();
            ClearTileWithinRenderTextureAtlasInternal(matAndSTPair.mat,matAndSTPair.st);
            it++;
        }while(erasureFromRTAtlasQueue.Count>0);        
    }
    /*
    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if(m_BlitToErase == true)
            ClearRenderTextureAtlasesBlit(true,true,true);
    }
    */

    /// <summary>
    /// OnPostRender is called after a camera finishes rendering the scene.
    /// </summary>
    /* 
    void OnPostRender()
    {
        //RenderCB();
        //Graphics.Blit(m_paintAccumulationRT, m_readbackRT);
        if(m_BlitToErase == true)
            ClearRenderTextureAtlasesBlit(true,true,true);
        m_BlitToErase = false;
    }
    */
    /// <summary>
    /// NOTE: The Blit method does not work outside of Start(). Seems like it gets ignored if the object is rendering regularly. 
    /// So I'm creating new RTs bycalling ConstructRenderTargets() instead of just this. TODO: find better way
    /// The first 2 params usually should be cleared together, doesn't usually make sense otherwise.
    /// The third parameter will clear the displacement texture if one is available.
    /// </summary>
    /// <param name="clearScreenRT"></param>
    /// <param name="clearInternalRT"></param>
    /// <param name="clearDisplacementRT"></param>
    public bool ClearRenderTextureAtlasesBlit(bool clearScreenRT, bool clearInternalRT, bool clearDisplacementRT){
        Material prevMat = null;
        bool displacementUsed = false;
        int i = 0;
        foreach(MaterialInspector_P3DA m_MaterialInspectorData in m_MaterialInspectorDataArr){
            if(m_MaterialInspectorData.getMaterial != prevMat){
                if(clearScreenRT || clearInternalRT || clearDisplacementRT){
                    m_MaterialInspectorData.RTColorInitializerMat.SetTexture(MaterialInspector_P3DA._StampTex, null);
                    m_MaterialInspectorData.RTColorInitializerMat.SetColor("_Color", new Color(0,0,0,1));
                    m_MaterialInspectorData.RTColorInitializerMat.SetVector("_Atlas_ST_PerMaterial_P3DA",m_Atlas_ST_PerMaterial[i]);
                    //m_MaterialInspectorData.RTColorInitializerMat.SetVector("_VRSettingsEyeTextureWidthHeight",new Vector2(UnityEngine.XR.XRSettings.eyeTextureWidth, UnityEngine.XR.XRSettings.eyeTextureHeight));
                    m_MaterialInspectorData.RTColorInitializerMat.SetInt("_OnStart", 0);
                }
                /*
                m_Camera.targetTexture = m_screenRT;
                float camAspect = m_Camera.aspect;
                m_Camera.aspect = 1;
                float eyeResScale = UnityEngine.XR.XRSettings.eyeTextureResolutionScale;
                UnityEngine.XR.XRSettings.eyeTextureResolutionScale = 4;//rtWH_x / UnityEngine.XR.XRSettings.eyeTextureWidth;
                Graphics.Blit(m_paintAccumulationRT,m_screenRT,m_MaterialInspectorData.RTColorInitializerMat,-1);
                m_Camera.targetTexture = null;
                m_Camera.aspect = camAspect;
                UnityEngine.XR.XRSettings.eyeTextureResolutionScale = eyeResScale;
                */
                /*
                float widthRatio = rtWH_x / UnityEngine.XR.XRSettings.eyeTextureWidth;
                float heightRatio = rtWH_y / UnityEngine.XR.XRSettings.eyeTextureHeight;
                for(int c = 0; c<Mathf.Floor(heightRatio); c++){
                    for(int r = 0; r<Mathf.Floor(widthRatio); r++){
                        m_MaterialInspectorData.RTColorInitializerMat.SetVector("_VRSettingsEyeTextureWidthHeight",
                        new Vector2(, ));

                        Graphics.Blit(m_paintAccumulationRT,m_screenRT,m_MaterialInspectorData.RTColorInitializerMat,-1);
                    }
                }*/
                GL.PushMatrix();
                Graphics.SetRenderTarget(m_screenRT);//https://docs.unity3d.com/ScriptReference/Graphics.Blit.html
                GL.LoadOrtho();
                //GL.LoadPixelMatrix();//https://docs.unity3d.com/ScriptReference/GL.QUADS.html
                m_MaterialInspectorData.RTColorInitializerMat.SetPass(0);
                GL.Begin(GL.QUADS);
                //GL.Color(Color.red);
                /*
                GL.Vertex3(0, 0, 0);
                GL.Vertex3(0, 1, 0);
                GL.Vertex3(1, 1f, 0);
                GL.Vertex3(1f, 0, 0);
                */
                float ze = 0;
                float on = 1f;
                float onY = 0.35f;
                GL.TexCoord2(ze, on);
                GL.Vertex3(ze, onY, 0);
                GL.TexCoord2(on, on);
                GL.Vertex3(on, onY, 0);
                GL.TexCoord2(on, ze);
                GL.Vertex3(on, ze, 0);
                GL.TexCoord2(ze, ze);
                GL.Vertex3(ze, ze, 0);
                GL.End();
                GL.PopMatrix();
                //Graphics.Blit(m_paintAccumulationRT,m_screenRT,m_MaterialInspectorData.RTColorInitializerMat,-1);
              

                /*
                if(clearScreenRT){
                    Graphics.Blit(m_screenRT,m_screenRT,m_MaterialInspectorData.RTColorInitializerMat);
                    //Debug.Log("________  clearScreenRT ________");
                }
                //m_MaterialInspectorData.RTColorInitializerMat.SetTexture(MaterialInspector_P3DA._StampTex, m_MaterialInspectorData._OverlayTex_Before_P3DA);
                //m_MaterialInspectorData.RTColorInitializerMat.SetColor("_Color", new Color(0,0,0,0));
                if(clearInternalRT){
                    Graphics.Blit(m_paintAccumulationRT,m_paintAccumulationRT,m_MaterialInspectorData.RTColorInitializerMat);
                }
                */
                if(m_MaterialInspectorData.use_CUSTOM_VERTEX_DISPLACEMENT){
                    displacementUsed = true;
                    // if(clearDisplacementRT){
                    //     m_MaterialInspectorData.RTColorInitializerMat.SetColor("_Color", new Color(0,0,0,0));
                    //     Graphics.Blit(m_DisplacementAccumulationRT,m_DisplacementAccumulationRT,m_MaterialInspectorData.RTColorInitializerMat);
                    // }
                }
                
                //Debug.Log("ClearRenderTextureAtlases on mat: "+m_MaterialInspectorData.getMaterial.name+"; displacementCleared: "+(displacementUsed&&clearDisplacementRT));
                i++;
            }
            prevMat = m_MaterialInspectorData.getMaterial;
            
        }
        return displacementUsed;
    }

    void ClearTileWithinRenderTextureAtlasInternal(Material RTColorInitializerMat, Vector4 m_Atlas_ST_PerMaterial){
        
        RTColorInitializerMat.SetTexture(MaterialInspector_P3DA._StampTex, null);
        RTColorInitializerMat.SetColor("_Color", new Color(0,0,0,1));
        RTColorInitializerMat.SetVector("_Atlas_ST_PerMaterial_P3DA",m_Atlas_ST_PerMaterial);
        //m_MaterialInspectorData.RTColorInitializerMat.SetVector("_VRSettingsEyeTextureWidthHeight",new Vector2(UnityEngine.XR.XRSettings.eyeTextureWidth, UnityEngine.XR.XRSettings.eyeTextureHeight));
        RTColorInitializerMat.SetInt("_OnStart", 0);
    
        GL.PushMatrix();
        Graphics.SetRenderTarget(m_screenRT);//https://docs.unity3d.com/ScriptReference/Graphics.Blit.html
        GL.LoadOrtho();
        //GL.LoadPixelMatrix();//https://docs.unity3d.com/ScriptReference/GL.QUADS.html
        RTColorInitializerMat.SetPass(0);
        GL.Begin(GL.QUADS);
        //GL.Color(Color.red);
        /*
        GL.Vertex3(0, 0, 0);
        GL.Vertex3(0, 1, 0);
        GL.Vertex3(1, 1f, 0);
        GL.Vertex3(1f, 0, 0);
        */
        float ze = 0;
        float on = 1f;
        float onY = 0.35f;
        GL.TexCoord2(ze, on);
        GL.Vertex3(ze, onY, 0);
        GL.TexCoord2(on, on);
        GL.Vertex3(on, onY, 0);
        GL.TexCoord2(on, ze);
        GL.Vertex3(on, ze, 0);
        GL.TexCoord2(ze, ze);
        GL.Vertex3(ze, ze, 0);
        GL.End();
        GL.PopMatrix();
    }

    public void ClearTileWithinRenderTextureAtlas(Material RTColorInitializerMat, Vector4 m_Atlas_ST_PerMaterial){
       erasureFromRTAtlasQueue.Enqueue(new MatAndSTPair(RTColorInitializerMat,m_Atlas_ST_PerMaterial));
       Debug.Log("enqueued: "+erasureFromRTAtlasQueue.Count);
    }

    /// <summary>
    /// This function directly sets shader properties from the given controllerData.
    /// </summary>
    /// <param name="controllerDataArr"></param>
    public void setControllerData(SprayCanControlManager.ControllerData_P3DA[] controllerDataArr, Matrix4x4[] trMatrix, Vector4[] brushPositionsWS, Vector4[] brushPositionsSS, Vector4[] paintingParams)  
    {
        //m_2DSprayAccumulator_mat.SetFloatArray(_BrushPosWS,m_BrushBuffer)

        // this sets arbitrary data to the gpu. If a shader on the GPU has an array of the same size and data structure type as the one we pass here, then we'll be able to read it there.
        // the reason it works is that we pass a struct. Structs are cross compatible (data wise) between c, c++, c# and c for graphics (CG).
        SprayCanControlManager.ControllerData_P3DA[] data = new SprayCanControlManager.ControllerData_P3DA[2];
        m_BrushComputeBuffer.GetData(data);


        //this is a bit hacky and not modular, but no time.
        for (int i = 0; i< controllerDataArr.Length; i++)
        {
            if(paintingParams[i].z < 1.0)
            {
                controllerDataArr[i].color = data[i].color;
            }
            
        }
        
        m_BrushComputeBuffer.SetData(controllerDataArr);
        Material prevMat = null;
        foreach(MaterialInspector_P3DA m_MaterialInspectorData in m_MaterialInspectorDataArr){
            if(m_MaterialInspectorData.getMaterial != prevMat){
                m_MaterialInspectorData.getMaterial.SetVectorArray(MaterialInspector_P3DA._PositionWS, brushPositionsWS);
                m_MaterialInspectorData.getMaterial.SetVectorArray(MaterialInspector_P3DA._PositionSS, brushPositionsSS);
                m_MaterialInspectorData.getMaterial.SetVectorArray(MaterialInspector_P3DA._PaintingParams, paintingParams);
                //m_2DSprayAccumulator_mat.SetBuffer(_BrushBuffer, m_BrushBuffer);
                m_MaterialInspectorData.getMaterial.SetMatrixArray(MaterialInspector_P3DA._Matrix_iTR, trMatrix);
            }
            prevMat = m_MaterialInspectorData.getMaterial;
        }
        
        /*
        Vector4[] temp = m_2DSprayAccumulator_mat.GetVectorArray(_PositionSS);
        for (int i = 0; i < controllerDataArr.Length; i++)
        {
            Debug.Log(brushPositions[i] + "; on shader: " + temp[i]);
        }
        */
    }



    public void OnDestroy()
    {
        m_BrushComputeBuffer.Release();
    }


    Mesh getQuad()
    {
        Mesh Quad = new Mesh();
        Vector2 marginOffsetUV = Vector2.zero;

        Quad.vertices = new Vector3[]
        {
            new Vector3(0, 0, 0),
            new Vector3(1, 0, 0),
            new Vector3(1, 1, 0),
            new Vector3(0, 1, 0)
        };

        Quad.uv = new Vector2[]
        {
            new Vector2(marginOffsetUV.x, marginOffsetUV.y),
            new Vector2(1 - marginOffsetUV.x, marginOffsetUV.y),
            new Vector2(1 - marginOffsetUV.x, 1 - marginOffsetUV.y),
            new Vector2(marginOffsetUV.x, 1 - marginOffsetUV.y)
        };

        Quad.triangles = new int[] { 0, 1, 2, 0, 2, 3 };
        Quad.UploadMeshData(false);
        Quad.name = "full screen quad";

        return Quad;
    }
}
