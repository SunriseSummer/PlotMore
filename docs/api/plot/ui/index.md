[plot](../../index.md) › plot.ui

# plot.ui

```cangjie
import plot.ui.{Toolbar, ToolButton, Placement}
```

可选交互组件：[`Component`](Component.md) 抽象、工具栏、悬停读数、光标状态条与缩放/平移交互。组件全部可选——不加任何组件的 [`PlotWindow`](../PlotWindow.md) 就是一个静态查看器；`addStandardToolbar`、`enableHoverReadout` 等便捷方法在窗口上装配本包的现成组件，自定义组件则从 `Component` 派生后经 `addComponent` 停靠。注意：`Component.handle`、[`Interactions.handle`](Interactions.md#handle) 等事件入口以 `sdl` 的 `UiEvent` 为参数，该类型未经 `plot.core` 再导出——正常经由 `PlotWindow` 路由事件无需触及它，只有自行驱动事件循环时才需要直接依赖 `sdl`。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`Component`](Component.md) | 停靠在图形上方的交互式悬浮界面基类——工具栏、坐标读数、状态行都由它派生。 |
| [`ToolButton`](ToolButton.md) | 工具栏中的一个按钮：一个图标、一条悬停工具提示和一个动作。 |
| [`Toolbar`](Toolbar.md) | 停靠在图形上方的一行浮动图标按钮。 |
| [`Interactions`](Interactions.md) | 笛卡尔面板上的缩放、平移与框选缩放交互。 |
| [`HoverReadout`](HoverReadout.md) | 悬停检查器：穿过光标的十字光标、最近数据点上的高亮环，以及标注其数值的数值标签。 |
| [`CursorStatus`](CursorStatus.md) | 以数据坐标报告光标当前位置的状态行。 |

**结构体**

| 类型 | 说明 |
|---|---|
| [`EventResponse`](EventResponse.md) | 组件事件处理的结果：告知窗口事件是否已被消费、画面是否需要重绘。 |

**枚举**

| 类型 | 说明 |
|---|---|
| [`Placement`](Placement.md) | 组件在窗口内的停靠位置：上、下两条边各有左、中、右三个槽位。 |
| [`ToolIcon`](ToolIcon.md) | 工具栏按钮可显示的图标字形。 |
| [`InteractionMode`](InteractionMode.md) | 拖拽在绘图区上的行为模式。 |

## 函数

| 函数 | 说明 |
|---|---|
| [`drawToolIcon`](functions.md#drawtoolicon) | 在 `rect` 内居中描边绘制 `icon`。 |
