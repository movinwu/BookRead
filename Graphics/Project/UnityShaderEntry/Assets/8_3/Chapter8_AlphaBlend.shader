Shader "Unity Shader Book/Chapter 8/AlphaBlend"
{
    Properties
    {
        _Color ("主色调", Color) = (1, 1, 1, 1)
        _MainTex ("主纹理", 2D) = "white" {}
        _AlphaScale ("alpha融合缩放", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags
        {
            // 设置渲染队列为alphaTest；使用RenderType提前将shader归入到提前定义的组Transparent中，指明该shader使用了透明度融合；需要不受投射器影响
            // 常见的渲染队列有：
            //        Background，队列索引1000，在任何其他队列前渲染，用于渲染背景
            //        Geometry，队列索引2000，这是默认的渲染队列，用于渲染大多数的物体，这些物体都是不透明的
            //        AlphaTest，队列索引2450，这个是专门用于透明度测试的队列，在所有不透明物体之后渲染，在透明度混合之前渲染
            //        Transparent，队列索引3000，这个是专门用于透明度混合的渲染队列
            //        OverLay，队列索引4000，这个队列最后渲染，用于实现一些叠加效果
            "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"
        }

        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            
            // 透明度融合需要关闭深度缓冲z写入，避免丢弃被此片元遮挡的片元
            ZWrite Off
            // 透明度融合需要指定融合公式
            // 透明度融合设置混合因子的公式可以是以下两种：
            //      Blend SrcFactor DstFactor, SrcFactorA DstFactorA  开启混合，源颜色（该片元产生的颜色）的rgb会乘以SrcFactor，而目标颜色（已经存在于颜色缓存内的颜色）的rgb会乘以DscFactor，然后把两者相加后的rgb再存入颜色缓冲的rgb内；源颜色（该片元产生的颜色）的a会乘以SrcFactorA，而目标颜色（已经存在于颜色缓存内的颜色）的a会乘以DscFactor，然后把两者相加后的a再存入颜色缓冲的a内
            //      Blend SrcFactor DstFactor  开启混合，并设置混合因子。和上面公式的计算相同，只是rgb的混合因子和a的混合因子相同，都是SrcFactor和DstFactor
            // 透明度混合的参数（SrcFactor、DstFactor、SrcFactorA、DstFactorA）可以是以下类型：
            //      One   1
            //      Zero  0
            //      SrcColor    当为SrcFactor或DstFactor时，使用源颜色对应的rgb分量，当为SrcFactorA或DstFactorA时，使用源颜色对应的a分量
            //      SrcAlpha    使用源颜色的a分量
            //      DstColor    当为SrcFactor或DstFactor时，使用目标颜色对应的rgb分量，当为SrcFactorA或DstFactorA时，使用目标颜色对应的a分量
            //      DstAlpha    使用目标颜色的a分量
            //      OneMinusSrcColor    1 - SrcColor
            //      OneMinusSrcAlpha    1 - SrcAlpha
            //      OneMinusDstColor    1 - DstColor
            //      OneMinusDstAlpha    1 - DstAlpha
            // 透明度混合还可以设置混合操作，默认没有设置时采用加法，支持如下混合操作设置：
            //      BlendOp Add      相加
            //      BlendOp Sub      相减
            //      BlendOp RevSub   反向相减，即由目标颜色减去源颜色
            //      BlendOp Min      取较小值
            //      BlendOp Max      取较大值
            // 下面例子是一些常见的混合公式设置
            //      Blend SrcAlpha OneMinusSrcAlpha    透明度混合采用，最常用的混合公式
            //      Blend OneMinusDstColor One         柔和相加
            //      Blend DstColor Zero                正片叠底，即相乘
            //      Blend DstColor SrcColor            两倍相乘
            //      BlendOp Min                        
            //      Blend One One                      变暗
            //      Blend Max                          
            //      Blend One One                      变亮
            //      Blend OneMinusDstColor One         滤色
            //      Blend One OneMinusSrcColor         滤色
            //      Blend One One                      线性减淡
            Blend SrcAlpha OneMinusSrcAlpha
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

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

            // 顶点着色器内计算方式和非融合的计算方式保持一致
            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPosition = mul(unity_ObjectToWorld, v.position);
                
                return o;
            }

            // 片元着色器颜色的计算方式和非融合的计算方式保持一致
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPosition));

                fixed4 texColor = tex2D(_MainTex, i.uv);

                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                // 最终输出的颜色的透明度乘上一个透明度因子，可以控制图片透明度值，方便查看效果
                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }
            ENDCG
        }
    }
}
