[plot](../../index.md) › [plot.ui](index.md) › 函数

# 函数 — plot.ui

### drawToolIcon

在 `rect` 内居中描边绘制 `icon`。`rect` 是图标的包围盒，每个字形自行内缩，笔画保持在盒内；图标全部由线段、圆等图元描边而成，不依赖图标字体，见 [ToolIcon](ToolIcon.md)。

```cangjie
public func drawToolIcon(canvas: Canvas, icon: ToolIcon, rect: Rect, color: Color, weight!: Float32 = 1.6): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 绘制目标。
- `icon`: `ToolIcon` — 要绘制的字形。
- `rect`: `Rect` — 图标的包围盒，窗口像素。
- `color`: `Color` — 描边颜色。
- `weight!`: `Float32` — 笔画宽度，逻辑像素，默认 `1.6`。

```cangjie
// 无渲染设备（headless）画布上也可直接描边
let canvas = Canvas(Renderer.headless())
drawToolIcon(canvas, ToolIcon.Save, Rect(0.0, 0.0, 16.0, 16.0), Color.rgb(51, 65, 85))
drawToolIcon(canvas, ToolIcon.Grid, Rect(20.0, 0.0, 16.0, 16.0), Color.rgb(51, 65, 85), weight: 1.2)
canvas.close()
```
