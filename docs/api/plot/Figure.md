[plot](../index.md) › [plot](index.md) › Figure

# Figure

`plot` 中的 public class

顶层绘图对象：标题、主题与按网格排布的面板集合。图形是纯描述——不持有窗口、渲染器或任何 GPU 资源——因此同一个图形既能在窗口中交互展示，也能以另一尺寸导出为图像文件。单面板图形最常见，[single](#single) 一行即可建成；多面板按行列网格排布，逐行填充。

## 声明

```cangjie
public class Figure
```

## 说明

面板网格有两种来源。未调用 [setGrid](#setgrid) 时为隐式网格：[addAxes](#addaxes)、[addPanel](#addpanel) 每次添加面板后，仅当现有网格容不下全部面板时才扩容，列数取平方不小于面板数的最小整数、行数向上取整，因此偏好横向排布——2 个面板并排为 1x2，4 个为 2x2，6 个为 2x3。扩容只增不减。显式调用 `setGrid` 后布局保持不变；仅当继续添加面板、显式网格已容不下时，才按上述隐式规则重新计算。

[draw](#draw) 是 [PlotWindow](PlotWindow.md) 窗口显示与 [FigureExport](FigureExport.md) 图像导出共用的唯一渲染入口——两者以不同矩形调用同一个函数，因此保存的文件与屏幕内容一致。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.Axes
import plot.core.Theme
import plot.series.LineSeries

main(): Unit {
    // 两个面板：隐式网格自动扩为 1x2，左右并排。
    let figure = Figure("阻尼振荡")
    figure.subtitle = "两条通道对比"
    figure.theme = Theme.dark()

    let left: Axes = figure.addAxes()
    left.add(LineSeries([0.0, 1.0, 2.0, 3.0], [0.0, 0.8, 0.3, 0.5], label: "通道 1"))
    let right: Axes = figure.addAxes()
    right.add(LineSeries([0.0, 1.0, 2.0, 3.0], [1.0, 0.4, 0.6, 0.2], label: "通道 2"))

    FigureExport.renderToPng(figure, "figure.png", width: 800, height: 600)
    println(figure.panelCount()) // 输出: 2
    // 当前目录同时生成 figure.png。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建空图形；可带主标题。 |
| [`init(title: String)`](#init) | 创建空图形；可带主标题。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static single(...)`](#single) | 创建持有单个笛卡尔面板的图形，并把图形与面板一并返回。 |
| [`addAxes()`](#addaxes) | 添加一个笛卡尔面板并返回它。 |
| [`addPanel(...)`](#addpanel) | 添加任意种类的面板并返回它。 |
| [`setGrid(...)`](#setgrid) | 把面板排布到显式指定的行列网格上，逐行填充。 |
| [`allPanels()`](#allpanels) | 按绘制顺序返回全部面板。 |
| [`panelCount()`](#panelcount) | 返回当前的面板数量。 |
| [`panelAt(...)`](#panelat) | 返回覆盖给定像素的面板；像素落在所有面板之外时返回 `None`。 |
| [`draw(...)`](#draw) | 把整个图形渲染到给定矩形内。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`title`](#title) | 绘制在图形顶部居中的主标题；为空则不绘制、不占位。 |
| [`subtitle`](#subtitle) | 主标题下方一行较小的副标题；为空则不绘制、不占位。 |
| [`theme`](#theme) | 全部面板共用的颜色、字号与调色板。 |

## 构造函数

### init

创建空图形；可带主标题。

```cangjie
public init()
```

```cangjie
public init(title: String)
```

**参数**

- `title`: `String` — 主标题，写入 [`title`](#title) 字段（仅第二个重载）。

## 方法

### single

创建持有单个笛卡尔面板的图形，并把图形与面板一并返回。返回的 [Axes](axes/Axes.md) 已就绪，可直接添加系列——这是单面板图形的最短路径。

```cangjie
public static func single(title!: String = ""): (Figure, Axes)
```

**参数**

- `title!`: `String` — 主标题；默认空字符串，即不绘制标题。

**返回值** `(Figure, Axes)` — 新建的图形与它唯一的面板。

### addAxes

添加一个笛卡尔面板并返回它。隐式网格随之扩容（规则见「说明」）。

```cangjie
public func addAxes(): Axes
```

**返回值** `Axes` — 新添加的笛卡尔面板。

### addPanel

添加任意种类的面板并返回它。[PieAxes](axes/PieAxes.md)、[RadarAxes](axes/RadarAxes.md) 与 `Axes` 同样适用——[Panel](axes/Panel.md) 抽象正是为了让几何上毫无共性的面板共存于一个图形。

```cangjie
public func addPanel(panel: Panel): Panel
```

**参数**

- `panel`: `Panel` — 要添加的面板。

**返回值** `Panel` — 传入的同一面板，便于链式配置。

### setGrid

把面板排布到显式指定的行列网格上，逐行填充。设定后网格不再随面板增加自动调整；仅当新面板放不下时才按隐式规则重新计算（见「说明」）。

```cangjie
public func setGrid(rows: Int64, columns: Int64): Unit
```

**参数**

- `rows`: `Int64` — 行数，须为正。
- `columns`: `Int64` — 列数，须为正。

**异常**

- [`PlotException`](core/PlotException.md) — `rows` 或 `columns` 非正，或 `rows * columns` 小于已添加的面板数——静默丢弃面板比拒绝更糟。

### allPanels

按绘制顺序返回全部面板。

```cangjie
public func allPanels(): ArrayList<Panel>
```

**返回值** `ArrayList<Panel>` — 面板列表本体（非副本），顺序即添加顺序。

### panelCount

返回当前的面板数量。

```cangjie
public func panelCount(): Int64
```

**返回值** `Int64` — 已添加的面板个数。

### panelAt

返回覆盖给定像素的面板；像素落在所有面板之外时返回 `None`。用于把鼠标事件路由到正确的面板；命中判定基于各面板最近一次 [draw](#draw) 时占据的矩形，因此首次绘制之前恒为 `None`。

```cangjie
public func panelAt(px: Float32, py: Float32): ?Panel
```

**参数**

- `px`: `Float32` — 横坐标，逻辑像素。
- `py`: `Float32` — 纵坐标，逻辑像素。

**返回值** `?Panel` — 覆盖该像素的面板；无命中时为 `None`。

### draw

把整个图形渲染到给定矩形内。先以主题背景色填充 `rect`，居中绘制主/副标题，再把剩余区域按网格等分为单元格、逐行放入各面板。没有面板时只绘制背景与标题。

```cangjie
public func draw(canvas: Canvas, rect: Rect): Unit
```

**参数**

- `canvas`: [`Canvas`](canvas/Canvas.md) — 绘制表面。
- `rect`: `Rect` — 目标矩形，逻辑像素。

## 字段

### title

绘制在图形顶部居中的主标题；为空则不绘制、不占位。以主题的标题字号加粗渲染。

```cangjie
public var title: String = ""
```

### subtitle

主标题下方一行较小的副标题；为空则不绘制、不占位。以主题的副标题字号与弱化文字色渲染。

```cangjie
public var subtitle: String = ""
```

### theme

全部面板共用的颜色、字号与调色板。默认取 [Theme](core/Theme.md) 的浅色预设 `Theme.light()`。

```cangjie
public var theme: Theme = Theme.light()
```

## 另请参阅

- [PlotWindow](PlotWindow.md) —— 在交互窗口中展示图形
- [FigureExport](FigureExport.md) —— 把图形导出为图像文件
- [Axes](axes/Axes.md)、[Panel](axes/Panel.md) —— 面板类型
