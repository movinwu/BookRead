# UnityShader入门精要

## 1. 渲染流水线

渲染流水线分为3个阶段：应用阶段（Application Stage）、几何阶段（Geometry Stage）、光栅化阶段（Rasterizer Stage）。
其中，应用阶段由CPU完成，几何阶段和光栅化阶段由GPU完成。

### 1.1 应用阶段

应用阶段可以分为3个阶段：把数据加载到显存中、设置渲染状态、调用Draw Call。

#### 1.1.1 把数据加载到显存中

所有渲染数据都需要从硬盘（Hard Disk Drive，HDD）中加载到系统内存（Random Access Memory，RAM）中，然后再从系统内存中加载到显存（Video Random Access Memory，VRAM）中。
原因在于显卡对于显存的访问速度更快，且大多数显卡都没有直接访问系统内存的权限。
需要加载的数据包含：网格、纹理、顶点位置、法线方向、顶点颜色、纹理坐标等等。

#### 1.1.2 设置渲染状态

渲染状态包含：使用哪个顶点着色器（Vertex Shader）/片元着色器（Fragment Shader）、光源属性、材质等。

#### 1.1.3 调用Draw Call

Draw Call是一个由CPU调用GPU接收的命令，这个命令仅会指向一个需要被渲染的图元（primitives）列表，不会再包含任何其他信息（其他信息已经在上一个阶段完成了设置）。
当给定一个Draw Call时，GPU会进行一次计算，并将计算结果绘制到屏幕上。
CPU给定一个Draw Call实际上意味着CPU完成了一次数据从RAM到VRAM的加载工作和一次渲染状态设置工作。

### 1.2 几何阶段

几何阶段分为：顶点着色器（Vertex Shader）、曲面细分着色器（Tessellation Shader）、几何着色器（Geometry Shader）、裁剪（Clipping）、屏幕映射（Screen Mapping）。

#### 1.2.1 顶点着色器

这是流水线的第一阶段，它的输入来自于CPU。输入进来的每个顶点都会调用一次顶点着色器，这个阶段也是可编程的。
顶点着色器不可以创建或销毁任何顶点，也不能获取顶点之间的关系。每个顶点都会执行一次顶点着色器操作，顶点之间是相互隔离的。
顶点着色器需要完成的主要工作有：顶点坐标变换、逐顶点光照。

##### 1.2.1.1 顶点坐标变换

顶点坐标变换指顶点坐标由模型空间转换到其次裁剪空间，一般有类似下面的代码完成：

```shaderlab
o.pos = mul(UNITY_MVP, v.position)
```

在进行顶点坐标变换前，可以对顶点坐标进行修改，这可以用于进行水面模拟、布料模拟等。

##### 1.2.1.2 逐顶点光照

#### 1.2.2 曲面细分着色器

可选着色器，用于细分图元。

#### 1.2.3 几何着色器

可选着色器，可以执行逐图元的着色操作，或被用于产生更多图元。

#### 1.2.4 裁剪

将不在视野范围内的图元裁剪掉。对于完全在视野外的图元，直接舍弃；对于完全在视野内的图元，图元的所有顶点全部保留；对于部分在视野内的图元，则需要对图元进行细分处理，这个处理就是裁剪。
图元裁剪后，会删除原来不在视野内的顶点，并产生新的顶点。
裁剪是硬件上的固定操作，不可编程，但是可以进行配置。

#### 1.2.5 屏幕映射

将每个图元的x和y坐标转换到屏幕坐标系（Screen Coordinates）下称为屏幕映射。屏幕映射得到的屏幕坐标确定了这个顶点对应屏幕上的哪个像素以及距离这个像素有多远。
屏幕坐标在OpenGL和DirectX之间存在差异，OpenGL将屏幕左下角当做坐标系原点，DirectX将屏幕左上角当做坐标系原点。

### 1.3 光栅化阶段

