# 样式、可读性与输出

## 先用一句话说明

颜色、图例、标注和尺寸共同决定读者能否正确理解并复核一张图。

样式不是最后随手“美化”的步骤。主题提供一致默认值，调色板区分类别，连续色图解释数值，图例说明系列，标注补充业务上下文，输出尺寸决定文字和细节是否仍能读清。每一项都服务于信息，而不是为了增加装饰。

## 为什么重要

屏幕上看起来清楚的图缩进报告后可能文字过小；依赖红绿区分的两条线对部分读者不可辨；把图例压在数据密集区会遮住关键点；只画阈值线却不设置范围，阈值可能根本不在画面中。Plot 提供 Theme、Palette、Legend、Annotation 和 FigureExport，但应用仍需根据交付介质做取舍。

![Plot 官方画廊中的主题与调色板对照；用于核对主题是一组整体默认值](../../../examples/gallery/themes.png)

## 工作模型

Figure 持有 Theme，面板和系列在绘制时读取主题默认颜色、字体和间距。系列可以覆盖颜色、线型、标记和透明度。Legend 从可见系列生成条目，并可放在面板内或外侧。Annotation 使用数据坐标，因此缩放和平移时会跟随数据位置；它通常不参与自动范围。FigureExport 按给定逻辑宽高绘制整张 Figure，窗口工具栏不会进入图片。

```cangjie role=contrast
figure.theme = Theme.publication()
axes.legend.position = LegendPosition.OutsideRight
series.setColor(Palette.colorblindSafe().at(0))
```

```cangjie role=trace
let threshold = HorizontalLine(150.0)
threshold.label = "SLO 150 ms"
axes.annotate(threshold)
axes.setYLimits(Bounds(0.0, 220.0))
FigureExport.renderToPng(figure, "report.png", width: 1200, height: 800)
```

## 选择与取舍

主题应在逐个系列设置前确定，否则局部颜色可能与背景失去对比。类别系列优先使用色盲友好调色板，并同时用线型、标记或直接标签提供第二种识别线索。图例条目少且不遮挡数据时可放面板内；条目多或数据铺满面板时放外侧，但要给整体图片足够宽度。标注只保留影响解释的阈值、事件和区间，过多说明会把图变成文字墙。

输出尺寸要按最终载体确定。网页宽栏、窄栏和打印页的有效尺寸不同。与其导出巨大图片后任意缩小，不如用目标宽高导出并实际打开检查标题、轴标签、图例和细线。连续颜色必须带 ColorBar；只有类别颜色才使用普通图例。

## 应用这个模型

先在灰度或低饱和环境中检查系列是否仍可区分，再模拟最终显示宽度。把最重要的系列放在视觉优先位置，次要参考线用较细或虚线。标注阈值后核对它确实在有效范围内。导出文件后检查文件存在、像素尺寸正确、四周没有裁切、透明度和背景满足交付要求。可把 Figure 构建器视为唯一事实来源，窗口和导出都调用它。

本概念依赖[Figure、面板与系列](figure-axes-series.md)。具体标注步骤见[添加上下文](../how-to/add-context.md)，交付文件见[导出图片](../how-to/export-image.md)。

## 常见误解

使用深色主题不自动意味着对比度合格，仍需检查文字与系列颜色。图例也不会解释连续渐变，ColorBar 才负责数值颜色。标注不会可靠地扩大自动范围；远离数据的阈值应配合显式范围。导出宽高是整张 Figure 的逻辑尺寸，不是每个面板的尺寸。最后，窗口中的工具按钮属于交互界面，导出图片只包含 Figure 内容，这是有意的交付边界。

## 相关 API

- [`Theme`](../../api/plot/core/Theme.md)：提供整图一致的颜色、字体和间距默认值。
- [`Legend`](../../api/plot/axes/Legend.md)：放置并绘制系列图例。
- [`FigureExport`](../../api/plot/FigureExport.md)：将同一个 Figure 渲染为文件。

## 下一步

先用[添加上下文](../how-to/add-context.md)补充阈值和事件，再用[导出图片](../how-to/export-image.md)形成可复核的交付文件。
