# Plot 使用指南

Plot 是一套仓颉绘图库：程序先构建 `Figure`，再把同一个结果显示在桌面窗口或导出为 PNG。本指南面向需要把业务数据变成可解释图表的应用开发者，不按源码包罗列类型，而是从“我要让读者看出什么”出发，逐步覆盖首个结果、图形选择、坐标、分布与不确定性、二维场、非笛卡尔面板、交互、复用构建器和最终交付。

## How to use this guide

第一次使用时按学习路径顺序阅读；已有项目时从“按任务查找”直接进入。教程提供完整学习过程，独立 how-to 提供可运行程序，继承型 how-to 明确指出基页和替换位置，概念页解释选择依据，排错页按可观察症状诊断。每个内容页至少给出两段职责不同的仓颉代码，完整程序的自动验证结果记录在[验证报告](_verification.md)。

需要构造参数、字段、默认值、异常或完整成员清单时，跳到独立的 [Plot API 参考](../api/index.md)。指南回答“何时用、怎样完成、怎样确认”，API 参考回答“精确签名是什么”。两套文档互相链接，但不会维护两份成员目录。

示例假设 `cjpm 1.0.5` 可用。可见窗口与 PNG 导出都需要正确的 SDL 运行环境；GUI 完整程序会编译，但自动流程不会替你打开并关闭窗口。无窗口导出程序会实际运行，并检查退出码、标准输出和生成行为。

## Start here

开始前需要能够运行 `cjpm --version`，并让示例项目通过本地依赖找到 Plot；打开窗口或实际导出还需要 SDL 原生运行库可用。你只需具备仓颉数组、导入和函数的基础知识，不需要预先理解 Plot 的包结构或全部图表类型。

先完成[打开第一张折线图](getting-started/first-chart.md)。该页从包声明、导入、数组、Figure、Series 一直写到 `PlotWindow.show()`，没有把 `main` 缩成“核心片段”。若环境已经配置好，十分钟内应看到带标题、坐标轴、圆点和图例的窗口；关闭窗口后命令正常返回。

首图成功后阅读[Figure、面板与系列](concepts/figure-axes-series.md)。这一步把刚才的代码整理成三个稳定职责：Figure 管整体布局，面板管局部坐标，Series 保存并绘制数据。理解它以后，再增加第二条线、第二个面板或饼图时就不会把所有逻辑重新塞进 `main`。

接着读[问题与视觉编码](concepts/chart-question-and-encoding.md)和[数据范围与标度](concepts/data-domain-and-scales.md)，先决定应该画什么，再决定值怎样进入坐标轴。随后完成[可复用交互仪表板](tutorials/advanced-dashboard.md)：它把构图代码提取为返回 Figure 的函数，同时加入四面板布局、连续色标、工具栏、悬停读数和光标状态。

如果首图在构建或运行阶段失败，不要跳过环境问题继续复制更多代码；直接进入[构建与窗口运行排错](troubleshooting/build-and-runtime.md)。如果程序能运行但图为空、范围错误或文件异常，使用[数据、坐标与导出排错](troubleshooting/data-and-output.md)。

## Learning paths

### 入门：从首个窗口到可复用仪表板

依次阅读[第一张折线图](getting-started/first-chart.md) → [Figure、面板与系列](concepts/figure-axes-series.md) → [问题与视觉编码](concepts/chart-question-and-encoding.md) → [数据范围与标度](concepts/data-domain-and-scales.md) → [选择图表](how-to/choose-chart.md) → [进阶仪表板](tutorials/advanced-dashboard.md)。完成后，你能把不同问题放进合适面板，并让一个构建器同时服务窗口和导出。

### 分析：从区间、分布到二维场

从[进阶仪表板](tutorials/advanced-dashboard.md)继续到[不确定性与分布](concepts/uncertainty-and-distribution.md)、[误差和置信带](how-to/show-uncertainty.md)、[两组分布](how-to/compare-distributions.md)、[二维场与色图](concepts/field-data-and-colormaps.md)、[热图和等高线](how-to/draw-field-data.md)、[非笛卡尔面板](concepts/non-cartesian-panels.md)和[饼图与雷达图](how-to/build-pie-and-radar.md)。这条路径强调统计含义、共同范围、色标和适用边界。

### 交互与交付：从人工检查到稳定文件

从[进阶仪表板](tutorials/advanced-dashboard.md)进入[交互与视图状态](concepts/interaction-and-view-state.md)、[启用窗口交互](how-to/interactive-window.md)、[样式、可读性与输出](concepts/style-accessibility-and-output.md)、[添加上下文](how-to/add-context.md)和[导出 PNG](how-to/export-image.md)。完成后，你能区分数据范围与用户视图，知道窗口组件为何不进入导出图片，并能实际核对最终文件。

## Find by task

