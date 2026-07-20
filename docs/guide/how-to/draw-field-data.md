# 绘制热图和等高线

## 目标

从同一个二维函数生成热图与等高线，并使用同一色图和色标解释数值。最终导出的图片左侧强调连续区域，右侧把等值线叠在半透明热图上，便于核对两种表现确实来自同一场。

![热图画廊结果](../../../examples/gallery/heatmap.png)

![等高线画廊结果](../../../examples/gallery/contour.png)

两图来自 `examples/src/field.cj`，SHA-256 分别为 `17452cd09ae18b008206ec51bee536f21e283dfd0d23148ec6d36a205ccf58c6` 和 `448a3867ec7d6e52469c3a1544dd906ad002e8cd271c030b25e32de1d70c2457`。

## 适用场景

适用于规则二维区域上每个位置都有数值的温度、地形、模拟或指标矩阵。只有散乱观测点时，应先采用有依据的插值或直接画散点，不能假装它们已经形成规则场。

## 准备工作

确定 x/y 空间范围、行列分辨率、值的单位与合理范围。下面使用简单的 `x*x - y*y`，无需外部数据。热图和等高线必须调用同一个函数并使用同一 Bounds，才能互相核对。

## 操作步骤

程序建立左右面板。左侧 HeatmapSeries 自动解析值域并创建 ColorBar；右侧先加半透明热图，再加 10 条等高线。`showGrid = false` 避免普通坐标网格干扰场结构。

```cangjie verify role=complete
package guide_examples

import plot.{Figure, FigureExport}
import plot.axes.ColorBar
import plot.core.{Bounds, Colormap}
import plot.series.{ContourSeries, HeatmapSeries}

func fieldValue(x: Float64, y: Float64): Float64 {
    x * x - y * y
}

main(): Unit {
    let xRange = Bounds(-3.0, 3.0)
    let yRange = Bounds(-3.0, 3.0)
    let figure = Figure("二维标量场")
    figure.setGrid(1, 2)

    let heatAxes = figure.addAxes()
    heatAxes.title = "连续填色"
    heatAxes.showGrid = false
    let heat = HeatmapSeries.fromFunction(60, 60, xRange, yRange) {x, y => fieldValue(x, y)}
    heat.map = Some(Colormap.coolWarm())
    heat.cellGap = 0.0
    heatAxes.add(heat)
    let bar = ColorBar(heat.resolvedValueRange(), Colormap.coolWarm())
    bar.label = "x² - y²"
    heatAxes.setColorBar(bar)

    let contourAxes = figure.addAxes()
    contourAxes.title = "填色 + 等高线"
    contourAxes.showGrid = false
    let background = HeatmapSeries.fromFunction(60, 60, xRange, yRange) {x, y => fieldValue(x, y)}
    background.map = Some(Colormap.coolWarm())
    background.opacity = 0.48
    contourAxes.add(background)
    let contour = ContourSeries.fromFunction(70, 70, xRange, yRange) {x, y => fieldValue(x, y)}
    contour.levelCount = 10
    contour.map = Some(Colormap.coolWarm())
    contourAxes.add(contour)

    FigureExport.renderToPng(figure, "field.png", width: 1200, height: 620)
    println("已写入 field.png") // 输出: 已写入 field.png
}
```

相关矩阵常以第 0 行在顶部表示。下面变化使用直接值数组、发散色图和对称值域，明确零为中性色；它不是改网格密度，而是改变数据组织与语义。

```cangjie role=variation
let matrix = HeatmapSeries([
    1.0, -0.4, 0.2,
    -0.4, 1.0, -0.7,
    0.2, -0.7, 1.0
], rows: 3, columns: 3)
matrix.originTop = true
matrix.valueRange = Some(Bounds(-1.0, 1.0))
matrix.map = Some(Colormap.coolWarm())
matrix.showValues = true
axes.add(matrix)
```

## 确认结果

程序打印文件名，PNG 可打开。左图应在 x 方向两侧为正、y 方向两侧为负，中心接近零；色标跨越负到正。右图的等值线应沿底图相同结构分布，不应出现颜色与线级别方向相反。调低背景透明度后，线仍清楚可见。

## 常见错误

行列数和扁平数组长度不一致、ColorBar 使用了另一套值域、热图和等高线调用不同函数、用顺序色图表达正负偏差，都会破坏解释。增加网格密度只提高采样分辨率，不会补回原始数据没有的精度。矩阵上下颠倒时，应核对 `originTop` 与类别顺序，而不是旋转导出图片。

## 相关 API

- [`HeatmapSeries`](../../api/plot/series/HeatmapSeries.md)：把规则网格值绘制为单元颜色。
- [`ContourSeries`](../../api/plot/series/ContourSeries.md)：在规则网格上追踪等值线。
- [`ColorBar`](../../api/plot/axes/ColorBar.md)：解释连续颜色与数值范围。

## 下一步

阅读[非笛卡尔面板](../concepts/non-cartesian-panels.md)，理解没有普通 x/y 标度的面板为何采用另一套数据约束。
