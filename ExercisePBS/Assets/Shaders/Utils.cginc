uint ReverseBits32(uint bits)
{
#if 0 // Shader model 5
	return reversebits(bits);
#else
	bits = (bits << 16) | (bits >> 16);
	bits = ((bits & 0x00ff00ff) << 8) | ((bits & 0xff00ff00) >> 8);
	bits = ((bits & 0x0f0f0f0f) << 4) | ((bits & 0xf0f0f0f0) >> 4);
	bits = ((bits & 0x33333333) << 2) | ((bits & 0xcccccccc) >> 2);
	bits = ((bits & 0x55555555) << 1) | ((bits & 0xaaaaaaaa) >> 1);
	return bits;
#endif
}
float RadicalInverse_VdC(uint bits)
{
	return float(ReverseBits32(bits)) * 2.3283064365386963e-10; // 0x100000000
}
float2 Hammersley2d(uint i, uint maxSampleCount)
{
	return float2(float(i) / float(maxSampleCount), RadicalInverse_VdC(i));
}


half3 SchilickFresnel(half3 f0, half vdoth)
{
	float3 specFresnel = f0 + (1.0 - f0) * pow(1.0 - vdoth, 5.0);
	return specFresnel;
}

half NDFofGGX(half alpha_tr,half ndoth)
{
	half Dm = alpha_tr * alpha_tr / (UNITY_PI * pow((ndoth * ndoth * (alpha_tr * alpha_tr - 1.0) + 1.0), 2.0)); 
	return Dm;
}

half GTermofTorranceAndSparrow(half ndoth,half ndotv,half ndotl,half vdoth)
{
	half Gmv = 2.0 * ndoth * ndotv / vdoth;
	half Gml = 2.0 * ndoth * ndotl / vdoth;
	half Gm = min(1.0, min(Gmv, Gml));

	return Gm;
}