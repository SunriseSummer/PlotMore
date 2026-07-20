[plot](../../index.md) › [plot.series](index.md) › StepWhere

# StepWhere

`plot.series` 中的 public enum

阶梯系列在相邻两个采样点之间改变水平值的位置。由 [StepSeries](StepSeries.md) 的 `changeAt` 字段选用。

## 声明

```cangjie
public enum StepWhere
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.series.{StepSeries, StepWhere}

main(): Unit {
    // 分时电价：每个时段的价格保持到下一时段开始，改变发生在左侧采样点
    let hourStarts = [0.0, 8.0, 12.0, 18.0, 22.0]
    let price = [0.31, 0.62, 0.86, 0.62, 0.31]
    let tariff = StepSeries(hourStarts, price, label: "电价")
    tariff.changeAt = StepWhere.Post

    let (figure, axes) = Figure.single(title: "分时电价")
    axes.add(tariff)

    FigureExport.renderToPng(figure, "step-where.png", width: 800, height: 600)
    println("采样点数: ${tariff.xValues().size}") // 输出: 采样点数: 5
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Post` | 水平值在左侧采样点处改变：数值保持到下一个 x 为止。 |
| `Pre` | 水平值在右侧采样点处改变：数值在其自身的 x 处到达。 |
| `Mid` | 水平值在两个采样点正中间改变。 |

## 另请参阅

- [StepSeries](StepSeries.md) — 使用此约定的阶梯系列
