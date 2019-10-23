using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

class GGXIntegrator : IMaterialColorCalculator
{
    public SamplerSpace samplerSpace;
    public Cubemap cubeMap;
    public float roughness;
    public bool importance;
    public int negNdotLNum ;
    public SampleMethod sampleMethod;



    public Color GetColorAt(Vector3 viewDir,bool debug)
    {
        negNdotLNum = 0;
       Vector3 normal = new Vector3(0f, 0f, 1f);
        // Vector3 normal = new Vector3(0f, 1f, 0f);

        Color result = Color.black;

        int i = 0;
        foreach (var sample in samplerSpace.samplerList)
        {
            i++;
            
            Color sampleVal =  GetColorForOneSample(sample, normal, viewDir, debug);
            result += sampleVal;
            if (debug)
                Debug.Log("sample index = " + i + " : sample value = " + sampleVal);
        }

        if (debug)
            Debug.LogError("GGXIntegrator value = " + result / samplerSpace.samplerList.Length + " ,int negNdotLNum = " + negNdotLNum);


        return result / samplerSpace.samplerList.Length;
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

    public float SmithG1ForGGX(float ndots,float alpha)
    {
        return 2.0f * ndots / (ndots * (2.0f - alpha) + alpha);
    }

    private Color GetColorForOneSample(Sampler sample, Vector3 normal, Vector3 viewDir, bool debug)
    {

        Vector3 H = sample.Dir;

        Vector3 upVector = Mathf.Abs(normal.z) < 0.999f ? new Vector3(0.0f, 0.0f, 1.0f) : new Vector3(0.0f, 1.0f, 0.0f);
        Vector3 tangentX = Vector3.Cross(upVector, normal).normalized;
        Vector3 tangentY = Vector3.Cross(normal, tangentX);

        H = tangentX * H.x + tangentY * H.y + normal * H.z;

        Vector3 L = Vector3.Reflect (-viewDir, H);// 2 * dot(H, viewDir)* H - viewDir;
              
        float nDotL = Mathf.Clamp01(Vector3.Dot(normal, L));
        if (nDotL <= 0)
            return Color.black;

        float vdoth = Mathf.Clamp01(Vector3.Dot(viewDir, H));
        float ndotv = Mathf.Clamp01(Vector3.Dot(viewDir, normal));
        float ndoth = Mathf.Clamp01(Vector3.Dot(normal, H));
        float hDotL = Mathf.Clamp01(Vector3.Dot(H, L));


        Color sampleValue =  Color.black;
        float alpha_tr = roughness * roughness;

        float Gv = SmithG1ForGGX(/*vdoth*/ndotv, alpha_tr); 
        float Gl = SmithG1ForGGX(/*hDotL*/nDotL, alpha_tr);

        float G = Gv * Gl;
        float G_Vis = G * vdoth / (ndoth * ndotv);
        float Fc = Mathf.Pow(1f - vdoth, 5f);
        sampleValue.r = (1 - Fc) * G_Vis;
        sampleValue.g = Fc * G_Vis;
        float f0 = 1.0f;

        float specFresnel = f0 + (1.0f - f0) * Mathf.Pow(1.0f - vdoth, 5.0f);
        sampleValue.b = specFresnel;

        return sampleValue;
        

    }
}

