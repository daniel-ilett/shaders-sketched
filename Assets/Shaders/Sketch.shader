Shader "DanielIlett/Sketch"
{
	SubShader
    {
        Tags 
		{ 
			"RenderType" = "Opaque"
			"RenderPipeline" = "UniversalPipeline"
		}

        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
			#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            TEXTURE2D(_SketchTexture);
            TEXTURE2D(_ShadowmapTexture);

            // Based on https://catlikecoding.com/unity/tutorials/advanced-rendering/triplanar-mapping/:
			float4 triplanarSample(Texture2D tex, SamplerState texSampler, float3 uv, float3 normals, float blend)
			{
				float2 uvX = uv.zy;
				float2 uvY = uv.xz;
				float2 uvZ = uv.xy;

				if (normals.x < 0)
				{
					uvX.x = -uvX.x;
				}

				if (normals.y < 0)
				{
					uvY.x = -uvY.x;
				}

				if (normals.z >= 0)
				{
					uvZ.x = -uvZ.x;
				}

				float4 colX = SAMPLE_TEXTURE2D(tex, texSampler, uvX);
				float4 colY = SAMPLE_TEXTURE2D(tex, texSampler, uvY);
				float4 colZ = SAMPLE_TEXTURE2D(tex, texSampler, uvZ);

				float3 blending = pow(abs(normals), blend);
				blending /= dot(blending, 1.0f);

				return (colX * blending.x + colY * blending.y + colZ * blending.z);
			}

            float4 frag (Varyings i) : SV_Target
            {
				float4 col = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, i.texcoord);

#if UNITY_REVERSED_Z
				float depth = SampleSceneDepth(i.texcoord);
#else
				float depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(i.texcoord));
#endif
                float3 worldPos = ComputeWorldSpacePosition(i.texcoord, depth, UNITY_MATRIX_I_VP);
                float3 worldNormal = normalize(SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_LinearClamp, i.texcoord));

                float4 sketchTexture = saturate(triplanarSample(_SketchTexture, sampler_LinearRepeat, worldPos, worldNormal, 1.0f));
                float shadows = 1.0f - SAMPLE_TEXTURE2D(_ShadowmapTexture, sampler_LinearClamp, i.texcoord);

                return lerp(col, sketchTexture, shadows * sketchTexture.a);
            }
            ENDHLSL
        }
    }
}
