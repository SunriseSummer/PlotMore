[plot](../../index.md) › [plot.axes](index.md) › Axes

# Axes

`plot.axes` 中的 public class

笛卡尔绘图面板：两条标度、一叠按序绘制的系列，加上网格线、刻度、标注与图例。每条轴的绘制范围按「视图 → 固定范围 → 自动适配」的优先级解析。作为面板挂进 [Figure](../Figure.md) 的网格，通常经 [Figure.addAxes](../Figure.md#addaxes) 创建。

## 声明

```cangjie
public class Axes <: Panel
```

## 继承

- 父类：[Panel](Panel.md)（`title`、`lastRect`、`frame`、`containsPixel` 继承自它）。

## 说明

**范围解析。** 每条轴在每次绘制时独立解析出一个数据区间，优先级固定：

1. **视图** —— `setView` 写入的缩放/平移覆盖区间，存在即用；
2. **固定范围** —— `setXLimits` / `setYLimits` 固定的区间；
3. **自动适配** —— 把所有可见系列的 [`Series.dataBounds`](../series/Series.md#databounds) 取并集，经 [`Bounds.nonDegenerate`](../core/Bounds.md#nondegenerate) 展开退化区间，再向外扩一次：`niceRange` 开启时用 [`Scale.niceBounds`](../core/Scale.md#nicebounds) 取整到整刻度，否则用 [`Scale.padBounds`](../core/Scale.md#padbounds) 追加 `headroom` 比例的呼吸空间——两者只取其一，绝不叠加。任一可见系列的 [`Series.fillsExtent`](../series/Series.md#fillsextent) 为 `true`（热力图、等高线这类铺满矩形的系列）时完全跳过外扩；没有任何可绘数据时退回标度当前的定义域，而不是杜撰一个 0..1。

`resetView` 只丢弃视图这一层：用户缩放后复位，落回作者设定的固定范围或自动适配的结果，而不是数据碰巧的形状。`hasView` 报告视图是否生效；`effectiveXBounds` / `effectiveYBounds` 给出解析结果。

**绘制顺序。** `draw` 依次绘制面板背景、网格线、系列、标注、轴脊、刻度、标题与轴标题、颜色条、图例；系列与标注被裁剪到绘图矩形内，放大后的数据不会画到轴上。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.Axes
import plot.core.Bounds
import plot.series.LineSeries

main(): Unit {
    let figure = Figure("信号")
    let axes: Axes = figure.addAxes()
    axes.title = "信号"
    axes.xLabel = "时间 (s)"
    axes.yLabel = "幅度"
    axes.add(LineSeries([0.0, 1.0, 2.0, 3.0], [0.0, 0.8, 0.4, 1.0], label: "通道 1"))

    // 固定 x 范围；y 轴保持自动适配
    axes.setXLimits(Bounds(0.0, 3.0))

    FigureExport.renderToPng(figure, "axes.png", width: 800, height: 600)
    println(axes.effectiveXBounds()) // 输出: Bounds(0.000000, 3.000000)
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建一个空面板：两轴均为线性标度，无系列、无固定范围、无视图。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`add(series)`](#add) | 添加一个系列并给它分配下一个调色板槽位，返回该系列以便继续配置。 |
| [`annotate(annotation)`](#annotate) | 添加一个绘制在数据之上的标注，返回该标注。 |
| [`setColorBar(colorBar)`](#setcolorbar) | 挂载颜色条并让绘图区变窄为其腾位，返回该颜色条。 |
| [`colorBar()`](#colorbar) | 已挂载的颜色条；没有则为 `None`。 |
| [`allSeries()`](#allseries) | 面板内的全部系列，按绘制顺序排列。 |
| [`clear()`](#clear) | 移除所有系列与标注，保留标度、固定范围与样式。 |
| [`setXScale(scale)`](#setxscale) | 替换 x 标度。 |
| [`setYScale(scale)`](#setyscale) | 替换 y 标度。 |
| [`x()`](#x) | 当前的 x 标度。 |
| [`y()`](#y) | 当前的 y 标度。 |
| [`setXLimits(bounds)`](#setxlimits) | 把 x 轴范围固定为 `bounds`，停用该轴的自动适配。 |
| [`setYLimits(bounds)`](#setylimits) | 把 y 轴范围固定为 `bounds`。 |
| [`autoscaleX()`](#autoscalex) | 撤销固定范围，让 x 轴恢复自动适配。 |
| [`autoscaleY()`](#autoscaley) | 撤销固定范围，让 y 轴恢复自动适配。 |
| [`setView(xBounds, yBounds)`](#setview) | 同时覆盖两轴的绘制范围——缩放与平移的写入路径。 |
| [`resetView()`](#resetview) | 丢弃缩放/平移视图，回到固定范围或自动适配。 |
| [`hasView()`](#hasview) | 报告缩放或平移是否正在覆盖轴范围。 |
| [`effectiveXBounds()`](#effectivexbounds) | 此刻将被绘制的 x 范围：视图，其次固定范围，否则自动适配。 |
| [`effectiveYBounds()`](#effectiveybounds) | 此刻将被绘制的 y 范围，解析规则与 `effectiveXBounds` 相同。 |
| [`dataArea()`](#dataarea) | 最近一次绘制得到的绘图矩形——数据实际占据的区域。 |
| [`projection()`](#projection) | 基于最近一次布局的投影，供两帧之间的命中测试使用。 |
| [`draw(canvas, rect, theme)`](#draw) | 把整个面板渲染进 `rect`：背景、网格、系列、标注、轴脊、刻度、文字、颜色条与图例。 |
| [`hitTest(px, py, theme)`](#hittest) | 在全部可见系列中寻找离 `(px, py)` 最近的数据点，供工具提示使用。 |
| [`legendEntries(theme)`](#legendentries) | 每个带标签系列贡献的图例条目，按系列添加顺序串联。 |
| [`legendHiddenFlags(theme)`](#legendhiddenflags) | 与 `legendEntries` 逐项对齐的隐藏标记：条目背后的系列当前不可见时为 `true`。 |
| [`toggleLegendEntry(index, theme)`](#togglelegendentry) | 翻转图例条目 `index` 背后那个系列的可见性，返回是否确有变化。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`xLabel`](#xlabel) | x 轴标题；为空则不绘制也不占空间。 |
| [`yLabel`](#ylabel) | y 轴标题；为空则不绘制也不占空间。 |
| [`yLabelOrientation`](#ylabelorientation) | y 轴标题的排布方向，默认 `Vertical`（旋转 90°，科学惯例）。 |
| [`showGrid`](#showgrid) | 网格线总开关：是否在主刻度处绘制网格线，默认开。 |
| [`showMinorGrid`](#showminorgrid) | 是否在次刻度处绘制更淡的网格线，默认关。 |
| [`showGridX`](#showgridx) | 是否绘制竖直网格线（x 刻度处），默认开。 |
| [`showGridY`](#showgridy) | 是否绘制水平网格线（y 刻度处），默认开。 |
| [`showSpines`](#showspines) | 是否绘制轴脊，默认开。 |
| [`showTicks`](#showticks) | 是否在面板外侧绘制刻度短线，默认开。 |
| [`showTickLabels`](#showticklabels) | 是否绘制刻度标签，默认开。 |
| [`legend`](#legend) | 本面板的图例配置；就地修改其字段即可调整图例。 |
| [`headroom`](#headroom) | 自动适配时在数据两侧追加的呼吸空间，取数据跨度的比例，默认 `0.05`。 |
| [`niceRange`](#nicerange) | 自动适配范围是否向外取整到整刻度，使轴恰好终止在带标签的刻度上；默认关。 |

## 构造函数

### init

创建一个空面板：两轴均为线性标度，无系列、无固定范围、无视图。之后用 `add` 挂系列，用 `setXScale` / `setYScale` 更换 [LinearScale](../core/LinearScale.md) 之外的标度。

```cangjie
public init()
```

## 方法

### add

添加一个系列并给它分配下一个调色板槽位，返回该系列以便继续配置。槽位等于添加时已有的系列数，决定未指定颜色的系列从主题调色板取哪一格。

```cangjie
public func add(series: Series): Series
```

**参数**

- `series`: `Series` — 要添加的数据层，见 [Series](../series/Series.md)。

**返回值** `Series` — 传入的同一系列，便于链式继续配置。

### annotate

添加一个绘制在数据之上的标注，返回该标注。标注在全部系列之后绘制，并被裁剪到绘图矩形内，见 [Annotation](Annotation.md)。

```cangjie
public func annotate(annotation: Annotation): Annotation
```

**参数**

- `annotation`: `Annotation` — 要添加的标注。

**返回值** `Annotation` — 传入的同一标注。

### setColorBar

挂载颜色条并让绘图区变窄为其腾位，返回该颜色条。当某个系列把数值编码为颜色（热力图、等高线）时需要它——否则面板上没有任何东西说明颜色的含义。见 [ColorBar](ColorBar.md)。

```cangjie
public func setColorBar(colorBar: ColorBar): ColorBar
```

**参数**

- `colorBar`: `ColorBar` — 要挂载的颜色条；再次调用会替换之前的。

**返回值** `ColorBar` — 传入的同一颜色条。

### colorBar

已挂载的颜色条；没有则为 `None`。

```cangjie
public func colorBar(): ?ColorBar
```

**返回值** `?ColorBar` — 当前颜色条，或 `None`。

### allSeries

面板内的全部系列，按绘制顺序排列。

```cangjie
public func allSeries(): ArrayList<Series>
```

**返回值** `ArrayList<Series>` — 面板内部持有的列表本身，而非副本。

### clear

移除所有系列与标注，保留标度、固定范围与样式。

```cangjie
public func clear(): Unit
```

### setXScale

替换 x 标度。换成 [LogScale](../core/LogScale.md) 得到对数轴，换成 [CategoryScale](../core/CategoryScale.md) 得到类别轴，整条轴的刻度与范围行为随之改变。

```cangjie
public func setXScale(scale: Scale): Unit
```

**参数**

- `scale`: `Scale` — 新的 x 标度。

### setYScale

替换 y 标度。

```cangjie
public func setYScale(scale: Scale): Unit
```

**参数**

- `scale`: `Scale` — 新的 y 标度。

### x

当前的 x 标度。注意面板在绘制与范围解析时会把解析出的有效区间写入该标度的定义域。

```cangjie
public func x(): Scale
```

**返回值** `Scale` — 当前 x 标度。

### y

当前的 y 标度。

```cangjie
public func y(): Scale
```

**返回值** `Scale` — 当前 y 标度。

### setXLimits

把 x 轴范围固定为 `bounds`，停用该轴的自动适配。仍会被缩放/平移视图覆盖；`autoscaleX` 撤销固定。

```cangjie
public func setXLimits(bounds: Bounds): Unit
```

**参数**

- `bounds`: `Bounds` — 要固定的数据区间。

### setYLimits

把 y 轴范围固定为 `bounds`。

```cangjie
public func setYLimits(bounds: Bounds): Unit
```

**参数**

- `bounds`: `Bounds` — 要固定的数据区间。

### autoscaleX

撤销固定范围，让 x 轴恢复自动适配。

```cangjie
public func autoscaleX(): Unit
```

### autoscaleY

撤销固定范围，让 y 轴恢复自动适配。

```cangjie
public func autoscaleY(): Unit
```

### setView

同时覆盖两轴的绘制范围——缩放与平移的写入路径。视图优先于固定范围与自动适配，两轴总是一起写入；`resetView` 清除。

```cangjie
public func setView(xBounds: Bounds, yBounds: Bounds): Unit
```

**参数**

- `xBounds`: `Bounds` — x 轴视图区间（数据坐标）。
- `yBounds`: `Bounds` — y 轴视图区间（数据坐标）。

### resetView

丢弃缩放/平移视图，回到固定范围或自动适配。只清除视图这一层，固定范围原样保留——复位落回作者的意图，而不是数据碰巧的形状。

```cangjie
public func resetView(): Unit
```

### hasView

报告缩放或平移是否正在覆盖轴范围。

```cangjie
public func hasView(): Bool
```

**返回值** `Bool` — 任一轴存在视图区间时为 `true`。

### effectiveXBounds

此刻将被绘制的 x 范围：视图，其次固定范围，否则自动适配。解析细节见「说明」。

```cangjie
public func effectiveXBounds(): Bounds
```

**返回值** `Bounds` — 数据坐标下的区间。

### effectiveYBounds

此刻将被绘制的 y 范围，解析规则与 `effectiveXBounds` 相同。

```cangjie
public func effectiveYBounds(): Bounds
```

**返回值** `Bounds` — 数据坐标下的区间。

### dataArea

最近一次绘制得到的绘图矩形——数据实际占据的区域。标题、刻度标签、图例与颜色条都在它之外。

```cangjie
public func dataArea(): Rect
```

**返回值** `Rect` — 逻辑像素；尚未绘制过时为零矩形。

### projection

基于最近一次布局的投影，供两帧之间的命中测试使用。调用时先把当前有效区间写回两条标度，因此缩放刚改变视图也能立即得到正确的映射。

```cangjie
public func projection(): Projection
```

**返回值** `Projection` — 最近一次绘图矩形加当前两条标度构成的数据↔像素变换，见 [Projection](../core/Projection.md)。

### draw

把整个面板渲染进 `rect`：背景、网格、系列、标注、轴脊、刻度、文字、颜色条与图例。先按实测文字尺寸从 `rect` 中切出绘图矩形（宽刻度标签不会被裁掉），再按固定顺序绘制；同时记下 `frame` 与 `dataArea` 之后报告的矩形。

```cangjie
public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标，见 [Canvas](../canvas/Canvas.md)。
- `rect`: `Rect` — 面板可用的矩形，逻辑像素。
- `theme`: `Theme` — 配色与字号，见 [Theme](../core/Theme.md)。

### hitTest

在全部可见系列中寻找离 `(px, py)` 最近的数据点，供工具提示使用。像素点必须落在最近一次绘制的绘图矩形内，否则直接返回 `None`；命中取各可见系列报告的像素距离中的最小者。

```cangjie
public func hitTest(px: Float32, py: Float32, theme: Theme): ?HitResult
```

**参数**

- `px`: `Float32` — 查询点的水平像素坐标（逻辑像素）。
- `py`: `Float32` — 查询点的竖直像素坐标（逻辑像素）。
- `theme`: `Theme` — 供系列解析命中结果所带的颜色。

**返回值** `?HitResult` — 全局最近的命中，见 [HitResult](../series/HitResult.md)；点在绘图矩形外或没有系列报告命中时为 `None`。

### legendEntries

每个带标签系列贡献的图例条目，按系列添加顺序串联。空标签的系列不贡献条目；被切换隐藏的系列仍保留条目，图例据此把它灰显并允许点击恢复——用 `legendHiddenFlags` 区分。

```cangjie
public func legendEntries(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 供系列解析色样颜色。

**返回值** `Array<LegendEntry>` — 图例条目数组，见 [LegendEntry](../series/LegendEntry.md)。

### legendHiddenFlags

与 `legendEntries` 逐项对齐的隐藏标记：条目背后的系列当前不可见时为 `true`。

```cangjie
public func legendHiddenFlags(theme: Theme): Array<Bool>
```

**参数**

- `theme`: `Theme` — 与 `legendEntries` 保持同一枚举顺序所需。

**返回值** `Array<Bool>` — 与 `legendEntries` 的返回一一对应。

### toggleLegendEntry

翻转图例条目 `index` 背后那个系列的可见性，返回是否确有变化。下标数的是图例条目而非系列——无标签系列不占下标；返回值让调用者决定是否需要重绘。

```cangjie
public func toggleLegendEntry(index: Int64, theme: Theme): Bool
```

**参数**

- `index`: `Int64` — 图例条目下标，从 0 起；越界时无副作用。
- `theme`: `Theme` — 与 `legendEntries` 保持同一枚举顺序所需。

**返回值** `Bool` — 找到条目并翻转了其系列时为 `true`；`index` 越界为 `false`。

## 字段

### xLabel

x 轴标题；为空则不绘制也不占空间。

```cangjie
public var xLabel: String = ""
```

### yLabel

y 轴标题；为空则不绘制也不占空间。

```cangjie
public var yLabel: String = ""
```

### yLabelOrientation

y 轴标题的排布方向，默认 `Vertical`（旋转 90°，科学惯例）。`Vertical` 经 [Canvas.textRotated](../canvas/Canvas.md#textrotated) 把标题整体旋转 -90° 画在轴旁，自下而上阅读；`Horizontal` 水平放在轴的上方，仪表盘风格；`Stacked` 让字形保持直立、自上而下逐字排成一列，是中日韩文字的自然纵排。三种取向在布局时各自预留不同的边距，见 [LabelOrientation](LabelOrientation.md)。

```cangjie
public var yLabelOrientation: LabelOrientation = LabelOrientation.Vertical
```

### showGrid

网格线总开关：是否在主刻度处绘制网格线，默认开。关闭后 `showGridX` / `showGridY` / `showMinorGrid` 均不再生效。

```cangjie
public var showGrid: Bool = true
```

### showMinorGrid

是否在次刻度处绘制更淡的网格线，默认关。标度得先产出次刻度才有内容，如 [LinearScale.setMinorDivisions](../core/LinearScale.md#setminordivisions)。

```cangjie
public var showMinorGrid: Bool = false
```

### showGridX

是否绘制竖直网格线（x 刻度处），默认开。

```cangjie
public var showGridX: Bool = true
```

### showGridY

是否绘制水平网格线（y 刻度处），默认开。

```cangjie
public var showGridY: Bool = true
```

### showSpines

是否绘制轴脊，默认开。主题的 `panelBordered` 为真时画完整边框，否则只画左侧与底部两条轴线。

```cangjie
public var showSpines: Bool = true
```

### showTicks

是否在面板外侧绘制刻度短线，默认开。次刻度的短线比主刻度短。

```cangjie
public var showTicks: Bool = true
```

### showTickLabels

是否绘制刻度标签，默认开。同时影响布局：关闭后不再为标签预留边距。

```cangjie
public var showTickLabels: Bool = true
```

### legend

本面板的图例配置；就地修改其字段即可调整图例。`let` 字段，不可整体替换，见 [Legend](Legend.md)。

```cangjie
public let legend: Legend = Legend()
```

### headroom

自动适配时在数据两侧追加的呼吸空间，取数据跨度的比例，默认 `0.05`。外扩的几何由标度决定：线性轴加性外扩，对数轴按十进位比例，类别轴忽略。`niceRange` 开启时被忽略；任一可见系列 `fillsExtent()` 为 `true` 时同样不生效。

```cangjie
public var headroom: Float64 = AUTOSCALE_HEADROOM
```

### niceRange

自动适配范围是否向外取整到整刻度，使轴恰好终止在带标签的刻度上；默认关。开启后 `headroom` 被忽略——取整本身已把范围推到下一个整步长，再叠加呼吸空间会外扩两次，把 0..10 的数据晾在 -2..12 的轴中间。

```cangjie
public var niceRange: Bool = false
```

## 另请参阅

- [Panel](Panel.md) — 面板抽象与 `frame` / `containsPixel`
- [Legend](Legend.md)、[ColorBar](ColorBar.md) — 面板的两种装饰
- [Annotation](Annotation.md) — 画在数据之上的标注
- [Scale](../core/Scale.md)、[Bounds](../core/Bounds.md)、[Projection](../core/Projection.md) — 范围与坐标变换
