[plot](../../index.md) › [plot.core](index.md) › Colors

# Colors

`plot.core` 中的 public class

基于 `Color` 的颜色构造与混合静态工具集：十六进制解析、HSL 生成、混色、明暗调整与对比度计算。

## 声明

```cangjie
public class Colors
```

## 说明

`Color` 定义在外部包中，仓颉的孤儿规则不允许本包直接为它扩展方法，因此这些能力以 `Colors` 上的静态函数提供，而非 `Color` 的方法。

## 示例

```cangjie verify
package demo

import plot.core.Colors

main(): Unit {
    // 解析十六进制字面量（前导 # 可省略，大小写不敏感）
    let brand = Colors.hex("#3B82F6")
    println("${brand.r} ${brand.g} ${brand.b}")     // 输出: 59 130 246

    // 由 HSL 生成：色相按度数回绕，饱和度与亮度夹取到 0..1
    let red = Colors.hsl(0.0, 1.0, 0.5)
    println("${red.r} ${red.g} ${red.b}")           // 输出: 255 0 0

    // 不透明度取 0..1 而非字节值
    println(Colors.fade(brand, 0.5).a)              // 输出: 128

    // 深色背景上自动选出白色文字
    println(Colors.contrastText(Colors.hex("#111827")).r)   // 输出: 255
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建无状态的工具对象；通常直接调用静态成员，无需构造实例。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static hex(code: String)`](#hex) | 解析 `#rgb`、`#rrggbb` 或 `#rrggbbaa` 形式的颜色字面量（前导 `#` 可省略，大小写不敏感）。 |
| [`static hsl(hue: Float64, saturation: Float64, lightness: Float64)`](#hsl) | 由色相（度数，自动回绕）、饱和度与亮度（均为 `0..1`）构造颜色。 |
| [`static mix(from: Color, to: Color, t: Float64)`](#mix) | 把 `from` 向 `to` 混合；`t` 夹取到 `0..1`。 |
| [`static fade(color: Color, opacity: Float64)`](#fade) | 返回换用新不透明度的同一颜色，不透明度取 `0..1` 而非字节值。 |
| [`static lighten(color: Color, amount: Float64)`](#lighten) | 把 `color` 向白色混合 `amount`（`0..1`）。 |
| [`static darken(color: Color, amount: Float64)`](#darken) | 把 `color` 向黑色混合 `amount`（`0..1`）。 |
| [`static luminance(color: Color)`](#luminance) | 按 WCAG 2.1 计算相对亮度，范围 `0..1`。 |
| [`static contrastText(background: Color)`](#contrasttext) | 返回深色或白色中在 `background` 上更易读的一个文字色。 |

## 构造函数

### init

**由编译器生成：** 该类未声明构造函数且没有未初始化的实例字段，仓颉因此合成此公有无参构造函数。

创建无状态的工具对象；通常直接调用静态成员，无需构造实例。

```cangjie
public init()
```

## 方法

### hex

解析 `#rgb`、`#rrggbb` 或 `#rrggbbaa` 形式的颜色字面量（前导 `#` 可省略，大小写不敏感）。主题里的畸形字面量属于编程错误而非预期状况，因此解析失败直接抛出异常。

```cangjie
public static func hex(code: String): Color
```

**参数**

- `code`: `String` — 颜色字面量，去掉可选的 `#` 后长度须为 3、6 或 8 个十六进制字符。

**返回值** `Color` — 解析出的颜色；`#rgb` 形式按每位重复展开（`#f80` 等价于 `#ff8800`），无 alpha 位时不透明。

**异常**

- [`PlotException`](PlotException.md) — 字符串不是三种形状之一，或含有非十六进制字符。

### hsl

由色相（度数，自动回绕）、饱和度与亮度（均为 `0..1`）构造颜色。适合在固定调色板之外按等距色相生成系列色。

```cangjie
public static func hsl(hue: Float64, saturation: Float64, lightness: Float64): Color
```

**参数**

- `hue`: `Float64` — 色相，单位为度；经 [`floorMod`](functions.md#floormod) 回绕到 `[0, 360)`，负值向前回绕（`-120` 等价于 `240`）。
- `saturation`: `Float64` — 饱和度，夹取到 `0..1`。
- `lightness`: `Float64` — 亮度，夹取到 `0..1`。

**返回值** `Color` — 转换得到的 RGB 颜色，不透明。

### mix

把 `from` 向 `to` 混合；`t` 夹取到 `0..1`。`t` 为 0 得到 `from`，为 1 得到 `to`。

```cangjie
public static func mix(from: Color, to: Color, t: Float64): Color
```

**参数**

- `from`: `Color` — 起始颜色。
- `to`: `Color` — 目标颜色。
- `t`: `Float64` — 混合比例，夹取到 `0..1`；NaN 按 0 处理。

**返回值** `Color` — 两色的线性插值结果。

### fade

返回换用新不透明度的同一颜色，不透明度取 `0..1` 而非字节值。

```cangjie
public static func fade(color: Color, opacity: Float64): Color
```

**参数**

- `color`: `Color` — 原始颜色，RGB 分量原样保留。
- `opacity`: `Float64` — 目标不透明度，夹取到 `0..1`（`0.5` 对应字节值 128）；NaN 按 0 处理，得到全透明。

**返回值** `Color` — 仅 alpha 改变的颜色。

### lighten

把 `color` 向白色混合 `amount`（`0..1`）。

```cangjie
public static func lighten(color: Color, amount: Float64): Color
```

**参数**

- `color`: `Color` — 原始颜色。
- `amount`: `Float64` — 混合比例，夹取到 `0..1`；`1.0` 得到纯白。

**返回值** `Color` — 变亮后的颜色。

### darken

把 `color` 向黑色混合 `amount`（`0..1`）。

```cangjie
public static func darken(color: Color, amount: Float64): Color
```

**参数**

- `color`: `Color` — 原始颜色。
- `amount`: `Float64` — 混合比例，夹取到 `0..1`；`1.0` 得到纯黑。

**返回值** `Color` — 变暗后的颜色。

### luminance

按 WCAG 2.1 计算相对亮度，范围 `0..1`。它驱动 [`contrastText`](#contrasttext)，让落在数据着色表面上的标签无论调色板怎么变都保持可读。

```cangjie
public static func luminance(color: Color): Float64
```

**参数**

- `color`: `Color` — 待测颜色；alpha 不参与计算。

**返回值** `Float64` — 相对亮度，黑为 0 附近、白为 1 附近。

### contrastText

返回深色或白色中在 `background` 上更易读的一个文字色。亮度高于 0.45 时返回近黑的 `rgb(16, 20, 28)`，否则返回白色。

```cangjie
public static func contrastText(background: Color): Color
```

**参数**

- `background`: `Color` — 文字将要落在的背景色。

**返回值** `Color` — 近黑或纯白。

## 另请参阅

- [`Palette`](Palette.md) — 预设的分类调色板。
- [`Colormap`](Colormap.md) — 连续色标。
- [`Theme`](Theme.md) — 图形层面的颜色配置。
