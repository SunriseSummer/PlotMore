# 添加阈值、区间和说明

## 目标

向进阶仪表板的趋势面板添加业务阈值线和事件区间，使读者知道何时越过上限、哪个时间段受发布影响。标注使用数据坐标，会随面板缩放和平移，但不会可靠地替你扩大自动范围。

![标注画廊结果；用于核对阈值线、区间底色和文字说明的层次](../../../examples/gallery/annotations.png)

画廊文件来自 `examples/src/composite.cj`，SHA-256 为 `c30b0b060bf3375aa17a6ab65208d0d969b195a675dba03717223231cabb3bd0`。

## 适用场景

适用于 SLO、目标线、发布窗口、异常区间和少量关键说明。若只是想给每个点贴值，优先考虑系列的值标签或悬停读数；大量文字会遮挡数据。此补丁建立在[进阶仪表板](../tutorials/advanced-dashboard.md)的 `buildDashboard` 上。

## 准备工作

先确认标注数值与面板使用相同单位：趋势面板横轴是日，纵轴是访问量。确定阈值 600、活动区间第 3 至第 4 天，并检查当前数据范围能看到阈值。下面新增导入并插入到 `trend.add(...)` 之后。

## 操作步骤

阈值线提供名称，区间使用较低透明度，避免压住折线。`annotate` 的返回值可忽略，但仍显式接收，便于仓颉代码保持清楚。

```cangjie role=patch
import plot.axes.{HorizontalLine, VerticalSpan}
import plot.core.Colors

let capacity = HorizontalLine(600.0)
capacity.label = "容量关注线 600"
capacity.color = Some(Colors.hex("#DC2626"))
let _ = trend.annotate(capacity)

let campaign = VerticalSpan(3.0, 4.0)
campaign.color = Some(Colors.hex("#F59E0B"))
campaign.opacity = 0.14
let _ = trend.annotate(campaign)
```

若需要指出一个具体异常点，可改为文字说明，并为文字设置像素偏移避免压住点。下面变化添加到散点 `quality` 面板，而不是继续给趋势面板堆标注。

```cangjie role=variation
import plot.axes.TextNote

let note = TextNote(146.0, 2.1, "检查高负载实例")
note.offsetX = 12.0
note.offsetY = -8.0
let _ = quality.annotate(note)
```

## 确认结果

运行仪表板后，趋势面板应看到横向红色阈值线及其标签，第 3 到第 4 天之间有半透明竖向区间，折线仍可读。缩放趋势面板，标注应跟随数据坐标。若添加文字变化，说明应锚定在散点附近，移动视图后仍指向同一数据位置。若阈值在画面外，显式调整 y 限制，而不是改阈值数值迎合画面。

## 常见错误

把像素坐标当数据坐标会让标注落在意外位置；透明度过高会遮住数据；同时给区间、边界线和文字都加长标签会互相重叠。标注通常不参与自动范围，远离系列的阈值可能不可见。另一个错误是用标注代替数据：关键事件来源仍应保存在业务数据或报告说明中。

## 相关 API

- [`Annotation`](../../api/plot/axes/Annotation.md)：所有普通坐标标注的共同接口。
- [`TextNote`](../../api/plot/axes/TextNote.md)：在数据位置附近放置文字说明。

## 下一步

完成标注后，继续[导出可交付 PNG](export-image.md)，在最终尺寸中检查说明是否仍可读。
