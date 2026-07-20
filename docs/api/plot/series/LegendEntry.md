[plot](../../index.md) › [plot.series](index.md) › LegendEntry

# LegendEntry

`plot.series` 中的 public struct

图例中的一个条目：由产生它的系列绘制的色块，加上标签与代表色。`draw` 回调让每个系列自行绘制色块——折线系列画一段带线型与标记的线段，柱状系列画一个填充块——因此图例始终与面板上的实际画法一致，而不是近似。

## 声明

```cangjie
public struct LegendEntry
```

## 示例

```cangjie verify
package demo

import plot.core.Theme
import plot.series.{LegendEntry, LineSeries}

main(): Unit {
    // 普通使用中，图例条目由系列按当前主题生成。
    let line = LineSeries([1.0, 2.0], [3.0, 4.0], label: "收入")
    let entry: LegendEntry = line.legend(Theme.light())[0]
    println("条目标签: ${entry.label}")
    // 输出: 条目标签: 收入
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建一个图例条目。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`label`](#label) | 图例中显示的文字。 |
| [`color`](#color) | 该条目代表的系列颜色。 |
| [`draw`](#draw) | 把色块画进给定矩形的回调。 |

## 构造函数

### init

创建一个图例条目。

```cangjie
public init(label: String, color: Color, draw: (Canvas, Rect, Theme) -> Unit)
```

**参数**

- `label`: `String` — 图例中显示的文字。
- `color`: `Color` — 该条目代表的系列颜色。
- `draw`: `(Canvas, Rect, Theme) -> Unit` — 色块绘制回调；注意 lambda 不能捕获可变局部变量，需要捕获的颜色等值应放在 `let` 变量中。

## 字段

### label

图例中显示的文字。

```cangjie
public let label: String
```

### color

该条目代表的系列颜色。

```cangjie
public let color: Color
```

### draw

把色块画进给定矩形的回调。参数依次为绘制目标 [Canvas](../canvas/Canvas.md)、色块矩形与当前 [Theme](../core/Theme.md)。

```cangjie
public let draw: (Canvas, Rect, Theme) -> Unit
```

## 另请参阅

- [Series.legend](Series.md#legend) — 生成图例条目的默认实现
