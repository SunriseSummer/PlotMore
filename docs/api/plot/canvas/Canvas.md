[plot](../../index.md) › [plot.canvas](index.md) › Canvas

# Canvas

`plot.canvas` 中的 public class

所有图表类型赖以渲染的绘制词汇——填充、折线、标记、扇形与文本——架设在 `Renderer` 之上。条带类填充会缓存填充色纹理，Canvas 因此拥有 GPU 资源，用毕必须关闭；在无渲染设备（headless）的渲染器上，一切绘制入口都是空操作。

## 声明

```cangjie
public class Canvas <: Resource
```

## 继承

实现标准库接口 `Resource`（`isClosed`/`close`），可交由 try-with-resources 语法管理。

## 说明

**两条填充路径。** 多边形填充（`fillPolygon`：雷达轨迹、标记字形）走渲染器的 `fillConvexPolygon`——逐顶点着色、羽化抗锯齿、不涉及纹理。条带类填充（`fillBand`、`fillWedge` 与两种渐变填充）走 `texturedStrip`——由上下顶点对构成的四边形条带，因其横档结构无法扇形填充。该原语把顶点颜色固定为白色，而 `SDL_RenderGeometry` 忽略 `SDL_SetTextureColorMod`，填充色因此只能存放在纹素里：Canvas 为每种颜色缓存一张 1×1 纹理，每次填充取用对应的一张。逐顶点透明度仍然有效——渐变面积填充正是靠它实现；连续色标使用一张 256 纹素的查找渐变带。条带填充是唯一会分配资源的路径；多边形、线段、标记与矩形走渲染器自带的顶点着色路径，没有额外开销。

**填充色缓存上限。** 每种不同的填充色缓存一张纹理，上限 512 种（`SOLID_CACHE_LIMIT`）；耗尽后任何需要新颜色的条带类填充都会抛出 [PlotException](../core/PlotException.md)。上限只为防止病态调用（如逐点取色标颜色的面积填充）无限泄漏 GPU 对象——一张图形实际用到的系列颜色远少于此。逐点着色请改用标记或线条：它们携带真实的顶点颜色，从不占用该缓存。

**资源所有权。** Canvas 拥有缓存的纹理，必须调用 `close` 释放（幂等）。[PlotWindow](../PlotWindow.md) 会代为关闭；仅当自行驱动渲染循环时才直接构造 Canvas。

**headless 行为。** 在 `Renderer.headless()` 上，所有绘制入口都是空操作，布局、测量与事件处理无需窗口即可运行——这正是本库自身测试的方式。渲染器的原语在无设备时本就静默跳过，但填充要先构建纹理，而 `textureFromSurface` 在空设备上会抛出异常而非跳过，因此各填充方法在参数校验之后、构建纹理之前提前返回：`fillBand`/`fillBandGradient` 对不等长边界的 `PlotException` 在 headless 下依然抛出。

## 示例

