[plot](../../index.md) › [plot.canvas](index.md) › LineStyle

# LineStyle

`plot.canvas` 中的 public enum

数据线的线型：虚线花纹以线宽的倍数表示，线加粗后节奏不变。[Canvas.styledPolyline](Canvas.md#styledpolyline) 按线型选择实线或虚线描边；`NoLine` 让线完全不绘制、由标记单独呈现。

## 声明

```cangjie
public enum LineStyle <: Equatable<LineStyle>
```

## 继承

实现标准库接口 `Equatable<LineStyle>`。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.canvas.LineStyle
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "虚线趋势")
    let series = LineSeries([0.0, 1.0, 2.0], [0.2, 0.9, 0.5], label: "预测")
    series.style = LineStyle.Dashed
    axes.add(series)
    FigureExport.renderToPng(figure, "line-style.png", width: 640, height: 480)
    // 虚线花纹按线宽换算：Dashed 在线宽 2.0 下为 (7.0, 5.0)
    match (LineStyle.Dashed.dashPattern(2.0)) {
        case Some((dash, gap)) => println("划长=${Int64(dash)} 间隔=${Int64(gap)}") // 输出: 划长=7 间隔=5
        case None => println("连续实线")
    }
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`dashPattern(...)`](#dashpattern) | 返回该线型在线宽 `width` 下的开/关段长；连续绘制的线型返回 `None`。 |
| [`isHidden()`](#ishidden) | 线型是否完全不绘制，让标记单独呈现。 |

**运算符**

| 成员 | 说明 |
|---|---|
| [`operator ==`](#operator) | 两个线型是否为同一枚举值。 |
| [`operator !=`](#operator-1) | `==` 的取反。 |

**枚举值**

| 成员 | 说明 |
|---|---|
| `Solid` | 连续实线；`dashPattern` 返回 `None`。 |
| `Dashed` | 长划虚线：划长 3.5 倍线宽、间隔 2.5 倍线宽。 |
| `Dotted` | 点线：划长 0.6 倍线宽、间隔 2.0 倍线宽。 |
| `DashDot` | 划长与 `Dashed` 相同（3.5 倍线宽）、间隔更紧（2.0 倍线宽）。 |
| `NoLine` | 不绘制任何线；`isHidden()` 为 `true`。 |

## 方法

### dashPattern

返回该线型在线宽 `width` 下的开/关段长；连续绘制的线型返回 `None`。`Solid` 与 `NoLine` 返回 `None`；`Dashed` 返回 `Some((width × 3.5, width × 2.5))`，`Dotted` 返回 `Some((width × 0.6, width × 2.0))`，`DashDot` 返回 `Some((width × 3.5, width × 2.0))`。

```cangjie
public func dashPattern(width: Float32): ?(Float32, Float32)
```

**参数**

- `width`: `Float32` — 线宽（像素）；花纹按其倍数换算，虚线因此在线加粗后保持节奏。

**返回值** `?(Float32, Float32)` — `(划长, 间隔)`，单位像素；连续描边为 `None`。

### isHidden

线型是否完全不绘制，让标记单独呈现。仅 `NoLine` 返回 `true`。

```cangjie
public func isHidden(): Bool
```

**返回值** `Bool` — `NoLine` 为 `true`，其余为 `false`。

## 运算符

### operator==

两个线型是否为同一枚举值。

```cangjie
public operator func ==(other: LineStyle): Bool
```

**参数**

- `other`: `LineStyle` — 参与比较的另一线型。

**返回值** `Bool` — 同为同一枚举值时为 `true`。

### operator!=

`==` 的取反。

```cangjie
public operator func !=(other: LineStyle): Bool
```

**参数**

- `other`: `LineStyle` — 参与比较的另一线型。

**返回值** `Bool` — 枚举值不同时为 `true`。

## 另请参阅

- [`Canvas.styledPolyline`](Canvas.md#styledpolyline) — 按线型描边折线
- [`MarkerStyle`](MarkerStyle.md) — 数据点的标记字形
