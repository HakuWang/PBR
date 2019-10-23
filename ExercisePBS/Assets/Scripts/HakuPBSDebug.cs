using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HakuPBSDebug : MonoBehaviour
{
    // Start is called before the first frame update
    public bool showSD;
    public GameObject sdIBLSphere;
    public GameObject pbsMatSphere;

    private Material sdIBLMat;
    private Material pbsMat;
    public Material skyboxMat;

    public int sdSampleCount, hakuSampleCount;

    [Range(0.02f,1f)]
    public float roughness;

    [Range(0f, 1f)]
    public float metallic;
    void Start()
    {
        sdIBLMat = sdIBLSphere.GetComponent<Renderer>().material;
        pbsMat = pbsMatSphere.GetComponent<Renderer>().material;


        sdIBLMat.SetFloat("_Glossiness", 1.0f - roughness);
        pbsMat.SetFloat("_Roughness", roughness);
    }

    // Update is called once per frame
    void Update()
    {
        if(showSD)
        {
            pbsMatSphere.SetActive( false);
            sdIBLSphere.SetActive( true);
        }
        else
        {
            pbsMatSphere.SetActive( true);
            sdIBLSphere.SetActive( false);
        }

        sdIBLMat.SetFloat("_Glossiness", 1.0f - roughness);
        pbsMat.SetFloat("_Roughness", roughness);

        sdIBLMat.SetFloat("_Metallic", metallic);
        pbsMat.SetFloat("_Metallic", metallic);

        sdIBLMat.SetInt("_nbSamples", sdSampleCount);
        pbsMat.SetInt("_MaxSampleCountMonteCarlo", hakuSampleCount);
        pbsMat.SetTexture("_Enviroment", skyboxMat.mainTexture);

    }
}
