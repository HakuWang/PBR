using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

public class LambertMaterialCalculator : IMaterialColorCalculator
{
    public SamplerSpace samplerSpace;
    public Cubemap cubeMap;

    public Color GetColorAt(float theta, float phi, Vector3 camPos, bool debug)
    {
        if (debug)
            Debug.LogError("Debug Start");

        Vector3 normal = Utils.ThetaPhiToDir(theta, phi);
        Color result = Color.black;
        foreach (var sample in samplerSpace.samplerList)
        {
            result += GetColorForOneSample(sample, normal, debug);
        }

        if (debug)
            Debug.LogError("LambertMaterialCalculator value = " + (result / (float)samplerSpace.samplerList.Length));

        return result / (float)samplerSpace.samplerList.Length;
    }

    public Color GetColorAt(float thetaInRad, float phiInRad, Vector3 viewDir, bool v, Transform transform)
    {
        throw new NotImplementedException();
    }

    public Color GetColorAt(Vector3 viewDir, bool v)
    {
        throw new NotImplementedException();
    }

    private Color GetColorForOneSample(Sampler sample, Vector3 normal,bool debug)
    {
        float dOmiga = Mathf.Sin(sample.theta);
        float space = 4.0f * Mathf.PI ;
        float brdf = 1.0f / Mathf.PI;

        float nDotL = Vector3.Dot(normal, sample.Dir);
        if (nDotL <= 0)
            return Color.black;

        Color light = Utils.SampleCubeMap(sample.Dir, cubeMap);

        return light * nDotL * space * dOmiga * brdf;
    }


}

