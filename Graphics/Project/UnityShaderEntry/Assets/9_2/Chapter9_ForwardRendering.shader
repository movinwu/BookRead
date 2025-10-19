Shader "Unity Shader Book/Chapter 9/ForwardRendering"
{
    
        Properties
    {
        // 漫反射颜色
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        // 高光颜色
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // 光滑度
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        // 前向渲染base pass
        Pass
        {
            Tags
            {
                // 使用标签定义此pass为前向渲染基础pass（处理基础平行光和环境光)，这个第一个处理的pass
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            // 使用指令保证在pass中相关光源属性被正确赋值
            #pragma multi_compile_fwdbase
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct appdata
            {
                // 模型空间顶点坐标
                float4 vertex : POSITION;
                // 法线方向
                float3 normal : NORMAL;
            };

            struct v2f
            {
                // 裁剪空间坐标
                float4 pos : SV_POSITION;
                // 世界空间下的法线
                float3 worldNormal : TEXCOORD0;
                // 世界空间下的坐标
                fixed3 worldPos : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 世界空间下的法线
                // o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 世界空间下的坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 世界法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 世界光线
                // fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                // 漫反射部分
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * (dot(worldNormal, worldLightDir) * 0.5 + 0.5);

                // 世界坐标的视线
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 视线和光线的中间方向
                fixed3 halfDir = normalize(worldLightDir + viewDir);

                // 高光部分
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(dot(worldNormal, halfDir) * 0.5 + 0.5, _Gloss);

                // 添加光照衰减参数，平行光不会有衰减，因此衰减为1
                fixed atten = 1.0;

                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }
            ENDCG
        }
        // 前向渲染additional pass
        Pass
        {
            Tags
            {
                // 设置这个pass为前向渲染additional pass
                "LightMode"="ForwardAdd"
            }
            
            // additional pass中需要将计算得到的颜色与已经在模板缓冲区内的颜色（base pass得到的颜色）做混合，混合方式一般为直接相加，常见的还有 Blend SrcAlpha One
            Blend One One
            
            CGPROGRAM
            // 使用指令保证在pass中相关光源属性被正确赋值
            #pragma multi_compile_fwdadd
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            // #include "UnityDeferredLibrary.cginc"
            // 包含阴影的代码
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct appdata
            {
                // 模型空间顶点坐标
                float4 vertex : POSITION;
                // 法线方向
                float3 normal : NORMAL;
            };

            struct v2f
            {
                // 裁剪空间坐标
                float4 pos : SV_POSITION;
                // 世界空间下的法线
                float3 worldNormal : TEXCOORD0;
                // 世界空间下的坐标
                fixed3 worldPos : TEXCOORD1;
                // 阴影
                SHADOW_COORDS(2)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                // 世界空间下的法线
                // o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 世界空间下的坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                // 计算阴影
                TRANSFER_SHADOW(0);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 世界法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 世界光线，使用预定义命令针对不同类型的光线做不同的处理
                #ifdef USING_DIRECTIONAL_LIGHT
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                #else
                // 对于点光源，需要自行计算光线方向
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif
                
                // 漫反射部分
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * (dot(worldNormal, worldLightDir) * 0.5 + 0.5);

                // 世界坐标的视线
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 视线和光线的中间方向
                fixed3 halfDir = normalize(worldLightDir + viewDir);

                // 高光部分
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(dot(worldNormal, halfDir) * 0.5 + 0.5, _Gloss);

                // #ifdef USING_DIRECTIONAL_LIGHT
                // fixed atten = 1.0;
                // #else
                // // 添加光照衰减参数，点光源的衰减需要单独计算
                // fixed3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                // fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                // #endif

                // 阴影值
                // fixed shadow = SHADOW_ATTENUATION(i);
                // return fixed4((diffuse + specular) * atten * shadow, 1.0);
                
                // 由于光照衰减和阴影的计算往往是放到一起的，因此这部分也封装好了
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                return fixed4((diffuse + specular) * atten, 1.0);

            }
            ENDCG
        }
    }
    Fallback "Specular"
}
