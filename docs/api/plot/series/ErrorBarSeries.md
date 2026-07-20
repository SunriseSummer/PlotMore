[plot](../../index.md) › [plot.series](index.md) › ErrorBarSeries

# ErrorBarSeries

`plot.series` 中的 public class

在 y、x 或两个方向上带误差棒的数据点。误差以半宽给出——从数据点到误差棒一端的距离——这正是标准差或标准误本来的形式；不对称区间用 `setYErrorRange` / `setXErrorRange`，其两个数组分别是向下（向左）与向上（向右）的距离。

## 声明

```cangjie
public class ErrorBarSeries <: Series
```

## 继承

- 父类：[Series](Series.md)

## 说明

缺失或非有限的误差按「没有误差」处理：既不画那根误差棒，也不会在自动适配中产生 NaN 端点。误差棒本身属于绘制范围，因此 `dataBounds` 覆盖到每根误差棒的两端，而不只是数据点。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.series.ErrorBarSeries

main(): Unit {
    // 四个剂量组的平均响应与标准误（半宽）
    let dose = [1.0, 2.0, 3.0, 4.0]
    let response = [2.0, 3.5, 5.0, 6.5]
    let sem = [0.25, 0.5, 0.25, 0.5]

    let trial = ErrorBarSeries(dose, response, label: "试验 A")
    trial.setYError(sem)
    trial.connect = true    // 除标记外再连线
    trial.capSize = 5.0

    let (figure, axes) = Figure.single(title: "剂量反应")
    axes.add(trial)

    FigureExport.renderToPng(figure, "error-bars.png", width: 800, height: 600)

    // 自动适配覆盖误差棒端点：2.0 - 0.25 到 6.5 + 0.5
    match (trial.dataBounds()) {
        case Some((_, ybounds)) => println("y 区间: ${ybounds}")
        case None => println("无数据")
    }
    // 输出: y 区间: Bounds(1.750000, 7.000000)
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建误差棒系列；`xs` 与 `ys` 一一配对。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`setYError(...)`](#setyerror) | 设置对称的 y 不确定度：每根误差棒从 `y - e` 延伸到 `y + e`。 |
| [`setYErrorRange(...)`](#setyerrorrange) | 设置不对称的 y 不确定度：每根误差棒从 `y - below` 延伸到 `y + above`。 |
| [`setXError(...)`](#setxerror) | 设置对称的 x 不确定度。 |
| [`setXErrorRange(...)`](#setxerrorrange) | 设置不对称的 x 不确定度。 |
| [`dataBounds()`](#databounds) | 返回把每根误差棒两端都并入后的 x、y 区间。 |
| [`draw(...)`](#draw) | 逐点绘制误差棒、端帽与中心标记；`connect` 开启时先连线。 |
| [`legend(...)`](#legend) | 返回一条画成竖直误差棒加中心标记的图例条目。 |
| [`hitTest(...)`](#hittest) | 返回像素空间中最接近 `(px, py)` 的数据点；没有可表达的点时为 `None`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`marker`](#marker) | 每个数据点处的符号。 |
| [`markerSize`](#markersize) | 标记半径（逻辑像素）；`None` 跟随 `theme.markerSize`。 |
| [`barWidth`](#barwidth) | 误差棒线宽（逻辑像素）。 |
| [`capSize`](#capsize) | 误差棒两端垂直端帽的半长（像素）；`0` 不画端帽。 |
| [`connect`](#connect) | 除标记外再用线依次连接各数据点。 |
| [`lineStyle`](#linestyle) | `connect` 开启时连线的线型。 |

## 构造函数

### init

创建误差棒系列；`xs` 与 `ys` 一一配对。构造后没有任何误差，需再调用 `setYError` 等方法设置。

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

### setYError

设置对称的 y 不确定度：每根误差棒从 `y - e` 延伸到 `y + e`。

```cangjie
public func setYError(errors: Array<Float64>): Unit
```

**参数**

- `errors`: `Array<Float64>` — 每点一个的半宽，须与点数等长；非有限的元素视为该点无误差棒。

**异常**

- `PlotException` — `errors` 长度与点数不同时。

### setYErrorRange

设置不对称的 y 不确定度：每根误差棒从 `y - below` 延伸到 `y + above`。

```cangjie
public func setYErrorRange(below: Array<Float64>, above: Array<Float64>): Unit
```

**参数**

- `below`: `Array<Float64>` — 每点向下的距离，须与点数等长。
- `above`: `Array<Float64>` — 每点向上的距离，须与点数等长。

**异常**

- `PlotException` — 任一数组长度与点数不同时。

### setXError

设置对称的 x 不确定度。

```cangjie
public func setXError(errors: Array<Float64>): Unit
```

**参数**

- `errors`: `Array<Float64>` — 每点一个的半宽，须与点数等长。

**异常**

- `PlotException` — `errors` 长度与点数不同时。

### setXErrorRange

设置不对称的 x 不确定度。

```cangjie
public func setXErrorRange(below: Array<Float64>, above: Array<Float64>): Unit
```

**参数**

- `below`: `Array<Float64>` — 每点向左的距离，须与点数等长。
- `above`: `Array<Float64>` — 每点向右的距离，须与点数等长。

**异常**

- `PlotException` — 任一数组长度与点数不同时。

### dataBounds

返回把每根误差棒两端都并入后的 x、y 区间。自动适配必须覆盖误差棒而不只是数据点，否则端帽会在面板边缘被裁掉；缺失或非有限的误差按 `0` 计。任一坐标非有限的数据点整体跳过；没有有限点时为 `None`。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — 数据坐标下的 (x 区间, y 区间)，或 `None`。

### draw

逐点绘制误差棒、端帽与中心标记；`connect` 开启时先连线。只有设置过对应方向误差的点才画那一方向的误差棒；投影无法表达的点被跳过。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标。
- `projection`: `Projection` — 数据坐标到像素坐标的变换。
- `theme`: `Theme` — 提供默认标记大小、连线宽度与颜色。

### legend

返回一条画成竖直误差棒加中心标记的图例条目。`label` 为空时为空数组。

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

### marker

每个数据点处的符号。取值见 [MarkerStyle](../canvas/MarkerStyle.md)。

```cangjie
public var marker: MarkerStyle = MarkerStyle.Circle
```

### markerSize

标记半径（逻辑像素）；`None` 跟随 `theme.markerSize`。

```cangjie
public var markerSize: ?Float32 = None
```

### barWidth

误差棒线宽（逻辑像素）。

```cangjie
public var barWidth: Float32 = 1.3
```

### capSize

误差棒两端垂直端帽的半长（像素）；`0` 不画端帽。

```cangjie
public var capSize: Float32 = 4.0
```

### connect

除标记外再用线依次连接各数据点。

```cangjie
public var connect: Bool = false
```

### lineStyle

`connect` 开启时连线的线型。取值见 [LineStyle](../canvas/LineStyle.md)。

```cangjie
public var lineStyle: LineStyle = LineStyle.Solid
```

## 另请参阅

- [LineSeries](LineSeries.md) — 无不确定度信息的折线
- [AreaSeries](AreaSeries.md) — 用条带而非误差棒表达区间
