[plot](../../index.md) › [plot.core](index.md) › Projection

# Projection

`plot.core` 中的 public class

单个面板的数据坐标到像素坐标变换：一个像素矩形，加上填充它的两条标度。

## 声明

```cangjie
public class Projection
```

## 说明

y 轴在此处且仅在此处翻转——数据向上增长，屏幕像素向下增长——因此任何图表类型都不必自己记得取反。每个系列都经由投影绘制，这也是缩放与平移能统一工作的原因：它们只替换[标度](Scale.md)的定义域。

## 示例

```cangjie verify
package demo

import plot.core.{Bounds, LinearScale, Projection, Rect}

main(): Unit {
    // 一个 400×200 像素的面板：x 覆盖 0..10，y 覆盖 0..20
    let area = Rect(100.0, 50.0, 400.0, 200.0)
    let projection = Projection(area, LinearScale(Bounds(0.0, 10.0)), LinearScale(Bounds(0.0, 20.0)))

    // 数据 → 像素；y 轴已翻转：数据越大，屏幕位置越高
    println(Int64(projection.pixelX(5.0)))      // 输出: 300
    println(Int64(projection.pixelY(20.0)))     // 输出: 50

    // 像素 → 数据：命中测试与读数所用的逆变换
    println(projection.dataX(300.0))            // 输出: 5.000000

    // 数据距离 → 像素长度
    println(Int64(projection.pixelWidth(1.0)))  // 输出: 40
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(area: Rect, xScale: Scale, yScale: Scale)`](#init) | 由面板矩形与两条标度构建投影。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`x()`](#x) | 返回水平方向的标度。 |
| [`y()`](#y) | 返回垂直方向的标度。 |
| [`pixelX(value: Float64)`](#pixelx) | 返回数据 x 值对应的像素列。 |
| [`pixelY(value: Float64)`](#pixely) | 返回数据 y 值对应的像素行；数据越大，屏幕位置越高。 |
| [`pixel(dataX: Float64, dataY: Float64)`](#pixel) | 返回数据点对应的像素位置。 |
| [`dataX(px: Float32)`](#datax) | 返回像素列之下的数据 x 值——`pixelX` 的逆变换，供命中测试与读数使用。 |
| [`dataY(py: Float32)`](#datay) | 返回像素行之下的数据 y 值。 |
| [`pixelWidth(dataSpan: Float64)`](#pixelwidth) | 返回数据空间距离沿 x 方向对应的像素长度，例如把柱宽对齐到类别带。 |
| [`pixelHeight(dataSpan: Float64)`](#pixelheight) | 返回数据空间距离沿 y 方向对应的像素长度。 |
| [`accepts(dataX: Float64, dataY: Float64)`](#accepts) | 当两条标度都能表达该点且两个坐标均有限时返回 `true`。 |
| [`containsPixel(px: Float32, py: Float32)`](#containspixel) | 当点落在面板矩形内时返回 `true`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`area`](#area) | 面板占据的像素矩形。 |

## 构造函数

### init

由面板矩形与两条标度构建投影。

```cangjie
public init(area: Rect, xScale: Scale, yScale: Scale)
```

**参数**

- `area`: `Rect` — 面板占据的像素矩形。
- `xScale`: [`Scale`](Scale.md) — 水平方向的标度。
- `yScale`: `Scale` — 垂直方向的标度。

## 方法

### x

返回水平方向的标度。

```cangjie
public func x(): Scale
```

**返回值** `Scale` — 构造时传入的 x 标度。

### y

返回垂直方向的标度。

```cangjie
public func y(): Scale
```

**返回值** `Scale` — 构造时传入的 y 标度。

### pixelX

返回数据 x 值对应的像素列。

```cangjie
public func pixelX(value: Float64): Float32
```

**参数**

- `value`: `Float64` — 数据坐标下的 x 值。

**返回值** `Float32` — 像素列：`area.x + normalize(value) × area.w`。

### pixelY

返回数据 y 值对应的像素行；数据越大，屏幕位置越高。

```cangjie
public func pixelY(value: Float64): Float32
```

**参数**

- `value`: `Float64` — 数据坐标下的 y 值。

**返回值** `Float32` — 像素行，从面板底边向上量起。

### pixel

返回数据点对应的像素位置。

```cangjie
public func pixel(dataX: Float64, dataY: Float64): Point
```

**参数**

- `dataX`: `Float64` — 数据 x 值。
- `dataY`: `Float64` — 数据 y 值。

**返回值** `Point` — `(pixelX(dataX), pixelY(dataY))` 组成的像素点。

### dataX

返回像素列之下的数据 x 值——`pixelX` 的逆变换，供命中测试与读数使用。

```cangjie
public func dataX(px: Float32): Float64
```

**参数**

- `px`: `Float32` — 像素列。

**返回值** `Float64` — 对应的数据 x 值；面板宽度为零或负时返回 x 定义域的中点，不做除法。

### dataY

返回像素行之下的数据 y 值。

```cangjie
public func dataY(py: Float32): Float64
```

**参数**

- `py`: `Float32` — 像素行。

**返回值** `Float64` — 对应的数据 y 值；面板高度为零或负时返回 y 定义域的中点，不做除法。

### pixelWidth

返回数据空间距离沿 x 方向对应的像素长度，例如把柱宽对齐到类别带。

```cangjie
public func pixelWidth(dataSpan: Float64): Float32
```

**参数**

- `dataSpan`: `Float64` — 数据空间中的距离。

**返回值** `Float32` — 像素长度；x 定义域宽度为零或负时返回 `0.0`。

### pixelHeight

返回数据空间距离沿 y 方向对应的像素长度。

```cangjie
public func pixelHeight(dataSpan: Float64): Float32
```

**参数**

- `dataSpan`: `Float64` — 数据空间中的距离。

**返回值** `Float32` — 像素长度；y 定义域宽度为零或负时返回 `0.0`。

### accepts

当两条标度都能表达该点且两个坐标均有限时返回 `true`。对数轴上的零就是被它判为不可绘制的典型例子——点被跳过而不是被夹取。

```cangjie
public func accepts(dataX: Float64, dataY: Float64): Bool
```

**参数**

- `dataX`: `Float64` — 数据 x 值。
- `dataY`: `Float64` — 数据 y 值。

**返回值** `Bool` — 两条标度的 [`Scale.accepts`](Scale.md#accepts) 均通过时为 `true`。

### containsPixel

当点落在面板矩形内时返回 `true`。

```cangjie
public func containsPixel(px: Float32, py: Float32): Bool
```

**参数**

- `px`: `Float32` — 像素列。
- `py`: `Float32` — 像素行。

**返回值** `Bool` — `area` 包含该点时为 `true`。

## 字段

### area

面板占据的像素矩形。声明为 `let`，构造后不可变。

```cangjie
public let area: Rect
```

## 另请参阅

- [`Scale`](Scale.md) — 数据侧的归一化变换。
- [`Axes`](../axes/Axes.md) — 持有投影所服务面板的坐标系。
