using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class IsReplaceShader : MonoBehaviour
{
    public Shader oldShader;
    public Shader newShader;
    public bool isReplace;

    private Material _mat;

    void Start()
    {
        _mat = this.GetComponent<Renderer>().sharedMaterial;
        
    }

    // Update is called once per frame
    void Update()
    {
        if (isReplace)
            _mat.shader = newShader;
        else
            _mat.shader = oldShader;
    }
}
