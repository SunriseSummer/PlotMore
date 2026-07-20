# 启用窗口交互

## 目标

在首图窗口中加入标准工具栏、悬停数据读数和光标坐标，并理解缩放、平移、复位与轴锁定各自改变什么。补丁完成后，读者可在不修改系列数组的前提下检查局部数据。

## 适用场景

适用于桌面探索、演示和人工检查。批处理报告或服务器任务应直接导出，不应进入窗口事件循环。先完成[第一张折线图](../getting-started/first-chart.md)，并阅读[交互与视图状态](../concepts/interaction-and-view-state.md)理解基础范围与临时视图的区别。

## 准备工作

确认静态首图已经正确显示；不要用交互组件掩盖数据或坐标问题。标准工具栏覆盖常见保存、缩放、平移、框选、复位、网格、图例和主题操作，优先使用它，再考虑自定义按钮。

## 操作步骤

在首图 `main` 中，用下面代码替换创建窗口到 `show()` 的部分。窗口标题与图表保持一致，不会再出现沿用旧示例标题的问题。三个组件分别承担工具操作、最近数据点读数和任意光标坐标。

```cangjie role=patch
let window = PlotWindow(
    figure,
    options: WindowOptions(title: "每周活跃用户（可交互）", width: 1040, height: 680)
)
window.addStandardToolbar()
window.enableHoverReadout()
window.addCursorStatus()
window.show()
```

时间序列常只需沿 x 方向导航。下面变化在 `show()` 之前锁定 y 视图，并设置导出按钮的默认文件名和尺寸。它改变导航约束与交付行为，而不只是改变外观。

```cangjie role=variation
window.interactions.lockY = true
window.exportWidth = 1400.0
window.exportHeight = 820.0
window.exportFileName = "weekly-users.png"
window.showStatus("纵轴已锁定：滚轮只缩放横轴")
```

## 确认结果

窗口右上应出现标准工具按钮，移动到折线点附近时出现与最近点对应的读数，状态区域随光标移动报告坐标。滚轮缩放或拖动后，数组没有变化；按复位按钮应回到初始范围。启用 `lockY` 后，纵轴上下界保持不变，横轴仍能缩放。关闭窗口，`show()` 返回，命令才结束。

## 常见错误

在无桌面显示环境运行会导致窗口初始化失败；把 `show` 当作立即返回函数，会让后续批处理迟迟不执行。HoverReadout 读取附近真实数据点，CursorStatus 读取任意光标位置，两者数值不同不代表错误。只添加 Toolbar 对象却没有 `window.addComponent`，或手工按钮忘记设置 action，也会得到看得见但不工作的界面。

## 相关 API

- [`PlotWindow`](../../api/plot/PlotWindow.md)：添加标准工具栏、读数和状态组件。
- [`Interactions`](../../api/plot/ui/Interactions.md)：控制导航模式、滚轮、拖动和轴锁定。

## 下一步

继续[样式、可读性与输出](../concepts/style-accessibility-and-output.md)，明确窗口界面与最终图片内容的边界。
