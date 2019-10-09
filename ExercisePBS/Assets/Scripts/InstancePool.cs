using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

public class InstancePool
{

    private readonly Transform mPoolParent;
    private readonly MeshRenderer mPrefab;

    private Queue<MeshRenderer> mPoolingList = new Queue<MeshRenderer>();

    public InstancePool(MeshRenderer prefab, Transform poolParent)
    {
        mPrefab = prefab;
    }

    public MeshRenderer Alloc(Transform parent)
    {
        if (mPoolingList.Count > 0)
        {
            var instance = mPoolingList.Dequeue();
            instance.transform.SetParent(parent);
            instance.gameObject.SetActive(true);
            return instance;
        }
        else
        {
            var instance = GameObject.Instantiate(mPrefab, parent);
            return instance;
        }

    }


    public void Release(MeshRenderer instance)
    {
        instance.transform.SetParent(mPoolParent);
        instance.gameObject.SetActive(false);
        mPoolingList.Enqueue(instance);
    }

}