光栅化阶段分为：三角形设置（Triangle Setup）、三角形遍历（Triangle Traversal）、片元着色器（Fragment Shader）、逐片元操作（Per-Fragment Operations）。
光栅化阶段需要计算每个图元覆盖了哪些像素，并为这些像素计算它们的颜色。

#### 1.3.1 三角形设置

计算光栅化一个三角形网格所需的信息，即计算每个三角形在屏幕上的像素边界。

#### 1.3.2 三角形遍历

检查每个像素是否被一个三角网格覆盖，如果覆盖，则生成一个片元（fragment）。
这个阶段根据上一个阶段的计算结果判断一个三角网格覆盖了哪些像素，并通过插值运算得到所有像素的深度等信息。
这一阶段会输出一个片元序列。一个片元并不是一个像素，而是一个像素状态的集合，通过这些状态计算该像素的最终颜色。这些状态有：屏幕坐标、深度信息、法线、纹理坐标等。

#### 1.3.3 片元着色器

根据上一个阶段得到的片元信息，通过片元着色器输出一个或多个颜色值。
片元着色器中，通过纹理采样的方式获取片元颜色。纹理采样使用的采样坐标是在三角形遍历中通过顶点插值得到的纹理坐标。
片元着色器只能影响单个片元，无法获取其他片元的信息，但是有一个情况例外，片元着色器可以反问到倒数信息。

#### 1.3.4 逐片元操作

这个阶段的任务可分为：决定每个片元的可见性、将所有可见片元的颜色进行混合。
值得注意的是，逐片元操作中的深度测试有可能在上一步片元着色器之前就完成。这是因为，如果我们在片元着色器渲染前就剔除部分不能通过测试的片元，可以减少GPU的运算。这种将深度测试提前的操作也称为Early-Z技术。

##### 1.3.4.1 决定每个片元的可见性

这个步骤包含一系列测试工作，如深度测试、模板测试等。当片元通过了所有这些测试，则这个片元是可见的，否则，这个片元会被舍弃。

###### 1.3.4.1.1 模板测试（Stencil Test）

如果开启了模板测试，GPU会首先读取（使用读取掩码）模板缓冲区中该片元位置的模板值，然后将该值和读取（使用读取掩码）到的参考值进行比较，这个比较函数可以是由开发者指定的，例如小于时舍弃该片元，或者大于等于时舍弃该片元。
模板测试一般用于限制渲染的区域，还可以用于渲染阴影、渲染轮廓等。

###### 1.3.4.1.2 深度测试（Depth Test）

如果开启了深度测试，GPU会把该片元的深度值和已经存在于深度缓冲区中的深度值进行比较。这个比较函数也是可由开发者设置的，例如小于时舍弃该片元，或者大于时舍弃该片元。通常是大于时舍弃该片元（需要渲染离摄像机更近的物体）。
深度缓冲区内的深度值会被通过深度测试的片元修改，但是一个片元不论是否通过模板测试，都会修改深度缓冲区内的深度值。

##### 1.3.4.2 将所有可见片元的颜色进行混合

混合操作一般是用于半透明物体的渲染，对于没有透明物体的场景，可以关闭混合操作。

## 2. Unity中的Shader

Unity中提供了ShaderLab语言作为shader和unity的中间层。

### 2.1 Unity Shader的结构

#### 2.1.1 名称

每个shader的开始就需要定义shader名称，在名称中添加'/'字符控制Shader在材质面板中出现的位置，如下：

```shaderlab
Shader "Custom/MyShader" {}
```

#### 2.1.2 属性Properties

属性类似于类中的变量，是shader和材质的中间桥梁，在材质中可以通过设置属性值控制shader渲染的结果。
属性的定义方式如下：

```shaderlab
Properties{
    Name ("display name", PropertyType) = DefaultValue
    Name ("display name", PropertyType) = DefaultValue
    // 更多属性
}
```

其中，Name指属性的名字，类似于类中的变量名，在Unity中，属性名通常以下划线开头；display name是属性显示在材质面板上的名字；PropertyType是属性类型，类似于变量的变量类型；DefaultValue是变量的默认值。
支持的属性如下：

