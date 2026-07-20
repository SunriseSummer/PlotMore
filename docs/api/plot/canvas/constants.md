[plot](../../index.md) › [plot.canvas](index.md) › 常量与变量

# 常量与变量 — plot.canvas

### WEDGE_EDGE_WIDTH

[Canvas.fillWedge](Canvas.md#fillwedge) 沿不透明扇形边界重描的羽化抗锯齿笔画宽度（像素）。笔画居中于边界上，扇形因此每侧外扩其宽度的一半；在扇形之间留缝的调用方（[PieAxes.sliceGap](../axes/PieAxes.md#slicegap)）须为每道缝预算一个完整宽度。

```cangjie
public const WEDGE_EDGE_WIDTH: Float32 = 1.2
```

扇形填充本身是硬边三角形条带，唯一的抗锯齿来自整帧的超采样合成；用羽化笔画按此宽度沿边界重描，扇形外缘才读作平滑曲线——见 `Canvas.fillWedge` 的 `smoothEdge` 参数（半透明填充自动跳过重描）。
