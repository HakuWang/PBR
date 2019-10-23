#include "Utils.cginc"

void UniformGlobalLSampleLightInputDir(float2 uv,float3 viewDir, float3 normal ,out float3 L, out float3 H, out float dOmega, out float space)
{
	float theta = 2 * acos(sqrt(1 - uv.x));
	float cosTheta = cos(theta);
	float sinTheta = sqrt(1 - cosTheta * cosTheta);

	float phi = 2 * UNITY_PI * uv.y;
	
	//uniformly sample L in world space within whole sphere ,theta is between sampleLightDir and y-up
	L = float3(sinTheta * cos(phi), cosTheta, sinTheta * sin(phi));
	H = normalize(L + viewDir);
	dOmega = 1.0;
	space = UNITY_PI * 4.0;

}

void UniformHemiLSampleLightInputDir(float2 uv, float3 viewDir, float3 normal, out float3 L, out float3 H, out float dOmega, out float space)
{
	float cosTheta = sqrt(1 - uv.x);
	float sinTheta = sqrt(1 - cosTheta * cosTheta);
	float phi = 2 * UNITY_PI * uv.y;

	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(0.0f, 1.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	L = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);
	L = tangentX * L.x + tangentY * L.y + normal * L.z;
	H = normalize(L + viewDir);

	dOmega = 1;
	space = UNITY_PI * 2.0;

}


float3 UniformSampleGGX(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, half roughness, half indirectSpecFactor)
{
	float3 accu = 0;
	int count = 0;


		for (int i = 0; i < maxSampleCount; i++)
		{

			//get random parameter u,v
			float2 uv = Hammersley2d(i, maxSampleCount);

			float cosTheta = sqrt(1 - uv.x);
			float phi = 2 * UNITY_PI * uv.y;

			float3 L, H;
			float dOmega, space;

			UniformGlobalLSampleLightInputDir(uv,viewDir, normal, L, H, dOmega, space);
			//UniformHemiLSampleLightInputDir(uv, viewDir, normal, L, H, dOmega, space); //to research more

			float ndotl = dot(normal, L);

			if (ndotl > 0)
			{
				float3 sampleL = samplePanoramicLOD(_Enviroment, L, 0) /*texCUBE(_Enviroment, L).rgb*/;
				

				float vdoth = clamp(dot(viewDir, H), 0.0001, 1.0);
				float ndotv = clamp(dot(viewDir, normal), 0.01, 1.0);
				float ndoth = dot(normal, H);

				float alpha_tr = roughness * roughness;
				float3 specFresnel = SchilickFresnel(f0, vdoth);
				half Dm = NDFofGGX( alpha_tr,  ndoth);
				half Gm =  GTermofTorranceAndSparrow(ndoth, ndotv,ndotl,vdoth);
				float3 brdfSpecular = specFresnel * Dm * Gm / (4.0 * ndotl * ndotv);

				accu += brdfSpecular  * sampleL * indirectSpecFactor * ndotl* space*  dOmega ;
				count = count + 1;
			}

		}
	
	accu /=  (float)maxSampleCount;
	return accu;
}

float3 UniformSampleGGXAndLambert(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, half roughness,float3 albedo,half indirectSpecFactor,half indirectDiffFactor)
{
	float3 accu = 0;

	for (int i = 0; i < maxSampleCount; i++)
	{

		float3 specVal = 0;
		float3 diffVal = 0;
		float3 specFresnel = 1;

		//Specular IBL
		float2 uv = Hammersley2d(i, maxSampleCount);

		float3 L, H;
		float dOmega, space;

		UniformGlobalLSampleLightInputDir(uv, viewDir, normal, L, H, dOmega, space);

		float ndotl = dot(normal, L);

		if (ndotl > 0)
		{
			float3 sampleL = /*texCUBE(_Enviroment, L).rgb*/ samplePanoramicLOD(_Enviroment, L, 0)  * 0.5;

			float vdoth = clamp(dot(viewDir, H), 0.0001, 1.0);
			float ndotv = dot(viewDir, normal);
			float ndoth = dot(normal, H);
			//ndotv = saturate(ndotv);
			ndotv = clamp(ndotv, 0.1, 1.0);

			//Fresnel coefficient
			specFresnel = f0 + (1 - f0) * pow(1 - dot(H, L), 5);

			float alpha_tr = roughness * roughness; 
			half Dm = alpha_tr * alpha_tr / (UNITY_PI * pow((ndoth * ndoth * (alpha_tr * alpha_tr - 1.0) + 1.0), 2.0)); //Q  

			half Gmv = 2.0 * ndoth * ndotv / vdoth;
			half Gml = 2.0 * ndoth * ndotl / vdoth;
			half Gm = min(1.0, min(Gmv, Gml));

			float3 brdfSpecular = specFresnel * Dm * Gm / (4.0 * ndotl * ndotv);

			float3 lambertfr = albedo  / UNITY_PI;
			specVal = brdfSpecular * indirectSpecFactor * sampleL * ndotl *  dOmega * space;
		}


		//diffuse IBL
		
		UniformHemiLSampleLightInputDir(uv, viewDir, normal, L, H, dOmega, space);

		ndotl = dot(normal, L);

		if (ndotl > 0)
		{

			float3 sampleL =/* texCUBE(_Enviroment, L)*/samplePanoramicLOD(_Enviroment, L, 0).rgb;

			float vdoth = clamp(dot(viewDir, H), 0.0001, 1.0);
			float ndotv = clamp(dot(viewDir, normal), 0.0001, 1.0);
			float ndoth = dot(normal, H);
			float hdotl = dot(H, L);

			float alpha_tr = roughness * roughness;

			//Disney Diffuse
			float Fss90 = sqrt(roughness)* hdotl * hdotl;
			float FD90 = 0.5 + 2 * Fss90;
			float fd = (1 + (FD90 - 1) * pow(1 - ndotl, 5)) * (1 + (FD90 - 1) * pow(1 - ndotv, 5));
			float3 brdfDiffuse = ndotl * saturate(ndotv) * fd;//1.0 / UNITY_PI;
			float3 pdfDiff = ndotl / UNITY_PI;//1.0;
			diffVal = ndotl * brdfDiffuse / pdfDiff * sampleL * indirectDiffFactor;//Moving Frosbite


			//Lambert 
			//float3 brdfDiffuse = 1.0 / UNITY_PI;
			//float3 pdfDiff = ndotl / UNITY_PI;//1.0;
			//diffVal = ndotl * brdfDiffuse / pdfDiff * sampleL * indirectDiffFactor;//Moving Frosbite
		}

		accu += specVal + albedo * diffVal * (1.0 - specFresnel);
		

	}

	accu /= (float)maxSampleCount;

	return accu;
}


float3 IndirectSpecularUniformSampling(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, half roughness,half indirectSpecFactor)
{
	float3 indirectSpecular;

	indirectSpecular = UniformSampleGGX(maxSampleCount, viewDir, normal, f0, roughness, indirectSpecFactor);
	
	return indirectSpecular;
}

float3 IndirectUniformSampling(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, half roughness, half3 albedo,half indirectSpecFactor,half indirectDiffFactor)
{
	float3 indirect;

	indirect = UniformSampleGGXAndLambert(maxSampleCount, viewDir, normal, f0, roughness, albedo, indirectSpecFactor,indirectDiffFactor);

	return indirect;
}