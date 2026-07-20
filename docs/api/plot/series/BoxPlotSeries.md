[plot](../../index.md) › [plot.series](index.md) › BoxPlotSeries

# BoxPlotSeries

`plot.series` 中的 public class

位于整数类别位置的 Tukey 箱线图系列，每组一个箱。箱体覆盖四分位距并标出中位数；须伸至距四分位数 `whiskerRange` 倍四分位距以内最远的真实观测，更远的样本画作离群点。须端落在真实观测上而非围栏值上——每个须端都是一个数据点。

## 声明

```cangjie
public class BoxPlotSeries <: Series
```

## 继承

- 父类型：[Series](Series.md)

## 说明

- 每组的摘要在构造时按当前 `whiskerRange` 一次算好——每组一次而非每帧一次。这正是 [whiskerRange](#whiskerrange) 做成属性的原因：写入即触发重算。
- 类别轴应设为 [CategoryScale](../core/CategoryScale.md)：第 `i` 组的箱位于数据坐标 `i`。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.core.CategoryScale
import plot.series.BoxPlotSeries

main(): Unit {
    let control = [4.8, 5.1, 5.3, 5.6, 9.9]
    let treated = [6.1, 6.4, 6.8, 7.2, 7.5]
    let boxes = BoxPlotSeries([control, treated], label: "疗效")

    let (figure, axes) = Figure.single(title: "疗效分布")
    axes.setXScale(CategoryScale(["对照组", "试验组"]))
    axes.add(boxes)

    FigureExport.renderToPng(figure, "boxplot.png", width: 800, height: 600)

    let first = boxes.stats()[0]
    println(first.median) // 输出: 5.300000
    // 9.9 越过上围栏，报告为离群点
    println(first.outliers.size) // 输出: 1
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 以分组样本构造箱线图系列。 |

**属性**

| 成员 | 说明 |
|---|---|
| [`whiskerRange`](#whiskerrange) | 决定须围栏的四分位距倍数；按 Tukey 惯例默认 `1.5`。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`stats()`](#stats) | 每组算出的箱形摘要。 |
| [`count()`](#count) | 本系列的分组数量。 |
| [`dataBounds()`](#databounds) | 类别向为 `[-0.5, n-0.5]`，数值向覆盖全部须端与离群点。 |
| [`draw(...)`](#draw) | 绘制箱体、须与中位数线，以及可选的均值标记与离群点。 |
| [`legend(...)`](#legend) | 本系列贡献的图例条目；标签为空时为空数组。 |
| [`hitTest(...)`](#hittest) | 按水平位置选中分组的命中测试。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`bandFraction`](#bandfraction) | 箱体占类别带的比例，`0..1`。 |
| [`showOutliers`](#showoutliers) | 把围栏之外的样本画成单独的标记点。 |
| [`outlierMarker`](#outliermarker) | 离群点使用的标记样式。 |
| [`showMean`](#showmean) | 在中位数线之外，再以菱形标记标出每组的均值。 |
| [`fillOpacity`](#fillopacity) | 箱体填充的不透明度，`0..1`。 |
| [`colorByGroup`](#colorbygroup) | 每个箱按分组序号从主题调色板取色。 |

## 构造函数

### init

以分组样本构造箱线图系列。

```cangjie
public init(groups: Array<Array<Float64>>, label!: String = "")
```

**参数**

- `groups`: `Array<Array<Float64>>` — 每组一份样本；非有限值在统计时被过滤。
- `label`: `String` — 图例标签；空串（默认）时系列不进入图例。

**异常**

- [`PlotException`](../core/PlotException.md) — `groups` 为空，或任一组不含任何有限样本时——空组无从概括成箱。

## 属性

### whiskerRange

决定须围栏的四分位距倍数；按 Tukey 惯例默认 `1.5`。可读写；写入即按新倍数重算全部分组摘要——即便写回原值也会重算一遍。

```cangjie
public mut prop whiskerRange: Float64
```

**返回值** `Float64` — 当前倍数。

## 方法

### stats

每组算出的箱形摘要。返回内部列表，写入 `whiskerRange` 后其内容随之更新。

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

类别向为 `[-0.5, n-0.5]`，数值向覆盖全部须端与离群点。构造成功即有可概括的数据，恒为 `Some`。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(`[`Bounds`](../core/Bounds.md)`, Bounds)` — (x 区间, y 区间)。

### draw

绘制箱体、须与中位数线，以及可选的均值标记与离群点。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 绘制目标。
- `projection`: [`Projection`](../core/Projection.md) — 数据坐标到像素坐标的投影。
- `theme`: [`Theme`](../core/Theme.md) — 颜色来源。

### legend

本系列贡献的图例条目；标签为空时为空数组。色样为带中线的描边圆角箱。

```cangjie
public override func legend(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 颜色来源。

**返回值** `Array<`[`LegendEntry`](LegendEntry.md)`>` — 至多一个条目。

### hitTest

按水平位置选中分组的命中测试。箱在数值方向贯穿整个类别带，纵坐标不参与判定；命中文本给出该组的中位数与四分位距。

```cangjie
public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult
```

**参数**

- `px`, `py`: `Float32` — 光标的像素坐标（`py` 不参与判定）。
- `projection`: `Projection` — 数据坐标到像素坐标的投影。
- `theme`: `Theme` — 读数颜色来源。

**返回值** `?`[`HitResult`](HitResult.md) — 光标不在任何组的横向范围内时为 `None`。

## 字段

### bandFraction

箱体占类别带的比例，`0..1`。默认 `0.5`，超出范围按边界处理。

```cangjie
public var bandFraction: Float64 = 0.5
```

### showOutliers

把围栏之外的样本画成单独的标记点。默认 `true`。

```cangjie
public var showOutliers: Bool = true
```

### outlierMarker

离群点使用的标记样式。默认圆形，取值见 [MarkerStyle](../canvas/MarkerStyle.md)。

```cangjie
public var outlierMarker: MarkerStyle = MarkerStyle.Circle
```

### showMean

在中位数线之外，再以菱形标记标出每组的均值。默认 `false`。

```cangjie
public var showMean: Bool = false
```

### fillOpacity

箱体填充的不透明度，`0..1`。默认 `0.45`。

```cangjie
public var fillOpacity: Float64 = 0.45
```

### colorByGroup

每个箱按分组序号从主题调色板取色。默认 `true`；为 `false` 时整个系列共用其调色板槽位色，被 `setColor` 固定颜色时以固定色优先。

```cangjie
public var colorByGroup: Bool = true
```

## 另请参阅

- [BoxStats](BoxStats.md)
- [Stats.box](Stats.md#box)
- [ViolinSeries](ViolinSeries.md)
- [CategoryScale](../core/CategoryScale.md)
