Shader "DanielIlett/Sketch"
{
	SubShader
    {
        Tags 
		{ 
			"RenderType" = "Opaque"
			"RenderPipeline" = "UniversalPipeline"
		}

		HLSLINCLUDE

		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

		#define E 2.71828f

#if UNITY_VERSION < 600000
		float4 _BlitTexture_TexelSize;
#endif

		uint _KernelSize;
		float _Spread;

		float gaussian(int x) 
		{
			float sigmaSqu = _Spread * _Spread;
			return (1 / sqrt(TWO_PI * sigmaSqu)) * pow(E, -(x * x) / (2 * sigmaSqu));
		}

		ENDHLSL

        Pass
        {
			Name "Sketch Main"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

            TEXTURE2D(_SketchTexture);
            TEXTURE2D(_ShadowmapTexture);
			float2 _SketchThresholds;

            // Based on https://catlikecoding.com/unity/tutorials/advanced-rendering/triplanar-mapping/:
			float4 triplanarSample(Texture2D tex, SamplerState texSampler, float3 uv, float3 normals, float blend)
			{
				float2x2 rotationMatrix = 
					float2x2(
						0, -1,
						1, 0
					);
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

                float4 sketchTexture = saturate(triplanarSample(_SketchTexture, sampler_LinearRepeat, worldPos, worldNormal, 10.0f));

				float shadows = 1.0f - SAMPLE_TEXTURE2D(_ShadowmapTexture, sampler_LinearClamp, i.texcoord).r;

				shadows = smoothstep(_SketchThresholds.x, _SketchThresholds.y, shadows);

                return lerp(col, sketchTexture, shadows * sketchTexture.a);
            }
            ENDHLSL
        }

		Pass
		{
			Name "Horizontal Blur"

			HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag_horizontal

            float4 frag_horizontal (Varyings i) : SV_Target
			{
				float3 col = 0.0f;
				float kernelSum = 0.0f;

				int upper = ((_KernelSize - 1) / 2);
				int lower = -upper;

				float2 uv;

				for (int x = lower; x <= upper; ++x)
				{
					float gauss = gaussian(x);
					kernelSum += gauss;
					uv = i.texcoord + float2(_BlitTexture_TexelSize.x * x, 0.0f);
					col += gauss * SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, uv);
				}

				col /= kernelSum;

				return float4(col, 1.0f);
			}
            ENDHLSL
		}

		Pass
		{
			Name "Vertical Blur"

			HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag_vertical

            float4 frag_vertical (Varyings i) : SV_Target
			{
				float3 col = 0.0f;
				float kernelSum = 0.0f;

				int upper = ((_KernelSize - 1) / 2);
				int lower = -upper;

				float2 uv;

				for (int y = lower; y <= upper; ++y)
				{
					float gauss = gaussian(y);
					kernelSum += gauss;
					uv = i.texcoord + float2(0.0f, _BlitTexture_TexelSize.y * y);
					col += gauss * SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, uv);
				}

				col /= kernelSum;
				return float4(col, 1.0f);
			}
            ENDHLSL
		}
    }
}
