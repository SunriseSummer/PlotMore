[plot](../../index.md) › [plot.axes](index.md) › Annotation

# Annotation

`plot.axes` 中的 public class（抽象基类）

绘制在数据之上的记号的抽象基类——阈值线、高亮区间、数据点旁的文字。经 [Axes.annotate](Axes.md#annotate) 挂到面板上。

## 声明

```cangjie
public abstract class Annotation
```

## 继承

- 本项目内的已知子类：[HorizontalLine](HorizontalLine.md)、[VerticalLine](VerticalLine.md)、[VerticalSpan](VerticalSpan.md)、[HorizontalSpan](HorizontalSpan.md)、[TextNote](TextNote.md)。

## 说明

标注以**数据坐标**定位，因此缩放与平移时跟着数据走，而不是钉在某个固定像素上。它们在全部系列之后绘制（叠在数据上方），并被裁剪到面板的绘图矩形内。

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.{Annotation, HorizontalLine, VerticalSpan}
import plot.series.LineSeries

main(): Unit {
    let (figure, axes) = Figure.single(title: "响应阈值")
    axes.add(LineSeries([0.0, 1.0, 2.0, 3.0], [0.2, 0.9, 0.4, 0.7], label: "响应"))

    // 不同子类经同一入口挂载，绘制时多态分派
    let threshold: Annotation = HorizontalLine(0.8)
    axes.annotate(threshold)
    axes.annotate(VerticalSpan(1.0, 2.0))

    FigureExport.renderToPng(figure, "annotations.png", width: 800, height: 600)
    println(figure.panelCount()) // 输出: 1
    // 生成的图像包含阈值线与区间带。
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`draw(canvas, projection, theme)`](#draw) | 渲染这条标注；调用时面板裁剪已经生效。 |

## 方法

### draw

渲染这条标注；调用时面板裁剪已经生效。抽象方法：各子类把自己的数据坐标经投影换算成像素后绘制。

```cangjie
public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
```

**参数**

- `canvas`: `Canvas` — 绘制目标，见 [Canvas](../canvas/Canvas.md)。
- `projection`: `Projection` — 面板当前的数据↔像素变换，见 [Projection](../core/Projection.md)。
- `theme`: `Theme` — 未显式指定颜色时的取色来源，见 [Theme](../core/Theme.md)。

## 另请参阅

- [Axes.annotate](Axes.md#annotate) — 标注的挂载入口
- [HorizontalLine](HorizontalLine.md)、[VerticalLine](VerticalLine.md) — 参考线
- [VerticalSpan](VerticalSpan.md)、[HorizontalSpan](HorizontalSpan.md) — 着色条带
- [TextNote](TextNote.md) — 数据点旁的文字备注
