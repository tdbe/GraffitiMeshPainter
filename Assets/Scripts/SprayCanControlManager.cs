using System;
using System.Collections.Generic;
using UnityEngine;
using Valve.VR;

public class SprayCanControlManager : MonoBehaviour {
    public static readonly int maxPainterToolsForShader = 2;

    [SerializeField]
    RenderManager m_renderMan;
    
    [SerializeField]
    float buttonPressTickSpeed = 20;
    [SerializeField]
    Vector3 m_rotOffset;//53,0,0
    Vector3 m_rotOffsetReset;
    [SerializeField]
    Vector3 m_posOffset;//0.5, -0.75, 0
    Vector3 m_posOffsetReset;
    [SerializeField]
    Vector3 m_posOffsetRelative;
    Vector3 m_posOffsetRelativeReset;
    [SerializeField]
    float m_scaleOffset = 0.33925f;
    

    [SerializeField]
    SteamVR_TrackedController[] m_steamVRControllerReferences;



    [SerializeField]
    ushort m_rumblePulseDuration = 790;

    [SerializeField]
    Camera m_Camera;

    const string _posOffsetZ = "posOffsetZ_P3DA";
    const string _posOffsetRelativeY = "posOffsetRelativeY_P3DA";
    const string _posOffsetRelativeZ = "posOffsetRelativeZ_P3DA";
    const string _rotOffsetX = "rotOffsetX_P3DA";


    [Serializable]
    public struct ControllerData_P3DA
    {
        /*
        [TextArea]
        public string MyTextArea = "
        flags for brushMode.x:\n
            .8 = just paint
            .7 = none
            .6 = blend 2 textures mode
            .5 = nothing
            .4 = vertex heightmap + paint
            .3 = none
            .2 = erase mesh mode
            .xyyyyyyyyy -> y = alpha";
        */
        public Vector3 brushMode;
        //public Vector2 positionSS;
        //public Vector3 normalws;
        //public Vector3 targetPos;
        //public Vector3 paintingParams;// paintingParams.x: 0 or 1. Y is pad pressed. Z is flag for whether c# is changing color or GPU is changing color. W is whether the brush is above the color wheel according to the gpu distance field shape.
        public Vector3 color;
        //public Vector2 paintSampleLF; // whether controller was painting or sampling last frame.
    }

    [Serializable]
    private class PainterTool{
        public string name ="painter tool airbrush";
        public int attachedInputController = 0;
        
        public Transform painterToolTransform;
        [TextArea(8,8)]
        public string Notes2 = "flags for brushMode.x:\n8 = just paint\n7 = none\n.6 = blend 2 textures mode\n.5 = nothing\n.4 = vertex heightmap + paint\n.3 = none, no paint\n.2 = erase mesh mode\n\n.xyyyyyyyyy -> y = alpha";
        [SerializeField]
        ControllerData_P3DA _controllerData;
        public ControllerData_P3DA controllerData { get { return _controllerData; } }
        public Matrix4x4 matrix_iTR;
        [SerializeField]
        Vector4 _positionWS;
        public Vector4 positionWS { get { return _positionWS; } }
        [SerializeField]

        Vector4 _positionSS;
        public Vector4 positionSS { get { return _positionSS; } }
        [SerializeField]
        Vector4 _paintingParams;
        public Vector4 paintingParams { get { return _paintingParams; } }

        /// <summary>
        /// this shouldn't be here because it's data about input.false but I didn't have another per-controller struct synced to this painter tool to store it in.
        /// </summary>
        public Vector3 prevTouchpadPos;

        
        
        public void OnPaintClicked(object sender, ClickedEventArgs e)
        {
            //Debug.Log("OnTriggerClicked");
            _paintingParams.x = 1;
        }

        public void OnPaintUnclicked(object sender, ClickedEventArgs e)
        {
            //Debug.Log("OnTriggerUnClicked");
            _paintingParams.x = 0;
        }

        public void OnEraseClicked()
        {
            _paintingParams.y = 1;
        }

        public void OnEraseUnclicked()
        {
            _paintingParams.y = 0;
        }

