[plot 指南](../index.md) › 第一张折线图

# 绘制第一张折线图

## 你将完成

你会从一个空的仓颉可执行项目开始，打开标题为“月度销量”的交互窗口。窗口中有一条连接四个月份数据的折线，图例把它标为“华东”。关闭窗口后程序正常返回。这个结果同时验证依赖、动态库、图形组合和窗口生命周期，而不只是证明某个构造函数能被调用。

本教程刻意只使用一个面板和一条系列。先得到可靠的最小结果，再到后续页面增加第二面板、分类轴和导出；这样出错时可以知道问题来自环境、数据还是新增配置。

## 开始之前

- 已安装仓颉 1.0.5，并能在终端运行 `cjpm --version`。
- 已取得同一工作区中的 `plot` 与它依赖的 `sdl` 源码；两者保持同级，因为 `plot/cjpm.toml` 的路径依赖指向 `../sdl`。只有孤立的 `plot` 目录时，依赖解析不会成功。
- 运行交互窗口时，SDL3 与 SDL3_ttf 动态库必须位于可执行文件目录或系统动态库搜索路径。缺少它们通常表现为编译成功、启动时报动态库加载错误。
- 你只需了解仓颉的数组、导入和 `main`；不需要先读 API 包结构。

新建 `demo` 可执行项目后，使用完整的最小 manifest；根包名与后面的 `package demo` 保持一致：

```toml
[package]
cjc-version = "1.0.5"
name = "demo"
version = "0.1.0"
output-type = "executable"

[dependencies]
plot = { path = "../plot" }
```

目录应类似 `demo/`、`plot/`、`sdl/` 三者同级。依赖路径指向包含 `plot` 的 `cjpm.toml` 的目录，而不是 `src`。先执行一次 `cjpm build`，把路径或工具链错误与后面的绘图问题分开。Windows 下构建成功后，把仓库自带的运行库复制到实际可执行文件目录：

```powershell
cjpm build
Copy-Item ..\sdl\.sdl3\*.dll target\release\bin\
cjpm run
```

## 先建立一个模型

把一张图想成三层容器。`Figure` 是整张作品，保存总标题、主题和面板排列；`Axes` 是其中一个带横纵坐标的绘图区；`LineSeries` 是放进绘图区的一层数据。`Figure.single` 是常见捷径，它一次创建整张图和唯一面板，所以返回两个值。窗口只是展示已经描述好的图，不拥有这些数据的定义。

这意味着操作顺序很自然：先创建整张图和面板，再创建系列并加入面板，最后选择显示或导出。以后增加第二条线时仍是“再加一层系列”；做 2×2 报表时才需要“再加面板”。

## 操作步骤

### 1. 写入图形描述

在 `src/main.cj` 中导入顶层的 `Figure`、`PlotWindow`、`WindowOptions` 和折线系列。四个 x 值与四个 y 值按位置配对；`label` 会成为图例文字。`Figure` 标题画在图内，`WindowOptions.title` 设置系统标题栏，两者是独立需求。

### 2. 把系列加入面板

构造系列本身不会自动显示。调用 `axes.add(...)` 后，该系列才属于这个面板，面板会把它的有效数据纳入自动范围计算。若以后发现窗口有坐标轴却没有数据，首先确认系列确实被加入，而不是只创建了局部变量。

### 3. 交给窗口运行

`PlotWindow(figure).show()` 创建并运行交互窗口。窗口关闭前 `show` 不返回，所以不要把必须立即执行的批处理逻辑放在它后面；纯导出任务使用后面的 `FigureExport` 路径。

## 完整程序

把以下内容保存为 `src/main.cj`：

```cangjie verify role=complete
package demo

import plot.{Figure, PlotWindow, WindowOptions}
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "月度销量")
    axes.xLabel = "月份"
    axes.yLabel = "销量"
    axes.add(LineSeries([1.0, 2.0, 3.0, 4.0], [12.0, 18.0, 15.0, 22.0], label: "华东"))
    let window = PlotWindow(figure, options: WindowOptions(title: "月度销量", width: 900, height: 600))
    window.show()
    // 关闭交互窗口后，show 返回，程序结束。
}
```

## 确认结果

在项目目录执行 `cjpm run`。成功时系统标题栏与图内总标题都显示“月度销量”；横轴标题为“月份”，纵轴标题为“销量”，折线依次经过四个点，图例出现“华东”。把 `WindowOptions.title` 临时改成“销售查看器”，应只改变系统标题栏，图内标题保持不变。拖动窗口尺寸时图形会重新排布；关闭窗口后终端重新出现提示符。

若 `cjpm build` 已成功但窗口启动失败，先查看错误是否直接指出 SDL 动态库。x/y 数组长度不一致会在 `LineSeries` 构造时直接抛错，窗口不会出现；窗口出现但没有折线时，重点确认 `axes.add` 是否仍在程序中以及数据是否为空/无效。不要先修改主题、范围或标度，那会同时引入多个变量。

## 接着试一试

1. 把最后一个销量从 `22.0` 改为 `30.0`，预测折线终点和纵轴自动上限如何变化，再重新运行。
2. 再调用一次 `axes.add(LineSeries(..., label: "华南"))`，使用相同 x 值和另一组 y 值。两条系列应共享坐标面板，并各自出现在图例中。
3. 把标题或轴标题改成业务中的真实名称。文字承担语义，颜色和线型只辅助区分；不要让读者仅凭“蓝线/橙线”猜系列含义。

第二项变化不需要新面板。把下面这层数据插在完整程序的第一条 `axes.add(...)` 之后、创建 `PlotWindow` 之前；它与“华东”共享月份和销量单位，所以会进入同一图例与坐标语境：

```cangjie role=variation
axes.add(LineSeries(
    [1.0, 2.0, 3.0, 4.0],
    [10.0, 16.0, 19.0, 24.0],
    label: "华南"
))
```

## 如果没有成功

- **依赖找不到**：先确认示例项目和两个依赖项目放在同一目录。再进入 `plot` 检查它引用的 `../sdl` 路径是否成立。

- **启动时报 DLL/动态库错误**：运行上面的 `Copy-Item`，确认 `SDL3.dll` 与 `SDL3_ttf.dll` 位于 `target/release/bin`。

- **构造系列时报长度错误**：让 x/y 数组数量一致；这是开窗前错误，不属于“空图”。

- **只有坐标轴没有折线**：确认系列已通过 `axes.add` 加入，再检查数组是否为空或没有有效值。

- **程序似乎“卡住”**：交互窗口打开期间 `show` 正在运行事件循环；关闭窗口后才会返回，这是预期生命周期。

更多分支见[常见绘图问题](../troubleshooting/common-problems.md)。

## 相关 API

- [`Figure.single`](../../api/plot/Figure.md#single) — 创建单个笛卡尔面板的常用入口。
- [`Axes.add`](../../api/plot/axes/Axes.md#add) — 把数据系列加入面板。
- [`LineSeries`](../../api/plot/series/LineSeries.md) — 折线数据、标记、填充和线型。
- [`PlotWindow`](../../api/plot/PlotWindow.md) — 交互窗口及其生命周期。
- [`WindowOptions`](../../api/plot/WindowOptions.md) — 系统标题栏与初始窗口尺寸。

## 下一步

继续阅读[整张图、面板与数据系列](../concepts/figure-axes-series.md)。它会解释为什么增加数据层和增加绘图区是两种不同操作，并为多面板报告做好准备。如果当前目标只是批量写出图片，可先跳到[导出 PNG](../how-to/export-image.md)。
