[plot](../../index.md) › [plot.axes](index.md) › Panel

# Panel

`plot.axes` 中的 public class（抽象基类）

图形网格中一块自成一体的绘图区域——所有面板类型的抽象基类。[Figure](../Figure.md) 把面板排进网格，每次绘制交给每个面板一个矩形；矩形内部如何布局与绘制完全由具体面板决定。

## 声明

```cangjie
public abstract class Panel
```

## 继承

- 本项目内的已知子类：[Axes](Axes.md)（笛卡尔面板）、[PieAxes](PieAxes.md)（饼图面板）、[RadarAxes](RadarAxes.md)（雷达图面板）。

## 说明

这条抽象接缝让几何上毫无共性的面板同处一图：饼图没有可共享的 x 标度，若强迫所有图表通过同一个笛卡尔轴类型，就会得到一半方法注明"此处无意义"的 API。子类只需实现 `draw`，即可经 [Figure.addPanel](../Figure.md#addpanel) 挂进网格。

交互事件到达在两帧之间，而面板最终落在哪里只有布局知道，因此每个子类在 `draw` 中把收到的矩形写入受保护字段 `lastRect`；`frame` 与 `containsPixel` 据此作答。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.{Axes, Panel}
import plot.series.LineSeries

main(): Unit {
    let axes = Axes()
    axes.add(LineSeries([0.0, 1.0, 2.0], [0.4, 0.9, 0.6], label: "样本"))

    // 图形网格正是通过 Panel 接口驱动每个面板的
    let panel: Panel = axes
    panel.title = "示例面板"
    let figure = Figure("面板示例")
    figure.addPanel(panel)
    FigureExport.renderToPng(figure, "panel.png", width: 640, height: 480)
    println(figure.panelCount()) // 输出: 1
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`draw(canvas, rect, theme)`](#draw) | 把面板渲染进 `rect`。 |
| [`frame()`](#frame) | 面板最近一次绘制时占据的矩形。 |
| [`containsPixel(px, py)`](#containspixel) | 当 `(px, py)` 落在面板最近一次绘制的矩形内时返回 `true`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`title`](#title) | 面板上方绘制的标题；为空则不绘制并让出空间。 |
| [`lastRect`](#lastrect) | （protected，仅子类可见）最近一次绘制时面板实际落到的矩形。 |

## 方法

### draw

把面板渲染进 `rect`。抽象方法：每个面板类型实现自己的布局与绘制，并在开始时把 `rect` 写入 `lastRect`。

```cangjie
public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标，见 [Canvas](../canvas/Canvas.md)。
- `rect`: `Rect` — 面板可用的矩形，逻辑像素。
- `theme`: `Theme` — 配色与字号，见 [Theme](../core/Theme.md)。

### frame

面板最近一次绘制时占据的矩形。尚未绘制过时为零矩形。

```cangjie
public func frame(): Rect
```

**返回值** `Rect` — 逻辑像素下的面板矩形。

### containsPixel

当 `(px, py)` 落在面板最近一次绘制的矩形内时返回 `true`。交互层用它把两帧之间到达的窗口事件路由给正确的面板。

```cangjie
public func containsPixel(px: Float32, py: Float32): Bool
```

**参数**

- `px`: `Float32` — 水平像素坐标（逻辑像素）。
- `py`: `Float32` — 竖直像素坐标（逻辑像素）。

**返回值** `Bool` — 点在最近一次绘制的矩形内为 `true`；尚未绘制过时按零矩形判断。

## 字段

### title

面板上方绘制的标题；为空则不绘制并让出空间。

```cangjie
public var title: String = ""
```

### lastRect

（protected，仅子类可见）最近一次绘制时面板实际落到的矩形。子类在 `draw` 中写入它，`frame` 与 `containsPixel` 由它作答。

```cangjie
protected var lastRect: Rect = Rect.zero()
```

## 另请参阅

- [Figure](../Figure.md) — `addPanel` 把任意面板挂进图形网格
- [Axes](Axes.md)、[PieAxes](PieAxes.md)、[RadarAxes](RadarAxes.md) — 本库自带的三种面板
