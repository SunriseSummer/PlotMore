[plot](../../index.md) › [plot.ui](index.md) › ToolButton

# ToolButton

`plot.ui` 中的 public class

工具栏中的一个按钮：一个图标、一条悬停工具提示和一个动作。按钮可设为开关型（[toggle](#toggle)），保持开/关状态并高亮显示——模式类按钮（平移、框选缩放）必须显示模式已启用，而单发按钮（保存、复位）无状态可显示。经 [Toolbar.add](Toolbar.md#add) 加入工具栏。

## 声明

```cangjie
public class ToolButton
```

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.ui.{ToolButton, ToolIcon, Toolbar}

main(): Unit {
    let window = PlotWindow(Figure("工具按钮"))
    let toolbar = Toolbar()
    // 模式按钮：开关型，点击后保持开/关状态
    let pan = ToolButton(ToolIcon.Pan, tooltip: "拖拽平移", action: {=> ()})
    pan.toggle = true
    toolbar.add(pan)
    // 单发按钮：按一次触发一次；先禁用，等有内容可保存时再启用
    let save = ToolButton(ToolIcon.Save, tooltip: "保存图像", action: {=> println("保存")})
    save.enabled = false
    toolbar.add(save)
    window.addComponent(toolbar)
    window.show()
    // 交互结果：平移按钮保持开关状态，保存按钮以禁用样式显示。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 以图标、工具提示与动作创建按钮。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`icon`](#icon) | 按钮绘制的图标字形。 |
| [`tooltip`](#tooltip) | 悬停时显示的工具提示文本。 |
| [`action`](#action) | 按钮被点击时执行的动作。 |
| [`toggle`](#toggle) | 为 `true` 时按钮保持开/关状态，而非按一次触发一次。 |
| [`active`](#active) | 开关状态，仅在 `toggle` 为 `true` 时有意义。 |
| [`enabled`](#enabled) | 按钮是否响应；禁用的按钮灰显。 |

## 构造函数

### init

以图标、工具提示与动作创建按钮。`toggle`、`active`、`enabled` 随后按字段配置。

```cangjie
public init(icon: ToolIcon, tooltip!: String = "", action!: () -> Unit = {=> ()})
```

**参数**

- `icon`: [`ToolIcon`](ToolIcon.md) — 按钮字形。
- `tooltip!`: `String` — 工具提示文本，默认空串（不显示提示）。
- `action!`: `() -> Unit` — 点击动作，默认空操作。

## 字段

### icon

按钮绘制的图标字形。

```cangjie
public let icon: ToolIcon
```

### tooltip

悬停时显示的工具提示文本。为空时不显示；图标独自很难猜，值得写上一条。

```cangjie
public var tooltip: String
```

### action

按钮被点击时执行的动作。在按下与松开落于同一按钮时触发，见 [Toolbar.handle](Toolbar.md#handle)。

```cangjie
public var action: () -> Unit
```

### toggle

为 `true` 时按钮保持开/关状态，而非按一次触发一次。

```cangjie
public var toggle: Bool = false
```

### active

开关状态，仅在 `toggle` 为 `true` 时有意义。点击时先翻转再调用 `action`，动作里读到的已是新状态；激活的按钮以主题强调色绘制。

```cangjie
public var active: Bool = false
```

### enabled

按钮是否响应；禁用的按钮灰显。禁用时不高亮悬停、不触发动作、也不显示工具提示。

```cangjie
public var enabled: Bool = true
```

## 另请参阅

- [Toolbar](Toolbar.md)
- [ToolIcon](ToolIcon.md)
- [PlotWindow.addStandardToolbar](../PlotWindow.md#addstandardtoolbar)
