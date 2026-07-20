# 不确定性与分布

## 先用一句话说明

中心值只回答典型水平，区间和分布还要说明波动、偏斜与异常值。

一条均值线或一根柱只能告诉读者“中间大约在哪里”。当样本变化、测量误差或预测范围影响决策时，图还必须表达数据有多散、是否偏斜、是否多峰，以及区间究竟代表标准差、标准误还是置信区间。

## 为什么重要

只显示均值可能让两组完全不同的样本看起来一样：一组稳定集中，另一组波动巨大，也可能有少量异常值拉高平均数。误差棒和置信带适合已计算好的区间；直方图、小提琴图和箱线图则从不同角度显示一批样本。选择错误不只是样式问题，会改变读者对证据强度的判断。

## 工作模型

先区分“每个位置有一个估计及上下界”和“每组有一批原始样本”。前者使用 ErrorBarSeries 或 `AreaSeries.between`：离散位置用误差棒，连续 x 上的上下界用带状区域。后者使用分布图：直方图把数值分箱，箱线图压缩为中位数、四分位范围、须和异常点，小提琴图用平滑密度保留形状。三者互补，不能互相当作精确替代。

```cangjie role=contrast
let measured = ErrorBarSeries(x, mean, label: "均值 ± 标准误")
measured.setYError(error)
axes.add(measured)
```

```cangjie role=trace
let interval = AreaSeries.between(days, lower95, upper95, label: "95% 区间")
axes.add(interval)
axes.add(LineSeries(days, forecast, label: "预测均值"))
```

## 选择与取舍

误差棒紧凑，适合少量位置，但点很密时会拥挤。置信带能显示区间随连续 x 的变化，却可能遮住其他系列，应降低填充透明度并用同色中心线建立联系。直方图直观，但分箱数会影响外观；比较组别时应使用相同范围和分箱规则，或把每组放在独立面板。箱线图便于比较许多组，但会隐藏多峰；小提琴图显示形状，却受带宽和平滑影响，样本少时不宜把光滑轮廓当成精确事实。

图中必须说明区间含义。标准差描述样本散布，标准误描述均值估计精度，预测区间与置信区间也不是同一件事。Plot 负责绘制传入的上下界，不会替应用判断统计定义是否正确。

## 应用这个模型

先在代码之外写清每个数组的含义和单位。例如 `below`/`above` 是相对中心值的误差量，还是绝对上下界；`AreaSeries.between` 需要的是两条边界。对原始样本，先看样本量和分布形状，再决定是否同时给箱线图和小提琴图。若要跨组比较直方图，固定相同 `Bounds` 并试验多个合理分箱数，检查结论是否稳定。

本概念建立在[问题与视觉编码](chart-question-and-encoding.md)之上。可运行做法见[显示误差和置信带](../how-to/show-uncertainty.md)与[比较分布](../how-to/compare-distributions.md)。

## 常见误解

误差棒不自动等于 95% 置信区间；字段名称或图注必须说明来源。箱线图的须也不必等于最小值和最大值，具体统计规则应查数据计算过程。`HistogramNorm.Count` 表示区间计数，`Frequency` 让柱高总和为 1，`Density` 让总面积为 1，不能把不同归一化结果放在同一纵轴上直接比较。小提琴越光滑不代表数据越准确。

## 相关 API

- [`ErrorBarSeries`](../../api/plot/series/ErrorBarSeries.md)：绘制对称或不对称的 x/y 误差。
- [`HistogramSeries`](../../api/plot/series/HistogramSeries.md)：按区间统计样本并选择归一化方式。

## 下一步

先完成[显示误差和置信带](../how-to/show-uncertainty.md)，再用[比较分布](../how-to/compare-distributions.md)检查整批样本的形状。
