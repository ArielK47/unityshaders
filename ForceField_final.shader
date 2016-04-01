// Upgrade NOTE: replaced 'samplerRECT' with 'sampler2D'
// Upgrade NOTE: replaced 'texRECTproj' with 'tex2Dproj'

Shader "Custom/ForceField_final" {

    Properties {
        _Color ("Color", Color) = (0,0.3921569,0.7843137,0.528)
        _fadepower ("Fade Power", Range(1, 20)) = 1
        _glancepower ("Glancing Power", Range(1, 20)) = 1
        _MinAlpha ("Minimum Alpha", Range(0, 1)) = 0
        [HideInInspector]_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _MainTex ("ForceField Pattern", 2D) = "white" {}
        _Speed ("Moving Speed", Range(0, 100)) = 1
        _DistortionAmp ("Distortion Amplitude", Range(0, 5)) = 1
        _AdaptSceneScale ("Depth Adapt Scale", Range(0, 4)) = 1
        
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        
        GrabPass{ }

        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            #pragma exclude_renderers gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2 
            #pragma target 3.0

            uniform float4 _Color;
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform float _Speed;
            uniform sampler2D _GrabTexture;
            uniform float _DistortionAmp;
            
            struct VertexInput {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 tex : TEXCOORD0;
                float4 grabProjPos : TEXCOORD2;
                float norm : NORMAL;
            };
            VertexOutput vert (appdata_base v) {
                VertexOutput o = (VertexOutput)0;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                o.tex = v.texcoord;
             	o.grabProjPos = ComputeGrabScreenPos (o.pos);
             	o.norm = v.normal;
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                _MainTex_ST.w =  fmod(_MainTex_ST.w + (_Time.x * _Speed), 2);
                float4 patternColor = tex2D(_MainTex, TRANSFORM_TEX(i.tex.xy, _MainTex));
                float4 refr_uv = i.grabProjPos;
                //refr_uv.y *= -1;
                //refr_uv.xy = (refr_uv.w + refr_uv.xy);
                half3 refracted = i.norm + patternColor.r * 1;
                refr_uv.xy = refracted.xy *_DistortionAmp + refr_uv.xy;
                half4 refr = tex2Dproj( _GrabTexture, refr_uv);
                float3 grabPassColor = refr;
                return fixed4(grabPassColor,1.0);
            }
            ENDCG
        }
        
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase
            #pragma exclude_renderers gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2 
            #pragma target 3.0
            uniform sampler2D _CameraDepthTexture;
            uniform float4 _Color;
            uniform float _fadepower;
            uniform float _glancepower;
            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform float _Speed;
            uniform float _MinAlpha;
            uniform float _AdaptSceneScale;
            
            struct VertexInput {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 worldPos: TEXCOORD2;
                float4 tex : TEXCOORD0;
                float4 projPos : TEXCOORD1;
                float3 normal : Normal;
            };
            VertexOutput vert (appdata_base v) {
                VertexOutput o = (VertexOutput)0;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                o.worldPos = mul( _Object2World, v.vertex);
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
                o.tex = v.texcoord;
                o.normal = normalize( mul( float4(v.normal, 0.0), _World2Object ).xyz );
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float sceneZ = max(0,LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)))) - _ProjectionParams.g);
                float partZ = max(0,i.projPos.z - _ProjectionParams.g);

                float3 emissive = _Color.rgb;
                _MainTex_ST.w =  fmod(_MainTex_ST.w + (_Time.x * _Speed), 2);
                float4 patternColor = tex2D(_MainTex, TRANSFORM_TEX(i.tex.xy, _MainTex));
                float3 viewDir = normalize( i.worldPos.xyz - _WorldSpaceCameraPos.xyz);
                float glancingFactor = pow( 1 - abs(dot(viewDir, i.normal)) ,_glancepower);
                float3 finalColor = emissive;
                float node_3825 = (1.0+(-1*saturate((sceneZ-partZ)*_AdaptSceneScale)));
                return fixed4(finalColor,(_Color.a * patternColor.r * glancingFactor + pow(node_3825,_fadepower)) + _MinAlpha);
            }
            ENDCG
        }
    }
    FallBack "Standard"
}
