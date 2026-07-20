[plot](../../index.md) › [plot.axes](index.md) › Legend

# Legend

`plot.axes` 中的 public class

把色样对应到系列标签的图例。每个条目经由系列提供的回调绘制自己的色样，因此带圆形标记的虚线系列在图例中同样显示为带圆形标记的虚线，而不是一块通用色块。悬浮图例衬在半透明的面板色底板上：放在绘图区内部保住了绘图宽度，底板则保证数据从标签下方穿过时文字仍可读。

## 声明

```cangjie
public class Legend
```

## 说明

命中矩形在每次 [`draw`](#draw) 中重建，[`entryAt`](#entryat) 据此把像素坐标换算成条目下标，实现点击切换系列显隐。被切换隐藏的系列保留自己的条目位置并淡化显示——布局不回流，用户下一次点击仍落在同一处。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.{Legend, LegendPosition}
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "月度营收")
    axes.add(LineSeries([1.0, 2.0, 3.0], [3.0, 4.0, 5.0], label: "三月"))
    axes.add(LineSeries([1.0, 2.0, 3.0], [2.0, 5.0, 4.0], label: "四月"))
    let legend: Legend = axes.legend
    legend.position = LegendPosition.OutsideRight
    FigureExport.renderToPng(figure, "legend.png", width: 800, height: 600)
    println(axes.legendEntries(figure.theme).size) // 输出: 2
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建默认配置的图例：位于右上角、纵向排列、带底板与边框。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`measure(...)`](#measure) | 计算图例容纳 `entries` 所需的尺寸；隐藏或条目为空时为 `(0.0, 0.0)`。 |
| [`draw(...)`](#draw) | 将图例绘制到 `rect`，并记录每个条目的命中矩形供 `entryAt` 响应点击。 |
| [`entryAt(px, py)`](#entryat) | 返回包含该像素的条目行下标，用于点击切换系列显隐。 |
| [`isHidden()`](#ishidden) | 当图例配置为不绘制时为 `true`。 |
| [`isOutside()`](#isoutside) | 当图例需要在绘图区之外占据独立条带时为 `true`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`position`](#position) | 图例的摆放位置；`Hidden` 完全跳过绘制。 |
| [`horizontal`](#horizontal) | 让条目横向排成一行而非纵向一列；位置为 `OutsideBottom` 时强制开启。 |
| [`showBackground`](#showbackground) | 是否绘制悬浮图例背后的圆角半透明底板。 |
| [`showBorder`](#showborder) | 是否沿底板绘制一圈细边框。 |

## 构造函数

### init

创建默认配置的图例：位于右上角、纵向排列、带底板与边框。

```cangjie
public init()
```

## 方法

### measure

计算图例容纳 `entries` 所需的尺寸；隐藏或条目为空时为 `(0.0, 0.0)`。

```cangjie
public func measure(canvas: Canvas, entries: Array<LegendEntry>, theme: Theme): (Float32, Float32)
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 用于文本测量；无渲染设备（headless）画布的文本测量返回 0，测得的尺寸相应偏小。
- `entries`: `Array<`[`LegendEntry`](../series/LegendEntry.md)`>` — 待排版的图例条目。
- `theme`: [`Theme`](../core/Theme.md) — 提供图例文字尺寸（`legendSize`）。

**返回值** `(Float32, Float32)` — 宽与高，逻辑像素。

### draw

将图例绘制到 `rect`，并记录每个条目的命中矩形供 `entryAt` 响应点击。`rect` 不应小于 [`measure`](#measure) 报告的尺寸。`hidden` 中标记为 `true` 的条目保留位置、降为淡色显示，布局不回流。

```cangjie
public func draw(canvas: Canvas, rect: Rect, entries: Array<LegendEntry>, theme: Theme, hidden: Array<Bool>): Unit
```

**参数**

- `canvas`: `Canvas` — 目标画布。
- `rect`: `Rect` — 图例占据的矩形，逻辑像素。
- `entries`: `Array<LegendEntry>` — 要绘制的图例条目。
- `theme`: `Theme` — 底板、边框与文字颜色的来源。
- `hidden`: `Array<Bool>` — 与 `entries` 按下标对齐的隐藏标记；长度不足时，缺少标记的条目视为未隐藏。

### entryAt

返回包含该像素的条目行下标，用于点击切换系列显隐。命中矩形来自上一次 `draw`；尚未绘制或点不在任何条目行内时为 `None`。

```cangjie
public func entryAt(px: Float32, py: Float32): ?Int64
```

**参数**

- `px`: `Float32` — 像素横坐标，与上次 `draw` 同一坐标系。
- `py`: `Float32` — 像素纵坐标。

**返回值** `?Int64` — 条目在 `entries` 中的下标，或 `None`。

### isHidden

当图例配置为不绘制时为 `true`。即 `position` 为 [`LegendPosition`](LegendPosition.md)`.Hidden`。

```cangjie
public func isHidden(): Bool
```

**返回值** `Bool` — 是否跳过绘制。

### isOutside

当图例需要在绘图区之外占据独立条带时为 `true`。即 `position` 为 `OutsideRight` 或 `OutsideBottom`。

```cangjie
public func isOutside(): Bool
```

**返回值** `Bool` — 是否占据外部条带。

## 字段

### position

图例的摆放位置；`Hidden` 完全跳过绘制。

```cangjie
public var position: LegendPosition = LegendPosition.TopRight
```

### horizontal

让条目横向排成一行而非纵向一列；位置为 `OutsideBottom` 时强制开启。

```cangjie
public var horizontal: Bool = false
```

### showBackground

是否绘制悬浮图例背后的圆角半透明底板。

```cangjie
public var showBackground: Bool = true
```

### showBorder

是否沿底板绘制一圈细边框。

```cangjie
public var showBorder: Bool = true
```

## 另请参阅

- [LegendPosition](LegendPosition.md)
- [LegendEntry](../series/LegendEntry.md)
- [Axes](Axes.md)、[PieAxes](PieAxes.md)、[RadarAxes](RadarAxes.md) —— 均以 `legend` 字段内嵌一个图例
