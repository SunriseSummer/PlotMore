[plot](../../index.md) › [plot.axes](index.md) › ColorBar

# ColorBar

`plot.axes` 中的 public class

连续颜色标度的图例：色带本身，加一条带标签的数值轴。热力图或按值着色的散点没有它便无法解读——颜色承载着数值，面板上没有其他元素说明颜色的含义。

## 声明

```cangjie
public class ColorBar
```

## 说明

色带以 [`resolution`](#resolution) 个堆叠条带绘制：单一渐变绘制原语只能在两种颜色之间插值，而[色标](../core/Colormap.md)是多停靠点的颜色曲线，细分条带才能忠实呈现它。竖直颜色条的数值自下而上增长，与它通常紧邻的 y 轴方向一致；水平颜色条自左向右增长。

刻度由 [Ticks.linear](../core/Ticks.md#linear) 按 [`tickTarget`](#ticktarget) 生成，数量只是近似目标。给 [Axes.setColorBar](Axes.md#setcolorbar) 传入颜色条后，面板会按 [`extent`](#extent) 预留空间并自动完成绘制，[HeatmapSeries](../series/HeatmapSeries.md) 是最常见的搭配。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.ColorBar
import plot.core.{Bounds, Colormap}
import plot.series.HeatmapSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "相关系数")
    axes.add(HeatmapSeries([0.1, 0.5, 0.8, 1.0], rows: 2, columns: 2))
    let colorBar = ColorBar(Bounds(0.0, 1.0), Colormap.viridis())
    colorBar.label = "相关系数"
    axes.setColorBar(colorBar)
    FigureExport.renderToPng(figure, "colorbar.png", width: 800, height: 600)
    println(colorBar.valueRange()) // 输出: Bounds(0.000000, 1.000000)
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(range: Bounds, map: Colormap)`](#init) | 按数值区间与色标创建颜色条。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`valueRange()`](#valuerange) | 返回颜色条覆盖的数值区间。 |
| [`extent(canvas, theme)`](#extent) | 返回颜色条沿短轴需要预留的总空间，含刻度标签与可选标题。 |
| [`draw(...)`](#draw) | 将颜色条绘制到 `rect`，该矩形应为按 `extent` 预留的条带。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`side`](#side) | 颜色条依附的边。 |
| [`label`](#label) | 所映射量的标题；空字符串既不绘制也不占位。 |
| [`tickTarget`](#ticktarget) | 沿条带放置的带标签刻度的目标数量，只是近似值。 |
| [`thickness`](#thickness) | 色带条本身的厚度，逻辑像素。 |
| [`resolution`](#resolution) | 色带绘制所用的堆叠条带数，越高越平滑。 |

## 构造函数

### init

按数值区间与色标创建颜色条。区间与色标此后不可更换；外观相关字段仍可随时调整。

```cangjie
public init(range: Bounds, map: Colormap)
```

**参数**

- `range`: [`Bounds`](../core/Bounds.md) — 色带两端对应的数值区间。
- `map`: [`Colormap`](../core/Colormap.md) — 采样出色带的连续色标。

## 方法

### valueRange

返回颜色条覆盖的数值区间。

```cangjie
public func valueRange(): Bounds
```

**返回值** `Bounds` — 构造时传入的区间。

### extent

返回颜色条沿短轴需要预留的总空间，含刻度标签与可选标题。`side` 为 `Right` 时是需要的总宽度，为 `Bottom` 时是总高度；[`label`](#label) 非空会再加一行标题的高度。

```cangjie
public func extent(canvas: Canvas, theme: Theme): Float32
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 用于测量刻度标签；无渲染设备（headless）画布的文本测量返回 0，结果相应偏小。
- `theme`: [`Theme`](../core/Theme.md) — 提供刻度与标题的文字尺寸。

**返回值** `Float32` — 逻辑像素。

### draw

将颜色条绘制到 `rect`，该矩形应为按 `extent` 预留的条带。`side` 为 `Right` 时沿矩形高度竖直绘制，为 `Bottom` 时沿矩形宽度水平绘制。

```cangjie
public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 目标画布。
- `rect`: `Rect` — 预留给颜色条的条带，逻辑像素。
- `theme`: `Theme` — 边框、刻度与文字颜色的来源。

## 字段

### side

颜色条依附的边。

```cangjie
public var side: ColorBarSide = ColorBarSide.Right
```

取值见 [ColorBarSide](ColorBarSide.md)。

### label

所映射量的标题；空字符串既不绘制也不占位。

```cangjie
public var label: String = ""
```

### tickTarget

沿条带放置的带标签刻度的目标数量，只是近似值。实际数量取决于把步长凑成整值后的结果。

```cangjie
public var tickTarget: Int64 = 5
```

### thickness

色带条本身的厚度，逻辑像素。默认 12.0（`BAR_THICKNESS`）。

```cangjie
public var thickness: Float32 = BAR_THICKNESS
```

### resolution

色带绘制所用的堆叠条带数，越高越平滑。细分的缘由见上文"说明"。

```cangjie
public var resolution: Int64 = 128
```

## 另请参阅

- [ColorBarSide](ColorBarSide.md)
- [Colormap](../core/Colormap.md)
- [HeatmapSeries](../series/HeatmapSeries.md)
- [Axes.setColorBar](Axes.md#setcolorbar)
