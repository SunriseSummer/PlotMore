# plot 示例画廊

28 个可运行示例，覆盖库中的每一种图表类型与全部交互组件。

## 运行

```shell
cjpm run                          # 列出全部示例
cjpm run --run-args="bubble"      # 查看气泡图示例
cjpm run --run-args="interactive"           # 手工装配交互组件的完整演示
```

每个窗口都带完整工具栏、悬停读数与光标状态条，因此任意示例都可以直接缩放、平移、保存。

## 画廊

| | | |
|---|---|---|
| **line** · 折线：标记、虚线、渐变填充<br>![line](gallery/line.png) | **line-styles** · 全部线型、标记与平滑<br>![line-styles](gallery/line-styles.png) | **scatter** · 散点 + 最小二乘趋势线<br>![scatter](gallery/scatter.png) |
| **bubble** · 气泡图：尺寸/颜色双映射<br>![bubble](gallery/bubble.png) | **bar** · 竖直柱状图，带数值标签<br>![bar](gallery/bar.png) | **bar-grouped** · 分组柱状图<br>![bar-grouped](gallery/bar-grouped.png) |
| **bar-stacked** · 堆叠柱状图，含负值<br>![bar-stacked](gallery/bar-stacked.png) | **bar-horizontal** · 水平柱状图<br>![bar-horizontal](gallery/bar-horizontal.png) | **area** · 面积图，向基线渐变淡出<br>![area](gallery/area.png) |
| **area-stacked** · 堆叠面积图<br>![area-stacked](gallery/area-stacked.png) | **band** · 均值曲线 + 置信区间带<br>![band](gallery/band.png) | **histogram** · 直方图 + 核密度叠加<br>![histogram](gallery/histogram.png) |
| **boxplot** · 箱线图对比分布<br>![boxplot](gallery/boxplot.png) | **violin** · 小提琴图（含双峰样本）<br>![violin](gallery/violin.png) | **errorbar** · 非对称误差棒<br>![errorbar](gallery/errorbar.png) |
| **step** · 阶梯图与火柴杆图<br>![step](gallery/step.png) | **pie** · 饼图<br>![pie](gallery/pie.png) | **donut** · 环形图，中心显示总量<br>![donut](gallery/donut.png) |
| **heatmap** · 热力图 + 颜色条<br>![heatmap](gallery/heatmap.png) | **matrix** · 带数值的相关系数矩阵<br>![matrix](gallery/matrix.png) | **contour** · 等高线（marching squares）<br>![contour](gallery/contour.png) |
| **radar** · 雷达图<br>![radar](gallery/radar.png) | **log** · 对数轴，跨六个数量级<br>![log](gallery/log.png) | **annotations** · 参考线、区间带与标注<br>![annotations](gallery/annotations.png) |
| **subplots** · 2x2 面板网格<br>![subplots](gallery/subplots.png) | **mixed** · 多种图表共用一个面板<br>![mixed](gallery/mixed.png) | **themes** · 内置调色板对比<br>![themes](gallery/themes.png) |
| **dashboard** · 深色主题综合报表页<br>![dashboard](gallery/dashboard.png) | | |

## 源码结构

| 文件 | 内容 |
|---|---|
| `registry.cj` | 示例注册表：每个示例是一个 `() -> Figure` |
| `data.cj` | 共享的确定性样本数据生成器（全部带固定种子） |
| `line.cj`、`scatter.cj`、`bar.cj`、`area.cj` | 基础图表 |
| `distribution.cj` | 直方图、箱线图、小提琴图 |
| `pie.cj` | 饼图、环形图、雷达图 |
| `field.cj` | 热力图、矩阵、等高线 |
| `composite.cj` | 对数轴、标注、子图、混合、主题、综合报表 |
| `interactive.cj` | 手工装配交互组件，含自定义按钮 |
| `main.cj` | 命令行入口 |

每个示例都是纯 `() -> Figure`。这正是画廊既能在窗口中*展示*、又能从同一份定义*导出*文件的原因，
也是读者应当照抄的形态：构建图表从不需要窗口。

数据生成器全部使用固定种子。每次运行画面都不同的示例，作为视觉参考毫无价值——而画廊恰恰是读者
拿所见与代码所写相互对照的地方。
