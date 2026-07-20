# 交互与视图状态

## 先用一句话说明

数据范围来自数据，视图范围来自用户操作；复位视图就是回到数据决定的范围。

缩放和平移改变“当前看哪里”，并不改写 Series 中的数组。HoverReadout、CursorStatus 和命中测试读取当前投影下的像素与数据坐标；PlotWindow 负责把这些输入事件分派到正确面板。

## 为什么重要

交互图常见的误判是：缩放后数据似乎消失，就认为数组被过滤；窗口一直运行，就认为程序卡死；悬停读数和光标坐标不同，就认为其中一个错误。理解视图状态和事件循环后，才知道何时复位、何时锁定某个轴，以及如何在多个面板中定位事件。

## 工作模型

Axes 先根据系列、标度和显式限制算出基础范围。Interactions 在拖动或滚轮事件到来时计算新的 x/y 视图，并调用 Axes 设置临时 view。绘制时投影使用这个有效视图。`resetAllViews` 让所有普通面板清除临时 view。HoverReadout 会在半径内寻找最近数据点并显示系列值；CursorStatus 报告光标映射回的数据位置，二者本来就回答不同问题。

```cangjie role=contrast
let window = PlotWindow(figure)
window.addStandardToolbar()
window.enableHoverReadout()
window.addCursorStatus()
window.show()
```

```cangjie role=trace
window.interactions.lockY = true
window.interactions.wheelZoom = true
window.interactions.dragPan = true
// 复位按钮最终调用 window.resetAllViews()
```

## 选择与取舍

静态报告不需要交互组件，直接导出更稳定。探索型桌面工具可先用标准工具栏，它已经提供保存、缩放、平移、框选、复位、网格、图例和主题入口。只有业务确有特殊模式时再手工组装 Toolbar 和 ToolButton。锁定 y 轴适合横向时间导航，但会阻止用户查看 y 方向细节，应给出明确状态提示。

悬停适合精确读取单点，数据极密时命中半径和系列顺序会影响体验；光标状态适合读任意坐标，不保证落在真实样本上。多个面板的交互状态彼此独立通常最安全，除非应用自己定义同步范围逻辑。PieAxes 和 RadarAxes 不具有与普通 Axes 相同的平移缩放语义。

## 应用这个模型

先让静态 Figure 正确显示，再添加工具栏；否则很难区分数据问题和交互问题。逐项验证：滚轮改变当前面板范围，拖动移动范围，框选只放大框内区域，Home 复位，悬停靠近点时显示读数，状态栏随鼠标变化。关闭窗口后 `show` 才返回，这是窗口事件循环的预期行为。若要批处理导出，不要调用 `show`。

本概念依赖[Figure、面板与系列](figure-axes-series.md)和[数据范围与标度](data-domain-and-scales.md)。实际增量修改见[启用窗口交互](../how-to/interactive-window.md)，完整仪表板则见[进阶教程](../tutorials/advanced-dashboard.md)。

## 常见误解

`lockY` 不是把 y 数据设为常量，只是让某些导航操作不改变 y 视图。HoverReadout 也不是光标位置格式化器，它会寻找附近数据点。窗口工具栏不会出现在 FigureExport 的图片里，因为它属于窗口界面而不是 Figure 内容。最后，调用 `show()` 后应由事件循环接管程序；在其后安排必须立即执行的批处理代码会等到窗口关闭才开始。

## 相关 API

- [`Interactions`](../../api/plot/ui/Interactions.md)：管理平移、缩放、框选和轴锁定状态。
- [`PlotWindow`](../../api/plot/PlotWindow.md)：分派事件、添加组件并运行窗口。
- [`Axes`](../../api/plot/axes/Axes.md)：保存基础范围与临时视图。

## 下一步

按[启用窗口交互](../how-to/interactive-window.md)把标准工具栏、悬停读数和光标状态加入首图。
