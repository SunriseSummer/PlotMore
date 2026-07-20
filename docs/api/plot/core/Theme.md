[plot](../../index.md) › [plot.core](index.md) › Theme

# Theme

`plot.core` 中的 public class

图形绘制所用的全部颜色、字号与粗细设置。主题刻意做成可变类而非不可变值：它是配置，常见姿势是取一个预设、只调整两三个字段（`palette`、`background`），而不是重述全部三十项。

## 声明

```cangjie
public class Theme
```

## 说明

从 [`light()`](#light) 或 [`dark()`](#dark) 出发，覆盖需要的字段；要在不改动预设的前提下派生变体，先 [`copy()`](#copy) 再改。

## 示例

```cangjie verify
package demo

import plot.core.Theme

main(): Unit {
    // 从暗色预设出发
    let dark = Theme.dark()
    println(dark.isDark)              // 输出: true
    println(dark.palette.size())      // 输出: 8

    // 派生副本，调整不会回写预设
    let custom = dark.copy()
    custom.panelBordered = false
    println(dark.panelBordered)       // 输出: true
    println(custom.panelBordered)     // 输出: false
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 以浅色默认值创建主题，等同于 `light()` 预设。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static light()`](#light) | 灰调克制的干净浅色主题——默认主题。 |
| [`static lightPanel()`](#lightpanel) | 面板带浅灰底色的浅色主题，更接近经典科学绘图的外观。 |
| [`static dark()`](#dark) | 为深色背景调校的主题，调色板在面板上保持对比度。 |
| [`static publication()`](#publication) | 高对比、色觉安全的出版物主题。 |
| [`copy()`](#copy) | 返回独立副本，调整派生主题不会改动它来自的预设。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`background`](#background) | 整个图形的底色，位于标题与图例之后，也位于绘图面板之后。 |
| [`panel`](#panel) | 绘图面板自身的底色；与 `background` 稍有区分即可让面板轮廓分明。 |
| [`text`](#text) | 主文字颜色：标题与轴标题。 |
| [`mutedText`](#mutedtext) | 次要文字颜色：刻度标签、说明文字与标注。 |
| [`grid`](#grid) | 主网格线颜色。 |
| [`gridMinor`](#gridminor) | 次网格线颜色，比主网格线更浅。 |
| [`axis`](#axis) | 轴线与刻度短线的颜色。 |
| [`border`](#border) | 面板边框与分隔线的颜色。 |
| [`accent`](#accent) | 交互强调色：焦点环、选区与十字光标。 |
| [`surface`](#surface) | 悬浮界面——工具栏、提示框、图例底板——的表面色。 |
| [`surfaceHover`](#surfacehover) | 交互悬浮界面的悬停态颜色。 |
| [`surfaceActive`](#surfaceactive) | 交互悬浮界面的按下／激活态颜色。 |
| [`palette`](#palette) | 分类系列用色的调色板。 |
| [`colormap`](#colormap) | 热力图等按值取色时默认使用的连续色标。 |
| [`titleSize`](#titlesize) | 图形标题字号。 |
| [`subtitleSize`](#subtitlesize) | 图形副标题字号。 |
| [`labelSize`](#labelsize) | 轴标题字号。 |
| [`tickSize`](#ticksize) | 刻度标签字号。 |
| [`legendSize`](#legendsize) | 图例条目字号。 |
| [`annotationSize`](#annotationsize) | 标注与读数字号。 |
| [`lineWidth`](#linewidth) | 数据线的默认宽度，单位为逻辑像素。 |
| [`markerSize`](#markersize) | 数据点标记的默认半径，单位为逻辑像素。 |
| [`cornerRadius`](#cornerradius) | 面板、提示框与工具栏按钮的圆角半径。 |
| [`isDark`](#isdark) | 主题是否为暗色；组件据此合理选择阴影与遮罩强度。 |
| [`panelFilled`](#panelfilled) | 绘图面板是否填充与图形底色不同的背景。 |
| [`panelBordered`](#panelbordered) | 绘图面板是否绘制边框。 |

## 构造函数

### init

以浅色默认值创建主题，等同于 `light()` 预设。

```cangjie
public init()
```

## 方法

### light

灰调克制的干净浅色主题——默认主题。即全部字段的默认值。

```cangjie
public static func light(): Theme
```

**返回值** `Theme` — 新的浅色主题实例。

### lightPanel

面板带浅灰底色的浅色主题，更接近经典科学绘图的外观。在 `light()` 基础上把 `panel` 设为 `#F9FAFB` 并开启 `panelFilled`。

```cangjie
public static func lightPanel(): Theme
```

**返回值** `Theme` — 新的浅色主题实例。

### dark

为深色背景调校的主题，调色板在面板上保持对比度。改用 [`Palette.vivid()`](Palette.md#vivid) 调色板，`isDark` 与 `panelFilled` 为 `true`。

```cangjie
public static func dark(): Theme
```

**返回值** `Theme` — 新的暗色主题实例。

### publication

高对比、色觉安全的出版物主题。文字与轴线纯黑，调色板换成 [`Palette.colorblindSafe()`](Palette.md#colorblindsafe)，色标换成 [`Colormap.cividis()`](Colormap.md#cividis)，线宽收紧到 1.6，圆角归零。

```cangjie
public static func publication(): Theme
```

**返回值** `Theme` — 新的出版物主题实例。

### copy

返回独立副本，调整派生主题不会改动它来自的预设。全部字段逐一复制。

```cangjie
public func copy(): Theme
```

**返回值** `Theme` — 字段值与当前主题一致的新实例。

## 字段

### background

整个图形的底色，位于标题与图例之后，也位于绘图面板之后。

```cangjie
public var background: Color = Colors.hex("#FFFFFF")
```

### panel

绘图面板自身的底色；与 `background` 稍有区分即可让面板轮廓分明。

```cangjie
public var panel: Color = Colors.hex("#FFFFFF")
```

### text

主文字颜色：标题与轴标题。

```cangjie
public var text: Color = Colors.hex("#111827")
```

### mutedText

次要文字颜色：刻度标签、说明文字与标注。

```cangjie
public var mutedText: Color = Colors.hex("#6B7280")
```

### grid

主网格线颜色。刻意保持浅淡：数据应当压过辅助线。

```cangjie
public var grid: Color = Colors.hex("#E5E7EB")
```

### gridMinor

次网格线颜色，比主网格线更浅。

```cangjie
public var gridMinor: Color = Colors.hex("#F3F4F6")
```

### axis

轴线与刻度短线的颜色。

```cangjie
public var axis: Color = Colors.hex("#D1D5DB")
```

### border

面板边框与分隔线的颜色。

```cangjie
public var border: Color = Colors.hex("#E5E7EB")
```

### accent

交互强调色：焦点环、选区与十字光标。

```cangjie
public var accent: Color = Colors.hex("#3B82F6")
```

### surface

悬浮界面——工具栏、提示框、图例底板——的表面色。

```cangjie
public var surface: Color = Colors.hex("#FFFFFF")
```

### surfaceHover

交互悬浮界面的悬停态颜色。

```cangjie
public var surfaceHover: Color = Colors.hex("#F3F4F6")
```

### surfaceActive

交互悬浮界面的按下／激活态颜色。

```cangjie
public var surfaceActive: Color = Colors.hex("#E5E7EB")
```

### palette

分类系列用色的调色板。默认 [`Palette.modern()`](Palette.md#modern)。

```cangjie
public var palette: Palette = Palette.modern()
```

### colormap

热力图等按值取色时默认使用的连续色标。默认 [`Colormap.viridis()`](Colormap.md#viridis)。

```cangjie
public var colormap: Colormap = Colormap.viridis()
```

### titleSize

图形标题字号。

```cangjie
public var titleSize: Float32 = 21.0
```

### subtitleSize

图形副标题字号。

```cangjie
public var subtitleSize: Float32 = 14.5
```

### labelSize

轴标题字号。

```cangjie
public var labelSize: Float32 = 14.5
```

### tickSize

刻度标签字号。

```cangjie
public var tickSize: Float32 = 13.5
```

### legendSize

图例条目字号。

```cangjie
public var legendSize: Float32 = 13.5
```

### annotationSize

标注与读数字号。

```cangjie
public var annotationSize: Float32 = 13.0
```

### lineWidth

数据线的默认宽度，单位为逻辑像素。

```cangjie
public var lineWidth: Float32 = 2.0
```

### markerSize

数据点标记的默认半径，单位为逻辑像素。

```cangjie
public var markerSize: Float32 = 3.5
```

### cornerRadius

面板、提示框与工具栏按钮的圆角半径。

```cangjie
public var cornerRadius: Float32 = 8.0
```

### isDark

主题是否为暗色；组件据此合理选择阴影与遮罩强度。

```cangjie
public var isDark: Bool = false
```

### panelFilled

绘图面板是否填充与图形底色不同的背景。

```cangjie
public var panelFilled: Bool = false
```

### panelBordered

绘图面板是否绘制边框。

```cangjie
public var panelBordered: Bool = true
```

## 另请参阅

- [`Palette`](Palette.md)、[`Colormap`](Colormap.md) — 主题携带的两类颜色来源。
- [`Colors`](Colors.md) — 构造自定义颜色值。
- [`Figure`](../Figure.md) — 持有主题并把它应用到整幅图形。
