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

        [Tooltip("Texture to use for the sketch pattern.")]
        public TextureParameter sketchTexture = new TextureParameter(null);

        [Tooltip("Color used to tint the sketch texture.")]
        public ColorParameter sketchColor = new ColorParameter(Color.black);

        [Tooltip("First value = shadow value where sketches start.\nSecond value = shadow value where sketches are at full opacity.")]
        public Vector2Parameter sketchThresholds = new Vector2Parameter(new Vector2(0.0f, 0.1f));

        [Tooltip("How strongly the shadow map is blurred. Higher values mean the sketches extend further outside the shadowed regions.")]
        public IntParameter blurAmount = new IntParameter(1);

        [Tooltip("Sensitivity of the function which prevents sketches appearing improperly on some objects.")]
        public ClampedFloatParameter extendDepthSensitivity = new ClampedFloatParameter(0.002f, 0.0001f, 0.01f);

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
