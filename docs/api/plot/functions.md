[plot](../index.md) › [plot](index.md) › 函数

# 函数 — plot

导出路径处理的三个工具函数。[PlotWindow](PlotWindow.md) 的保存流程使用它们，也可单独调用。

### withPngExtension

当 `path` 未带 `.png` 或 `.bmp` 扩展名时为其追加 `.png`。这样在保存对话框中只输入 "figure" 的用户也能得到系统认得的文件；显式的 `.bmp` 是格式选择，保持不变。扩展名比较不区分 ASCII 大小写。

```cangjie
public func withPngExtension(path: String): String
```

**参数**

- `path`: `String` — 文件路径或裸文件名。

**返回值** `String` — 带扩展名的路径；已以 `.png` 或 `.bmp` 结尾（不区分大小写）时原样返回。

```cangjie
withPngExtension("figure")     // "figure.png"
withPngExtension("figure.png") // 原样返回 "figure.png"
withPngExtension("figure.bmp") // 原样返回 "figure.bmp" —— 显式 .bmp 是格式选择
```

### isBmpPath

报告 `path` 是否指向 BMP 文件，为真时导出应跳过 PNG 编码器。判定条件是路径以 `.bmp` 结尾，不区分 ASCII 大小写；[PlotWindow.saveImage](PlotWindow.md#saveimage) 据此选择输出格式。

```cangjie
public func isBmpPath(path: String): Bool
```

**参数**

- `path`: `String` — 待判定的文件路径。

**返回值** `Bool` — 以 `.bmp`（任意大小写）结尾时为 `true`。

### fileNameOf

返回 `path` 的文件名部分，供状态消息显示。路径解析失败时原样返回 `path`，因此总有可显示的内容。

```cangjie
public func fileNameOf(path: String): String
```

**参数**

- `path`: `String` — 文件路径。

**返回值** `String` — 路径最后一级的文件名；解析失败时为原始 `path`。
