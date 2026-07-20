# 导出可交付 PNG

## 目标

把一个由独立构建函数返回的 Figure 导出为指定逻辑尺寸的 PNG，并通过终端输出和实际文件完成验证。程序不打开可见窗口，适合命令行、自动报告和 CI 环境。

## 适用场景

当结果要嵌入网页、报告、工单或测试产物时使用。需要人工缩放和读取数据时，使用[交互窗口](interactive-window.md)。构图逻辑应放在返回 Figure 的函数中，让显示与导出共享同一事实来源。

## 准备工作

确定输出目录可写、文件名以 `.png` 结束，并根据最终载体选择宽高。下面输出到当前工作目录；在服务程序中应使用明确的绝对或配置路径。导出依赖 SDL 的隐藏渲染环境，但不会显示桌面窗口。

## 操作步骤

完整程序构建一张带目标线的折线图，再以 1200×720 逻辑尺寸导出。`renderToPng` 是同步调用，返回后才能安全上传、移动或覆盖文件。

```cangjie verify role=complete profile=gui-visual
package guide_examples

import plot.{Figure, FigureExport}
import plot.series.LineSeries

func buildReport(): Figure {
    let (figure, axes) = Figure.single(title: "每周订单")
    axes.xLabel = "周"
    axes.yLabel = "订单数"
    axes.add(LineSeries([1.0, 2.0, 3.0, 4.0, 5.0], [320.0, 365.0, 351.0, 418.0, 447.0], label: "实际"))
    axes.add(LineSeries([1.0, 2.0, 3.0, 4.0, 5.0], [330.0, 350.0, 370.0, 390.0, 410.0], label: "目标"))
    figure
}

main(): Unit {
    let path = "weekly-orders.png"
    FigureExport.renderToPng(buildReport(), path, width: 1200, height: 720)
    println("已写入 ${path}") // 输出: 已写入 weekly-orders.png
}
```

同一个构建器也可用于桌面预览。下面变化用 PlotWindow 接收 `buildReport()`，加入标准工具栏，允许人工检查后从窗口保存；它改变交付方式，不是重复导出代码。

```cangjie role=variation
import plot.{PlotWindow, WindowOptions}

let window = PlotWindow(
    buildReport(),
    options: WindowOptions(title: "每周订单预览", width: 1000, height: 640)
)
window.addStandardToolbar()
window.exportFileName = "weekly-orders-reviewed.png"
window.show()
```

## 确认结果

运行完整程序后，终端应打印“已写入 weekly-orders.png”，当前目录存在可打开的 PNG。检查图片约为 1200×720、标题与两条图例完整、坐标标签没有裁切、折线颜色在背景上可辨。默认渲染可能采用超采样，实际物理像素应以 PNG 文件头为准；交付方要求严格尺寸时必须实际检查文件，不要只凭参数猜测。

## 常见错误

相对路径写入了意外工作目录、父目录不存在、扩展名错误或目标没有写权限，都会导致文件缺失。导出是同步任务，返回前不要启动并发上传。窗口工具栏不会进入图片，因为它不是 Figure 内容。若隐藏渲染环境初始化失败，按[构建与运行排错](../troubleshooting/build-and-runtime.md)检查 SDL；若文件存在但内容空白，按[数据与输出排错](../troubleshooting/data-and-output.md)检查范围和系列。

## 相关 API

- [`FigureExport`](../../api/plot/FigureExport.md)：建立隐藏渲染环境并写入 PNG。

## 下一步

若导出或运行不符合预期，进入[构建与运行排错](../troubleshooting/build-and-runtime.md)，按可观察症状逐步定位。
