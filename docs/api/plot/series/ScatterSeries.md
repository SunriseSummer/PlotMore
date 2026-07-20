[plot](../../index.md) › [plot.series](index.md) › ScatterSeries

# ScatterSeries

`plot.series` 中的 public class

位于 `(x, y)` 的散点，可再把额外维度映射到标记大小与颜色。普通散点用单一颜色与单一大小；`sizeBy` 把第三个变量映射到标记面积（即气泡图），`colorBy` 把第四个变量映射到[色标](../core/Colormap.md)，一块面板最多同时承载四个维度。

## 声明

```cangjie
public class ScatterSeries <: Series
```

## 继承

- 父类：[Series](Series.md)

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.core.Colormap
import plot.series.ScatterSeries

main(): Unit {
    // 身高（m）、体重（kg）、年龄（岁）：大小与颜色各承载一个维度
    let heights = [1.62, 1.71, 1.68, 1.80, 1.75]
    let weights = [56.0, 68.5, 61.2, 79.4, 72.3]
    let ages = [23.0, 31.0, 27.0, 45.0, 38.0]

    let samples = ScatterSeries(heights, weights, label: "体检样本")
    samples.sizeBy(ages, minSize: 4.0, maxSize: 12.0)
    samples.colorBy(ages, Colormap.viridis())

    let (figure, axes) = Figure.single(title: "体检样本")
    axes.add(samples)

    FigureExport.renderToPng(figure, "scatter-series.png", width: 800, height: 600)
    println("点数: ${samples.xValues().size}") // 输出: 点数: 5
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建散点系列；`xs` 与 `ys` 一一配对。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`xValues()`](#xvalues) | 返回构造时传入的 x 坐标数组。 |
| [`yValues()`](#yvalues) | 返回构造时传入的 y 坐标数组。 |
| [`sizeBy(...)`](#sizeby) | 按 `values` 为每个标记确定大小，把数据范围映射到 `minSize..maxSize`。 |
| [`colorBy(...)`](#colorby) | 按 `values` 经色标 `map` 为每个标记着色。 |
| [`colorValueBounds()`](#colorvaluebounds) | 返回颜色映射覆盖的取值区间，供颜色条使用；未调用 `colorBy` 时为 `None`。 |
| [`colormap()`](#colormap) | 返回正在使用的色标；未调用 `colorBy` 时为 `None`。 |
| [`dataBounds()`](#databounds) | 返回有限数据点的 x、y 区间；没有有限点时为 `None`。 |
| [`draw(...)`](#draw) | 逐点绘制标记，按 `sizeBy`、`colorBy` 的映射逐点解析大小与颜色。 |
| [`legend(...)`](#legend) | 返回一个以本系列标记与颜色绘制的图例条目。 |
| [`hitTest(...)`](#hittest) | 返回像素空间中最接近 `(px, py)` 的数据点；没有可表达的点时为 `None`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`marker`](#marker) | 每个数据点处绘制的符号。 |
| [`size`](#size) | 标记半径（逻辑像素）；`None` 跟随 `theme.markerSize`，`sizeBy` 生效时被逐点覆盖。 |
| [`showEdge`](#showedge) | 在每个标记外描一圈细边，让重叠的点仍可分辨。 |

## 构造函数

### init

创建散点系列；`xs` 与 `ys` 一一配对。

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

### sizeBy

按 `values` 为每个标记确定大小，把数据范围映射到 `minSize..maxSize`。映射作用在**面积**而非半径上：感知到的量级跟随面积，线性缩放半径会把大值大约按平方夸大。

```cangjie
public func sizeBy(values: Array<Float64>, minSize!: Float32 = 3.0, maxSize!: Float32 = 14.0): Unit
```

**参数**

- `values`: `Array<Float64>` — 每点一个的映射值，须与点数等长。
- `minSize!`: `Float32` — 最小标记半径（逻辑像素），默认 `3.0`。
- `maxSize!`: `Float32` — 最大标记半径（逻辑像素），默认 `14.0`。

**异常**

- `PlotException` — `values` 长度与点数不同时。

### colorBy

按 `values` 经色标 `map` 为每个标记着色。`domain` 固定颜色映射的取值范围；`None` 时自动适配为 `values` 的覆盖区间。

```cangjie
public func colorBy(values: Array<Float64>, map: Colormap, domain!: ?Bounds = None): Unit
```

**参数**

- `values`: `Array<Float64>` — 每点一个的映射值，须与点数等长。
- `map`: `Colormap` — 采样颜色的色标。
- `domain!`: `?Bounds` — 颜色映射的取值区间；默认 `None`，即取 `values` 的实际范围。

**异常**

- `PlotException` — `values` 长度与点数不同时。

### colorValueBounds

返回颜色映射覆盖的取值区间，供颜色条使用；未调用 `colorBy` 时为 `None`。`colorBy` 指定过 `domain` 则返回它，否则返回 `values` 的覆盖区间。

```cangjie
public func colorValueBounds(): ?Bounds
```

**返回值** `?Bounds` — 颜色条应标注的取值区间，或 `None`。

### colormap

返回正在使用的色标；未调用 `colorBy` 时为 `None`。

```cangjie
public func colormap(): ?Colormap
```

**返回值** `?Colormap` — `colorBy` 设定的色标，或 `None`。

### dataBounds

返回有限数据点的 x、y 区间；没有有限点时为 `None`。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — 数据坐标下的 (x 区间, y 区间)，或 `None`。

### draw

逐点绘制标记，按 `sizeBy`、`colorBy` 的映射逐点解析大小与颜色。投影无法表达的点被跳过；`showEdge` 开启且标记为填充型时附加细描边。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标。
- `projection`: `Projection` — 数据坐标到像素坐标的变换。
- `theme`: `Theme` — 提供默认标记大小与颜色。

### legend

返回一个以本系列标记与颜色绘制的图例条目。`label` 为空时为空数组。

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

### marker

每个数据点处绘制的符号。取值见 [MarkerStyle](../canvas/MarkerStyle.md)。

```cangjie
public var marker: MarkerStyle = MarkerStyle.Circle
```

### size

标记半径（逻辑像素）；`None` 跟随 `theme.markerSize`，`sizeBy` 生效时被逐点覆盖。

```cangjie
public var size: ?Float32 = None
```

### showEdge

在每个标记外描一圈细边，让重叠的点仍可分辨。描边只加在填充型符号上——描边型符号没有可以围出的内部。

```cangjie
public var showEdge: Bool = true
```

## 另请参阅

- [LineSeries](LineSeries.md) — 连线的对应形态
- [Colormap](../core/Colormap.md) — `colorBy` 使用的连续色带