| 属性类型            | 默认值的定义语法                         | 例子                                                      |
|:--------------- |:-------------------------------- |:-------------------------------------------------------:|
| Int             | number                           | _IntExample("int example", Int) = 2                     |
| Float           | number                           | _FloatExample("float example", Float) = 1.5             |
| Range(min, max) | number                           | _RangeExample("range example", Range(0.0, 5.0)) = 3.0   |
| Color           | (number, number, number, number) | _ColorExample("color example", Color) = (1, 1, 1, 1)    |
| Vector          | (number, number, number, number) | _VectorExample("vector example", Vector) = (2, 3, 7, 1) |
| 2D              | "defaulttexture" {}              | _2DExample("2D example", 2D) = "" {}                    |
| 3D              | "defaulttexture" {}              | _3DExample("3D example", 3D) = "" {}                    |
| Cube            | "defaulttexture" {}              | _CubeExample("cube example", Cube) = "" {}              |

#### 2.1.3 SubShader

每一个Unity Shader文件中可以包含多个SubShader语义块，但最少要有一个。当unity加载shader时，会扫描所有SubShader语义块，然后选择第一个能够在目标平台上运行的SubShader。如果都不支持，unity会使用Fallback语义指定的shader。

SubShader包含的定义通常如下：

```shaderlab
SubShader{
    // 可选的
    [Tags]

    // 可选的
    [RenderSetup]

    Pass{

    }
    // Other Passes
}
```

SubShader中定义了一系列Pass一级可选的状态（[RenderSetup]）和标签（[Tags]）设置。每个Pass定义了一次完整的渲染流程，但如果Pass的数量过多，会造成渲染性能的下降。

##### 2.1.3.1 SubShader的标签

SubShader的标签是一个键和值都是字符串类型的键值对。标签结构如下：

```shaderlab
Tags { "TagName1" = "Value1" "TagName2" = "Value2" }
```

###### 2.1.3.1.1 Queue标签

这个标签用于向Unity告知要用于它渲染的几何体的渲染队列。

有两种语法形式：

```shaderlab
// 使用命名渲染队列
"Queue" = "[queue name]"
// 在相对于命名队列的给定偏移处使用未命名队列。
// 这种用法十分有用的一种示例情况是透明的水，他应该在不透明对象之后绘制，但是“Queue” = “[queue name] + [offset]”
```

支持的签名如下：

| 签名           | 值           | 功能                          |
| ------------ | ----------- | --------------------------- |
| [queue name] | Background  | 指定背景渲染队列                    |
|              | Geometry    | 指定几何体渲染队列                   |
|              | AlphaTest   | 指定AlphaTest渲染队列             |
|              | Transparent | 指定透明渲染队列                    |
|              | Overlay     | 指定覆盖渲染队列                    |
| [offset]     | 整数          | 指定Unity渲染未命名队列处的索引（相对于命名队列） |

###### 2.1.3.1.2 RenderType标签

对着色器进行分类，例如这是一个不透明的着色器，或是一个透明的着色器等。这可以被用于着色器替换功能。值为任意字符串。

所有内置着色器都设置了一个RenderType标签，如下：

* \_\_Opaque\_\_：大部分着色器（法线、自发光、反射和地形着色器）。

* \_\_Transparent\_\_：大部分半透明着色器（透明、粒子、字体和地形附加通道着色器）。

* \_\_TransparentCutout\_\_：遮罩透明度着色器（透明镂空、两个通道植被着色器）。

* \_\_Background\_\_：天空盒着色器。

* \_\_Overlay\_\_：光环、光晕着色器。

* \_\_TreeOpaque\_\_：地形引擎树皮。

* \_\_TreeTransparentCutout\_\_：地形引擎树叶。

* \_\_TreeBillboard\_\_：地形引擎公告牌树。

* \_\_Grass\_\_：地形引擎草。

* \_\_GrassBillboard\_\_：地形引擎公告牌草。

