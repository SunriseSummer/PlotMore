[plot](../index.md) › plot

# plot

```cangjie
import plot.{Figure, PlotWindow, FigureExport}
```

顶层入口：[`Figure`](Figure.md)、[`PlotWindow`](PlotWindow.md) 与 [`FigureExport`](FigureExport.md)。描述与呈现在此分开：`Figure` 是纯数据的图表描述，`PlotWindow` 在窗口中交互展示它，`FigureExport` 把它写入图像文件——三者作用于同一个图形对象。子包提供底层构件：面板与系列类型来自 [`plot.axes`](axes/index.md) 与 [`plot.series`](series/index.md)，通常与本包配合使用。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`Figure`](Figure.md) | 顶层绘图对象：标题、主题与按网格排布的面板集合。 |
| [`PlotWindow`](PlotWindow.md) | 交互展示图形的窗口：按需重绘，工具栏、悬停读数等悬浮界面全部可选。 |
| [`FigureExport`](FigureExport.md) | 把图形渲染并写入 PNG 或 BMP 图像文件的导出入口。 |

**结构体**

| 类型 | 说明 |
|---|---|
| [`WindowOptions`](WindowOptions.md) | 窗口的标题、初始尺寸与是否可调整大小。 |

## 函数

| 函数 | 说明 |
|---|---|
| [`withPngExtension`](functions.md#withpngextension) | 当 `path` 未带 `.png` 或 `.bmp` 扩展名时为其追加 `.png`。 |
| [`isBmpPath`](functions.md#isbmppath) | 报告 `path` 是否指向 BMP 文件，为真时导出应跳过 PNG 编码器。 |
| [`fileNameOf`](functions.md#filenameof) | 返回 `path` 的文件名部分，供状态消息显示。 |

## 常量与变量

| 常量 | 说明 |
|---|---|
| [`VERSION`](constants.md#version) | 库的版本号，遵循语义化版本规范。 |

## 子包

| 包 | 说明 |
|---|---|
| [`plot.core`](core/index.md) | 颜色、主题、调色板、色标、刻度、标度、投影与数值格式化，并再导出 sdl 的几何与颜色类型。 |
| [`plot.canvas`](canvas/index.md) | 绘制层：Canvas 绘图词汇表（填充、描边、标记、文本、裁剪）与线型、标记、对齐枚举。 |
| [`plot.image`](image/index.md) | 纯仓颉图像编解码：RGBA 缓冲、BMP 解码器与 PNG 编码器（含 deflate 与校验和实现）。 |
| [`plot.series`](series/index.md) | Series 抽象与全部图表类型：折线、散点、阶梯、柱状、面积、直方图、箱线、小提琴、误差棒、热力图、等高线，以及描述统计函数。 |
| [`plot.axes`](axes/index.md) | 面板层：Panel 抽象、笛卡尔 Axes、PieAxes、RadarAxes，以及图例、颜色条与标注。 |
| [`plot.ui`](ui/index.md) | 可选交互组件：组件抽象、工具栏、悬停读数、光标状态条与缩放/平移交互。 |
