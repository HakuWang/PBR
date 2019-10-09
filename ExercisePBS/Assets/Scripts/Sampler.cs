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


}

public struct SamplerSpace
{
    public Sampler[] samplerList;

}

public interface ISamplerSpaceCreator
{
    SamplerSpace CreateSampler(int samplerCount);
}


public class UniformSamplerSpaceCreator : ISamplerSpaceCreator
{
    public SamplerSpace CreateSampler(int samplerCount)
    {
        SamplerSpace space = new SamplerSpace();
        space.samplerList = new Sampler[samplerCount];
        for (int i = 0; i < samplerCount; i ++)
        {
            space.samplerList[i] = CreateOneRandomSample(i,samplerCount);
        }
        return space;
    }

    private Sampler CreateOneRandomSample(int i, int samplerCount)
    {
        Sampler sample = new Sampler();

        //built-in random function, not used
        //sample.theta = Random.Range(0f, 1.0f) * Mathf.PI;
        //sample.phi = Random.Range(0f, 1.0f) * Mathf.PI * 2.0f;

        //Hammersley2d psude random
        Vector2 uv = Utils.Hammersley2d((uint)i, (uint)samplerCount);
        float u = uv.x;
        float v = uv.y;

        float cosTheta = Mathf.Sqrt(1 - u);
        sample.theta = Mathf.Acos(cosTheta);
        sample.phi = 2 * Mathf.PI * v;

        sample.Calculate();
        return sample;
    }

}




