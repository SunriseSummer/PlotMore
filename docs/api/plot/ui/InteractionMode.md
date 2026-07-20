[plot](../../index.md) › [plot.ui](index.md) › InteractionMode

# InteractionMode

`plot.ui` 中的 public enum

拖拽在绘图区上的行为模式。赋给 [Interactions.mode](Interactions.md#mode)；滚轮缩放不受模式影响，由 [Interactions.wheelZoom](Interactions.md#wheelzoom) 单独控制。

## 声明

```cangjie
public enum InteractionMode
```

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.series.LineSeries
import plot.ui.InteractionMode

main(): Unit {
    let (figure, axes) = Figure.single(title: "框选缩放")
    axes.add(LineSeries([0.0, 1.0, 2.0], [0.2, 0.9, 0.5]))
    let window = PlotWindow(figure)
    let mode: InteractionMode = InteractionMode.BoxZoom
    window.interactions.mode = mode
    window.show()
    // 交互结果：在数据区拖拽框出矩形，松开后缩放到该范围。
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `PanZoom` | 拖拽平移；滚轮缩放。默认值。 |
| `BoxZoom` | 拖拽画出矩形，松开时缩放到该区域。 |
| `Inspect` | 拖拽不做任何事。 |

## 另请参阅

- [Interactions](Interactions.md)
