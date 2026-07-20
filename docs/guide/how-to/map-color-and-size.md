# 用颜色和大小编码散点属性

## 目标

在 x/y 位置之外，用颜色表示负载、用点面积表示请求量，并添加匹配的 ColorBar。最终导出一张可解释的气泡散点图，而不是一团只有作者知道颜色含义的点。

## 适用场景

适用于每个观测有至少四个数值变量，并且主要关系仍是 x 对 y 的场景。例如服务实例的延迟、错误率、负载和请求量。若只需两个变量，普通 ScatterSeries 更清楚；若颜色表示类别，应使用离散颜色和图例，而不是连续色标。

## 准备工作

四个数组必须描述同一批观测，长度完全一致。先确定颜色变量的最小最大值和单位，再选择连续 Colormap。点大小表示面积时，最小和最大显示尺寸不宜差得过分，否则小点会消失、大点会遮挡邻居。

## 操作步骤

程序使用固定数据，便于核对。`colorBy` 绑定负载和 viridis 色图，`sizeBy` 绑定请求量，ColorBar 使用同一值域与色图。透明度降低到 0.82，使重叠点仍可识别。

```cangjie verify role=complete
package guide_examples

import plot.{Figure, FigureExport}
import plot.axes.ColorBar
import plot.core.{Bounds, Colormap}
import plot.series.ScatterSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "服务实例：延迟、错误率与负载")
    axes.xLabel = "p95 延迟 (ms)"
    axes.yLabel = "错误率 (%)"
    let latency = [72.0, 84.0, 93.0, 108.0, 126.0, 148.0, 171.0]
    let errors = [0.3, 0.4, 0.6, 0.8, 1.1, 1.7, 2.4]
    let load = [31.0, 42.0, 49.0, 58.0, 67.0, 79.0, 91.0]
    let requests = [12.0, 20.0, 18.0, 33.0, 45.0, 58.0, 70.0]

    let points = ScatterSeries(latency, errors, label: "实例")
    points.colorBy(load, Colormap.viridis())
    points.sizeBy(requests, minSize: 4.0, maxSize: 14.0)
    points.opacity = 0.82
    axes.add(points)

    let bar = ColorBar(Bounds(31.0, 91.0), Colormap.viridis())
    bar.label = "负载 %"
    axes.setColorBar(bar)
    FigureExport.renderToPng(figure, "service-scatter.png", width: 1000, height: 700)
    println("已写入 service-scatter.png") // 输出: 已写入 service-scatter.png
}
```

若第四个变量不可靠，宁可退回普通散点并加参考线。下面变化移除颜色和大小编码，只突出一个业务阈值，使图回答“哪些实例超过错误率上限”。

```cangjie role=variation
let points = ScatterSeries(latency, errors, label: "实例")
points.size = Some(6.0)
axes.add(points)
let limit = HorizontalLine(1.0)
limit.label = "错误率上限 1%"
axes.annotate(limit)
```

## 确认结果

运行后终端打印文件名，并生成可打开的 PNG。点应从左下向右上分布，颜色由深到亮随负载变化，右侧色标明确标为“负载 %”，点面积也有可见差异。检查最小点仍可见，最大点没有遮住全部邻点。ColorBar 的两端必须覆盖传入的 31 到 91。

## 常见错误

颜色数组或大小数组长度与 x/y 不同会使观测错位或构造失败。使用连续色图表达无序类别会暗示不存在的高低关系。只设置 `colorBy` 不加 ColorBar，读者无法把颜色还原为数值。把半径当面积理解会夸大大值；应以实际图面效果检查 `minSize` 和 `maxSize`。

## 相关 API

- [`ScatterSeries`](../../api/plot/series/ScatterSeries.md)：绘制点，并按数组映射颜色和大小。
- [`ColorBar`](../../api/plot/axes/ColorBar.md)：说明连续颜色的数值范围与单位。

## 下一步

把这些编码组合进[可复用交互仪表板](../tutorials/advanced-dashboard.md)，并用悬停读数核对单个点。
