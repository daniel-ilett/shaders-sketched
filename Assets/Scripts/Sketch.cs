namespace DanielIlett.Sketch
{
    using UnityEngine;
    using UnityEngine.Rendering;
    using UnityEngine.Rendering.Universal;
#if UNITY_6000_0_OR_NEWER
    using UnityEngine.Rendering.RenderGraphModule;
#endif

    public class Sketch : ScriptableRendererFeature
    {
        SketchRenderPass sketchPass;

        public override void Create()
        {
            sketchPass = new SketchRenderPass();
            name = "Sketch";
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            var settings = VolumeManager.instance.stack.GetComponent<SketchSettings>();

            if (settings != null && settings.IsActive())
            {
                //renderer.EnqueuePass(shadowmapPass);
                renderer.EnqueuePass(sketchPass);
            }
        }

        protected override void Dispose(bool disposing)
        {
            sketchPass.Dispose();
            base.Dispose(disposing);
        }

        class SketchRenderPass : ScriptableRenderPass
        {
            private Material material;
            private RTHandle tempTexHandle;

            public SketchRenderPass()
            {
                profilingSampler = new ProfilingSampler("Sketch");
                renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

#if UNITY_6000_0_OR_NEWER
                requiresIntermediateTexture = true;
#endif
            }

            private void CreateMaterial()
            {
                var shader = Shader.Find("DanielIlett/Sketch");

                if (shader == null)
                {
                    Debug.LogError("Cannot find shader: \"DanielIlett/Sketch\".");
                    return;
                }

                material = new Material(shader);
            }

            private static RenderTextureDescriptor GetCopyPassDescriptor(RenderTextureDescriptor descriptor)
            {
                descriptor.msaaSamples = 1;
                descriptor.depthBufferBits = (int)DepthBits.None;

                return descriptor;
            }

            public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
            {
                ResetTarget();

                var descriptor = GetCopyPassDescriptor(cameraTextureDescriptor);
                RenderingUtils.ReAllocateIfNeeded(ref tempTexHandle, descriptor);

                ConfigureInput(ScriptableRenderPassInput.Depth);
                ConfigureInput(ScriptableRenderPassInput.Normal);

                base.Configure(cmd, cameraTextureDescriptor);
            }

            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                if (renderingData.cameraData.isPreviewCamera)
                {
                    return;
                }

                if (material == null)
                {
                    CreateMaterial();
                }

                CommandBuffer cmd = CommandBufferPool.Get();

                // Set Sketch effect properties.
                var settings = VolumeManager.instance.stack.GetComponent<SketchSettings>();
                material.SetColor("_BackgroundColor", settings.backgroundColor.value);
                material.SetFloat("_Strength", settings.strength.value);
                material.SetTexture("_SketchTexture", settings.sketchTexture.value);

                var shadowmapTextureID = Shader.PropertyToID("_ScreenSpaceShadowmapTexture");
                var shadowmapTexture = (RenderTexture)Shader.GetGlobalTexture(shadowmapTextureID);

                material.SetTexture("_ShadowmapTexture", shadowmapTexture);

                RTHandle cameraTargetHandle = renderingData.cameraData.renderer.cameraColorTargetHandle;

                // Perform the Blit operations for the Colorize effect.
                using (new ProfilingScope(cmd, profilingSampler))
                {
                    Blit(cmd, cameraTargetHandle, tempTexHandle);
                    Blit(cmd, tempTexHandle, cameraTargetHandle, material, 0);
                }

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                CommandBufferPool.Release(cmd);
            }

            public void Dispose()
            {
                tempTexHandle?.Release();
            }

#if UNITY_6000_0_OR_NEWER

            private class CopyPassData
            {
                public TextureHandle inputTexture;
            }

            private class MainPassData
            {
                public Material material;
                public TextureHandle inputTexture;
            }

            private static void ExecuteCopyPass(RasterCommandBuffer cmd, RTHandle source)
            {
                Blitter.BlitTexture(cmd, source, new Vector4(1, 1, 0, 0), 0.0f, false);
            }

            private static void ExecuteMainPass(RasterCommandBuffer cmd, RTHandle source, Material material)
            {
                // Set Sketch effect properties.
                var settings = VolumeManager.instance.stack.GetComponent<SketchSettings>();
                material.SetColor("_BackgroundColor", settings.backgroundColor.value);
                material.SetFloat("_Strength", settings.strength.value);

                Blitter.BlitTexture(cmd, source, new Vector4(1, 1, 0, 0), material, 0);
            }

            public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
            {
                if(material == null)
                {
                    CreateMaterial();
                }

                UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
                UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

                UniversalRenderer renderer = (UniversalRenderer)cameraData.renderer;
                var colorCopyDescriptor = GetCopyPassDescriptor(cameraData.cameraTargetDescriptor);
                TextureHandle copiedColor = TextureHandle.nullHandle;

                // Perform the intermediate copy pass (source -> temp).
                copiedColor = UniversalRenderer.CreateRenderGraphTexture(renderGraph, colorCopyDescriptor, "_SketchColorCopy", false);

                using (var builder = renderGraph.AddRasterRenderPass<CopyPassData>("Sketch_CopyColor", out var passData, profilingSampler))
                {
                    passData.inputTexture = resourceData.activeColorTexture;

                    builder.UseTexture(resourceData.activeColorTexture, AccessFlags.Read);
                    builder.SetRenderAttachment(copiedColor, 0, AccessFlags.Write);
                    builder.SetRenderFunc((CopyPassData data, RasterGraphContext context) => ExecuteCopyPass(context.cmd, data.inputTexture));
                }

                // Perform main pass (temp -> source).
                using (var builder = renderGraph.AddRasterRenderPass<MainPassData>("Sketch_MainPass", out var passData, profilingSampler))
                {
                    passData.material = material;
                    passData.inputTexture = copiedColor;

                    builder.UseTexture(copiedColor, AccessFlags.Read);
                    builder.SetRenderAttachment(resourceData.activeColorTexture, 0, AccessFlags.Write);
                    builder.SetRenderFunc((MainPassData data, RasterGraphContext context) => ExecuteMainPass(context.cmd, data.inputTexture, data.material));
                }
            }

#endif
        }
    }
}
