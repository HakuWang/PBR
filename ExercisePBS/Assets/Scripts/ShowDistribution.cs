using System.Collections;
using System.Collections.Generic;
using UnityEngine;
public enum IndirectLightType
{
    LAMBERT_DIFFUSE,
    GGX_SPECULAR
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
    public GameObject parent;
    public Transform poolTrans;
    public Cubemap testCubemap;

    public IndirectLightType indirectLightType;

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

        mSamplerCreator = new UniformSamplerSpaceCreator();

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

        var space = mSamplerCreator.CreateSampler(sampleTimes);

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
 
        }

        displayer.CreateScene(calculator, parent.transform, mMainCameraObj.transform.position);
    }

    #endregion
}
