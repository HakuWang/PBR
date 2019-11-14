#ifndef __RONIN_SH_L2_CGINC__
#define __RONIN_SH_L2_CGINC__


#include "SRP/Library/Core.hlsl"


#if COMPACT_MODE

///////////////////////////////////////////////
// Define Instanced Property
///////////////////////////////////////////////


#define DEFINE_RONIN_SH_INSTANCED_PROP \
            UNITY_DEFINE_INSTANCED_PROP(float4, _Slot1)     \
            UNITY_DEFINE_INSTANCED_PROP(float4, _Slot2)     \
            UNITY_DEFINE_INSTANCED_PROP(float4, _Slot3)     \
            UNITY_DEFINE_INSTANCED_PROP(float4, _Slot4)


#define ACCESS_SH_INSTANCED_PROP(props) \
            float4 roninSHSlot1 = UNITY_ACCESS_INSTANCED_PROP(props, _Slot1);  \
            float4 roninSHSlot2 = UNITY_ACCESS_INSTANCED_PROP(Props, _Slot2);  \
            float4 roninSHSlot3 = UNITY_ACCESS_INSTANCED_PROP(Props, _Slot3);  \
            float4 roninSHSlot4 = UNITY_ACCESS_INSTANCED_PROP(Props, _Slot4);




///////////////////////////////////////////////
// Access Light Info
///////////////////////////////////////////////

inline float3 roninSHThetaPhiToDir(float2 thetaPhi) {
    float sinTheta = sin(thetaPhi.x);
    float cosTheta = cos(thetaPhi.x);
    float sinPhi   = sin(thetaPhi.y);
    float cosPhi   = cos(thetaPhi.y);

    // y-up left hand coord
    return float3(
        sinTheta * cosPhi,
        cosTheta,
        sinTheta * sinPhi);
}



#define     RoninSHLight0Col     (roninSHSlot1.rgb)
#define     RoninSHLight0Dir     (roninSHThetaPhiToDir(roninSHSlot4.xy))
#define     RoninSHLight1Col     (roninSHSlot2.rgb)
#define     RoninSHLight1Dir     (roninSHThetaPhiToDir(roninSHSlot4.zw))
#define     RoninSHLight2Lum     (length(roninSHSlot3.xyz))
#define     RoninSHLight2Dir     (normalize(roninSHSlot3.xyz))
#define     RoninSHLight2LumDir  (roninSHSlot3.xyz)
#define     RoninSHAmbient       float3(roninSHSlot1.w, roninSHSlot2.w, roninSHSlot3.w)



#elif FAST_MODE



///////////////////////////////////////////////
// Define Instanced Property
///////////////////////////////////////////////


#define DEFINE_RONIN_SH_INSTANCED_PROP \
            UNITY_DEFINE_INSTANCED_PROP(float4, _Slot1)     \
            UNITY_DEFINE_INSTANCED_PROP(float4, _Slot2)     \
            UNITY_DEFINE_INSTANCED_PROP(float4, _Slot3)     \
            UNITY_DEFINE_INSTANCED_PROP(float4, _Slot4)     \
            UNITY_DEFINE_INSTANCED_PROP(float4, _Slot5)


#define ACCESS_SH_INSTANCED_PROP(Props) \
            float4 roninSHSlot1 = UNITY_ACCESS_INSTANCED_PROP(Props, _Slot1);  \
            float4 roninSHSlot2 = UNITY_ACCESS_INSTANCED_PROP(Props, _Slot2);  \
            float4 roninSHSlot3 = UNITY_ACCESS_INSTANCED_PROP(Props, _Slot3);  \
            float4 roninSHSlot4 = UNITY_ACCESS_INSTANCED_PROP(Props, _Slot4);  \
            float4 roninSHSlot5 = UNITY_ACCESS_INSTANCED_PROP(Props, _Slot5);



///////////////////////////////////////////////
// Access Light Info
///////////////////////////////////////////////


#define     RoninSHLight0Col     (roninSHSlot1.rgb)
#define     RoninSHLight0Dir     (roninSHSlot3.xyz)
#define     RoninSHLight1Col     (roninSHSlot2.rgb)
#define     RoninSHLight1Dir     (roninSHSlot4.xyz)
#define     RoninSHLight2Lum     (roninSHSlot5.w)
#define     RoninSHLight2Dir     (roninSHSlot5.xyz)
#define     RoninSHLight2LumDir  (roninSHSlot5.w * roninSHSlot5.xyz)
#define     RoninSHAmbient       float3(roninSHSlot1.w, roninSHSlot2.w, roninSHSlot3.w)





#else   // Simple Mode



///////////////////////////////////////////////
// Define Instanced Property
///////////////////////////////////////////////

#define DEFINE_RONIN_SH_INSTANCED_PROP \
            UNITY_DEFINE_INSTANCED_PROP(float4, _RoninSH_A)     \
            UNITY_DEFINE_INSTANCED_PROP(float4, _RoninSH_H)     \
            UNITY_DEFINE_INSTANCED_PROP(float4, _RoninSH_D)


#define ACCESS_SH_INSTANCED_PROP(Props) \
            float4 roninSHA = UNITY_ACCESS_INSTANCED_PROP(Props, _RoninSH_A);  \
            float4 roninSHH = UNITY_ACCESS_INSTANCED_PROP(Props, _RoninSH_H);  \
            float4 roninSHD = UNITY_ACCESS_INSTANCED_PROP(Props, _RoninSH_D);



///////////////////////////////////////////////
// Access Light Info
///////////////////////////////////////////////


#define     RoninSHLight0Col     (roninSHH.rgb)
#define     RoninSHLight0Dir     (roninSHD.xyz)
#define     RoninSHLight1Col     float3(0, 0, 0)
#define     RoninSHLight1Dir     float3(0, 1, 0)
#define     RoninSHLight2Lum     0
#define     RoninSHLight2Dir     float3(0, 1, 0)
#define     RoninSHLight2LumDir  float3(0, 0, 0)
#define     RoninSHAmbient       float3(roninSHA.xyz)









#endif






#endif