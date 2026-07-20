# 分组或堆叠柱形

## 目标

用同一份分类数据生成并列柱和堆叠柱两个面板，并导出为一张 PNG。并列柱回答“同一季度中各渠道谁更高”，堆叠柱回答“总量由哪些渠道构成”，两者不能只靠一个样式开关互相替代。

![并列柱画廊结果](../../../examples/gallery/bar-grouped.png)

![堆叠柱画廊结果](../../../examples/gallery/bar-stacked.png)

## 适用场景

当每个类别有多组同单位数值时使用。需要精确比较每组，选 grouped；关心总量和构成，选 stacked。若各组单位不同或正负含义复杂，应拆面板。类别很多且名称长时，可考虑水平柱。

## 准备工作

每个 BarSeries 的值数量必须等于类别数量，参与一个 BarGroup 的所有系列也必须数量一致。准备四个季度、两个渠道和相同单位的数值。程序使用 FigureExport，无需打开窗口，适合 CI 或远程环境。

## 操作步骤

完整程序建立 1×2 网格，为两个面板分别设置相同 CategoryScale。`BarGroup.grouped` 为同类柱分配并列槽位；`BarGroup.stacked` 为各层计算基线。它们返回调整后的系列数组，仍要逐个加入目标 Axes。

```cangjie verify role=complete
package guide_examples

import plot.{Figure, FigureExport}
import plot.core.CategoryScale
import plot.series.{BarGroup, BarSeries}

main(): Unit {
    let figure = Figure("季度收入：比较与构成")
    figure.setGrid(1, 2)
    let categories = ["Q1", "Q2", "Q3", "Q4"]

    let groupedAxes = figure.addAxes()
    groupedAxes.title = "并列比较"
    groupedAxes.setXScale(CategoryScale(categories))
    groupedAxes.showGridX = false
    let grouped = BarGroup.grouped(
        [
            BarSeries([12.0, 18.0, 16.0, 24.0], label: "线上"),
            BarSeries([8.0, 11.0, 13.0, 15.0], label: "门店")
        ]
    )
    for (series in grouped) {
        groupedAxes.add(series)
    }

    let stackedAxes = figure.addAxes()
    stackedAxes.title = "堆叠构成"
    stackedAxes.setXScale(CategoryScale(categories))
    stackedAxes.showGridX = false
    let stacked = BarGroup.stacked(
        [
            BarSeries([12.0, 18.0, 16.0, 24.0], label: "线上"),
            BarSeries([8.0, 11.0, 13.0, 15.0], label: "门店")
        ]
    )
    for (series in stacked) {
        stackedAxes.add(series)
    }

    FigureExport.renderToPng(figure, "bars.png", width: 1200, height: 560)
    println("已写入 bars.png") // 输出: 已写入 bars.png
}
```

横向柱适合长类别名。下面变化使用 `BarOrientation.Horizontal`，类别标度改到 y 轴，不再经过 BarGroup，验证的是另一种布局任务。

```cangjie role=variation
axes.setYScale(CategoryScale(["解析", "类型检查", "优化", "代码生成", "链接"]))
let duration = BarSeries([142.0, 388.0, 265.0, 431.0, 96.0])
duration.orientation = BarOrientation.Horizontal
duration.showValues = true
axes.add(duration)
```

## 确认结果

终端应打印“已写入 bars.png”，当前目录应存在可打开的 1200×560 PNG。左面板每个季度有两根并列柱，能直接比较渠道；右面板每个季度只有一根总柱，但有两段颜色，顶边代表总量。两个面板的类别顺序必须相同，图例名称必须对应同一渠道。

## 常见错误

把长度不同的 BarSeries 交给 BarGroup 会失败；只创建 group 却忘记循环 `axes.add` 会得到空面板。堆叠柱不适合精确比较上层段，因为它们没有共同基线。正负值混合时会分别从零向上下堆叠，不应把正负相消后的净值当作柱顶读数。

## 相关 API

- [`BarGroup`](../../api/plot/series/BarGroup.md)：计算并列槽位或堆叠基线。
- [`BarSeries`](../../api/plot/series/BarSeries.md)：绘制竖直或水平柱。

## 下一步

继续[用颜色和大小编码散点属性](map-color-and-size.md)，学习在位置之外增加两个有解释的变量。
