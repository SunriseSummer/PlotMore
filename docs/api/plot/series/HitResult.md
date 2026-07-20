[plot](../../index.md) › [plot.series](index.md) › HitResult

# HitResult

`plot.series` 中的 public struct

命中测试识别出的光标下数据点，用于构建工具提示与悬停读数。由 [Series.hitTest](Series.md#hittest) 产生；调用方在多条系列之间保留 `distance` 最小的那个结果。

## 声明

```cangjie
public struct HitResult
```

## 示例

```cangjie verify
package demo

import plot.core.{Bounds, LinearScale, Projection, Rect, Theme}
import plot.series.{HitResult, LineSeries}

main(): Unit {
    let series = LineSeries([0.0, 1.0, 2.0], [12.0, 18.0, 15.0], label: "温度")
    let projection = Projection(Rect(0.0, 0.0, 200.0, 100.0),
        LinearScale(Bounds(0.0, 2.0)), LinearScale(Bounds(10.0, 20.0)))

    // 悬停层把光标像素交给系列，并消费它返回的最近数据点。
    let pointer = projection.pixel(1.0, 18.0)
    let result: ?HitResult = series.hitTest(pointer.x, pointer.y, projection, Theme.light())
    match (result) {
        case Some(hit) => println("${hit.label}: ${hit.text}") // 输出: 温度: 1, 18
        case None => println("光标附近没有数据")
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建一个命中结果。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`label`](#label) | 拥有该点的系列的标签。 |
| [`dataX`](#datax) | 该点的 x 值，数据坐标。 |
| [`dataY`](#datay) | 该点的 y 值，数据坐标。 |
| [`pixelX`](#pixelx) | 该点落在屏幕上的像素横坐标。 |
| [`pixelY`](#pixely) | 该点落在屏幕上的像素纵坐标。 |
| [`distance`](#distance) | 与光标的像素距离——调用方跨系列保留最近者。 |
| [`color`](#color) | 系列颜色，让工具提示与数据同色呼应。 |
| [`text`](#text) | 现成的描述文本，如 `sin(x): (1.20, 0.93)`。 |

## 构造函数

### init

创建一个命中结果。

```cangjie
public init(
    label: String,
    dataX: Float64,
    dataY: Float64,
    pixelX: Float32,
    pixelY: Float32,
    distance: Float32,
    color: Color,
    text: String
)
```

**参数**

- `label`: `String` — 拥有该点的系列的标签。
- `dataX`: `Float64` — 该点的 x 值，数据坐标。
- `dataY`: `Float64` — 该点的 y 值，数据坐标。
- `pixelX`: `Float32` — 该点的像素横坐标。
- `pixelY`: `Float32` — 该点的像素纵坐标。
- `distance`: `Float32` — 与光标的像素距离。
- `color`: `Color` — 系列颜色。
- `text`: `String` — 供读数直接显示的描述文本。

## 字段

### label

拥有该点的系列的标签。

```cangjie
public let label: String
```

### dataX

该点的 x 值，数据坐标。

```cangjie
public let dataX: Float64
```

### dataY

该点的 y 值，数据坐标。

```cangjie
public let dataY: Float64
```

### pixelX

该点落在屏幕上的像素横坐标。

```cangjie
public let pixelX: Float32
```

### pixelY

该点落在屏幕上的像素纵坐标。

```cangjie
public let pixelY: Float32
```

### distance

与光标的像素距离——调用方跨系列保留最近者。距离在像素空间度量而非数据空间：两条轴单位无关、量级常常悬殊，用数据距离会让读数偏向数值恰好较小的那条轴。

```cangjie
public let distance: Float32
```

### color

系列颜色，让工具提示与数据同色呼应。

```cangjie
public let color: Color
```

### text

现成的描述文本，如 `sin(x): (1.20, 0.93)`。

```cangjie
public let text: String
```

## 另请参阅

- [Series.hitTest](Series.md#hittest) — 产生命中结果的入口
