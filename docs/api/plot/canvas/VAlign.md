[plot](../../index.md) › [plot.canvas](index.md) › VAlign

# VAlign

`plot.canvas` 中的 public enum

文本的垂直锚定方式：锚点落在文本的顶缘、垂直中心或底缘。供 [Canvas.textAnchored](Canvas.md#textanchored) 的 `vAlign` 参数使用。

## 声明

```cangjie
public enum VAlign
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.TextNote
import plot.canvas.VAlign
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "月度营收")
    axes.add(LineSeries([1.0, 2.0, 3.0], [80.0, 120.0, 95.0]))
    let note = TextNote(2.0, 120.0, "峰值")
    let alignment: VAlign = VAlign.Bottom
    note.vAlign = alignment
    axes.annotate(note)
    FigureExport.renderToPng(figure, "valign.png", width: 640, height: 480)
    println(note.boxed) // 输出: true
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Top` | 锚点为文本顶缘，文本自锚点向下延伸。 |
| `Middle` | 锚点为文本的垂直中心。 |
| `Bottom` | 锚点为文本底缘，文本自锚点向上延伸。 |

## 另请参阅

- [`Canvas.textAnchored`](Canvas.md#textanchored) — 按对齐方式锚定绘制文本
- [`HAlign`](HAlign.md) — 水平锚定方式
