[plot](../../index.md) › [plot.axes](index.md) › PieSlice

# PieSlice

`plot.axes` 中的 public struct

饼图的一个切片：数值、名称与可选样式。切片本身只是数据，角度、颜色回退与标签绘制都由 [PieAxes](PieAxes.md) 完成。

## 声明

```cangjie
public struct PieSlice
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.{PieAxes, PieSlice}
import plot.core.Colors

main(): Unit {
    let slice = PieSlice(27.0, label: "Firefox", color: Colors.hex("#FF7139"), explode: 0.08)
    let pie = PieAxes([slice, PieSlice(73.0, label: "其他")])
    let figure = Figure("浏览器份额")
    figure.addPanel(pie)
    FigureExport.renderToPng(figure, "exploded-slice.png", width: 640, height: 480)
    println("${slice.label}: ${slice.value}") // 输出: Firefox: 27.000000
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 按数值创建切片，名称、颜色与拉出量可选。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`value`](#value) | 切片的数值大小，决定它占据的扇形角度份额。 |
| [`label`](#label) | 切片名称；名称为空的切片不产生图例条目。 |
| [`color`](#color) | 显式颜色；`None` 取主题调色板中与切片位置对应的槽位。 |
| [`explode`](#explode) | 沿切片中角方向向外拉出的距离，为半径的分数；可突出某一个切片。 |

## 构造函数

### init

按数值创建切片，名称、颜色与拉出量可选。

```cangjie
public init(value: Float64, label!: String = "", color!: ?Color = None, explode!: Float64 = 0.0)
```

**参数**

- `value`: `Float64` — 切片的大小；必须有限且非负，由 [PieAxes 构造函数](PieAxes.md#init)统一校验。
- `label`: `String` — 切片名称；空字符串的切片不进图例。默认 `""`。
- `color`: `?Color` — 显式颜色；`None` 时按切片在数组中的位置取调色板槽位。默认 `None`。
- `explode`: `Float64` — 把切片沿其中角方向拉出的距离，为半径的分数，用于突出某一片；`0.0` 及以下不拉出。默认 `0.0`。

## 字段

### value

切片的数值大小，决定它占据的扇形角度份额。

```cangjie
public let value: Float64
```

### label

切片名称；名称为空的切片不产生图例条目。

```cangjie
public let label: String
```

### color

显式颜色；`None` 取主题调色板中与切片位置对应的槽位。调色板来自 [Theme](../core/Theme.md) 的 `palette` 字段。

```cangjie
public let color: ?Color
```

### explode

沿切片中角方向向外拉出的距离，为半径的分数；可突出某一个切片。

```cangjie
public let explode: Float64
```

## 另请参阅

- [PieAxes](PieAxes.md)
- [PieLabelMode](PieLabelMode.md)
