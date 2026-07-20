[plot](../../index.md) › [plot.series](index.md) › Series

# Series

`plot.series` 中的 public class（抽象基类）

[Axes](../axes/Axes.md) 中一条可绘制的数据层：报告自身占据的数据区间、经由投影绘制、贡献图例条目，并可选地响应命中测试。子类只需实现 `dataBounds` 与 `draw`；标签、可见性、颜色解析与默认图例行为由本类统一提供。

## 声明

```cangjie
public abstract class Series
```

## 继承

- 本项目内已知子类型：[LineSeries](LineSeries.md)、[ScatterSeries](ScatterSeries.md)、[StepSeries](StepSeries.md)、[StemSeries](StemSeries.md)、[ErrorBarSeries](ErrorBarSeries.md)、[AreaSeries](AreaSeries.md)、[BarSeries](BarSeries.md)、[HistogramSeries](HistogramSeries.md)、[BoxPlotSeries](BoxPlotSeries.md)、[ViolinSeries](ViolinSeries.md)、[HeatmapSeries](HeatmapSeries.md)、[ContourSeries](ContourSeries.md)

## 说明

系列通过 [Projection](../core/Projection.md) 绘制：数据坐标到像素坐标的变换由投影独自持有，没有任何系列自己在面板矩形上做算术。系列以 `dataBounds` 报告需要的数据区间（[Bounds](../core/Bounds.md)），`Axes` 对可见系列求并集来完成自动适配。

颜色解析是延迟的：未用 `setColor` 固定颜色的系列，绘制时取 [Theme](../core/Theme.md) 的 `theme.palette` 在 `paletteIndex` 处的颜色；该下标由 `Axes` 在 `add` 系列时通过 `setPaletteIndex` 分配。这使调色板成为主题的决定，而不必每个调用方各自重复指定。`opacity` 在解析结果之上再做一次不透明度乘法。

`dataBounds` 与 `draw` 是抽象方法（源码中只有签名、没有函数体），每个子类必须实现；`fillsExtent`、`legend`、`hitTest` 提供可覆盖的默认实现。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.core.Colors
import plot.series.{LineSeries, ScatterSeries, Series}

