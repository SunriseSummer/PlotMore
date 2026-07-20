[plot](../../index.md) › [plot.series](index.md) › BarGroup

# BarGroup

`plot.series` 中的 public class

把共享一条类别轴的多个条形系列安排成并排分组或堆叠布局的工具。分组与堆叠是系列*之间*的关系——单根条形无法从自身数值得知槽位或堆叠起点——所以在这里一次安排妥当，而不是在每个 [BarSeries](BarSeries.md) 上分别配置、靠约定对齐。

## 声明

```cangjie
public class BarGroup
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.core.CategoryScale
import plot.series.{BarGroup, BarSeries}

main(): Unit {
    let (figure, axes) = Figure.single(title: "季度营收")
    axes.setXScale(CategoryScale(["Q1", "Q2", "Q3"]))
    let hardware = BarSeries([4.0, 6.0, 5.0], label: "硬件")
    let software = BarSeries([3.0, 2.0, 7.0], label: "软件")
    for (series in BarGroup.stacked([hardware, software])) {
        axes.add(series)
    }

    FigureExport.renderToPng(figure, "bar-stack.png", width: 800, height: 600)

    // 堆叠后，"软件"从"硬件"的累计值上继续生长
    match (software.dataBounds()) {
        case Some((_, valueBounds)) => println("${valueBounds}") // 输出: Bounds(0.000000, 12.000000)
        case None => ()
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建无状态的工具对象；通常直接调用静态成员，无需构造实例。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static grouped(...)`](#grouped) | 把各系列在每个类别带内并排放置，槽位按实参顺序。 |
| [`static stacked(...)`](#stacked) | 把各系列按实参顺序堆叠，每个系列从前一个结束的位置继续。 |

## 构造函数

### init

**由编译器生成：** 该类未声明构造函数且没有未初始化的实例字段，仓颉因此合成此公有无参构造函数。

创建无状态的工具对象；通常直接调用静态成员，无需构造实例。

```cangjie
public init()
```

## 方法

### grouped

把各系列在每个类别带内并排放置，槽位按实参顺序。

```cangjie
public static func grouped(series: Array<BarSeries>): Array<BarSeries>
```

**参数**

- `series`: `Array<BarSeries>` — 共享同一类别轴的条形系列。

**返回值** `Array<BarSeries>` — 原样返回传入的数组，便于直接继续添加到坐标区。

**异常**

- [`PlotException`](../core/PlotException.md) — 各系列的条形数不一致时——错位的分组会对不上类别。

### stacked

把各系列按实参顺序堆叠，每个系列从前一个结束的位置继续。正值与负值各自独立地背离基线累计——混合符号的堆叠从零向上下两个方向生长，而不是相互抵消成一团无法阅读的重叠。非有限值不计入累计；每个系列的槽位同时被重置为独占整个类别带。空数组原样返回。

```cangjie
public static func stacked(series: Array<BarSeries>): Array<BarSeries>
```

**参数**

- `series`: `Array<BarSeries>` — 共享同一类别轴的条形系列，按堆叠顺序（自基线向外）。

**返回值** `Array<BarSeries>` — 原样返回传入的数组。

**异常**

- `PlotException` — 各系列的条形数不一致时。

## 另请参阅

- [BarSeries](BarSeries.md)
- [BarOrientation](BarOrientation.md)
- [CategoryScale](../core/CategoryScale.md)