        public void SetTRMatrix(Transform transform, Vector3 rotOffset, Vector3 posOffset, Vector3 posOffsetRelative, float scaleOffset)
        {
            //Quaternion rotation = Quaternion.AngleAxis(-90, transform.right) * transform.rotation;
            Quaternion rotation = transform.rotation;
            Quaternion offsetRot = Quaternion.AngleAxis(rotOffset.x, transform.right) * Quaternion.AngleAxis(rotOffset.y, transform.up) * Quaternion.AngleAxis(rotOffset.z, transform.forward);

            rotation *= Quaternion.Euler(rotOffset);

            Vector3 pos = transform.position;
            pos.x += posOffset.x;// - 0.5f;
            pos.y += posOffset.y;// - 0.28125f;//16/9
            pos.z += posOffset.z;
            
            pos = pos + offsetRot * (posOffsetRelative.x * transform.right);
            pos = pos + offsetRot * (posOffsetRelative.y * transform.up); 
            pos = pos + offsetRot * (posOffsetRelative.z * transform.forward);

            Matrix4x4 MatTrs = Matrix4x4.TRS(
                               posOffset,//pos,//Vector3.zero,//Vector3.one*scaleOffset,//pos,// * scaleOffset,
                               rotation,
                               new Vector3(transform.localScale.x, transform.localScale.y, -transform.localScale.z)//new Vector3(1, 1, -1)
                               ).inverse;

            matrix_iTR = MatTrs;
            /*
            Vector3 normal = transform.forward * -1;
            normal += posOffset;
            normal *= scaleOffset;
            _controllerData.normalws = normal.normalized;
            */
        }

        public void SetColor(bool touched, Vector2 touchpad, Vector3 prevTouchpadPos)
        {

            if(touched){
                float radAgnle = Utils.CalculateAngle(new Vector3(touchpad.x, touchpad.y, 0), Vector3.up) / 360;
                //Debug.Log(radAgnle);

                Color color = Color.HSVToRGB(
                    radAgnle,
                    Vector2.Distance(touchpad, Vector2.zero),
                    1//colorHSVExisting.z
                    );
                //Debug.Log(color);
                _controllerData.color = new Vector3(color.r, color.g, color.b);
                
                
                prevTouchpadPos = touchpad;

                _paintingParams.z = 1;
            }
            else
            {
                _paintingParams.z = 0;
            }
        

        
                
        }

        public void SetPosition(Transform transform, Camera wallCam)
        {
            _positionWS = transform.position;
            Vector3 ssp = wallCam.WorldToViewportPoint(transform.position);
            _positionSS = new Vector4(ssp.x, ssp.y, ssp.z, 0);
           
        }

        public void Init(string name, int attachedInputController, Transform painterToolTransform)
        {
            this.name = name;
            this.attachedInputController = attachedInputController;
            this.painterToolTransform = painterToolTransform;
            _controllerData.color = new Vector3(1, 1, 1);
        }

        public void Init(string name, int attachedInputController)
        {
            this.name = name;
            this.attachedInputController = attachedInputController;
            _controllerData.color = new Vector3(1, 1, 1);
        }

        public void UpdateInput(SteamVR_TrackedController[] svtcontrollers){
            if(svtcontrollers[attachedInputController].gripped){
                OnEraseClicked();
            }
            else{
                OnEraseUnclicked();
            }
        }
    }
    [SerializeField]
    PainterTool[] m_painterTools;



	// Use this for initialization
	void Start ()
    {
        //OpenVR.System.GetTrackedDeviceIndexForControllerRole(ETrackedControllerRole.RightHand);

        m_posOffsetReset = m_posOffset;//new Vector3(1.47f,-0.3f,-0.2f);
        m_rotOffsetReset = m_rotOffset;// new Vector3(53, 0, 0);
        m_posOffsetRelativeReset = m_posOffsetRelative;// Vector3.zero;

        if (PlayerPrefs.HasKey(_posOffsetRelativeY))
        {
            m_posOffsetRelative.y = PlayerPrefs.GetFloat(_posOffsetRelativeY);
        }

        if (PlayerPrefs.HasKey(_posOffsetRelativeZ))
        {
            m_posOffsetRelative.z = PlayerPrefs.GetFloat(_posOffsetRelativeZ);
        }

        if (PlayerPrefs.HasKey(_posOffsetZ))
        {
            m_posOffset.z = PlayerPrefs.GetFloat(_posOffsetZ);
        }

        if (PlayerPrefs.HasKey(_rotOffsetX))
        {
            m_rotOffset.x = PlayerPrefs.GetFloat(_rotOffsetX);
        }

        // m_steamControllers = new SteamControllerWrapper[m_steamVRControllerReferences.Length];
        Debug.Log("Num steam controllers: " +m_steamVRControllerReferences.Length);
        // for (int i=0; i< m_steamVRControllerReferences.Length; i++)
        // {
        //     m_steamControllers[i] = new SteamControllerWrapper();
        // }   
    }

