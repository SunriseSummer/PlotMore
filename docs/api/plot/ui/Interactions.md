[plot](../../index.md) › [plot.ui](index.md) › Interactions

# Interactions

`plot.ui` 中的 public class

笛卡尔面板上的缩放、平移与框选缩放交互。全部通过改写坐标轴的视图区间实现，因此与任何图表类型自动组合。[PlotWindow](../PlotWindow.md) 内建一个实例（`interactions` 字段）并把窗口事件路由给它，多数用户只需设置本类的开关字段。

## 声明

```cangjie
public class Interactions
```

## 说明

一切都只改写 [Axes](../axes/Axes.md) 的视图区间：[handle](#handle) 经 [Axes.setView](../axes/Axes.md#setview) 写入，系列经投影绘制、投影读取视图，所以每种图表类型都天然支持缩放与平移。[Axes.resetView](../axes/Axes.md#resetview)（或 [PlotWindow.resetAllViews](../PlotWindow.md#resetallviews)）丢弃视图，坐标轴回到作者设定的范围或自动适配。

滚轮缩放以光标处的**数据坐标**为锚——指针下的数据点保持在指针下，否则围绕面板中心缩放就无法放大角落。每格滚轮把可见范围乘或除以 1.15（约 13%）；缩放交由各轴的 [Scale.zoomAround](../core/Scale.md#zoomaround) 在自身几何中完成，对数轴因此按对数几何缩放。拖拽平移在按下瞬间冻结区间、此后每次移动都从冻结值偏移，避免跨拖拽累计舍入漂移。

关于签名中的外部类型：`handle` 的事件类型 `UiEvent`（及其中的 `MouseButton`）来自底层 sdl 库，plot.core **不**再导出它们——直接调用 `handle` 的工程需要直接依赖 sdl 才能写出 `UiEvent` 这个类型名。通常无须如此：`PlotWindow` 已负责构造并路由事件，多数用户从不亲手构造一个 `UiEvent`。

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.series.LineSeries
import plot.ui.Interactions

main(): Unit {
    let (figure, axes) = Figure.single(title: "传感器时间序列")
    axes.add(LineSeries([0.0, 1.0, 2.0], [0.2, 0.9, 0.5]))
    let window = PlotWindow(figure)
    // 时间序列：把缩放与平移都约束到 x 轴
    let interactions: Interactions = window.interactions
    interactions.lockY = true
    window.show()
    // 交互结果：滚轮以光标处为锚缩放 x 轴，拖拽只沿 x 轴平移。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建全部开关取默认值的交互控制器。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`isBoxing()`](#isboxing) | 报告是否正有框选缩放矩形在拖拽中。 |
| [`boxRect()`](#boxrect) | 返回当前正在拖拽的框选缩放矩形。 |
| [`handle(event, axes)`](#handle) | 把一个窗口事件路由到 `axes`，返回窗口是否应当重绘。 |
| [`drawOverlay(canvas, theme)`](#drawoverlay) | 绘制框选缩放的橡皮筋矩形。 |
| [`cancelDrag()`](#canceldrag) | 清除进行中的拖拽。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`mode`](#mode) | 拖拽执行的操作，默认 `PanZoom`。 |
| [`wheelZoom`](#wheelzoom) | 是否启用滚轮缩放，默认启用。 |
| [`dragPan`](#dragpan) | 是否启用 `PanZoom` 模式下的拖拽平移，默认启用。 |
| [`lockY`](#locky) | 把缩放与平移约束到 x 轴——时间序列的合适选择。 |
| [`lockX`](#lockx) | 把缩放与平移约束到 y 轴。 |

## 构造函数

### init

创建全部开关取默认值的交互控制器。

```cangjie
public init()
```

## 方法

### isBoxing

报告是否正有框选缩放矩形在拖拽中。窗口据此决定是否调用 [drawOverlay](#drawoverlay)。

```cangjie
public func isBoxing(): Bool
```

**返回值** `Bool` — 处于 `BoxZoom` 模式且拖拽进行中时为 `true`。

### boxRect

返回当前正在拖拽的框选缩放矩形。无论拖拽方向如何都已规范化（左上角加非负宽高）；仅在 [isBoxing](#isboxing) 为 `true` 时有意义。

```cangjie
public func boxRect(): Rect
```

**返回值** `Rect` — 起点与当前点张成的矩形，窗口像素。

### handle

把一个窗口事件路由到 `axes`，返回窗口是否应当重绘。滚轮在数据区内缩放（`dy` 为 0 时无操作）；左键在数据区内按下开始拖拽——`PanZoom` 且 [dragPan](#dragpan) 开启时平移，`BoxZoom` 时画框并在松开时缩放到框内，`Inspect` 不拖拽；宽或高不足 6 像素的框视为误击，忽略。[lockX](#lockx)/[lockY](#locky) 使对应轴的区间保持不变。

```cangjie
public func handle(event: UiEvent, axes: Axes): Bool
```

**参数**

- `event`: `UiEvent` — 窗口事件；只响应滚轮与左键的按下/移动/松开。
- `axes`: [`Axes`](../axes/Axes.md) — 目标坐标轴，视图经其 `setView` 改写。

**返回值** `Bool` — 需要重绘时为 `true`：通常因为视图已改写，框选拖拽进行中为刷新橡皮筋矩形也返回 `true`。

### drawOverlay

绘制框选缩放的橡皮筋矩形。由窗口在框选拖拽进行中调用；矩形宽或高不足 1 像素时不绘制。

```cangjie
public func drawOverlay(canvas: Canvas, theme: Theme): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 绘制目标。
- `theme`: [`Theme`](../core/Theme.md) — 提供强调色，矩形以其半透明填充加虚线描边。

### cancelDrag

清除进行中的拖拽。供模式在拖拽中途被切换时调用，避免残留的拖拽状态继续生效。

```cangjie
public func cancelDrag(): Unit
```

## 字段

### mode

拖拽执行的操作，默认 `PanZoom`。取值见 [InteractionMode](InteractionMode.md)。

```cangjie
public var mode: InteractionMode = InteractionMode.PanZoom
```

### wheelZoom

是否启用滚轮缩放，默认启用。

```cangjie
public var wheelZoom: Bool = true
```

### dragPan

是否启用 `PanZoom` 模式下的拖拽平移，默认启用。

```cangjie
public var dragPan: Bool = true
```

### lockY

把缩放与平移约束到 x 轴——时间序列的合适选择。开启后 y 轴区间在滚轮、平移与框选中均保持不变。

```cangjie
public var lockY: Bool = false
```

### lockX

把缩放与平移约束到 y 轴。开启后 x 轴区间在滚轮、平移与框选中均保持不变。

```cangjie
public var lockX: Bool = false
```

## 另请参阅

- [InteractionMode](InteractionMode.md)
- [Axes](../axes/Axes.md)
- [Scale.zoomAround](../core/Scale.md#zoomaround)
- [PlotWindow](../PlotWindow.md)
