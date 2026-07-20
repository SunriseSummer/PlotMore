[plot 指南](../index.md) › 导出 PNG

# 把图导出为 PNG

## 目标

在不打开可见查看窗口的情况下，把完整 `Figure` 写入 `monthly-sales.png`，并区分传入的逻辑布局尺寸与最终 PNG 的物理像素尺寸。当前渲染器默认请求每轴 2 倍超采样；只有超采样目标可用时才会按该倍率捕获，程序返回后应读取 PNG 实际尺寸再检查或移动。

## 适用场景

当输出的主要消费者是文档、邮件、网页或归档系统，而不是正在探索数据的人时使用。人工缩放、平移和悬停读数属于 `PlotWindow`；直接导出省去等待用户关闭窗口的事件循环。两条路径都复用同一个图形描述。

## 准备工作

项目已经可以构建 `plot`，运行环境能加载 SDL 动态库，目标目录可写。选择明确的像素尺寸和文件名；批量任务为每个结果使用不同路径。若目标目录不存在，应在业务层先创建或报告错误，不要把路径准备藏在图形构建函数中。

## 操作步骤

### 1. 构建与窗口无关的 Figure

沿用第一张图的 `Figure.single` 和 `LineSeries`。不要先创建 `PlotWindow`；`FigureExport.renderToPng` 会自行建立隐藏渲染环境，并在完成后释放它。

### 2. 指定文件和尺寸

调用 `renderToPng(figure, path, width, height)`。宽高必须是正的**逻辑尺寸**。`width`/`height` 是逻辑尺寸；当默认的 2 倍超采样目标可用时，物理像素每轴翻倍，实际文件尺寸仍以 IHDR 为准。本次验证环境实测传入 600×400 落盘为 1200×800；若渲染器回退到直接绘制，则可能得到 600×400。逻辑尺寸影响布局，超采样可用时会提高文字和线条的物理像素密度。

### 3. 等待调用返回再使用文件

导出是同步任务。调用返回后再上传、移动或覆盖文件。失败时保留错误信息并处理目标路径，不要把失败吞掉后继续声称报告已生成。

## 完整程序

```cangjie verify role=complete
package demo

import plot.{Figure, FigureExport}
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "月度销量")
    axes.xLabel = "月份"
    axes.yLabel = "销量"
    axes.add(LineSeries([1.0, 2.0, 3.0, 4.0], [12.0, 18.0, 15.0, 22.0], label: "华东"))
    FigureExport.renderToPng(
        figure,
        "monthly-sales.png",
        width: 600,
        height: 400
    )
    println("已写入 monthly-sales.png")
}
```

## 确认结果

执行 `cjpm run`。终端应打印文件名，当前目录出现非空的 `monthly-sales.png`。用图片查看器打开它，确认总标题、轴标签、折线和图例与 `Figure` 描述一致。本次验证环境中，请求的逻辑尺寸 600×400 实测得到物理像素 1200×800；你的运行环境应以 PNG 的 IHDR 为准。Windows 可这样读取：

```powershell
$bytes = [System.IO.File]::ReadAllBytes("monthly-sales.png")
$width = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($bytes, 16))
$height = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($bytes, 20))
"${width}x${height}"
```

本次验证记录为 `1200x800`。若你的输出是 `600x400`，说明渲染器使用了直接绘制回退，并不表示编码器改变了纵横比。自动化任务至少检查文件存在、非空和 IHDR 实测尺寸；只有固定了运行环境后，才把具体物理尺寸写成回归断言。视觉回归可再比较确定性示例的截图。

需要横向报告时，不必重建数据。把下面变化插入完整程序的 `println` 之前；它复用同一个 `figure`，额外写出逻辑尺寸 900×300 的横向版本：

```cangjie role=variation
FigureExport.renderToPng(
    figure,
    "monthly-sales-wide.png",
    width: 900,
    height: 300
)
```

## 常见错误

- **尺寸为零或负数**：导出会报告尺寸错误；在调用前校验配置。
- **路径不可写或目录不存在**：先创建目录并检查权限，不要把错误解释为编码问题。
- **编译成功、运行时报 SDL 动态库缺失**：隐藏渲染仍需要运行库；“不显示窗口”不等于完全不使用 SDL。
- **循环覆盖同一路径**：为每个数据集生成稳定且唯一的文件名，调用返回后再进入下一项。
- **导出与窗口外观不同**：检查导出尺寸、窗口附加组件和主题；工具栏等窗口界面不属于图本身。
- **图片宽高翻倍或没有翻倍**：`width`/`height` 是逻辑尺寸。默认超采样目标可用时通常每轴 2 倍，不可用时渲染器会回退到直接绘制；读取 IHDR 确认当前环境的实际倍率，不要把 2 倍当成跨环境契约。

## 相关 API

- [`FigureExport`](../../api/plot/FigureExport.md) — PNG/BMP 路径、尺寸要求和错误行为。
- [`Figure`](../../api/plot/Figure.md) — 可被显示或导出的完整图形描述。
- [`PlotWindow`](../../api/plot/PlotWindow.md) — 需要人工交互时的替代交付路径。

## 下一步

为图补充阈值和说明时返回[给图形补充上下文](add-context.md)。批量导出失败时转到[常见绘图问题](../troubleshooting/common-problems.md)，按尺寸、路径、动态库和数据四类现象诊断。
