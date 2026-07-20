[plot](../../index.md) › plot.core

# plot.core

```cangjie
import plot.core.{Bounds, Colors, Theme, LinearScale}
```

颜色、主题、调色板、色标、刻度、标度、投影与数值格式化，并再导出 sdl 的几何与颜色类型。本包是依赖图的最底层：不含任何图表类型，只提供其余各包共用的数值与视觉基础设施。区间（[`Bounds`](Bounds.md)）、标度（[`Scale`](Scale.md) 及其三个实现）、投影（[`Projection`](Projection.md)）与刻度（[`Ticks`](Ticks.md)）共同构成数据坐标到像素坐标的完整通路；[`Theme`](Theme.md)、[`Palette`](Palette.md)、[`Colormap`](Colormap.md) 与 [`Colors`](Colors.md) 承担图形的全部配色。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`PlotException`](PlotException.md) | 图表描述无法渲染时抛出的异常。 |
| [`Colors`](Colors.md) | 基于 `Color` 的颜色构造与混合静态工具集：十六进制解析、HSL 生成、混色、明暗调整与对比度计算。 |
| [`NumberFormat`](NumberFormat.md) | 面向坐标轴、图例与读数的数值标签格式化工具。 |
| [`Projection`](Projection.md) | 单个面板的数据坐标到像素坐标变换：一个像素矩形，加上填充它的两条标度。 |
| [`Scale`](Scale.md) | 数据范围与归一化 `0..1` 轴位置之间的映射，外加标注这段范围的刻度。 |
| [`LinearScale`](LinearScale.md) | 成比例的线性轴：相等的数据间隔占据相等的像素间隔。 |
| [`LogScale`](LogScale.md) | 以 10 为底的对数轴，用于跨多个数量级的数据。 |
| [`CategoryScale`](CategoryScale.md) | 覆盖命名类别的离散轴，类别落在整数位置 `0 … n-1`。 |
| [`Ticks`](Ticks.md) | 刻度放置算法：刻度落在圆整数值上，而不是数据自身的端点上。 |
| [`Theme`](Theme.md) | 图形绘制所用的全部颜色、字号与粗细设置。 |

**结构体**

| 类型 | 说明 |
|---|---|
| [`Bounds`](Bounds.md) | 单轴上的闭区间 `[low, high]`——标度从中取值的数据范围。 |
| [`Palette`](Palette.md) | 按系列序号索引的有序分类色集合。 |
| [`Colormap`](Colormap.md) | 把 `0..1` 连续映射为颜色的色标，在锚点色停之间插值。 |
| [`Tick`](Tick.md) | 一个轴刻度：它在数据空间中的位置、标签文本，以及它是带标签与完整网格线的主刻度，还是裸的次级细分。 |

## 函数

| 函数 | 说明 |
|---|---|
| [`isFinite`](functions.md#isfinite) | 当 `value` 既非 NaN 也非无穷时返回 `true`——每条数据摄入路径最先执行的守卫。 |
| [`floorMod`](functions.md#floormod) | 把 `value` 归约到大于等于 `0` 且小于 `modulus` 的范围。 |

## 再导出

以下 sdl 类型属于 `plot` 自身的公开接口（设置系列颜色、缩进矩形、为自定义标注构造画笔都要用到），因此在此再导出：使用方只需声明对 `plot` 的依赖，写 `import plot.core.Color` 即可，无需直接依赖 `sdl`。它们不是本文档的收录对象，语义以 `sdl` 模块为准。

| 符号 | 说明 |
|---|---|
| `Color` | 8 位 RGBA 颜色。 |
| `Insets` | 四边缩进量。 |
| `Pen` | 描边画笔：线宽与颜色。 |
| `Point` | 二维像素坐标点。 |
| `Rect` | 轴对齐矩形。 |
| `Size` | 宽高尺寸。 |
| `FontStyle` | 字体样式（常规/加粗等）。 |
| `Renderer` | sdl 渲染器；`Canvas` 构造所需，`Renderer.headless()` 支持无窗口测试。 |
| `CuiException` | sdl 层在原生调用失败时抛出的异常；捕获 plot 错误的调用方也需要指名它。 |
