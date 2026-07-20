[plot](../../index.md) › [plot.axes](index.md) › LegendPosition

# LegendPosition

`plot.axes` 中的 public enum

图例相对绘图区的摆放位置。四个角落值让图例悬浮在绘图区内部、衬以半透明底板；两个 `Outside` 值在绘图区之外预留独立条带；`Hidden` 跳过绘制。

## 声明

```cangjie
public enum LegendPosition
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.LegendPosition
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "外置图例")
    axes.add(LineSeries([0.0, 1.0], [0.0, 1.0], label: "基准"))
    axes.legend.position = LegendPosition.OutsideBottom
    FigureExport.renderToPng(figure, "legend-bottom.png", width: 800, height: 600)
    println(axes.legend.isOutside()) // 输出: true
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `TopLeft` | 悬浮在绘图区内部的左上角。 |
| `TopRight` | 悬浮在绘图区内部的右上角。 |
| `BottomLeft` | 悬浮在绘图区内部的左下角。 |
| `BottomRight` | 悬浮在绘图区内部的右下角。 |
| `OutsideRight` | 占据绘图区右侧的独立一列，绘图区相应变窄让位。 |
| `OutsideBottom` | 占据绘图区下方的独立一行，图例条目强制横向排列。 |
| `Hidden` | 不绘制图例。 |

## 另请参阅

- [Legend](Legend.md)
