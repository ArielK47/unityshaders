Shader "Custom/Outline" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Threshold ("Threshold", Range(0,10)) = 1
		_ToggleCamera ("Use Camera Color", int) = 1
		_SampleTexelWidth ("Sample Texel Width", int) = 1
	}
	SubShader {
		Tags { "RenderType"="Transparent"  "RenderQueue" = "Transparent"}
		LOD 200
		
		Pass{
			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 3.0

			sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
			sampler2D _CameraDepthNormalsTexture;
			float4 _CameraDepthTexture_TexelSize; // (1.0/width, 1.0/height, width, height)
			float4 _Color;
			float _Threshold;
			int _ToggleCamera;
			int _SampleTexelWidth;

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 scrPos : TEXCOORD1;
			};
			
			v2f vert(appdata_base v){
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.texcoord;
				#if defined (UNITY_UV_STARTS_AT_TOP)
				o.uv.y = 1 - o.uv.y;
				#endif
				o.scrPos = v.texcoord;
				return o;
			}
			
			float4 frag(v2f input) : COLOR{
				float4 defaultColor = tex2D(_MainTex, input.scrPos);
				float2 texelSize = 0.5 * _CameraDepthTexture_TexelSize.xy;
			    float2 taps[4] = {     
				    float2(input.uv + float2(-_SampleTexelWidth,-_SampleTexelWidth)*texelSize),
				    float2(input.uv + float2(-_SampleTexelWidth,_SampleTexelWidth)*texelSize),
				    float2(input.uv + float2(_SampleTexelWidth,-_SampleTexelWidth)*texelSize),
				    float2(input.uv + float2(_SampleTexelWidth,_SampleTexelWidth)*texelSize) 
				};
				
			 	float depth1 = LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, taps[0])));
			    float depth2 = LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, taps[1])));
			    float depth3 = LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, taps[2])));
			    float depth4 = LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, taps[3])));
			 	
			    float max_dep = max(depth1, max(depth2, max(depth3, depth4)));
			    float min_dep = min(depth1, min(depth2, min(depth3, depth4)));
			    //float depth_outline = max_dep - min_dep;
			    float depth_outline = ceil(max((max_dep - min_dep) - _Threshold, 0));
			    float4 sobelColor = float4(depth_outline, depth_outline, depth_outline, 1) * _Color;
				//return sobelColor;
				_ToggleCamera = clamp(_ToggleCamera, 0 ,1);
				return float4((defaultColor * _ToggleCamera + sobelColor * sobelColor.a).xyz, 1.0);
			}


			ENDCG
		}
	} 
	FallBack "Diffuse"
}
