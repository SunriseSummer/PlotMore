[plot 指南](../index.md) › 多面板报告

# 构建一份多面板分析报告

## 你将完成

你会在一个窗口中并排展示两个问题：左侧用折线观察四周销量趋势，右侧用分类柱状图比较三个渠道。它们共享总标题和主题，但各自拥有适合数据的坐标语境。完成后，你应能指出哪些配置属于整张图、哪些属于面板、哪些属于数据系列，并能独立修改任一面板而不影响另一边的含义。

这个教程不是为了塞入尽可能多的图表类型，而是练习“一个分析问题一个面板”。趋势和渠道比较都与销量有关，适合出现在同一报告；一个使用连续时间位置，另一个使用离散类别，所以不应共用同一横轴。

## 开始之前

先完成[第一张折线图](../getting-started/first-chart.md)，并读过[组合模型](../concepts/figure-axes-series.md)。沿用同一个 `demo` 项目和 SDL 运行环境即可。你需要知道数组按位置配对，以及 `Figure.addAxes` 会按加入顺序填充已设置的网格。

本例使用固定数据，便于每次运行对照。真实项目中可以先在业务层完成查询和清洗，再把结果数组交给图形构建函数；不要让绘图代码同时负责网络请求、错误恢复和数据转换。

## 先建立一个模型

把报告看成一张桌面：`Figure` 决定桌面标题和两个位置；每个 `Axes` 是一个独立分析卡片；`LineSeries` 与 `BarSeries` 是卡片中的数据层。两个面板可以使用不同横轴，因为它们只共享外层作品，不共享标度。

我们先调用 `setGrid(1, 2)` 留出一行两列，再连续调用两次 `addAxes`。第一个面板使用数值位置表示周次，第二个面板换成 `CategoryScale` 显示渠道名称。系列标签仍然有意义，因为图例告诉读者数值代表“销量”而非目标、预测或成本。

## 操作步骤

### 1. 建立整张报告

创建 `Figure`，设置总标题和 1×2 网格。总标题回答“这份作品是什么”，不要拿它重复左侧面板标题。

### 2. 加入趋势面板

第一个 `Axes` 使用折线。设置 x/y 标签后加入系列；自动范围会合并该系列的四个有效点。若以后再加入目标线，仍应加到这个面板，因为它与销量趋势共享单位。

### 3. 加入渠道面板

第二个 `Axes` 使用分类标度，把三个位置显示为“门店、网站、合作方”。柱状图比较离散项目，横向网格通常没有额外价值，因此可以关闭 `showGridX`。

### 4. 运行同一个窗口

把完成的 `Figure` 交给一个 `PlotWindow`。窗口会把可用区域分给两个面板；窗口尺寸变化时，它们一起重新排布。

## 完整程序

```cangjie verify role=complete
package demo

import plot.{Figure, PlotWindow}
import plot.core.CategoryScale
import plot.series.{BarSeries, LineSeries}

main(): Unit {
    let figure = Figure("四周销售报告")
    figure.subtitle = "趋势与渠道构成使用独立坐标面板"
    figure.setGrid(1, 2)

    let trend = figure.addAxes()
    trend.title = "周销量趋势"
    trend.xLabel = "周次"
    trend.yLabel = "件"
    trend.add(LineSeries([1.0, 2.0, 3.0, 4.0], [120.0, 146.0, 138.0, 171.0], label: "销量"))

    let channel = figure.addAxes()
    channel.title = "本月渠道销量"
    channel.yLabel = "件"
    channel.showGridX = false
    channel.setXScale(CategoryScale(["门店", "网站", "合作方"]))
    channel.add(BarSeries([230.0, 318.0, 127.0], label: "销量"))

    let window = PlotWindow(figure)
    window.show()
}
```

## 确认结果

执行 `cjpm run`。窗口应显示一行两列：左侧折线有四个周次数据，右侧三根柱对应三个渠道；两个面板都有独立标题和纵轴，但共享“销售报告”的总标题。关闭窗口后程序返回。

检查代码与画面的对应关系：修改左侧最后一个值只应改变折线；把右侧类别顺序和数值同时调换，只应改变柱状面板。若一次修改同时改变两边，检查是否误用了同一个面板变量或把配置写到了 `figure` 层。

## 接着试一试

1. 将网格改为 `2, 1`，观察同样两个面板改为上下排列；数据与系列代码无需变化。
2. 给趋势面板再加入一条“目标”折线，使用相同周次。它应与销量直接比较，而不是占用新面板。
3. 将渠道面板的类别改为真实业务渠道，并确保数组顺序同步。分类标签与数值错位不会触发编译错误，只能通过语义检查发现。

第二项修改只触及趋势面板。把这段放在原有“销量”系列之后；它复用同一组周次，因此两条线可以直接比较：

```cangjie role=variation
trend.add(LineSeries(
    [1.0, 2.0, 3.0, 4.0],
    [130.0, 140.0, 150.0, 160.0],
    label: "目标"
))
```

## 如果没有成功

- **只有一个面板**：确认 `setGrid(1, 2)` 后调用了两次 `figure.addAxes()`，且两个返回值没有相互覆盖。
- **柱子显示数值位置而不是渠道名**：检查 `setXScale(CategoryScale(...))` 是否设置在 `channel` 面板。
- **内容过挤**：增大窗口或改用 2×1；不要先缩小全部字号掩盖信息密度。
- **两个面板单位混乱**：分别设置每个面板的 `yLabel`，不要把单位只写进总标题。

## 相关 API

- [`Figure`](../../api/plot/Figure.md) — 网格与面板组合。
- [`Axes`](../../api/plot/axes/Axes.md) — 每个笛卡尔面板的标签、标度和系列。
- [`LineSeries`](../../api/plot/series/LineSeries.md) 与 [`BarSeries`](../../api/plot/series/BarSeries.md) — 两种数据关系的表达。
- [`CategoryScale`](../../api/plot/core/CategoryScale.md) — 离散类别横轴。

## 下一步

继续[配置坐标与对数轴](../how-to/configure-axes.md)，学习何时保留自动范围、何时显式固定。需要把报告交给别人而不是只在窗口查看时，完成[导出 PNG](../how-to/export-image.md)。
