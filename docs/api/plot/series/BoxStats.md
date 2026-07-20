[plot](../../index.md) › [plot.series](index.md) › BoxStats

# BoxStats

`plot.series` 中的 public struct

箱线图绘制所需的五数概括与离群点。通常由 [Stats.box](Stats.md#box) 从一份样本算出，而不是手工构造；[BoxPlotSeries](BoxPlotSeries.md) 与 [ViolinSeries](ViolinSeries.md) 的 `stats()` 返回的就是它。

## 声明

```cangjie
public struct BoxStats
```

## 示例

```cangjie verify
package demo

import plot.series.{BoxStats, Stats}

main(): Unit {
    let summary: BoxStats = Stats.box([1.0, 2.0, 3.0, 4.0, 5.0, 100.0])
    println(summary.median) // 输出: 3.500000
    println(summary.iqr()) // 输出: 2.500000
    // 须落在围栏内最远的真实观测上；100.0 越过围栏，成为离群点
    println(summary.upperWhisker) // 输出: 5.000000
    println(summary.outliers[0]) // 输出: 100.000000
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 逐字段构造摘要。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`iqr()`](#iqr) | 四分位距。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`q1`](#q1) | 下四分位数（第 25 百分位）。 |
| [`median`](#median) | 中位数（第 50 百分位）。 |
| [`q3`](#q3) | 上四分位数（第 75 百分位）。 |
| [`lowerWhisker`](#lowerwhisker) | 仍在须可达范围内的最低样本。 |
| [`upperWhisker`](#upperwhisker) | 仍在须可达范围内的最高样本。 |
| [`outliers`](#outliers) | 须之外的样本。 |
| [`mean`](#mean) | 样本的算术平均值。 |

## 构造函数

### init

逐字段构造摘要。绘图路径由 [Stats.box](Stats.md#box) 生成摘要；手工构造只在自备统计结果时需要。

```cangjie
public init(q1: Float64, median: Float64, q3: Float64, lowerWhisker: Float64, upperWhisker: Float64, outliers: Array<Float64>, mean: Float64)
```

**参数**

- `q1`: `Float64` — 下四分位数。
- `median`: `Float64` — 中位数。
- `q3`: `Float64` — 上四分位数。
- `lowerWhisker`: `Float64` — 下须端值。
- `upperWhisker`: `Float64` — 上须端值。
- `outliers`: `Array<Float64>` — 须外样本。
- `mean`: `Float64` — 算术平均值。

## 方法

### iqr

四分位距。

```cangjie
public func iqr(): Float64
```

**返回值** `Float64` — `q3 - q1`。

## 字段

### q1

下四分位数（第 25 百分位）。

```cangjie
public let q1: Float64
```

### median

中位数（第 50 百分位）。

```cangjie
public let median: Float64
```

### q3

上四分位数（第 75 百分位）。

```cangjie
public let q3: Float64
```

### lowerWhisker

仍在须可达范围内的最低样本。

```cangjie
public let lowerWhisker: Float64
```

### upperWhisker

仍在须可达范围内的最高样本。

```cangjie
public let upperWhisker: Float64
```

### outliers

须之外的样本。

```cangjie
public let outliers: Array<Float64>
```

### mean

样本的算术平均值。

```cangjie
public let mean: Float64
```

## 另请参阅

- [Stats.box](Stats.md#box)
- [BoxPlotSeries](BoxPlotSeries.md)
- [ViolinSeries](ViolinSeries.md)
