[plot 指南](../index.md) › 配置坐标

# 配置坐标范围、分类轴与对数轴

## 目标

根据数据含义选择自动线性范围、显式范围、分类标度或对数标度，并在运行前检查不被所选标度接受的数据。结果应是坐标距离与读者需要比较的关系一致，而不只是“所有点都显示出来”。

## 适用场景

用于多张图需要同尺度比较、柱状图必须表达零基线、类别名称应代替数值位置，或正值跨多个数量级的情况。先读[数据范围、标度与投影](../concepts/data-domain-and-scales.md)；本页把模型变成操作顺序。

## 准备工作

保留[第一张折线图](../getting-started/first-chart.md)的完整程序，本页片段都放在 `axes.add(...)` 之后、创建窗口之前。确认每个轴的单位、最小/最大有效值、是否允许零和负数，以及不同面板是否必须可比。清理 `NaN`、无限值和业务上无效的观测。自动范围只会处理系列报告的有效数据，不能替你判断业务缺失值。

## 操作步骤

### 1. 从自动线性范围开始

先绘制有效数据，让 `Axes` 合并系列范围。观察刻度是否足以回答问题。如果只是标题或单位缺失，补 `xLabel`/`yLabel`，不要过早固定数值。

### 2. 需要可比性时固定范围

多个面板比较同一指标时，为它们设置相同域。固定前检查所有数据，明确超出范围是裁剪、错误还是需要扩大；不要静默隐藏异常值。

这段补丁以[第一张折线图](../getting-started/first-chart.md)为基页：在导入区增加 `import plot.core.Bounds`，再把下列语句插入 `axes.add(...)` 之后、创建 `PlotWindow` 之前。

```cangjie role=patch
axes.setYLimits(Bounds(0.0, 30.0))
println("固定范围：${axes.effectiveYBounds()}")
```

先运行并确认窗口确实显示 0 到 30 的固定纵轴。以后需要重新交回数据自动范围时，再把这条 `setYLimits(...)` 替换为 `axes.autoscaleY()` 并重新运行；不要在创建窗口前连续执行两者，否则固定范围会在绘制前被撤销。

### 3. 类别使用分类标度

下面是同一基页的分类轴变化。先在导入区增加 `import plot.core.CategoryScale` 与 `import plot.series.BarSeries`，再用整个片段替换基页的 `axes.add(LineSeries(...))`；不要让原折线和新柱子混在同一类别面板。

```cangjie role=variation
axes.setXScale(CategoryScale(["基础版", "专业版", "企业版"]))
axes.xLabel = "套餐"
axes.yLabel = "客户数"
axes.add(BarSeries([128.0, 86.0, 34.0], label: "客户数"))
```

类别顺序和数值数组按位置对应。排序类别时必须同步排序数值，最好在绘图前形成一组结构化记录再拆分。

### 4. 只有正值才能使用对数轴

这个变化仍以第一张图为基页。在导入区增加 `import plot.core.{Bounds, LogScale}`，然后把下列语句插在原 `axes.add(...)` 之后、窗口创建之前；原示例的销量全部为正，因此可安全切换。

```cangjie role=variation
axes.setYScale(LogScale(Bounds(1.0, 1.0e6)))
axes.setYLimits(Bounds(1.0, 1.0e6))
```

`LogScale` 构造参数是标度的初始/回退定义域，并不会在有数据时自动固定可见范围；需要跨图保持 1 到 1e6 时，仍要调用 `setYLimits`。在设置前检查最小值大于零。零和负值不属于对数域；应明确选择过滤、单独标注或返回线性轴，而不是用极小正数偷偷替换。

## 确认结果

用四个检查验证：`effectiveYBounds()` 输出指定范围，窗口纵轴可见 0 到 30；刻度标签包含正确单位；同尺度面板中的同一数值位于相同相对高度；对数轴每个可见点都来自正值。另一次运行中将补丁替换为 `axes.autoscaleY()`，应回到数据范围。交互缩放的视图范围优先于固定 limits，`resetView()` 会回到固定范围；对分类轴逐项核对标签和数值顺序。

## 常见错误

- 为突出微小波动截断柱状图零点，却没有说明，夸大类别差异。
- 对数轴混入零或负值，折线出现间断后误判为渲染故障。
- 只更换类别标签，没有同步数据顺序。
- 固定范围后新增数据超界，却仍假设自动范围会扩展。
- 用轴标题代替系列标签，导致多条线仍无法区分。

## 相关 API

- [`Axes`](../../api/plot/axes/Axes.md) — x/y 标度、标签、网格和范围入口。
- [`LogScale`](../../api/plot/core/LogScale.md) — 正数域及对数换算。
- [`CategoryScale`](../../api/plot/core/CategoryScale.md) — 类别顺序和标签。
- [`Bounds`](../../api/plot/core/Bounds.md) — 显式数值域。

## 下一步

返回[多面板报告](../tutorials/analysis-report.md)为不同面板选择合适标度，或到[常见绘图问题](../troubleshooting/common-problems.md)排查空数据、对数断线和标注不可见。
