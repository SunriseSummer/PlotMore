[plot](../../index.md) › [plot.axes](index.md) › PieLabelMode

# PieLabelMode

`plot.axes` 中的 public enum

饼图切片标签显示的内容。设置到 [PieAxes](PieAxes.md) 的 `labelMode` 字段上，对所有切片统一生效。

## 声明

```cangjie
public enum PieLabelMode
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.{PieAxes, PieSlice, PieLabelMode}

main(): Unit {
    let pie = PieAxes([
        PieSlice(3.0, label: "赞成"),
        PieSlice(1.0, label: "反对")
    ])
    pie.labelMode = PieLabelMode.Percent    // 切片上只标百分比
    let figure = Figure("投票结果")
    figure.addPanel(pie)
    FigureExport.renderToPng(figure, "pie-percent.png", width: 640, height: 480)
    println(pie.fraction(0)) // 输出: 0.750000
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Name` | 仅切片名称。 |
| `Percent` | 占总量的百分比。 |
| `Value` | 原始数值，按紧凑格式显示。 |
| `NameAndPercent` | 名称加百分比；名称为空时只显示百分比。 |
| `NoLabel` | 切片上不放标签，改用图例。 |

## 另请参阅

- [PieAxes](PieAxes.md)
- [NumberFormat](../core/NumberFormat.md) —— 百分比与紧凑数值的格式化来源
