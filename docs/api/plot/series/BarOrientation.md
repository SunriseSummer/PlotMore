[plot](../../index.md) › [plot.series](index.md) › BarOrientation

# BarOrientation

`plot.series` 中的 public enum

条形系列的生长方向：垂直（类别沿 x 轴）或水平（类别沿 y 轴）。设置在 [BarSeries.orientation](BarSeries.md#orientation) 上，须与所属坐标区安排标度的方式一致——水平条形图要把类别标度放到 y 轴上。

## 声明

```cangjie
public enum BarOrientation
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.core.CategoryScale
import plot.series.{BarOrientation, BarSeries}

main(): Unit {
    // 水平条形图：数值沿 x 轴，类别标度放在 y 轴
    let bars = BarSeries([36.0, 52.0, 18.0], label: "库存")
    bars.orientation = BarOrientation.Horizontal

    let (figure, axes) = Figure.single(title: "仓库库存")
    axes.setYScale(CategoryScale(["仓库甲", "仓库乙", "仓库丙"]))
    axes.add(bars)

    FigureExport.renderToPng(figure, "horizontal-bars.png", width: 800, height: 600)
    println(bars.count()) // 输出: 3
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Vertical` | 条形从 x 轴向上生长；类别沿 x 轴排布。 |
| `Horizontal` | 条形从 y 轴向外延伸；类别沿 y 轴排布。 |

## 另请参阅

- [BarSeries](BarSeries.md)
- [BarGroup](BarGroup.md)
