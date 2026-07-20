[plot](../../index.md) › [plot.series](index.md) › ViolinSeries

# ViolinSeries

`plot.series` 中的 public class

小提琴图系列：每组样本的核密度估计沿类别位置左右镜像成对称轮廓。小提琴显示分布的形状，而箱线图只显示四分位数——这正是看出双峰样本与只看到一个宽箱的差别。密度终究是估计：平滑程度取决于带宽选择而非数据本身，形状承载论点时请显式设置 `bandwidth`。

## 声明

```cangjie
public class ViolinSeries <: Series
```

## 继承

- 父类型：[Series](Series.md)

## 说明

- 每个小提琴按自身峰值归一成满宽：各组形状可比，但宽度不反映相对样本量——`showBox` 的内嵌箱线可弥补这一信息。
- 密度采样范围在每组数据两端各外扩 12%，让尾部收拢，而不是在极值处被截平。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.core.CategoryScale
import plot.series.ViolinSeries

main(): Unit {
    let groupA = [1.0, 1.2, 1.4, 2.8, 3.0, 3.1]
    let groupB = [2.0, 2.2, 2.4, 2.5, 2.7]
    let violins = ViolinSeries([groupA, groupB], label: "响应时间")
    violins.bandwidth = Some(0.3)

    let (figure, axes) = Figure.single(title: "响应时间")
    axes.setXScale(CategoryScale(["版本 A", "版本 B"]))
    axes.add(violins)

    FigureExport.renderToPng(figure, "violin.png", width: 800, height: 600)

    println(violins.count()) // 输出: 2
    println(violins.stats()[0].median) // 输出: 2.100000
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 以分组样本构造小提琴图系列。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`stats()`](#stats) | 内嵌箱线所用的每组箱形摘要。 |
| [`count()`](#count) | 本系列的分组数量。 |
| [`dataBounds()`](#databounds) | 类别向为 `[-0.5, n-0.5]`，数值向为各组外扩后采样范围的并集。 |
| [`draw(...)`](#draw) | 绘制小提琴填充与轮廓、内嵌箱线与中位数点。 |
| [`legend(...)`](#legend) | 本系列贡献的图例条目；标签为空时为空数组。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`bandFraction`](#bandfraction) | 满宽小提琴占类别带的比例，`0..1`。 |
| [`resolution`](#resolution) | 每条密度曲线的采样点数。 |
| [`bandwidth`](#bandwidth) | 核带宽；`None` 用 Silverman 经验规则。 |
| [`showBox`](#showbox) | 在每个小提琴内部叠加显示四分位距与须的微型箱线。 |
| [`showMedian`](#showmedian) | 以圆点标出每组的中位数。 |
| [`fillOpacity`](#fillopacity) | 填充不透明度，`0..1`。 |
| [`showEdge`](#showedge) | 为每个小提琴的轮廓描边。 |
| [`colorByGroup`](#colorbygroup) | 每个小提琴按分组序号从主题调色板取色。 |

## 构造函数

### init

以分组样本构造小提琴图系列。

```cangjie
public init(groups: Array<Array<Float64>>, label!: String = "")
```

**参数**

- `groups`: `Array<Array<Float64>>` — 每组一份样本；非有限值在统计时被过滤。
- `label`: `String` — 图例标签；空串（默认）时系列不进入图例。

**异常**

- [`PlotException`](../core/PlotException.md) — `groups` 为空，或任一组的有限样本少于两个时——太少无从估计密度。

## 方法

### stats

内嵌箱线所用的每组箱形摘要。

```cangjie
public func stats(): ArrayList<BoxStats>
```

**返回值** `ArrayList<`[`BoxStats`](BoxStats.md)`>` — 与 `groups` 同序。

### count

本系列的分组数量。

```cangjie
public func count(): Int64
```

**返回值** `Int64` — 分组个数。

### dataBounds

类别向为 `[-0.5, n-0.5]`，数值向为各组外扩后采样范围的并集。构造成功即有数据，恒为 `Some`。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(`[`Bounds`](../core/Bounds.md)`, Bounds)` — (x 区间, y 区间)。

### draw

绘制小提琴填充与轮廓、内嵌箱线与中位数点。密度峰值为零的组跳过。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 绘制目标。
- `projection`: [`Projection`](../core/Projection.md) — 数据坐标到像素坐标的投影。
- `theme`: [`Theme`](../core/Theme.md) — 颜色来源。

### legend

本系列贡献的图例条目；标签为空时为空数组。

```cangjie
public override func legend(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 颜色来源。

**返回值** `Array<`[`LegendEntry`](LegendEntry.md)`>` — 至多一个条目。

## 字段

### bandFraction

满宽小提琴占类别带的比例，`0..1`。默认 `0.8`，超出范围按边界处理。

```cangjie
public var bandFraction: Float64 = 0.8
```

### resolution

每条密度曲线的采样点数。越高越平滑，也越慢；默认 `96`。

```cangjie
public var resolution: Int64 = 96
```

### bandwidth

核带宽；`None` 用 Silverman 经验规则。核带宽即高斯核的标准差（见 [Stats.silvermanBandwidth](Stats.md#silvermanbandwidth)），默认 `None`。

```cangjie
public var bandwidth: ?Float64 = None
```

### showBox

在每个小提琴内部叠加显示四分位距与须的微型箱线。默认 `true`。

```cangjie
public var showBox: Bool = true
```

### showMedian

以圆点标出每组的中位数。默认 `true`。

```cangjie
public var showMedian: Bool = true
```

### fillOpacity

填充不透明度，`0..1`。默认 `0.4`。

```cangjie
public var fillOpacity: Float64 = 0.4
```

### showEdge

为每个小提琴的轮廓描边。默认 `true`。

```cangjie
public var showEdge: Bool = true
```

### colorByGroup

每个小提琴按分组序号从主题调色板取色。默认 `true`；为 `false` 时整个系列共用其调色板槽位色，被 `setColor` 固定颜色时以固定色优先。

```cangjie
public var colorByGroup: Bool = true
```

## 另请参阅

- [BoxPlotSeries](BoxPlotSeries.md)
- [BoxStats](BoxStats.md)
- [Stats.kernelDensity](Stats.md#kerneldensity)
- [Stats.silvermanBandwidth](Stats.md#silvermanbandwidth)
