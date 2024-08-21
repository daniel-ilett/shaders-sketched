#ifndef ADDITIONAL_LIGHT_INCLUDED
#define ADDITIONAL_LIGHT_INCLUDED

void MainLight_float(float3 WorldPos, out float3 Direction, out float3 Color, out float Attenuation)
{
#ifdef SHADERGRAPH_PREVIEW
    Direction = normalize(float3(1.0f, 1.0f, 0.0f));
    Color = 1.0f;
    Attenuation = 1.0f;
#else
    Light mainLight = GetMainLight();
    Direction = mainLight.direction;
    Color = mainLight.color;
    Attenuation = mainLight.distanceAttenuation;
#endif
}

void MainLight_half(half3 WorldPos, out half3 Direction, out half3 Color, out half Attenuation)
{
#ifdef SHADERGRAPH_PREVIEW
    Direction = normalize(half3(1.0f, 1.0f, 0.0f));
    Color = 1.0f;
    Attenuation = 1.0f;
#else
    Light mainLight = GetMainLight();
    Direction = mainLight.direction;
    Color = mainLight.color;
    Attenuation = mainLight.distanceAttenuation;
#endif
}

void AdditionalLight_float(float3 WorldPos, int lightID, out float3 Direction, out float3 Color, out float Attenuation)
{
    Direction = normalize(float3(1.0f, 1.0f, 0.0f));
    Color = 0.0f;
    Attenuation = 0.0f;

#ifndef SHADERGRAPH_PREVIEW
    int lightCount = GetAdditionalLightsCount();
    if(lightID < lightCount)
    {
        Light light = GetAdditionalLight(lightID, WorldPos);
        Direction = light.direction;
        Color = light.color;
        Attenuation = light.distanceAttenuation;
    }
#endif
}

void AdditionalLight_half(half3 WorldPos, int lightID, out half3 Direction, out half3 Color, out half Attenuation)
{
    Direction = normalize(half3(1.0f, 1.0f, 0.0f));
    Color = 0.0f;
    Attenuation = 0.0f;

#ifndef SHADERGRAPH_PREVIEW
    int lightCount = GetAdditionalLightsCount();
    if(lightID < lightCount)
    {
        Light light = GetAdditionalLight(lightID, WorldPos);
        Direction = light.direction;
        Color = light.color;
        Attenuation = light.distanceAttenuation;
    }
#endif
}

void AllAdditionalLights_float(float3 WorldPos, float3 WorldNormal, float2 CutoffThresholds, out float3 LightColor)
{
    LightColor = 0.0f;

#ifndef SHADERGRAPH_PREVIEW
    int lightCount = GetAdditionalLightsCount();

    for(int i = 0; i < lightCount; ++i)
    {
        Light light = GetAdditionalLight(i, WorldPos);

        float3 color = dot(light.direction, WorldNormal);
        color = smoothstep(CutoffThresholds.x, CutoffThresholds.y, color);
        color *= light.color;
        color *= light.distanceAttenuation;

        LightColor += color;
    } 
#endif
}

void AllAdditionalLights_half(half3 WorldPos, half3 WorldNormal, half2 CutoffThresholds, out half3 LightColor)
{
    LightColor = 0.0f;

#ifndef SHADERGRAPH_PREVIEW
    int lightCount = GetAdditionalLightsCount();

    for(int i = 0; i < lightCount; ++i)
    {
        Light light = GetAdditionalLight(i, WorldPos);
        
        float3 color = dot(light.direction, WorldNormal);
        color = smoothstep(CutoffThresholds.x, CutoffThresholds.y, color);
        color *= light.color;
        color *= light.distanceAttenuation;

        LightColor += color;
    } 
#endif
}

#ifndef SHADERGRAPH_PREVIEW
	#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
	#if (SHADERPASS != SHADERPASS_FORWARD)
		#undef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
	#endif
#endif

void MainLightShadows_float (float3 WorldPos, half4 Shadowmask, out float ShadowAtten){
#ifdef SHADERGRAPH_PREVIEW
		ShadowAtten = 1;
#else
		#if defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT)
		float4 shadowCoord = ComputeScreenPos(TransformWorldToHClip(WorldPos));
		#else
		float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
		#endif
		ShadowAtten = MainLightShadow(shadowCoord, WorldPos, Shadowmask, _MainLightOcclusionProbes);
#endif
}

void MainLightShadows_float (float3 WorldPos, out float ShadowAtten){
	MainLightShadows_float(WorldPos, float4(1,1,1,1), ShadowAtten);
}

#endif // ADDITIONAL_LIGHT_INCLUDED
