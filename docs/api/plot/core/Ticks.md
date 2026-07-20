[plot](../../index.md) › [plot.core](index.md) › Ticks

# Ticks

`plot.core` 中的 public class

刻度放置算法：刻度落在圆整数值上，而不是数据自身的端点上。

## 声明

```cangjie
public class Ticks
```

## 说明

覆盖 `[3.7, 91.2]` 的轴在 20、40、60、80 落刻度，而不是 3.7 与 91.2：圆整位置让图一眼可读，代价——刻度不一定顶到面板边缘——几乎不可见。位置按步长的整数倍计算并吸附零点（3 × 0.1 在二进制浮点里是 0.30000000000000004，坐标轴绝不能把这样的标签印出来）。

## 示例

```cangjie verify
package demo

import plot.core.{Bounds, Ticks}

main(): Unit {
    // 原始间距向上圆整到 1/2/5 × 10 的幂
    println(Ticks.niceStep(3.0))                       // 输出: 5.000000
    println(Ticks.linearStep(Bounds(0.0, 10.0), 5))    // 输出: 2.000000

    // 主刻度落在圆整位置
    let ticks = Ticks.linear(Bounds(0.0, 10.0), target: 5)
    println(ticks.size)                                // 输出: 6
    println("${ticks[0].label} 到 ${ticks[5].label}")  // 输出: 0 到 10

    // 区间向外圆整到整步长
    println(Ticks.nice(Bounds(3.7, 91.2), target: 5))  // 输出: Bounds(0.000000, 100.000000)
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init()`](#init) | 创建无状态的工具对象；通常直接调用静态成员，无需构造实例。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static niceStep(rawStep: Float64)`](#nicestep) | 把原始间距向上圆整到下一个 1、2、5 或 10 乘以 10 的幂。 |
| [`static linear(bounds: Bounds, target!: Int64)`](#linear) | 返回覆盖 `bounds` 的主刻度，数量大致为 `target` 个。 |
| [`static linearStep(bounds: Bounds, target: Int64)`](#linearstep) | 返回 `linear` 将采用的刻度间距——供自行格式化标签的调用方使用。 |
| [`static linearMinor(bounds: Bounds, target!: Int64, divisions!: Int64)`](#linearminor) | 返回把每个主刻度间隔细分为 `divisions` 份的次刻度，不含主刻度位置本身。 |
| [`static log10Scale(bounds: Bounds, minorTicks!: Bool)`](#log10scale) | 返回覆盖 `bounds` 的十倍程刻度（…、0.1、1、10、100、…），要求区间严格为正。 |
| [`static nice(bounds: Bounds, target!: Int64)`](#nice) | 返回向外扩展到最近整步长的区间，让轴结束在带标签的刻度上而非间隔中途。 |

## 构造函数

### init

**由编译器生成：** 该类未声明构造函数且没有未初始化的实例字段，仓颉因此合成此公有无参构造函数。

创建无状态的工具对象；通常直接调用静态成员，无需构造实例。

```cangjie
public init()
```

## 方法

### niceStep

把原始间距向上圆整到下一个 1、2、5 或 10 乘以 10 的幂。把步长限制在这个集合里，标签才既短又便于心算细分；3.7 这样的步长技术上合法、实际上不可读。

```cangjie
public static func niceStep(rawStep: Float64): Float64
```

**参数**

- `rawStep`: `Float64` — 原始间距；非有限或非正时结果为 `1.0`。

**返回值** `Float64` — 圆整后的步长（`niceStep(3.0)` 为 `5.0`，`niceStep(0.03)` 为 `0.05`）。

### linear

返回覆盖 `bounds` 的主刻度，数量大致为 `target` 个。数量刻意近似：严格兑现会要求不圆整的步长。标签由 [`NumberFormat.tick`](NumberFormat.md#tick) 按步长生成。无法安全落刻度的区间——跨度为无穷，或步数超过一万——返回空数组而不是崩溃。

```cangjie
public static func linear(bounds: Bounds, target!: Int64 = 6): Array<Tick>
```

**参数**

- `bounds`: [`Bounds`](Bounds.md) — 待覆盖的区间。
- `target!`: `Int64` — 主刻度目标数；小于 2 按 2 处理。默认 `6`。

**返回值** `Array<Tick>` — 落在步长整数倍上的主[刻度](Tick.md)。

### linearStep

返回 `linear` 将采用的刻度间距——供自行格式化标签的调用方使用。

```cangjie
public static func linearStep(bounds: Bounds, target: Int64): Float64
```

**参数**

- `bounds`: `Bounds` — 待覆盖的区间；跨度非有限或非正时结果为 `1.0`。
- `target`: `Int64` — 主刻度目标数；小于 2 按 2 处理。

**返回值** `Float64` — 经 [`niceStep`](#nicestep) 圆整的间距。

### linearMinor

返回把每个主刻度间隔细分为 `divisions` 份的次刻度，不含主刻度位置本身。是否与主刻度重合由值自身相对次步长的倍数决定——每第 `divisions` 个倍数是主刻度——而不是它在列表中的位置，因此不从圆整数值起步的轴也不会丢失或重画刻度。

```cangjie
public static func linearMinor(bounds: Bounds, target!: Int64 = 6, divisions!: Int64 = 5): Array<Tick>
```

**参数**

- `bounds`: `Bounds` — 待覆盖的区间。
- `target!`: `Int64` — 主刻度目标数，决定主步长；默认 `6`。
- `divisions!`: `Int64` — 每个主刻度间隔的细分份数；小于 2 时返回空数组。默认 `5`。

**返回值** `Array<Tick>` — 标签为空、`major` 为 `false` 的次刻度。

### log10Scale

返回覆盖 `bounds` 的十倍程刻度（…、0.1、1、10、100、…），要求区间严格为正。当范围只跨少数几个十倍程（不超过 3 个）时，2…9 的细分作为次刻度加入，两个十倍程的轴不至于只剩三个孤零零的标签；其中仅当范围不超过 2 个十倍程时，2 与 5 的次刻度带标签——每个十倍程九个标签在任何合理宽度下都会互相挤压。主刻度标签来自 [`NumberFormat.power10`](NumberFormat.md#power10)。

```cangjie
public static func log10Scale(bounds: Bounds, minorTicks!: Bool = true): Array<Tick>
```

**参数**

- `bounds`: `Bounds` — 待覆盖的区间，必须严格为正且有限。
- `minorTicks!`: `Bool` — 是否加入 2…9 次刻度；默认 `true`。

**返回值** `Array<Tick>` — 十倍程主刻度与可选次刻度。

**异常**

- [`PlotException`](PlotException.md) — `bounds` 到达零或以下时抛出——对数轴无法表达；两端存在非有限值时同样抛出，而不是在内部整数转换处崩溃。

### nice

返回向外扩展到最近整步长的区间，让轴结束在带标签的刻度上而非间隔中途。范围交由数据决定时，[`Axes`](../axes/Axes.md) 应用的就是它。退化区间先经 [`Bounds.nonDegenerate`](Bounds.md#nondegenerate) 打开，再按 [`linearStep`](#linearstep) 的步长向下／向上取整两端。

```cangjie
public static func nice(bounds: Bounds, target!: Int64 = 6): Bounds
```

**参数**

- `bounds`: `Bounds` — 原始区间。
- `target!`: `Int64` — 主刻度目标数；默认 `6`。

**返回值** `Bounds` — 两端都是步长整数倍的区间（`[3.7, 91.2]` 圆整为 `[0, 100]`）。

## 另请参阅

- [`Tick`](Tick.md) — 刻度值本身。
- [`NumberFormat`](NumberFormat.md) — 刻度标签的格式化。
- [`LinearScale.ticks`](LinearScale.md#ticks)、[`LogScale.ticks`](LogScale.md#ticks) — 标度侧的调用入口。
