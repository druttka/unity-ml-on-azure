using System;
using UnityEditor;
using UnityEngine;

public class AzureDeploymentWindow : EditorWindow
{
	[MenuItem("ML on Azure/Train")]
    static void OnAzureLogin()
    {
        EditorWindow.GetWindow(typeof(AzureDeploymentWindow), false, "Train ML on Azure", true);
    }

    // TODO: Good enough for initial POC. Not good enough to ship. 
    // 1. Should remember the user's storage acct name once set, or let them select from a dropdown using Azure SDKs to populate from their subscription
    // 2. This default wouldn't be globally unique at scale
    string storageAccountName = $"unityml{DateTime.Now.ToString("yyyyMMddHHmm")}";

    void OnGUI()
    {
        EditorGUILayout.LabelField("Train ML on Azure", EditorStyles.boldLabel);

        storageAccountName = EditorGUILayout.TextField("Storage account name", storageAccountName);

        GUILayout.FlexibleSpace();

        if (GUILayout.Button(new GUIContent("Deploy")))
        {
            GUILayout.Label(storageAccountName);
        }
    }
}
