[plot](../../index.md) › [plot.axes](index.md) › LabelOrientation

# LabelOrientation

`plot.axes` 中的 public enum

y 轴标题的排布方向：整体旋转、逐字纵排或水平置顶。由 [Axes](Axes.md) 的 [`yLabelOrientation`](Axes.md#ylabelorientation) 字段使用（默认 `Vertical`）；三种取向在布局时各自预留不同的边距。

## 声明

```cangjie
public enum LabelOrientation
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.LabelOrientation
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "纵排标签")
    axes.yLabel = "幅度"
    // 中日韩标题用纵排：字形直立、自上而下排成一列
    axes.yLabelOrientation = LabelOrientation.Stacked
    axes.add(LineSeries([0.0, 1.0, 2.0], [0.3, 0.9, 0.5], label: "通道 1"))

    FigureExport.renderToPng(figure, "stacked-label.png", width: 800, height: 600)
    println(axes.yLabel) // 输出: 幅度
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Vertical` | 旋转 90°，在轴旁自下而上阅读——科学出版的惯例。 |
| `Stacked` | 字形保持直立、自上而下排成一列——中日韩文字的自然纵排。 |
| `Horizontal` | 水平排在轴的上方，仪表盘风格。 |

## 另请参阅

- [Axes](Axes.md) 的 [`yLabelOrientation`](Axes.md#ylabelorientation) 字段
