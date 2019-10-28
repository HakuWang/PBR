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
            //if (debug)
            //    Debug.Log("sample index = " + i + " : sample value = " + sampleVal);
        }

        //if (debug)
        //    Debug.LogError("GGXIntegrator value = " + result / samplerSpace.samplerList.Length + " ,int negNdotLNum = " + negNdotLNum);


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

     
        float vdoth = Mathf.Max(Mathf.Abs(Vector3.Dot(viewDir, H)), 1e-8f);
        float ndotv = Mathf.Max(Mathf.Abs(Vector3.Dot(viewDir, normal)), 1e-8f);
        float ndoth = Mathf.Max(Mathf.Abs(Vector3.Dot(normal, H)), 1e-8f);
        float nDotL = Mathf.Max(Vector3.Dot(normal, L), 1e-8f);



        Color sampleValue =  Color.black;
        float alpha_tr = roughness * roughness;

        float Gv = SmithG1ForGGX(/*vdoth*/ndotv, alpha_tr); 
        float Gl = SmithG1ForGGX(/*hDotL*/nDotL, alpha_tr);

        float G = Gv * Gl;
        float G_Vis = G * vdoth / (ndoth * ndotv);
        // float Fc = Mathf.Pow(1f - vdoth, 5f);

        float index = (-5.55473F * vdoth - 6.98316F) * vdoth;
        float Fc =Mathf.Pow(2f, index); 

        sampleValue.r = (1 - Fc) * G_Vis;
        sampleValue.g = Fc * G_Vis;
   
        return sampleValue;
        

    }
}

