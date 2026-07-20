[plot](../../index.md) › [plot.series](index.md) › BarSeries

# BarSeries

`plot.series` 中的 public class

在整数类别位置绘制条形的系列，条宽跟随类别轴的类别带而非以像素估计。类别轴应设为 [CategoryScale](../core/CategoryScale.md)——它把第 `i` 个类别放在数据坐标 `i` 处的单位宽类别带内，本系列按这条带为自己定宽定位。分组与堆叠是一组系列之间的关系，由 [BarGroup](BarGroup.md) 统一安排，而不在单个系列上配置。

## 声明

```cangjie
public class BarSeries <: Series
```

## 继承

- 父类型：[Series](Series.md)

## 说明

- 条形从 `baseline` 向条形值生长，负值向反方向生长；值为非有限的条形不绘制、不参与自动适配，也不响应命中测试。
- 圆角只加在条形的生长端：堆叠时整列读作一根带单个圆头的柱子，而不是一摞独立的胶囊。条形比自身圆角还短时不做圆角——这避免了微小值被画成一个圆点。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.core.CategoryScale
import plot.series.BarSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "季度营收")
    axes.setXScale(CategoryScale(["Q1", "Q2", "Q3", "Q4"]))
    let revenue = BarSeries([12.0, 19.0, 7.0, 15.0], label: "营收")
    revenue.showValues = true
    axes.add(revenue)

    FigureExport.renderToPng(figure, "bars.png", width: 800, height: 600)
    println(revenue.count()) // 输出: 4
    println(revenue.barValues()[1]) // 输出: 19.000000
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 以各类别一个条形值构造系列。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`barValues()`](#barvalues) | 条形值，按类别顺序。 |
| [`count()`](#count) | 本系列的条形数量。 |
| [`setSlot(...)`](#setslot) | 把本系列放进每个类别带内 `total` 个并排槽位中的第 `index` 个。 |
| [`setStackBase(...)`](#setstackbase) | 把本系列堆叠在 `base` 之上，每个类别一个起点累计值。 |
| [`dataBounds()`](#databounds) | 本系列占据的数据区间；没有有限条形值时为 `None`。 |
| [`draw(...)`](#draw) | 绘制全部条形，`showValues` 开启时一并打印数值标签。 |
| [`hitTest(...)`](#hittest) | 以整根条形的面积作为命中目标的命中测试。 |
| [`barRect(...)`](#barrect) | 条形 `index` 在投影下的像素矩形。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`orientation`](#orientation) | 条形的生长方向；须与所属坐标区安排标度的方式一致。 |
| [`bandFraction`](#bandfraction) | 条形占类别带的比例，`0..1`；余下部分是间隙。 |
| [`cornerRadius`](#cornerradius) | 条形生长端的圆角半径，单位逻辑像素。 |
| [`baseline`](#baseline) | 条形生长的起点值；通常为零。 |
| [`showValues`](#showvalues) | 在每根条形的端部打印其数值。 |
| [`valueDecimals`](#valuedecimals) | `showValues` 的小数位数；`None` 时按数值选紧凑格式。 |

## 构造函数

### init

以各类别一个条形值构造系列。

```cangjie
public init(values: Array<Float64>, label!: String = "")
```

**参数**

- `values`: `Array<Float64>` — 条形值，按类别顺序；非有限值对应的条形不绘制。
- `label`: `String` — 图例标签；空串（默认）时系列不进入图例。

## 方法

### barValues

条形值，按类别顺序。

```cangjie
public func barValues(): Array<Float64>
```

**返回值** `Array<Float64>` — 构造时传入的同一数组。

### count

本系列的条形数量。

```cangjie
public func count(): Int64
```

**返回值** `Int64` — 条形个数，等于构造数组的长度。

### setSlot

把本系列放进每个类别带内 `total` 个并排槽位中的第 `index` 个。由 [BarGroup.grouped](BarGroup.md#grouped) 调用；直接调用只在自定义排布时有用。

```cangjie
public func setSlot(index: Int64, total: Int64): Unit
```

**参数**

- `index`: `Int64` — 槽位序号，从 0 开始。
- `total`: `Int64` — 槽位总数；小于 1 时按 1 处理。

### setStackBase

把本系列堆叠在 `base` 之上，每个类别一个起点累计值。由 [BarGroup.stacked](BarGroup.md#stacked) 调用。

```cangjie
public func setStackBase(base: Array<Float64>): Unit
```

**参数**

- `base`: `Array<Float64>` — 每个类别的堆叠起点；长度必须等于条形数。

**异常**

- [`PlotException`](../core/PlotException.md) — `base` 的长度与条形数不一致时。

### dataBounds

本系列占据的数据区间；没有有限条形值时为 `None`。类别向为 `[-0.5, n-0.5]`（`n` 为条形数），数值向覆盖基线与每根条形的两端（含堆叠起点）；`orientation` 决定哪一向是 x。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — (x 区间, y 区间)，类型为 [Bounds](../core/Bounds.md)。

### draw

绘制全部条形，`showValues` 开启时一并打印数值标签。非有限值与零尺寸的条形跳过。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 绘制目标。
- `projection`: [`Projection`](../core/Projection.md) — 数据坐标到像素坐标的投影。
- `theme`: [`Theme`](../core/Theme.md) — 颜色与字号来源。

### hitTest

以整根条形的面积作为命中目标的命中测试。适合线条的最近点规则会让高条形只剩顶端可命中，所以条形的整个矩形都算命中。

```cangjie
public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult
```

**参数**

- `px`, `py`: `Float32` — 光标的像素坐标。
- `projection`: `Projection` — 数据坐标到像素坐标的投影。
- `theme`: `Theme` — 读数颜色来源。

**返回值** `?`[`HitResult`](HitResult.md) — 命中时给出条形的类别序号与端值（数据坐标）及读数文本；未命中为 `None`。

### barRect

条形 `index` 在投影下的像素矩形。分组槽位与堆叠起点都已计入——绘制与命中测试使用的正是同一几何。

```cangjie
public func barRect(index: Int64, projection: Projection): Rect
```

**参数**

- `index`: `Int64` — 条形序号，从 0 开始。
- `projection`: `Projection` — 数据坐标到像素坐标的投影。

**返回值** `Rect` — 该条形的像素矩形。

## 字段

### orientation

条形的生长方向；须与所属坐标区安排标度的方式一致。取值见 [BarOrientation](BarOrientation.md)，默认垂直。

```cangjie
public var orientation: BarOrientation = BarOrientation.Vertical
```

### bandFraction

条形占类别带的比例，`0..1`；余下部分是间隙。默认 `0.7`；分组时各槽位平分这一比例。

```cangjie
public var bandFraction: Float64 = 0.7
```

### cornerRadius

条形生长端的圆角半径，单位逻辑像素。默认 `3.0`；实际圆角不超过条形短边的一半，退化到 0.5 像素以下时画直角矩形。

```cangjie
public var cornerRadius: Float32 = 3.0
```

### baseline

条形生长的起点值；通常为零。默认 `0.0`；堆叠时以 [setStackBase](#setstackbase) 传入的起点为准。

```cangjie
public var baseline: Float64 = 0.0
```

### showValues

在每根条形的端部打印其数值。默认 `false`。独立条形标在端点外侧；堆叠段标在段内，颜色自动取与填充对比的颜色。

```cangjie
public var showValues: Bool = false
```

### valueDecimals

`showValues` 的小数位数；`None` 时按数值选紧凑格式。默认 `None`。

```cangjie
public var valueDecimals: ?Int64 = None
```

## 另请参阅

- [BarOrientation](BarOrientation.md)
- [BarGroup](BarGroup.md)
- [CategoryScale](../core/CategoryScale.md)
- [HistogramSeries](HistogramSeries.md)（按分箱而非类别统计的条形）
