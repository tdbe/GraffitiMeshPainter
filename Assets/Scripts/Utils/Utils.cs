using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class Utils {

    public static float CalculateAngle(Vector3 from, Vector3 to)
    {

        //return Quaternion.FromToRotation(Vector3.up, to - from).eulerAngles.z;
        return Quaternion.FromToRotation(from, to).eulerAngles.z;

    }
}
