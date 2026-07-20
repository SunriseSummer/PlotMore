# Figure、面板与系列

## 先用一句话说明

Figure 管整体布局，面板管坐标和局部显示，Series 把一组数据画进面板。

这三个层次对应三个不同问题：整张图要放几块内容；某一块内容用什么坐标、标题和图例；一组数据具体画成折线、柱形还是散点。先分清职责，后续增加面板、替换图表或切换输出方式时就不用重写整个程序。

## 为什么重要

初学者常把“图”当成一个不可拆的对象，于是设置标题、范围、数据和窗口都挤在 `main` 中。程序稍大就会出现两个麻烦：一是同一份图不能同时用于窗口和导出；二是改一个面板时容易误改整张图。Plot 的结构允许你先构建纯 Figure，再交给 `PlotWindow` 或 `FigureExport`。面板还不只 `Axes`：饼图和雷达图也实现 Panel，它们没有普通的 x/y 坐标，却仍能参加 Figure 网格布局。

## 工作模型

可以把对象关系看成一棵树。Figure 保存标题、主题、网格和有序面板；普通 Axes 保存 x/y 标度、坐标标签、图例、标注与一组 Series；每个 Series 保存数据和该图形自己的样式。绘制时 Figure 给每个面板分配矩形，面板再把数据通过标度映射到像素。窗口负责事件和显示，不拥有数据语义。

下面对比“一个面板叠加两组数据”和“两个面板分别显示”。前者适合共享单位并需要直接比较的系列；后者适合单位、范围或问题不同的内容。

```cangjie role=contrast
let (figure, axes) = Figure.single(title: "共享坐标")
axes.add(LineSeries(xs, actual, label: "实际"))
axes.add(LineSeries(xs, target, label: "目标"))
```

```cangjie role=trace
let figure = Figure("独立面板")
figure.setGrid(1, 2)
let traffic = figure.addAxes()
traffic.add(LineSeries(hours, requests, label: "请求量"))
let latency = figure.addAxes()
latency.add(LineSeries(hours, milliseconds, label: "延迟"))
```

## 选择与取舍

当系列共享相同的横轴含义和相近的纵轴单位时，放在一个 Axes 中可直接比较；如果单位不同，强行叠加会让一组曲线被压扁，也会让读者误以为共用刻度。此时应拆成面板。面板太多也会稀释重点：先按问题分组，再决定网格，不要为了展示 API 而堆满图形。

构建函数返回 Figure 是推荐边界。它能接收业务数据并完成标题、面板和系列设置，但不应在内部打开窗口。窗口配置属于交付方式，文件名和图片尺寸也属于调用端。这样同一构建器可被 GUI、命令行报告和测试使用。

## 应用这个模型

阅读一段 Plot 代码时，先圈出 Figure 的创建和 `setGrid`，再按 `addAxes`/`addPanel` 顺序列出面板，最后看每个面板收到哪些系列。排查空图时也按相反顺序检查：Figure 是否有面板，面板是否收到系列，系列是否有有效数据。为已有图增加第二条曲线，只改系列层；为报告增加一个独立指标，才改面板和网格层；要在桌面与 PNG 间切换，只改 Figure 之后的交付层。

该模型是后续[问题与视觉编码](chart-question-and-encoding.md)的前提：先知道对象放在哪里，才谈选择哪种系列。完整构建可回到[第一张折线图](../getting-started/first-chart.md)逐行对应。

## 常见误解

“Axes 就是整张图”不准确，一张 Figure 可以有多个 Axes，也可以混入 PieAxes 或 RadarAxes。“Series 自己决定坐标范围”也只对了一半：系列报告数据范围，Axes 合并可见系列后再决定有效范围。“窗口关闭会删除 Figure”同样不是设计模型；窗口只是使用 Figure 的一种方式。最后，`add` 返回值不代表复制了系列，通常仍是同一个对象，因此应在加入前后有意识地完成样式设置。

## 相关 API

- [`Figure`](../../api/plot/Figure.md)：整图、网格和面板集合。
- [`Axes`](../../api/plot/axes/Axes.md)：普通二维坐标面板。
- [`Series`](../../api/plot/series/Series.md)：所有普通数据系列的共同接口。

## 下一步

阅读[问题与视觉编码](chart-question-and-encoding.md)，把“数据画在哪里”推进到“数据应该怎样表达”。
