[plot](../../index.md) › [plot.axes](index.md) › HorizontalLine

# HorizontalLine

`plot.axes` 中的 public class

固定 y 值处的水平参考线——上限、均值或目标。以数据坐标定位，横贯绘图区整宽，随缩放与平移跟着数据走；经 [Axes.annotate](Axes.md#annotate) 挂到面板上。

## 声明

```cangjie
public class HorizontalLine <: Annotation
```

## 继承

- 父类：[Annotation](Annotation.md)。

## 说明

参考线在全部系列之后绘制并被裁剪到面板内。y 标度无法表达构造时给定的值时（如对数轴上的零或负值），整条线跳过不画，而不是画在错误的位置。默认虚线，让参考读作标注而非数据。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.HorizontalLine
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "错误率")
    axes.yLabel = "错误率"
    axes.add(LineSeries([1.0, 2.0, 3.0, 4.0], [0.02, 0.05, 0.09, 0.04], label: "服务 A"))

    // 0.08 处的警戒线：默认虚线、主题次要文字色
    let limit = HorizontalLine(0.08)
    limit.label = "警戒值"
    axes.annotate(limit)

    FigureExport.renderToPng(figure, "horizontal-line.png", width: 800, height: 600)
    println(limit.label) // 输出: 警戒值
    // 生成的图像包含水平阈值线。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(value)`](#init) | 在数据坐标的 y = `value` 处创建参考线。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`draw(canvas, projection, theme)`](#draw) | 沿绘图区整宽绘制参考线；y 标度无法表达 `value` 时整体跳过。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`color`](#color) | 线条颜色；`None` 用主题的次要文字色。 |
| [`style`](#style) | 线型；默认 `Dashed`，让参考线读作标注而非数据。 |
| [`width`](#width) | 线宽，逻辑像素，默认 `1.4`。 |
| [`label`](#label) | 画在线条右端上方的可选说明；为空不绘制。 |

## 构造函数

### init

在数据坐标的 y = `value` 处创建参考线。该值构造后不可更改。

```cangjie
public init(value: Float64)
```

**参数**

- `value`: `Float64` — 参考线所在的 y 值（数据坐标）。

## 方法

### draw

沿绘图区整宽绘制参考线；y 标度无法表达 `value` 时整体跳过。`label` 非空时以同一颜色画在右端。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标，见 [Canvas](../canvas/Canvas.md)。
- `projection`: `Projection` — 面板当前的数据↔像素变换，见 [Projection](../core/Projection.md)。
- `theme`: `Theme` — `color` 为 `None` 时的取色来源，见 [Theme](../core/Theme.md)。

## 字段

### color

线条颜色；`None` 用主题的次要文字色。说明文字与线同色。

```cangjie
public var color: ?Color = None
```

### style

线型；默认 `Dashed`，让参考线读作标注而非数据。取值见 [LineStyle](../canvas/LineStyle.md)。

```cangjie
public var style: LineStyle = LineStyle.Dashed
```

### width

线宽，逻辑像素，默认 `1.4`。

```cangjie
public var width: Float32 = 1.4
```

### label

画在线条右端上方的可选说明；为空不绘制。

```cangjie
public var label: String = ""
```

## 另请参阅

- [VerticalLine](VerticalLine.md) — 竖直方向的参考线
- [HorizontalSpan](HorizontalSpan.md) — 一段 y 区间的着色条带
- [Annotation](Annotation.md)、[Axes.annotate](Axes.md#annotate)
