#include "Utils.cginc"

void UniformSampleLightInputDir(float2 uv,float3 viewDir, float3 normal ,out float3 L, out float3 H, out float dOmega, out float space)
{
	float cosTheta = sqrt(1 - uv.x) ;
	float sinTheta = sqrt(1 - cosTheta * cosTheta);
	float phi = 2 * UNITY_PI * uv.y;
	
	//uniformly sample L in world space within whole sphere ,theta is between sampleLightDir and y-up
	L = float3(sinTheta * cos(phi), cosTheta, sinTheta * sin(phi));
	H = normalize(L + viewDir);
	float ndotl = dot(normal, L);

	dOmega = sinTheta;
	space = UNITY_PI * 4.0;
}

float3 UniformSampleGGX(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, half roughness, float2 uvr)
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

			UniformSampleLightInputDir(uv,viewDir, normal, L, H, dOmega, space);

			float ndotl = dot(normal, L);

			if (ndotl > 0)
			{
				float3 sampleL = texCUBE(_Enviroment, L).rgb;

				float vdoth = dot(viewDir, H);
				float ndotv = dot(viewDir, normal);
				float ndoth = dot(normal, H);
				ndotv = saturate(ndotv);

				//Fresnel coefficient
				float3 specFresnel = f0 + (1 - f0) * pow(1 - dot(H, L), 5);

				float alpha_tr = roughness * roughness; //_Roughness =  1 表示越光滑
				half Dm = alpha_tr * alpha_tr / (UNITY_PI * pow((ndoth * ndoth * (alpha_tr * alpha_tr - 1.0) + 1.0), 2.0)); //Q  

				half Gmv = 2.0 * ndoth * ndotv / vdoth;
				half Gml = 2.0 * ndoth * ndotl / vdoth;
				half Gm = min(1.0, min(Gmv, Gml));

				float3 brdfSpecular = specFresnel * Dm * Gm / (4.0 * ndotl * ndotv);

				float lambertfr = 1.0/UNITY_PI;

				accu += brdfSpecular /*( + lambertfr *(1.0 - specFresnel)) */ * sampleL * ndotl *  dOmega * space;
				count = count + 1;
			}

		}
	
		accu /=  (float)count;

	return accu;
}

float3 UniformSampleGGXAndLambert(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, half roughness, float2 uvr,float3 albedo)
{
	float3 accu = 0;
	int count = 0;


	for (int i = 0; i < maxSampleCount; i++)
	{

		//get random parameter u,v
		float2 uv = Hammersley2d(i, maxSampleCount);

		float3 L, H;
		float dOmega, space;

		UniformSampleLightInputDir(uv, viewDir, normal, L, H, dOmega, space);

		float ndotl = dot(normal, L);

		if (ndotl > 0)
		{
			float3 sampleL = texCUBE(_Enviroment, L).rgb * 0.5;

			float vdoth = dot(viewDir, H);
			float ndotv = dot(viewDir, normal);
			float ndoth = dot(normal, H);
			ndotv = saturate(ndotv);

			//Fresnel coefficient
			float3 specFresnel = f0 + (1 - f0) * pow(1 - dot(H, L), 5);

			float alpha_tr = roughness * roughness; //_Roughness =  1 表示越光滑
			half Dm = alpha_tr * alpha_tr / (UNITY_PI * pow((ndoth * ndoth * (alpha_tr * alpha_tr - 1.0) + 1.0), 2.0)); //Q  

			half Gmv = 2.0 * ndoth * ndotv / vdoth;
			half Gml = 2.0 * ndoth * ndotl / vdoth;
			half Gm = min(1.0, min(Gmv, Gml));

			float3 brdfSpecular = specFresnel * Dm * Gm / (4.0 * ndotl * ndotv);

			float3 lambertfr = albedo / UNITY_PI;

			accu +=  (brdfSpecular  + lambertfr *(1.0 - specFresnel))  * sampleL * ndotl *  dOmega * space;
			count = count + 1;
		}

	}

	accu /= (float)count;

	return accu;
}


float3 IndirectSpecularUniformSampling(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, half roughness,float2 uvr)
{
	float3 indirectSpecular;

	indirectSpecular = UniformSampleGGX(maxSampleCount, viewDir, normal, f0, roughness, uvr);
	
	return indirectSpecular;
}

float3 IndirectUniformSampling(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, half roughness, float2 uvr, half3 albedo)
{
	float3 indirect;

	indirect = UniformSampleGGXAndLambert(maxSampleCount, viewDir, normal, f0, roughness, uvr, albedo);

	return indirect;
}