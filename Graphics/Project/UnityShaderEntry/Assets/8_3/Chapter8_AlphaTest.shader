Shader "Unity Shader Book/Chapter 8/AlphaTest"
{
    Properties
    {
        _Color ("主色调", Color) = (1, 1, 1, 1)
        _MainTex ("主纹理", 2D) = "white" {}
        _Cutoff ("alpha测试裁剪值", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags
        {
            // 设置渲染队列为alphaTest；使用RenderType提前将shader归入到提前定义的组TransparentCutout中，指明该shader使用了透明度测试；需要不受投射器影响
            // 常见的渲染队列有：
            //        Background，队列索引1000，在任何其他队列前渲染，用于渲染背景
            //        Geometry，队列索引2000，这是默认的渲染队列，用于渲染大多数的物体，这些物体都是不透明的
            //        AlphaTest，队列索引2450，这个是专门用于透明度测试的队列，在所有不透明物体之后渲染，在透明度混合之前渲染
            //        Transparent，队列索引3000，这个是专门用于透明度混合的渲染队列
            //        OverLay，队列索引4000，这个队列最后渲染，用于实现一些叠加效果
            "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"
        }

        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            
            // 关闭剔除
            // 以正方体为例，默认情况下，正方体内部的图元会被剔除渲染，以节约运算；但是当正方体一个面为透明或半透明时，正方体内部就是可见的，这时就有必要关闭剔除
            // 如果是采用透明混合的情况，由于透明混合关闭了深度写入，直接关闭剔除会导致正面和背面都渲染出来的情况，得到奇怪的效果，因此透明混合时要渲染图元内部的情况，需要分开为两个Pass分别进行相同的透明混合渲染，
            // 其中一个pass负责执行正面渲染，使用Cull Front指令；一个pass负责执行背面渲染，使用Cull Back指令
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

            struct appdata
            {
                // 模型空间坐标
                float4 position : POSITION;
                // 模型空间法线
                float3 normal : NORMAL;
                // 顶点uv坐标
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                // uv坐标
                float2 uv : TEXCOORD0;
                // 顶点裁剪空间坐标
                float4 position : SV_POSITION;
                // 世界空间法线
                float3 worldNormal : TEXCOORD1;
                // 世界空间坐标
                float3 worldPosition : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.position);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPosition));

                fixed4 texColor = tex2D(_MainTex, i.uv);

                // 对采样的颜色进行模板测试
                if ((texColor.r - _Cutoff) < 0.0)
                    discard;// discard命令代表直接丢弃此片元
                // 上述命令已经封装为clip函数
                // clip (texColor.a - _Cutoff)

                // 通过采样的片元，正常计算光照等颜色信息
                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                
                return fixed4(ambient + diffuse, 1.0);
            }
            ENDCG
        }
    }
}
