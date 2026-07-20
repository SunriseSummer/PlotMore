[plot](../../index.md) › [plot.axes](index.md) › RadarAxes

# RadarAxes

`plot.axes` 中的 public class

雷达图（蜘蛛图）面板：多个变量在从共享中心辐射的辐条上展开，每条轨迹画成闭合多边形。辐条至少三根，构造时校验。

## 声明

```cangjie
public class RadarAxes <: Panel
```

## 继承

- 父类：[Panel](Panel.md) —— 由其继承 `title` 字段与 `frame()`、`containsPixel()`。

## 说明

所有辐条共用同一条径向标度，因此各变量必须可通约——量纲不同就先归一化，否则多边形的形状反映的是单位而不是数据。

网格环画成多边形而不是圆：轨迹本身是多边形，圆形参考环会落在其顶点连线之外，错报辐条之间的数值。非有限（NaN 或无穷）的轨迹值按量程下限绘制；隐藏的轨迹不绘制、不参与自动适配，其图例条目保留原位并减淡显示。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.{RadarAxes, RadarTrace}

main(): Unit {
    let radar = RadarAxes(["速度", "功率", "续航", "成本", "重量"])
    radar.add(RadarTrace([80.0, 60.0, 90.0, 40.0, 70.0], label: "车型 A"))
    radar.add(RadarTrace([60.0, 85.0, 70.0, 75.0, 55.0], label: "车型 B"))
    let figure = Figure("车型对比")
    figure.addPanel(radar)
    FigureExport.renderToPng(figure, "radar.png", width: 800, height: 600)
    // 峰值 90 自动适配到上方最近的整刻度 100
    println(radar.resolvedRange()) // 输出: Bounds(0.000000, 100.000000)
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(spokes: Array<String>)`](#init) | 按辐条名创建雷达图面板；辐条至少三根。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`add(trace)`](#add) | 添加一条轨迹并原样返回，便于继续配置。 |
| [`spokeNames()`](#spokenames) | 返回辐条名称。 |
| [`allTraces()`](#alltraces) | 返回全部轨迹，按绘制顺序。 |
| [`resolvedRange()`](#resolvedrange) | 返回实际使用的径向量程——固定值，或从零到峰值上方最近整刻度的自动适配结果。 |
| [`draw(...)`](#draw) | 把标题、多边形网格环、辐条与标签、各轨迹和图例绘制到 `rect`。 |
| [`legendEntries(theme)`](#legendentries) | 返回图例条目，每条有标签的轨迹一条。 |
| [`toggleTrace(index)`](#toggletrace) | 切换下标为 `index` 的轨迹的显隐；下标有效时返回 `true`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`valueRange`](#valuerange) | 径向量程；`None` 时从零自动适配到最大值。 |
| [`rings`](#rings) | 标记径向标度的同心环数量。 |
| [`showGrid`](#showgrid) | 是否绘制多边形网格环。 |
| [`showSpokes`](#showspokes) | 是否绘制辐条本身。 |
| [`showRingLabels`](#showringlabels) | 是否沿第一根辐条为每个环标注数值。 |
| [`legend`](#legend) | 图例配置；位置在构造时预设为 `LegendPosition.OutsideRight`。 |

## 构造函数

### init

按辐条名创建雷达图面板；辐条至少三根。校验通过后把 `legend.position` 预设为 [LegendPosition](LegendPosition.md)`.OutsideRight`。

```cangjie
public init(spokes: Array<String>)
```

**参数**

- `spokes`: `Array<String>` — 辐条名称，按顺时针顺序，从十二点方向开始。

**异常**

- [`PlotException`](../core/PlotException.md) — 辐条少于三根：两根辐条退化成一条线，围不出面积。

## 方法

### add

添加一条轨迹并原样返回，便于继续配置。

```cangjie
public func add(trace: RadarTrace): RadarTrace
```

**参数**

- `trace`: [`RadarTrace`](RadarTrace.md) — 待添加的轨迹；值的数量须与辐条数一致。

**返回值** `RadarTrace` — 传入的轨迹本身。

**异常**

- `PlotException` — 轨迹的值数量与辐条数不一致。

### spokeNames

返回辐条名称。

```cangjie
public func spokeNames(): Array<String>
```

**返回值** `Array<String>` — 构造时传入的辐条名，按顺序。

### allTraces

返回全部轨迹，按绘制顺序。

```cangjie
public func allTraces(): ArrayList<RadarTrace>
```

**返回值** `ArrayList<RadarTrace>` — 已添加的轨迹。

### resolvedRange

返回实际使用的径向量程——固定值，或从零到峰值上方最近整刻度的自动适配结果。[`valueRange`](#valuerange) 已设置时原样返回；否则取所有可见轨迹的有限值峰值，把量程自动适配为从 0 到 [Ticks.nice](../core/Ticks.md#nice) 取整后的上界，让最外环落在整数刻度上。

```cangjie
public func resolvedRange(): Bounds
```

**返回值** [`Bounds`](../core/Bounds.md) — 径向量程；没有可见轨迹或峰值不为正时为 `Bounds(0.0, 1.0)`。

### draw

把标题、多边形网格环、辐条与标签、各轨迹和图例绘制到 `rect`。外置图例（`OutsideRight`、`OutsideBottom`）先从可用区域扣除自身空间，辐条标签在最外环之外另留边距；剩余半径不足 4 逻辑像素时直接返回，不绘制。

```cangjie
public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 目标画布。
- `rect`: `Rect` — 面板占据的矩形，逻辑像素。
- `theme`: [`Theme`](../core/Theme.md) — 网格、文字颜色与调色板的来源。

### legendEntries

返回图例条目，每条有标签的轨迹一条。色样为半透明填充块加一条轨迹颜色的横线；标签为空的轨迹跳过。

```cangjie
public func legendEntries(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 决定未显式着色轨迹的回退颜色。

**返回值** `Array<`[`LegendEntry`](../series/LegendEntry.md)`>` — 图例条目，按轨迹顺序。

### toggleTrace

切换下标为 `index` 的轨迹的显隐；下标有效时返回 `true`。图例点击（经 [Legend.entryAt](Legend.md#entryat)）就落到这里。

```cangjie
public func toggleTrace(index: Int64): Bool
```

**参数**

- `index`: `Int64` — 轨迹下标；负数或超出范围时返回 `false` 且不改动任何轨迹。

**返回值** `Bool` — 下标是否有效。

## 字段

### valueRange

径向量程；`None` 时从零自动适配到最大值。实际生效的量程由 [`resolvedRange`](#resolvedrange) 给出。

```cangjie
public var valueRange: ?Bounds = None
```

### rings

标记径向标度的同心环数量。小于 1 时按 1 环绘制。

```cangjie
public var rings: Int64 = 4
```

### showGrid

是否绘制多边形网格环。画成圆会错报多边形轨迹在辐条之间的数值，见上文"说明"。

```cangjie
public var showGrid: Bool = true
```

### showSpokes

是否绘制辐条本身。

```cangjie
public var showSpokes: Bool = true
```

### showRingLabels

是否沿第一根辐条为每个环标注数值。仅在 `showGrid` 开启时生效；数值按 [NumberFormat.compact](../core/NumberFormat.md#compact) 的紧凑格式标注。

```cangjie
public var showRingLabels: Bool = true
```

### legend

图例配置；位置在构造时预设为 `LegendPosition.OutsideRight`。

```cangjie
public let legend: Legend = Legend()
```

配置项见 [Legend](Legend.md)。

## 另请参阅

- [RadarTrace](RadarTrace.md)
- [Legend](Legend.md)
- [Figure.addPanel](../Figure.md#addpanel) —— 把面板加入图形
