[plot](../../index.md) › [plot.ui](index.md) › ToolIcon

# ToolIcon

`plot.ui` 中的 public enum

工具栏按钮可显示的图标字形。由 [drawToolIcon](functions.md#drawtoolicon) 绘制，[ToolButton](ToolButton.md) 构造时选定。

## 声明

```cangjie
public enum ToolIcon
```

## 说明

这些图标由线段、圆等图元描边而成，不取自图标字体或位图。直接描边无需分发额外字体或位图，并会使用当前主题颜色显示。

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.ui.{ToolButton, ToolIcon, Toolbar}

main(): Unit {
    let window = PlotWindow(Figure("图标字形"))
    let toolbar = Toolbar()
    let icon: ToolIcon = ToolIcon.Home
    toolbar.add(ToolButton(icon, tooltip: "复位", action: {=> ()}))
    toolbar.add(ToolButton(ToolIcon.ZoomIn, tooltip: "放大", action: {=> ()}))
    window.addComponent(toolbar)
    window.show()
    // 交互结果：工具栏显示 Home 与 ZoomIn 两个主题着色的线条图标。
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Save` | 托盘上方的下载箭头——保存到文件。 |
| `ZoomIn` | 带加号的放大镜。 |
| `ZoomOut` | 带减号的放大镜。 |
| `Pan` | 四向箭头——拖拽平移。 |
| `BoxZoom` | 虚线矩形——拖拽框选缩放到某个区域。 |
| `Home` | 房子——恢复初始视图。 |
| `Grid` | 井字格——开关网格线。 |
| `LegendIcon` | 层叠的行——开关图例。 |
| `ThemeIcon` | 半填充圆——切换亮/暗主题。 |
| `Crosshair` | 十字光标——开关悬停读数。 |

## 另请参阅

- [drawToolIcon](functions.md#drawtoolicon)
- [ToolButton](ToolButton.md)
- [Toolbar](Toolbar.md)
