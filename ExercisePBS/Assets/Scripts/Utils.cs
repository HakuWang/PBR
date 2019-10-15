using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;

public static class Utils
{
    public static Vector3 ThetaPhiToDir(float theta, float phi)
    {
        return new Vector3(
            Mathf.Sin(theta) * Mathf.Cos(phi),
            Mathf.Cos(theta),
            Mathf.Sin(theta) * Mathf.Sin(phi)
            );
    }

    public static Vector3 ThetaPhiToDirZUp(float theta, float phi)
    {
        return new Vector3(
            Mathf.Sin(theta) * Mathf.Cos(phi),
            Mathf.Sin(theta) * Mathf.Sin(phi),
            Mathf.Cos(theta)
            );
    }
    

    private static uint ReverseBits32(uint bits)
    {

        bits = (bits << 16) | (bits >> 16);
        bits = ((bits & 0x00ff00ff) << 8) | ((bits & 0xff00ff00) >> 8);
        bits = ((bits & 0x0f0f0f0f) << 4) | ((bits & 0xf0f0f0f0) >> 4);
        bits = ((bits & 0x33333333) << 2) | ((bits & 0xcccccccc) >> 2);
        bits = ((bits & 0x55555555) << 1) | ((bits & 0xaaaaaaaa) >> 1);
        return bits;
    }
    private static float RadicalInverse_VdC(uint bits)
    {
        return (ReverseBits32(bits)) * 2.3283064365386963e-10f; // 0x100000000
    }
    public static Vector2 Hammersley2d(uint i, uint maxSampleCount)
    {
        return new Vector2((float)(i) / (float)(maxSampleCount), RadicalInverse_VdC(i));
    }


    public static Color SampleCubeMap(Vector3 dir, Cubemap cube)
    {

        CubemapFace sampleFace;
        float max = Mathf.Max(Mathf.Abs(dir.x), Mathf.Abs(dir.y), Mathf.Abs(dir.z));

        int cubeWidth = cube.width;
        int cubeHeight = cube.height;

        int sampleCubeU, sampleCubeV;
        float u, v;
        if (max == Mathf.Abs(dir.x))
        {
            if (dir.x > 0)
            {
                sampleFace = CubemapFace.PositiveX;
                u = -0.5f * dir.z / Mathf.Abs(dir.x) + 0.5f;
                v = -0.5f * dir.y / Mathf.Abs(dir.x) + 0.5f;
            }
            else
            {
                sampleFace = CubemapFace.NegativeX;
                u = 0.5f * dir.z / Mathf.Abs(dir.x) + 0.5f;
                v = -0.5f * dir.y / Mathf.Abs(dir.x) + 0.5f;

            }

        }
        else if (max == Mathf.Abs(dir.y))
        {
            if (dir.y > 0)
            {
                sampleFace = CubemapFace.PositiveY;
                u = 0.5f * dir.x / Mathf.Abs(dir.y) + 0.5f;
                v = 0.5f * dir.z / Mathf.Abs(dir.y) + 0.5f;

            }
            else
            {
                sampleFace = CubemapFace.NegativeY;
                u = 0.5f * dir.x / Mathf.Abs(dir.y) + 0.5f;
                v = -0.5f * dir.z / Mathf.Abs(dir.y) + 0.5f;

            }


        }
        else
        {
            if (dir.z > 0)
            {
                sampleFace = CubemapFace.PositiveZ;
                u = 0.5f * dir.x / Mathf.Abs(dir.z) + 0.5f;
                v = -0.5f * dir.y / Mathf.Abs(dir.z) + 0.5f;

            }
            else
            {
                sampleFace = CubemapFace.NegativeZ;
                u = -0.5f * dir.x / Mathf.Abs(dir.z) + 0.5f;
                v = -0.5f * dir.y / Mathf.Abs(dir.z) + 0.5f;

            }

        }

        sampleCubeU = (int)(u * cubeWidth);
        sampleCubeV = (int)(v * cubeHeight);

        Color sampleCol = cube.GetPixel(sampleFace, sampleCubeU, sampleCubeV);

        return sampleCol;
    }

}

