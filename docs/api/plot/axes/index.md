[plot](../../index.md) › plot.axes

# plot.axes

```cangjie
import plot.axes.{Axes, PieAxes, RadarAxes}
```

面板层：[`Panel`](Panel.md) 抽象、笛卡尔 [`Axes`](Axes.md)、[`PieAxes`](PieAxes.md)、[`RadarAxes`](RadarAxes.md)，以及图例、颜色条与标注。[`Figure`](../Figure.md) 按网格排布面板并把矩形交给每个面板，矩形内如何绘制完全由面板自定——这正是 `Axes`、`PieAxes` 与 `RadarAxes` 能共处一图的接缝。数据系列本身在 [`plot.series`](../series/index.md)；本包提供承载它们的坐标面板，以及叠加其上的[标注](Annotation.md)、[图例](Legend.md)与[颜色条](ColorBar.md)。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`Panel`](Panel.md) | 图形网格中一块自成一体的绘图区域——所有面板类型的抽象基类。 |
| [`Axes`](Axes.md) | 笛卡尔绘图面板：两条标度、多条按顺序绘制的系列，以及网格线、刻度、标注和图例。 |
| [`Annotation`](Annotation.md) | 绘制在数据之上的记号的抽象基类——阈值线、高亮区间、数据点旁的文字。 |
| [`HorizontalLine`](HorizontalLine.md) | 固定 y 值处的水平参考线——上限、均值或目标。 |
| [`VerticalLine`](VerticalLine.md) | 固定 x 值处的竖直参考线——事件时刻或边界。 |
| [`VerticalSpan`](VerticalSpan.md) | 介于两个 x 值之间的着色条带——高亮一段区间或感兴趣区域。 |
| [`HorizontalSpan`](HorizontalSpan.md) | 介于两个 y 值之间的着色条带。 |
| [`TextNote`](TextNote.md) | 锚定在某个数据点上的文字备注，可垫在半透明底衬上。 |
| [`Legend`](Legend.md) | 把色样对应到系列标签的图例。 |
| [`ColorBar`](ColorBar.md) | 连续颜色标度的图例：色带本身，加一条带标签的数值轴。 |
| [`PieAxes`](PieAxes.md) | 饼图或环形图面板：把各切片的份额编码为扇形角度。 |
| [`RadarTrace`](RadarTrace.md) | 雷达图的一条轨迹：每根辐条一个值，外加样式。 |
| [`RadarAxes`](RadarAxes.md) | 雷达图（蜘蛛图）面板：多个变量在从共享中心辐射的辐条上展开，每条轨迹画成闭合多边形。 |

**结构体**

| 类型 | 说明 |
|---|---|
| [`PieSlice`](PieSlice.md) | 饼图的一个切片：数值、名称与可选样式。 |

**枚举**

| 类型 | 说明 |
|---|---|
| [`LabelOrientation`](LabelOrientation.md) | y 轴标题的排布方向：整体旋转、逐字纵排或水平置顶。 |
| [`LegendPosition`](LegendPosition.md) | 图例相对绘图区的摆放位置。 |
| [`ColorBarSide`](ColorBarSide.md) | 指定颜色条显示在绘图区右侧还是下方。 |
| [`PieLabelMode`](PieLabelMode.md) | 饼图切片标签显示的内容。 |
