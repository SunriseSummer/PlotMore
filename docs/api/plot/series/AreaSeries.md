[plot](../../index.md) › [plot.series](index.md) › AreaSeries

# AreaSeries

`plot.series` 中的 public class

系列与基线之间、或两条边界之间的填充区域。`AreaSeries(xs, ys)` 从曲线向下填充到基线；[between](#between) 填充两条曲线之间的条带——置信区间、最值包络、公差带。多层堆叠是 [AreaStack](AreaStack.md) 的职责，因为堆叠中每层的基线取决于相邻层。

## 声明

```cangjie
public class AreaSeries <: Series
```

## 继承

- 父类：[Series](Series.md)

## 说明

两种构造形态的默认外观不同：基线形态构造后 `fadeOpacity` 为 `0.04`，填充自曲线向基线渐隐；`between` 构造的条带保持 `fadeOpacity` 的字段默认值 `0.3`，且 `showEdge` 为 `false`——条带没有单独属于自己的那条曲线可描。

绘制时，任一边界不可表达（非有限，或对数轴无法表达）的位置会把条带断开成独立的段，数据缺口保持为缺口。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.series.AreaSeries

main(): Unit {
    let days = [1.0, 2.0, 3.0, 4.0, 5.0]

    // 形态一：从曲线填充到基线 0
    let visits = AreaSeries(days, [120.0, 180.0, 150.0, 210.0, 190.0], label: "访问量")
    visits.fillOpacity = 0.35

    // 形态二：两条边界之间的条带（如预测区间）
    let forecast = AreaSeries.between(days, [100.0, 150.0, 130.0, 180.0, 160.0], [140.0, 210.0, 175.0, 240.0, 220.0],
        label: "预测区间")

    let (figure, axes) = Figure.single(title: "访问量")
    axes.add(forecast)
    axes.add(visits)

    FigureExport.renderToPng(figure, "area-series.png", width: 800, height: 600)
    println("系列数: ${axes.allSeries().size}") // 输出: 系列数: 2
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建从曲线填充到 `baseline` 的面积系列。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static between(...)`](#between) | 创建两条边界之间的条带。 |
| [`xValues()`](#xvalues) | 返回构造时传入的 x 坐标数组。 |
| [`upperValues()`](#uppervalues) | 返回上边界的各点数值。 |
| [`lowerValues()`](#lowervalues) | 返回下边界的各点数值。 |
| [`dataBounds()`](#databounds) | 返回覆盖两条边界的 x、y 区间；上下关系逐点判断。 |
| [`draw(...)`](#draw) | 逐段填充条带，`showEdge` 时描出上边界。 |
| [`legend(...)`](#legend) | 返回一个按填充不透明度着色的色块条目，`showEdge` 时附上边界线。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`fillOpacity`](#fillopacity) | 上边缘处的填充不透明度，`0..1`。 |
| [`fadeOpacity`](#fadeopacity) | 下边缘处的填充不透明度；低于 `fillOpacity` 即形成渐隐。 |
| [`showEdge`](#showedge) | 描出上边界，让系列自己的曲线在填充之上保持清晰。 |
| [`edgeWidth`](#edgewidth) | 边界线宽（逻辑像素）；`None` 跟随 `theme.lineWidth`。 |

## 构造函数

### init

创建从曲线填充到 `baseline` 的面积系列。构造后 `fadeOpacity` 为 `0.04`，填充向基线一侧渐隐。

```cangjie
public init(xs: Array<Float64>, ys: Array<Float64>, baseline!: Float64 = 0.0, label!: String = "")
```

**参数**

- `xs`: `Array<Float64>` — x 坐标。
- `ys`: `Array<Float64>` — 曲线各点数值（作为上边界），须与 `xs` 等长。
- `baseline!`: `Float64` — 填充到的基准值，默认 `0.0`；在每个 x 处作为下边界。
- `label!`: `String` — 图例标签，默认空（不进入图例）。

**异常**

- `PlotException` — `xs` 与 `ys` 长度不同时。

## 方法

### between

创建两条边界之间的条带。构造出的系列 `showEdge` 为 `false`。

```cangjie
public static func between(
    xs: Array<Float64>,
    lower: Array<Float64>,
    upper: Array<Float64>,
    label!: String = ""
): AreaSeries
```

**参数**

- `xs`: `Array<Float64>` — x 坐标。
- `lower`: `Array<Float64>` — 下边界各点数值，须与 `xs` 等长。
- `upper`: `Array<Float64>` — 上边界各点数值，须与 `xs` 等长。
- `label!`: `String` — 图例标签，默认空（不进入图例）。

**返回值** `AreaSeries` — 两条边界之间的条带系列。

**异常**

- `PlotException` — 三个数组长度不一致时。

### xValues

返回构造时传入的 x 坐标数组。

```cangjie
public func xValues(): Array<Float64>
```

**返回值** `Array<Float64>` — 原始 x 坐标，未复制。

### upperValues

返回上边界的各点数值。基线形态下即构造时的 `ys`。

```cangjie
public func upperValues(): Array<Float64>
```

**返回值** `Array<Float64>` — 上边界数值。

### lowerValues

返回下边界的各点数值。基线形态下是与 `xs` 等长、每个元素都为 `baseline` 的数组。

```cangjie
public func lowerValues(): Array<Float64>
```

**返回值** `Array<Float64>` — 下边界数值。

### dataBounds

返回覆盖两条边界的 x、y 区间；上下关系逐点判断。每个位置取 `upper[i]` 与 `lower[i]` 的较大与较小者并入 y 区间，因此两条边界交叉也不会漏掉范围；x、上边界或下边界任一非有限的位置整体跳过。没有有限点时为 `None`。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — 数据坐标下的 (x 区间, y 区间)，或 `None`。

### draw

逐段填充条带，`showEdge` 时描出上边界。任一边界不可表达的位置把条带断开成独立的段；填充自上边缘的 `fillOpacity` 渐变到下边缘的 `fadeOpacity`。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标。
- `projection`: `Projection` — 数据坐标到像素坐标的变换。
- `theme`: `Theme` — 提供默认边界线宽与颜色。

### legend

返回一个按填充不透明度着色的色块条目，`showEdge` 时附上边界线。`label` 为空时为空数组。

```cangjie
public override func legend(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 用于解析颜色与默认线宽。

**返回值** `Array<LegendEntry>` — 至多一个条目。

## 字段

### fillOpacity

上边缘处的填充不透明度，`0..1`。

```cangjie
public var fillOpacity: Float64 = 0.3
```

### fadeOpacity

下边缘处的填充不透明度；低于 `fillOpacity` 即形成渐隐。字段默认 `0.3`；基线形态的构造函数把它设为 `0.04`。

```cangjie
public var fadeOpacity: Float64 = 0.3
```

### showEdge

描出上边界，让系列自己的曲线在填充之上保持清晰。默认 `true`；`between` 构造的条带为 `false`。

```cangjie
public var showEdge: Bool = true
```

### edgeWidth

边界线宽（逻辑像素）；`None` 跟随 `theme.lineWidth`。

```cangjie
public var edgeWidth: ?Float32 = None
```

## 另请参阅

- [AreaStack](AreaStack.md) — 把多层面积逐层堆叠
- [LineSeries](LineSeries.md) — `fillTo` 提供的轻量面积形态
