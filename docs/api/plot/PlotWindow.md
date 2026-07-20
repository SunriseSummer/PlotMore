[plot](../index.md) › [plot](index.md) › PlotWindow

# PlotWindow

`plot` 中的 public class

交互展示图形的窗口：按需重绘，工具栏、悬停读数等悬浮界面全部可选。无组件的 `PlotWindow(figure).show()` 就是一个纯静态查看器；[addStandardToolbar](#addstandardtoolbar) 添加常用控件，[addComponent](#addcomponent) 可停靠任何 [Component](ui/Component.md)，包括自定义组件。[show](#show) 阻塞直至窗口被关闭。

## 声明

```cangjie
public class PlotWindow
```

## 说明

渲染是按需的：仅当有内容变化时才绘制一帧——事件、组件或 [invalidate](#invalidate) 置脏后于下一轮循环重绘。空闲时事件循环仍每 12 ms 轮询一次，但不会重复绘制静态内容。

生命周期与所有权：`show()` 打开系统窗口并阻塞运行事件循环，期间 `SdlWindow`、`Renderer` 与 [Canvas](canvas/Canvas.md) 由本窗口创建并独占，返回前全部关闭。展示的 [Figure](Figure.md) 由构造函数传入，窗口不会自行侦测它的变化——展示期间在外部改动图形后需调用 `invalidate()`。

事件路由以悬浮界面优先：组件消费掉的事件不再落到下方图表，因此点击工具栏按钮不会顺带平移坐标轴；在图例条目上单击会切换对应系列的显示。缩放与平移作用于光标所在的笛卡尔面板。

导出请求尺寸由 [exportWidth](#exportwidth) x [exportHeight](#exportheight) 指定（逻辑像素）。默认超采样目标可用时通常每轴为 2×；输出尺寸查询失败、结果无效或目标纹理不可用时会回退为直接绘制，最终像素尺寸以生成文件实测为准。

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow}
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "传感器读数")
    axes.xLabel = "时间 (s)"
    axes.yLabel = "电压 (V)"
    axes.add(LineSeries([0.0, 1.0, 2.0, 3.0], [0.2, 0.9, 0.5, 0.7], label: "通道 1"))

    let window = PlotWindow(figure)
    let _ = window.addStandardToolbar() // 保存 / 平移 / 框选缩放 / 复位 / 网格 / 主题
    let _ = window.enableHoverReadout() // 十字光标 + 吸附最近数据点的数值气泡
    window.interactions.lockY = true    // 缩放与平移锁定在横轴——时间序列的常用设置
    window.show()                       // 阻塞直至用户关闭窗口
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 以给定图形与窗口选项构造窗口；此时不创建任何系统资源。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`plotFigure()`](#plotfigure) | 返回正在展示的图形。 |
| [`addComponent(...)`](#addcomponent) | 把组件停靠到图形上方并返回它，以便继续配置。 |
| [`allComponents()`](#allcomponents) | 按绘制顺序返回已停靠的全部组件。 |
| [`enableHoverReadout()`](#enablehoverreadout) | 开启悬停十字光标与数值气泡，吸附到最近的数据点。 |
| [`saveImageButton()`](#saveimagebutton) | 返回接入本窗口导出流程的保存按钮，即保存图像组件。 |
| [`addStandardToolbar(...)`](#addstandardtoolbar) | 添加常用工具栏：保存、平移、框选缩放、复位视图、网格开关与深浅主题切换。 |
| [`addCursorStatus(...)`](#addcursorstatus) | 添加光标位置读数并返回它，停靠于 `placement`。 |
| [`requestSaveImage()`](#requestsaveimage) | 打开平台保存对话框，用户选定路径后从事件循环完成导出。 |
| [`saveImage(...)`](#saveimage) | 立即把图形写入 `path`，不经对话框——脚本化的导出路径。 |
| [`resetAllViews()`](#resetallviews) | 清除每个笛卡尔面板上的缩放与平移。 |
| [`setGridVisible(...)`](#setgridvisible) | 显示或隐藏每个笛卡尔面板的网格。 |
| [`setDarkTheme(...)`](#setdarktheme) | 在深浅两套预设主题之间切换图形主题。 |
| [`showStatus(...)`](#showstatus) | 在图形上方短暂显示一条状态消息。 |
| [`invalidate()`](#invalidate) | 强制在下一轮事件循环重绘一帧。 |
| [`show()`](#show) | 打开窗口并运行事件循环，直至用户关闭窗口。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`interactions`](#interactions) | 缩放、平移与框选缩放的行为配置，作用于光标所在的笛卡尔面板。 |
| [`hover`](#hover) | 悬停十字光标与数值气泡；调用 [enableHoverReadout](#enablehoverreadout) 之前处于停用状态。 |
| [`exportWidth`](#exportwidth) | 导出请求宽度，单位逻辑像素；实际文件宽度取决于渲染目标，以文件实测为准。 |
| [`exportHeight`](#exportheight) | 导出请求高度，单位逻辑像素；实际文件高度取决于渲染目标，以文件实测为准。 |
| [`exportDirectory`](#exportdirectory) | 保存对话框打开时的初始目录；`None` 使用平台默认位置。 |
| [`exportFileName`](#exportfilename) | 保存对话框拟预填的文件名。 |

## 构造函数

### init

以给定图形与窗口选项构造窗口；此时不创建任何系统资源。

```cangjie
public init(figure: Figure, options!: WindowOptions = WindowOptions())
```

**参数**

- `figure`: `Figure` — 要展示的图形。窗口持有引用而非副本，展示期间在外部修改它之后调用 `invalidate()` 刷新。
- `options!`: [`WindowOptions`](WindowOptions.md) — 窗口标题、尺寸与可调整性；默认各取 `WindowOptions` 的默认值。

## 方法

### plotFigure

返回正在展示的图形。

```cangjie
public func plotFigure(): Figure
```

**返回值** `Figure` — 构造时传入的同一实例。

### addComponent

把组件停靠到图形上方并返回它，以便继续配置。组件按添加顺序绘制与接收事件，停靠在同一角落的多个组件依次向内堆叠。

```cangjie
public func addComponent(component: Component): Component
```

**参数**

- `component`: `Component` — 要停靠的组件，位置由其自身的停靠设置决定。

**返回值** `Component` — 传入的同一组件。

### allComponents

按绘制顺序返回已停靠的全部组件。

```cangjie
public func allComponents(): ArrayList<Component>
```

**返回值** `ArrayList<Component>` — 组件列表本体（非副本），顺序即添加顺序。

### enableHoverReadout

开启悬停十字光标与数值气泡，吸附到最近的数据点。默认关闭：开启后每次指针移动都会触发重绘，大型系列会因此增加每帧的命中测试与绘制工作。

```cangjie
public func enableHoverReadout(): HoverReadout
```

**返回值** [`HoverReadout`](ui/HoverReadout.md) — 即 [hover](#hover) 字段，便于链式配置其显示选项。

### saveImageButton

返回接入本窗口导出流程的保存按钮，即保存图像组件。按下后打开平台保存对话框，选定路径后以导出尺寸、不带任何悬浮界面重新渲染图形并写入文件。可加入自建工具栏；`addStandardToolbar` 已含一个。

```cangjie
public func saveImageButton(): ToolButton
```

**返回值** [`ToolButton`](ui/ToolButton.md) — 动作为 [requestSaveImage](#requestsaveimage) 的保存按钮。

### addStandardToolbar

添加常用工具栏：保存、平移、框选缩放、复位视图、网格开关与深浅主题切换。平移与框选缩放为互斥的切换按钮——激活一个会停用另一个并取消进行中的拖拽，初始为平移模式；网格开关初始开启，主题开关初始取当前主题的明暗。返回工具栏本身，可继续增删按钮；需要不同组合时自建 [Toolbar](ui/Toolbar.md) 并停靠。

```cangjie
public func addStandardToolbar(placement!: Placement = Placement.TopRight): Toolbar
```

**参数**

- `placement!`: [`Placement`](ui/Placement.md) — 停靠位置；默认 `Placement.TopRight`（右上角）。

**返回值** `Toolbar` — 已停靠到本窗口的工具栏。

### addCursorStatus

添加光标位置读数并返回它，停靠于 `placement`。读数显示光标处的数据坐标，坐标换算取图形中第一个笛卡尔面板。

```cangjie
public func addCursorStatus(placement!: Placement = Placement.BottomRight): CursorStatus
```

**参数**

- `placement!`: `Placement` — 停靠位置；默认 `Placement.BottomRight`（右下角）。

**返回值** [`CursorStatus`](ui/CursorStatus.md) — 已停靠的读数组件。

### requestSaveImage

打开平台保存对话框，用户选定路径后从事件循环完成导出。对话框在独立线程上异步应答；已有保存对话框未关闭时调用是无操作，窗口尚未打开（`show()` 之前）时也直接返回。选定路径若无扩展名会经 [withPngExtension](functions.md#withpngextension) 补上 `.png`，随后交给 [saveImage](#saveimage)；成败都会以状态消息提示（文件名经 [fileNameOf](functions.md#filenameof) 取短名显示）。`requestSaveImage` 会捕获导出异常并把失败显示为状态消息；直接调用 `saveImage` 时，异常按 `FigureExport` 的契约向调用方传播。

```cangjie
public func requestSaveImage(): Unit
```

### saveImage

立即把图形写入 `path`，不经对话框——脚本化的导出路径。扩展名决定格式：[isBmpPath](functions.md#isbmppath) 判定为 BMP 时直接写位图，其余一律写 PNG；实际工作交给 [FigureExport](FigureExport.md) 的 `savePng`/`saveBmp`，尺寸取 `exportWidth` x `exportHeight`。

```cangjie
public func saveImage(path: String): Unit
```

**参数**

- `path`: `String` — 目标文件路径；以 `.bmp` 结尾（不区分大小写）写 BMP，否则写 PNG。

**异常**

- [`PlotException`](core/PlotException.md) — 没有已打开的窗口或画布，导出尺寸小于 `1.0`，临时 BMP 无法解码，或绘图期间触发 plot 侧的参数、状态校验。
- `CuiException` — sdl 渲染、回读像素或写入 BMP 捕获文件失败；PNG 导出中的临时捕获也属于这一类。
- `FSException`（`std.fs`）— PNG 导出无法读取临时 BMP，或无法创建、截断、写入目标 PNG。BMP 导出不经过 `std.fs`。

### resetAllViews

清除每个笛卡尔面板上的缩放与平移。各面板经 [Axes.resetView](axes/Axes.md#resetview) 回落到作者设定的范围或自动适配。

```cangjie
public func resetAllViews(): Unit
```

### setGridVisible

显示或隐藏每个笛卡尔面板的网格。写入各面板的 [Axes.showGrid](axes/Axes.md#showgrid)；非笛卡尔面板不受影响。

```cangjie
public func setGridVisible(visible: Bool): Unit
```

**参数**

- `visible`: `Bool` — `true` 显示网格，`false` 隐藏。

### setDarkTheme

在深浅两套预设主题之间切换图形主题。`true` 换到 `Theme.dark()`，`false` 换到 `Theme.light()`——整个 [Theme](core/Theme.md) 对象被替换，此前对主题的自定义修改不保留。

```cangjie
public func setDarkTheme(useDark: Bool): Unit
```

**参数**

- `useDark`: `Bool` — `true` 使用深色预设，`false` 使用浅色预设。

### showStatus

在图形上方短暂显示一条状态消息。消息以居中气泡显示在窗口底部，约 2.6 秒后自动消失；保存流程用它报告成败。

```cangjie
public func showStatus(message: String, error!: Bool = false): Unit
```

**参数**

- `message`: `String` — 显示的文字。
- `error!`: `Bool` — `true` 时以红色错误样式显示；默认 `false`。

### invalidate

强制在下一轮事件循环重绘一帧。窗口不会自行侦测图形的变化，展示期间从外部修改数据或主题后调用它，改动才会及时上屏。

```cangjie
public func invalidate(): Unit
```

### show

打开窗口并运行事件循环，直至用户关闭窗口。调用期间阻塞；`SdlWindow`、`Renderer` 与画布由本方法创建并独占，返回前全部关闭。窗口关闭返回后可以再次调用。

```cangjie
public func show(): Unit
```

**异常**

- [`PlotException`](core/PlotException.md) — 本窗口已在展示中时再次调用，或绘图期间触发 plot 侧的参数、状态校验。
- `CuiException` — sdl 初始化窗口、渲染器或文本输入失败，刷新窗口尺寸失败，或渲染、呈现期间的原生调用失败。

## 字段

### interactions

缩放、平移与框选缩放的行为配置，作用于光标所在的笛卡尔面板。类型见 [Interactions](ui/Interactions.md)；例如 `window.interactions.lockY = true` 把缩放与平移锁定在横轴。

```cangjie
public let interactions: Interactions = Interactions()
```

### hover

悬停十字光标与数值气泡；调用 [enableHoverReadout](#enablehoverreadout) 之前处于停用状态。字段本身始终可配置，开关只决定它是否参与事件与绘制。

```cangjie
public let hover: HoverReadout = HoverReadout()
```

### exportWidth

导出请求宽度，单位逻辑像素；实际文件宽度取决于渲染目标，以文件实测为准。默认 `1200.0`，导出要求不小于 `1.0`。

```cangjie
public var exportWidth: Float32 = EXPORT_WIDTH
```

### exportHeight

导出请求高度，单位逻辑像素；实际文件高度取决于渲染目标，以文件实测为准。默认 `800.0`，导出要求不小于 `1.0`。

```cangjie
public var exportHeight: Float32 = EXPORT_HEIGHT
```

### exportDirectory

保存对话框打开时的初始目录；`None` 使用平台默认位置。默认 `None`。

```cangjie
public var exportDirectory: ?String = None
```

### exportFileName

保存对话框拟预填的文件名。默认 `"figure.png"`。当前版本尚未接入对话框——sdl 的文件对话框选项没有文件名参数——设置它暂不影响对话框显示。

```cangjie
public var exportFileName: String = "figure.png"
```

## 另请参阅

- [Figure](Figure.md) —— 被展示的图形
- [FigureExport](FigureExport.md) —— 不经窗口的批量导出
- [Toolbar](ui/Toolbar.md)、[ToolButton](ui/ToolButton.md)、[Placement](ui/Placement.md) —— 自建悬浮界面
- [Interactions](ui/Interactions.md)、[HoverReadout](ui/HoverReadout.md)、[CursorStatus](ui/CursorStatus.md) —— 交互组件
