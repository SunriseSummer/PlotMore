[plot](../../index.md) › [plot.axes](index.md) › HorizontalSpan

# HorizontalSpan

`plot.axes` 中的 public class

介于两个 y 值之间的着色条带。以数据坐标定位，横贯绘图区整宽，随缩放与平移跟着数据走；经 [Axes.annotate](Axes.md#annotate) 挂到面板上，常用来标示正常区间或容差带。

## 声明

```cangjie
public class HorizontalSpan <: Annotation
```

## 继承

- 父类：[Annotation](Annotation.md)。

## 说明

条带在全部系列之后绘制并被裁剪到面板内。填充色统一按 `opacity` 淡化，默认近乎透明——叠在数据之上却读作背景。与 [VerticalSpan](VerticalSpan.md) 不同，它没有说明文字字段。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.HorizontalSpan
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "体温")
    axes.yLabel = "体温 (°C)"
    axes.add(LineSeries([0.0, 1.0, 2.0, 3.0], [36.2, 37.8, 36.9, 36.5], label: "患者甲"))

    // 标出 36.0 到 37.2 的正常区间
    let normal = HorizontalSpan(36.0, 37.2)
    normal.opacity = 0.25
    axes.annotate(normal)

    FigureExport.renderToPng(figure, "horizontal-span.png", width: 800, height: 600)
    println("${normal.opacity}") // 输出: 0.250000
    // 生成的图像已高亮正常区间。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(from, to)`](#init) | 以数据坐标的两个 y 值创建条带，端点顺序任意。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`draw(canvas, projection, theme)`](#draw) | 在绘图区整宽上填充从 `from` 到 `to` 的矩形。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`color`](#color) | 条带颜色，绘制时按 `opacity` 淡化；`None` 用主题强调色。 |
| [`opacity`](#opacity) | 填充不透明度，取值 `0..1`，默认 `0.12`。 |

## 构造函数

### init

以数据坐标的两个 y 值创建条带，端点顺序任意。两个端点构造后不可更改。

```cangjie
public init(from: Float64, to: Float64)
```

**参数**

- `from`: `Float64` — 条带一端的 y 值（数据坐标）。
- `to`: `Float64` — 条带另一端的 y 值（数据坐标）；小于 `from` 也可，绘制时自动取序。

## 方法

### draw

在绘图区整宽上填充从 `from` 到 `to` 的矩形。填充色为 `color`（或主题强调色）按 `opacity` 淡化后的结果。

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

填充不透明度，取值 `0..1`，默认 `0.12`。

```cangjie
public var opacity: Float64 = 0.12
```

## 另请参阅

- [VerticalSpan](VerticalSpan.md) — x 方向的着色条带（带说明文字）
- [HorizontalLine](HorizontalLine.md) — 单个 y 值处的参考线
- [Annotation](Annotation.md)、[Axes.annotate](Axes.md#annotate)
