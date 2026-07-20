[plot](../../index.md) › [plot.core](index.md) › Palette

# Palette

`plot.core` 中的 public struct

按系列序号索引的有序分类色集合。[`at`](#at) 会回绕，因此调色板永远不会用尽：十色调色板中的第十一条系列重新使用第一色，而不是抛出异常或变得不可见。

## 声明

```cangjie
public struct Palette
```

## 示例

```cangjie verify
package demo

import plot.core.Palette

main(): Unit {
    let palette = Palette.modern()
    println(palette.size())        // 输出: 10

    // 索引回绕：第 10 条系列重新用回第 0 色
    let first = palette.at(0)
    let wrapped = palette.at(10)
    println(first.r == wrapped.r && first.g == wrapped.g)   // 输出: true

    // 负索引向前回绕到末尾
    println(palette.at(-1).b == palette.at(9).b)            // 输出: true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(colors: Array<Color>)`](#init) | 由颜色数组创建调色板。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`at(index: Int64)`](#at) | 返回系列 `index` 的颜色，用尽后回绕。 |
| [`size()`](#size) | 返回调色板在开始重复之前拥有的不同颜色数。 |
| [`static modern()`](#modern) | 沉稳、高对比的十色定性色组，在浅色与深色背景上都保持可分辨——系列着色的默认调色板。 |
| [`static muted()`](#muted) | 柔和、适合印刷的十色色组，用于系列密集的图形。 |
| [`static colorblindSafe()`](#colorblindsafe) | Okabe-Ito 八色组，在常见色觉缺陷下仍保持可区分。 |
| [`static vivid()`](#vivid) | 高饱和的八色色组，在深色背景或投影仪上依然醒目。 |

## 构造函数

### init

由颜色数组创建调色板。

```cangjie
public init(colors: Array<Color>)
```

**参数**

- `colors`: `Array<Color>` — 按系列顺序排列的颜色，至少一个。

**异常**

- [`PlotException`](PlotException.md) — `colors` 为空时抛出，否则 `at` 将无色可返回。

## 方法

### at

返回系列 `index` 的颜色，用尽后回绕。索引对颜色数取模，负索引向前回绕：`at(-1)` 得到最后一色，`at(size())` 又回到第一色。

```cangjie
public func at(index: Int64): Color
```

**参数**

- `index`: `Int64` — 系列序号，可为负或超出颜色数。

**返回值** `Color` — 回绕后对应位置的颜色。

### size

返回调色板在开始重复之前拥有的不同颜色数。

```cangjie
public func size(): Int64
```

**返回值** `Int64` — 颜色数，构造保证至少为 1。

### modern

沉稳、高对比的十色定性色组，在浅色与深色背景上都保持可分辨——系列着色的默认调色板。

```cangjie
public static func modern(): Palette
```

**返回值** `Palette` — 十色调色板，首色为 `#3B82F6`。

### muted

柔和、适合印刷的十色色组，用于系列密集的图形。

```cangjie
public static func muted(): Palette
```

**返回值** `Palette` — 十色调色板。

### colorblindSafe

Okabe-Ito 八色组，在常见色觉缺陷下仍保持可区分。面向出版物的图形应默认选它。

```cangjie
public static func colorblindSafe(): Palette
```

**返回值** `Palette` — 八色调色板。

### vivid

高饱和的八色色组，在深色背景或投影仪上依然醒目。

```cangjie
public static func vivid(): Palette
```

**返回值** `Palette` — 八色调色板。

## 另请参阅

- [`Colormap`](Colormap.md) — 连续取色的色标。
- [`Theme.palette`](Theme.md#palette) — 主题携带的分类调色板（默认 `modern()`，暗色主题用 `vivid()`）。
- [`Colors`](Colors.md) — 逐个构造与调整颜色。
