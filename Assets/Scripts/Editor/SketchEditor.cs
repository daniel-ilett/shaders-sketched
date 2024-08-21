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
        SerializedDataParameter strength;
        SerializedDataParameter backgroundColor;
        SerializedDataParameter sketchTexture;

        public override void OnEnable()
        {
            var o = new PropertyFetcher<SketchSettings>(serializedObject);
            strength = Unpack(o.Find(x => x.strength));
            backgroundColor = Unpack(o.Find(x => x.backgroundColor));
            sketchTexture = Unpack(o.Find(x => x.sketchTexture));
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

            PropertyField(strength);
            PropertyField(backgroundColor);
            PropertyField(sketchTexture);
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
