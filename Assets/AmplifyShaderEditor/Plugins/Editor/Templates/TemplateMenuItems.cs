// Amplify Shader Editor - Visual Shader Editing Tool
// Copyright (c) Amplify Creations, Lda <info@amplify.pt>
using UnityEditor;

namespace AmplifyShaderEditor
{
	public class TemplateMenuItems
	{
		[ MenuItem( "Assets/Create/Amplify Shader/Single Pass/Post Process", false, 85 )]
		public static void ApplyTemplate0()
		{
			AmplifyShaderEditorWindow.CreateNewTemplateShader( "c71b220b631b6344493ea3cf87110c93" );
		}
		[ MenuItem( "Assets/Create/Amplify Shader/Single Pass/Default Unlit", false, 85 )]
		public static void ApplyTemplate1()
		{
			AmplifyShaderEditorWindow.CreateNewTemplateShader( "6e114a916ca3e4b4bb51972669d463bf" );
		}
		[ MenuItem( "Assets/Create/Amplify Shader/Single Pass/Default UI", false, 85 )]
		public static void ApplyTemplate2()
		{
			AmplifyShaderEditorWindow.CreateNewTemplateShader( "5056123faa0c79b47ab6ad7e8bf059a4" );
		}
		[ MenuItem( "Assets/Create/Amplify Shader/Single Pass/Default Sprites", false, 85 )]
		public static void ApplyTemplate3()
		{
			AmplifyShaderEditorWindow.CreateNewTemplateShader( "0f8ba0101102bb14ebf021ddadce9b49" );
		}
		[ MenuItem( "Assets/Create/Amplify Shader/Single Pass/Particles Alpha Blended", false, 85 )]
		public static void ApplyTemplate4()
		{
			AmplifyShaderEditorWindow.CreateNewTemplateShader( "0b6a9f8b4f707c74ca64c0be8e590de0" );
		}
		[ MenuItem( "Assets/Create/Amplify Shader/Multi Pass/Unlit", false, 85 )]
		public static void ApplyTemplate5()
		{
			AmplifyShaderEditorWindow.CreateNewTemplateShader( "e1de45c0d41f68c41b2cc20c8b9c05ef" );
		}
		[ MenuItem( "Assets/Create/Amplify Shader/Custom/3DPaintAccumulator_AmplifyTemplate_Multipass", false, 85 )]
		public static void ApplyTemplate6()
		{
			AmplifyShaderEditorWindow.CreateNewTemplateShader( "09182848b7475fc468fbdf38ee264256" );
		}
		[ MenuItem( "Assets/Create/Amplify Shader/Custom/3DPaintAccumulator_AmplifyTemplate_Multipass_2", false, 85 )]
		public static void ApplyTemplate7()
		{
			AmplifyShaderEditorWindow.CreateNewTemplateShader( "869e290ce923c6e4fa87eaeeb0f8c6b0" );
		}
	}
}
