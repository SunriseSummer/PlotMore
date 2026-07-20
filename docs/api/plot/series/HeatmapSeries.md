[plot](../../index.md) › [plot.series](index.md) › HeatmapSeries

# HeatmapSeries

`plot.series` 中的 public class

规则网格上的二维标量场，经色标映射为色块矩阵。值按行主序存放：`value(row, column)` 位于网格位置 (column, row)，默认行 0 在*底部*，让 y 轴像其他图一样向上读；`originTop` 为天然是图像或矩阵的数据翻转这一约定。

## 声明

```cangjie
public class HeatmapSeries <: Series
```

## 继承

- 父类型：[Series](Series.md)

## 说明

- [fillsExtent()](#fillsextent) 为 `true`：网格恰好铺满自己的矩形，坐标区不再加自动适配余量——留白会在面板边缘围出一圈底色，读作缺数据而非页边距。
- 非有限的单元格不绘制，命中测试对它们返回 `None`——屏幕上没有对应色块可命中。
- [dataBounds()](#databounds) 在网格中心之外各延伸半个单元格，让最外圈单元格完整落在面板内。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.core.{Bounds, Colormap}
import plot.series.HeatmapSeries

main(): Unit {
    let xr = Bounds(0.0, 7.0)
    let yr = Bounds(0.0, 7.0)
    // f 是最后一个形参，因此可用尾随 lambda 形式采样乘法表
    let heat = HeatmapSeries.fromFunction(8, 8, xr, yr) { x, y => x * y }
    heat.map = Some(Colormap.magma())
    heat.showValues = true

    let (figure, axes) = Figure.single(title: "乘法表热图")
    axes.add(heat)

    FigureExport.renderToPng(figure, "heatmap.png", width: 800, height: 600)

    println(heat.value(7, 7)) // 输出: 49.000000
    println("${heat.resolvedValueRange()}") // 输出: Bounds(0.000000, 49.000000)
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 以行主序的网格值构造热力图。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static fromFunction(...)`](#fromfunction) | 在网格上采样函数 `f` 构建热力图。 |
| [`value(...)`](#value) | 网格单元格的值。 |
| [`rows()`](#rows) | 网格的行数。 |
| [`columns()`](#columns) | 网格的列数。 |
| [`resolvedValueRange()`](#resolvedvaluerange) | 实际映射到色标上的值域——固定的 `valueRange`，或对有限数据自动适配的范围。 |
| [`resolvedColormap(...)`](#resolvedcolormap) | 实际使用的色标——`map`，未设置时取主题的色标。 |
| [`dataBounds()`](#databounds) | 网格覆盖的数据区间，向外各延伸半个单元格。 |
| [`fillsExtent()`](#fillsextent) | 恒为 `true`：网格恰好铺满其矩形，自动适配不再加余量。 |
| [`draw(...)`](#draw) | 逐格填色绘制网格。 |
| [`legend(...)`](#legend) | 本系列贡献的图例条目；标签为空时为空数组。 |
| [`hitTest(...)`](#hittest) | 最近单元格的命中测试。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`map`](#map) | 色标；`None` 跟随主题的 `theme.colormap`。 |
| [`valueRange`](#valuerange) | 映射到色标两端的值域；`None` 时自动适配有限数据。 |
| [`originTop`](#origintop) | 把行 0 放在顶部（矩阵、图像风格）而非底部。 |
| [`cellGap`](#cellgap) | 单元格之间的像素间隙。 |
| [`cornerRadius`](#cornerradius) | 每个单元格的圆角，单位逻辑像素。 |
| [`showValues`](#showvalues) | 在每个单元格中央打印其数值，颜色自动取与格色对比的颜色。 |
| [`valueDecimals`](#valuedecimals) | `showValues` 的小数位数；`None` 时用紧凑格式。 |
| [`xRange`](#xrange) | 网格覆盖的数据 x 区间；`None` 时用 `0 .. columns-1`（按单元格中心）。 |
| [`yRange`](#yrange) | 网格覆盖的数据 y 区间；`None` 时用 `0 .. rows-1`（按单元格中心）。 |

## 构造函数

### init

以行主序的网格值构造热力图。

```cangjie
public init(values: Array<Float64>, rows!: Int64, columns!: Int64, label!: String = "")
```

**参数**

- `values`: `Array<Float64>` — 网格值，行主序，长度必须恰为 `rows * columns`；非有限的单元格留空。
- `rows`: `Int64` — 行数，须为正。
- `columns`: `Int64` — 列数，须为正。
- `label`: `String` — 图例标签；空串（默认）时系列不进入图例。

**异常**

- [`PlotException`](../core/PlotException.md) — 维度非正，或 `values` 的数量不为 `rows * columns` 时。

## 方法

### fromFunction

在网格上采样函数 `f` 构建热力图。这是场由解析式而非实测给出时的常见入口；`f` 是最后一个形参，因此可用尾随 lambda 形式调用：`HeatmapSeries.fromFunction(8, 8, xr, yr) { x, y => x * y }`。结果的 `xRange`/`yRange` 已设为传入的范围。

```cangjie
public static func fromFunction(rows: Int64, columns: Int64, xRange: Bounds, yRange: Bounds, f: (Float64, Float64) -> Float64): HeatmapSeries
```

**参数**

- `rows`: `Int64` — 行数，须为正。
- `columns`: `Int64` — 列数，须为正。
- `xRange`: [`Bounds`](../core/Bounds.md) — 采样的 x 区间；网格列均匀分布其上（含两端）。
- `yRange`: `Bounds` — 采样的 y 区间；网格行均匀分布其上（含两端）。
- `f`: `(Float64, Float64) -> Float64` — 被采样的函数，实参为数据坐标 (x, y)。

**返回值** `HeatmapSeries` — 已填好网格值并设定 `xRange`/`yRange` 的系列。

**异常**

- `PlotException` — 维度非正时。

### value

网格单元格的值。

```cangjie
public func value(row: Int64, column: Int64): Float64
```

**参数**

- `row`: `Int64` — 行序号，从 0 开始。
- `column`: `Int64` — 列序号，从 0 开始。

**返回值** `Float64` — 该单元格存储的值。

### rows

网格的行数。

```cangjie
public func rows(): Int64
```

**返回值** `Int64` — 行数。

### columns

网格的列数。

```cangjie
public func columns(): Int64
```

**返回值** `Int64` — 列数。

### resolvedValueRange

实际映射到色标上的值域——固定的 `valueRange`，或对有限数据自动适配的范围。数据退化（全部相同）时展开为非退化区间；完全没有有限值时为 `Bounds(0.0, 1.0)`。

```cangjie
public func resolvedValueRange(): Bounds
```

**返回值** `Bounds` — 色标两端对应的值域。

### resolvedColormap

实际使用的色标——`map`，未设置时取主题的色标。

```cangjie
public func resolvedColormap(theme: Theme): Colormap
```

**参数**

- `theme`: [`Theme`](../core/Theme.md) — 提供默认色标。

**返回值** [`Colormap`](../core/Colormap.md) — 生效的色标。

### dataBounds

网格覆盖的数据区间，向外各延伸半个单元格。这样最外圈单元格以中心对齐网格坐标时仍完整落在面板内。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — (x 区间, y 区间)，恒为 `Some`。

### fillsExtent

恒为 `true`：网格恰好铺满其矩形，自动适配不再加余量。

```cangjie
public override func fillsExtent(): Bool
```

**返回值** `Bool` — 恒为 `true`。

### draw

逐格填色绘制网格。非有限的单元格跳过；`showValues` 开启时在格内打印数值。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 绘制目标。
- `projection`: [`Projection`](../core/Projection.md) — 数据坐标到像素坐标的投影。
- `theme`: `Theme` — 默认色标来源。

### legend

本系列贡献的图例条目；标签为空时为空数组。色样画成一段微缩色带——单色芯片无法代表连续标度。

```cangjie
public override func legend(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 默认色标来源。

**返回值** `Array<`[`LegendEntry`](LegendEntry.md)`>` — 至多一个条目。

### hitTest

最近单元格的命中测试。光标落在网格范围外，或该单元格值非有限时为 `None`；命中文本给出 `[行, 列]` 与数值。

```cangjie
public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult
```

**参数**

- `px`, `py`: `Float32` — 光标的像素坐标。
- `projection`: `Projection` — 数据坐标到像素坐标的投影。
- `theme`: `Theme` — 读数颜色取自该单元格在色标上的颜色。

**返回值** `?`[`HitResult`](HitResult.md) — 命中单元格的读数信息，或 `None`。

## 字段

### map

色标；`None` 跟随主题的 `theme.colormap`。默认 `None`。

```cangjie
public var map: ?Colormap = None
```

### valueRange

映射到色标两端的值域；`None` 时自动适配有限数据。默认 `None`。

```cangjie
public var valueRange: ?Bounds = None
```

### originTop

把行 0 放在顶部（矩阵、图像风格）而非底部。默认 `false`。

```cangjie
public var originTop: Bool = false
```

### cellGap

单元格之间的像素间隙。默认 `0.5`——发丝级间隙即可读出网格感，而无需真画网格线。

```cangjie
public var cellGap: Float32 = 0.5
```

### cornerRadius

每个单元格的圆角，单位逻辑像素。默认 `0.0`（直角）。

```cangjie
public var cornerRadius: Float32 = 0.0
```

### showValues

在每个单元格中央打印其数值，颜色自动取与格色对比的颜色。默认 `false`；宽于单元格的文本省略不画。

```cangjie
public var showValues: Bool = false
```

### valueDecimals

`showValues` 的小数位数；`None` 时用紧凑格式。默认 `None`。

```cangjie
public var valueDecimals: ?Int64 = None
```

### xRange

网格覆盖的数据 x 区间；`None` 时用 `0 .. columns-1`（按单元格中心）。默认 `None`。

```cangjie
public var xRange: ?Bounds = None
```

### yRange

网格覆盖的数据 y 区间；`None` 时用 `0 .. rows-1`（按单元格中心）。默认 `None`。

```cangjie
public var yRange: ?Bounds = None
```

## 另请参阅

- [ContourSeries](ContourSeries.md)
- [Colormap](../core/Colormap.md)
- [ColorBar](../axes/ColorBar.md)
