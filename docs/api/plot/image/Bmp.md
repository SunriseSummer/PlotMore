[plot](../../index.md) › [plot.image](index.md) › Bmp

# Bmp

`plot.image` 中的 public class

读取 `sdl` 渲染器截屏所用的规范 BGR(A) BMP，并转换为 RGBA 图像。它只处理未压缩的 24 位与 32 位形态；`renderer.captureBmp` 只会产出这些形态，而这正是 PNG 导出路径（[FigureExport](../FigureExport.md)）需要读回的全部。

## 声明

```cangjie
public class Bmp
```

## 示例

```cangjie verify
package demo

import plot.image.Bmp

main(args: Array<String>): Int64 {
    if (args.size != 1) {
        println("用法: bmp-info <capture.bmp>") // 输出: 用法: bmp-info <capture.bmp>
        return 0
    }

    // 普通用法：读取渲染器截屏或其他规范 BGR(A) BMP，并查看解码后的 RGBA 缓冲。
    let image = Bmp.read(args[0])
    println("${args[0]}: ${image.width()}x${image.height()}，${image.pixels().size} 字节 RGBA")
    return 0
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
| [`static decode(...)`](#decode) | 把 BMP 文件的字节解码为 RGBA 图像。 |
| [`static read(...)`](#read) | 读取并解码一个 BMP 文件。 |

## 构造函数

### init

**由编译器生成：** 该类未声明构造函数且没有未初始化的实例字段，仓颉因此合成此公有无参构造函数。

创建无状态的工具对象；通常直接调用静态成员，无需构造实例。

```cangjie
public init()
```

## 方法

### decode

把 BMP 文件的字节解码为 RGBA 图像。接受压缩字段为 BI_RGB 或 BI_BITFIELDS 的 24/32 位文件、自下而上与自上而下两种行序（高度为负即自上而下），以及不小于 BITMAPINFOHEADER（40 字节）的各代 DIB 头。

解码器固定按规范 BGR(A) 字节位置读取通道，不解析 BI_BITFIELDS 位掩码。因此 BI_BITFIELDS 只适用于掩码与规范 BGR(A) 布局一致的文件；其他掩码不会被拒绝，但会得到错误颜色，不属于受支持输入。需要通用 BMP 位域解码时应使用完整的图像格式库。

通道按 BGR(A) 读入、以 RGBA 交回；24 位文件没有 alpha 通道，一律置 255。若整幅图的 alpha 全为零——SDL 写 32 位 BMP 时从不填充 alpha——则视为"文件不含 alpha"而强制不透明：按字面解读那是一张全透明图像，导出的 PNG 将一片空白。

```cangjie
public static func decode(bytes: Array<UInt8>): ImageBuffer
```

**参数**

- `bytes`: `Array<UInt8>` — BMP 文件的完整字节。

**返回值** [`ImageBuffer`](ImageBuffer.md) — 解码出的 RGBA 图像。

**异常**

- `PlotException` — 字节数容不下文件头、缺少 `BM` 签名、DIB 头小于 40 字节、压缩字段不是 BI_RGB/BI_BITFIELDS、色深不是 24/32 位、尺寸非法（不为正或超过 16777216 像素），或声明的像素数据超出文件末尾。BI_BITFIELDS 的非规范掩码不会触发异常，见上文限制。

### read

读取并解码一个 BMP 文件。等价于把 `File.readFrom(path)` 的结果交给 `decode`。

若 `std.fs` 无法打开或读取文件，`Bmp.read` 向调用方传播 `FSException`；文件成功读入但内容无法解码时，`decode` 抛出 `PlotException`。

```cangjie
public static func read(path: String): ImageBuffer
```

**参数**

- `path`: `String` — BMP 文件路径。

**返回值** `ImageBuffer` — 解码出的 RGBA 图像。

**异常**

- `FSException`（`std.fs`）— 无法打开或读取 `path` 指向的文件。
- `PlotException` — 文件内容不是可解码的 BMP 时由 `decode` 抛出。

## 另请参阅

- [`ImageBuffer`](ImageBuffer.md) — 解码结果的载体
- [`Png`](Png.md) — 把读回的图像编码为 PNG
- [`FigureExport`](../FigureExport.md) — 截屏到 PNG 的导出路径
