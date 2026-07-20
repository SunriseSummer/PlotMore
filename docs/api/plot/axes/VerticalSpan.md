[plot](../../index.md) › [plot.axes](index.md) › VerticalSpan

# VerticalSpan

`plot.axes` 中的 public class

介于两个 x 值之间的着色条带——高亮一段区间或感兴趣区域。以数据坐标定位，纵贯绘图区整高，随缩放与平移跟着数据走；经 [Axes.annotate](Axes.md#annotate) 挂到面板上。

## 声明

```cangjie
public class VerticalSpan <: Annotation
```

## 继承

- 父类：[Annotation](Annotation.md)。

## 说明

条带在全部系列之后绘制并被裁剪到面板内。填充色统一按 `opacity` 淡化，默认得到一层不遮数据的浅色底；说明文字用主题的次要文字色绘制，与条带颜色无关。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.VerticalSpan
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "每日负载")
    axes.xLabel = "小时"
    axes.add(LineSeries([0.0, 1.0, 2.0, 3.0, 4.0], [0.2, 0.6, 0.9, 0.5, 0.3], label: "负载"))

    // 高亮 1.5 到 3.0 的高峰时段
    let peak = VerticalSpan(1.5, 3.0)
    peak.label = "高峰时段"
    peak.opacity = 0.2
    axes.annotate(peak)

    FigureExport.renderToPng(figure, "vertical-span.png", width: 800, height: 600)
    println(peak.label) // 输出: 高峰时段
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(from, to)`](#init) | 以数据坐标的两个 x 值创建条带，端点顺序任意。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`draw(canvas, projection, theme)`](#draw) | 在绘图区整高上填充从 `from` 到 `to` 的矩形，并绘制可选说明。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`color`](#color) | 条带颜色，绘制时按 `opacity` 淡化；`None` 用主题强调色。 |
| [`opacity`](#opacity) | 填充不透明度，取值 `0..1`，默认 `0.12`。 |
| [`label`](#label) | 画在条带顶部居中的可选说明；为空不绘制。 |

## 构造函数

### init

以数据坐标的两个 x 值创建条带，端点顺序任意。两个端点构造后不可更改。

```cangjie
public init(from: Float64, to: Float64)
```

**参数**

- `from`: `Float64` — 条带一端的 x 值（数据坐标）。
- `to`: `Float64` — 条带另一端的 x 值（数据坐标）；小于 `from` 也可，绘制时自动取序。

## 方法

### draw

在绘图区整高上填充从 `from` 到 `to` 的矩形，并绘制可选说明。填充色为 `color`（或主题强调色）按 `opacity` 淡化后的结果。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标，见 [Canvas](../canvas/Canvas.md)。
- `projection`: `Projection` — 面板当前的数据↔像素变换，见 [Projection](../core/Projection.md)。
- `theme`: `Theme` — `color` 为 `None` 时的取色来源，见 [Theme](../core/Theme.md)。

## 字段

### color

条带颜色，绘制时按 `opacity` 淡化；`None` 用主题强调色。

```cangjie
public var color: ?Color = None
```

### opacity

填充不透明度，取值 `0..1`，默认 `0.12`。默认值刻意很低：条带虽叠在数据之上，读起来应像背景，而不是盖住数据。

```cangjie
public var opacity: Float64 = 0.12
```

### label

画在条带顶部居中的可选说明；为空不绘制。用主题的次要文字色，与条带颜色无关。

```cangjie
public var label: String = ""
```

## 另请参阅

- [HorizontalSpan](HorizontalSpan.md) — y 方向的着色条带
- [VerticalLine](VerticalLine.md) — 单个 x 值处的参考线
- [Annotation](Annotation.md)、[Axes.annotate](Axes.md#annotate)