    void OnEnable(){
        SetupPainterTools();
    }

    void OnDisable(){
        DisablePainterTools();
    }

    void SetupPainterTools(){
        if(m_painterTools == null || m_painterTools.Length == 0){
            m_painterTools = new PainterTool[1];
        
            for(int i = 0; i< m_painterTools.Length; i++){
                m_painterTools[i] = new PainterTool();
                m_painterTools[i].Init("painter tool airbrush", i);
            }
        }

        for(int i = 0; i< m_painterTools.Length; i++){
            m_steamVRControllerReferences[m_painterTools[i].attachedInputController].TriggerClicked += m_painterTools[i].OnPaintClicked;
            m_steamVRControllerReferences[m_painterTools[i].attachedInputController].TriggerUnclicked += m_painterTools[i].OnPaintUnclicked;

            //m_steamVRControllerReferences[i].MenuButtonClicked += m_steamControllers[i].OnEraseClicked;
            //m_steamVRControllerReferences[i].MenuButtonUnclicked += m_steamControllers[i].OnEraseUnclicked;

            //steamVRControllerReferences[i].OnGripped += m_steamControllers[i].OnGripPressed;
            //steamVRControllerReferences[i].gri += m_steamControllers[i].OnGripPressed;

            //m_steamVRControllerReferences[m_painterTools[i].attachedInputController].PadClicked += m_steamControllers[i].OnPadPressed;
            //m_steamVRControllerReferences[m_painterTools[i].attachedInputController].PadUnclicked += m_steamControllers[i].OnPadUnpressed;

        }
    }

    void DisablePainterTools(){
        for(int i = 0; i< m_painterTools.Length; i++){
            m_steamVRControllerReferences[m_painterTools[i].attachedInputController].TriggerClicked -= m_painterTools[i].OnPaintClicked;
            m_steamVRControllerReferences[m_painterTools[i].attachedInputController].TriggerUnclicked -= m_painterTools[i].OnPaintUnclicked;
        }
    }


    // Update is called once per frame
    void Update()
    {

        adjustOffset();


        

        for (int i = 0; i < m_painterTools.Length; i++)
        {
            #region controller touchpad input sampler that will be treated as a color wheel
            bool touched = false;
            Vector2 touchpadVal = Vector3.zero;
            SteamVR_Controller.Device device = SteamVR_Controller.Input((int)m_steamVRControllerReferences[m_painterTools[i].attachedInputController].controllerIndex);
            // if touchpad pressed, set color and saturation
            if (!device.GetPress(SteamVR_Controller.ButtonMask.Touchpad) && 
            device.GetTouch(SteamVR_Controller.ButtonMask.Touchpad)
            )
            {
                /*
                Vector3 colorHSVExisting;
                Color.RGBToHSV(new Color(_controllerData.color.x * 255, _controllerData.color.y * 255, _controllerData.color.z * 255), out colorHSVExisting.x, out colorHSVExisting.y, out colorHSVExisting.z);
                colorHSVExisting.z = 1;
                */
                touchpadVal = device.GetAxis(EVRButtonId.k_EButton_SteamVR_Touchpad);

                if (Vector2.Distance(touchpadVal, m_painterTools[i].prevTouchpadPos) > .1f)
                {
                    device.TriggerHapticPulse((ushort)(132 + m_rumblePulseDuration * Vector2.Distance(m_painterTools[i].prevTouchpadPos, touchpadVal)));
                    touched = true;
                }
                else{
                    touched = false;
                }
            }
            else{
                touched = false;
            }
            #endregion

            m_painterTools[i].UpdateInput(m_steamVRControllerReferences);
            m_painterTools[i].SetColor(touched, touchpadVal, m_painterTools[i].prevTouchpadPos);
            m_painterTools[i].SetPosition(m_steamVRControllerReferences[m_painterTools[i].attachedInputController].transform, m_Camera);

            //Debug.Log("tr: "+ steamVRControllerReferences[m_painterTools[i].attachedInputController].transform.name+"; pos: "+ steamVRControllerReferences[i].transform.position);
            m_painterTools[i].SetTRMatrix(m_steamVRControllerReferences[m_painterTools[i].attachedInputController].transform, m_rotOffset, m_posOffset, m_posOffsetRelative, m_scaleOffset);
        }





        #region send data structures to the GPU
        // we create data for maxPainterToolsForShader
        // this is because the buffer stored on the GPU is of fixed size; it always takes maxPainterTools and runs for each one. (but we skip them in the shader if we know they are empty)
        ControllerData_P3DA[] outData = new ControllerData_P3DA[maxPainterToolsForShader];
        Matrix4x4[] matrix_iTR_arr = new Matrix4x4[maxPainterToolsForShader];
        Vector4[] positionSS = new Vector4[maxPainterToolsForShader];
        Vector4[] positionWS = new Vector4[maxPainterToolsForShader];
        Vector4[] paintingParams = new Vector4[maxPainterToolsForShader];
        for (int i = 0; i < maxPainterToolsForShader; i++)
        {
            
            if (i >= m_painterTools.Length)
            {
                matrix_iTR_arr[i] = Matrix4x4.identity;
            }
            else
            {
                outData[i] = m_painterTools[i].controllerData;
                matrix_iTR_arr[i] = m_painterTools[i].matrix_iTR;
                positionSS[i] = m_painterTools[i].positionSS;
                positionWS[i] = m_painterTools[i].positionWS;
                
                paintingParams[i] = m_painterTools[i].paintingParams;
            }
           
        }
        m_renderMan.setControllerData(outData, matrix_iTR_arr, positionWS, positionSS, paintingParams);
        #endregion;

        
    }


