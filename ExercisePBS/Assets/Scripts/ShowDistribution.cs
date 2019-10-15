using System.Collections;
using System.Collections.Generic;
using UnityEngine;
public enum IndirectLightType
{
    LAMBERT_DIFFUSE,
    GGX_SPECULAR
}


public enum SampleMethod
{
    GLOBALL,
    HEMIH,
    HEMIL
}

public enum DistributionType
{
    UNIFORM,
    IMPORTANCE
}


public class ShowDistribution : MonoBehaviour {
    
    void Start() {
        InitTestMaterialDisplayer();
    }
    
    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.F))
            TestSamplerSpace();
        else if (Input.GetKeyDown(KeyCode.C))
            TestMaterialDisplayer();
        return;

    }

    #region TEST_SAMPLER_SPACE

    private void TestSamplerSpace()
    {
        ISamplerTestor testor = new SimpleCosTestor();
        ISamplerSpaceCreator creator = new UniformSamplerSpaceCreator();
        var space = creator.CreateSampler(1000);
        float value = testor.TestSamplerSpace(space);
        Debug.LogError(value);
    }
    #endregion

    #region TEST_MATERIAL_DISPLAER



    public float radius;
    public int interval;
    public MeshRenderer prefab;
    public MeshRenderer showSamplerPrefeb;

    public GameObject parent;
    public Transform poolTrans;
    private Transform debugIndexVertPoolTrans;
    public Cubemap testCubemap;

    public IndirectLightType indirectLightType;
    public SampleMethod sampleMethod;
    public DistributionType distributionType;

    public int testIndex;
    public float roughness;
    public int sampleTimes;



    private MCMaterialDisplayer displayer;
    private IMaterialColorCalculator calculator ;
    private ISamplerSpaceCreator mSamplerCreator ;

    private GameObject mMainCameraObj;
    private Mesh mMesh;
    private Camera mMainCam;

    
    private void InitTestMaterialDisplayer()
    {
        mMesh = GetComponent<MeshFilter>().mesh;
        mMainCam = Camera.main;
        mMainCameraObj = mMainCam.gameObject;

        if(indirectLightType==IndirectLightType.LAMBERT_DIFFUSE)
            calculator = new LambertMaterialCalculator();
        else
            calculator = new GGXMaterialCalculator();

        if (distributionType == DistributionType.UNIFORM)
            mSamplerCreator = new UniformSamplerSpaceCreator();
        else
            mSamplerCreator = new ImportanceSamplerSpaceCreator();

        displayer = new MCMaterialDisplayer();
        displayer.DEBUG_INDEX = testIndex;
        displayer.Init(prefab, poolTrans);


    }


    private void TestMaterialDisplayer()
    {
        displayer.sceneCenter = transform.position;
        displayer.radius = radius;
        displayer.interval = interval;
        displayer.DEBUG_INDEX = testIndex;

        //set sampler space
        SamplerSpace space;

        if (distributionType == DistributionType.UNIFORM)
            space = mSamplerCreator.CreateSampler(sampleTimes, sampleMethod);
        else
            space = mSamplerCreator.CreateSampler(sampleTimes,roughness);

        space.showSamplerPrefeb = showSamplerPrefeb;



        //set calculator
        if (indirectLightType == IndirectLightType.LAMBERT_DIFFUSE)
        {
            (calculator as LambertMaterialCalculator).samplerSpace = space;
            (calculator as LambertMaterialCalculator).cubeMap = testCubemap;
        }
        else
        {
            (calculator as GGXMaterialCalculator).samplerSpace = space;
            (calculator as GGXMaterialCalculator).cubeMap = testCubemap;
            (calculator as GGXMaterialCalculator).roughness = roughness;

            if (distributionType == DistributionType.UNIFORM)
                (calculator as GGXMaterialCalculator).importance = false;
            else
                (calculator as GGXMaterialCalculator).importance = true;

            (calculator as GGXMaterialCalculator).sampleMethod = sampleMethod;

        }

        displayer.CreateScene(calculator, parent.transform, mMainCameraObj.transform.position, debugIndexVertPoolTrans);
    }

    #endregion
}
