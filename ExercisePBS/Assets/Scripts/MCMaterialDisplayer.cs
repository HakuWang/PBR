using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;


public interface IMaterialColorCalculator
{
    /// <param name="theta">in radius</param>
    /// <param name="phi">in radius</param>
    Color GetColorAt(float theta, float phi,Vector3 camPos, bool debug);
    Color GetColorAt(float thetaInRad, float phiInRad, Vector3 viewDir, bool v, Transform transform);
    Color GetColorAt(Vector3 viewDir, bool v);
}

public class DummyMaterialColorCalculator : IMaterialColorCalculator
{
    public Color GetColorAt(float theta, float phi, bool debug)
    {
        return Color.red;
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
}



class MCMaterialDisplayer
{

    public Vector3      sceneCenter;
    public float        radius;
    private MeshRenderer prefab;
    public int          interval;

    public int DEBUG_INDEX;

    private List<MeshRenderer> mInstanceList = new List<MeshRenderer>();
    private InstancePool mInstancePool;




    public void Init(MeshRenderer prefab, Transform poolTrans)
    {
        mInstancePool = new InstancePool(prefab, poolTrans);
    }

    public void CreateScene(IMaterialColorCalculator calculator, Transform parent ,Vector3 camPos,Transform debugIndexVertPoolTrans)
    {
        // destroy all existing instance
        foreach (var ins in mInstanceList)
            mInstancePool.Release(ins);
        mInstanceList.Clear();

        int index = 0;

        for (int theta = 0; theta <= 180; theta += interval)
        {
            for (int phi = 0; phi < 360; phi += interval)
            {

                index++;

                float thetaInRad = (float)theta * Mathf.Deg2Rad;
                float phiInRad = (float)phi * Mathf.Deg2Rad;

                // set position
                var instance = mInstancePool.Alloc(parent);
                Vector3 pos = new Vector3(
                    Mathf.Sin(thetaInRad) * Mathf.Cos(phiInRad),
                    Mathf.Cos(thetaInRad),
                    Mathf.Sin(thetaInRad) * Mathf.Sin(phiInRad)
                    );
                instance.transform.position = sceneCenter + radius * pos;

                Vector3 viewDir = camPos - instance.transform.position;
                viewDir = viewDir.normalized;

                if (index == DEBUG_INDEX)
                    Debug.LogError( index + " instance.position = " + instance.transform.position);


                Color col = calculator.GetColorAt(thetaInRad, phiInRad, viewDir, index == DEBUG_INDEX, instance.transform);
                
                instance.material.SetColor("_MainColor", col);

                mInstanceList.Add(instance);
            }
        }
    }

}