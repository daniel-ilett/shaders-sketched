namespace DanielIlett.Sketch
{
    using UnityEditor.Rendering;
    using UnityEngine.Rendering.Universal;
    using System.Reflection;
    using UnityEditor;
    using UnityEngine;

#if UNITY_2022_2_OR_NEWER
    [CustomEditor(typeof(SketchSettings))]
#else
    [VolumeComponentEditor(typeof(SketchSettings))]
#endif
    public class SketchEditor : VolumeComponentEditor
    {
        SerializedDataParameter sketchTexture;
        SerializedDataParameter blurAmount;
        SerializedDataParameter sketchThresholds;
        SerializedDataParameter extendDepthSensitivity;
        SerializedDataParameter sketchColor;

        public override void OnEnable()
        {
            var o = new PropertyFetcher<SketchSettings>(serializedObject);
            sketchTexture = Unpack(o.Find(x => x.sketchTexture));
            blurAmount = Unpack(o.Find(x => x.blurAmount));
            sketchThresholds = Unpack(o.Find(x => x.sketchThresholds));
            extendDepthSensitivity = Unpack(o.Find(x => x.extendDepthSensitivity));
            sketchColor = Unpack(o.Find(x => x.sketchColor));
        }

        public override void OnInspectorGUI()
        {
            if (!PostProcessUtility.CheckEffectEnabled<Sketch>())
            {
                EditorGUILayout.HelpBox("The Sketch effect must be added to your renderer's Renderer Features list.", MessageType.Error);
                if (GUILayout.Button("Add Sketch Renderer Feature"))
                {
                    PostProcessUtility.AddEffectToPipelineAsset<Sketch>();
                }
            }

            PropertyField(sketchTexture);
            PropertyField(blurAmount);
            PropertyField(sketchThresholds);
            PropertyField(extendDepthSensitivity);
            PropertyField(sketchColor);
        }

#if UNITY_2021_2_OR_NEWER
        public override GUIContent GetDisplayTitle()
        {
            return new GUIContent("Sketch");
        }
#else
    public override string GetDisplayTitle()
    {
        return "Barrel Distortion";
    }
#endif
    }
}
