[plot](../../index.md) › [plot.series](index.md) › StepSeries

# StepSeries

`plot.series` 中的 public class

分段常值的折线，忠实呈现在采样点之间保持数值而非滑动过渡的量：计数器、离散状态、区间内固定的速率。改变水平值的位置由 [StepWhere](StepWhere.md) 约定；非有限的点与坐标轴无法表达的点把台阶断成独立的段，缺口保持为缺口。

## 声明

```cangjie
public class StepSeries <: Series
```

## 继承

- 父类：[Series](Series.md)

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.series.{StepSeries, StepWhere}

main(): Unit {
    // 每分钟累计完成的任务数：数值在采样点之间保持不变
    let minutes = [0.0, 1.0, 2.0, 3.0, 4.0]
    let done = [0.0, 3.0, 3.0, 7.0, 9.0]
    let progress = StepSeries(minutes, done, label: "完成任务数")
    progress.changeAt = StepWhere.Post
    progress.fillTo = Some(0.0)   // 台阶下方填充到基线 0

    let (figure, axes) = Figure.single(title: "完成任务数")
    axes.add(progress)

    FigureExport.renderToPng(figure, "step-series.png", width: 800, height: 600)
    println("采样点数: ${progress.xValues().size}") // 输出: 采样点数: 5
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建阶梯系列；`xs` 与 `ys` 一一配对。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`xValues()`](#xvalues) | 返回构造时传入的 x 坐标数组。 |
| [`yValues()`](#yvalues) | 返回构造时传入的 y 坐标数组。 |
| [`dataBounds()`](#databounds) | 返回有限数据点的 x、y 区间；设置了 `fillTo` 时把基线并入 y 区间。 |
| [`draw(...)`](#draw) | 按 `changeAt` 约定把采样点展开成台阶折线后逐段绘制。 |
| [`legend(...)`](#legend) | 返回一条画成微型台阶的图例条目，表明「分段常值」而非普通折线。 |
| [`hitTest(...)`](#hittest) | 返回像素空间中最接近 `(px, py)` 的采样点；没有可表达的点时为 `None`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`changeAt`](#changeat) | 相邻采样点之间改变水平值的位置。 |
| [`style`](#style) | 台阶线的线型。 |
| [`marker`](#marker) | 每个采样点处的符号；默认 `NoMarker`。 |
| [`width`](#width) | 线宽（逻辑像素）；`None` 跟随 `theme.lineWidth`。 |
| [`fillTo`](#fillto) | 设置后在台阶与该基线之间填充。 |
| [`fillOpacity`](#fillopacity) | 台阶一侧的填充不透明度。 |

## 构造函数

### init

创建阶梯系列；`xs` 与 `ys` 一一配对。

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

### xValues

返回构造时传入的 x 坐标数组。

```cangjie
public func xValues(): Array<Float64>
```

**返回值** `Array<Float64>` — 原始 x 坐标，未复制。

### yValues

返回构造时传入的 y 坐标数组。

```cangjie
public func yValues(): Array<Float64>
```

**返回值** `Array<Float64>` — 原始 y 坐标，未复制。

### dataBounds

返回有限数据点的 x、y 区间；设置了 `fillTo` 时把基线并入 y 区间。没有有限点时为 `None`。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — 数据坐标下的 (x 区间, y 区间)，或 `None`。

### draw

按 `changeAt` 约定把采样点展开成台阶折线后逐段绘制。分段规则与折线相同（见 [plottableRuns](functions.md#plottableruns)）：非有限的点、对数轴无法表达的点都会断开台阶；设置了 `fillTo` 时先填充台阶与基线之间的条带。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标。
- `projection`: `Projection` — 数据坐标到像素坐标的变换。
- `theme`: `Theme` — 提供默认线宽、标记大小与颜色。

### legend

返回一条画成微型台阶的图例条目，表明「分段常值」而非普通折线。`label` 为空时为空数组。

```cangjie
public override func legend(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 用于解析颜色与默认线宽。

**返回值** `Array<LegendEntry>` — 至多一个条目。

### hitTest

返回像素空间中最接近 `(px, py)` 的采样点；没有可表达的点时为 `None`。命中对象是采样点本身，不是台阶边沿。

```cangjie
public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult
```

**参数**

- `px`: `Float32` — 光标像素横坐标。
- `py`: `Float32` — 光标像素纵坐标。
- `projection`: `Projection` — 数据坐标到像素坐标的变换。
- `theme`: `Theme` — 用于解析结果中的系列颜色。

**返回值** `?HitResult` — 最近采样点的命中结果，或 `None`。

## 字段

### changeAt

相邻采样点之间改变水平值的位置。取值见 [StepWhere](StepWhere.md)。

```cangjie
public var changeAt: StepWhere = StepWhere.Post
```

### style

台阶线的线型。取值见 [LineStyle](../canvas/LineStyle.md)。

```cangjie
public var style: LineStyle = LineStyle.Solid
```

### marker

每个采样点处的符号；默认 `NoMarker`。取值见 [MarkerStyle](../canvas/MarkerStyle.md)。

```cangjie
public var marker: MarkerStyle = MarkerStyle.NoMarker
```

### width

线宽（逻辑像素）；`None` 跟随 `theme.lineWidth`。

```cangjie
public var width: ?Float32 = None
```

### fillTo

设置后在台阶与该基线之间填充。同时使 `dataBounds` 把基线并入 y 区间。

```cangjie
public var fillTo: ?Float64 = None
```

### fillOpacity

台阶一侧的填充不透明度。

```cangjie
public var fillOpacity: Float64 = 0.18
```

## 另请参阅

- [StepWhere](StepWhere.md) — 三种台阶改变位置的约定
- [LineSeries](LineSeries.md) — 采样点之间线性过渡的折线
- [StemSeries](StemSeries.md) — 只强调采样点本身的茎干图
