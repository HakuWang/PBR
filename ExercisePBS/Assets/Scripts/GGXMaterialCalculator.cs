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
    public bool importance;
    public int negNdotLNum ;
    public SampleMethod sampleMethod;



    public Color GetColorAt(float theta, float phi,Vector3 viewDir, bool debug,Transform vertInstance)
    {
        bool debugShowSampleDir = false;//need to be true if you want to see the sample dir for indexed vert
        negNdotLNum = 0;
        Vector3 normal = Utils.ThetaPhiToDir(theta, phi);
        Color result = Color.black;

        if (debug)
        {
            Debug.LogError("theta = " + theta + ",  phi = " + phi);
            if(debugShowSampleDir)
            {
            samplerSpace.InitShowSamplerSpace(samplerSpace.showSamplerPrefeb, vertInstance);
            samplerSpace.ShowSamplerSpace(samplerSpace.samplerList.Length, samplerSpace, vertInstance);
            }
        }

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
            Debug.LogError("GGXMaterialCalculator value = " + result / samplerSpace.samplerList.Length + " ,int negNdotLNum = " + negNdotLNum);


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

    public Color GetColorAt(Vector3 viewDir, bool v)
    {
        throw new NotImplementedException();
    }

    private Color GetColorForOneSample(Sampler sample, Vector3 normal, Vector3 viewDir, bool debug)
    {
        if(importance)
        {
            Vector3 H = sample.Dir;

            Vector3 upVector = Mathf.Abs(normal.y) < 0.999f ? new Vector3(0.0f, 0.0f, 1.0f) : new Vector3(0.0f, 1.0f, 0.0f);
            Vector3 tangentX = Vector3.Cross(upVector, normal).normalized;
            Vector3 tangentY = Vector3.Cross(normal, tangentX);

            H = tangentX * H.x + tangentY * H.y + normal * H.z;

            Vector3 L = Vector3.Reflect (-viewDir, H);// 2 * dot(H, viewDir)* H - viewDir;
            float nDotL = Vector3.Dot(normal, L);
            if (nDotL <= 0)
                return Color.black;
            
            float vdoth = Vector3.Dot(viewDir, H);
            float ndotv = Vector3.Dot(viewDir, normal);
            float ndoth = Vector3.Dot(normal, H);
            float hDotL = Vector3.Dot(H, L);

            // ndotv = Mathf.Max(0.000000001f, ndotv);
            //  ndotv = Mathf.Clamp01( ndotv);
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
                Debug.Log("ndotv = "+ ndotv +" 分母 = " + ndotv * ndoth + ", 分子 = " + specFresnel * Gm * vdoth * light + ", Dm = " + Dm);
            // FTerm* GTerm *vdoth * sampleL / (ndotv * ndoth)
            // Color sampleValue = specFresnel * Gm * vdoth * light / (ndotv * ndoth);//GGX 逆采样变换推导 pdf

            Color sampleValue = specFresnel * Gm * light / ndotv;//Gpu pro6

            //sampleValue.r = Mathf.Clamp01(sampleValue.r);
            //sampleValue.g= Mathf.Clamp01(sampleValue.g);
            //sampleValue.b = Mathf.Clamp01(sampleValue.b);

            return sampleValue;
        }
        else //uniform 
        {
           
            Vector3 H, L;

            float dOmiga , space;

            if (sampleMethod == SampleMethod.HEMIH)
            {
                H = sample.Dir;
                Vector3 upVector = Mathf.Abs(normal.z) < 0.999f ? new Vector3(0.0f, 0.0f, 1.0f) : new Vector3(0.0f, 1.0f, 0.0f);
                Vector3 tangentX = Vector3.Cross(upVector, normal).normalized;
                Vector3 tangentY = Vector3.Cross(normal, tangentX);
                H = tangentX * H.x + tangentY * H.y + normal * H.z;
                L = Vector3.Reflect(-viewDir, H);
                dOmiga = 1.0f;
                space = 2.0f * Mathf.PI;
            }

            else if (sampleMethod == SampleMethod.GLOBALL)
            {
                L = sample.Dir;
                H = (L + viewDir).normalized;
                dOmiga = 1.0f;
                space = 4.0f * Mathf.PI;
            }

            //half L, which need more research to know why the border area become too dark
            else if (sampleMethod == SampleMethod.HEMIL) 
            {
                L = sample.Dir;
                Vector3 upVector = Mathf.Abs(normal.z) < 0.999f ? new Vector3(0.0f, 0.0f, 1.0f) : new Vector3(0.0f, 1.0f, 0.0f);
                Vector3 tangentX = Vector3.Cross(upVector, normal).normalized;
                Vector3 tangentY = Vector3.Cross(normal, tangentX);
                L = tangentX * L.x + tangentY * L.y + normal * L.z;
                H = (L + viewDir).normalized;
                dOmiga = 1.0f;
                space = 2.0f * Mathf.PI;
            }

            // only for remove errors
            else
            {
                L = normal;
                H = normal;

                dOmiga = 1.0f;
                space = 1.0f;
            }
            
            float nDotL = Vector3.Dot(normal, L);
            if (nDotL <= 0)
            {
                negNdotLNum++;
                //if (debug)
                //    Debug.LogError("ndotL = " + nDotL + " , negNdotLNum = " + negNdotLNum);
                return Color.black;

            }

            float vdoth = Vector3.Dot(viewDir, H);
            float ndotv = Vector3.Dot(viewDir, normal);
            float ndoth = Vector3.Dot(normal, H);
            float hDotL = Vector3.Dot(H, L);
            
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
                {
                    //  Debug.Log("ndoth * ndoth = " + ndoth * ndoth + ", (alpha_tr * alpha_tr - 1) = " + (alpha_tr * alpha_tr - 1) + ", 分子 = " + alpha_tr * alpha_tr + ", 分母 = " + (Mathf.PI * Mathf.Pow((ndoth * ndoth * (alpha_tr * alpha_tr - 1) + 1), 2)) + ", Dm = " + Dm);
                    Debug.Log("light = " + light +" , ndotL = "+ nDotL+ ", brdfGGXSpecular = " + brdfGGXSpecular + " , dOmiga = "+dOmiga + " , space = "+ space);

                }

            return  light * 1.0f * nDotL * space * dOmiga * brdfGGXSpecular;
        }
    }
}

