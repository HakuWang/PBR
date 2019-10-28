
float3 SpecularImportanceSample(int maxSampleCount, float3 viewDir, float3 normal, float3 tangentX, float3 tangentY, float3 f0, float3 f90, half roughness)
{
	float3 accu= 0;
	int count = 0;

	for (int i = 0; i < maxSampleCount; i++)
	{
		float3 specVal = 0;
		float3 specFresnel = 1;

		/*Importance Sampling for indirect specular start */

		//get random parameter u,v
		float2 uv = fibonacci2D(i, maxSampleCount);

		//compute theta and phi from u,v for half vector H
		float alpha_tr = roughness * roughness;
		float cosTheta = sqrt((1 - uv.x) / (1 + (alpha_tr  * alpha_tr - 1)* uv.x));
		float sinTheta = sqrt(1 - cosTheta * cosTheta);
		float phi = 2 * UNITY_PI * uv.y;

		//compute local xyz from polar coordinates
		float3 H = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);

		//transform local to world
		H = tangentX * H.x + tangentY * H.y + normal * H.z;

		float3 L = reflect(-viewDir, H);
		float ndotl = dot(normal, L);

		ndotl = max(ndotl, 1e-8);
		float vdoth = max(1e-8, abs(dot(viewDir, H)));
		float ndotv = max(abs(dot(viewDir, normal)), 1e-8);
		float ndoth = max(1e-8, abs(dot(normal, H)));

		half Dm = NDFofGGX(alpha_tr, ndoth);
		float3 pdf = Dm * ndoth / (4.0 * vdoth);//参考 GGX 逆采样变换推导 pdf

		float sdMipLevel = computeSDLOD(L, pdf, maxSampleCount);

		int mipLevel = PrefilterMipLevel(maxSampleCount, alpha_tr, ndoth, vdoth, 12);
		float3 sampleL = samplePanoramicLOD(_Enviroment, L, sdMipLevel);

		specFresnel = /*SchilickFresnel*/UESchilickFresnel(f0, vdoth);
		half Gm = SmithG1ForGGX(ndotv, alpha_tr) * SmithG1ForGGX(ndotl, alpha_tr);
		//float3 brdfSpecular = specFresnel * Dm * Gm / (4.0 * ndotl * ndotv);

		float3 integVal = specFresnel * Gm * vdoth / (ndotv * ndoth);
		specVal = integVal * sampleL;
		
		accu += specVal;

		count++;
	
	}

	accu /= float(maxSampleCount);
	return accu;
}


//IvanSpecularImportanceSample is not finished
float3 IvanSpecularImportanceSample(int maxSampleCount, float3 viewDir, float3 normal, float3 tangentX, float3 tangentY, float3 f0, float3 f90, half roughness, half indirectSpecFactor)
{
	float3 accu = 0;
	int count = 0;

	for (int i = 0; i < maxSampleCount; i++)
	{
		//get random parameter u,v
		float2 uv = Hammersley2d(i, maxSampleCount);


		//compute theta and phi from u,v for half vector H
		float alpha_tr = roughness * roughness;
		float cosTheta = sqrt((1 - uv.x) / (1 + (alpha_tr  * alpha_tr - 1)* uv.x));
		float sinTheta = sqrt(1 - cosTheta * cosTheta);
		float phi = 2 * UNITY_PI * uv.y;

		//compute local xyz from polar coordinates
		float3 H = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);

		//transform local to world
		H = tangentX * H.x + tangentY * H.y + normal * H.z;

		float3 L = reflect(-viewDir, H);
		float ndotl = dot(normal, L);

		if (ndotl > 0)
		{
			float vdoth = clamp(dot(viewDir, H), 0.0001, 1.0);
			float ndotv = clamp(dot(viewDir, normal), 0.0001, 1.0);
			float ndoth = dot(normal, H);
			float hdotl = dot(H, L);
			int mipLevel = PrefilterMipLevel(maxSampleCount, alpha_tr, ndoth, hdotl, 8);
			float3 sampleL =samplePanoramicLOD(_Enviroment, L, mipLevel);



			float alpha_tr = roughness * roughness;
			float3 specFresnel = SchilickFresnel(f0, vdoth);
			half Dm = NDFofGGX(alpha_tr, ndoth);
			half Gm = GTermofTorranceAndSparrow(ndoth, ndotv, ndotl, vdoth);
			float3 brdfSpecular = specFresnel * Dm * Gm / (4.0 * ndotl * ndotv);
			float3 pdf = Dm  / 4.0 ;//refer to  Gpu pro6  ch4

			accu += brdfSpecular / pdf * sampleL  * indirectSpecFactor * ndotl;
			
			count++;
		}
	}

	accu /= float(count);
	return accu;
}


