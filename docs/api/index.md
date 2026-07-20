# plot

`plot` 是基于 `sdl` 模块构建的仓颉（Cangjie）科学绘图库：15 类常用图表、现代化的默认视觉风格、纯仓颉 PNG 导出，以及一套可选的窗口交互组件。图表描述与渲染完全分离——[`Figure`](plot/Figure.md) 是纯数据结构，不持有窗口、渲染器或任何 GPU 资源，同一个图形既可以在窗口中交互展示，也可以以另一种尺寸导出为图像文件。

面向的读者：用仓颉绘制数据图的开发者。使用方只需在 `cjpm.toml` 中声明对 `plot` 的依赖；`sdl` 的几何与颜色类型（`Color`、`Rect`、`Pen` 等）已由 [`plot.core`](plot/core/index.md) 再导出，无需直接依赖 `sdl`。

```toml
[dependencies]
plot = { path = "<path-to-plotmore>" }
```

## 快速示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "月度销量")
    axes.add(LineSeries([1.0, 2.0, 3.0, 4.0], [12.0, 18.0, 15.0, 22.0], label: "华东"))
    let window = PlotWindow(figure)
    window.show()
    // 显示带一条折线的交互窗口；关闭窗口后程序返回。
}
```

## 使用指南

本目录是按包、类型和成员组织的精确 API 参考。若要从第一个图表开始系统学习、按绘图任务选择方案或排查运行问题，请转到独立的 [plot 使用指南](../guide/index.md)。

## 包

| 包 | 说明 |
|---|---|
| [`plot`](plot/index.md) | 顶层入口：Figure、PlotWindow 与 FigureExport。 |
| [`plot.ui`](plot/ui/index.md) | 可选交互组件：组件抽象、工具栏、悬停读数、光标状态条与缩放/平移交互。 |
| [`plot.axes`](plot/axes/index.md) | 面板层：Panel 抽象、笛卡尔 Axes、PieAxes、RadarAxes，以及图例、颜色条与标注。 |
| [`plot.series`](plot/series/index.md) | Series 抽象与全部图表类型：折线、散点、阶梯、柱状、面积、直方图、箱线、小提琴、误差棒、热力图、等高线，以及描述统计函数。 |
| [`plot.image`](plot/image/index.md) | 纯仓颉图像编解码：RGBA 缓冲、BMP 解码器与 PNG 编码器（含 deflate 与校验和实现）。 |
| [`plot.canvas`](plot/canvas/index.md) | 绘制层：Canvas 绘图词汇表（填充、描边、标记、文本、裁剪）与线型、标记、对齐枚举。 |
| [`plot.core`](plot/core/index.md) | 颜色、主题、调色板、色标、刻度、标度、投影与数值格式化，并再导出 sdl 的几何与颜色类型。 |

## 文档信息

- 文档对象：plot 0.1.0（`cjpm.toml`），生成日期 2026-07-20。
- 文档语言：简体中文；标识符、签名与代码保持源码原文。
- 每个类型页附有一个通过编译验证的完整示例（```cangjie verify 围栏）；验证细节见[验证报告](_verification.md)。
