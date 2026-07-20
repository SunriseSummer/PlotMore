[plot](../../index.md) › [plot.image](index.md) › Png

# Png

`plot.image` 中的 public class

最小化的 PNG 编码器：8 位 RGBA、无隔行扫描、单个 IDAT 块。`sdl` 渲染器只能截取 BMP 且没有可用的 zlib 绑定，从过滤扫描线到 DEFLATE 的完整链路因此都在本包内实现；[FigureExport](../FigureExport.md) 的 PNG 导出即经由此处。

## 声明

```cangjie
public class Png
```

## 示例

```cangjie verify
package demo

import plot.image.{ImageBuffer, Png}

main(): Unit {
    // 2x2 纯白图像编码为 PNG
    let image = ImageBuffer(2, 2, Array<UInt8>(16, repeat: 255))
    let bytes = Png.encode(image)
    println("签名首字节=${bytes[0]}") // 输出: 签名首字节=137

    // 写出文件（示例在临时目录运行）；已存在的同名文件会被截断
    Png.write(image, "white_2x2.png")
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
| [`static encode(...)`](#encode) | 把图像编码为 PNG 字节。 |
| [`static write(...)`](#write) | 编码并写入 `path`，已存在的文件会被截断。 |

## 构造函数

### init

**由编译器生成：** 该类未声明构造函数且没有未初始化的实例字段，仓颉因此合成此公有无参构造函数。

创建无状态的工具对象；通常直接调用静态成员，无需构造实例。

```cangjie
public init()
```

## 方法

### encode

把图像编码为 PNG 字节。输出为颜色类型 6（真彩加 alpha）、8 位深、单个 IDAT 块，内含自适应过滤后扫描线的 zlib 流；每行按 PNG 规范推荐的"有符号滤后字节绝对值之和最小"启发式在 5 种过滤器中择优——平坦背景的行滤成全零，渐变经左/上预测器化为常量，DEFLATE 因此压得动。

```cangjie
public static func encode(image: ImageBuffer): Array<UInt8>
```

**参数**

- `image`: [`ImageBuffer`](ImageBuffer.md) — 待编码的 RGBA 图像。

**返回值** `Array<UInt8>` — 完整的 PNG 文件字节（8 字节签名与 IHDR、IDAT、IEND 三个块）。

### write

编码并写入 `path`，已存在的文件会被截断。

```cangjie
public static func write(image: ImageBuffer, path: String): Unit
```

**参数**

- `image`: `ImageBuffer` — 待编码的 RGBA 图像。
- `path`: `String` — 输出文件路径。

**异常**

- `FSException`（`std.fs`）— 若 `std.fs` 无法创建、打开、截断或写入目标文件，`Png.write` 向调用方传播 `FSException`。

## 另请参阅

- [`ImageBuffer`](ImageBuffer.md) — 编码输入的载体
- [`Bmp`](Bmp.md) — 读回截屏 BMP 的解码器
- [`FigureExport`](../FigureExport.md) — 截屏到 PNG 的导出路径
