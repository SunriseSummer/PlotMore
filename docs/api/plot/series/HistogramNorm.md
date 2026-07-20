[plot](../../index.md) › [plot.series](index.md) › HistogramNorm

# HistogramNorm

`plot.series` 中的 public enum

直方图条高的统计含义：原始计数、总和为 1 的频率，或积分为 1 的密度。设置在 [HistogramSeries.norm](HistogramSeries.md#norm) 上，[heights()](HistogramSeries.md#heights) 与绘制随之归一。

## 声明

```cangjie
public enum HistogramNorm
```

## 示例

```cangjie verify
package demo

import plot.series.{HistogramNorm, HistogramSeries}

main(): Unit {
    // 4 个样本落在 [0, 4] 上，分成 2 箱，分箱宽度 2.0
    let hist = HistogramSeries([0.0, 1.0, 1.0, 4.0], bins: 2)

    hist.norm = HistogramNorm.Frequency
    println(hist.heights()[0]) // 输出: 0.750000

    // 密度 = 频率 / 分箱宽度，各条形面积合计为 1
    hist.norm = HistogramNorm.Density
    println(hist.heights()[0]) // 输出: 0.375000
}
```

## 成员概览

**枚举值**

| 成员 | 说明 |
|---|---|
| `Count` | 每个分箱的原始样本计数。 |
| `Frequency` | 计数除以样本总数，各条形相加为 1。 |
| `Density` | 计数除以（样本总数 × 分箱宽度），条形面积积分为 1——可直接与概率密度函数比较。 |

## 另请参阅

- [HistogramSeries](HistogramSeries.md)
- [Stats.histogram](Stats.md#histogram)
