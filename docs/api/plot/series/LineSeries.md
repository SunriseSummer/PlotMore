[plot](../../index.md) › [plot.series](index.md) › LineSeries

# LineSeries

`plot.series` 中的 public class

经过一组 `(x, y)` 数据点的折线，可选带标记，也可选填充到基线。非有限的点把折线断成独立的段而不是被跨接，数据中的缺口保持为缺口；坐标轴无法表达的点——对数轴上的零或负值——同样断开。

## 声明

```cangjie
public class LineSeries <: Series
```

## 继承

- 父类：[Series](Series.md)

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.canvas.MarkerStyle
import plot.series.LineSeries

main(): Unit {
    // 一天内每 4 小时的 CPU 负载采样
    let hours = [0.0, 4.0, 8.0, 12.0, 16.0, 20.0]
    let load = [0.32, 0.28, 0.55, 0.74, 0.68, 0.41]
    let series = LineSeries(hours, load, label: "CPU 负载")
    series.marker = MarkerStyle.Circle
    series.fillTo = Some(0.0) // 面积图形态：填充到基线 0
    series.fillOpacity = 0.25

    let (figure, axes) = Figure.single(title: "CPU 负载")
    axes.add(series)

    FigureExport.renderToPng(figure, "line-series.png", width: 800, height: 600)
    println("点数: ${series.xValues().size}") // 输出: 点数: 6
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建折线系列；`xs` 与 `ys` 一一配对。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`xValues()`](#xvalues) | 返回构造时传入的 x 坐标数组。 |
| [`yValues()`](#yvalues) | 返回构造时传入的 y 坐标数组。 |
| [`dataBounds()`](#databounds) | 返回有限数据点的 x、y 区间；设置了 `fillTo` 时把基线并入 y 区间。 |
| [`draw(...)`](#draw) | 把数据点拆成可绘制的段，逐段绘制填充、折线与标记。 |
| [`legend(...)`](#legend) | 返回一条与面板画法一致的图例条目：线型、标记与填充示意。 |
| [`hitTest(...)`](#hittest) | 返回像素空间中最接近 `(px, py)` 的数据点；没有可表达的点时为 `None`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`style`](#style) | 连线的线型；`NoLine` 只留标记。 |
| [`marker`](#marker) | 每个数据点处的符号；默认 `NoMarker`，密集折线不带标记更清晰。 |
| [`width`](#width) | 线宽（逻辑像素）；`None` 跟随 `theme.lineWidth`。 |
| [`markerSize`](#markersize) | 标记半径（逻辑像素）；`None` 跟随 `theme.markerSize`。 |
| [`fillTo`](#fillto) | 设置后在折线与该基线之间填充——折线的面积图形态。 |
| [`fillOpacity`](#fillopacity) | 面积填充在折线一侧的不透明度，向基线一侧渐隐到 `fillFadeOpacity`。 |
| [`fillFadeOpacity`](#fillfadeopacity) | 面积填充在基线一侧的不透明度；低于 `fillOpacity` 即形成渐隐。 |
| [`markerEvery`](#markerevery) | 每隔多少个点画一个标记，保持密集系列可读；`1` 为每点都画。 |
| [`smooth`](#smooth) | 用向心 Catmull-Rom 样条代替直线段圆滑折线；默认关闭。 |

## 构造函数

### init

创建折线系列；`xs` 与 `ys` 一一配对。

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

返回有限数据点的 x、y 区间；设置了 `fillTo` 时把基线并入 y 区间。填充会一直画到基线，基线属于绘制范围，因此自动适配必须覆盖它。没有有限点时为 `None`。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — 数据坐标下的 (x 区间, y 区间)，或 `None`。

### draw

把数据点拆成可绘制的段，逐段绘制填充、折线与标记。分段规则见 [plottableRuns](functions.md#plottableruns)；`smooth` 开启时每段先经样条重采样，标记按 `markerEvery` 间隔绘制。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标。
- `projection`: `Projection` — 数据坐标到像素坐标的变换。
- `theme`: `Theme` — 提供默认线宽、标记大小与颜色。

### legend

返回一条与面板画法一致的图例条目：线型、标记与填充示意。`label` 为空时为空数组。

```cangjie
public override func legend(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 用于解析颜色与默认尺寸。

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

### style

连线的线型；`NoLine` 只留标记。取值见 [LineStyle](../canvas/LineStyle.md)。

```cangjie
public var style: LineStyle = LineStyle.Solid
```

### marker

每个数据点处的符号；默认 `NoMarker`，密集折线不带标记更清晰。取值见 [MarkerStyle](../canvas/MarkerStyle.md)。

```cangjie
public var marker: MarkerStyle = MarkerStyle.NoMarker
```

### width

线宽（逻辑像素）；`None` 跟随 `theme.lineWidth`。

```cangjie
public var width: ?Float32 = None
```

### markerSize

标记半径（逻辑像素）；`None` 跟随 `theme.markerSize`。

```cangjie
public var markerSize: ?Float32 = None
```

### fillTo

设置后在折线与该基线之间填充——折线的面积图形态。同时使 `dataBounds` 把基线并入 y 区间。

```cangjie
public var fillTo: ?Float64 = None
```

### fillOpacity

面积填充在折线一侧的不透明度，向基线一侧渐隐到 `fillFadeOpacity`。

```cangjie
public var fillOpacity: Float64 = 0.22
```

### fillFadeOpacity

面积填充在基线一侧的不透明度；低于 `fillOpacity` 即形成渐隐。

```cangjie
public var fillFadeOpacity: Float64 = 0.02
```

### markerEvery

每隔多少个点画一个标记，保持密集系列可读；`1` 为每点都画。小于 `1` 的值按 `1` 处理。

```cangjie
public var markerEvery: Int64 = 1
```

### smooth

用向心 Catmull-Rom 样条代替直线段圆滑折线；默认关闭。且有意如此：平滑会在采样点之间发明数据，只应在展示真正连续的信号时开启，不适用于稀疏测量。向心参数化（指数 0.5）是不会在控制点之间产生尖角或自交的变体。

```cangjie
public var smooth: Bool = false
```

## 另请参阅

- [ScatterSeries](ScatterSeries.md) — 只画点不连线
- [StepSeries](StepSeries.md) — 分段常值的折线
- [AreaSeries](AreaSeries.md) — 以填充为主体的面积系列