下表不是目录缩写，而是按“可观察结果”选择入口。先找最接近当前目标的一行；完成后按页面的下一步继续，不必从头通读所有类型。

| 目标 | 入口 | 完成后的结果 |
|---|---|---|
| 打开第一个 Plot 窗口 | [第一张折线图](getting-started/first-chart.md) | 窗口显示标题、坐标轴、折线和图例 |
| 组合多种图形并复用构建代码 | [可复用交互仪表板](tutorials/advanced-dashboard.md) | 四面板窗口可缩放、悬停，并可改为导出 |
| 按趋势、比较、关系或构成选择图形 | [按问题选择图表](how-to/choose-chart.md) | 为选择给出与读者问题一致的理由 |
| 固定范围、设置类别轴或对数轴 | [配置坐标范围和标度](how-to/configure-axes.md) | 坐标边界和刻度符合数据语义 |
| 比较分类组或显示总量构成 | [分组或堆叠柱形](how-to/group-and-stack-bars.md) | 一张图片并列展示 grouped 与 stacked |
| 在散点中加入负载和请求量 | [颜色和大小编码](how-to/map-color-and-size.md) | 气泡图带可解释的连续色标 |
| 显示点误差与连续区间 | [误差和置信带](how-to/show-uncertainty.md) | 一张图片区分误差棒和 95% 带 |
| 比较两批原始样本 | [比较两组分布](how-to/compare-distributions.md) | 两组都进入直方图、箱线图和小提琴图 |
| 显示二维标量场 | [绘制热图和等高线](how-to/draw-field-data.md) | 热图、等高线与 ColorBar 使用一致值域 |
| 显示整体构成或多指标轮廓 | [构建饼图和雷达图](how-to/build-pie-and-radar.md) | 两种非笛卡尔面板加入同一 Figure |
| 启用缩放、平移、复位和读数 | [启用窗口交互](how-to/interactive-window.md) | 首图获得标准工具栏、悬停和光标状态 |
| 添加阈值、事件区间和文字 | [添加上下文](how-to/add-context.md) | 标注在数据坐标中跟随视图 |
| 在批处理任务中生成图片 | [导出可交付 PNG](how-to/export-image.md) | 程序同步生成指定尺寸的 PNG |
| 定位依赖、SDL 或窗口生命周期问题 | [构建与窗口运行排错](troubleshooting/build-and-runtime.md) | 用退出码、探针和可见窗口缩小故障范围 |
| 定位空图、范围或文件异常 | [数据、坐标与导出排错](troubleshooting/data-and-output.md) | 从数据层、坐标层或文件层完成修复确认 |

## Core concepts

这八个概念组成一套从数据到交付的思维模型。前四个决定对象、图形、坐标和统计表达，后四个处理二维场、特殊面板、交互状态和最终可读性。概念页都提供对比或过程代码，但不替代任务页的完整程序。

- [Figure、面板与系列](concepts/figure-axes-series.md)：整图、局部面板和数据系列怎样分工。
- [问题与视觉编码](concepts/chart-question-and-encoding.md)：为什么先明确比较关系，再选择位置、长度、颜色或形状。
- [数据范围与标度](concepts/data-domain-and-scales.md)：自动范围、显式限制、Scale 与临时视图的区别。
- [不确定性与分布](concepts/uncertainty-and-distribution.md)：中心值、误差、区间和完整样本形状各回答什么。
- [二维场与色图](concepts/field-data-and-colormaps.md)：网格、值域、Colormap 与 ColorBar 如何保持一致。
- [非笛卡尔面板](concepts/non-cartesian-panels.md)：饼图和雷达图为何是 Panel，以及它们的适用边界。
- [交互与视图状态](concepts/interaction-and-view-state.md)：缩放和平移为何不修改原始数组。
- [样式、可读性与输出](concepts/style-accessibility-and-output.md)：主题、图例、标注和尺寸如何共同支持复核。

## API reference

精确查询使用 [Plot API 参考](../api/index.md)。例如整图布局见 [`Figure`](../api/plot/Figure.md)，普通坐标见 [`Axes`](../api/plot/axes/Axes.md)，窗口生命周期见 [`PlotWindow`](../api/plot/PlotWindow.md)，文件输出见 [`FigureExport`](../api/plot/FigureExport.md)。指南页的“相关 API”会直接落到最窄的类型页，避免你在包索引中反复搜索。

## Troubleshooting

错误发生在编译、原生库加载、显示环境或 `show()` 生命周期时，从[构建与窗口运行排错](troubleshooting/build-and-runtime.md)开始。程序已经运行但结果空白、范围不对、对数轴失败或 PNG 异常时，从[数据、坐标与导出排错](troubleshooting/data-and-output.md)开始。两页都按三种症状分支组织，每个分支要求实际检查动作和可观察的修复确认，不使用“检查配置”一笔带过。
