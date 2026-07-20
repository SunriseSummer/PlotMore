# 显示误差和置信带

## 目标

在一张双面板图片中，用误差棒表示离散测量点的上下误差，用面积带表示连续预测的上下边界。读者能从标题和图例判断区间含义，而不会把两种图形误认为原始数据本身。

![误差棒画廊结果；用于核对点、连线、上下误差与端帽](../../../examples/gallery/errorbar.png)

画廊文件来自 `examples/src/scatter.cj`，SHA-256 为 `855ff1c25b2869f3e4e99dbda602b3cd2dae406c23743a8b6bbce046a75410d8`。

## 适用场景

每个离散 x 位置已有中心估计与误差量时使用 ErrorBarSeries；连续 x 上已有 lower/upper 边界时使用 `AreaSeries.between`。如果手头是一批原始样本而不是预先计算的区间，应阅读[比较分布](compare-distributions.md)。

## 准备工作

明确区间的统计含义和单位。`setYErrorRange(below, above)` 接收相对中心值向下和向上的误差量，不是绝对上下边界；`AreaSeries.between` 接收绝对 lower 与 upper 数组。所有数组长度必须与 x 一致。

## 操作步骤

下面程序使用固定数据，建立上下两个面板并导出。误差棒连接中心点，置信带上再叠加均值线，避免读者只看到一块填色区域。

```cangjie verify role=complete
package guide_examples

import plot.{Figure, FigureExport}
import plot.series.{AreaSeries, ErrorBarSeries, LineSeries}

main(): Unit {
    let figure = Figure("离散误差与连续区间")
    figure.setGrid(2, 1)

    let measuredAxes = figure.addAxes()
    measuredAxes.title = "测量均值 ± 标准误"
    let x = [1.0, 2.0, 3.0, 4.0, 5.0]
    let mean = [10.2, 12.4, 15.1, 16.8, 19.3]
    let measured = ErrorBarSeries(x, mean, label: "均值")
    measured.setYErrorRange([0.8, 0.7, 1.1, 0.9, 1.3], [1.0, 0.9, 1.2, 1.1, 1.5])
    measured.connect = true
    measuredAxes.add(measured)

    let forecastAxes = figure.addAxes()
    forecastAxes.title = "预测均值与 95% 区间"
    let lower = [9.0, 10.3, 11.1, 11.6, 11.8]
    let upper = [11.0, 13.1, 15.3, 17.4, 19.2]
    let band = AreaSeries.between(x, lower, upper, label: "95% 区间")
    band.fillOpacity = 0.22
    forecastAxes.add(band)
    forecastAxes.add(LineSeries(x, [10.0, 11.7, 13.2, 14.5, 15.5], label: "预测均值"))

    FigureExport.renderToPng(figure, "uncertainty.png", width: 1000, height: 820)
    println("已写入 uncertainty.png") // 输出: 已写入 uncertainty.png
}
```

若上下误差对称，可使用一个数组简化输入。下面变化还关闭中心点连线，适合彼此独立、没有连续顺序的实验条件。

```cangjie role=variation
let groups = [1.0, 2.0, 3.0, 4.0]
let summary = ErrorBarSeries(groups, [8.2, 7.9, 9.1, 8.7], label: "均值 ± 标准差")
summary.setYError([0.6, 0.4, 0.8, 0.5])
summary.connect = false
axes.add(summary)
```

## 确认结果

运行后应打印文件名并生成可打开的 1000×820 PNG。上面板有五个中心点、五组上下端帽，误差不完全对称；下面板的阴影带随 x 变宽，中间有一条均值线。图例应明确区分“均值”和“95% 区间”。核对任何位置都满足 lower ≤ mean ≤ upper。

## 常见错误

把绝对上下界传给 `setYErrorRange` 会把区间画得过大；把相对误差传给 `AreaSeries.between` 则会把带放到错误位置。区间名称含糊也会误导：标准差、标准误、置信区间和预测区间必须明确。透明度过高会遮住中心线，点太密时误差棒会互相覆盖。

在交付前还应核对单位：误差量必须与中心值同单位，x 误差与 y 误差也不能交换。若多个系列共享面板，应让区间颜色与对应中心线保持一致，并在灰度下检查两组结果仍可区分。

## 相关 API

- [`ErrorBarSeries`](../../api/plot/series/ErrorBarSeries.md)：显示离散位置的对称或不对称误差。
- [`AreaSeries`](../../api/plot/series/AreaSeries.md)：填充两条连续边界之间的区域。

## 下一步

继续[比较两组分布](compare-distributions.md)，从区间摘要推进到完整样本形状。
