[plot](../../index.md) › [plot.axes](index.md) › RadarTrace

# RadarTrace

`plot.axes` 中的 public class

雷达图的一条轨迹：每根辐条一个值，外加样式。值的数量必须与所属雷达图的辐条数一致，由 [RadarAxes.add](RadarAxes.md#add) 在加入时校验。

## 声明

```cangjie
public class RadarTrace
```

## 示例

```cangjie verify
package demo

import plot.{Figure, FigureExport}
import plot.axes.{RadarAxes, RadarTrace}
import plot.canvas.MarkerStyle

main(): Unit {
    let trace = RadarTrace([80.0, 60.0, 90.0], label: "车型 A")
    trace.fillOpacity = 0.35              // 加深多边形填充
    trace.marker = MarkerStyle.Diamond    // 顶点改用菱形标记
    let radar = RadarAxes(["速度", "功率", "续航"])
    radar.add(trace)
    let figure = Figure("车型对比")
    figure.addPanel(radar)
    FigureExport.renderToPng(figure, "radar-trace.png", width: 640, height: 480)
    println(trace.values.size) // 输出: 3
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(values: Array<Float64>, label!: String = "")`](#init) | 按各辐条的值创建轨迹，图例标签可选。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`values`](#values) | 各辐条上的值，按辐条顺序。 |
| [`label`](#label) | 图例标签；为空的轨迹不进图例。 |
| [`color`](#color) | 显式颜色；`None` 取主题调色板中与轨迹位置对应的槽位。 |
| [`fillOpacity`](#fillopacity) | 围合多边形的填充不透明度，`0..1`；0 只画轮廓。 |
| [`lineWidth`](#linewidth) | 轮廓宽度，逻辑像素。 |
| [`marker`](#marker) | 每个顶点处的标记符号。 |
| [`visible`](#visible) | 是否绘制该轨迹。 |

## 构造函数

### init

按各辐条的值创建轨迹，图例标签可选。样式字段（颜色、填充、线宽、标记）创建后可随时调整。

```cangjie
public init(values: Array<Float64>, label!: String = "")
```

**参数**

- `values`: `Array<Float64>` — 各辐条上的值，按辐条顺序；数量须与雷达图的辐条数一致。
- `label`: `String` — 图例标签；空字符串的轨迹不产生图例条目。默认 `""`。

## 字段

### values

各辐条上的值，按辐条顺序。

```cangjie
public let values: Array<Float64>
```

### label

图例标签；为空的轨迹不进图例。

```cangjie
public var label: String
```

### color

显式颜色；`None` 取主题调色板中与轨迹位置对应的槽位。调色板来自 [Theme](../core/Theme.md) 的 `palette` 字段。

```cangjie
public var color: ?Color = None
```

### fillOpacity

围合多边形的填充不透明度，`0..1`；0 只画轮廓。

```cangjie
public var fillOpacity: Float64 = 0.2
```

### lineWidth

轮廓宽度，逻辑像素。

```cangjie
public var lineWidth: Float32 = 2.0
```

### marker

每个顶点处的标记符号。取值见 [MarkerStyle](../canvas/MarkerStyle.md)；`NoMarker` 不画顶点标记。

```cangjie
public var marker: MarkerStyle = MarkerStyle.Circle
```

### visible

是否绘制该轨迹。关闭的轨迹不绘制、也不参与径向量程的自动适配，其图例条目保留原位并减淡显示；用 [RadarAxes.toggleTrace](RadarAxes.md#toggletrace) 可按下标切换。

```cangjie
public var visible: Bool = true
```

## 另请参阅

- [RadarAxes](RadarAxes.md)
- [MarkerStyle](../canvas/MarkerStyle.md)
