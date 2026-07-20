[plot](../../index.md) › [plot.axes](index.md) › ColorBarSide

# ColorBarSide

`plot.axes` 中的 public enum

指定颜色条显示在绘图区右侧还是下方。右侧使用竖直条带，下方使用水平条带。

## 声明

```cangjie
public enum ColorBarSide
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.{ColorBar, ColorBarSide}
import plot.core.{Bounds, Colormap}
import plot.series.HeatmapSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "温度场")
    axes.add(HeatmapSeries([12.0, 18.0, 25.0, 40.0], rows: 2, columns: 2))
    let colorBar = ColorBar(Bounds(0.0, 40.0), Colormap.magma())
    colorBar.side = ColorBarSide.Bottom // 水平条带，放到面板下方
    axes.setColorBar(colorBar)
    FigureExport.renderToPng(figure, "colorbar-bottom.png", width: 800, height: 600)
    println(colorBar.valueRange()) // 输出: Bounds(0.000000, 40.000000)
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Right` | 竖直颜色条，位于绘图区右侧。 |
| `Bottom` | 水平颜色条，位于绘图区下方。 |

## 另请参阅

- [ColorBar](ColorBar.md)
