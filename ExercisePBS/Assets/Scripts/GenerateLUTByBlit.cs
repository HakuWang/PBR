using System.Collections;
using System.Collections.Generic;
using UnityEngine;



[ExecuteInEditMode]
public class GenerateLUTByBlit : MonoBehaviour
{

    public Texture2D environmentMap;
    public int sampleCount;
    public Shader lutGenShader;
    public RenderTexture lutRT;
    public Texture2D lutTex;

    public int lutSize;

    private Material mLutGenMat;
    private bool run;

    private void Start()
    {
        mLutGenMat = new Material(lutGenShader);
        lutRT = new RenderTexture(lutSize, lutSize, 0, RenderTextureFormat.RGHalf);
        run = false;
    }


    static public Texture2D GetRTPixels(RenderTexture rt)
    {

        // Set the supplied RenderTexture as the active one
        RenderTexture.active = rt;
        Debug.LogError(RenderTexture.active.name);
        // Create a new Texture2D and read the RenderTexture image into it
        Texture2D tex = new Texture2D(rt.width, rt.height,TextureFormat.RGBAHalf,false);
        tex.ReadPixels(new Rect(0, 0, tex.width, tex.height), 0, 0);

        // Restorie previously active render texture
        RenderTexture.active = null;
        Debug.Log(tex.GetPixel(1,1));

        return tex;


    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (mLutGenMat != null && !run)
        {
            mLutGenMat.SetTexture("_Enviroment", environmentMap);
            mLutGenMat.SetInt("_MaxSampleCountMonteCarlo", sampleCount);
            Debug.Log(lutTex.GetPixel(1, 1));

            Graphics.Blit(src, lutRT, mLutGenMat);
            lutTex =  GetRTPixels(lutRT);
            lutTex.Apply();
            Debug.Log(lutTex.GetPixel(1, 1));

            Graphics.Blit(lutRT, dest);
          //  run = true;
        }
        else
        Graphics.Blit(src, dest);
    }
}
