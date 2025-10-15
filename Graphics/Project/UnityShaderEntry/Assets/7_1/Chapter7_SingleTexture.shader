Shader "Unity Shader Book/Chapter 7/SingleTexture"
{
    Properties
    {
        // 漫反射颜色
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        // 高光颜色
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // 光滑度
        _Gloss ("Gloss", Range(8.0, 256)) = 20
        // 纹理
        _MainTex ("Main Tex", 2D) = "white" {}
        // 纹理颜色叠加修正
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            sampler2D _MainTex;
            // 特殊的向量，向量名为 纹理名_ST，对应了纹理的缩放和偏移，其中，xy值为缩放（Tiling），zw值为偏移（Offset）
            float4 _MainTex_ST;
            fixed4 _Color;

            struct appdata
            {
                // 模型空间顶点坐标
                float4 vertex : POSITION;
                // 法线方向
                float3 normal : NORMAL;
                // 纹理坐标
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                // 裁剪空间坐标
                float4 pos : SV_POSITION;
                // 世界空间下的法线
                float3 worldNormal : TEXCOORD0;
                // 世界空间下的坐标
                fixed3 worldPos : TEXCOORD1;
                // uv坐标
                float2 uv : TEXCOORD2;
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

                // 计算uv坐标
                // o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 世界法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 世界光线
                // fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                // 纹理颜色参与环境光计算
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                
                // 环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 漫反射部分
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * albedo * max(dot(worldNormal, worldLightDir), 0);

                // 世界坐标的视线
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 视线和光线的中间方向
                fixed3 halfDir = normalize(worldLightDir + viewDir);

                // 高光部分
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(dot(worldNormal, halfDir), 0), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
                // return fixed4(albedo + specular, 1.0);
            }
            ENDCG
        }
    }
}
