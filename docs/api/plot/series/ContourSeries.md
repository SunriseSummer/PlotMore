[plot](../../index.md) › [plot.series](index.md) › ContourSeries

# ContourSeries

`plot.series` 中的 public class

用行进方格（marching squares）在二维标量场上追踪等值线的系列。每个单元格独立检查，边上的等值穿越点连成短线段——逐格精确、无全局记账；代价是产出松散线段而非连续闭合路径，这对绘制不可见，也是这里没有路径拼接环节的原因。

## 声明

```cangjie
public class ContourSeries <: Series
```

## 继承

- 父类型：[Series](Series.md)

## 说明

- 鞍点歧义：对角两角高于等值、另两角低于时，穿越点有两种连法，网格本身无法裁决。实现按中心平均规则选择连法：比较单元格四角均值与当前等值。
- 触及非有限值的单元格无法插值，如实留空。
- [fillsExtent()](#fillsextent) 为 `true`：场恰好覆盖构造时给定的矩形，坐标区不再加自动适配余量。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.core.Bounds
import plot.series.ContourSeries

main(): Unit {
    let xr = Bounds(-1.0, 1.0)
    let yr = Bounds(-1.0, 1.0)
    // f 是最后一个形参，可用尾随 lambda 形式；这里是同心圆场
    let rings = ContourSeries.fromFunction(60, 60, xr, yr) {x, y => x * x + y * y}
    rings.setLevels([0.25, 0.5, 0.75])

    let (figure, axes) = Figure.single(title: "等值线")
    axes.add(rings)

    FigureExport.renderToPng(figure, "contours.png", width: 800, height: 600)

    println(rings.levels().size) // 输出: 3
    println(rings.trace(0.25).size > 0) // 输出: true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 以行主序的网格值构造等值线系列。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static fromFunction(...)`](#fromfunction) | 在网格上采样函数 `f` 构建等值线系列。 |
| [`setLevels(...)`](#setlevels) | 固定要追踪的等值。 |
| [`levels()`](#levels) | 实际使用的等值——固定值，或跨场值范围放置的约 `levelCount` 个整值刻度。 |
| [`value(...)`](#value) | 网格点的值。 |
| [`dataBounds()`](#databounds) | 恒为构造时给定的 `xRange` 与 `yRange`。 |
| [`fillsExtent()`](#fillsextent) | 恒为 `true`：场恰好覆盖其矩形，自动适配不再加余量。 |
| [`draw(...)`](#draw) | 逐等值追踪并绘制线段。 |
| [`legend(...)`](#legend) | 本系列贡献的图例条目；标签为空时为空数组。 |
| [`trace(...)`](#trace) | `level` 的全部穿越线段，数据坐标下的 `(x1, y1, x2, y2)`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`levelCount`](#levelcount) | 未显式设置等值时自动放置的等值数量目标。 |
| [`lineWidth`](#linewidth) | 等值线宽度，单位逻辑像素。 |
| [`map`](#map) | 按等值高低经色标取线色；`None` 时全部线条用系列颜色。 |
| [`showLabels`](#showlabels) | 在每个等值的第一条线段旁打印其数值。 |

## 构造函数

### init

以行主序的网格值构造等值线系列。

```cangjie
public init(values: Array<Float64>, rows!: Int64, columns!: Int64, xRange!: Bounds, yRange!: Bounds, label!: String = "")
```

**参数**

- `values`: `Array<Float64>` — 网格点的值，行主序，长度必须恰为 `rows * columns`。
- `rows`: `Int64` — 行数，至少 2。
- `columns`: `Int64` — 列数，至少 2。
- `xRange`: [`Bounds`](../core/Bounds.md) — 网格覆盖的数据 x 区间。
- `yRange`: `Bounds` — 网格覆盖的数据 y 区间。
- `label`: `String` — 图例标签；空串（默认）时系列不进入图例。

**异常**

- [`PlotException`](../core/PlotException.md) — 网格小于 2×2（行进方格至少需要一个单元格），或 `values` 的数量不为 `rows * columns` 时。

## 方法

### fromFunction

在网格上采样函数 `f` 构建等值线系列。这是为解析场画等值线的常用方式；`f` 是最后一个形参，因此可用仓颉的尾随 lambda 形式：`ContourSeries.fromFunction(60, 60, xr, yr) { x, y => x * y }`。在返回的系列上设置 `label`。

```cangjie
public static func fromFunction(rows: Int64, columns: Int64, xRange: Bounds, yRange: Bounds, f: (Float64, Float64) -> Float64): ContourSeries
```

**参数**

- `rows`: `Int64` — 行数，至少 2。
- `columns`: `Int64` — 列数，至少 2。
- `xRange`: `Bounds` — 采样的 x 区间；网格列均匀分布其上（含两端）。
- `yRange`: `Bounds` — 采样的 y 区间；网格行均匀分布其上（含两端）。
- `f`: `(Float64, Float64) -> Float64` — 被采样的函数，实参为数据坐标 (x, y)。

**返回值** `ContourSeries` — 已填好网格值的系列。

**异常**

- `PlotException` — 网格小于 2×2 时。

### setLevels

固定要追踪的等值。

```cangjie
public func setLevels(levels: Array<Float64>): Unit
```

**参数**

- `levels`: `Array<Float64>` — 等值列表，按给定顺序绘制。

**异常**

- `PlotException` — `levels` 为空时。

### levels

实际使用的等值——固定值，或跨场值范围放置的约 `levelCount` 个整值刻度。自动等值取自 [Ticks](../core/Ticks.md) 的主刻度并排除两端极值（等值线在极值处退化成点）；整值刻度全被排除时退回均匀内插，没有有限数据时为空数组。

```cangjie
public func levels(): Array<Float64>
```

**返回值** `Array<Float64>` — 生效的等值。

### value

网格点的值。

```cangjie
public func value(row: Int64, column: Int64): Float64
```

**参数**

- `row`: `Int64` — 行序号，从 0 开始。
- `column`: `Int64` — 列序号，从 0 开始。

**返回值** `Float64` — 该网格点存储的值。

### dataBounds

恒为构造时给定的 `xRange` 与 `yRange`。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — (x 区间, y 区间)，恒为 `Some`。

### fillsExtent

恒为 `true`：场恰好覆盖其矩形，自动适配不再加余量。

```cangjie
public override func fillsExtent(): Bool
```

**返回值** `Bool` — 恒为 `true`。

### draw

逐等值追踪并绘制线段。未设 `map` 时低等值按序淡出以保持嵌套层次可读；`showLabels` 开启时每个等值只在其第一条线段处标注一次。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 绘制目标。
- `projection`: [`Projection`](../core/Projection.md) — 数据坐标到像素坐标的投影。
- `theme`: [`Theme`](../core/Theme.md) — 颜色与标注字号来源。

### legend

本系列贡献的图例条目；标签为空时为空数组。色样画成两个嵌套圆环——比直线更能读作等值线；设有色标时圆环取色标采样。

```cangjie
public override func legend(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 颜色来源。

**返回值** `Array<`[`LegendEntry`](LegendEntry.md)`>` — 至多一个条目。

### trace

`level` 的全部穿越线段，数据坐标下的 `(x1, y1, x2, y2)`。公开它是为了能直接测试：等值线的正确性在渲染出的图里不可见，直到它错得看似合理。

```cangjie
public func trace(level: Float64): ArrayList<(Float64, Float64, Float64, Float64)>
```

**参数**

- `level`: `Float64` — 要追踪的等值。

**返回值** `ArrayList<(Float64, Float64, Float64, Float64)>` — 松散线段的列表，不保证连成路径。

## 字段

### levelCount

未显式设置等值时自动放置的等值数量目标。默认 `8`。

```cangjie
public var levelCount: Int64 = 8
```

### lineWidth

等值线宽度，单位逻辑像素。默认 `1.4`。

```cangjie
public var lineWidth: Float32 = 1.4
```

### map

按等值高低经色标取线色；`None` 时全部线条用系列颜色。默认 `None`——此时低等值按序淡出，让嵌套层次仍然可读。色标类型见 [Colormap](../core/Colormap.md)。

```cangjie
public var map: ?Colormap = None
```

### showLabels

在每个等值的第一条线段旁打印其数值。默认 `false`——逐段标注会把场埋进文字里。

```cangjie
public var showLabels: Bool = false
```

## 另请参阅

- [HeatmapSeries](HeatmapSeries.md)
- [Colormap](../core/Colormap.md)
- [Ticks](../core/Ticks.md)
