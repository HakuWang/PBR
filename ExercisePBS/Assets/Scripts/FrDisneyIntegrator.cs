using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

class FrDisneyIntegrator : IMaterialColorCalculator
{
    public SamplerSpace samplerSpace;
    public Cubemap cubeMap;
    public float roughness;
    public bool importance;
    public int negNdotLNum ;
    public SampleMethod sampleMethod;


    public Color GetColorAt(Vector3 viewDir,bool debug, float fresnel)
    {
        negNdotLNum = 0;
       Vector3 normal = new Vector3(0f, 0f, 1f);
        // Vector3 normal = new Vector3(0f, 1f, 0f);

        Color result = Color.black;

        int i = 0;
        foreach (var sample in samplerSpace.samplerList)
        {
            i++;
            
            Color sampleVal =  GetColorForOneSample(sample, normal, viewDir, debug, fresnel);
            result += sampleVal;
            if (debug)
                Debug.Log("sample index = " + i + " : sample value = " + sampleVal);
        }

        if (debug)
            Debug.LogError("Disney diffuse Integrator value = " + result / samplerSpace.samplerList.Length + " ,int negNdotLNum = " + negNdotLNum);

        return result  / samplerSpace.samplerList.Length;
    }

    public Color GetColorAt(float theta, float phi, bool debug)
    {
        throw new NotImplementedException();
    }

    public Color GetColorAt(float theta, float phi, Vector3 camPos, bool debug)
    {
        throw new NotImplementedException();
    }

    public Color GetColorAt(float thetaInRad, float phiInRad, Vector3 viewDir, bool v, Transform transform)
    {
        throw new NotImplementedException();
    }

    public Color GetColorAt(Vector3 viewDir, bool v)
    {
        throw new NotImplementedException();
    }

    public float SmithG1ForGGX(float ndots,float alpha)
    {
        return 2.0f * ndots / (ndots * (2.0f - alpha) + alpha);
    }

    private Color GetColorForOneSample(Sampler sample, Vector3 normal, Vector3 viewDir, bool debug , float fresnel)
    {

        Vector3 L = sample.Dir;

        Vector3 upVector = Mathf.Abs(normal.z) < 0.999f ? new Vector3(0.0f, 0.0f, 1.0f) : new Vector3(0.0f, 1.0f, 0.0f);
        Vector3 tangentX = Vector3.Cross(upVector, normal).normalized;
        Vector3 tangentY = Vector3.Cross(normal, tangentX);

        L = tangentX * L.x + tangentY * L.y + normal * L.z;

        Vector3 H = Vector3.Normalize(L + viewDir);

        float nDotL = Mathf.Max(Vector3.Dot(normal, L), 1e-8f);
        float vdoth = Mathf.Max(Mathf.Abs(Vector3.Dot(viewDir, H)), 1e-8f);
        float ndotv = Mathf.Max(Mathf.Abs(Vector3.Dot(viewDir, normal)), 1e-8f);
        float ndoth = Mathf.Max(Mathf.Abs(Vector3.Dot(normal, H)), 1e-8f);



        // float Fss90 = Mathf.Sqrt(roughness) * hDotL * hDotL;
        // float FD90 = 0.5f + 2f * Fss90;

        //frosbite Disney Diffuse
        float energyBias = Mathf.Lerp(0f, 0.5f, roughness);
        float energyFactor = Mathf.Lerp(1.0f, 1.0f / 1.51f, roughness);
        float FD90 = energyBias + 2.0f * vdoth * vdoth * roughness;
        float lightScatter = (1f + (FD90 - 1f) * Mathf.Pow(1f - nDotL, 5f));
        float viewScatter = (1f + (FD90 - 1f) * Mathf.Pow(1f - ndotv, 5f));
        float fd = lightScatter * viewScatter * energyFactor;
        float diffuseBrdfMulPi = /*nDotL * ndotv **/ fd ;

        //   float diffuseBrdf = 1.0f/Mathf.PI; //lambert

        Color sampleValue =  Color.black;
       
        sampleValue.b = diffuseBrdfMulPi;

        return sampleValue;
        

    }
}

