# 非笛卡尔面板

## 先用一句话说明

饼图和雷达图使用角度或半径表达关系，因此它们是独立面板而不是普通坐标系中的数据系列。

Plot 通过共同的 Panel 接口让 PieAxes、RadarAxes 和普通 Axes 都能加入 Figure。共同之处是占据版面、绘制标题或图例；不同之处是它们没有普通 x/y 标度，数据的可比条件也更严格。

## 为什么重要

把饼图当作任何分类比较的默认选项，会使相近切片难以区分；把不同单位的指标直接放入雷达图，会让多边形形状主要反映单位量级。非笛卡尔图并非“更高级”的装饰，而是为特定问题服务：饼图回答少量部分如何组成整体，雷达图比较已经归一到共同范围的多指标轮廓。

## 工作模型

PieAxes 接收多个 PieSlice，按非负数值计算各自占总和的角度。标签可显示名称或百分比，图例帮助识别颜色，甜甜圈中心可放总量。RadarAxes 先定义辐条名称和共同值域，再接收一个或多个 RadarTrace；每个 trace 的数值数量必须与辐条数量一致。Figure 只负责把这些 Panel 放入网格，不替它们建立 x/y 坐标。

```cangjie role=contrast
let pie = PieAxes([
    PieSlice(62.0, label: "订阅"),
    PieSlice(25.0, label: "服务"),
    PieSlice(13.0, label: "其他")
])
pie.labelMode = PieLabelMode.Percent
figure.addPanel(pie)
```

```cangjie role=trace
let radar = RadarAxes(["准确率", "速度", "内存", "稳定性"])
radar.valueRange = Some(Bounds(0.0, 1.0))
radar.add(RadarTrace([0.86, 0.72, 0.65, 0.91], label: "方案 A"))
radar.add(RadarTrace([0.78, 0.90, 0.82, 0.70], label: "方案 B"))
figure.addPanel(radar)
```

## 选择与取舍

饼图只在切片少、总和确实代表一个整体且读者关心大致占比时使用。若问题是“谁比谁大多少”，柱形提供共同基线，会更准确。切片过多时可合并真正次要的类别，但应在正文说明合并规则，不要隐藏关键项。甜甜圈中心适合放可直接核对的总量，不能把与切片无关的宣传语当数据。

雷达图的辐条顺序会改变轮廓，因此要采用稳定且有解释的顺序。所有指标应先转换为同向、同范围的得分；例如“成本越低越好”若直接和“准确率越高越好”并列，会让外侧含义不一致。方案太多时多边形会互相遮挡，应减少 trace、拆面板或改成分组柱形。

## 应用这个模型

做饼图前，检查每个值非负且总和有明确含义，列出切片数，决定标签与图例是否重复。做雷达图前，保留一张归一化说明表，写明每个指标的原始单位、方向和转换公式；图中使用转换后的 0 到 1 得分。把 PieAxes 或 RadarAxes 加到 Figure 后，不要再尝试调用普通 Axes 的 `setXScale`。

本概念依赖[Figure、面板与系列](figure-axes-series.md)和[问题与视觉编码](chart-question-and-encoding.md)。完整并排示例见[构建饼图和雷达图](../how-to/build-pie-and-radar.md)。

## 常见误解

PieAxes 名字中含 Axes，不代表它拥有普通直角坐标轴。饼图百分比来自切片总和，不应在外部先四舍五入成合计不等于 100 的数再作为输入。雷达图面积没有天然业务单位，不宜用多边形面积给方案打总分。另一个误区是认为切片“炸开”会提高准确性；它只适合强调极少量已说明的重点，过多炸开会破坏整体结构。

## 相关 API

- [`PieAxes`](../../api/plot/axes/PieAxes.md)：显示整体构成、标签、图例和甜甜圈中心。
- [`RadarAxes`](../../api/plot/axes/RadarAxes.md)：在共同径向范围上比较多指标轨迹。

## 下一步

完成[构建饼图和雷达图](../how-to/build-pie-and-radar.md)，并用同一份数据说明为什么不选择普通柱形。
