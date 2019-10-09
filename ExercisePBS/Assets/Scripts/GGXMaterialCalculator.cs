using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

class GGXMaterialCalculator : IMaterialColorCalculator
{
    public SamplerSpace samplerSpace;
    public Cubemap cubeMap;
    public float roughness;

    public Color GetColorAt(float theta, float phi,Vector3 viewDir, bool debug)
    {
        if (debug)
            Debug.LogError("theta = " + theta + ",  phi = "+ phi);

        Vector3 normal = Utils.ThetaPhiToDir(theta, phi);
        Color result = Color.black;
        int i = 0;
        foreach (var sample in samplerSpace.samplerList)
        {
            i++;
            Color sampleCol =  GetColorForOneSample(sample, normal, viewDir, debug);
            result += sampleCol;
            if (debug)
                Debug.Log("sample index = " + i + " : sample color = " + sampleCol);
        }

        if (debug)
            Debug.LogError("GGXMaterialCalculator value = " + (result / samplerSpace.samplerList.Length));

        return result / samplerSpace.samplerList.Length;
    }

    public Color GetColorAt(float theta, float phi, bool debug)
    {
        throw new NotImplementedException();
    }

    private Color GetColorForOneSample(Sampler sample, Vector3 normal, Vector3 viewDir, bool debug)
    {
        float dOmiga = Mathf.Sin(sample.theta);
        float space = 4.0f * Mathf.PI  ;

        float nDotL = Vector3.Dot(normal, sample.Dir);
        if (nDotL <= 0)
            return Color.black;

        Vector3 L = sample.Dir;
        Vector3 H = (L + viewDir).normalized;

        float vdoth = Vector3.Dot(viewDir, H);
        float ndotv = Vector3.Dot(viewDir, normal);
        float ndoth = Vector3.Dot(normal, H);

        //Fresnel coefficient
        float f0 = 0.5f;
        float specFresnel = f0 + (1.0f - f0) * Mathf.Pow(1.0f - Vector3.Dot(H, L), 5.0f);

        //D term
        float alpha_tr = roughness * roughness; //_Roughness =  1 表示越光滑
        float Dm = alpha_tr * alpha_tr / (Mathf.PI * Mathf.Pow(ndoth * ndoth * (alpha_tr * alpha_tr - 1.0f) + 1.0f, 2.0f));

        //G term
        float Gmv = 2.0f * ndoth * ndotv / vdoth;
        float Gml = 2.0f * ndoth * nDotL / vdoth;
        float Gm = Mathf.Min(1.0f, Mathf.Min(Gmv, Gml));

        float brdfGGXSpecular = specFresnel * Dm * Gm / (4.0f * nDotL * ndotv);
          
        Color light = Utils.SampleCubeMap(L, cubeMap);

        if (debug)
            Debug.Log("ndoth * ndoth = " + ndoth * ndoth + ", (alpha_tr * alpha_tr - 1) = " + (alpha_tr * alpha_tr - 1) + ", 分子 = " + alpha_tr * alpha_tr + ", 分母 = " + (Mathf.PI * Mathf.Pow((ndoth * ndoth * (alpha_tr * alpha_tr - 1) + 1), 2)) + ", Dm = " + Dm);
        
        return  light * nDotL * space * dOmiga * brdfGGXSpecular;
    }
}

