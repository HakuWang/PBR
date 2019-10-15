
float3 SpecularImportanceSample(int maxSampleCount, float3 viewDir, float3 normal, float3 tangentX, float3 tangentY, float3 f0, float3 f90, half roughness, half indirectSpecFactor)
{
	float3 accu= 0;
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
			float3 sampleL = texCUBE(_Enviroment, L).rgb;

			float vdoth = clamp(dot(viewDir, H), 0.0001, 1.0);
			float ndotv = clamp(dot(viewDir, normal), 0.0001, 1.0);
			float ndoth = dot(normal, H);
			float hdotl = dot(H , L);

			float alpha_tr = roughness * roughness;
			float3 specFresnel = SchilickFresnel(f0, vdoth);
			half Dm = NDFofGGX(alpha_tr, ndoth);
			half Gm = GTermofTorranceAndSparrow(ndoth, ndotv, ndotl, vdoth);
			float3 brdfSpecular = specFresnel * Dm * Gm / (4.0 * ndotl * ndotv);

			float3 pdf = Dm * ndoth / (4.0 * hdotl);//参考 GGX 逆采样变换推导 pdf

			accu += brdfSpecular / pdf * sampleL  * indirectSpecFactor * ndotl;

			count++;
		}
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
			float3 sampleL = texCUBE(_Enviroment, L).rgb;

			float vdoth = clamp(dot(viewDir, H), 0.0001, 1.0);
			float ndotv = clamp(dot(viewDir, normal), 0.0001, 1.0);
			float ndoth = dot(normal, H);
			float hdotl = dot(H, L);

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


float3 IndirectSpecularImportanceSampling(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90 , half roughness,half indirectSpecFactor)
{
	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(0.0f, 1.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	float3 indirectSpecular= SpecularImportanceSample(maxSampleCount,viewDir, normal, tangentX, tangentY, f0,f90 , roughness, indirectSpecFactor);
	
	return indirectSpecular;
}


//ImportanceSampleforDiffandSpec need more research ,diffuse IBL is always black
float3 ImportanceSampleforDiffandSpec(int maxSampleCount, float3 viewDir, float3 normal, float3 tangentX, float3 tangentY, float3 f0, float3 f90, half roughness, half indirectSpecFactor, half indirectDiffFactor)
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
			float3 sampleL = texCUBE(_Enviroment, L).rgb;

			float vdoth = clamp(dot(viewDir, H), 0.0001, 1.0);
			float ndotv = clamp(dot(viewDir, normal), 0.0001, 1.0);
			float ndoth = dot(normal, H);
			float hdotl = dot(H, L);

			float alpha_tr = roughness * roughness;
			float3 specFresnel = SchilickFresnel(f0, vdoth);
			half Dm = NDFofGGX(alpha_tr, ndoth);
			half Gm = GTermofTorranceAndSparrow(ndoth, ndotv, ndotl, vdoth);
			float3 brdfSpecular = specFresnel * Dm * Gm / (4.0 * ndotl * ndotv);

			float3 pdf = Dm * ndoth / (4.0 * hdotl);//参考 GGX 逆采样变换推导 pdf
			float3 specVal = brdfSpecular / pdf * sampleL  * indirectSpecFactor * ndotl;


			//Disney Diffuse
			float Fss90 = sqrt(roughness)* hdotl * hdotl;
			float FD90 = 0.5 + 2 * Fss90;
			float fd = (1 + (FD90 - 1) * pow(1 - ndotl, 5)) * (1 + (FD90 - 1) * pow(1 - ndotv, 5));
			float3 brdfDiffuse = ndotl * saturate(ndotv) * fd;//1.0 / UNITY_PI;
			float3 pdfDiff = ndotl / UNITY_PI;//1.0;
			float3 diffVal = ndotl * brdfDiffuse/ pdfDiff * sampleL * indirectDiffFactor ;//Moving Frosbite

			accu += specVal + diffVal * (1.0 - specFresnel) ;//Gpu pro6

			count++;
		}
	}

	accu /= float(maxSampleCount);
	return accu;
}


float3 IndirectImportanceSampling(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90, half roughness , half indirectSpecFactor,half indirectDiffFactor)
{
	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(0.0f, 1.0f, 0.0f);
	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	float3 indirect = ImportanceSampleforDiffandSpec(maxSampleCount, viewDir, normal, tangentX, tangentY, f0, f90, roughness, indirectSpecFactor, indirectDiffFactor);

	return indirect;
}

