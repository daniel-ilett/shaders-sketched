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
			#include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

			float4 _BackgroundColor;
			float _Strength;

            TEXTURE2D(_ShadowmapTexture);

            float4 frag (Varyings i) : SV_Target
            {
				float2 UVs = i.texcoord - 0.5f;
				UVs = UVs * (1 + _Strength * length(UVs) * length(UVs)) + 0.5f;

				float4 col = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, UVs);
				col = (UVs.x >= 0.0f && UVs.x <= 1.0f && UVs.y >= 0.0f && UVs.y <= 1.0f) ? col : _BackgroundColor;
                //return col;

                return SAMPLE_TEXTURE2D(_ShadowmapTexture, sampler_LinearClamp, i.texcoord);
            }
            ENDHLSL
        }
    }
}
