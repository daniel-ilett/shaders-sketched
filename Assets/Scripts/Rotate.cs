using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

public class Rotate : MonoBehaviour
{
    [SerializeField] private float rotateSpeed;
    [SerializeField] private Transform rotateTarget;
    [SerializeField] private Vector3 rotateOffset;
    [SerializeField] private float rotateRadius;

    [SerializeField] private RenderPassEvent eve;

    private void Update()
    {
        float x = Mathf.Sin(Time.time * rotateSpeed) * rotateRadius;
        float z = Mathf.Cos(Time.time * rotateSpeed) * rotateRadius;

        transform.position = rotateTarget.position + rotateOffset + new Vector3(x, 0.0f, z);
        transform.LookAt(rotateTarget.position);
    }
}
