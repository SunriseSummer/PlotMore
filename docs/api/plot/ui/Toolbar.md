[plot](../../index.md) › [plot.ui](index.md) › Toolbar

# Toolbar

`plot.ui` 中的 public class

停靠在图形上方的一行浮动图标按钮。完全可选：构造后经 [PlotWindow.addComponent](../PlotWindow.md#addcomponent) 挂到窗口，或调用 [PlotWindow.addStandardToolbar](../PlotWindow.md#addstandardtoolbar) 直接获得常用按钮组。按钮由调用方添加，定制工具栏只是 `add(ToolButton(...))` 的事，无须子类化。

## 声明

```cangjie
public class Toolbar <: Component
```

## 继承

- 父类：[Component](Component.md)。

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.ui.{Placement, ToolButton, ToolIcon, Toolbar}

main(): Unit {
    let window = PlotWindow(Figure("工具栏示例"))
    let toolbar = Toolbar(Placement.TopRight)
    toolbar.add(ToolButton(ToolIcon.Home, tooltip: "复位", action: {=> ()}))
    window.addComponent(toolbar)
    window.show()
    // 交互结果：右上角出现浮动工具栏，点击 Home 按钮执行 action。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建空工具栏，默认停靠在右上角。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`add(button)`](#add) | 添加一个按钮并原样返回它，便于继续配置。 |
| [`allButtons()`](#allbuttons) | 返回全部按钮，按添加顺序。 |
| [`setPlacement(placement)`](#setplacement) | 把工具栏改停靠到 `placement`。 |
| [`placement()`](#placement) | 返回当前停靠位置。 |
| [`measure(canvas, theme)`](#measure) | 返回工具栏想要的尺寸；没有按钮时为 (0, 0)。 |
| [`draw(canvas, rect, theme)`](#draw) | 在停靠矩形里绘制底板、按钮与工具提示。 |
| [`handle(event)`](#handle) | 处理鼠标事件，驱动按钮的悬停、按下与触发。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`showBackground`](#showbackground) | 是否绘制按钮后方的圆角底板。 |
| [`showTooltips`](#showtooltips) | 是否显示悬停按钮的工具提示。 |

## 构造函数

### init

创建空工具栏，默认停靠在右上角。带 `placement` 的重载停靠到指定槽位。

```cangjie
public init()
```

```cangjie
public init(placement: Placement)
```

**参数**

- `placement`: [`Placement`](Placement.md) — 停靠槽位。

## 方法

### add

添加一个按钮并原样返回它，便于继续配置。

```cangjie
public func add(button: ToolButton): ToolButton
```

**参数**

- `button`: [`ToolButton`](ToolButton.md) — 要加入的按钮，排在现有按钮之后。

**返回值** `ToolButton` — 传入的同一个按钮。

### allButtons

返回全部按钮，按添加顺序。返回的是工具栏内部列表本身，而非副本。

```cangjie
public func allButtons(): ArrayList<ToolButton>
```

**返回值** `ArrayList<ToolButton>` — 按钮列表，添加顺序。

### setPlacement

把工具栏改停靠到 `placement`。

```cangjie
public func setPlacement(placement: Placement): Unit
```

**参数**

- `placement`: `Placement` — 新的停靠槽位。

### placement

返回当前停靠位置。

```cangjie
public override func placement(): Placement
```

**返回值** `Placement` — 构造或 [setPlacement](#setplacement) 设定的槽位，默认 `Placement.TopRight`。

### measure

返回工具栏想要的尺寸；没有按钮时为 (0, 0)。尺寸只由按钮数决定：每个按钮 28×28 逻辑像素、按钮间距 3、四周留白 5，不依赖 `canvas` 与 `theme`。

```cangjie
public func measure(canvas: Canvas, theme: Theme): Size
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 未参与计算。
- `theme`: [`Theme`](../core/Theme.md) — 未参与计算。

**返回值** `Size` — 期望的宽高，逻辑像素；空工具栏为 `Size.zero()`，窗口随即跳过停靠。

### draw

在停靠矩形里绘制底板、按钮与工具提示。底板受 [showBackground](#showbackground) 控制（浅色主题另加柔和投影，深色主题省略，黑晕在暗底上读作污渍而非悬浮）；工具提示在工具栏停靠于上边缘时出现在栏下方、停靠于下边缘时出现在栏上方，避免超出窗口。

```cangjie
public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标。
- `rect`: `Rect` — 窗口分配的停靠矩形，窗口像素。
- `theme`: `Theme` — 配色与圆角。

### handle

处理鼠标事件，驱动按钮的悬停、按下与触发。只响应鼠标左键；悬停变化只重绘、不拦截事件——窗口自己的十字光标仍需要这次指针移动，否则读数会在指针扫过工具栏时停住。按下落在启用按钮上即消费；松开时，仅当按下与松开落在同一启用按钮上才触发（拖离按钮即取消）；开关按钮先翻转 `active` 再调用 `action`。

```cangjie
public override func handle(event: UiEvent): EventResponse
```

**参数**

- `event`: `UiEvent` — 窗口坐标下的鼠标事件；非左键与其他事件一律忽略。

**返回值** [`EventResponse`](EventResponse.md) — 悬停变化为 `repaint()`，按下/触发为 `handled()`，其余为 `ignored()`；工具栏不可见或没有按钮时恒为 `ignored()`。

## 字段

### showBackground

是否绘制按钮后方的圆角底板。

```cangjie
public var showBackground: Bool = true
```

### showTooltips

是否显示悬停按钮的工具提示。提示文本为空或按钮被禁用时不显示。

```cangjie
public var showTooltips: Bool = true
```

## 另请参阅

- [ToolButton](ToolButton.md)
- [ToolIcon](ToolIcon.md)
- [PlotWindow.addComponent](../PlotWindow.md#addcomponent)
- [PlotWindow.addStandardToolbar](../PlotWindow.md#addstandardtoolbar)
