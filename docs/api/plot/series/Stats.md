[plot](../../index.md) › [plot.series](index.md) › Stats

# Stats

`plot.series` 中的 public class

分布类图表使用的描述统计工具集。原始样本入口先过滤非有限值——带缺口的数据集按真实样本统计，而不是产出 NaN；[quantile](#quantile) 与 [silvermanBandwidth](#silvermanbandwidth) 则约定以 [sortedFinite](#sortedfinite) 的输出为输入。

## 声明

```cangjie
public class Stats
```

## 示例

```cangjie verify
package demo

import plot.core.Bounds
import plot.series.Stats

main(): Unit {
    let sorted = Stats.sortedFinite([3.0, 1.0, 4.0, 2.0])
    println(Stats.quantile(sorted, 0.5)) // 输出: 2.500000

    // 边界上的值进上方的分箱；最大值 4.0 收进最后一箱
    let counts = Stats.histogram([1.0, 2.0, 3.0, 4.0], Bounds(0.0, 4.0), 4)
    println("${counts[0]} ${counts[1]} ${counts[2]} ${counts[3]}") // 输出: 0 1 1 2

    match (Stats.linearFit([0.0, 1.0, 2.0], [1.0, 3.0, 5.0])) {
        case Some((slope, intercept)) => println("${slope} ${intercept}") // 输出: 2.000000 1.000000
        case None => println("拟合失败")
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
| [`static sortedFinite(...)`](#sortedfinite) | `values` 中的有限子集，升序排序——本类其他方法约定的输入形态。 |
| [`static quantile(...)`](#quantile) | 已排序数组的第 `p` 分位数（`p` 取 `0..1`），按 R 型 7 定义在相邻次序统计量间线性插值。 |
| [`static mean(...)`](#mean) | 有限值的算术平均；没有任何有限值时为 `None`。 |
| [`static standardDeviation(...)`](#standarddeviation) | 样本标准差（除以 n-1）；有限值少于两个时为 `None`。 |
| [`static box(...)`](#box) | `values` 的箱线摘要。 |
| [`static histogram(...)`](#histogram) | 把 `values` 按 `count` 个等宽分箱统计到 `range` 上，返回每箱计数。 |
| [`static suggestBinCount(...)`](#suggestbincount) | 按 Freedman-Diaconis 规则选择的分箱数，钳制在 `1..200`。 |
| [`static kernelDensity(...)`](#kerneldensity) | `values` 的高斯核密度估计，在 `range` 上等距取 `count` 个采样点。 |
| [`static silvermanBandwidth(...)`](#silvermanbandwidth) | Silverman 经验带宽：`0.9 * min(sd, IQR/1.34) * n^(-1/5)`。 |
| [`static linearFit(...)`](#linearfit) | 最小二乘拟合 `y = slope * x + intercept`。 |

## 构造函数

### init

**由编译器生成：** 该类未声明构造函数且没有未初始化的实例字段，仓颉因此合成此公有无参构造函数。

创建无状态的工具对象；通常直接调用静态成员，无需构造实例。

```cangjie
public init()
```

## 方法

### sortedFinite

`values` 中的有限子集，升序排序——本类其他方法约定的输入形态。

```cangjie
public static func sortedFinite(values: Array<Float64>): Array<Float64>
```

**参数**

- `values`: `Array<Float64>` — 原始样本，可含非有限值。

**返回值** `Array<Float64>` — 新数组，可能为空。

### quantile

已排序数组的第 `p` 分位数（`p` 取 `0..1`），按 R 型 7 定义在相邻次序统计量间线性插值。与 numpy.percentile 和多数电子表格一致；`p` 超出 `0..1` 时按边界处理，单元素数组直接返回该元素。

```cangjie
public static func quantile(sorted: Array<Float64>, p: Float64): Float64
```

**参数**

- `sorted`: `Array<Float64>` — 已升序排序的有限值，通常来自 [sortedFinite](#sortedfinite)。
- `p`: `Float64` — 分位位置，`0..1`。

**返回值** `Float64` — 分位数。

**异常**

- [`PlotException`](../core/PlotException.md) — `sorted` 为空时。

### mean

有限值的算术平均；没有任何有限值时为 `None`。

```cangjie
public static func mean(values: Array<Float64>): ?Float64
```

**参数**

- `values`: `Array<Float64>` — 样本，非有限值不计入。

**返回值** `?Float64` — 平均值，或 `None`。

### standardDeviation

样本标准差（除以 n-1）；有限值少于两个时为 `None`。

```cangjie
public static func standardDeviation(values: Array<Float64>): ?Float64
```

**参数**

- `values`: `Array<Float64>` — 样本，非有限值不计入。

**返回值** `?Float64` — 标准差，或 `None`。

### box

`values` 的箱线摘要。箱须延伸到距四分位数 `whiskerRange` 倍四分位距以内最远的样本（Tukey 规则，惯例 1.5），更远的样本报告为离群点；箱须端点落在真实数据点上而非围栏上。全部样本都在围栏外时，两侧箱须收拢到中位数。

```cangjie
public static func box(values: Array<Float64>, whiskerRange!: Float64 = 1.5): BoxStats
```

**参数**

- `values`: `Array<Float64>` — 样本，非有限值先被过滤。
- `whiskerRange`: `Float64` — 围栏的四分位距倍数；默认 `1.5`。

**返回值** [`BoxStats`](BoxStats.md) — 五数概括加离群点。

**异常**

- `PlotException` — 没有任何有限值时。

### histogram

把 `values` 按 `count` 个等宽分箱统计到 `range` 上，返回每箱计数。落在分箱边界上的值进上方的分箱，最顶端的边界除外（收进最后一箱）——否则最大样本会落进一个不存在的分箱。范围之外与非有限的值不计入；`range` 跨度非正时全为零。

```cangjie
public static func histogram(values: Array<Float64>, range: Bounds, count: Int64): Array<Int64>
```

**参数**

- `values`: `Array<Float64>` — 样本。
- `range`: [`Bounds`](../core/Bounds.md) — 统计区间。
- `count`: `Int64` — 分箱数，须为正。

**返回值** `Array<Int64>` — 长度为 `count` 的每箱计数。

**异常**

- `PlotException` — `count` 小于 1 时。

### suggestBinCount

按 Freedman-Diaconis 规则选择的分箱数，钳制在 `1..200`。分箱宽度 `2 * IQR / n^(1/3)` 随散布而不仅随样本量适应——这是重尾分布不被切成噪声的原因；四分位距为零（过半质量集中在同一个值上）时退回 Sturges 规则。有限样本少于两个或全部相等时为 1。

```cangjie
public static func suggestBinCount(values: Array<Float64>): Int64
```

**参数**

- `values`: `Array<Float64>` — 样本，非有限值不计入。

**返回值** `Int64` — `1..200` 内的分箱数。

### kernelDensity

`values` 的高斯核密度估计，在 `range` 上等距取 `count` 个采样点。`bandwidth` 是核的标准差；`None` 用 Silverman 经验规则——对大致单峰的数据是合理默认，对多峰数据会过度平滑，形状要紧时请显式给带宽。

```cangjie
public static func kernelDensity(values: Array<Float64>, range: Bounds, count: Int64, bandwidth!: ?Float64 = None): Array<Float64>
```

**参数**

- `values`: `Array<Float64>` — 样本，非有限值先被过滤。
- `range`: `Bounds` — 采样区间。
- `count`: `Int64` — 采样点数；小于 1 时返回空数组。
- `bandwidth`: `?Float64` — 核标准差，须为正；`None`（默认）或非正值退回 Silverman 规则。

**返回值** `Array<Float64>` — 各采样点的密度；没有有限样本时全为零。

### silvermanBandwidth

Silverman 经验带宽：`0.9 * min(sd, IQR/1.34) * n^(-1/5)`。对大致单峰的数据是合理的默认平滑度。

```cangjie
public static func silvermanBandwidth(sorted: Array<Float64>): Float64
```

**参数**

- `sorted`: `Array<Float64>` — 已升序排序的有限值，通常来自 [sortedFinite](#sortedfinite)。

**返回值** `Float64` — 带宽；样本少于两个或散布度量退化为零时为 `1.0`。

### linearFit

最小二乘拟合 `y = slope * x + intercept`。有限点少于两个，或所有 x 相同（垂直线没有斜率）时为 `None`；任一坐标非有限的点按对跳过。

```cangjie
public static func linearFit(xs: Array<Float64>, ys: Array<Float64>): ?(Float64, Float64)
```

**参数**

- `xs`: `Array<Float64>` — 自变量。
- `ys`: `Array<Float64>` — 因变量，与 `xs` 一一对应。

**返回值** `?(Float64, Float64)` — `(斜率, 截距)`，或 `None`。

**异常**

- `PlotException` — `xs` 与 `ys` 长度不一致时。

## 另请参阅

- [BoxStats](BoxStats.md)
- [HistogramSeries](HistogramSeries.md)
- [ViolinSeries](ViolinSeries.md)
