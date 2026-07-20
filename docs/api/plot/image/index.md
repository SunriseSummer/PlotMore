[plot](../../index.md) › plot.image

# plot.image

```cangjie
import plot.image.{ImageBuffer, Bmp, Png}
```

纯仓颉图像编解码：RGBA 缓冲、BMP 解码器与 PNG 编码器（含 deflate 与校验和实现）。它存在的原因是导出链路：`sdl` 渲染器只能把渲染目标截取为 BMP 文件，而工具链没有 zlib 绑定，于是 [`FigureExport`](../FigureExport.md) 用 [`Bmp`](Bmp.md) 读回截屏、用 [`Png`](Png.md) 重编码写盘。deflate 压缩与 CRC-32/Adler-32 校验和是包内实现细节，不对外公开。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`ImageBuffer`](ImageBuffer.md) | 行主序的 8 位 RGBA 图像，每像素 4 字节。 |
| [`Bmp`](Bmp.md) | 读取 `sdl` 渲染器截屏所用的规范 BGR(A) BMP，并转换为 RGBA 图像。 |
| [`Png`](Png.md) | 最小化的 PNG 编码器：8 位 RGBA、无隔行扫描、单个 IDAT 块。 |
