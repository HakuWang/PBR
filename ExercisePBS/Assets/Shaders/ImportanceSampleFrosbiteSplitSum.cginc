
void SplitSumSpecFrosbite(int maxSampleCount, float3 viewDir, float3 normal, float3 tangentX, float3 tangentY, float3 f0, float3 f90, half roughness, out float2 accuDFG, out float3 accuLD)
{
	float accLDweight = 0;
	
	for (int i = 0; i < maxSampleCount; i++)
	{
		//get random parameter u,v
		float2 uv = fibonacci2D/*Hammersley2d */(i, maxSampleCount);

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

		float vdoth = max( abs( dot(viewDir, H)), 1e-8 );
		float ndotv = max( abs(dot(viewDir, normal)), 1e-8);
		float ndoth = max( abs(dot(normal, H)), 1e-8);
		float ndotl = max( dot(normal, L), 1e-8);

		float Gv = SmithG1ForGGX(ndotv, alpha_tr);
		float Gl = SmithG1ForGGX(ndotl, alpha_tr);

		float G = Gv * Gl;
		float G_Vis = G * vdoth / (ndoth * ndotv);
		float index = (-5.55473 * vdoth - 6.98316)* vdoth;
		float Fc = pow(2, index );  //   pow(1 - vdoth, 5);
	
		accuDFG.x += (1 - Fc) * G_Vis;
		accuDFG.y += Fc * G_Vis;


		//compute LD for each sample
		
		half Dm = NDFofGGX(alpha_tr, ndoth);
		float3 pdf = Dm * ndoth / (4.0 * vdoth);//参考 GGX 逆采样变换推导 pdf

		float mipLevel = PrefilterMipLevel(maxSampleCount, alpha_tr, ndoth, vdoth, 12);
		float sdMipLevel = computeSDLOD(L, pdf, maxSampleCount);

		float3 sampleL = samplePanoramicLOD(_Enviroment, L, sdMipLevel);

		float weight = ndotl;

		accuLD += sampleL * weight;
		accLDweight += weight;
	}

	accuDFG /= (float) maxSampleCount;
	accuLD /= accLDweight;
}


float3 SpecLDImportanceSampleFrosbite(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90, half roughness)
{
	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(1.0f, 0.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	float accLDweight = 0;
	float3 accuLD = 0;

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

		accuLD += sampleL * weight;
		accLDweight += weight;
	}

	accuLD /= accLDweight;

	return accuLD;
}


float3 DiffLDImportanceSampleFrosbite(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90, half roughness)
{
	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(1.0f, 0.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	float3 accuLD = 0;

	for (int i = 0; i < maxSampleCount; i++)
	{
		//get random parameter u,v
		float2 uv = fibonacci2D/*Hammersley2d*/(i, maxSampleCount);

		//compute theta and phi from u,v for half vector H
		float alpha_tr = roughness * roughness;
		float cosTheta = sqrt(1 - uv.x);
		float sinTheta = sqrt(1 - cosTheta * cosTheta);
		float phi = 2 * UNITY_PI * uv.y;

		//compute local xyz from polar coordinates
		float3 L = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);

		//transform local to world
		L = tangentX * L.x + tangentY * L.y + normal * L.z;

		float3 H = normalize(viewDir + L);

		float vdoth = max(abs(dot(viewDir, H)), 1e-8);
		float ndoth = max(abs(dot(normal, H)), 1e-8);
		float ndotl = max(dot(normal, L), 1e-8);

		//compute LD for each sample

		half Dm = NDFofGGX(alpha_tr, ndoth);
		float3 pdf = Dm * ndoth / (4.0 * vdoth);//参考 GGX 逆采样变换推导 pdf

		float sdMipLevel = computeSDLOD(L, pdf, maxSampleCount);
		float3 sampleL = samplePanoramicLOD(_Enviroment, L, sdMipLevel);

		accuLD += sampleL ;
	}

	accuLD /= maxSampleCount;

	return accuLD;
}