    void adjustOffset()
    {
        
        float y = m_posOffsetRelative.y;
        float z = m_posOffsetRelative.z;
        float zBoard = m_posOffset.z;
        float rX = m_rotOffset.x;
        float incrBoard = 0.05f;
        float incrPos = 0.005f;
        float incrRot = 1f;

        /*
            
            Arrow keys Up and Down change spray position forward-back relative to each controller.
            Arrow keys left and right change the spray position up-down relative to each controller.
            Home key and End key rotate the spray direction around each controller's position, around each controller's left-right axis.
            PageUp and PageDown move the wall closer or further to the controllers. 
            Delete key resets all the values.
            All keypresses now change values smoothly while the key is pressed down.
            Values are saved to disk after each key press.

        */

        if (Input.GetKeyUp(KeyCode.Delete))
        {
            y = m_posOffsetRelativeReset.y;
            z = m_posOffsetRelativeReset.z;
            zBoard = m_posOffsetReset.z;
            rX = m_rotOffsetReset.x;
        }
        else
        {
            if (Input.GetKey(KeyCode.UpArrow) && !Input.GetKey(KeyCode.DownArrow))
            {
                z += incrPos * buttonPressTickSpeed * Time.deltaTime;
            }
            else if (Input.GetKey(KeyCode.DownArrow) && !Input.GetKey(KeyCode.UpArrow))
            {
                z -= incrPos * buttonPressTickSpeed * Time.deltaTime;
            }

            if (Input.GetKey(KeyCode.RightArrow) && !Input.GetKey(KeyCode.LeftArrow))
            {
                y += incrPos * buttonPressTickSpeed * Time.deltaTime;
            }
            else if (Input.GetKey(KeyCode.LeftArrow) && !Input.GetKey(KeyCode.RightArrow))
            {
                y -= incrPos * buttonPressTickSpeed * Time.deltaTime;
            }

            if (Input.GetKey(KeyCode.PageUp) && !Input.GetKey(KeyCode.PageDown))
            {
                zBoard += incrBoard * buttonPressTickSpeed * Time.deltaTime;
            }
            else if (Input.GetKey(KeyCode.PageDown) && !Input.GetKey(KeyCode.PageUp))
            {
                zBoard -= incrBoard * buttonPressTickSpeed * Time.deltaTime;
            }

            if (Input.GetKey(KeyCode.Home) && !Input.GetKey(KeyCode.End))
            {
                rX += incrRot * buttonPressTickSpeed * Time.deltaTime;
            }
            else if (Input.GetKey(KeyCode.End) && !Input.GetKey(KeyCode.Home))
            {
                rX -= incrRot * buttonPressTickSpeed * Time.deltaTime;
            }

        }

        if (z != m_posOffsetRelative.z)
        {
            m_posOffsetRelative.z = z;
            PlayerPrefs.SetFloat(_posOffsetRelativeZ, z);
        }

        if (y != m_posOffsetRelative.y)
        {
            m_posOffsetRelative.y = y;
            PlayerPrefs.SetFloat(_posOffsetRelativeY, y);
        }

        if (zBoard != m_posOffset.z)
        {
            m_posOffset.z = zBoard;
            PlayerPrefs.SetFloat(_posOffsetZ, zBoard);
        }

        if (rX != m_rotOffset.y)
        {
            m_rotOffset.x = rX;
            PlayerPrefs.SetFloat(_rotOffsetX, rX);
        }
    }

}