main(): Unit {
    let days = [1.0, 2.0, 3.0, 4.0]
    let measured: Series = LineSeries(days, [3.2, 4.1, 3.8, 4.6], label: "实测")
    let reference = ScatterSeries(days, [3.0, 3.9, 4.0, 4.4], label: "参考")

    measured.setColor(Colors.hex("#D97706")) // 固定颜色，覆盖调色板
    reference.opacity = 0.6 // 在解析出的颜色之上再乘不透明度

    let (figure, axes) = Figure.single(title: "实测与参考")
    axes.add(measured) // Axes 依次为系列分配调色板槽位
    axes.add(reference)

    FigureExport.renderToPng(figure, "series.png", width: 800, height: 600)
    println("系列数: ${axes.allSeries().size}") // 输出: 系列数: 2
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`setColor(...)`](#setcolor) | 将系列固定为给定颜色，覆盖主题调色板。 |
| [`color()`](#color) | 返回已固定的显式颜色；未固定时为 `None`。 |
| [`setPaletteIndex(...)`](#setpaletteindex) | 由 `Axes` 在添加系列时调用，为未固定颜色的系列选定调色板槽位。 |
| [`indexInPalette()`](#indexinpalette) | 返回分配给该系列的调色板槽位下标。 |
| [`dataBounds()`](#databounds) | 返回该系列占据的 x、y 数据区间；不含任何有限数据时为 `None`。 |
| [`draw(...)`](#draw) | 将系列渲染到画布上。 |
| [`fillsExtent()`](#fillsextent) | 当 `dataBounds` 是应当铺满面板的精确范围、而非需要留边的散点云时返回 `true`。 |
| [`legend(...)`](#legend) | 返回该系列贡献的图例条目；没有标签时为空数组。 |
| [`hitTest(...)`](#hittest) | 返回最接近指定像素的数据点；该系列附近没有内容时为 `None`。 |
| [`resolveColor(...)`](#resolvecolor) | （protected，仅子类可见）返回该系列实际绘制所用的颜色：已固定的颜色，否则为调色板槽位上的颜色。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`label`](#label) | 图例标签；留空则该系列不进入图例。 |
| [`visible`](#visible) | 为 `false` 时整条系列被跳过——绘制、自动适配、图例与命中测试都不参与。 |
| [`opacity`](#opacity) | 在解析出的颜色之上相乘的不透明度，取值 `0..1`。 |
| [`explicitColor`](#explicitcolor) | （protected，仅子类可见）已固定的显式颜色；`None` 表示交给 `paletteIndex` 决定。 |
| [`paletteIndex`](#paletteindex) | （protected，仅子类可见）未固定颜色时所用的调色板槽位下标。 |

## 方法

### setColor

将系列固定为给定颜色，覆盖主题调色板。

```cangjie
public func setColor(color: Color): Unit
```

**参数**

- `color`: `Color` — 该系列此后绘制所用的颜色。

### color

返回已固定的显式颜色；未固定时为 `None`。

```cangjie
public func color(): ?Color
```

**返回值** `?Color` — `setColor` 固定的颜色，或 `None`。

### setPaletteIndex

由 `Axes` 在添加系列时调用，为未固定颜色的系列选定调色板槽位。一般不需要手动调用。

```cangjie
public func setPaletteIndex(index: Int64): Unit
```

**参数**

- `index`: `Int64` — 调色板槽位下标。

### indexInPalette

返回分配给该系列的调色板槽位下标。

```cangjie
public func indexInPalette(): Int64
```

**返回值** `Int64` — 槽位下标，初始为 `0`。

### dataBounds

返回该系列占据的 x、y 数据区间；不含任何有限数据时为 `None`。空系列，或每个点都被过滤掉的系列，都返回 `None`。`Axes` 对可见系列的区间求并集来完成自动适配。抽象方法，子类必须实现。

```cangjie
public func dataBounds(): ?(Bounds, Bounds)
```

**返回值** `?(Bounds, Bounds)` — 数据坐标下的 (x 区间, y 区间)，或 `None`。

### draw

将系列渲染到画布上。调用时面板裁剪已经生效。抽象方法，子类必须实现。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标，见 [Canvas](../canvas/Canvas.md)。
- `projection`: `Projection` — 数据坐标到像素坐标的变换。
- `theme`: `Theme` — 提供颜色、线宽等默认样式。

### fillsExtent

当 `dataBounds` 是应当铺满面板的精确范围、而非需要留边的散点云时返回 `true`。热力图或等高线铺满一个矩形：再加 5% 边距会在场与面板边缘之间留出一圈空白背景，读起来像缺数据而不是留白；散点则需要边距，避免最外侧标记被边框截断。任一可见系列返回 `true` 时，`Axes` 跳过自动适配的预留边距。默认返回 `false`。

```cangjie
public open func fillsExtent(): Bool
```

**返回值** `Bool` — 默认 `false`；`HeatmapSeries`、`ContourSeries` 覆盖为 `true`。

### legend

返回该系列贡献的图例条目；没有标签时为空数组。默认实现当 `label` 非空时返回一个条目，色块为该系列颜色的圆角矩形。

```cangjie
public open func legend(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 用于解析色块颜色。

**返回值** `Array<LegendEntry>` — 图例条目，见 [LegendEntry](LegendEntry.md)；`label` 为空时为空数组。

### hitTest

返回最接近指定像素的数据点；该系列附近没有内容时为 `None`。默认实现总是返回 `None`；有离散数据点的系列会覆盖它。

```cangjie
public open func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult
```

**参数**

- `px`: `Float32` — 光标像素横坐标。
- `py`: `Float32` — 光标像素纵坐标。
- `projection`: `Projection` — 数据坐标到像素坐标的变换。
- `theme`: `Theme` — 用于解析结果中的系列颜色。

**返回值** `?HitResult` — 命中结果，见 [HitResult](HitResult.md)；默认 `None`。

### resolveColor

（protected，仅子类可见）返回该系列实际绘制所用的颜色：已固定的颜色，否则为调色板槽位上的颜色。`opacity` 小于 `1.0` 时在结果上再做一次不透明度乘法。

```cangjie
protected func resolveColor(theme: Theme): Color
```

**参数**

- `theme`: `Theme` — 提供调色板。

**返回值** `Color` — 已应用 `opacity` 的最终绘制颜色。

## 字段

### label

图例标签；留空则该系列不进入图例。

```cangjie
public var label: String = ""
```

### visible

为 `false` 时整条系列被跳过——绘制、自动适配、图例与命中测试都不参与。

```cangjie
public var visible: Bool = true
```

### opacity

在解析出的颜色之上相乘的不透明度，取值 `0..1`。

```cangjie
public var opacity: Float64 = 1.0
```

### explicitColor

（protected，仅子类可见）已固定的显式颜色；`None` 表示交给 `paletteIndex` 决定。

```cangjie
protected var explicitColor: ?Color = None
```

### paletteIndex

（protected，仅子类可见）未固定颜色时所用的调色板槽位下标。

```cangjie
protected var paletteIndex: Int64 = 0
```

## 另请参阅

- [Axes](../axes/Axes.md) — 持有系列并驱动其绘制与自动适配的面板
- [LegendEntry](LegendEntry.md)、[HitResult](HitResult.md) — 系列产出的图例与命中测试结果
- [函数 — plot.series](functions.md) — 供子类使用的 `requireSameLength`、`pairedBounds`、`plottableRuns`
