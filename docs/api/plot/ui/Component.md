[plot](../../index.md) › [plot.ui](index.md) › Component

# Component

`plot.ui` 中的 public class（抽象基类）

停靠在图形上方的交互式悬浮界面基类——工具栏、坐标读数、状态行都由它派生。组件完全可选：不加任何组件的 [PlotWindow](../PlotWindow.md) 就是一个纯粹的图表查看器。窗口逐个度量组件、按其 [Placement](Placement.md) 停靠、在图形之后绘制，并把事件先于图形路由给它，悬浮界面因此在视觉与事件两个意义上都位于数据之上。

## 声明

```cangjie
public abstract class Component
```

## 继承

- 本项目内的已知子类：[Toolbar](Toolbar.md)、[CursorStatus](CursorStatus.md)。

## 说明

窗口每帧的组件流程：跳过 `visible` 为 `false` 的组件；调用 [measure](#measure)，宽或高不大于 0 的组件本帧不停靠、不绘制；按 [placement](#placement) 计算停靠矩形，同一槽位的多个组件按添加顺序依次堆叠；最后调用 [draw](#draw)。子类必须实现 `measure` 与 `draw`，可按需覆写 `placement` 与 [handle](#handle)；`draw` 中应调用 [setFrame](#setframe) 记录停靠矩形，[frame](#frame) 与 [containsPixel](#containspixel) 才能给出正确结果。

关于签名中的外部类型：`Size`、`Rect` 由 [plot.core](../core/index.md) 再导出，正常导入即可；而 `handle` 的事件类型 `UiEvent`（及其中的 `MouseButton`）来自底层 sdl 库，plot.core **不**再导出它们——覆写 `handle` 或直接调用事件入口的工程，需要直接依赖 sdl 才能写出 `UiEvent` 这个类型名。通常无须如此：`PlotWindow` 负责构造并路由全部事件，多数用户从不亲手构造一个 `UiEvent`。

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.canvas.Canvas
import plot.core.{Rect, Size, Theme}
import plot.ui.{Component, Placement}

// 最小组件：在停靠矩形处画一块圆角底色牌
class Badge <: Component {
    public init() {
        super()
    }

    public func measure(canvas: Canvas, theme: Theme): Size {
        Size(60.0, 20.0)
    }

    public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        setFrame(rect) // 记录停靠矩形，事件命中测试才有依据
        canvas.fillRoundedRect(rect, theme.cornerRadius, theme.surface)
    }

    public override func placement(): Placement {
        Placement.BottomLeft
    }
}

main(): Unit {
    let badge = Badge()
    let window = PlotWindow(Figure("徽章示例"))
    window.addComponent(badge)
    window.show()
    // 交互结果：徽章按 Component 布局流程停靠在窗口左下角。
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`measure(canvas, theme)`](#measure) | 返回组件想要的尺寸，按当前主题的度量计算；抽象方法，子类必须实现。 |
| [`draw(canvas, rect, theme)`](#draw) | 把组件绘制到窗口停靠它的矩形里；抽象方法，子类必须实现。 |
| [`placement()`](#placement) | 返回组件在窗口中的停靠位置，默认右上角（`Placement.TopRight`）。 |
| [`handle(event)`](#handle) | 处理一个窗口事件；默认实现忽略一切。 |
| [`frame()`](#frame) | 返回组件最近一次占据的停靠矩形。 |
| [`containsPixel(px, py)`](#containspixel) | 判断窗口像素 `(px, py)` 是否落在组件最近一次的停靠矩形内。 |
| [`setFrame(rect)`](#setframe) | （protected，仅子类可见）记录停靠矩形。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`visible`](#visible) | 组件是否绘制并接收事件。 |
| [`lastFrame`](#lastframe) | （protected，仅子类可见）组件最近一次绘制时停靠的矩形。 |

## 方法

### measure

返回组件想要的尺寸，按当前主题的度量计算；抽象方法，子类必须实现。窗口每帧调用；返回宽或高不大于 0 时，本帧跳过该组件。

```cangjie
public func measure(canvas: Canvas, theme: Theme): Size
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 用于文本宽高等度量。
- `theme`: [`Theme`](../core/Theme.md) — 提供字号、留白等度量依据。

**返回值** `Size` — 期望的宽高，逻辑像素。

### draw

把组件绘制到窗口停靠它的矩形里；抽象方法，子类必须实现。实现应调用 [setFrame](#setframe) 记录 `rect`。

```cangjie
public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标。
- `rect`: `Rect` — 窗口分配的停靠矩形，窗口像素。
- `theme`: `Theme` — 配色与度量。

### placement

返回组件在窗口中的停靠位置，默认右上角（`Placement.TopRight`）。可覆写。

```cangjie
public open func placement(): Placement
```

**返回值** [`Placement`](Placement.md) — 停靠槽位。

### handle

处理一个窗口事件；默认实现忽略一切。窗口在图形处理事件之前调用它；参数类型 `UiEvent` 未经 plot.core 再导出，见[说明](#说明)。

```cangjie
public open func handle(event: UiEvent): EventResponse
```

**参数**

- `event`: `UiEvent` — 窗口坐标下的输入事件。

**返回值** [`EventResponse`](EventResponse.md) — 事件是否被消费、是否需要重绘；默认为 `EventResponse.ignored()`。

### frame

返回组件最近一次占据的停靠矩形。

```cangjie
public func frame(): Rect
```

**返回值** `Rect` — 最近一次 `draw` 经 [setFrame](#setframe) 记录的矩形；尚未绘制过时为 `Rect.zero()`。

### containsPixel

判断窗口像素 `(px, py)` 是否落在组件最近一次的停靠矩形内。组件不可见时恒为 `false`。

```cangjie
public func containsPixel(px: Float32, py: Float32): Bool
```

**参数**

- `px`: `Float32` — 窗口像素 x 坐标。
- `py`: `Float32` — 窗口像素 y 坐标。

**返回值** `Bool` — 可见且点在停靠矩形内时为 `true`。

### setFrame

（protected，仅子类可见）记录停靠矩形。在 `draw` 里调用，事件才能与只有布局才知道的停靠矩形比对。

```cangjie
protected func setFrame(rect: Rect): Unit
```

**参数**

- `rect`: `Rect` — 本次绘制的停靠矩形，窗口像素。

## 字段

### visible

组件是否绘制并接收事件。为 `false` 时窗口整帧跳过它，[containsPixel](#containspixel) 恒为 `false`。

```cangjie
public var visible: Bool = true
```

### lastFrame

（protected，仅子类可见）组件最近一次绘制时停靠的矩形。经 [setFrame](#setframe) 写入、[frame](#frame) 读取。

```cangjie
protected var lastFrame: Rect = Rect.zero()
```

## 另请参阅

- [PlotWindow.addComponent](../PlotWindow.md#addcomponent)
- [Placement](Placement.md)
- [EventResponse](EventResponse.md)
