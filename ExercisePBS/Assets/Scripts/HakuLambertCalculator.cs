using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

public class HakuLambertCalculator : IMaterialColorCalculator
{
    public SamplerSpace samplerSpace;
    public Cubemap cubeMap;

    public Color GetColorAt(float theta, float phi, Vector3 camPos, bool debug)
    {
        Vector3 normal = Utils.ThetaPhiToDir(theta, phi);
        Color result = Color.black;
        int sampleIndex = 0;
        foreach (var sample in samplerSpace.samplerList)
        {
            sampleIndex++;
            Debug.LogError("sampleIndex = " + sampleIndex);
            result += GetColorForOneSample(sample, normal,debug);
        }


        if (debug)
            Debug.LogError("HakuLambertMaterialCalculator value = " + (result / (float)samplerSpace.samplerList.Length));

        return result / (float)samplerSpace.samplerList.Length;



    }

    public Color GetColorAt(float thetaInRad, float phiInRad, Vector3 viewDir, bool v, Transform transform)
    {
        throw new NotImplementedException();
    }

    private Color GetColorForOneSample(Sampler sample, Vector3 normal,bool debug)
    {
        float brdf = 1.0f / Mathf.PI;

        //random L  in world
        //float space0 = 4.0f * Mathf.PI ;
        //Vector3 L0 = sample.Dir;
        //Color light0 = Utils.SampleCubeMap(L0, cubeMap);
        //float nDotL0 = Vector3.Dot(normal, L0);

        //float dOmiga0 = Mathf.Sin(sample.theta);
        //Color result0;
        //result0 = brdf * light0 * nDotL0 * dOmiga0 * space0 ;
        //if (nDotL0 <= 0)
        //    result0 = Color.black;

        //random L in normal hemisphere
        Vector3 upVector = Mathf.Abs(normal.z) < 0.999f ? new Vector3(0.0f, 0.0f, 1.0f) : new Vector3(1.0f, 0.0f, 0.0f);
        Vector3 tangentX = Vector3.Normalize(Vector3.Cross(upVector, normal));
        Vector3 tangentY = Vector3.Cross(normal, tangentX);

        Vector3 L = new Vector3(
            Mathf.Sin(sample.theta) * Mathf.Cos(sample.phi),
            Mathf.Sin(sample.theta) * Mathf.Sin(sample.phi),
            Mathf.Cos(sample.theta));
        L = tangentX * L.x + tangentY * L.y + normal * L.z;

        float nDotL = Vector3.Dot(normal, L);
        Color light = Utils.SampleCubeMap(L, cubeMap);
        float dOmiga = Mathf.Sqrt(1 - nDotL * nDotL); //  Mathf.Sin(sample.theta);
        Color result;
        float space = 4.0f * Mathf.PI;
        result = brdf * light * nDotL * dOmiga * space;
        if (nDotL <= 0)
            result = Color.black;

        return result;

    }
}