float3 IndirectSpecularImportanceSamplingFrosibite(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90 , half roughness)
{
	float3 indirectSpecular;
	float2 accuDFGterm = 0;
	float3 accuLDterm = 0;
	
	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(1.0f, 0.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	SplitSumSpecFrosbite(maxSampleCount,viewDir, normal, tangentX, tangentY, f0,f90 , roughness , accuDFGterm , accuLDterm);
	float DFG1 = accuDFGterm.x;
	float DFG2 = accuDFGterm.y;

	float3 LD = accuLDterm;
	indirectSpecular = (f0 * DFG1 + f90 * DFG2) * LD;
	return indirectSpecular;
}


void SplitSumBothFrosbite(
	
	int maxSampleCount, 
	float3 viewDir, 
	float3 normal, 
	float3 tangentX, 
	float3 tangentY, 
	float3 f0, 
	float3 f90, 
	half roughness,
	out float2 accuSpecDFG,
	out float3 accuSpecLD, 
	out float3 accuDiffDFG, 
	out float3 accuDiffLD )
{
	float accSpecLDweight = 0;

	for (int i = 0; i < maxSampleCount; i++)
	{
		//get random parameter u,v
		float2 uv = fibonacci2D/*Hammersley2d */(i, maxSampleCount);


		//spec DFG and LD
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
		float ndotv = max(abs(dot(viewDir, normal)), 1e-8);
		float ndoth = max(abs(dot(normal, H)), 1e-8);
		float ndotl = max(dot(normal, L), 1e-8);

		float Gv = SmithG1ForGGX(ndotv, alpha_tr);
		float Gl = SmithG1ForGGX(ndotl, alpha_tr);

		float G = Gv * Gl;
		float G_Vis = G * vdoth / (ndoth * ndotv);
		float index = (-5.55473 * vdoth - 6.98316)* vdoth;
		float Fc = pow(2, index);  //   pow(1 - vdoth, 5);

		accuSpecDFG.x += (1 - Fc) * G_Vis;
		accuSpecDFG.y += Fc * G_Vis;


		//compute LD for each sample

		half Dm = NDFofGGX(alpha_tr, ndoth);
		float3 pdf = Dm * ndoth / (4.0 * vdoth);//参考 GGX 逆采样变换推导 pdf

		float mipLevel = PrefilterMipLevel(maxSampleCount, alpha_tr, ndoth, vdoth, 12);
		float sdMipLevel = computeSDLOD(L, pdf, maxSampleCount);

		float3 sampleL = samplePanoramicLOD(_Enviroment, L, sdMipLevel);

		float weight = ndotl;

		accuSpecLD += sampleL * weight;
		accSpecLDweight += weight;


		//diffuse DFG and LD
		 cosTheta = sqrt(1 - uv.x);
		 sinTheta = sqrt(1 - cosTheta * cosTheta);
		 phi = 2 * UNITY_PI * uv.y;

		 L = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);
		 L = tangentX * L.x + tangentY * L.y + normal * L.z;
		 H = normalize(viewDir + L);

		 vdoth = max(abs(dot(viewDir, H)), 1e-8);
		 ndoth = max(abs(dot(normal, H)), 1e-8);
		 ndotl = max(dot(normal, L), 1e-8);

		 float3 diffBrdfMultiPi = FrosbiteDisneyDiffuseBRDF(roughness, vdoth, ndotl, ndotv) * UNITY_PI;
		 accuDiffDFG += diffBrdfMultiPi;

		 pdf = ndotl / UNITY_PI;
		 sdMipLevel = computeSDLOD(L, pdf, maxSampleCount);
		 sampleL = samplePanoramicLOD(_Enviroment, L, sdMipLevel);
		 accuDiffLD += sampleL;

	}

	accuSpecDFG /= (float)maxSampleCount;
	accuSpecLD /= accSpecLDweight;

	accuDiffDFG /= (float)maxSampleCount;
	accuDiffLD /= (float)maxSampleCount;
}




float3 IndirectSplitSumBothFrosibite(float3 diffCol,int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90, half roughness)
{
	
	float3 indirectSpecular, indirectDiffuse;
	float2 accuSpecDFGterm = 0;
	float3 accuSpecLDterm = 0;
	float3 accuDiffDFGterm = 0;
	float3 accuDiffLDterm = 0;


	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(1.0f, 0.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	SplitSumBothFrosbite(maxSampleCount,viewDir,normal,tangentX,tangentY,f0,f90,roughness,accuSpecDFGterm,accuSpecLDterm,accuDiffDFGterm,accuDiffLDterm);
		
	indirectSpecular = (f0 * accuSpecDFGterm.x + f90 * accuSpecDFGterm.y) * accuSpecLDterm;
	indirectDiffuse = accuDiffDFGterm * accuDiffLDterm;
	return indirectSpecular + diffCol * indirectDiffuse;
}

float3 FrosibiteLUT(int maxSampleCount, float ndotv,float roughness)
{
	float3 normal = float3(0, 0, 1);
	float3 viewDir = float3(sqrt(1.0 - ndotv * ndotv), 0, ndotv);
	float3 f0 = 1.0; 
	float3 f90 = 1.0;

	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(1.0f, 0.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	float3 lutCol = float3(0,0,0);
	float2 accuDFGterm = 0;
	float3 accuLDterm = 0;

	SplitSumSpecFrosbite(maxSampleCount, viewDir, normal, tangentX, tangentY, f0, f90, roughness, accuDFGterm, accuLDterm);
	lutCol.r = accuDFGterm.x;
	lutCol.g = accuDFGterm.y;

	float3 LD = accuLDterm;
	
	return lutCol;
}