float3 IndirectSpecularImportanceSampling(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90 , half roughness)
{
	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(0.0f, 1.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	float3 indirectSpecular= SpecularImportanceSample(maxSampleCount,viewDir, normal, tangentX, tangentY, f0,f90 , roughness);
	
	return indirectSpecular;
}


//ImportanceSampleforDiffandSpec need more research ,diffuse IBL is always black
float3 ImportanceSampleforSpecandUniformDiff(float3 diffCol, int maxSampleCount, float3 viewDir, float3 normal, float3 tangentX, float3 tangentY, float3 f0, float3 f90, half roughness)
{
	float3 accu = 0;

	for (int i = 0; i < maxSampleCount; i++)
	{

		float3 specVal = 0;
		float3 diffVal = 0;
		float3 specFresnel = 1;

		/*Importance Sampling for indirect specular start */

		//get random parameter u,v
		float2 uv = fibonacci2D(i, maxSampleCount);

		//compute theta and phi from u,v for half vector H
		float alpha_tr = roughness * roughness;
		float cosTheta = sqrt((1 - uv.x) / (1 + (alpha_tr  * alpha_tr - 1)* uv.x));
		float sinTheta = sqrt(1 - cosTheta * cosTheta);
		float phi = 2 * UNITY_PI * uv.y;

		//compute local xyz from polar coordinates
		float3 H = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);

		//transform local to world
		H = tangentX * H.x + tangentY * H.y + normal * H.z;

		float3 L = reflect(-viewDir, H);
		float ndotl = dot(normal, L);

		ndotl = max(ndotl,1e-8);
		float vdoth = max(1e-8, abs(dot(viewDir, H)));
		float ndotv = max(abs(dot(viewDir, normal)), 1e-8);
		float ndoth = max(1e-8, abs(dot(normal, H))); 

		half Dm = NDFofGGX(alpha_tr, ndoth);
		float3 pdf = Dm * ndoth / (4.0 * vdoth);//参考 GGX 逆采样变换推导 pdf

		float sdMipLevel = computeSDLOD(L, pdf, maxSampleCount);

		int mipLevel = PrefilterMipLevel(maxSampleCount, alpha_tr, ndoth, vdoth, 12);
		float3 sampleL = samplePanoramicLOD(_Enviroment, L, sdMipLevel);

		specFresnel = /*SchilickFresnel*/UESchilickFresnel(f0, vdoth);
		half Gm = SmithG1ForGGX(ndotv, alpha_tr) * SmithG1ForGGX(ndotl, alpha_tr); 
		//float3 brdfSpecular = specFresnel * Dm * Gm / (4.0 * ndotl * ndotv);

		float3 integVal = specFresnel * Gm * vdoth / (ndotv * ndoth);
		specVal =  integVal *sampleL;


		/*Importance Sampling for indirect specular end */


		/*Uniform Sampling for indirect diffuse*/
		cosTheta = sqrt(1 - uv.x);
		sinTheta = sqrt(uv.x);

		L = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);
		L = tangentX * L.x + tangentY * L.y + normal * L.z;

		H = normalize(viewDir + L);
		ndotl = dot(normal, L);

		if( ndotl > 0)
		{
			float vdoth = clamp(dot(viewDir, H), 0.0001, 1.0);
			float ndotv = clamp(dot(viewDir, normal), 0.0001, 1.0);
			float ndoth = clamp(dot(normal, H), 0.0001, 1.0);
			float hdotl = clamp(dot(H, L), 0.0001, 1.0);

			int mipLevel = PrefilterMipLevel(maxSampleCount, alpha_tr, ndoth, hdotl, 12);
			pdf = ndotl / UNITY_PI;//参考 GGX 逆采样变换推导 pdf
			sdMipLevel = computeSDLOD(L, pdf, maxSampleCount);

			float3 sampleL = samplePanoramicLOD(_Enviroment, L, sdMipLevel);

			//Disney Diffuse
			float3 brdfDiffuse = /*DisneyDiffuseBRDF*/FrosbiteDisneyDiffuseBRDF(roughness, hdotl, ndotl, ndotv);
			
		    //Lambert 
		//	float3 brdfDiffuse = 1.0 / UNITY_PI * (1- specFresnel);
			float3 pdfDiff = ndotl / UNITY_PI;
			diffVal = ndotl * brdfDiffuse / pdfDiff * sampleL;


        }

		accu += specVal + diffCol * diffVal;

	}

	accu /= float(maxSampleCount);
	return accu;
}


float3 IndirectImportanceSampling(float3 diffCol,int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90, half roughness )
{
	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(0.0f, 1.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	float3 indirect = ImportanceSampleforSpecandUniformDiff(diffCol, maxSampleCount, viewDir, normal, tangentX, tangentY, f0, f90, roughness);

	return indirect;
}

