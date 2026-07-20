[plot](../../index.md) › [plot.series](index.md) › StemSeries

# StemSeries

`plot.series` 中的 public class

从基线竖直伸到每个数据点、顶端带标记的茎干图——折线的离散信号对应物：样本本身是数据，样本之间的空隙不是。

## 声明

```cangjie
public class StemSeries <: Series
```

## 继承

- 父类：[Series](Series.md)

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.series.StemSeries

main(): Unit {
    // 离散信号的采样值：样本之间没有数据，茎干强调这一点
    let n = [0.0, 1.0, 2.0, 3.0, 4.0]
    let amplitude = [3.0, 5.0, 2.0, 4.0, 1.0]
    let signal = StemSeries(n, amplitude, label: "采样值")
    signal.stemWidth = 2.0
    signal.markerSize = Some(4.5)

    let (figure, axes) = Figure.single(title: "离散信号")
    axes.add(signal)

    FigureExport.renderToPng(figure, "stem-series.png", width: 800, height: 600)

    // 基线 0 并入了 y 区间，即使所有样本都为正
    match (signal.dataBounds()) {
        case Some((_, ybounds)) => println("y 区间: ${ybounds}")
        case None => println("无数据")
    }
    // 输出: y 区间: Bounds(0.000000, 5.000000)
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建茎干系列；`xs` 与 `ys` 一一配对。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`dataBounds()`](#databounds) | 返回有限数据点的 x、y 区间，并把 `baseline` 并入 y 区间。 |
| [`draw(...)`](#draw) | 绘制基线（可选）、每个点的茎干与顶端标记。 |
| [`legend(...)`](#legend) | 返回一条画成竖直茎干加顶端标记的图例条目。 |
| [`hitTest(...)`](#hittest) | 返回像素空间中最接近 `(px, py)` 的数据点；没有可表达的点时为 `None`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`baseline`](#baseline) | 茎干升起的基准值。 |
| [`marker`](#marker) | 茎干顶端的符号。 |
| [`stemWidth`](#stemwidth) | 茎干线宽（逻辑像素）。 |
| [`markerSize`](#markersize) | 标记半径（逻辑像素）；`None` 跟随 `theme.markerSize`。 |
| [`showBaseline`](#showbaseline) | 是否绘制基线本身。 |

## 构造函数

### init

创建茎干系列；`xs` 与 `ys` 一一配对。

```cangjie
public init(xs: Array<Float64>, ys: Array<Float64>, label!: String = "")
```

**参数**

- `xs`: `Array<Float64>` — x 坐标。
- `ys`: `Array<Float64>` — y 坐标，须与 `xs` 等长。
- `label!`: `String` — 图例标签，默认空（不进入图例）。

**异常**

- `PlotException` — `xs` 与 `ys` 长度不同时。

## 方法

### dataBounds

返回有限数据点的 x、y 区间，并把 `baseline` 并入 y 区间。茎干从基线画起，基线属于绘制范围，因此自动适配必须覆盖它。没有有限点时为 `None`。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — 数据坐标下的 (x 区间, y 区间)，或 `None`。

### draw

绘制基线（可选）、每个点的茎干与顶端标记。`showBaseline` 开启时先以主题的坐标轴颜色横贯面板画出基线；随后为每个投影可表达的点画一根从基线到该点的竖线并盖上标记，无法表达的点被跳过。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标。
- `projection`: `Projection` — 数据坐标到像素坐标的变换。
- `theme`: `Theme` — 提供基线颜色、默认标记大小与系列颜色。

### legend

返回一条画成竖直茎干加顶端标记的图例条目。`label` 为空时为空数组。

```cangjie
public override func legend(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 用于解析颜色与默认标记大小。

**返回值** `Array<LegendEntry>` — 至多一个条目。

### hitTest

返回像素空间中最接近 `(px, py)` 的数据点；没有可表达的点时为 `None`。

```cangjie
public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult
```

**参数**

- `px`: `Float32` — 光标像素横坐标。
- `py`: `Float32` — 光标像素纵坐标。
- `projection`: `Projection` — 数据坐标到像素坐标的变换。
- `theme`: `Theme` — 用于解析结果中的系列颜色。

**返回值** `?HitResult` — 最近点的命中结果，或 `None`。

## 字段

### baseline

茎干升起的基准值。

```cangjie
public var baseline: Float64 = 0.0
```

### marker

茎干顶端的符号。取值见 [MarkerStyle](../canvas/MarkerStyle.md)。

```cangjie
public var marker: MarkerStyle = MarkerStyle.Circle
```

### stemWidth

茎干线宽（逻辑像素）。

```cangjie
public var stemWidth: Float32 = 1.4
```

### markerSize

标记半径（逻辑像素）；`None` 跟随 `theme.markerSize`。

```cangjie
public var markerSize: ?Float32 = None
```

### showBaseline

是否绘制基线本身。开启时以主题的坐标轴颜色横贯整个面板画出。

```cangjie
public var showBaseline: Bool = true
```

## 另请参阅

- [StepSeries](StepSeries.md) — 采样点之间保持数值的阶梯折线
- [ScatterSeries](ScatterSeries.md) — 只画点、不画茎干
