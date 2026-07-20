[plot](../../index.md) › [plot.core](index.md) › LogScale

# LogScale

`plot.core` 中的 public class

以 10 为底的对数轴，用于跨多个数量级的数据。零与负值在对数轴上没有位置：与其悄悄丢弃，[`setDomain`](#setdomain) 直接拒绝非正定义域，[`accepts`](#accepts) 报告哪些值可以绘制，让调用方自行决定过滤数据还是改用线性标度。

## 声明

```cangjie
public class LogScale <: Scale
```

## 继承

父类为 [`Scale`](Scale.md)；除 `domain()` 按原样继承外，其余开放成员均被覆盖为对数几何下的行为。

## 说明

接受原始区间的方法（[`niceBounds`](#nicebounds)、[`padBounds`](#padbounds)、[`zoomAround`](#zoomaround)、[`panByFraction`](#panbyfraction)）先把区间钳制为正：下界不大于零而上界为正时，下界提升为上界的 `1e-6` 倍（最大值之下六个十倍程——系列绘制时本就跳过非正点，而自动适配报告的是原始数据范围，无从知道它会落在对数轴上）；整个区间都不为正时抛出 [`PlotException`](PlotException.md)。

## 示例

```cangjie verify
package demo

import plot.core.{Bounds, LogScale, PlotException}

main(): Unit {
    let scale = LogScale(Bounds(1.0, 1000.0))
    println(scale.accepts(0.0))        // 输出: false
    println(scale.niceDomain())        // 输出: Bounds(1.000000, 1000.000000)

    // 每个十倍程内的 2…9 次刻度默认开启
    println(scale.ticks().size)        // 输出: 28
    scale.setMinorTicks(false)
    println(scale.ticks().size)        // 输出: 4

    // 非正定义域在对数轴上无法表达，直接被拒绝
    try {
        scale.setDomain(Bounds(0.0, 100.0))
    } catch (_: PlotException) {
        println("已拒绝非正定义域")     // 输出: 已拒绝非正定义域
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建对数标度：无参形式使用定义域 `[1, 10]`，带参形式要求 `domain` 严格为正。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`setMinorTicks(enabled: Bool)`](#setminorticks) | 设定是否绘制每个十倍程内 2…9 的次刻度。 |
| [`setDomain(bounds: Bounds)`](#setdomain) | 替换定义域；到达零或以下的区间被拒绝。 |
| [`normalize(value: Float64)`](#normalize) | 把值按其在定义域对数空间中的位置映射到 `0..1`；非正值一律返回 `0.0`。 |
| [`denormalize(t: Float64)`](#denormalize) | `normalize` 的逆变换，把归一化位置还原为数据值。 |
| [`ticks()`](#ticks) | 返回覆盖当前定义域的十倍程刻度，含可选的次刻度。 |
| [`niceDomain()`](#nicedomain) | 返回向外圆整到整十倍程的定义域。 |
| [`niceBounds(bounds: Bounds)`](#nicebounds) | 返回钳制为正后向外圆整到整十倍程的给定区间。 |
| [`padBounds(bounds: Bounds, fraction: Float64)`](#padbounds) | 乘法式留白：范围按其十倍程跨度的 `fraction` 增长，不会越过零。 |
| [`zoomAround(bounds: Bounds, pivot: Float64, factor: Float64)`](#zoomaround) | 在对数空间缩放，锚点保持在光标下，结果不会越过零。 |
| [`panByFraction(bounds: Bounds, fraction: Float64)`](#panbyfraction) | 在对数空间平移可见十倍程数的 `fraction`；结果不会到达零。 |
| [`accepts(value: Float64)`](#accepts) | 当 `value` 为严格为正的有限值时返回 `true`。 |

## 构造函数

### init

创建对数标度：无参形式使用定义域 `[1, 10]`，带参形式要求 `domain` 严格为正。

```cangjie
public init()
```

```cangjie
public init(domain: Bounds)
```

**参数**（第二个重载）

- `domain`: [`Bounds`](Bounds.md) — 初始定义域，`low` 必须大于零。

**异常**（第二个重载）

- [`PlotException`](PlotException.md) — `domain` 到达零或以下时抛出。

## 方法

### setMinorTicks

设定是否绘制每个十倍程内 2…9 的次刻度。

```cangjie
public func setMinorTicks(enabled: Bool): Unit
```

**参数**

- `enabled`: `Bool` — `true` 开启（默认开启），`false` 只保留十倍程主刻度。

### setDomain

替换定义域；到达零或以下的区间被拒绝。

```cangjie
public override func setDomain(bounds: Bounds): Unit
```

**参数**

- `bounds`: `Bounds` — 新定义域，`low` 必须大于零。

**异常**

- [`PlotException`](PlotException.md) — `bounds.low` 不大于零时抛出。

### normalize

把值按其在定义域对数空间中的位置映射到 `0..1`；非正值一律返回 `0.0`。定义域的对数跨度不为正（退化）时返回 `0.5`。在 `[1, 1000]` 上，`10` 位于三个十倍程中的第一个末端，即约 `1/3` 处，而不是十分之一处。

```cangjie
public func normalize(value: Float64): Float64
```

**参数**

- `value`: `Float64` — 数据坐标下的值。

**返回值** `Float64` — 对数空间中的归一化位置。

### denormalize

`normalize` 的逆变换，把归一化位置还原为数据值。

```cangjie
public func denormalize(t: Float64): Float64
```

**参数**

- `t`: `Float64` — 归一化位置。

**返回值** `Float64` — 对应的数据值，恒为正。

### ticks

返回覆盖当前定义域的十倍程刻度，含可选的次刻度。委托 [`Ticks.log10Scale`](Ticks.md#log10scale)，次刻度开关来自 [`setMinorTicks`](#setminorticks)。

```cangjie
public func ticks(): Array<Tick>
```

**返回值** `Array<Tick>` — 十倍程主刻度与可选次刻度组成的[刻度](Tick.md)列表。

### niceDomain

返回向外圆整到整十倍程的定义域。下界落到 `10^⌊log10(low)⌋`，上界升到 `10^⌈log10(high)⌉`：`[3, 4000]` 圆整为 `[1, 10000]`。

```cangjie
public override func niceDomain(): Bounds
```

**返回值** `Bounds` — 两端都是 10 的整数次幂的定义域。

### niceBounds

返回钳制为正后向外圆整到整十倍程的给定区间。

```cangjie
public override func niceBounds(bounds: Bounds): Bounds
```

**参数**

- `bounds`: `Bounds` — 原始数据范围；钳制规则见"说明"。

**返回值** `Bounds` — 两端都是 10 的整数次幂的区间。

**异常**

- [`PlotException`](PlotException.md) — 区间整个不为正时抛出。

### padBounds

乘法式留白：范围按其十倍程跨度的 `fraction` 增长，不会越过零。加法留白在这里毫无意义——`[1, 1e6]` 跨度的 5% 是 50000，会把下界推到 -49999、彻底推下轴去；按十倍程的分数增长才是对数空间的等价物。留白下限为 0.02 个十倍程，单十倍程的范围也能得到可见的余量。

```cangjie
public override func padBounds(bounds: Bounds, fraction: Float64): Bounds
```

**参数**

- `bounds`: `Bounds` — 原始数据范围；钳制规则见"说明"。
- `fraction`: `Float64` — 每侧留白占十倍程跨度的比例。

**返回值** `Bounds` — 留白后的区间，恒为正，可直接交给 [`setDomain`](#setdomain)。

**异常**

- [`PlotException`](PlotException.md) — 区间整个不为正时抛出。

### zoomAround

在对数空间缩放，锚点保持在光标下，结果不会越过零。十倍程在轴上占固定的一段，因此缩放的是**指数**而不是数值；缩放原始区间反而会拖走锚点，还可能交回负的下界。

```cangjie
public override func zoomAround(bounds: Bounds, pivot: Float64, factor: Float64): Bounds
```

**参数**

- `bounds`: `Bounds` — 当前可见区间；钳制规则见"说明"。
- `pivot`: `Float64` — 缩放锚点，数据坐标；非有限或非正时不缩放，返回钳制后的区间。
- `factor`: `Float64` — 缩放因子，小于 1 放大视图。

**返回值** `Bounds` — 对数空间缩放后的区间，恒为正。

**异常**

- [`PlotException`](PlotException.md) — 区间整个不为正时抛出。

### panByFraction

在对数空间平移可见十倍程数的 `fraction`；结果不会到达零。拖动 10% 面板宽度就把六个十倍程的视图移动 0.6 个十倍程。

```cangjie
public override func panByFraction(bounds: Bounds, fraction: Float64): Bounds
```

**参数**

- `bounds`: `Bounds` — 当前可见区间；钳制规则见"说明"。
- `fraction`: `Float64` — 平移量占可见十倍程数的比例，正值向数值增大方向。

**返回值** `Bounds` — 平移后的区间，十倍程宽度保持不变。

**异常**

- [`PlotException`](PlotException.md) — 区间整个不为正时抛出。

### accepts

当 `value` 为严格为正的有限值时返回 `true`。零与负值无法在对数轴上定位。

```cangjie
public override func accepts(value: Float64): Bool
```

**参数**

- `value`: `Float64` — 待检验的数据值。

**返回值** `Bool` — `isFinite(value) && value > 0.0` 的结果。

## 另请参阅

- [`Scale`](Scale.md) — 抽象基类与各操作长在标度上的理由。
- [`Ticks.log10Scale`](Ticks.md#log10scale) — 十倍程刻度的放置细节。
- [`NumberFormat.power10`](NumberFormat.md#power10) — 十倍程主刻度的标签形式。
