Shader "Custom/OutlineGlow" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Emission ("Emission", Color) = (0,0,0,1)
        _ExtrudeAmount ("Extrusion Amount", Range(0,1)) = 0.5
        _ScaleAmount ("Scale Amount", Range(1,2)) = 1.5
        _GlowColor ("Outline Glow Color", Color) = (1,1,1,1)
        _GlowBump ("Glow Bump", 2D) = "bump" {}
        _RimPower ("Rim Power", Range(0,10)) = 0.0
    }
    SubShader {
        Tags {  "RenderType" = "Transparent" "Queue" = "Transparent" }
        //LOD 200
            
        ZTest Always
        ZWrite Off
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        //AlphaTest Greater [_Cutoff]

        
        CGPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma surface surf Standard vertex:vert alpha:fade finalcolor:flatcolor

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0

            sampler2D _MainTex;
            sampler2D _BumpMap;
            
            struct Input {
                float2 uv_MainTex; 
                float2 uv_BumpMap;
                float3 viewDir;
            };
            
            fixed4 _GlowColor;
            fixed _RimPower;
            fixed _ScaleAmount;
            fixed _ExtrudeAmount;
            void vert (inout appdata_full v) {
                v.vertex.xyz += v.normal * _ExtrudeAmount;
                v.vertex.xyz *= _ScaleAmount;
                
            }
            
            void flatcolor (Input IN, SurfaceOutputStandard o, inout fixed4 color) {
              fixed4 glowColor = _GlowColor;
              fixed rimAlpha;
              rimAlpha = clamp(dot(IN.viewDir, o.Normal), 0, 1);
              //rimAlpha = 1 - clamp(dot(IN.viewDir, o.Normal), 0, 1);
              #ifdef UNITY_PASS_FORWARDADD
              glowColor = 0;
              #endif
              color.rgb = glowColor.rgb;
              color.a = pow(rimAlpha, _RimPower) * glowColor.a;
              //color.a = 0.1 + pow(rimAlpha, _RimPower)*0.9;
            }

            void surf (Input IN, inout SurfaceOutputStandard o) {
                // Albedo comes from a texture tinted by color
                o.Albedo = _GlowColor.rgb;
                o.Alpha = _GlowColor.a;
                //o.Emission = _GlowColor.rgb;
                //o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
            }
        ENDCG


        Blend Off
        ZTest LEqual
        ZWrite On
        Cull Back
        //Pass {
            //Blend One One
            //SetTexture [_MainTex] { combine texture }
            
            CGPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma surface surf Standard fullforwardshadows alpha:fade

            // Use shader model 3.0 target, to get nicer looking lighting
            //#pragma target 3.0

            sampler2D _MainTex;

            struct Input {
                float2 uv_MainTex; 
            };

            half _Glossiness;
            half _Metallic;
            fixed4 _Emission;
            fixed4 _Color;
            
            
            void surf (Input IN, inout SurfaceOutputStandard o) {
                // Albedo comes from a texture tinted by color
                fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
                o.Albedo = c.rgb;
                o.Alpha = c.a;
                // Metallic and smoothness come from slider variables
                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;
                o.Emission = _Emission.rgb;
                
            }
            ENDCG
        //}
        
    
        
        
        
        
    } 
    FallBack "Diffuse"
}
