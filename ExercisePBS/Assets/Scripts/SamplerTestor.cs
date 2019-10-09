using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

public interface ISamplerTestor
{
    // return test value
    float TestSamplerSpace(SamplerSpace space);
}


public class SimpleCosTestor : ISamplerTestor
{
    public float TestSamplerSpace(SamplerSpace space)
    {
        float result = 0;
        foreach (var sample in space.samplerList)
        {
            var value = GetSampleValue(sample);
            result += value;
        }
        return result / (float)space.samplerList.Length;
    }


    private float GetSampleValue(Sampler sample)
    {
        float integrateValue = Mathf.Max(0, Mathf.Cos(sample.theta));
        float dOmiga = Mathf.Sin(sample.theta);
        float space = 2.0f * Mathf.PI * Mathf.PI / 2.0f;
        return  integrateValue * dOmiga * space;
    }
}