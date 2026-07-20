[plot](../../index.md) › plot.canvas

# plot.canvas

```cangjie
import plot.canvas.{Canvas, LineStyle, MarkerStyle}
```

绘制层：[`Canvas`](Canvas.md) 绘图词汇表（填充、描边、标记、文本、裁剪）与线型、标记、对齐枚举。所有图表类型都经由 `Canvas` 渲染，自定义系列或组件也在这一层落笔；它把 `sdl` 渲染器的图元包装成图表需要的形状——条带、扇形、标记字形、锚定文本。样式枚举（[`LineStyle`](LineStyle.md)、[`MarkerStyle`](MarkerStyle.md)）被 [`plot.series`](../series/index.md) 的系列类型直接复用。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`Canvas`](Canvas.md) | Canvas 在 `Renderer` 之上提供图表需要的填充、折线、标记、扇形和文本绘制方法。 |

**枚举**

| 类型 | 说明 |
|---|---|
| [`LineStyle`](LineStyle.md) | 数据线的线型：虚线花纹以线宽的倍数表示，线加粗后节奏不变。 |
| [`MarkerStyle`](MarkerStyle.md) | 数据点处的标记字形：形状居中于数据点、以外接圆半径定尺寸，同尺寸下视觉分量相近。 |
| [`HAlign`](HAlign.md) | 文本的水平锚定方式：锚点落在文本的左缘、水平中心或右缘。 |
| [`VAlign`](VAlign.md) | 文本的垂直锚定方式：锚点落在文本的顶缘、垂直中心或底缘。 |

## 常量与变量

| 常量 | 说明 |
|---|---|
| [`WEDGE_EDGE_WIDTH`](constants.md#wedge_edge_width) | [Canvas.fillWedge](Canvas.md#fillwedge) 沿不透明扇形边界重描的羽化抗锯齿笔画宽度（像素）。 |
