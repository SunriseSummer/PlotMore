# 打开第一张折线图

## 你将完成

本页带你从一个空目录走到真正可见的 Plot 窗口。最终程序会创建一张“每周活跃用户”折线图：横轴是周次，纵轴是人数，图中有标题、坐标轴名称、数据点和图例。这里不省略包声明、导入或 `main`，因此你可以把程序原样放进项目运行。完成后，你也会知道哪几行负责数据、哪几行负责图形、哪一行负责打开窗口，而不只是复制一段看不懂的代码。

![Plot 官方画廊中的折线图；用来核对线、坐标轴和图例是否正常显示](../../../examples/gallery/line.png)

上图由项目自己的 `examples/src/line.cj` 构建，文件 SHA-256 为 `866c67743ec06d4a70ee0ef609146897a24e4b5cbcc160a6ce9b800c376349bd`。你的数据不同，所以曲线形状不必相同；应核对的是同一种可见结构，而不是逐像素一致。

## 开始之前

先确认本机可运行 `cjpm --version`，并已按 Plot 项目的 README 配好 SDL 原生运行库。把 Plot 项目放在当前示例项目旁边，然后在示例项目的 `cjpm.toml` 中添加本地依赖。不同机器的绝对路径不同，文档不替你猜路径；依赖解析成功时，`cjpm build` 应能找到 `plot` 包。窗口示例会进入事件循环，必须由你关闭窗口后命令才返回，这不是卡住。

建议先在普通桌面会话运行，不要一开始就在没有显示服务的远程终端中试窗口。如果你的目标只是在服务器上生成图片，可在完成首图后直接阅读[导出图片](../how-to/export-image.md)。

## 先建立一个模型

记住三个对象就够开始：`Figure` 是整张图，`Axes` 是带坐标轴的一个面板，`LineSeries` 是要画进面板的一组折线数据。`Figure.single` 一次返回一张图和它的第一个坐标面板；`axes.add` 把系列放进去；`PlotWindow.show` 才把结果呈现在桌面窗口。数据与窗口没有直接关系，所以以后可以让一个构建函数返回 `Figure`，再选择显示或导出。

## 操作步骤

1. 新建仓颉可执行项目，并让 `cjpm.toml` 依赖本地 `plot`。
2. 将下面完整程序保存为 `src/main.cj`。数组中的七个 x 值和七个 y 值一一对应；长度不一致会在构造系列时失败。
3. 在项目目录运行 `cjpm run`。窗口标题应为“每周活跃用户”，图例应出现“用户数”。
4. 用窗口关闭按钮退出。命令返回到终端后，首个完整运行闭环才算完成。

若你确实从空目录开始，不要把“新建项目”理解成一句省略的前置条件。先执行 `cjpm init --type=executable weekly_plot`，进入 `weekly_plot`，再把生成的 `cjpm.toml` 中依赖部分改为下面这样；`<path-to-plotmore>` 要换成 PlotMore 项目相对于 `weekly_plot` 的真实路径。

```toml
[dependencies]
plot = { path = "<path-to-plotmore>" }
```

此时项目至少已有 `cjpm.toml` 和 `src/main.cj` 两个文件。先运行一次 `cjpm build` 验证依赖，再替换 `src/main.cj`；这样“项目没建好”和“绘图代码写错了”不会混在一次报错里。

## 完整程序

```cangjie verify role=complete profile=gui-visual
package guide_examples

import plot.{Figure, PlotWindow, WindowOptions}
import plot.canvas.MarkerStyle
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "每周活跃用户")
    axes.xLabel = "周"
    axes.yLabel = "用户数"

    let weeks = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
    let users = [120.0, 138.0, 151.0, 147.0, 169.0, 181.0, 205.0]
    let series = LineSeries(weeks, users, label: "用户数")
    series.marker = MarkerStyle.Circle
    axes.add(series)

    let window = PlotWindow(
        figure,
        options: WindowOptions(title: "每周活跃用户", width: 960, height: 640)
    )
    window.show()
}
```

程序从 `package` 开始，结尾也确实调用了 `show()`。交互窗口打开期间 `show` 正在运行事件循环；关闭窗口后才会返回，这是预期生命周期。

## 确认结果

先看终端：构建阶段没有“找不到 plot 包”或原生库加载错误。再看窗口：标题完整显示，七个圆点由折线连接，横轴覆盖 1 到 7 附近，纵轴覆盖 120 到 205 附近，图例只出现一次。最后关闭窗口，确认进程正常结束。如果窗口打开但空白，先不要随意固定坐标范围，检查数组长度和数值是否有效，再读[数据与输出排错](../troubleshooting/data-and-output.md)。

## 接着试一试

下面的变化仍使用同一个对象关系，但增加第二条系列。把它放在 `axes.add(series)` 之后、创建窗口之前。两条线共享坐标轴，图例会自动出现两个条目；这比复制整个 `main` 更能看清“一个面板可以容纳多个系列”。

```cangjie role=variation
let target = LineSeries(
    [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
    [130.0, 140.0, 150.0, 160.0, 170.0, 180.0, 190.0],
    label: "目标"
)
axes.add(target)
```

观察实际值在哪些周高于目标、哪些周低于目标。这里的变化是新增一组数据，不是只改标题或颜色，因此它验证了“多系列共享一个面板”的能力。

## 如果没有成功

如果编译器提示无法解析 `plot`，核对依赖路径和包名，而不是修改导入语句碰运气。如果程序编译成功但运行时提示 SDL 动态库不可用，检查原生库路径以及当前是否有桌面显示环境。如果程序一直不返回但窗口仍开着，这是正常事件循环；关闭窗口即可。如果窗口存在但图例或曲线不可见，检查是否把系列真正传给了 `axes.add`。更系统的步骤见[构建与运行排错](../troubleshooting/build-and-runtime.md)。

## 相关 API

- [`Figure`](../../api/plot/Figure.md)：创建整张图和面板布局。
- [`PlotWindow`](../../api/plot/PlotWindow.md)：显示 Figure，并管理窗口事件循环。
- [`LineSeries`](../../api/plot/series/LineSeries.md)：保存并绘制成对的 x/y 数据。

## 下一步

继续阅读 [Figure、面板与系列](../concepts/figure-axes-series.md)，把刚才运行成功的代码整理成可复用的工作模型。
