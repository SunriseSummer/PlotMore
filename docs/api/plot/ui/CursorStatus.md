[plot](../../index.md) › [plot.ui](index.md) › CursorStatus

# CursorStatus

`plot.ui` 中的 public class

以数据坐标报告光标当前位置的状态行。与 [HoverReadout](HoverReadout.md) 互补：那个吸附到最近的数据点，这个报告指针真实所在——读一片区域而非某个样本时正需要它。经 [PlotWindow.addComponent](../PlotWindow.md#addcomponent) 挂到窗口，或直接调用 [PlotWindow.addCursorStatus](../PlotWindow.md#addcursorstatus)。

## 声明

```cangjie
public class CursorStatus <: Component
```

## 继承

- 父类：[Component](Component.md)。

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.series.LineSeries
import plot.ui.{CursorStatus, Placement}

main(): Unit {
    let (figure, axes) = Figure.single(title: "坐标读数")
    axes.add(LineSeries([0.0, 1.0, 2.0], [0.2, 0.9, 0.5]))
    let window = PlotWindow(figure)
    let status = CursorStatus(Placement.BottomLeft)
    status.prefix = "位置 " // 读数显示为「位置 x, y」
    window.addComponent(status)
    window.show()
    // 交互结果：光标在数据区内移动时，左下角显示其数据坐标。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建状态行，默认停靠在右下角。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`placement()`](#placement) | 返回状态行的停靠位置。 |
| [`update(event, axes)`](#update) | 根据光标位置刷新读数文本，返回文本是否变化。 |
| [`measure(canvas, theme)`](#measure) | 返回读数条想要的尺寸；文本为空时为 (0, 0)。 |
| [`draw(canvas, rect, theme)`](#draw) | 在停靠矩形里绘制带边框的读数条。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`prefix`](#prefix) | 显示在坐标前的前缀，例如轴名。 |

## 构造函数

### init

创建状态行，默认停靠在右下角。带 `placement` 的重载停靠到指定槽位。

```cangjie
public init()
```

```cangjie
public init(placement: Placement)
```

**参数**

- `placement`: [`Placement`](Placement.md) — 停靠槽位。

## 方法

### placement

返回状态行的停靠位置。

```cangjie
public override func placement(): Placement
```

**返回值** `Placement` — 构造时选定的槽位，默认 `Placement.BottomRight`。

### update

根据光标位置刷新读数文本，返回文本是否变化。光标在数据区内时，文本为 `prefix` 加上光标数据坐标的紧凑格式（[NumberFormat.compact](../core/NumberFormat.md#compact)）；在数据区外时文本清空、读数条随之消失。事件类型 `UiEvent` 未经 plot.core 再导出，说明见 [Interactions](Interactions.md#说明)。

```cangjie
public func update(event: UiEvent, axes: Axes): Bool
```

**参数**

- `event`: `UiEvent` — 窗口事件；只有 `MouseMove` 有效，其余一律返回 `false`。
- `axes`: [`Axes`](../axes/Axes.md) — 提供数据区判定与像素到数据坐标的投影。

**返回值** `Bool` — 文本与上次不同（需要重绘）时为 `true`。

### measure

返回读数条想要的尺寸；文本为空时为 (0, 0)。宽度随文本变化，窗口每帧重新度量，因此不会因尺寸滞后而闪烁。

```cangjie
public func measure(canvas: Canvas, theme: Theme): Size
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 用于文本宽高度量。
- `theme`: [`Theme`](../core/Theme.md) — 提供注记字号。

**返回值** `Size` — 文本尺寸加内边距，逻辑像素；文本为空时为 `Size.zero()`，窗口随即跳过停靠。

### draw

在停靠矩形里绘制带边框的读数条。文本为空时什么都不画。

```cangjie
public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标。
- `rect`: `Rect` — 窗口分配的停靠矩形，窗口像素。
- `theme`: `Theme` — 提供底色、边框色与弱化文字色。

## 字段

### prefix

显示在坐标前的前缀，例如轴名。默认空串。

```cangjie
public var prefix: String = ""
```

## 另请参阅

- [HoverReadout](HoverReadout.md)
- [PlotWindow.addCursorStatus](../PlotWindow.md#addcursorstatus)
- [Placement](Placement.md)
