[plot](../../index.md) › [plot.core](index.md) › Scale

# Scale

`plot.core` 中的 public class（抽象基类）

数据范围与归一化 `0..1` 轴位置之间的映射，外加标注这段范围的刻度。

## 声明

```cangjie
public abstract class Scale
```

## 继承

本包内的已知子类型：[`LinearScale`](LinearScale.md)、[`LogScale`](LogScale.md)、[`CategoryScale`](CategoryScale.md)。

## 说明

标度只拥有变换的数据一侧；把 `0..1` 变成像素是 [`Projection`](Projection.md) 的职责——这正是同一条标度得以同时驱动面板、图例色块与颜色条的原因。[`normalize`](#normalize)、[`denormalize`](#denormalize)、[`ticks`](#ticks) 是抽象方法，由子类实现；其余开放方法给出线性几何下的默认行为，非线性标度按需覆盖（[`padBounds`](#padbounds)、[`zoomAround`](#zoomaround) 的说明解释了为什么这些操作长在标度上）。

## 示例

```cangjie verify
package demo

import plot.core.{Bounds, LinearScale, Scale}

main(): Unit {
    // 以 Scale 类型的变量驱动一条线性标度
    let scale: Scale = LinearScale(Bounds(0.0, 100.0))
    println(scale.normalize(50.0)) // 输出: 0.500000
    println(scale.denormalize(0.25)) // 输出: 25.000000
    println(scale.ticks().size) // 输出: 6

    // 缩放与平移只计算新的区间，标度本身不变
    let view = scale.domain()
    println(scale.zoomAround(view, 25.0, 0.5)) // 输出: Bounds(12.500000, 62.500000)
    println(scale.panByFraction(view, -0.1)) // 输出: Bounds(-10.000000, 90.000000)
    println(scale.domain()) // 输出: Bounds(0.000000, 100.000000)
}
```

## 成员概览

**方法**

| 成员 | 说明 |
|---|---|
| [`domain()`](#domain) | 返回标度当前覆盖的数据区间。 |
| [`setDomain(bounds: Bounds)`](#setdomain) | 替换数据区间。 |
| [`normalize(value: Float64)`](#normalize) | 把数据值映射到跨越定义域的 `0..1`；定义域之外的值映射到 `0..1` 之外。 |
| [`denormalize(t: Float64)`](#denormalize) | `normalize` 的逆变换。 |
| [`ticks()`](#ticks) | 返回标注当前定义域的刻度。 |
| [`niceDomain()`](#nicedomain) | 返回向外圆整到整刻度的定义域；圆整无意义时原样返回。 |
| [`padBounds(bounds: Bounds, fraction: Float64)`](#padbounds) | 把原始数据范围按其宽度的 `fraction` 向外留白，准备显示。 |
| [`niceBounds(bounds: Bounds)`](#nicebounds) | 把原始数据范围向外圆整到整刻度，准备显示。 |
| [`zoomAround(bounds: Bounds, pivot: Float64, factor: Float64)`](#zoomaround) | 返回以 `pivot` 为锚点缩放 `factor` 倍的 `bounds`，锚点保持在原归一化位置——滚轮缩放背后的变换。 |
| [`panByFraction(bounds: Bounds, fraction: Float64)`](#panbyfraction) | 返回平移了可见宽度 `fraction` 倍的 `bounds`——拖拽平移背后的变换。 |
| [`accepts(value: Float64)`](#accepts) | 当标度完全能够表达 `value` 时返回 `true`（对数标度无法表达零）。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`range`](#range) | （protected，仅子类可见）标度当前覆盖的数据区间。 |

## 方法

### domain

返回标度当前覆盖的数据区间。

```cangjie
public func domain(): Bounds
```

**返回值** [`Bounds`](Bounds.md) — 当前定义域。

### setDomain

替换数据区间。实现会拒绝自己无法表达的定义域——对数标度拒绝到达零的区间——并以 [`PlotException`](PlotException.md) 报告；基类实现本身直接赋值，不抛异常。

```cangjie
public open func setDomain(bounds: Bounds): Unit
```

**参数**

- `bounds`: `Bounds` — 新的定义域。

### normalize

把数据值映射到跨越定义域的 `0..1`；定义域之外的值映射到 `0..1` 之外。抽象方法，由子类实现。

```cangjie
public func normalize(value: Float64): Float64
```

**参数**

- `value`: `Float64` — 数据坐标下的值。

**返回值** `Float64` — 归一化位置；不做夹取。

### denormalize

`normalize` 的逆变换。抽象方法，由子类实现。

```cangjie
public func denormalize(t: Float64): Float64
```

**参数**

- `t`: `Float64` — 归一化位置，`0..1` 之外同样接受。

**返回值** `Float64` — 对应的数据值。

### ticks

返回标注当前定义域的刻度。抽象方法，由子类实现。

```cangjie
public func ticks(): Array<Tick>
```

**返回值** `Array<Tick>` — 当前定义域上的[刻度](Tick.md)列表。

### niceDomain

返回向外圆整到整刻度的定义域；圆整无意义时原样返回。基类默认原样返回 `range`。

```cangjie
public open func niceDomain(): Bounds
```

**返回值** `Bounds` — 圆整后的定义域。

### padBounds

把原始数据范围按其宽度的 `fraction` 向外留白，准备显示。默认做加法留白。这件事长在标度而不是坐标系上，因为"5% 余量"的含义完全取决于标度的几何：加法留白对线性轴正确，对对数轴毫无意义（甚至可能把范围推过零），对类别轴则干脆是错的（它的范围是类别，不是数据）。

```cangjie
public open func padBounds(bounds: Bounds, fraction: Float64): Bounds
```

**参数**

- `bounds`: `Bounds` — 原始数据范围。
- `fraction`: `Float64` — 每侧留白占宽度的比例。

**返回值** `Bounds` — 留白后的区间；默认实现即 [`Bounds.expanded`](Bounds.md#expanded)。

### niceBounds

把原始数据范围向外圆整到整刻度，准备显示。默认委托 [`Ticks.nice`](Ticks.md#nice)。

```cangjie
public open func niceBounds(bounds: Bounds): Bounds
```

**参数**

- `bounds`: `Bounds` — 原始数据范围。

**返回值** `Bounds` — 圆整后的区间。

### zoomAround

返回以 `pivot` 为锚点缩放 `factor` 倍的 `bounds`，锚点保持在原归一化位置——滚轮缩放背后的变换。滚轮缩放必须让光标下的数据留在光标下；这件事与 `padBounds` 同理长在标度上：缩放原始区间只在轴成比例时才正确，对数轴必须在对数空间缩放，否则锚点漂移、范围还可能被推过零而被标度直接拒绝。

```cangjie
public open func zoomAround(bounds: Bounds, pivot: Float64, factor: Float64): Bounds
```

**参数**

- `bounds`: `Bounds` — 当前可见区间。
- `pivot`: `Float64` — 缩放锚点，数据坐标。
- `factor`: `Float64` — 缩放因子，小于 1 放大视图。

**返回值** `Bounds` — 缩放后的区间；默认实现即 [`Bounds.scaledAround`](Bounds.md#scaledaround)。

### panByFraction

返回平移了可见宽度 `fraction` 倍的 `bounds`——拖拽平移背后的变换。

```cangjie
public open func panByFraction(bounds: Bounds, fraction: Float64): Bounds
```

**参数**

- `bounds`: `Bounds` — 当前可见区间。
- `fraction`: `Float64` — 平移量占可见宽度的比例，正值向数值增大方向。

**返回值** `Bounds` — 平移后的区间；默认实现即 `bounds.shifted(bounds.span() × fraction)`。

### accepts

当标度完全能够表达 `value` 时返回 `true`（对数标度无法表达零）。基类默认只要求值有限。

```cangjie
public open func accepts(value: Float64): Bool
```

**参数**

- `value`: `Float64` — 待检验的数据值。

**返回值** `Bool` — 默认即 [`isFinite`](functions.md#isfinite) 的结果。

## 字段

### range

（protected，仅子类可见）标度当前覆盖的数据区间。默认 `Bounds(0.0, 1.0)`；对外经 [`domain()`](#domain) 读取、[`setDomain`](#setdomain) 写入。

```cangjie
protected var range: Bounds = Bounds(0.0, 1.0)
```

## 另请参阅

- [`LinearScale`](LinearScale.md) — 成比例的默认标度。
- [`LogScale`](LogScale.md) — 以 10 为底的对数标度。
- [`CategoryScale`](CategoryScale.md) — 覆盖命名类别的离散标度。
- [`Projection`](Projection.md) — 把归一化位置变成像素。
