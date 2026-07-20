[plot](../../index.md) › plot.series

# plot.series

```cangjie
import plot.series.{LineSeries, ScatterSeries, BarSeries}
```

[`Series`](Series.md) 抽象与全部图表类型：折线、散点、阶梯、柱状、面积、直方图、箱线、小提琴、误差棒、热力图、等高线，以及描述统计函数。每种图表都是 `Series` 的子类，加入 [`Axes`](../axes/Axes.md) 后由面板统一驱动：报告数据区间、经由 [`Projection`](../core/Projection.md) 绘制、贡献图例条目。多系列之间的关系（并排分组、堆叠）由 [`BarGroup`](BarGroup.md) 与 [`AreaStack`](AreaStack.md) 这样的构建器安排，而不是在单个系列上配置。饼图与雷达图不在此包——它们没有笛卡尔标度，是 [`plot.axes`](../axes/index.md) 中的独立面板类型。

## 类型

**类**

| 类型 | 说明 |
|---|---|
| [`Series`](Series.md) | [Axes](../axes/Axes.md) 中一条可绘制的数据层：报告自身占据的数据区间、经由投影绘制、贡献图例条目，并可选地响应命中测试。 |
| [`LineSeries`](LineSeries.md) | 经过一组 `(x, y)` 数据点的折线，可选带标记，也可选填充到基线。 |
| [`ScatterSeries`](ScatterSeries.md) | 位于 `(x, y)` 的散点，可再把额外维度映射到标记大小与颜色。 |
| [`StepSeries`](StepSeries.md) | 分段常值的折线，忠实呈现在采样点之间保持数值而非滑动过渡的量：计数器、离散状态、区间内固定的速率。 |
| [`StemSeries`](StemSeries.md) | 从基线竖直伸到每个数据点、顶端带标记的茎干图——折线的离散信号对应物：样本本身是数据，样本之间的空隙不是。 |
| [`BarSeries`](BarSeries.md) | 在整数类别位置绘制条形的系列，条宽跟随类别轴的类别带而非以像素估计。 |
| [`BarGroup`](BarGroup.md) | 把共享一条类别轴的多个条形系列安排成并排分组或堆叠布局的工具。 |
| [`AreaSeries`](AreaSeries.md) | 系列与基线之间、或两条边界之间的填充区域。 |
| [`AreaStack`](AreaStack.md) | 把多条 [AreaSeries](AreaSeries.md) 堆叠为逐层累计面积图的构建器：每层坐在其下所有层的累计总和之上。 |
| [`HistogramSeries`](HistogramSeries.md) | 把一份样本按等宽分箱统计并绘制的直方图系列。 |
| [`BoxPlotSeries`](BoxPlotSeries.md) | 位于整数类别位置的 Tukey 箱线图系列，每组一个箱。 |
| [`ViolinSeries`](ViolinSeries.md) | 小提琴图系列：每组样本的核密度估计沿类别位置左右镜像成对称轮廓。 |
| [`ErrorBarSeries`](ErrorBarSeries.md) | 在 y、x 或两个方向上带误差棒的数据点。 |
| [`HeatmapSeries`](HeatmapSeries.md) | 规则网格上的二维标量场，经色标映射为色块矩阵。 |
| [`ContourSeries`](ContourSeries.md) | 用行进方格（marching squares）在二维标量场上追踪等值线的系列。 |
| [`Stats`](Stats.md) | 分布类图表使用的描述统计工具集。 |

**结构体**

| 类型 | 说明 |
|---|---|
| [`LegendEntry`](LegendEntry.md) | 图例中的一个条目：由产生它的系列绘制的色块，加上标签与代表色。 |
| [`HitResult`](HitResult.md) | 命中测试识别出的光标下数据点，用于构建工具提示与悬停读数。 |
| [`BoxStats`](BoxStats.md) | 箱线图绘制所需的五数概括与离群点。 |

**枚举**

| 类型 | 说明 |
|---|---|
| [`StepWhere`](StepWhere.md) | 阶梯系列在相邻两个采样点之间改变水平值的位置。 |
| [`BarOrientation`](BarOrientation.md) | 条形系列的生长方向：垂直（类别沿 x 轴）或水平（类别沿 y 轴）。 |
| [`HistogramNorm`](HistogramNorm.md) | 直方图条高的统计含义：原始计数、总和为 1 的频率，或积分为 1 的密度。 |

## 函数

| 函数 | 说明 |
|---|---|
| [`requireSameLength`](functions.md#requiresamelength) | 校验成对的坐标数组长度一致，不一致时抛出异常。 |
| [`pairedBounds`](functions.md#pairedbounds) | 返回成对坐标中有限数据点的 x、y 区间；一个有限点都没有时为 `None`。 |
| [`plottableRuns`](functions.md#plottableruns) | 把成对坐标拆分成若干段连续可绘制的像素点。 |
