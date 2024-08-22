namespace DanielIlett.Sketch
{
    using UnityEngine;
    using UnityEngine.Rendering;
    using UnityEngine.Rendering.Universal;

    [System.Serializable, VolumeComponentMenu("Daniel Ilett/Sketch")]
    public class SketchSettings : VolumeComponent, IPostProcessComponent
    {
        public SketchSettings()
        {
            displayName = "Barrel Distortion";
        }

        [Tooltip("Strength of the distortion. Values above zero cause CRT screen-like distortion; values below zero bulge outwards.")]
        public ClampedFloatParameter strength = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

        [Tooltip("Color of the background around the 'screen'.")]
        public ColorParameter backgroundColor = new ColorParameter(Color.black);

        public TextureParameter sketchTexture = new TextureParameter(null);

        public IntParameter blurAmount = new IntParameter(1);

        public Vector2Parameter sketchThresholds = new Vector2Parameter(new Vector2(0.0f, 0.1f));

        public bool IsActive()
        {
            return sketchTexture.value != null && active;
        }

        public bool IsTileCompatible()
        {
            return false;
        }
    }
}