```cangjie verify
package demo

import std.collection.ArrayList
import plot.canvas.{Canvas, MarkerStyle}
import plot.core.{Color, Pen, Point, Rect, Renderer}

main(): Unit {
    // 无渲染设备（headless）的画布：绘制入口全部为空操作，适合测试与布局
    let canvas = Canvas(Renderer.headless())
    canvas.fillRect(Rect(0.0, 0.0, 320.0, 200.0), Color.rgb(248, 249, 250))
    let path = ArrayList<Point>([Point(40.0, 160.0), Point(120.0, 60.0), Point(200.0, 100.0), Point(280.0, 40.0)])
    canvas.polyline(path, Pen(width: 2.0, color: Color.rgb(31, 119, 180)))
    canvas.marker(MarkerStyle.Circle, 120.0, 60.0, 4.0, Color.rgb(31, 119, 180))
    canvas.text("月度销量", 40.0, 16.0, Color.rgb(60, 60, 60), size: 16.0)
    println("headless=${canvas.isHeadless()}") // 输出: headless=true
    canvas.close()
    println("closed=${canvas.isClosed()}") // 输出: closed=true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 在给定渲染器上创建画布。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`renderer()`](#renderer) | 返回底层渲染器。 |
| [`isHeadless()`](#isheadless) | 画布是否没有渲染设备（headless），此时填充会被跳过。 |
| [`fillBand(...)`](#fillband) | 在两条等长像素边界之间填充条带。 |
| [`fillPolygon(...)`](#fillpolygon) | 以首个顶点为扇心填充多边形。 |
| [`fillWedge(...)`](#fillwedge) | 填充环形扇形：从 `startAngle` 到 `endAngle`、介于内外半径之间的扇形段。 |
| [`fillBandGradient(...)`](#fillbandgradient) | 填充颜色沿横档跟随色标变化的条带。 |
| [`fillRect(...)`](#fillrect) | 填充轴对齐矩形。 |
| [`fillRoundedRect(...)`](#fillroundedrect) | 填充圆角矩形；半径为零时退化为普通矩形填充。 |
| [`fillPerCornerRect(...)`](#fillpercornerrect) | 填充四角半径各自独立的矩形——用于堆叠柱的端帽。 |
| [`fillRectGradient(...)`](#fillrectgradient) | 填充纵向或横向渐变的矩形。 |
| [`fillSoftRect(...)`](#fillsoftrect) | 填充边缘在 `feather` 个像素内淡出的圆角矩形——软阴影原语。 |
| [`fillCircle(...)`](#fillcircle) | 填充圆。 |
| [`line(...)`](#line) | 绘制一条抗锯齿的圆头线段。 |
| [`polyline(...)`](#polyline) | 以圆头线段依次连接 `points`，任意夹角下接头无缺口。 |
| [`dashedPolyline(...)`](#dashedpolyline) | 以虚线描边连接 `points`，开/关花纹跨线段边界连续推进。 |
| [`styledPolyline(...)`](#styledpolyline) | 按给定线型描边 `points`；`NoLine` 线型不绘制。 |
| [`strokeRect(...)`](#strokerect) | 描边矩形轮廓。 |
| [`strokeRoundedRect(...)`](#strokeroundedrect) | 描边圆角矩形轮廓。 |
| [`strokeCircle(...)`](#strokecircle) | 描边圆轮廓。 |
| [`arc(...)`](#arc) | 描边圆弧，采样密度足以在半径 `radius` 下读作平滑曲线。 |
| [`marker(...)`](#marker) | 在数据点上居中绘制一个标记字形。 |
| [`text(...)`](#text) | 以 `(x, y)` 为左上角绘制文本。 |
| [`textAnchored(...)`](#textanchored) | 按两个对齐方式把文本锚定在 `(x, y)` 绘制。 |
| [`textCentered(...)`](#textcentered) | 在矩形内居中绘制文本。 |
| [`textRotated(...)`](#textrotated) | 绘制以 `(centerX, centerY)` 为中心、旋转 `angleDegrees` 度的文本。 |
| [`textStacked(...)`](#textstacked) | 把文本逐字符竖排绘制，水平居中于 `x`、自 `y` 起向下。 |
| [`textWidth(...)`](#textwidth) | 返回 `content` 在字号 `size` 下的渲染宽度。 |
| [`textHeight(...)`](#textheight) | 返回字号 `size` 下的行高。 |
| [`stackedTextHeight(...)`](#stackedtextheight) | 返回一次 `textStacked` 调用将占据的高度。 |
| [`pushClip(...)`](#pushclip) | 把绘制范围收窄为 `rect` 与现有裁剪区的交集。 |
| [`popClip()`](#popclip) | 恢复到匹配的 `pushClip` 之前的裁剪区。 |
| [`isClosed()`](#isclosed) | 画布是否已关闭。 |
| [`close()`](#close) | 释放所有缓存的填充纹理。 |

## 构造函数

### init

在给定渲染器上创建画布。通过 `renderer.driverName()` 是否为 `"headless"` 判定画布有无渲染设备。一般随 [PlotWindow](../PlotWindow.md) 一起创建并由其关闭；仅当自行驱动渲染循环时才直接构造。

```cangjie
public init(renderer: Renderer)
```

**参数**

- `renderer`: `Renderer` — 承接所有绘制原语的底层渲染器；传入 `Renderer.headless()` 得到无渲染设备的画布。

## 方法

### renderer

返回底层渲染器。仅当需要 Canvas 尚未封装的渲染原语时使用。

```cangjie
public func renderer(): Renderer
```

**返回值** `Renderer` — 构造时传入的渲染器。

### isHeadless

画布是否没有渲染设备（headless），此时填充会被跳过。供自行驱动渲染循环的调用方区分 headless 画布与真实画布；图表类型自身不需要它——每个绘制入口在 headless 下本就是空操作。

```cangjie
public func isHeadless(): Bool
```

**返回值** `Bool` — 在 `Renderer.headless()` 上构造时为 `true`。

### fillBand

在两条等长像素边界之间填充条带。这是最通用的填充：第 i 个采样点处从 `upper[i]` 连向 `lower[i]` 形成一根横档——面积图（[AreaSeries](../series/AreaSeries.md)）传入系列与基线，小提琴图（[ViolinSeries](../series/ViolinSeries.md)）传入两条镜像的密度曲线，置信条带传入上下包络。边界无需 x 单调，但每根横档独立填充，只有相邻横档不交叉时形状才有明确定义。

`upperAlpha`/`lowerAlpha` 沿每根横档做透明度渐变，面积图向基线淡出的效果即来于此。少于两个采样点时不绘制任何内容；headless 下在参数校验后直接返回。

```cangjie
public func fillBand(upper: ArrayList<Point>, lower: ArrayList<Point>, color: Color, upperAlpha!: Float32 = 1.0, lowerAlpha!: Float32 = 1.0): Unit
```

**参数**

- `upper`: `ArrayList<Point>` — 上边界的像素坐标序列。
- `lower`: `ArrayList<Point>` — 下边界的像素坐标序列；长度必须与 `upper` 相同。
- `color`: `Color` — 填充色。
- `upperAlpha!`: `Float32` — 上边界处的不透明度；默认 `1.0`。
- `lowerAlpha!`: `Float32` — 下边界处的不透明度；默认 `1.0`。

**异常**

- `PlotException` — 两条边界长度不同（headless 下同样抛出）。

### fillPolygon

以首个顶点为扇心填充多边形。对凸多边形、以及关于 `points[0]` 呈星形（star-shaped）的凹多边形都正确——这覆盖了图表实际构造的形状（扇形、雷达多边形、闭合面积）。一般凹多边形需要真正的三角剖分，不受支持；请改用 `fillBand`，其横档结构可直接表达这类形状。

委托给渲染器的 `fillConvexPolygon`：边缘做解析式羽化抗锯齿、逐顶点着色、不涉及纹理，因此不占用填充色缓存。

```cangjie
public func fillPolygon(points: ArrayList<Point>, color: Color): Unit
```

**参数**

- `points`: `ArrayList<Point>` — 多边形顶点的像素坐标序列。
- `color`: `Color` — 填充色。

### fillWedge

填充环形扇形：从 `startAngle` 到 `endAngle`、介于内外半径之间的扇形段。角度为弧度制，自十二点钟方向顺时针计。`innerRadius` 为零得到实心饼图切片，更大则得到环形图段，负值按零处理；`outerRadius` 不为正时不绘制任何内容。

`smoothEdge`（默认开启）用填充色沿扇形边界重描一圈，笔宽为 [WEDGE_EDGE_WIDTH](constants.md#wedge_edge_width)，笔画居中于边界，扇形因此每侧外扩其宽度的一半。填充本身是硬边三角形条带，唯一的抗锯齿来自整帧的超采样合成，饱和色切片贴着浅色面板仍会露出阶梯；重描的笔画是羽化的胶囊网格，沿边界描一圈才让外缘读作平滑曲线。填充色半透明时自动跳过重描，否则边缘处双重叠加的 alpha 会形成一圈可见的深色轮廓。

```cangjie
public func fillWedge(centerX: Float32, centerY: Float32, innerRadius: Float32, outerRadius: Float32, startAngle: Float64, endAngle: Float64, color: Color, smoothEdge!: Bool = true): Unit
```

**参数**

- `centerX`: `Float32` — 圆心 x（像素坐标）。
- `centerY`: `Float32` — 圆心 y（像素坐标）。
- `innerRadius`: `Float32` — 内半径（像素）；零为实心切片，负值按零处理。
- `outerRadius`: `Float32` — 外半径（像素）；不为正时不绘制。
- `startAngle`: `Float64` — 起始角（弧度，自十二点钟方向顺时针）。
- `endAngle`: `Float64` — 终止角（弧度，同一约定）。
- `color`: `Color` — 填充色。
- `smoothEdge!`: `Bool` — 是否沿边界重描以平滑外缘；默认 `true`；填充色不完全不透明（alpha 不为 255）时自动跳过。

### fillBandGradient

填充颜色沿横档跟随色标变化的条带。取色从第一个采样点的 `fromT` 推进到最后一个采样点的 `toT`（超出 [0, 1] 的部分截断），色标为 [Colormap](../core/Colormap.md)。条带原语的顶点颜色固定为白色，真正的多色渐变只能来自纹理：本方法为色标构建一张 256 档查找纹理并让纹理坐标沿它推进；采样落在纹素中心，相邻色档不会互相渗色。

查找纹理按色标在 0、0.5、1 三处的采样值作键缓存，采样一致的两个色标共享一张纹理——绘制循环里反复调用 `Colormap.viridis()` 因此没有代价。少于两个采样点时不绘制任何内容；headless 下在参数校验后直接返回。

```cangjie
public func fillBandGradient(upper: ArrayList<Point>, lower: ArrayList<Point>, map: Colormap, fromT!: Float64 = 0.0, toT!: Float64 = 1.0, upperAlpha!: Float32 = 1.0, lowerAlpha!: Float32 = 1.0): Unit
```

**参数**

- `upper`: `ArrayList<Point>` — 上边界的像素坐标序列。
- `lower`: `ArrayList<Point>` — 下边界的像素坐标序列；长度必须与 `upper` 相同。
- `map`: `Colormap` — 沿条带取色的色标。
- `fromT!`: `Float64` — 第一个采样点的色标位置；超出 [0, 1] 截断；默认 `0.0`。
- `toT!`: `Float64` — 最后一个采样点的色标位置；超出 [0, 1] 截断；默认 `1.0`。
- `upperAlpha!`: `Float32` — 上边界处的不透明度；默认 `1.0`。
- `lowerAlpha!`: `Float32` — 下边界处的不透明度；默认 `1.0`。

**异常**

- `PlotException` — 两条边界长度不同（headless 下同样抛出）。

### fillRect

填充轴对齐矩形。

```cangjie
public func fillRect(rect: Rect, color: Color): Unit
```

**参数**

- `rect`: `Rect` — 要填充的矩形（像素坐标）。
- `color`: `Color` — 填充色。

### fillRoundedRect

填充圆角矩形；半径为零时退化为普通矩形填充。

```cangjie
public func fillRoundedRect(rect: Rect, radius: Float32, color: Color): Unit
```

**参数**

- `rect`: `Rect` — 要填充的矩形。
- `radius`: `Float32` — 圆角半径（像素）。
- `color`: `Color` — 填充色。

### fillPerCornerRect

填充四角半径各自独立的矩形——用于堆叠柱的端帽。

```cangjie
public func fillPerCornerRect(rect: Rect, color: Color, topLeft!: Float32, topRight!: Float32, bottomRight!: Float32, bottomLeft!: Float32): Unit
```

**参数**

- `rect`: `Rect` — 要填充的矩形。
- `color`: `Color` — 填充色。
- `topLeft!`: `Float32` — 左上角半径（像素）。
- `topRight!`: `Float32` — 右上角半径（像素）。
- `bottomRight!`: `Float32` — 右下角半径（像素）。
- `bottomLeft!`: `Float32` — 左下角半径（像素）。

### fillRectGradient

填充纵向或横向渐变的矩形。颜色自 `from` 渐变到 `to`，圆角由 `radius` 控制。

```cangjie
public func fillRectGradient(rect: Rect, radius: Float32, from: Color, to: Color, vertical!: Bool = true): Unit
```

**参数**

- `rect`: `Rect` — 要填充的矩形。
- `radius`: `Float32` — 圆角半径（像素）。
- `from`: `Color` — 渐变起点颜色。
- `to`: `Color` — 渐变终点颜色。
- `vertical!`: `Bool` — `true` 为纵向渐变，`false` 为横向；默认 `true`。

### fillSoftRect

填充边缘在 `feather` 个像素内淡出的圆角矩形——软阴影原语。

```cangjie
public func fillSoftRect(rect: Rect, radius: Float32, color: Color, feather!: Float32): Unit
```

**参数**

- `rect`: `Rect` — 要填充的矩形。
- `radius`: `Float32` — 圆角半径（像素）。
- `color`: `Color` — 填充色。
- `feather!`: `Float32` — 边缘淡出的宽度（像素）。

### fillCircle

填充圆。

```cangjie
public func fillCircle(centerX: Float32, centerY: Float32, radius: Float32, color: Color): Unit
```

**参数**

- `centerX`: `Float32` — 圆心 x（像素坐标）。
- `centerY`: `Float32` — 圆心 y（像素坐标）。
- `radius`: `Float32` — 半径（像素）。
- `color`: `Color` — 填充色。

### line

绘制一条抗锯齿的圆头线段。

```cangjie
public func line(x1: Float32, y1: Float32, x2: Float32, y2: Float32, pen: Pen): Unit
```

**参数**

- `x1`: `Float32` — 起点 x（像素坐标）。
- `y1`: `Float32` — 起点 y（像素坐标）。
- `x2`: `Float32` — 终点 x（像素坐标）。
- `y2`: `Float32` — 终点 y（像素坐标）。
- `pen`: `Pen` — 笔画（宽度与颜色）。

### polyline

以圆头线段依次连接 `points`，任意夹角下接头无缺口。少于两个点时不绘制任何内容。

```cangjie
public func polyline(points: ArrayList<Point>, pen: Pen): Unit
```

**参数**

- `points`: `ArrayList<Point>` — 折线顶点的像素坐标序列。
- `pen`: `Pen` — 笔画（宽度与颜色）。

### dashedPolyline

以虚线描边连接 `points`，开/关花纹跨线段边界连续推进。花纹节奏不会在每个顶点重启——多段短线段的折线与一条长路径的虚线效果一致。`dash` 或 `gap` 不为正时整体退化为实线 `polyline`；零长线段被跳过。

```cangjie
public func dashedPolyline(points: ArrayList<Point>, pen: Pen, dash: Float32, gap: Float32): Unit
```

**参数**

- `points`: `ArrayList<Point>` — 折线顶点的像素坐标序列。
- `pen`: `Pen` — 笔画（宽度与颜色）。
- `dash`: `Float32` — 每段划线的长度（像素）；不为正时退化为实线。
- `gap`: `Float32` — 划线之间的间隔（像素）；不为正时退化为实线。

### styledPolyline

按给定线型描边 `points`；`NoLine` 线型不绘制。虚线类线型经 [LineStyle.dashPattern](LineStyle.md#dashpattern) 以 `pen.width` 换算出花纹后走 `dashedPolyline`，连续线型走 `polyline`。

```cangjie
public func styledPolyline(points: ArrayList<Point>, pen: Pen, style: LineStyle): Unit
```

**参数**

- `points`: `ArrayList<Point>` — 折线顶点的像素坐标序列。
- `pen`: `Pen` — 笔画（宽度与颜色）。
- `style`: `LineStyle` — 线型；虚线花纹按 `pen.width` 的倍数换算。

### strokeRect

描边矩形轮廓。

```cangjie
public func strokeRect(rect: Rect, pen: Pen): Unit
```

**参数**

- `rect`: `Rect` — 要描边的矩形。
- `pen`: `Pen` — 笔画（宽度与颜色）。

### strokeRoundedRect

描边圆角矩形轮廓。

```cangjie
public func strokeRoundedRect(rect: Rect, radius: Float32, pen: Pen): Unit
```

**参数**

- `rect`: `Rect` — 要描边的矩形。
- `radius`: `Float32` — 圆角半径（像素）。
- `pen`: `Pen` — 笔画（宽度与颜色）。

### strokeCircle

描边圆轮廓。

```cangjie
public func strokeCircle(centerX: Float32, centerY: Float32, radius: Float32, pen: Pen): Unit
```

**参数**

- `centerX`: `Float32` — 圆心 x（像素坐标）。
- `centerY`: `Float32` — 圆心 y（像素坐标）。
- `radius`: `Float32` — 半径（像素）。
- `pen`: `Pen` — 笔画（宽度与颜色）。

### arc

描边圆弧，采样密度足以在半径 `radius` 下读作平滑曲线。角度约定与 `fillWedge` 相同：弧度制，自十二点钟方向顺时针计。

```cangjie
public func arc(centerX: Float32, centerY: Float32, radius: Float32, startAngle: Float64, endAngle: Float64, pen: Pen): Unit
```

**参数**

- `centerX`: `Float32` — 圆心 x（像素坐标）。
- `centerY`: `Float32` — 圆心 y（像素坐标）。
- `radius`: `Float32` — 半径（像素）。
- `startAngle`: `Float64` — 起始角（弧度，自十二点钟方向顺时针）。
- `endAngle`: `Float64` — 终止角（弧度，同一约定）。
- `pen`: `Pen` — 笔画（宽度与颜色）。

### marker

在数据点上居中绘制一个标记字形。`size` 为外接圆半径，不同形状因此保持相近的视觉分量。实心形状以 `color` 填充并把 `edge` 作为轮廓描边；描边形状（`Cross`、`Plus`、`Ring`）没有内部，直接以 `edge` 给定的笔画绘制，省略时使用颜色为 `color`、宽度为 `max(1.2, size × 0.45)` 的默认笔画。[MarkerStyle](MarkerStyle.md) 为 `NoMarker` 或 `size` 不为正时不绘制任何内容。

```cangjie
public func marker(style: MarkerStyle, x: Float32, y: Float32, size: Float32, color: Color, edge!: ?Pen = None): Unit
```

**参数**

- `style`: `MarkerStyle` — 标记形状。
- `x`: `Float32` — 字形中心 x（像素坐标）。
- `y`: `Float32` — 字形中心 y（像素坐标）。
- `size`: `Float32` — 外接圆半径（像素）；不为正时不绘制。
- `color`: `Color` — 实心形状的填充色，也是描边形状省略 `edge` 时的笔画颜色。
- `edge!`: `?Pen` — 实心形状的轮廓笔画，描边形状直接以它绘制；默认 `None`（实心形状不描边）。

### text

以 `(x, y)` 为左上角绘制文本。

```cangjie
public func text(content: String, x: Float32, y: Float32, color: Color, size!: Float32 = 13.0, style!: FontStyle = FontStyle.regular): Unit
```

**参数**

- `content`: `String` — 要绘制的文本。
- `x`: `Float32` — 左上角 x（像素坐标）。
- `y`: `Float32` — 左上角 y（像素坐标）。
- `color`: `Color` — 文本颜色。
- `size!`: `Float32` — 字号；默认 `13.0`。
- `style!`: `FontStyle` — 字体样式；默认 `FontStyle.regular`。

### textAnchored

按两个对齐方式把文本锚定在 `(x, y)` 绘制。先测量文本宽高，再按 [HAlign](HAlign.md)/[VAlign](VAlign.md) 把锚点对到文本的相应边缘或中心。`content` 为空时不绘制任何内容。

```cangjie
public func textAnchored(content: String, x: Float32, y: Float32, color: Color, size!: Float32 = 13.0, hAlign!: HAlign = HAlign.Left, vAlign!: VAlign = VAlign.Top, style!: FontStyle = FontStyle.regular): Unit
```

**参数**

- `content`: `String` — 要绘制的文本；为空时不绘制。
- `x`: `Float32` — 锚点 x（像素坐标）。
- `y`: `Float32` — 锚点 y（像素坐标）。
- `color`: `Color` — 文本颜色。
- `size!`: `Float32` — 字号；默认 `13.0`。
- `hAlign!`: `HAlign` — 锚点落在文本的左缘、水平中心还是右缘；默认 `HAlign.Left`。
- `vAlign!`: `VAlign` — 锚点落在文本的顶缘、垂直中心还是底缘；默认 `VAlign.Top`。
- `style!`: `FontStyle` — 字体样式；默认 `FontStyle.regular`。

### textCentered

在矩形内居中绘制文本。

```cangjie
public func textCentered(content: String, rect: Rect, color: Color, size!: Float32 = 13.0, style!: FontStyle = FontStyle.regular): Unit
```

**参数**

- `content`: `String` — 要绘制的文本。
- `rect`: `Rect` — 文本在其中居中的矩形（像素坐标）。
- `color`: `Color` — 文本颜色。
- `size!`: `Float32` — 字号；默认 `13.0`。
- `style!`: `FontStyle` — 字体样式；默认 `FontStyle.regular`。

### textRotated

绘制以 `(centerX, centerY)` 为中心、旋转 `angleDegrees` 度的文本。顺时针为正，-90 度自下而上——这是旋转轴标题背后的原语。渲染器把字符串一次性栅格化进缓存纹理，再经旋转纹理管线绘制，静态旋转标签只花费一次栅格化而非每帧一次。headless 或空文本时为空操作。

```cangjie
public func textRotated(content: String, centerX: Float32, centerY: Float32, angleDegrees: Float64, color: Color, size!: Float32 = 13.0, style!: FontStyle = FontStyle.regular): Unit
```

**参数**

- `content`: `String` — 要绘制的文本；为空时不绘制。
- `centerX`: `Float32` — 旋转中心 x（像素坐标）。
- `centerY`: `Float32` — 旋转中心 y（像素坐标）。
- `angleDegrees`: `Float64` — 旋转角（度，顺时针为正；-90 自下而上）。
- `color`: `Color` — 文本颜色。
- `size!`: `Float32` — 字号；默认 `13.0`。
- `style!`: `FontStyle` — 字体样式；默认 `FontStyle.regular`。

### textStacked

把文本逐字符竖排绘制，水平居中于 `x`、自 `y` 起向下。[Axes](../axes/Axes.md) 在 `LabelOrientation.Stacked` 下用它排列中日韩文字；默认的 `Vertical` 方向则调用 [`textRotated`](#textrotated) 把整行标题旋转 -90 度，`Horizontal` 把标题横排在坐标轴上方。

按 rune 而非字节逐字符排布，多字节字符不会被拆开；空格前进半行，其余字符前进 0.92 倍行高。`content` 为空时不绘制任何内容。

```cangjie
public func textStacked(content: String, x: Float32, y: Float32, color: Color, size!: Float32 = 13.0, style!: FontStyle = FontStyle.regular): Unit
```

**参数**

- `content`: `String` — 要竖排的文本；为空时不绘制。
- `x`: `Float32` — 每个字符水平居中的 x（像素坐标）。
- `y`: `Float32` — 首个字符的顶部 y（像素坐标）。
- `color`: `Color` — 文本颜色。
- `size!`: `Float32` — 字号；默认 `13.0`。
- `style!`: `FontStyle` — 字体样式；默认 `FontStyle.regular`。

### textWidth

返回 `content` 在字号 `size` 下的渲染宽度。

```cangjie
public func textWidth(content: String, size!: Float32 = 13.0, style!: FontStyle = FontStyle.regular): Float32
```

**参数**

- `content`: `String` — 要测量的文本。
- `size!`: `Float32` — 字号；默认 `13.0`。
- `style!`: `FontStyle` — 字体样式；默认 `FontStyle.regular`。

**返回值** `Float32` — 渲染宽度（像素）。

### textHeight

返回字号 `size` 下的行高。

```cangjie
public func textHeight(size!: Float32 = 13.0, style!: FontStyle = FontStyle.regular): Float32
```

**参数**

- `size!`: `Float32` — 字号；默认 `13.0`。
- `style!`: `FontStyle` — 字体样式；默认 `FontStyle.regular`。

**返回值** `Float32` — 行高（像素）。

### stackedTextHeight

返回一次 `textStacked` 调用将占据的高度。按每个字符一行估算：rune 数 × 行高 × 0.92（`textStacked` 中空格实际只前进半行，含空格的文本此估计略偏大）。空字符串返回 `0.0`。

```cangjie
public func stackedTextHeight(content: String, size!: Float32 = 13.0): Float32
```

**参数**

- `content`: `String` — 要竖排的文本。
- `size!`: `Float32` — 字号；默认 `13.0`。

**返回值** `Float32` — 竖排占据的高度（像素）。

### pushClip

把绘制范围收窄为 `rect` 与现有裁剪区的交集。与 `popClip` 配对使用。

```cangjie
public func pushClip(rect: Rect): Unit
```

**参数**

- `rect`: `Rect` — 新的裁剪矩形（像素坐标），与当前生效的裁剪区取交集。

### popClip

恢复到匹配的 `pushClip` 之前的裁剪区。

```cangjie
public func popClip(): Unit
```

### isClosed

画布是否已关闭。

```cangjie
public func isClosed(): Bool
```

**返回值** `Bool` — `close` 调用过后为 `true`。

### close

释放所有缓存的填充纹理。幂等：重复调用是空操作，不会重复释放。

```cangjie
public func close(): Unit
```

## 另请参阅

- [`LineStyle`](LineStyle.md) — 折线的线型
- [`MarkerStyle`](MarkerStyle.md) — 标记字形
- [`WEDGE_EDGE_WIDTH`](constants.md#wedge_edge_width) — 扇形边界重描的笔宽
- [`PlotWindow`](../PlotWindow.md) — 拥有并自动关闭画布的窗口
