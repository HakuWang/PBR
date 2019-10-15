using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

public struct Sampler
{
    public float theta;
    public float phi;

    public Vector3 Dir;
    

    public void Calculate()
    {
        Dir = Utils.ThetaPhiToDir(theta, phi);
    }

    public void CalculateRandomH()
    {
        Dir = Utils.ThetaPhiToDirZUp(theta, phi);
    }




}

public struct SamplerSpace
{
    public Sampler[] samplerList;
    private InstancePool mSamplerInstancePool;
    private List<MeshRenderer> mSamplerInstanceList;

    public bool uniformHemiHorGlobalL;
    public MeshRenderer showSamplerPrefeb;

    public void InitShowSamplerSpace(MeshRenderer prefab, Transform poolTrans)
    {
        mSamplerInstancePool = new InstancePool(prefab, poolTrans);
        mSamplerInstanceList = new List<MeshRenderer>();
    }

    public void ShowSamplerSpace(int samplerCount, SamplerSpace space, Transform parent)
    {
        foreach (var ins in mSamplerInstanceList)
            mSamplerInstancePool.Release(ins);
        mSamplerInstanceList.Clear();



        int index = 0;

        for (int i = 0; i < samplerCount; i++)
        {
            index++;

            // set position
            var instance = mSamplerInstancePool.Alloc(parent);// GameObject.Instantiate(prefab, parent);
            Vector3 pos = space.samplerList[i].Dir;

            instance.transform.position = parent.localPosition + pos;
            mSamplerInstanceList.Add(instance);
        }


    }

}

public interface ISamplerSpaceCreator
{
    SamplerSpace CreateSampler(int samplerCount);
    SamplerSpace CreateSampler(int samplerCount, float roughness);
    SamplerSpace CreateSampler(int samplerCount, SampleMethod samplemethod);

}


public class UniformSamplerSpaceCreator : ISamplerSpaceCreator
{
   
    public SamplerSpace CreateSampler(int samplerCount, SampleMethod samplemethod)
    {
        SamplerSpace space = new SamplerSpace();
        space.samplerList = new Sampler[samplerCount];
        for (int i = 0; i < samplerCount; i ++)
        {
            space.samplerList[i] = CreateOneRandomSample(i,samplerCount, samplemethod);
        }

        return space;
    }

    public SamplerSpace CreateSampler(int samplerCount, float roughness)
    {
        throw new System.NotImplementedException();
    }

    public SamplerSpace CreateSampler(int samplerCount)
    {
        throw new System.NotImplementedException();
    }

    private Sampler CreateOneRandomSample(int i, int samplerCount, SampleMethod samplemethod)
    {
        Sampler sample = new Sampler();

        //Hammersley2d psude random
        Vector2 uv = Utils.Hammersley2d((uint)i, (uint)samplerCount);
        float u = uv.x;
        float v = uv.y;

        float cosTheta = Mathf.Sqrt(1 - u);
        sample.phi = 2 * Mathf.PI * v;

        if (samplemethod == SampleMethod.HEMIH)
        {
            sample.theta = Mathf.Acos(cosTheta);
            sample.CalculateRandomH();
        }

        if (samplemethod == SampleMethod.GLOBALL)
        {
            sample.theta = 2.0f * Mathf.Acos(cosTheta);
            sample.Calculate();
        }

        if (samplemethod == SampleMethod.HEMIL)
        {
            sample.theta = Mathf.Acos(cosTheta);
            sample.CalculateRandomH();
        }

        return sample;
    }





}

public class ImportanceSamplerSpaceCreator : ISamplerSpaceCreator
{
    public SamplerSpace CreateSampler(int samplerCount,float roughness)
    {
        SamplerSpace space = new SamplerSpace();
        space.samplerList = new Sampler[samplerCount];
        for (int i = 0; i < samplerCount; i++)
        {
            space.samplerList[i] = CreateOneRandomSample(i, samplerCount, roughness);
        }
        return space;
    }

    public SamplerSpace CreateSampler(int samplerCount)
    {
        throw new System.NotImplementedException();
    }

    public SamplerSpace CreateSampler(int samplerCount, SampleMethod samplemethod)
    {
        throw new System.NotImplementedException();
    }

    public void InitShowSamplerSpace(MeshRenderer prefab, Transform poolTrans)
    {
        throw new System.NotImplementedException();
    }

    private Sampler CreateOneRandomSample(int i, int samplerCount, float roughness)
    {
        Sampler sample = new Sampler();

        //Hammersley2d psude random
        Vector2 uv = Utils.Hammersley2d((uint)i, (uint)samplerCount);
        float u = uv.x;
        float v = uv.y;

        float cosTheta = Mathf.Sqrt((1 - u) / (1 + (Mathf.Pow(roughness,4.0f) - 1) * u));
        sample.theta = Mathf.Acos(cosTheta);
        sample.phi = 2 * Mathf.PI * v;

        sample.CalculateRandomH();
        return sample;
    }

}



