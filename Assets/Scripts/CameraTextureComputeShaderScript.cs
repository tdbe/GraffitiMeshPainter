// note, this script must be attached to the main camera

using System;
using UnityEngine;
using System.Collections;
using Object = UnityEngine.Object;
using Random = UnityEngine.Random;

public class CameraTextureComputeShaderScript : MonoBehaviour
{

    public ComputeShader TextureComputeShader0;  // this must be public so it can be set in the inspector!!!!!!!!!!!!!
    protected int TextureCSMainKernel;

    private RenderTexture readWriteTexture;  // a random write texture  for TextureCSMainKernel()
    private Texture2D texture2D;  // a readable texture

    int texWidth = 1920;
    int texHeight = 1080;

    [SerializeField]
    GameObject screenQuad;
    Material screenQuadMat;

    private const string _MainTex = "_MainTex";

    // Use this for initialization
    void Start()
    {
        if (TextureComputeShader0 != null)
        {
            TextureCSMainKernel = TextureComputeShader0.FindKernel("TextureCSMainKernel");

            texture2D = new Texture2D(texWidth, texHeight, TextureFormat.ARGB32, false, true);
            texture2D.name = "texture2D";
            TextureComputeShader0.SetTexture(TextureCSMainKernel, "inputTex1", texture2D);

            Color[] pix = new Color[texWidth * texHeight]; // SetPixels takes Color[], rgba
            Random.seed = 12345;
            for (int p = 0; p < (texWidth * texHeight); ++p)
                pix[p] = new Color(Random.value, Random.value, Random.value, 1);  // rgba
            texture2D.SetPixels(pix);
            texture2D.Apply();

            readWriteTexture = new RenderTexture(texWidth, texHeight, 0, RenderTextureFormat.ARGB32,
                            RenderTextureReadWrite.Linear);
            readWriteTexture.name = "readWriteTexture";
            readWriteTexture.enableRandomWrite = true;
            readWriteTexture.Create();  // otherwise not created until first time it is set to active
            TextureComputeShader0.SetTexture(TextureCSMainKernel, "outputTex1", readWriteTexture);
            RenderTexture.active = readWriteTexture;
            Graphics.Blit(texture2D, readWriteTexture);
            RenderTexture.active = null;
        }

        screenQuadMat = screenQuad.GetComponent<Renderer>().material;
        screenQuadMat.SetTexture(_MainTex, readWriteTexture);

    }


    void Update()
    {

        if (TextureComputeShader0 != null)
            TextureComputeShader0.Dispatch(TextureCSMainKernel, texWidth / 32, texHeight / 32, 1);
    }

    void OnPostRender()
    {   // we are still in the render frame at this point
        // if you want to copy texture to another texture
        /*
        if (readWriteTexture != null)
        {
            RenderTexture.active = readWriteTexture;  // copy RenderTexture to Texture2D
            texture2D.ReadPixels(new Rect(0, 0, readWriteTexture.width, readWriteTexture.height), 0, 0);
            texture2D.Apply();
            RenderTexture.active = null;
        }
        */
    }
}