[plot](../../index.md) › [plot.core](index.md) › Colormap

# Colormap

`plot.core` 中的 public struct

把 `0..1` 连续映射为颜色的色标，在锚点色停之间插值。经 [`sample`](#sample) 取色，用于热力图、等值线填充等一切按值取色的场景。

## 声明

```cangjie
public struct Colormap
```

## 说明

连续预设（[`viridis`](#viridis)、[`magma`](#magma)、[`plasma`](#plasma)、[`inferno`](#inferno)、[`cividis`](#cividis)）由内置色停构成，`sample` 在相邻色停之间线性插值。[`coolWarm`](#coolwarm) 与 [`spectral`](#spectral) 则从中点向两侧使用不同颜色，适合区分中点以下与以上的值。

## 示例

```cangjie verify
package demo

import plot.core.{Bounds, Colormap}

main(): Unit {
    let map = Colormap.viridis()

    // t 被夹取到 0..1：越界一律取端点色
    let low = map.sample(-1.0)
    println("${low.r} ${low.g} ${low.b}")      // 输出: 68 1 84
    let high = map.sample(2.0)
    println("${high.r} ${high.g} ${high.b}")   // 输出: 253 231 37

    // 把数据值放进定义域取色；退化定义域一律取中点色
    let mid = map.sampleIn(150.0, Bounds(100.0, 200.0))
    println(mid.r == map.sample(0.5).r)        // 输出: true

    // 为图例取 5 个等距样本
    println(map.ramp(5).size)                  // 输出: 5
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(stops: Array<Color>)`](#init) | 由锚点色停数组创建色标。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`sample(t: Float64)`](#sample) | 返回 `t` 处的颜色；`t` 夹取到 `0..1`，在相邻色停之间插值。 |
| [`sampleIn(value: Float64, domain: Bounds)`](#samplein) | 返回 `value` 在 `domain` 中所处位置对应的颜色；域外的值夹取到端点色。 |
| [`ramp(count: Int64)`](#ramp) | 返回横跨色带的 `count` 个等距采样——用于构建查找纹理与图例。 |
| [`reversed()`](#reversed) | 返回方向反转的色标。 |
| [`static viridis()`](#viridis) | 感知均匀的蓝-绿-黄色标；顺序数据的安全默认。 |
| [`static magma()`](#magma) | 感知均匀的黑-紫-白色标。 |
| [`static plasma()`](#plasma) | 感知均匀的蓝-红-黄色标。 |
| [`static inferno()`](#inferno) | 感知均匀的黑-红-黄色标。 |
| [`static cividis()`](#cividis) | 感知均匀且对色觉缺陷友好的蓝-黄色标。 |
| [`static coolWarm()`](#coolwarm) | 蓝-白-红发散色标，用于以零为中心的带符号数据。 |
| [`static spectral()`](#spectral) | 红-黄-蓝发散色标。 |
| [`static monochrome(base: Color)`](#monochrome) | 由 `base` 派生的单色调浅-深色带。 |

## 构造函数

### init

由锚点色停数组创建色标。色停沿 `0..1` 等距分布，采样在相邻两停之间插值。

```cangjie
public init(stops: Array<Color>)
```

**参数**

- `stops`: `Array<Color>` — 锚点色停，至少两个。

**异常**

- [`PlotException`](PlotException.md) — 色停少于两个时抛出，色带没有可插值的区间。

## 方法

### sample

返回 `t` 处的颜色；`t` 夹取到 `0..1`，在相邻色停之间插值。NaN 按 0 处理并取低端色——被采到缺失值的色标应交回端点色停，而不是让整帧崩溃。

```cangjie
public func sample(t: Float64): Color
```

**参数**

- `t`: `Float64` — 色带位置；小于 0、大于 1 或 NaN 分别夹取到两端与低端。

**返回值** `Color` — 插值得到的颜色；`t` 为 0 或 1 时恰为端点色停。

### sampleIn

返回 `value` 在 `domain` 中所处位置对应的颜色；域外的值夹取到端点色。退化定义域没有可放置数值的梯度，一律映射到色带中点而不是除以零。

```cangjie
public func sampleIn(value: Float64, domain: Bounds): Color
```

**参数**

- `value`: `Float64` — 待着色的数据值。
- `domain`: [`Bounds`](Bounds.md) — 值域区间；退化区间时结果固定为 `sample(0.5)`。

**返回值** `Color` — 归一化位置上的采样色。

### ramp

返回横跨色带的 `count` 个等距采样——用于构建查找纹理与图例。

```cangjie
public func ramp(count: Int64): Array<Color>
```

**参数**

- `count`: `Int64` — 采样数量；不大于 1 时结果退化为只含中点色的单元素数组。

**返回值** `Array<Color>` — 首尾恰为色带两端的 `count` 个采样。

### reversed

返回方向反转的色标。原色带的高端成为新色带的低端。

```cangjie
public func reversed(): Colormap
```

**返回值** `Colormap` — 色停顺序翻转的新色标。

### viridis

感知均匀的蓝-绿-黄色标；顺序数据的安全默认。

```cangjie
public static func viridis(): Colormap
```

**返回值** `Colormap` — 十停色标，从 `#440154` 到 `#FDE725`。

### magma

感知均匀的黑-紫-白色标。

```cangjie
public static func magma(): Colormap
```

**返回值** `Colormap` — 十停色标。

### plasma

感知均匀的蓝-红-黄色标。

```cangjie
public static func plasma(): Colormap
```

**返回值** `Colormap` — 十停色标。

### inferno

感知均匀的黑-红-黄色标。

```cangjie
public static func inferno(): Colormap
```

**返回值** `Colormap` — 十停色标。

### cividis

感知均匀且对色觉缺陷友好的蓝-黄色标。

```cangjie
public static func cividis(): Colormap
```

**返回值** `Colormap` — 十停色标。

### coolWarm

蓝-白-红发散色标，用于以零为中心的带符号数据。

```cangjie
public static func coolWarm(): Colormap
```

**返回值** `Colormap` — 九停发散色标。

### spectral

红-黄-蓝发散色标。

```cangjie
public static func spectral(): Colormap
```

**返回值** `Colormap` — 十停发散色标。

### monochrome

由 `base` 派生的单色调浅-深色带。四个色停依次为 `base` 变亮 0.85、变亮 0.45、原色与变暗 0.45。

```cangjie
public static func monochrome(base: Color): Colormap
```

**参数**

- `base`: `Color` — 色带的基准色。

**返回值** `Colormap` — 四停单色色标。

## 另请参阅

- [`Palette`](Palette.md) — 离散的分类色。
- [`Theme.colormap`](Theme.md#colormap) — 主题默认色标（`viridis()`）。
- [`HeatmapSeries`](../series/HeatmapSeries.md) — 按值取色的典型使用方。
- [`ColorBar`](../axes/ColorBar.md) — 把色标绘制成图旁的颜色条。
