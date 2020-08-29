Shader "Custom/BlitRGBAColorToTarget"
{
	Properties
	{
		[HDR] _Color("Color", Color) = (0,0,0,1)
		_MainTex ("Blit Main Texture", 2D) = "black" {}
		_StampTex ("Stamp Texture", 2D) = "black" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma target 5.0
			#pragma only_renderers d3d11
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			uniform RWTexture2D<float4> _MainTexInternal_P3DA : register(u3);
		
			/// Contains the accumulated paint data + everything not painted on, like color picker, tooltips etc.
			uniform RWTexture2D<float4> _MainTexScreen_P3DA : register(u2);

			uniform RWTexture2D<float4> _DisplacementTexInternal_P3DA : register(u4);

			

			float4 _Color;
			sampler2D _StampTex;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Atlas_ST_PerMaterial_P3DA;
			uint2 _RT_Resolution;
			//uint2  _VRSettingsEyeTextureWidthHeight;
			uint _OnStart;

			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				//if( _OnStart == 0){
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);				
				//}
				//else{
				//	o.uv = 
				//}
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				float2 uvMainTex = i.uv * _MainTex_ST.xy + _MainTex_ST.zw;
							
				float2 clipAtlas = /*i.uv * */_Atlas_ST_PerMaterial_P3DA.xy + _Atlas_ST_PerMaterial_P3DA.zw;
				
				// sample the texture
				float4 col = 
				//tex2D(_MainTex, uvMainTex) + 
				_Color 
				+ tex2D(_StampTex, uvMainTex)
				;
				//col = float4(1,0,0,1);

				if( _OnStart == 1 &&
					((uvMainTex.x < 0 || uvMainTex.x > clipAtlas.x /*+ _Atlas_ST_PerMaterial_P3DA.x*/) ||
					(uvMainTex.y < 0 || uvMainTex.y > clipAtlas.y /*+ _Atlas_ST_PerMaterial_P3DA.y*/))
				){
					clip( -1.0 );
				}

				if( _OnStart == 0
					//&&
					//!((uvMainTex.x < 0 || uvMainTex.x > clipAtlas.x /*+ _Atlas_ST_PerMaterial_P3DA.x*/) ||
					//(uvMainTex.y < 0 || uvMainTex.y > clipAtlas.y /*+ _Atlas_ST_PerMaterial_P3DA.y*/))
				){
					//col = float4(1,0,0,1);
					float2 uvAtlassed = uvMainTex;//i.uv;
					/*
					float heightRatio = (float)_VRSettingsEyeTextureWidthHeight.x/(float)_VRSettingsEyeTextureWidthHeight.y;
					float2 vrWH = (float2)(_VRSettingsEyeTextureWidthHeight);
					//vrWH.y/=1.3;//heightRatio;//1.5;
					vrWH.x *=2.4;
					//vrWH = normalize(vrWH);
					float2 scaleScreen =(float2)(_RT_Resolution)/vrWH.xy*2;
					//float2 scaleScreen =_RT_Resolution/float2(1330*2,1584)*2;
					//scaleScreen.y *= heightRatio;
					*/
					uvAtlassed = uvAtlassed*_Atlas_ST_PerMaterial_P3DA.xy//*scaleScreen 
					+ _Atlas_ST_PerMaterial_P3DA.zw;
					//*vrWH*4.5
					//uvAtlassed *= scaleScreen;
				
					uint coordx = uint((uvAtlassed.x)*_RT_Resolution.x);
					uint coordy = uint((uvAtlassed.y)*_RT_Resolution.y);
					int2 uvAtlassedInt = uint2(coordx,coordy);

					_MainTexInternal_P3DA[uvAtlassedInt]=col;
					_MainTexScreen_P3DA[uvAtlassedInt]=col;
					_DisplacementTexInternal_P3DA[uvAtlassedInt]=float4(0,0,0,0);//col;
					clip( -1.0 );
				}
				
				
				// if((uvMainTex.x < 0 || uvMainTex.x > clipAtlas.x /*+ _Atlas_ST_PerMaterial_P3DA.x*/) ||
				// 	(uvMainTex.y < 0 || uvMainTex.y > clipAtlas.y /*+ _Atlas_ST_PerMaterial_P3DA.y*/)
				// ){
				// 	clip( -1.0 );
				// }
				// if(!_OnStart)
				// 	clip( -1.0 );
				
	
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
