[plot 指南](../index.md) › 比较分布

# 比较直方图、箱线图和小提琴图

## 目标

根据样本量和分析问题，在直方图、箱线图与小提琴图之间做出可解释选择，并避免把分箱或平滑参数造成的形状当成数据事实。最终图应让读者看出频数形状、稳健摘要或密度轮廓中的一种主要信息。

## 适用场景

用于延迟、价格、测量误差等一组或多组连续样本。若只有每月一个汇总值，你没有可展示的分布，应使用趋势或类别比较；若要观察两个变量关系，使用散点图。

## 准备工作

本页是独立操作指南，不继承第一张图或选择图表页。准备一个能依赖 `plot` 的 `demo` 消费者项目；项目布局与[第一张折线图](../getting-started/first-chart.md)相同。程序不打开可见窗口，而是直接导出 `distribution-comparison.png`，但 `FigureExport` 仍会创建隐藏 SDL 窗口：自动环境必须能加载 SDL3/SDL3_ttf，并支持隐藏渲染；纯无图形运行环境不保证可用。

保留原始样本数组，记录单位、缺失值处理和组别。样本太少时，平滑密度会暗示不存在的细节；极端值很多时，先确认它们是有效观测还是数据错误。读者需要知道每组样本代表相同口径。本例故意使用固定数组而不是随机生成器，使分箱、箱体和小提琴的变化都来自参数，而不是每次运行的新样本。

## 操作步骤

### 1. 需要看频数形状时选直方图

`HistogramSeries` 把样本分进等宽区间。`Count` 适合回答每个区间有多少观测；`Frequency` 让柱高总和为 1；`Density` 让总面积为 1，适合与概率密度比较。分箱数量会改变细节：先用中等数量，再用相邻设置检查结论是否稳定。

下面的完整程序把同一批两组样本放进三个独立面板：直方图回答“基线样本集中在哪些区间”，箱线图比较摘要，小提琴图展示平滑轮廓。三个面板共享报告标题，但不共用不相容的横轴语义。

### 2. 需要紧凑比较多组时选箱线图

`BoxPlotSeries` 用中位数、四分位范围和须概括样本，适合在有限空间比较多个组。它不展示完整形状；两个不同分布可能有相似箱体，因此发现异常后应回到原始点或分布图。

### 3. 需要看形状与多峰时选小提琴图

`ViolinSeries` 用核密度展示轮廓，能暴露偏斜或多峰。带宽和平滑会影响轮廓，样本很少时不要把光滑曲线当精确事实。最好同时标明样本量或配合箱线摘要。

### 4. 用同一口径比较

多组分布应使用相同单位、过滤规则和可比范围。将图放在同一面板或一致尺度的面板中，再通过标签说明组别；不要让每组自动范围制造视觉上同样宽的假象。

## 完整程序

把以下内容保存为 `src/main.cj`。程序使用公开 API 构建三面板报告，并同步导出文件；不依赖仓库内部的 `examples.Data` 辅助函数。

```cangjie verify role=complete
package demo

import plot.{Figure, FigureExport}
import plot.core.CategoryScale
import plot.series.{BoxPlotSeries, HistogramNorm, HistogramSeries, ViolinSeries}

main(): Unit {
    let baseline = [118.0, 121.0, 123.0, 126.0, 129.0, 131.0, 134.0, 138.0, 143.0, 151.0, 164.0, 188.0]
    let optimized = [72.0, 76.0, 79.0, 81.0, 84.0, 86.0, 88.0, 91.0, 95.0, 101.0, 108.0, 119.0]
    let groups = [baseline, optimized]

    let figure = Figure("响应时间分布比较")
    figure.subtitle = "同一口径的直方图、箱线摘要与密度轮廓"
    figure.setGrid(1, 3)

    let histogramAxes = figure.addAxes()
    histogramAxes.title = "基线频数"
    histogramAxes.xLabel = "响应时间（ms）"
    histogramAxes.yLabel = "观测数"
    let histogram = HistogramSeries(baseline, bins: 6, label: "基线")
    histogram.norm = HistogramNorm.Count
    histogramAxes.add(histogram)

    let boxAxes = figure.addAxes()
    boxAxes.title = "分位数摘要"
    boxAxes.xLabel = "版本"
    boxAxes.yLabel = "响应时间（ms）"
    boxAxes.setXScale(CategoryScale(["基线", "优化后"]))
    let boxes = BoxPlotSeries(groups, label: "响应时间")
    boxes.showMean = true
    boxAxes.add(boxes)

    let violinAxes = figure.addAxes()
    violinAxes.title = "密度轮廓"
    violinAxes.xLabel = "版本"
    violinAxes.yLabel = "响应时间（ms）"
    violinAxes.setXScale(CategoryScale(["基线", "优化后"]))
    let violins = ViolinSeries(groups, label: "响应时间")
    violins.showBox = true
    violinAxes.add(violins)

    FigureExport.renderToPng(figure, "distribution-comparison.png", width: 900, height: 360)
    println("已写入 distribution-comparison.png")
}
```

要比较“每个区间的占比”而不是原始观测数，只替换完整程序中 `histogram.norm` 的赋值，并同步更改纵轴标题。这个变化不影响箱线图和小提琴图：

```cangjie role=variation
histogramAxes.yLabel = "频率"
histogram.norm = HistogramNorm.Frequency
```

## 确认结果

在项目目录运行 `cjpm run`，终端应打印“已写入 distribution-comparison.png”，当前目录出现非空 PNG。打开文件后应看到一行三列：左侧六个区间的基线直方图，中间两个箱体，右侧两把小提琴；后两面板的“基线/优化后”标签顺序相同。再用一个已知的小样本手工核对最小值、中位数和最大值，并观察结论是否在相邻分箱/带宽设置下保持。若读者无法知道柱高是计数、频率还是密度，补充轴标签。

## 常见错误

- 把频率与密度都解释为“百分比”，忽略区间宽度。
- 只凭一个分箱数量判断双峰或异常峰。
- 用小提琴图显示十几个样本，平滑轮廓比数据本身更强。
- 用箱线图推断完整分布形状。
- 多组样本过滤规则不同，却放在一起比较。

## 相关 API

- [`HistogramSeries`](../../api/plot/series/HistogramSeries.md) — 样本分箱及归一化方式。
- [`BoxPlotSeries`](../../api/plot/series/BoxPlotSeries.md) — 分位数摘要和异常值表达。
- [`ViolinSeries`](../../api/plot/series/ViolinSeries.md) — 核密度轮廓。
- [`Axes`](../../api/plot/axes/Axes.md) — 多组系列的共享坐标语境。

## 下一步

先在[选择图表](choose-chart.md)中检查分布图是否真的回答业务问题，再用[配置坐标](configure-axes.md)固定多组比较所需的共同尺度。需要交付报告时继续[导出 PNG](export-image.md)。
