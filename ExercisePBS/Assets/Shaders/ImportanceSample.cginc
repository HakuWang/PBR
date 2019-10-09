
void ImportanceSample(int maxSampleCount, float3 viewDir, float3 normal, float3 tangentX, float3 tangentY, float3 f0, float3 f90, half roughness, out float2 accuDFG, out float3 accuLD)
{
	float accLDweight = 0;

	for (int i = 0; i < maxSampleCount; i++)
	{
		//get random parameter u,v
		float2 uv = Hammersley2d(i, maxSampleCount);

		//compute theta and phi from u,v for half vector H
		float cosTheta = sqrt((1 - uv.x) / (1 + (roughness * roughness - 1)* uv.x));//origin : cosTheta = sqrt(1 - uv.x) ,here is GGX
		float sinTheta = sqrt(1 - cosTheta * cosTheta);
		float phi = 2 * UNITY_PI * uv.y;

		//compute local xyz from polar coordinates
		float3 H = float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);

		//transform local to world
		H = tangentX * H.x + tangentY * H.y + normal * H.z;

		float3 L = 2 * dot(H, viewDir)* H - viewDir;

		float vdoth = dot(viewDir, H);
		float ndotv = dot(viewDir, normal);
		float ndoth = dot(normal, H);
		float ndotl = dot(normal, L);

		//compute DFG for each sample
		float Fc = pow(1 - vdoth, 5);

		//Torrance and Sparrow  Gterm
		float G1Light = 2 * ndoth * ndotl / vdoth;
		float G1View = 2 * ndoth * ndotv / vdoth;
		float GTerm = min(1, min(G1Light, G1View));

		float Gvis = GTerm * vdoth / (ndotv * ndoth);

		accuDFG.x += (1 - Fc)*Gvis;
		accuDFG.y += Fc * Gvis;


		//compute LD for each sample
		float3 sampleL = texCUBE(_Enviroment, L).rgb;
		float weight = ndotl;

		accuLD += sampleL * weight;
		accLDweight += weight;
	}

	accuDFG /= maxSampleCount;
	accuLD /= accLDweight;
}

float3 IndirectSpecularImportanceSampling(int maxSampleCount, float3 viewDir, float3 normal, float3 f0, float3 f90 , half roughness)
{
	float3 indirectSpecular;
	float2 accuDFGterm;
	float3 accuLDterm;
	
	float3 upVector = abs(normal.z) < 0.999f ? float3(0.0f, 0.0f, 1.0f) : float3(1.0f, 0.0f, 0.0f);//Q 这里的 (0,0,1) 指的是世界的向上吧？

	float3 tangentX = normalize(cross(upVector, normal));
	float3 tangentY = cross(normal, tangentX);

	ImportanceSample(maxSampleCount,viewDir, normal, tangentX, tangentY, f0,f90 , roughness , accuDFGterm , accuLDterm);
	
	float DFG1 = accuDFGterm.x;
	float DFG2 = accuDFGterm.y;

	float LD = accuLDterm;

	indirectSpecular = (f0 * DFG1 + f90 * DFG2) * LD;
	
	return indirectSpecular;
}

