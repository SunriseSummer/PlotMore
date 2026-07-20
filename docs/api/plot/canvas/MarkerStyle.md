[plot](../../index.md) › [plot.canvas](index.md) › MarkerStyle

# MarkerStyle

`plot.canvas` 中的 public enum

数据点处的标记字形：形状居中于数据点、以外接圆半径定尺寸，同尺寸下视觉分量相近。`Cross`、`Plus`、`Ring` 是描边轮廓而非填充面；`NoMarker` 让线不带标记。由 [Canvas.marker](Canvas.md#marker) 绘制。

## 声明

```cangjie
public enum MarkerStyle <: Equatable<MarkerStyle>
```

## 继承

实现标准库接口 `Equatable<MarkerStyle>`。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.canvas.MarkerStyle
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "采样点")
    let series = LineSeries([0.0, 1.0, 2.0], [0.2, 0.9, 0.5])
    series.marker = MarkerStyle.Ring
    series.markerSize = Some(6.0)
    axes.add(series)
    FigureExport.renderToPng(figure, "marker-style.png", width: 640, height: 480)
    println("Ring 描边=${MarkerStyle.Ring.isStroked()} Circle 描边=${MarkerStyle.Circle.isStroked()}")
    // 输出: Ring 描边=true Circle 描边=false
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`isHidden()`](#ishidden) | 标记是否完全不绘制。 |
| [`isStroked()`](#isstroked) | 形状是否为描边轮廓而非填充面。 |

**运算符**

| 成员 | 说明 |
|---|---|
| [`operator ==`](#operator) | 两个标记形状是否为同一枚举值。 |
| [`operator !=`](#operator-1) | `==` 的取反。 |

**枚举值**

| 成员 | 说明 |
|---|---|
| `Circle` | 实心圆，半径即 `size`。 |
| `Square` | 实心正方形，边长为 1.6 倍 `size`。 |
| `Diamond` | 实心菱形，外接圆半径 1.25 倍 `size`。 |
| `Triangle` | 尖朝上的实心三角形，外接圆半径 1.25 倍 `size`。 |
| `TriangleDown` | 尖朝下的实心三角形，外接圆半径 1.25 倍 `size`。 |
| `Cross` | 斜十字（X 形）描边，臂展 0.75 倍 `size`。 |
| `Plus` | 正十字描边，臂展等于 `size`。 |
| `Star` | 五角星，外半径 1.35 倍、内半径 0.55 倍 `size`。 |
| `Ring` | 圆环描边（不填充），半径即 `size`。 |
| `NoMarker` | 不绘制任何标记；`isHidden()` 为 `true`。 |

## 方法

### isHidden

标记是否完全不绘制。仅 `NoMarker` 返回 `true`。

```cangjie
public func isHidden(): Bool
```

**返回值** `Bool` — `NoMarker` 为 `true`，其余为 `false`。

### isStroked

形状是否为描边轮廓而非填充面。仅 `Cross`、`Plus`、`Ring` 返回 `true`；这些形状没有内部，调用方不应再为它们叠加轮廓。

```cangjie
public func isStroked(): Bool
```

**返回值** `Bool` — `Cross`、`Plus`、`Ring` 为 `true`，其余为 `false`。

## 运算符

### operator==

两个标记形状是否为同一枚举值。

```cangjie
public operator func ==(other: MarkerStyle): Bool
```

**参数**

- `other`: `MarkerStyle` — 参与比较的另一标记形状。

**返回值** `Bool` — 同为同一枚举值时为 `true`。

### operator!=

`==` 的取反。

```cangjie
public operator func !=(other: MarkerStyle): Bool
```

**参数**

- `other`: `MarkerStyle` — 参与比较的另一标记形状。

**返回值** `Bool` — 枚举值不同时为 `true`。

## 另请参阅

- [`Canvas.marker`](Canvas.md#marker) — 绘制标记字形
- [`LineStyle`](LineStyle.md) — 数据线的线型
