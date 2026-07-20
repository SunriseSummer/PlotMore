[plot](../../index.md) › [plot.axes](index.md) › PieAxes

# PieAxes

`plot.axes` 中的 public class

饼图或环形图面板：把各切片的份额编码为扇形角度。[`innerRadius`](#innerradius) 大于零即为环形图。构造即校验数据，画不出来的输入当场抛出异常。

## 声明

```cangjie
public class PieAxes <: Panel
```

## 继承

- 父类：[Panel](Panel.md) —— 由其继承 `title` 字段与 `frame()`、`containsPixel()`。

## 说明

饼图把大小编码为角度，而人比较角度远不如比较长度准确；比较类别时 [BarSeries](../series/BarSeries.md) 是更好的默认选择。当信息是"部分与整体"且切片只有寥寥数片时，饼图才物有所值——[`donutLabel`](#donutlabel) 正为此而设：把总量放进环孔，让它直接可读。

角度一律为弧度，从十二点方向顺时针增长；[`startAngle`](#startangle) 与扇形绘制遵循同一约定。未显式指定颜色的切片按下标取主题调色板的对应槽位；[`legend`](#legend) 的位置在构造时预设为 [LegendPosition](LegendPosition.md)`.OutsideRight`。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.{PieAxes, PieSlice}

main(): Unit {
    let pie = PieAxes([
        PieSlice(42.0, label: "Chrome"),
        PieSlice(31.0, label: "Safari"),
        PieSlice(27.0, label: "Firefox")
    ])
    pie.innerRadius = 0.55    // 大于零：画成环形图
    pie.donutLabel = "100"    // 环孔里标出总量
    let figure = Figure("浏览器份额")
    figure.addPanel(pie)
    FigureExport.renderToPng(figure, "pie.png", width: 800, height: 600)
    println(pie.sum()) // 输出: 100.000000
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(slices: Array<PieSlice>)`](#init) | 按切片数组创建面板，构造即校验数据。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`allSlices()`](#allslices) | 返回切片，按绘制顺序。 |
| [`sum()`](#sum) | 返回全部切片值之和。 |
| [`fraction(index)`](#fraction) | 返回下标为 `index` 的切片占总量的份额，`0..1`。 |
| [`draw(...)`](#draw) | 把标题、扇形切片、标签、环孔标题与图例绘制到 `rect`。 |
| [`legendEntries(theme)`](#legendentries) | 返回图例条目，每个有名称的切片一条。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`innerRadius`](#innerradius) | 内半径，为外半径的分数，`0..1`；0 是饼图，约 0.5–0.6 是环形图。 |
| [`startAngle`](#startangle) | 第一个切片的起始角，弧度，从十二点方向顺时针。 |
| [`labelMode`](#labelmode) | 每个切片标签显示的内容。 |
| [`labelsOutside`](#labelsoutside) | 把标签放到环外并配引导线，而不是画在切片内部。 |
| [`labelThreshold`](#labelthreshold) | 份额低于此值的切片不加标签——文字放不下。 |
| [`percentDecimals`](#percentdecimals) | 百分比标签的小数位数。 |
| [`sliceGap`](#slicegap) | 相邻切片之间的可见像素间隙；细缝足以表达分隔而无需描边。 |
| [`donutLabel`](#donutlabel) | 绘制在环孔中的标题——放总量的天然位置。 |
| [`donutSublabel`](#donutsublabel) | `donutLabel` 下方较小的第二行。 |
| [`legend`](#legend) | 图例配置；位置在构造时预设为 `LegendPosition.OutsideRight`。 |

## 构造函数

### init

按切片数组创建面板，构造即校验数据。校验通过后把 `legend.position` 预设为 `LegendPosition.OutsideRight`。

```cangjie
public init(slices: Array<PieSlice>)
```

**参数**

- `slices`: `Array<`[`PieSlice`](PieSlice.md)`>` — 至少一个切片；每个值必须有限且非负，且总和大于零。

**异常**

- [`PlotException`](../core/PlotException.md) — `slices` 为空；任一切片值非有限；任一切片值为负（角度无法表达负份额，异常消息建议改用柱状图）；或全部值之和为零（没有可以取份额的整体）。

## 方法

### allSlices

返回切片，按绘制顺序。

```cangjie
public func allSlices(): Array<PieSlice>
```

**返回值** `Array<PieSlice>` — 构造时传入的切片数组。

### sum

返回全部切片值之和。

```cangjie
public func sum(): Float64
```

**返回值** `Float64` — 总量，构造校验保证大于零。

### fraction

返回下标为 `index` 的切片占总量的份额，`0..1`。

```cangjie
public func fraction(index: Int64): Float64
```

**参数**

- `index`: `Int64` — 切片下标，须在 `0..allSlices().size` 内。

**返回值** `Float64` — 份额；全部切片的份额之和为 1。

### draw

把标题、扇形切片、标签、环孔标题与图例绘制到 `rect`。外置图例（`OutsideRight`、`OutsideBottom`）先从可用区域扣除自身空间；[`labelsOutside`](#labelsoutside) 开启时四周再预留引导线与标签边距；剩余半径不足 2 逻辑像素时直接返回，不绘制。

```cangjie
public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit
```

**参数**

- `canvas`: [`Canvas`](../canvas/Canvas.md) — 目标画布。
- `rect`: `Rect` — 面板占据的矩形，逻辑像素。
- `theme`: [`Theme`](../core/Theme.md) — 文字颜色、调色板与图例样式的来源。

### legendEntries

返回图例条目，每个有名称的切片一条。色样为切片颜色的圆角色块；名称为空的切片跳过。

```cangjie
public func legendEntries(theme: Theme): Array<LegendEntry>
```

**参数**

- `theme`: `Theme` — 决定未显式着色切片的回退颜色。

**返回值** `Array<`[`LegendEntry`](../series/LegendEntry.md)`>` — 图例条目，按切片顺序。

## 字段

### innerRadius

内半径，为外半径的分数，`0..1`；0 是饼图，约 0.5–0.6 是环形图。绘制时超出 `0..1` 的值截取到该区间。

```cangjie
public var innerRadius: Float64 = 0.0
```

### startAngle

第一个切片的起始角，弧度，从十二点方向顺时针。

```cangjie
public var startAngle: Float64 = 0.0
```

### labelMode

每个切片标签显示的内容。取值见 [PieLabelMode](PieLabelMode.md)。

```cangjie
public var labelMode: PieLabelMode = PieLabelMode.NameAndPercent
```

### labelsOutside

把标签放到环外并配引导线，而不是画在切片内部。关闭（默认）时标签画在切片中部，文字颜色自动取与切片底色对比的颜色（[Colors.contrastText](../core/Colors.md#contrasttext)）。

```cangjie
public var labelsOutside: Bool = false
```

### labelThreshold

份额低于此值的切片不加标签——文字放不下。默认 `0.03`，即低于 3% 的切片不标。

```cangjie
public var labelThreshold: Float64 = 0.03
```

### percentDecimals

百分比标签的小数位数。格式化由 [NumberFormat.percent](../core/NumberFormat.md#percent) 完成。

```cangjie
public var percentDecimals: Int64 = 0
```

### sliceGap

相邻切片之间的可见像素间隙；细缝足以表达分隔而无需描边。扇形自带的平滑描边横跨切片边界，绘制时在此值上额外加一个 [WEDGE_EDGE_WIDTH](../canvas/constants.md#wedge_edge_width)，使该字段始终指*可见*间隔；间隙换算的角度以切片自身角度的四分之一为上限，极细的切片仍保持可见。

```cangjie
public var sliceGap: Float32 = 1.5
```

### donutLabel

绘制在环孔中的标题——放总量的天然位置。仅当 `innerRadius > 0.05` 时绘制；对（近似）实心的饼图忽略。

```cangjie
public var donutLabel: String = ""
```

### donutSublabel

`donutLabel` 下方较小的第二行。`donutLabel` 不绘制时它也不绘制。

```cangjie
public var donutSublabel: String = ""
```

### legend

图例配置；位置在构造时预设为 `LegendPosition.OutsideRight`。

```cangjie
public let legend: Legend = Legend()
```

配置项见 [Legend](Legend.md)。

## 另请参阅

- [PieSlice](PieSlice.md)
- [PieLabelMode](PieLabelMode.md)
- [Legend](Legend.md)
- [Figure.addPanel](../Figure.md#addpanel) —— 把面板加入图形
