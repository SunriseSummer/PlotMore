# 按问题选择图表

## 目标

在动手调用 API 前，把“我要画什么”改写成读者真正要回答的问题，并选择最直接的 Plot 系列或面板。完成本页后，你应能为趋势、类别比较、关系、分布、构成和二维场各选出首选图形，也知道何时应拆成多个面板。

## 适用场景

适用于已有数据、但还没有确定图表类型的阶段。若只是要修改已选图形的范围，请读[配置坐标轴](configure-axes.md)；若要理解选择原则，先读[问题与视觉编码](../concepts/chart-question-and-encoding.md)。本页的补丁建立在[第一张折线图](../getting-started/first-chart.md)上。

## 准备工作

写下四项：每个观测代表什么、主要比较是什么、变量是连续还是类别、读者需要大致模式还是精确值。然后用这张简表：随顺序变化选折线或阶梯；类别大小选柱形；两个连续变量关系选散点；样本形状选直方图/箱线图/小提琴图；连续区间选面积带；二维网格选热图/等高线；少量整体构成才选饼图；已归一化的多指标轮廓才选雷达图。

## 操作步骤

下面把首图从“连续周次趋势”改成“四个无序渠道的转化率比较”。这是对首图 `main` 中构图部分的精确替换；同时补上 `CategoryScale` 和 `BarSeries` 导入。类别没有连续插值含义，所以不再用折线。

```cangjie role=patch
import plot.core.CategoryScale
import plot.series.BarSeries

let (figure, axes) = Figure.single(title: "渠道转化率")
axes.xLabel = "渠道"
axes.yLabel = "转化率 (%)"
axes.setXScale(CategoryScale(["搜索", "推荐", "直接", "活动"]))
axes.showGridX = false
let bars = BarSeries([4.8, 6.2, 5.1, 7.4], label: "转化率")
bars.showValues = true
bars.valueDecimals = Some(1)
axes.add(bars)
let window = PlotWindow(figure, options: WindowOptions(title: "渠道转化率", width: 960, height: 640))
window.show()
```

如果问题变成“延迟是否随负载上升”，观测单位是服务实例，两个变量都连续，应换成散点而不是柱形。下面是不同问题的变化，不是同一补丁换颜色。

```cangjie role=variation
import plot.series.ScatterSeries

let (figure, axes) = Figure.single(title: "负载与延迟")
axes.xLabel = "负载 (%)"
axes.yLabel = "p95 延迟 (ms)"
let points = ScatterSeries(
    [22.0, 35.0, 48.0, 64.0, 79.0, 91.0],
    [48.0, 55.0, 67.0, 83.0, 118.0, 176.0],
    label: "服务实例"
)
axes.add(points)
```

## 确认结果

运行柱形补丁后，应看到四个类别名称和四根从共同基线出发的柱，不能出现连接类别的折线。转化率最大的是“活动”，读者无需查数组即可判断。换成散点变化后，应看到点云从左下向右上延伸，横轴不再显示类别名称。若图形虽能运行却无法直接回答你写下的问题，就回到准备工作重新选择，而不是继续添加样式掩盖问题。

## 常见错误

无序类别用折线会暗示中间过程；相近占比用饼图会让角度难比较；不同单位直接做雷达图会让轮廓受量纲支配；直方图和柱形图外观相似，但前者对连续样本分箱，后者比较明确类别。另一个常见错误是把“图要好看”当作问题，导致颜色和形状不断增加，却没有一句可验证结论。

## 相关 API

- [系列总览](../../api/plot/series/index.md)：折线、柱形、散点、分布和场数据系列。
- [面板总览](../../api/plot/axes/index.md)：普通、饼图和雷达图面板。

## 下一步

把选择应用到一张综合结果中，继续[构建可复用的交互仪表板](../tutorials/advanced-dashboard.md)。
