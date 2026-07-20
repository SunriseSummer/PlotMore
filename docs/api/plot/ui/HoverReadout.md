[plot](../../index.md) › [plot.ui](index.md) › HoverReadout

# HoverReadout

`plot.ui` 中的 public class

悬停检查器：穿过光标的十字光标、最近数据点上的高亮环，以及标注其数值的数值标签。吸附到最近的数据点而非报告光标原始位置正是它的价值——样本明明在 (4, 1) 时，读出「3.97, 1.02」只是噪声。[hitRadius](#hitradius) 限定吸附距离，空白区域里数值标签随之消失，而不是指向远处的点。

## 声明

```cangjie
public class HoverReadout
```

## 说明

命中测试交给 [Axes.hitTest](../axes/Axes.md#hittest)，得到的 [HitResult](../series/HitResult.md) 提供吸附点的像素位置、系列颜色与文本，数值标签直接取用。[PlotWindow](../PlotWindow.md) 内建一个实例（`hover` 字段）但默认关闭——它让窗口在每次指针移动时都重绘，大型系列会因此增加每帧的命中测试与绘制工作；用 [PlotWindow.enableHoverReadout](../PlotWindow.md#enablehoverreadout) 开启。想读光标本身的位置而非最近样本，用 [CursorStatus](CursorStatus.md)。

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.series.LineSeries
import plot.ui.HoverReadout

main(): Unit {
    let (figure, axes) = Figure.single(title: "采样浏览")
    axes.add(LineSeries([0.0, 1.0, 2.0], [0.2, 0.9, 0.5], label: "样本"))
    let window = PlotWindow(figure)
    let readout: HoverReadout = window.enableHoverReadout() // 悬停读数默认关闭，需显式开启
    readout.hitRadius = 16.0 // 收紧吸附半径（默认 28 逻辑像素）
    readout.showCrosshair = false // 只要高亮环与数值标签
    window.show()
    // 交互结果：光标靠近数据点时高亮该点并弹出数值标签。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建全部开关取默认值的悬停读数。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`handle(event, axes)`](#handle) | 记录光标位置，返回该帧是否需要重绘。 |
| [`clear()`](#clear) | 忘记光标，例如指针离开面板时。 |
| [`draw(canvas, axes, theme)`](#draw) | 在 `axes` 的数据区上绘制十字光标、命中高亮与数值标签。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`showCrosshair`](#showcrosshair) | 是否绘制穿过光标的十字光标线。 |
| [`showChip`](#showchip) | 是否绘制吸附点的数值标签。 |
| [`showHighlight`](#showhighlight) | 是否以高亮环标出吸附到的数据点。 |
| [`hitRadius`](#hitradius) | 光标与数据点相距多少像素以内才吸附并显示读数，默认 `28.0`。 |

## 构造函数

### init

创建全部开关取默认值的悬停读数。

```cangjie
public init()
```

## 方法

### handle

记录光标位置，返回该帧是否需要重绘。只响应指针移动事件；事件类型 `UiEvent` 未经 plot.core 再导出，说明见 [Interactions](Interactions.md#说明)。

```cangjie
public func handle(event: UiEvent, axes: Axes): Bool
```

**参数**

- `event`: `UiEvent` — 窗口事件；只有 `MouseMove` 有效，其余一律返回 `false`。
- `axes`: [`Axes`](../axes/Axes.md) — 提供数据区判定。

**返回值** `Bool` — 光标当前位于数据区内、或刚从数据区移出时为 `true`（两种情况画面都变了）。

### clear

忘记光标，例如指针离开面板时。此后 [draw](#draw) 不再绘制任何内容，直到下一次数据区内的移动。

```cangjie
public func clear(): Unit
```

### draw

在 `axes` 的数据区上绘制十字光标、命中高亮与数值标签。光标尚未在数据区内移动过时什么都不画；命中点距光标超出 [hitRadius](#hitradius) 时只画十字光标，高亮与数值标签消失。数值标签避开命中点摆放，并始终收在数据区内——被裁掉的标签恰恰盖着最有趣的数据。

```cangjie
public func draw(canvas: Canvas, axes: Axes, theme: Theme): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 绘制目标。
- `axes`: `Axes` — 提供数据区与命中测试。
- `theme`: [`Theme`](../core/Theme.md) — 提供强调色与注记字号。

## 字段

### showCrosshair

是否绘制穿过光标的十字光标线。

```cangjie
public var showCrosshair: Bool = true
```

### showChip

是否绘制吸附点的数值标签。文本取自命中结果：有系列名时为「名称  数值」，否则只有数值。

```cangjie
public var showChip: Bool = true
```

### showHighlight

是否以高亮环标出吸附到的数据点。环采用命中系列自己的颜色。

```cangjie
public var showHighlight: Bool = true
```

### hitRadius

光标与数据点相距多少像素以内才吸附并显示读数，默认 `28.0`。

```cangjie
public var hitRadius: Float32 = HIT_RADIUS
```

## 另请参阅

- [PlotWindow.enableHoverReadout](../PlotWindow.md#enablehoverreadout)
- [HitResult](../series/HitResult.md)
- [CursorStatus](CursorStatus.md)
- [Interactions](Interactions.md)
