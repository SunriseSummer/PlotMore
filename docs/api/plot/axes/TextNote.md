[plot](../../index.md) › [plot.axes](index.md) › TextNote

# TextNote

`plot.axes` 中的 public class

锚定在某个数据点上的文字备注，可垫在半透明底衬上。锚点用数据坐标，随缩放与平移跟着数据走；文字相对锚点再偏移若干像素，好让开它所描述的点。经 [Axes.annotate](Axes.md#annotate) 挂到面板上。

## 声明

```cangjie
public class TextNote <: Annotation
```

## 继承

- 父类：[Annotation](Annotation.md)。

## 说明

备注在全部系列之后绘制并被裁剪到面板内。投影无法表达锚点（如对数轴上的非正值）或 `content` 为空时整体跳过。`boxed` 开启时先画一块按主题浮层色淡化的圆角底衬（chip），尺寸按实测文字外扩数像素，保证备注叠在数据上仍可读。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.TextNote
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "增益")
    axes.add(LineSeries([0.0, 1.0, 2.0, 3.0], [0.1, 0.9, 0.4, 0.2], label: "增益"))

    // 在峰值点旁加一条备注；默认向右上偏移并垫底衬
    let note = TextNote(1.0, 0.9, "峰值 0.9")
    note.offsetX = 10.0
    axes.annotate(note)

    FigureExport.renderToPng(figure, "text-note.png", width: 800, height: 600)
    println(note.boxed) // 输出: true
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(dataX, dataY, content)`](#init) | 在数据坐标 `(dataX, dataY)` 处创建内容为 `content` 的备注。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`draw(canvas, projection, theme)`](#draw) | 在锚点加偏移处绘制文字；投影无法表达锚点或内容为空时整体跳过。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`color`](#color) | 文字颜色；`None` 用主题的主文字色。 |
| [`offsetX`](#offsetx) | 锚点到文字的水平偏移，逻辑像素，默认 `8.0`。 |
| [`offsetY`](#offsety) | 锚点到文字的竖直偏移，逻辑像素，默认 `-8.0`（负值向上）。 |
| [`boxed`](#boxed) | 是否在文字下垫一块半透明圆角底衬，默认开。 |
| [`hAlign`](#halign) | 文字相对偏移后锚点的水平对齐，默认 `Left`。 |
| [`vAlign`](#valign) | 文字相对偏移后锚点的竖直对齐，默认 `Bottom`。 |

## 构造函数

### init

在数据坐标 `(dataX, dataY)` 处创建内容为 `content` 的备注。三者构造后不可更改。

```cangjie
public init(dataX: Float64, dataY: Float64, content: String)
```

**参数**

- `dataX`: `Float64` — 锚点的 x 值（数据坐标）。
- `dataY`: `Float64` — 锚点的 y 值（数据坐标）。
- `content`: `String` — 备注文字；为空时绘制阶段整体跳过。

## 方法

### draw

在锚点加偏移处绘制文字；投影无法表达锚点或内容为空时整体跳过。`boxed` 开启时先按实测文字尺寸画底衬，再画文字。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标，见 [Canvas](../canvas/Canvas.md)。
- `projection`: `Projection` — 面板当前的数据↔像素变换，见 [Projection](../core/Projection.md)。
- `theme`: `Theme` — `color` 为 `None` 时的取色来源，见 [Theme](../core/Theme.md)。

## 字段

### color

文字颜色；`None` 用主题的主文字色。

```cangjie
public var color: ?Color = None
```

### offsetX

锚点到文字的水平偏移，逻辑像素，默认 `8.0`。与 `offsetY` 一起让备注让开它所描述的点。

```cangjie
public var offsetX: Float32 = 8.0
```

### offsetY

锚点到文字的竖直偏移，逻辑像素，默认 `-8.0`（负值向上）。

```cangjie
public var offsetY: Float32 = -8.0
```

### boxed

是否在文字下垫一块半透明圆角底衬，默认开。底衬用主题浮层色（`surface`）按 90% 不透明度淡化，保证备注叠在数据上仍可读。

```cangjie
public var boxed: Bool = true
```

### hAlign

文字相对偏移后锚点的水平对齐，默认 `Left`。`Left` 让文字从锚点向右展开；取值见 [HAlign](../canvas/HAlign.md)。

```cangjie
public var hAlign: HAlign = HAlign.Left
```

### vAlign

文字相对偏移后锚点的竖直对齐，默认 `Bottom`。`Bottom` 让文字落在锚点上方；取值见 [VAlign](../canvas/VAlign.md)。

```cangjie
public var vAlign: VAlign = VAlign.Bottom
```

## 另请参阅

- [Annotation](Annotation.md)、[Axes.annotate](Axes.md#annotate)
- [HorizontalLine](HorizontalLine.md)、[VerticalSpan](VerticalSpan.md) — 其他标注形式
