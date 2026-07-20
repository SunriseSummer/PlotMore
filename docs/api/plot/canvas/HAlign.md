[plot](../../index.md) › [plot.canvas](index.md) › HAlign

# HAlign

`plot.canvas` 中的 public enum

文本的水平锚定方式：锚点落在文本的左缘、水平中心或右缘。供 [Canvas.textAnchored](Canvas.md#textanchored) 的 `hAlign` 参数使用。

## 声明

```cangjie
public enum HAlign
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.TextNote
import plot.canvas.HAlign
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "季度营收")
    axes.add(LineSeries([1.0, 2.0, 3.0], [80.0, 120.0, 95.0]))
    let note = TextNote(2.0, 120.0, "峰值")
    let alignment: HAlign = HAlign.Center
    note.hAlign = alignment
    axes.annotate(note)
    FigureExport.renderToPng(figure, "halign.png", width: 640, height: 480)
    println(note.boxed) // 输出: true
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Left` | 锚点为文本左缘，文本自锚点向右延伸。 |
| `Center` | 锚点为文本的水平中心。 |
| `Right` | 锚点为文本右缘，文本自锚点向左延伸。 |

## 另请参阅

- [`Canvas.textAnchored`](Canvas.md#textanchored) — 按对齐方式锚定绘制文本
- [`VAlign`](VAlign.md) — 垂直锚定方式
