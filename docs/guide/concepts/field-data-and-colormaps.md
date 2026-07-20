# 二维场与色图

## 先用一句话说明

二维场在每个位置都有数值，色图把连续数值变成颜色，色标负责解释这种映射。

温度、海拔、相关系数和模拟结果都可能形成二维场。HeatmapSeries 把网格单元填色，ContourSeries 沿相同数值画等高线；两者可以单独使用，也可以叠加，让读者同时看到整体区域和可追踪的数值边界。

## 为什么重要

二维场通常包含远多于折线的数据点，逐个写数字既慢又难读。颜色能快速显示区域结构，但颜色本身没有单位。没有 ColorBar，读者只能看到“深浅不同”，不知道某个颜色对应多少。错误的值域或色图还会夸大微小差异、隐藏异常，或让正负值失去共同基准。

## 工作模型

规则网格由行数、列数、x 范围和 y 范围决定。`fromFunction` 在网格位置计算值；直接构造时，扁平值数组必须和 `rows * columns` 对应。HeatmapSeries 根据值域从 Colormap 取颜色，ContourSeries 根据若干 level 在相邻网格点之间追踪等值线。ColorBar 必须使用与系列相同的值域和色图，才能成为可信的图例。

```cangjie role=contrast
let heat = HeatmapSeries.fromFunction(60, 80, Bounds(-3.0, 3.0), Bounds(-2.0, 2.0)) {
    x, y => fieldValue(x, y)
}
heat.map = Some(Colormap.viridis())
axes.add(heat)
```

```cangjie role=trace
let contour = ContourSeries.fromFunction(80, 100, Bounds(-3.0, 3.0), Bounds(-2.0, 2.0)) {
    x, y => fieldValue(x, y)
}
contour.levelCount = 12
contour.map = Some(Colormap.viridis())
axes.add(contour)
axes.setColorBar(ColorBar(heat.resolvedValueRange(), Colormap.viridis()))
```

## 选择与取舍

热图适合看连续区域、热点与整体结构；等高线适合追踪阈值、坡度和边界。叠加时应降低底图不透明度并保持相同值域，否则线和底色会互相矛盾。顺序色图适合从低到高的量，发散色图适合围绕有意义中心（例如零或基准值）的正负偏差。不要仅因为色彩丰富就使用彩虹色图，它可能产生不存在的视觉边界。

网格更密会增加细节和计算量，但不会创造原始数据中没有的信息。矩阵数据常把第 0 行放在顶部，而普通坐标的 y 方向从下到上；`originTop` 等方向设置应依据数据约定，并用已知角点核对。多个场要横向比较时，应固定共同值域，不能让每个面板各自自动拉伸颜色后再比较深浅。

## 应用这个模型

先检查数组形状和坐标范围，再计算有限值的最小/最大。选择色图后，把同一个 `Colormap` 实例或同一种静态构造同时传给系列和 ColorBar。若零点很重要，显式使用对称 `Bounds(-m, m)`。用几个已知位置核对颜色方向：左下、右上或峰值位置应符合业务预期。最后分别试热图、等高线和叠加，确认读者需要的结构在哪一种最清楚。

本概念以前置的[数据范围与标度](data-domain-and-scales.md)为基础。完整程序见[绘制热图和等高线](../how-to/draw-field-data.md)，其中会实际导出图片并核对色标。

## 常见误解

ColorBar 不是装饰边框，而是数值解释的一部分。`resolvedValueRange` 来自有效场值，不等于 x/y 的空间范围。热图的行列数也不是输出像素尺寸；FigureExport 会把整个 Figure 渲染为指定图片大小。等高线数量越多不一定越好，线太密会遮住场结构。最后，缺失值或非有限值应在数据准备阶段处理，不要期待色图自动赋予它们正确业务含义。

## 用三个已知点诊断方向和值域

当图“能画出来但看着不对”时，先不要换色图。选出左下角、右上角和一个已知峰值，打印这三个位置的原始数值，再核对它们在图上的位置与颜色。位置上下颠倒时检查行序和 `originTop`；位置正确但颜色强弱相反时检查值域与色图方向；热图和等高线互相矛盾时检查两者是否使用相同网格、相同范围。修正后再次导出，并确认三个已知点、等高线数值和 ColorBar 能讲出同一个结论。这条诊断链把“观感不对”变成可重复的输入、检查和确认。

## 相关 API

- [`HeatmapSeries`](../../api/plot/series/HeatmapSeries.md)：显示规则网格的连续值。
- [`Colormap`](../../api/plot/core/Colormap.md)：把归一化数值映射为颜色。
- [`ColorBar`](../../api/plot/axes/ColorBar.md)：显示值域与颜色的对应关系。

## 下一步

完成[绘制热图和等高线](../how-to/draw-field-data.md)，把网格、值域、色图和色标连接成可验证结果。
