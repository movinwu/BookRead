Shader "Unity Shader Book/Chapter 7/NormalMapWorldSpace"
{
    Properties
    {
        // 颜色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 主纹理
        _MainTex ("Main Tex", 2D) = "white" {}
        // 法线纹理，默认值 bump 是unity内置的法线纹理，对应原始法线纹理
        _BumpMap ("Normal Map", 2D) = "bump" {}
        // 法线纹理缩放
        _BumpScale ("Bump Scale", Float) = 1.0
        // 高光反射
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // 光滑度
        _Gloss ("Gloss", Range(8.0, 256)) = 20
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

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                // 顶点
                float4 vertex : POSITION;
                // 法线
                float3 normal : NORMAL;
                // 切线
                float4 tangent : TANGENT;
                // 纹理坐标
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                // 裁剪空间坐标
                float4 pos : SV_POSITION;
                // uv，xy为主纹理uv，zw为法线纹理uv
                float4 uv : TEXCOORD0;
                // 记录从切线空间到世界空间的变换矩阵，将顶点位置存储在w分量中，节约存储空间
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                // o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

                // 计算世界坐标、世界法线、世界切线、世界副法线
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinomal = cross(worldNormal, worldTangent) * v.tangent.w;

                // 构造矩阵
                o.TtoW0 = float4(worldTangent.x, worldBinomal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinomal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinomal.z, worldNormal.z, worldPos.z);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 取出世界坐标
                fixed3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

                // 计算光线方向和视线方向
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                // 根据颜色反向计算得到切线
                // fixed3 tangentNormal;
                // tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
                // tangentNormal.z = sqrt(1.0 - max(dot(tangentNormal.xy, tangentNormal.xy), 0));

                fixed3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - max(dot(tangentNormal.xy, tangentNormal.xy), 0));

                // 计算法线，从法线空间到世界空间，直接左乘变换矩阵
                tangentNormal = normalize(half3(dot(i.TtoW0.xyz, tangentNormal), dot(i.TtoW1.xyz, tangentNormal), dot(i.TtoW2.xyz, tangentNormal)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(dot(tangentNormal, lightDir), 0);
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(dot(tangentNormal, halfDir), 0), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
}
