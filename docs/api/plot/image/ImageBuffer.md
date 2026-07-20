[plot](../../index.md) › [plot.image](index.md) › ImageBuffer

# ImageBuffer

`plot.image` 中的 public class

行主序的 8 位 RGBA 图像，每像素 4 字节。像素数组按引用保留而非复制：一幅完整图形有数兆字节，本包内的每个生产者交出的都是刚构建、不再持有的数组。

## 声明

```cangjie
public class ImageBuffer
```

## 说明

引用语义贯穿始终：[pixels](#pixels) 返回的就是背后的数组本身，调用方应把它当作只读。每像素 4 字节依次为红、绿、蓝、alpha。边长上限为 16777216（2^24）像素：本包各解码器都会算出 `width * height * 4`，仓颉对 `Int64` 溢出会直接 trap，先行拒绝越界尺寸才能让损坏的文件头表现为可捕获的 [PlotException](../core/PlotException.md) 而非算术 trap。

## 示例

```cangjie verify
package demo

import plot.image.ImageBuffer

main(): Unit {
    // 2x2 纯白图像：RGBA 每像素 4 字节，共 16 字节
    let pixels = Array<UInt8>(16, repeat: 255)
    let image = ImageBuffer(2, 2, pixels)
    println("${image.width()}x${image.height()} 共 ${image.pixels().size} 字节")
    // 输出: 2x2 共 16 字节
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建图像并校验尺寸与字节数。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`width()`](#width) | 宽度（像素），始终为正。 |
| [`height()`](#height) | 高度（像素），始终为正。 |
| [`pixels()`](#pixels) | 背后的 RGBA 字节数组——不是副本，调用方应视为只读。 |

## 构造函数

### init

创建图像并校验尺寸与字节数。`pixels` 的长度必须恰为 `width * height * 4`：哪怕只差一个字节，下游所有行索引都会整体错位、错误远离成因，因此在此处立即失败。数组按引用保留，不做复制。

```cangjie
public init(width: Int64, height: Int64, pixels: Array<UInt8>)
```

**参数**

- `width`: `Int64` — 宽度（像素）；须为正且不超过 16777216（2^24）。
- `height`: `Int64` — 高度（像素）；约束同 `width`。
- `pixels`: `Array<UInt8>` — 行主序 RGBA 字节，每像素 4 字节（依次为红、绿、蓝、alpha）；长度必须恰为 `width * height * 4`。

**异常**

- `PlotException` — 尺寸不为正、任一边长超过 16777216 像素、或 `pixels` 长度与尺寸不符。

## 方法

### width

宽度（像素），始终为正。

```cangjie
public func width(): Int64
```

**返回值** `Int64` — 宽度（像素）。

### height

高度（像素），始终为正。

```cangjie
public func height(): Int64
```

**返回值** `Int64` — 高度（像素）。

### pixels

背后的 RGBA 字节数组——不是副本，调用方应视为只读。

```cangjie
public func pixels(): Array<UInt8>
```

**返回值** `Array<UInt8>` — 行主序 RGBA 字节；所有权仍属图像，就地修改会直接改变图像内容。

## 另请参阅

- [`Bmp`](Bmp.md) — 解码 BMP 为 ImageBuffer
- [`Png`](Png.md) — 把 ImageBuffer 编码为 PNG