###### 2.1.3.1.3 ForceNoShadoeCasting标签

控制使用该SubShader的物体是否会投射阴影，值为True或False。

###### 2.1.3.1.4 DisableBatching标签

一些SubShader在使用Unity的批处理功能时会出现问题，例如使用了模型空间下的坐标进行顶点动画。这时可以通过该标签来直接指明是否对该SubShader使用批处理。

标签值有True、False、LODFading。为true时，unity会对使用此SubShader的物体阻止动态批处理；为False时则不会，False也是标签默认值；为LODFading时，对于属于Fade Mode值部位None的LODGroup一部分的所有几何体，unity会阻止动态批处理，否则不会阻止。

###### 2.1.3.1.5 IgnoreProjector标签

控制应用该SubShader的子着色器是否受Projector（投影器）的影响，为true时不受影响。通常用于排除不兼容投影器的半透明物体。值为True或False。

###### 2.1.3.1.6 PreviewType标签

指明材质面板会如何预览该材质。

标签值有Sphere、Plane、Skybox。值为Sphere时，以球体形式预览，这个值是默认值；值为Plane时，以平面形式预览；值为Skybox时，以天空盒形式预览。

###### 2.1.3.1.7 CanUseSpriteAtlas标签

代表使用此SubShader的精灵是否与Legacy Sprite Packer兼容。

值为True或False。

当这个SubShader是用于精灵时，将该标签设置为False。

##### 2.1.3.2 状态设置

通过一系列渲染状态的设置指令，可以设置显卡的各种状态，如是否开启混合、深度测试等。如下表：

| 状态名称   | 设置指令                                                        | 解释                  |
| ------ | ----------------------------------------------------------- | ------------------- |
| Cull   | Cull Back\|Front\|Off                                       | 设置剔除模式：剔除背面、正面、关闭剔除 |
| ZTest  | ZTest Less Greater\|LEqual\|GEqual\|Equal\|NotEqual\|Always | 设置深度测试时使用的函数        |
| ZWrite | ZWrite On\|Off                                              | 开启、关闭深度写入           |
| Blend  | Blend SrcFactor DstFactor                                   | 开启并设置混合模式           |

##### 2.1.3.3 Pass语义块

Pass语义块包含的语义如下：

```shaderlab
Pass{
    [Name]
    [Tags]
    [RenderSetup]
    // Other Code
}
```

Pass中通过如下形式定义Pass的名称：

```shaderlab
Name "MyPassName"
```

通过这个名称，我们可以使用ShaderLab的UsePass命令来直接使用其他Unity Shader中的Pass。需要注意的是，Unity内部会将所有Pass名称转换成大写字母表示，因此使用UsePass命令时必须使用大写字母形式。使用方式如下：

```shaderlab
UsePass "MyShader/MYPASSNAME"
```

可以看到，Pass语义块中同样可以进行标签设置和状态设置。在Pass语义块中进行的标签设置和状态设置仅对当前Pass生效，而在SubShader中进行的状态设置和标签设置对该SubShader中的所有Pass生效。

#### 2.1.4 Fallback

Fallback指令紧跟在各个SubShader语义块后面，也可以不指定Fallback指令。这个指令用于指定当上面所有SubShader都不能在显卡上运行时，使用指定的Shader。

Fallback语义如下：

```shaderlab
Fallback "name"
// 或者
Fallback Off
```

事实上，Fallback还会影响阴影的投射。在渲染阴影纹理时，unity会在每个UnityShader中寻找一个阴影投射的Pass。通常情况下，我们不需要自己专门实现一个Pass，这是因为Fallback使用的内置Shader中包含了这样一个通用的Pass。

#### 2.1.5 其他语义

##### 2.1.5.1 CustomEditor

当我们不满足于Unity内置的属性类型，想自定义材质面板的编辑界面，就可以使用此语义来拓展编辑界面。

##### 2.1.5.2 Category

使用这个语义可以对UnityShader中的命令进行分组。  


