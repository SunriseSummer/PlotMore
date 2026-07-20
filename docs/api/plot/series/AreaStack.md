[plot](../../index.md) › [plot.series](index.md) › AreaStack

# AreaStack

`plot.series` 中的 public class

把多条 [AreaSeries](AreaSeries.md) 堆叠为逐层累计面积图的构建器：每层坐在其下所有层的累计总和之上。与 [BarGroup](BarGroup.md) 一样，堆叠是系列之间的关系而非单条系列的属性，因此在这里统一安排，而不是在每条系列上各自配置、再靠巧合对齐。

## 声明

```cangjie
public class AreaStack
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.series.AreaStack

main(): Unit {
    // 四个季度、三种渠道的营收：各层自底向上堆叠
    let quarters = [1.0, 2.0, 3.0, 4.0]
    let layers = AreaStack.build(
        quarters,
        [[40.0, 55.0, 62.0, 70.0], [80.0, 76.0, 70.0, 64.0], [12.0, 14.0, 11.0, 9.0]],
        labels: ["移动端", "桌面端", "平板"]
    )

    let (figure, axes) = Figure.single(title: "渠道营收")
    for (layer in layers) {
        axes.add(layer)
    }

    FigureExport.renderToPng(figure, "area-stack.png", width: 800, height: 600)
    println("层数: ${layers.size}") // 输出: 层数: 3
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
| [`static build(...)`](#build) | 从共享的 `xs` 与每层一个数值数组构建堆叠面积系列，层按自底向上的顺序给出。 |

## 构造函数

### init

**由编译器生成：** 该类未声明构造函数且没有未初始化的实例字段，仓颉因此合成此公有无参构造函数。

创建无状态的工具对象；通常直接调用静态成员，无需构造实例。

```cangjie
public init()
```

## 方法

### build

从共享的 `xs` 与每层一个数值数组构建堆叠面积系列，层按自底向上的顺序给出。每层的下边界是其下各层数值的累计和，上边界再加上本层数值；非有限的采样按 `0` 计入，不会毒化堆在它上面的每一层。返回的每条系列 `fillOpacity` 与 `fadeOpacity` 为 `0.85`、`showEdge` 为 `false`。

```cangjie
public static func build(xs: Array<Float64>, layers: Array<Array<Float64>>, labels!: Array<String> = []): Array<AreaSeries>
```

**参数**

- `xs`: `Array<Float64>` — 所有层共享的 x 坐标。
- `layers`: `Array<Array<Float64>>` — 每层一个数值数组，自底向上排列；每个数组须与 `xs` 等长。
- `labels!`: `Array<String>` — 各层的图例标签，默认 `[]`；比层数短时，其余层标签为空（不进入图例）。

**返回值** `Array<AreaSeries>` — 与 `layers` 等长、顺序相同的堆叠系列，可逐条加入 [Axes](../axes/Axes.md)。

**异常**

- `PlotException` — 任一层的长度与 `xs` 不同时。

## 另请参阅

- [AreaSeries](AreaSeries.md) — 堆叠产出的条带系列
- [BarGroup](BarGroup.md) — 柱状系列的分组与堆叠
