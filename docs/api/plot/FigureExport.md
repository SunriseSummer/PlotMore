[plot](../index.md) › [plot](index.md) › FigureExport

# FigureExport

`plot` 中的 public class

把图形渲染并写入 PNG 或 BMP 图像文件的导出入口。三个静态方法覆盖两条路径：[savePng](#savepng)/[saveBmp](#savebmp) 复用已打开窗口的渲染器，[renderToPng](#rendertopng) 不依赖既有窗口、自行打开一个隐藏窗口。全部成员为静态方法，本类不需实例化。

## 声明

```cangjie
public class FigureExport
```

## 说明

sdl 只能以 BMP 回读渲染目标（`Renderer.captureBmp`），且本工具链没有 zlib 可供委托，PNG 由 [Png](image/Png.md) 的纯仓颉编码器完成。`savePng` 因此先把一帧捕获为 BMP 临时文件、经 [Bmp](image/Bmp.md) 解码、再编码为 PNG；临时文件是目标路径的同级文件 `<path>.capture.tmp.bmp`，无论成败都会删除。`saveBmp` 跳过这趟往返。

捕获发生在 `beginScene` 与 `endScene` 之间，读取渲染器当时的当前目标。默认超采样目标可用时每轴为 2×；输出尺寸查询失败、结果无效或目标纹理不可用时，渲染器会回退为直接绘制，最终像素尺寸以生成文件实测为准。超采样生效时，文字也按高分辨率目标光栅化，并非事后放大。该帧从不 `present`，不会在屏幕上闪现。

这些异常按来源原样传播，不统一包装为 `PlotException`：plot 侧的尺寸或绘制校验以及临时 BMP 解码问题抛出 `PlotException`；sdl 的窗口、渲染和 BMP 捕获问题抛出 `CuiException`；PNG 路径读取临时 BMP 或写入最终文件的文件系统问题抛出 `FSException`。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "月度销量")
    axes.add(LineSeries([1.0, 2.0, 3.0, 4.0], [12.0, 18.0, 15.0, 22.0], label: "华东"))

    // 内部打开一个隐藏窗口完成光栅化，返回前关闭。
    // 默认超采样目标可用时通常每轴为 2×；若回退直接绘制，尺寸会不同。
    // 需要依赖物理像素时读取生成文件，以实测宽高为准。
    FigureExport.renderToPng(figure, "figure.png", width: 800, height: 600)
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
| [`static savePng(...)`](#savepng) | 以 `width` x `height` 逻辑像素渲染图形，并把结果编码为 PNG 写入 `path`。 |
| [`static saveBmp(...)`](#savebmp) | 渲染图形并直接写为 BMP 位图——sdl 原生捕获的格式，无需解码与再编码。 |
| [`static renderToPng(...)`](#rendertopng) | 在没有既有窗口的情况下把图形渲染为 PNG：内部打开一个隐藏窗口完成光栅化。 |

## 构造函数

### init

**由编译器生成：** 该类未声明构造函数且没有未初始化的实例字段，仓颉因此合成此公有无参构造函数。

创建无状态的工具对象；通常直接调用静态成员，无需构造实例。

```cangjie
public init()
```

## 方法

### savePng

以 `width` x `height` 逻辑像素渲染图形，并把结果编码为 PNG 写入 `path`。复用调用方的 `renderer`——通常来自已打开的窗口——导出只多渲染一帧、不建新的 GPU 上下文，且该帧不会显示到屏幕。转换经由同级临时文件 `<path>.capture.tmp.bmp` 完成，成败两种情况下临时文件都会删除。

```cangjie
public static func savePng(figure: Figure, renderer: Renderer, canvas: Canvas, path: String, width!: Float32, height!: Float32): Unit
```

**参数**

- `figure`: [`Figure`](Figure.md) — 要渲染的图形。
- `renderer`: `Renderer` — 执行渲染与捕获的渲染器（sdl 类型）。
- `canvas`: [`Canvas`](canvas/Canvas.md) — 建立在同一 `renderer` 上的画布。
- `path`: `String` — 目标 PNG 路径；其同级会短暂出现临时 BMP 文件。
- `width!`: `Float32` — 导出宽度，逻辑像素，须不小于 `1.0`。
- `height!`: `Float32` — 导出高度，逻辑像素，须不小于 `1.0`。

**异常**

- [`PlotException`](core/PlotException.md) — 宽或高小于 `1.0`，临时 BMP 内容无法解码，或绘图期间触发 plot 侧的参数、状态校验。
- `CuiException` — sdl 渲染、回读像素或把临时捕获写成 BMP 失败。
- `FSException`（`std.fs`）— 无法读取临时 BMP，或无法创建、截断、写入目标 PNG。

### saveBmp

渲染图形并直接写为 BMP 位图——sdl 原生捕获的格式，无需解码与再编码。文件更大；适合不想让 PNG 编码器进入路径的场合。

```cangjie
public static func saveBmp(figure: Figure, renderer: Renderer, canvas: Canvas, path: String, width!: Float32, height!: Float32): Unit
```

**参数**

- `figure`: `Figure` — 要渲染的图形。
- `renderer`: `Renderer` — 执行渲染与捕获的渲染器（sdl 类型）。
- `canvas`: `Canvas` — 建立在同一 `renderer` 上的画布。
- `path`: `String` — 目标 BMP 路径，捕获直接写入此处。
- `width!`: `Float32` — 导出宽度，逻辑像素，须不小于 `1.0`。
- `height!`: `Float32` — 导出高度，逻辑像素，须不小于 `1.0`。

**异常**

- [`PlotException`](core/PlotException.md) — 宽或高小于 `1.0`，或绘图期间触发 plot 侧的参数、状态校验。
- `CuiException` — sdl 渲染、回读像素或通过 `SDL_SaveBMP` 写入目标文件失败。此路径不经过 `std.fs`，因此写 BMP 失败不会改为 `FSException`。

### renderToPng

在没有既有窗口的情况下把图形渲染为 PNG：内部打开一个隐藏窗口完成光栅化。用于批量或无界面的图形生成；SDL 仍需要渲染器来光栅化文字与几何，因此窗口必须存在，但它保持隐藏并在返回前关闭。

```cangjie
public static func renderToPng(figure: Figure, path: String, width!: Int64 = 1200, height!: Int64 = 800): Unit
```

**参数**

- `figure`: `Figure` — 要渲染的图形。
- `path`: `String` — 目标 PNG 路径。
- `width!`: `Int64` — 导出宽度，逻辑像素，须为正；默认 `1200`。
- `height!`: `Int64` — 导出高度，逻辑像素，须为正；默认 `800`。

**异常**

- [`PlotException`](core/PlotException.md) — 宽或高非正（在创建窗口之前即抛出），临时 BMP 内容无法解码，或绘图期间触发 plot 侧的参数、状态校验。
- `CuiException` — sdl 初始化窗口、渲染器或文本输入失败，隐藏窗口失败，或后续渲染与 BMP 捕获失败。
- `FSException`（`std.fs`）— 无法读取临时 BMP，或无法创建、截断、写入目标 PNG。

## 另请参阅

- [PlotWindow.saveImage](PlotWindow.md#saveimage) —— 已打开窗口内的脚本化导出
- [Png](image/Png.md)、[Bmp](image/Bmp.md) —— 底层图像编解码
- [函数 — plot](functions.md) —— 导出路径工具函数
