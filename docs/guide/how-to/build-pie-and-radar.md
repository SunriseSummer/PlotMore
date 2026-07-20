# 构建饼图和雷达图

## 目标

在一个 1×2 Figure 中并排放置饼图与雷达图：饼图说明三个收入来源如何构成整体，雷达图比较两个已经归一化的方案轮廓。最终程序导出 PNG，并展示非笛卡尔面板如何参加普通 Figure 网格。

![饼图画廊结果](../../../examples/gallery/pie.png)

![雷达图画廊结果](../../../examples/gallery/radar.png)

两图来自 `examples/src/pie.cj`，SHA-256 分别为 `97057c68e1fa3d258484c4e24768527d28f3a897438f1f4711ef0d1593e9a916` 和 `c4cc2c63514b24d8dad399f5fb30a4b47d5f5bec22ed03a12052ebccb708e8af`。

## 适用场景

饼图只用于少量非负部分构成同一整体；雷达图只用于方向一致、已缩放到共同范围的多个指标。若要精确比较类别，优先柱形；若指标仍保留不同单位，优先分面或表格。

## 准备工作

确认饼图切片值非负、总和有明确业务意义。确认雷达图每条轨迹的值数与辐条名数一致，所有值都在 0 到 1，且“越外越好”的方向统一。下面数据已经完成这些准备。

## 操作步骤

Figure 先设置 1×2 网格，再用 `addPanel` 依次加入 PieAxes 和 RadarAxes。不要调用 `addAxes` 后把饼图当作 Series 添加；它们本身就是 Panel。

```cangjie verify role=complete
package guide_examples

import plot.{Figure, FigureExport}
import plot.axes.{PieAxes, PieLabelMode, PieSlice, RadarAxes, RadarTrace}
import plot.core.Bounds

main(): Unit {
    let figure = Figure("构成与多指标轮廓")
    figure.setGrid(1, 2)

    let pie = PieAxes(
        [
            PieSlice(62.0, label: "订阅"),
            PieSlice(25.0, label: "专业服务"),
            PieSlice(13.0, label: "其他")
        ]
    )
    pie.labelMode = PieLabelMode.NameAndPercent
    pie.percentDecimals = 1
    figure.addPanel(pie)

    let radar = RadarAxes(["准确率", "速度", "内存", "稳定性", "成本"])
    radar.valueRange = Some(Bounds(0.0, 1.0))
    radar.rings = 5
    radar.add(RadarTrace([0.88, 0.62, 0.74, 0.91, 0.58], label: "方案 A"))
    radar.add(RadarTrace([0.79, 0.89, 0.83, 0.72, 0.81], label: "方案 B"))
    figure.addPanel(radar)

    FigureExport.renderToPng(figure, "pie-radar.png", width: 1200, height: 620)
    println("已写入 pie-radar.png") // 输出: 已写入 pie-radar.png
}
```

如果中心需要显示绝对总量，可把饼图改成甜甜圈。下面变化关闭切片标签、保留图例，并把总收入放在中心；它改变了信息层次而非只改颜色。

```cangjie role=variation
pie.innerRadius = 0.58
pie.labelMode = PieLabelMode.NoLabel
pie.donutLabel = "8,420 万元"
pie.donutSublabel = "年度总收入"
```

## 确认结果

程序应打印文件名并生成可打开 PNG。左侧三个切片合计为 100，订阅最大，标签包含名称和百分比；右侧恰有五根辐条和两条轨迹，所有顶点位于 0 到 1 范围。方案 A 在准确率和稳定性更外，方案 B 在速度、内存和成本得分更外。若结论依赖辐条顺序，应改用表格或柱形复核。

## 常见错误

切片包含负数、把彼此无关的金额凑成“整体”、切片过多、在雷达图直接混用毫秒和百分比，都会使图失真。雷达轨迹值数量不等于辐条数量会失败。不要把多边形面积当作自动总分，也不要通过任意改变辐条顺序让某方案看起来更大。

## 扩展到第三个方案而不改变比较口径

新增雷达轨迹时，先把新方案按现有五个指标的顺序归一化，再调用一次 `radar.add`；不要同时调整 `valueRange` 或辐条顺序，否则旧方案的视觉基准也会变化。新增业务来源时同样先确认它属于原来的总收入，再加入一个 `PieSlice` 并重新核对总和。扩展后的可见检查是：饼图仍只表达同一整体，雷达图仍为五根辐条、三条轨迹，且原来 A/B 的相对结论没有因改口径而被悄悄改写。

## 相关 API

- [`PieAxes`](../../api/plot/axes/PieAxes.md)：显示部分与整体，并支持甜甜圈中心。
- [`RadarAxes`](../../api/plot/axes/RadarAxes.md)：在共同径向范围中显示多个指标轨迹。

## 下一步

继续[样式、可读性与输出](../concepts/style-accessibility-and-output.md)，为最终交付检查颜色、图例、标注和尺寸。
