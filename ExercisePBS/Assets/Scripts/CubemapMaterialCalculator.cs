using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;


public class CubemapMaterialCalculator : IMaterialColorCalculator
{
    public Cubemap cubeMap;

    public Color GetColorAt(float theta, float phi, Vector3 camPos, bool debug)
    {
        Vector3 dir = new Vector3(
             Mathf.Sin(theta) * Mathf.Cos(phi),
             Mathf.Cos(theta),
             Mathf.Sin(theta) * Mathf.Sin(phi)
             );
        return Utils.SampleCubeMap(dir, cubeMap);
    }

    public Color GetColorAt(float thetaInRad, float phiInRad, Vector3 viewDir, bool v, Transform transform)
    {
        throw new NotImplementedException();
    }
}

