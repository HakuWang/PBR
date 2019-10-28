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

float3 UniformSampleDirNormalHemi(float2 uv)
{

	float cosTheta = sqrt(1 - uv.x);
	float sinTheta = sqrt(1 - cosTheta * cosTheta);
	float phi = 2 * UNITY_PI * uv.y;

	//compute local xyz from polar coordinates
	float3 dir = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);

	return dir;
}

half3 SchilickFresnel(half3 f0, half vdoth)
{
	float3 specFresnel = f0 + (1.0 - f0) * pow(1.0 - vdoth, 5.0);
	return specFresnel;
}

half3 UESchilickFresnel(half3 f0, half vdoth)
{
	float index = (-5.55473 * vdoth - 6.98316)* vdoth;
	float3 specFresnel = f0 + (1.0 - f0) * pow(2.0, index);
	return specFresnel;
}

half3 CODBlackOps2ApproxFresnel(half3 f0, half hdotl)
{
	float3 specFresnel = f0 + (1.0 - f0) * pow(2.0, -10.0 * hdotl);
	return specFresnel;
}

half CODBlackOps2ApproxVterm(float glossness, float vdoth)
{
	half k = min(1.0, glossness + 0.545);
	half VTerm = 1.0 / (k * vdoth * vdoth + (1.0 - k));
	return VTerm;
}

half CODBlackOps2DplTerm(float glossness, float ndoth)
{
	half alpha = pow(8192 , glossness);
	half DplTerm = (alpha + 2.0) /8.0 * pow ( ndoth ,alpha );
	return DplTerm;
}

half3 CODBlackOps2BRDF(float3 f0 , float glossness, float ndoth, float vdoth)
{
	//this brdf can multiply light color directly
	half V = CODBlackOps2ApproxVterm(glossness, vdoth);

	half3 F = CODBlackOps2ApproxFresnel(f0, vdoth);

	half Dpl= CODBlackOps2DplTerm( glossness, ndoth);
	
	half3 brdf = Dpl * F * V;

	return brdf;
}

half NDFofBlinnPhong(half roughness, half ndoth)
{
	half glossness = 1 - roughness;
	half alpha = pow(8192, glossness);

	half Dm = (alpha + 2.0) / (8.0 * UNITY_PI) * pow(ndoth , alpha);
	return Dm;
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

float SmithG1ForGGX(float ndots, float alpha)
{
	return 2.0 * ndots / (ndots * (2.0 - alpha) + alpha);
}

float3 samplePanoramicLOD(sampler2D panoMap, float3 dir, float lod)
{
	float n = length(dir.xz);
	float2 pos = float2((n > 0.0000001) ? dir.x / n : 0.0, dir.y);
	pos = acos(pos)*0.31831;
	pos.x = (dir.z > 0.0) ? 1.0 - (pos.x*0.5):  pos.x*0.5;
	pos.y = 1.0 - pos.y;

	float4 hdrColor = tex2Dlod(panoMap, half4(pos, 0, lod));

	//hdrColor.rgb = (_EvnMapIntensity * hdrColor.a * hdrColor.a) * hdrColor.rgb;

	return hdrColor.rgb;
}

float3 DisneyDiffuseBRDF(float roughness, float hdotl , float ndotl,float ndotv)
{
	float Fss90 = sqrt(roughness)* hdotl * hdotl;
	float FD90 = 0.5 + 2 * Fss90;
	float fd = (1 + (FD90 - 1) * pow(1 - ndotl, 5)) * (1 + (FD90 - 1) * pow(1 - ndotv, 5));
	float3 brdfDiffuse = ndotl * saturate(ndotv) * fd;

	return brdfDiffuse;
}

float3 FrosbiteDisneyDiffuseBRDF(float roughness, float hdotl, float ndotl, float ndotv)
{
	float energyBias = lerp(0, 0.5, roughness);
	float energyFactor = lerp(1.0, 1.0 / 1.51, roughness);
	float FD90 = energyBias + 2.0 * hdotl * hdotl * roughness;
	float lightScatter = (1 + (FD90 - 1) * pow(1 - ndotl, 5));
	float viewScatter = (1 + (FD90 - 1) * pow(1 - ndotv, 5));
	float fd = lightScatter * viewScatter * energyFactor;
	float diffuseBrdf = fd / UNITY_PI;
	return diffuseBrdf;
}

int PrefilterMipLevel(int maxSampleCount, float alpha_tr,float ndoth,float hdotl,int maxLevel)
{
	float pdf = NDFofGGX(alpha_tr, ndoth) * ndoth / (4 * hdotl);
	float omegaS = 1.0 / (maxSampleCount * pdf);
	float omegaP = 4 * UNITY_PI / (2048 * 1024);
	float mipLevel = 0.5 *log2(omegaS / omegaP);
	mipLevel = (int)clamp(mipLevel, 0, maxLevel);
	
	return mipLevel;
}

float computeSDLOD(float3 Ln, float p, int nbSamples)
{
	return max(0.0, 12.0 - 1.5 - 0.5 * log2(float(nbSamples) * p * sqrt(1.0 - Ln.y*Ln.y)));
}

float2 fibonacci2D(int i, int nbSample)
{
	return float2(
		(float(i) + 0.5) / float(nbSample),
		float(i + 1) * 0.618034
		
		);
}