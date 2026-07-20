[plot](../../index.md) › [plot.series](index.md) › 函数

# 函数 — plot.series

### requireSameLength

校验成对的坐标数组长度一致，不一致时抛出异常。长度不匹配始终是调用方的错误；静默截断到较短数组只会画出一张微妙错误的图并把错误藏起来，因此异常消息同时给出两个长度。

```cangjie
public func requireSameLength(xs: Array<Float64>, ys: Array<Float64>, context: String): Unit
```

**参数**

- `xs`: `Array<Float64>` — 第一个数组。
- `ys`: `Array<Float64>` — 第二个数组。
- `context`: `String` — 异常消息中标识调用方的名称，如 `"LineSeries"`。

**异常**

- `PlotException` — `xs.size != ys.size` 时；消息包含 `context` 与两个长度。

### pairedBounds

返回成对坐标中有限数据点的 x、y 区间；一个有限点都没有时为 `None`。任一坐标非有限的点被整体跳过：有效 x 配上 NaN 的 y，不得把 x 区间拉伸到数据从未占据的空档。

```cangjie
public func pairedBounds(xs: Array<Float64>, ys: Array<Float64>): ?(Bounds, Bounds)
```

**参数**

- `xs`: `Array<Float64>` — x 坐标。
- `ys`: `Array<Float64>` — y 坐标，与 `xs` 按下标配对。

**返回值** `?(Bounds, Bounds)` — 数据坐标下的 ([Bounds](../core/Bounds.md) x 区间, y 区间)，或 `None`。

### plottableRuns

把成对坐标拆分成若干段连续可绘制的像素点。非有限的坐标、以及[投影](../core/Projection.md)的标度无法表达的值（对数轴上的零）都会结束当前段；把每段画成独立的折线，数据缺口才会呈现为缺口，而不是被一条直线跨接。

```cangjie
public func plottableRuns(
    xs: Array<Float64>,
    ys: Array<Float64>,
    projection: Projection
): ArrayList<ArrayList<Point>>
```

**参数**

- `xs`: `Array<Float64>` — x 坐标。
- `ys`: `Array<Float64>` — y 坐标，与 `xs` 按下标配对。
- `projection`: `Projection` — 提供数据到像素的变换与可表达性判断（`accepts`）。

**返回值** `ArrayList<ArrayList<Point>>` — 各段像素坐标点；每段至少一个点，不可绘制的位置不产生空段。

```cangjie
// NaN 把折线断成两段，每段 2 个点
let projection = Projection(Rect(0.0, 0.0, 400.0, 300.0),
    LinearScale(Bounds(0.0, 4.0)), LinearScale(Bounds(0.0, 5.0)))
let runs = plottableRuns([0.0, 1.0, 2.0, 3.0, 4.0],
    [1.0, 2.0, Float64.NaN, 3.0, 5.0], projection)
// runs.size == 2
```
