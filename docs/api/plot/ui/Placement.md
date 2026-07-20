[plot](../../index.md) › [plot.ui](index.md) › Placement

# Placement

`plot.ui` 中的 public enum

组件在窗口内的停靠位置：上、下两条边各有左、中、右三个槽位。[Component.placement](Component.md#placement) 报告此值，[PlotWindow](../PlotWindow.md) 布局时据此停靠组件；同一槽位的多个组件按添加顺序依次堆叠。

## 声明

```cangjie
public enum Placement
```

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.ui.{CursorStatus, Placement, Toolbar}

main(): Unit {
    let window = PlotWindow(Figure("停靠位置"))
    window.addComponent(Toolbar(Placement.TopLeft))
    window.addComponent(CursorStatus(Placement.BottomRight))
    window.show()
    // 交互结果：工具栏停靠在左上角，坐标读数停靠在右下角。
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `TopLeft` | 停靠在窗口上边缘左侧。 |
| `TopCenter` | 停靠在窗口上边缘居中。 |
| `TopRight` | 停靠在窗口上边缘右侧。 |
| `BottomLeft` | 停靠在窗口下边缘左侧。 |
| `BottomCenter` | 停靠在窗口下边缘居中。 |
| `BottomRight` | 停靠在窗口下边缘右侧。 |

## 另请参阅

- [Component](Component.md)
- [PlotWindow.addComponent](../PlotWindow.md#addcomponent)
