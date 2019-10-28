using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

/*------------Generate LUT -----------------*/
//press C to run 

class SplitSumIBLGenerator : MonoBehaviour
{
    #region

    public int texWidth, texHeight;  //1/width is the ndotv interval, 1/height is the interval of roughness
    public int preIntegrateSampleCount;
    public Color specularColor;
    public GameObject displayer;

    public Texture2D mLUT;

    private GGXIntegrator mSpecIntegrator;
    private FrDisneyIntegrator mDiffIntegrator;
    
    private ImportanceSamplerSpaceCreator mSpecSamplerCreator;
    private UniformSamplerSpaceCreator mDiffSamplerCreator;

    private Material mDisplayLUTMat;
    private Color[] mPixelArray;

    #endregion


    void Start()
    {
        Init();
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.C))
            ApproximateSpecularIBL(mSpecIntegrator, mDiffIntegrator, specularColor);
        return;

    }

    public void Init()
    {
        mLUT = new Texture2D(texWidth, texHeight,TextureFormat.RGBAHalf,false);

        mSpecIntegrator = new GGXIntegrator();
        mDiffIntegrator = new FrDisneyIntegrator();

        mSpecSamplerCreator = new ImportanceSamplerSpaceCreator();
        mDiffSamplerCreator = new UniformSamplerSpaceCreator();

        mDisplayLUTMat = displayer.GetComponent<Renderer>().material;
        mPixelArray = new Color[texWidth * texHeight];
    }


    public void ApproximateSpecularIBL(GGXIntegrator mSpecIntegrator, FrDisneyIntegrator mDiffIntegrator , Color SpecularColor)
    {            
        for(int i=0; i < texHeight; i++)
            for(int j=0; j < texWidth; j++)
            {
                float roughness = 1.0f / (texHeight - 1) * i;
           
                float ndotv = 1.0f / (texWidth - 1) * j;
                //  ndotv += 0.5f * 1f / texWidth;

                ndotv = Mathf.Clamp(ndotv, 0.5f * 1f / texWidth,1.0f);
                SamplerSpace specSpace = mSpecSamplerCreator.CreateSampler(preIntegrateSampleCount, roughness);
                mSpecIntegrator.samplerSpace = specSpace;
                mSpecIntegrator.roughness = roughness;

                SamplerSpace diffSpace = mDiffSamplerCreator.CreateSampler(preIntegrateSampleCount, SampleMethod.HEMIL);
                mDiffIntegrator.samplerSpace = diffSpace;
                mDiffIntegrator.roughness = roughness;

                Vector3 viewDir = new Vector3(Mathf.Sqrt(1.0f - ndotv * ndotv), 0, ndotv);

                bool debug = (i < 20) && (j < 20);
                Color specIntegratedCol = mSpecIntegrator.GetColorAt( viewDir, debug);

               Color diffIntegratedCol = mDiffIntegrator.GetColorAt(viewDir, false , specIntegratedCol.b);

                Color integratedCol = new Color(specIntegratedCol.r, specIntegratedCol.g, diffIntegratedCol.b );

                mPixelArray[i * texWidth + j] = integratedCol;
                
            }
        mLUT.SetPixels(mPixelArray, 0);//mPixelArray is from bottom to top , left to right
        mLUT.Apply(false);
        mDisplayLUTMat.SetTexture("_LUT", mLUT);

        byte[] _bytes = mLUT.EncodeToPNG();
        System.IO.File.WriteAllBytes("D:/Haku/HakuGitRepository/PBS_Exercise/ExercisePBS/Assets/Textures/SDHakuLUT_Diff_RGBAHalf1.png", _bytes);
        Debug.Log(_bytes.Length / 1024 + "LUT was saved as: HakuLUT" );


    }





}

