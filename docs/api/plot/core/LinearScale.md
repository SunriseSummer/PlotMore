[plot](../../index.md) › [plot.core](index.md) › LinearScale

# LinearScale

`plot.core` 中的 public class

成比例的线性轴：相等的数据间隔占据相等的像素间隔。两条轴的默认标度，也是数据穿过零时唯一正确的选择。

## 声明

```cangjie
public class LinearScale <: Scale
```

## 继承

父类为 [`Scale`](Scale.md)。未在本页出现的成员（`domain`、`setDomain`、`padBounds`、`zoomAround`、`panByFraction`、`accepts`）按 Scale 的默认行为继承：加法留白、原始区间的缩放与平移、接受一切有限值。

## 示例

```cangjie verify
package demo

import plot.core.{Bounds, LinearScale}

main(): Unit {
    let scale = LinearScale(Bounds(-20.0, 60.0))
    println(scale.normalize(20.0))      // 输出: 0.500000
    println(scale.denormalize(1.0))     // 输出: 60.000000

    // 自动适配所用的圆整：区间向外扩展到整刻度
    let survey = LinearScale(Bounds(3.7, 91.2))
    println(survey.niceDomain())        // 输出: Bounds(0.000000, 100.000000)

    // 次刻度：每个主刻度间隔再分 5 份
    survey.setMinorDivisions(5)
    var minors = 0
    for (tick in survey.ticks()) {
        if (!tick.major) {
            minors += 1
        }
    }
    println(minors)                     // 输出: 18
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 创建线性标度：无参形式使用默认定义域 `[0, 1]`，带参形式以 `domain` 为初始定义域。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`setTickTarget(target: Int64)`](#setticktarget) | 设定主刻度的大致目标数量；实际数量取决于圆整后的步长。 |
| [`setMinorDivisions(divisions: Int64)`](#setminordivisions) | 设定相邻主刻度之间的次刻度细分份数；小于 2 时不产生次刻度。 |
| [`normalize(value: Float64)`](#normalize) | 按比例映射 `(value - low) / span`；退化定义域一律返回 `0.5`。 |
| [`denormalize(t: Float64)`](#denormalize) | 线性反变换 `low + t × span`。 |
| [`ticks()`](#ticks) | 返回当前定义域上的主刻度，开启细分后附带次刻度。 |
| [`niceDomain()`](#nicedomain) | 返回按当前刻度目标向外圆整到整步长的定义域。 |
| [`niceBounds(bounds: Bounds)`](#nicebounds) | 返回按当前刻度目标向外圆整到整步长的给定区间。 |

## 构造函数

### init

创建线性标度：无参形式使用默认定义域 `[0, 1]`，带参形式以 `domain` 为初始定义域。

```cangjie
public init()
```

```cangjie
public init(domain: Bounds)
```

**参数**（第二个重载）

- `domain`: [`Bounds`](Bounds.md) — 初始定义域。

## 方法

### setTickTarget

设定主刻度的大致目标数量；实际数量取决于圆整后的步长。目标刻意近似：严格兑现数量会要求不圆整的步长。

```cangjie
public func setTickTarget(target: Int64): Unit
```

**参数**

- `target`: `Int64` — 主刻度目标数；小于 2 时按 2 处理。默认目标为 6。

### setMinorDivisions

设定相邻主刻度之间的次刻度细分份数；小于 2 时不产生次刻度。负值按 0 处理。

```cangjie
public func setMinorDivisions(divisions: Int64): Unit
```

**参数**

- `divisions`: `Int64` — 每个主刻度间隔的细分份数；默认 0，即关闭次刻度。

### normalize

按比例映射 `(value - low) / span`；退化定义域一律返回 `0.5`。定义域之外的值映射到 `0..1` 之外，不做夹取——面板裁剪会处理它们。

```cangjie
public func normalize(value: Float64): Float64
```

**参数**

- `value`: `Float64` — 数据坐标下的值。

**返回值** `Float64` — 归一化位置。

### denormalize

线性反变换 `low + t × span`。

```cangjie
public func denormalize(t: Float64): Float64
```

**参数**

- `t`: `Float64` — 归一化位置。

**返回值** `Float64` — 对应的数据值。

### ticks

返回当前定义域上的主刻度，开启细分后附带次刻度。主刻度来自 [`Ticks.linear`](Ticks.md#linear)（按当前刻度目标），细分份数不小于 2 时再追加 [`Ticks.linearMinor`](Ticks.md#linearminor) 的次刻度。

```cangjie
public func ticks(): Array<Tick>
```

**返回值** `Array<Tick>` — 主刻度在前、次刻度在后的[刻度](Tick.md)列表。

### niceDomain

返回按当前刻度目标向外圆整到整步长的定义域。

```cangjie
public override func niceDomain(): Bounds
```

**返回值** `Bounds` — [`Ticks.nice`](Ticks.md#nice) 以当前刻度目标圆整后的定义域。

### niceBounds

返回按当前刻度目标向外圆整到整步长的给定区间。

```cangjie
public override func niceBounds(bounds: Bounds): Bounds
```

**参数**

- `bounds`: `Bounds` — 原始数据范围。

**返回值** `Bounds` — 圆整后的区间。

## 另请参阅

- [`Scale`](Scale.md) — 继承来的定义域、留白与缩放平移行为。
- [`Ticks`](Ticks.md) — 主/次刻度的放置算法。
