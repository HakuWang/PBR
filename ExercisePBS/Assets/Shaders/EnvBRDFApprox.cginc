
float3 CoDSpecEnvLFrosbite(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90, half roughness)
{
	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(1.0f, 0.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	float3 accu = 0;
	float3 accweight = 0;

	for (int i = 0; i < maxSampleCount; i++)
	{
		//get random parameter u,v
		float2 uv = fibonacci2D/*Hammersley2d*/(i, maxSampleCount);

		//compute theta and phi from u,v for half vector H
		float alpha_tr = roughness * roughness;
		float cosTheta = sqrt((1 - uv.x) / (1 + (alpha_tr * alpha_tr - 1)* uv.x));
		float sinTheta = sqrt(1 - cosTheta * cosTheta);
		float phi = 2 * UNITY_PI * uv.y;

		//compute local xyz from polar coordinates
		float3 H = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);

		//transform local to world
		H = tangentX * H.x + tangentY * H.y + normal * H.z;

		float3 L = 2 * dot(H, viewDir)* H - viewDir;

		float vdoth = max(abs(dot(viewDir, H)), 1e-8);
		float ndoth = max(abs(dot(normal, H)), 1e-8);
		float ndotl = max(dot(normal, L), 1e-8);


		//compute LD for each sample

		half Dm = NDFofGGX(alpha_tr, ndoth);
		float3 pdf = Dm * ndoth / (4.0 * vdoth);//参考 GGX 逆采样变换推导 pdf


		float sdMipLevel = computeSDLOD(L, pdf, maxSampleCount);
		float3 sampleL = samplePanoramicLOD(_Enviroment, L, sdMipLevel);

		float weight = ndotl;

		accu += sampleL * weight;
		accweight += weight;
	}

	accu /= accweight;

	return accu;
}

float3 CoDSpecEnvL(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90, half roughness)
{
	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(1.0f, 0.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	float3 accu = 0;
	float3 accweight = 0;

	for (int i = 0; i < maxSampleCount; i++)
	{
		float2 uv = fibonacci2D/*Hammersley2d*/(i, maxSampleCount);
		float3 L = UniformSampleDirNormalHemi(uv);
		L = tangentX * L.x + tangentY * L.y + normal * L.z;

		float3 H = normalize(viewDir + L);

		float vdoth = max(abs(dot(viewDir, H)), 1e-8);
		float ndoth = max(abs(dot(normal, H)), 1e-8);
		float ndotl = max(dot(normal, L), 1e-8);

		half Dm = NDFofBlinnPhong(roughness, ndoth);

		float pdf = 1;
		float sdMipLevel = computeSDLOD(L, pdf, maxSampleCount);
		float3 sampleL = samplePanoramicLOD(_Enviroment, L, sdMipLevel);

		float space = 2.0 * UNITY_PI;

		accu += sampleL * Dm * ndotl * space;
	}

	accu /= maxSampleCount;

	return accu;
}

half3 CODBlackOps2EnvSpecBRDF(float3 f0, float roughness, float ndotv)
{
	float glossness = 1.0 - roughness;
	float4 t = float4(1 / 0.96, 0.475, (0.0275 - 0.25 * 0.04) / 0.96, 0.25);
	t *= float4(glossness, glossness, glossness, glossness);
	t += float4(0, 0, (0.015 - 0.75 * 0.04) / 0.96, 0.75);
	float a0 = t.x * min(t.y, exp2(-9.28 * ndotv)) + t.z;
	float a1 = t.w;
	return saturate(a0 + f0 * (a1 - a0));
}


half3 UESpecEnvBRDFApprox(half3 SpecularColor, half Roughness, half NoV)
{

	const half4 c0 = half4 ( -1, -0.0275, -0.572, 0.022 );

	const half4 c1 = half4( 1, 0.0425, 1.04, -0.04 );

	half4 r = Roughness * c0 + c1;

	half a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;

	half2 AB = half2(-1.04, 1.04) * a004 + r.zw;

	return SpecularColor * AB.x + AB.y;

}


half3 UnityPPTSpecEnvBRDFApprox(half3 SpecularColor, half Roughness, half NoV)
{
	half3 approxF = pow((1.0 - max(Roughness, NoV)), 3);
	half3 envBrdf = approxF + SpecularColor;
	return envBrdf;

}

half3 UnityBRDFSpecEnvBRDFApprox(half3 f0, half roughness, half ndotv,half metallic, bool metellicSetup)
{
	half surfaceReduction = 1;
#   ifdef UNITY_COLORSPACE_GAMMA
	surfaceReduction = 1.0 - 0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
#   else
	surfaceReduction = 1.0 / ( roughness * roughness + 1.0);           // fade \in [0.5;1]
#   endif

	half reflectivity;
	if (metellicSetup)
	{
		half dielectricSpec = 1 - unity_ColorSpaceDielectricSpec.a;
		reflectivity = lerp(dielectricSpec, 1, metallic); //MetallicSetup or RoughnessSetup
	}
	else
		reflectivity = SpecularStrength(f0); //SpecularSetup , EnergyConservationBetweenDiffuseAndSpecular

	half grazingTerm = saturate( 1 - roughness + reflectivity);

	half3 fApproxRoughnessBrdf1 = f0 + (/*f90*/ grazingTerm - f0) * pow((1 - ndotv), 5);
	half3 fApproxRoughnessBrdf2or3 = f0 + (/*f90*/ grazingTerm - f0) * pow((1 - ndotv), 4);

	half3 envBrdf = surfaceReduction * fApproxRoughnessBrdf1;
	return envBrdf;

}


