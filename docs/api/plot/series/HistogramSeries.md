[plot](../../index.md) › [plot.series](index.md) › HistogramSeries

# HistogramSeries

`plot.series` 中的 public class

把一份样本按等宽分箱统计并绘制的直方图系列。分箱数默认由 Freedman-Diaconis 规则给出（见 [Stats.suggestBinCount](Stats.md#suggestbincount)）而非固定值——分箱宽度决定直方图看起来在说什么，固定值会把一份数据切碎、把另一份摊平。比较多份分布时请显式传入 `bins`，让它们共享同一分箱。

## 声明

```cangjie
public class HistogramSeries <: Series
```

## 继承

- 父类型：[Series](Series.md)

## 说明

- 没有任何有限样本时系列不绘制、不参与自动适配（[range()](#range) 与 [dataBounds()](#databounds) 为 `None`）。
- 条高、绘制与数据区间都按 `norm` 归一，切换 `norm` 立即生效——高度在每次调用时计算，不做缓存。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.series.{HistogramNorm, HistogramSeries}

main(): Unit {
    let sample = [1.0, 2.0, 2.0, 3.0]
    let hist = HistogramSeries(sample, bins: 2, label: "试次 A")
    hist.norm = HistogramNorm.Frequency

    let (figure, axes) = Figure.single(title: "试次分布")
    axes.add(hist)

    FigureExport.renderToPng(figure, "histogram.png", width: 800, height: 600)

    // 范围 [1, 3] 分两箱：1.0 落在下箱，2.0、2.0、3.0 落在上箱
    let heights = hist.heights()
    println(heights[0]) // 输出: 0.250000
    println(heights[1]) // 输出: 0.750000
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 以样本值构造直方图系列。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`setRange(...)`](#setrange) | 固定分箱覆盖的范围，不再跟随数据。 |
| [`bins()`](#bins) | 当前使用的分箱数。 |
| [`range()`](#range) | 实际使用的分箱范围。 |
| [`heights()`](#heights) | 各条形的高度，已按 `norm` 归一。 |
| [`dataBounds()`](#databounds) | x 为分箱范围，y 为 `0` 到最高条形；没有有限样本时为 `None`。 |
| [`draw(...)`](#draw) | 绘制直方图条形；高度为零的分箱不画。 |
| [`legend(...)`](#legend) | 本系列贡献的图例条目；标签为空时为空数组。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`norm`](#norm) | 条高的统计含义。 |
| [`barGap`](#bargap) | 相邻条形之间的间隙，占分箱宽度的比例，`0..1`。 |
| [`cornerRadius`](#cornerradius) | 条形顶部的圆角，单位逻辑像素。 |
| [`showEdge`](#showedge) | 为每根条形描边；`barGap` 为零时仍能区分相邻分箱。 |
| [`fillOpacity`](#fillopacity) | 填充不透明度，`0..1`。 |

## 构造函数

### init

以样本值构造直方图系列。`bins` 为 `None`（默认）时按 Freedman-Diaconis 规则选择分箱数。

```cangjie
public init(values: Array<Float64>, bins!: ?Int64 = None, label!: String = "")
```

**参数**

- `values`: `Array<Float64>` — 样本；非有限值不参与分箱与分箱数估计。
- `bins`: `?Int64` — 分箱数，须为正；`None`（默认）自动选择。
- `label`: `String` — 图例标签；空串（默认）时系列不进入图例。

**异常**

- [`PlotException`](../core/PlotException.md) — 显式给出的 `bins` 为零或负数时。

## 方法

### setRange

固定分箱覆盖的范围，不再跟随数据。范围之外的样本不计入任何分箱。

```cangjie
public func setRange(range: Bounds): Unit
```

**参数**

- `range`: [`Bounds`](../core/Bounds.md) — 分箱统计的区间。

### bins

当前使用的分箱数。构造时确定，之后不变。

```cangjie
public func bins(): Int64
```

**返回值** `Int64` — 分箱数，恒为正。

### range

实际使用的分箱范围。显式固定的优先；否则覆盖数据的范围（退化时展开为非退化区间）；没有有限样本时为 `None`。

```cangjie
public func range(): ?Bounds
```

**返回值** `?Bounds` — 分箱区间。

### heights

各条形的高度，已按 `norm` 归一。范围缺失（无有限样本）时为空数组；范围内没有样本时全为 0。

```cangjie
public func heights(): Array<Float64>
```

**返回值** `Array<Float64>` — 长度为 `bins()` 的条高（范围缺失时长度为 0）。

### dataBounds

x 为分箱范围，y 为 `0` 到最高条形；没有有限样本时为 `None`。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — (x 区间, y 区间)。

### draw

绘制直方图条形；高度为零的分箱不画。`showEdge` 开启时以面板色为每根条形描边。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 绘制目标。
- `projection`: [`Projection`](../core/Projection.md) — 数据坐标到像素坐标的投影。
- `theme`: [`Theme`](../core/Theme.md) — 颜色来源。

### legend

本系列贡献的图例条目；标签为空时为空数组。色样为按填充不透明度着色的圆角色块。

```cangjie
public override func legend(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 颜色来源。

**返回值** `Array<`[`LegendEntry`](LegendEntry.md)`>` — 至多一个条目。

## 字段

### norm

条高的统计含义。取值见 [HistogramNorm](HistogramNorm.md)，默认原始计数。

```cangjie
public var norm: HistogramNorm = HistogramNorm.Count
```

### barGap

相邻条形之间的间隙，占分箱宽度的比例，`0..1`。默认 `0.06`；零表示条形彼此相接，超出范围按边界处理。

```cangjie
public var barGap: Float64 = 0.06
```

### cornerRadius

条形顶部的圆角，单位逻辑像素。默认 `2.0`；实际圆角不超过条形短边的一半。

```cangjie
public var cornerRadius: Float32 = 2.0
```

### showEdge

为每根条形描边；`barGap` 为零时仍能区分相邻分箱。默认 `false`。

```cangjie
public var showEdge: Bool = false
```

### fillOpacity

填充不透明度，`0..1`。默认 `0.85`；调低以叠加比较多份分布。

```cangjie
public var fillOpacity: Float64 = 0.85
```

## 另请参阅

- [HistogramNorm](HistogramNorm.md)
- [Stats.suggestBinCount](Stats.md#suggestbincount)
- [BarSeries](BarSeries.md)
