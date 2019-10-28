Please begin with " PBS_MetallicSetup.shader " or "PBS_SpecularSetup.shader".

You can choose in the material panel for enable indirect lighting, and choose 
different methods for computing indirect specular IBL and indirect spec + diff at once.

When enable indirect lighting and disable the realtime sampling, the default setting is 
to compute the indirect lighting by LUT assignned including the indirect specular and diffuse.