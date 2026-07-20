[plot](../../index.md) › [plot.core](index.md) › Bounds

# Bounds

`plot.core` 中的 public struct

单轴上的闭区间 `[low, high]`——标度从中取值的数据范围。公开 `init` 要求调用方保证 `low <= high`，但不会检查或交换参数；顺序未知时使用 [`of`](#of) 规范化端点。除非另有说明，本页其余成员的区间保证都以满足此前置条件为准。

## 声明

```cangjie
public struct Bounds <: ToString & Equatable<Bounds>
```

## 继承

实现标准库接口 `ToString` 与 `Equatable<Bounds>`。

## 说明

在 `low <= high` 的有效区间中，`low` 等于 `high` 表示**退化**区间：单个数据值，或一条常量系列。退化区间可以合法构造，但映射到像素范围会除以零，因此调用方在建立 [`Projection`](Projection.md) 之前会先用 [`padded()`](#padded) 或 [`nonDegenerate()`](#nondegenerate) 把它打开。逆序参数会构造不满足本类型约定的实例，并可能让 `span()` 为负；不要依赖后续成员替调用方修正它。

## 示例

```cangjie verify
package demo

import plot.core.Bounds

main(): Unit {
    // 覆盖所有有限值；NaN 与无穷被跳过，不会污染区间
    let covered = Bounds.cover([3.0, Float64.NaN, -2.0, 7.0]).getOrThrow()
    println(covered)                    // 输出: Bounds(-2.000000, 7.000000)
    println(covered.span())             // 输出: 9.000000
    println(covered.contains(7.0))      // 输出: true

    // 两侧各留 10% 余量，再与另一区间求并
    let padded = Bounds(0.0, 10.0).expanded(0.1)
    println(padded)                     // 输出: Bounds(-1.000000, 11.000000)
    println(padded.union(Bounds(-3.0, 1.0)))    // 输出: Bounds(-3.000000, 11.000000)

    // 单点区间在建立投影前需要先打开
    println(Bounds(4.0, 4.0).nonDegenerate())   // 输出: Bounds(2.000000, 6.000000)
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(low: Float64, high: Float64)`](#init) | 由已按升序排列的一对值创建区间。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static of(a: Float64, b: Float64)`](#of) | 由任意顺序的两个值创建区间。 |
| [`static cover(values: Array<Float64>)`](#cover) | 返回覆盖所有有限值的最紧区间；输入不含任何有限值时返回 `None`。 |
| [`span()`](#span) | 返回区间宽度；退化区间为零。 |
| [`center()`](#center) | 返回区间的算术中点。 |
| [`contains(value: Float64)`](#contains) | 当 `value` 位于区间内（含两端）时返回 `true`。 |
| [`isDegenerate()`](#isdegenerate) | 当区间收缩为单点、无法映射到像素范围时返回 `true`。 |
| [`union(other: Bounds)`](#union) | 返回覆盖两个区间的最小区间。 |
| [`expanded(fraction: Float64)`](#expanded) | 返回两侧各增长当前宽度 `fraction` 倍的区间（`0.05` 即每侧 5% 余量）。 |
| [`padded(amount: Float64)`](#padded) | 返回两侧各增长绝对量 `amount` 的区间。 |
| [`nonDegenerate()`](#nondegenerate) | 返回这组区间的非退化版本：已有宽度的区间原样返回，单点区间围绕该点打开。 |
| [`shifted(delta: Float64)`](#shifted) | 返回两端同时移动 `delta` 的区间。 |
| [`scaledAround(pivot: Float64, factor: Float64)`](#scaledaround) | 返回围绕 `pivot` 缩放 `factor` 倍的区间；`factor` 小于 1 收窄区间（放大视图），大于 1 加宽区间（缩小视图）。 |
| [`toString()`](#tostring) | 返回形如 `Bounds(low, high)` 的字符串表示。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`low`](#low) | 区间下界（含端点）。 |
| [`high`](#high) | 区间上界（含端点）。 |

**运算符**

| 成员 | 说明 |
|---|---|
| [`operator ==`](#operator) | 当两个区间的 `low` 与 `high` 都相等时返回 `true`。 |
| [`operator !=`](#operator-1) | `==` 的取反。 |

## 构造函数

### init

由已按升序排列的一对值创建区间。调用方必须保证 `low <= high`；`init` 不检查也不交换，顺序未知时改用 [`of`](#of)。

```cangjie
public init(low: Float64, high: Float64)
```

**参数**

- `low`: `Float64` — 区间下界（含端点）。
- `high`: `Float64` — 区间上界（含端点）；必须不小于 `low`，但构造函数不会检查。

## 方法

### of

由任意顺序的两个值创建区间。两个值按升序放入 `low` 与 `high`。

```cangjie
public static func of(a: Float64, b: Float64): Bounds
```

**参数**

- `a`: `Float64` — 任一端点。
- `b`: `Float64` — 另一端点。

**返回值** `Bounds` — `low` 取两者较小值、`high` 取较大值的区间。

### cover

返回覆盖所有有限值的最紧区间；输入不含任何有限值时返回 `None`。NaN 与无穷被跳过而不是污染整个范围——这正是系列得以携带缺口的原因。

```cangjie
public static func cover(values: Array<Float64>): ?Bounds
```

**参数**

- `values`: `Array<Float64>` — 待覆盖的数据值；非有限元素被忽略。

**返回值** `?Bounds` — 覆盖全部有限值的最紧区间；`values` 为空或全部非有限时为 `None`。

### span

返回区间宽度；退化区间为零。

```cangjie
public func span(): Float64
```

**返回值** `Float64` — `high - low`；对不满足构造前置条件的逆序实例可能为负。

### center

返回区间的算术中点。

```cangjie
public func center(): Float64
```

**返回值** `Float64` — `low` 与 `high` 的中点。

### contains

当 `value` 位于区间内（含两端）时返回 `true`。

```cangjie
public func contains(value: Float64): Bool
```

**参数**

- `value`: `Float64` — 待检验的值。

**返回值** `Bool` — `value >= low && value <= high` 的结果。

### isDegenerate

当区间收缩为单点、无法映射到像素范围时返回 `true`。

```cangjie
public func isDegenerate(): Bool
```

**返回值** `Bool` — `span() <= 0.0` 时为 `true`；逆序实例也会返回 `true`，但这不表示它是合法的单点区间。

### union

返回覆盖两个区间的最小区间。

```cangjie
public func union(other: Bounds): Bounds
```

**参数**

- `other`: `Bounds` — 参与合并的另一区间。

**返回值** `Bounds` — 下界取两者较小、上界取两者较大的区间。

### expanded

返回两侧各增长当前宽度 `fraction` 倍的区间（`0.05` 即每侧 5% 余量）。

```cangjie
public func expanded(fraction: Float64): Bounds
```

**参数**

- `fraction`: `Float64` — 每侧增量占当前宽度的比例。

**返回值** `Bounds` — 加宽后的区间。

### padded

返回两侧各增长绝对量 `amount` 的区间。

```cangjie
public func padded(amount: Float64): Bounds
```

**参数**

- `amount`: `Float64` — 每侧增加的绝对量。

**返回值** `Bounds` — `[low - amount, high + amount]`。

### nonDegenerate

返回这组区间的非退化版本：已有宽度的区间原样返回，单点区间围绕该点打开。单点为零时加宽到 `[-1, 1]` 而不是保持收缩（零的相对留白仍是零）；非零单点 `v` 打开为 `[v - |v| × 0.5, v + |v| × 0.5]`。

```cangjie
public func nonDegenerate(): Bounds
```

**返回值** `Bounds` — 对满足 `low <= high` 前置条件的输入，保证宽度大于零。

### shifted

返回两端同时移动 `delta` 的区间。

```cangjie
public func shifted(delta: Float64): Bounds
```

**参数**

- `delta`: `Float64` — 位移量，正值向数值增大方向移动。

**返回值** `Bounds` — `[low + delta, high + delta]`。

### scaledAround

返回围绕 `pivot` 缩放 `factor` 倍的区间；`factor` 小于 1 收窄区间（放大视图），大于 1 加宽区间（缩小视图）。`pivot` 在结果中保持原有的相对位置——这是滚轮缩放把光标下的数据钉在光标下的基础。

```cangjie
public func scaledAround(pivot: Float64, factor: Float64): Bounds
```

**参数**

- `pivot`: `Float64` — 缩放锚点，数据坐标。
- `factor`: `Float64` — 缩放因子。

**返回值** `Bounds` — 缩放后的区间。

### toString

返回形如 `Bounds(low, high)` 的字符串表示。两端以字符串插值默认格式打印，如 `Bounds(1.000000, 9.000000)`。

```cangjie
public func toString(): String
```

**返回值** `String` — 区间的文本表示。

## 字段

### low

区间下界（含端点）。声明为 `let`，构造后不可变。

```cangjie
public let low: Float64
```

### high

区间上界（含端点）。声明为 `let`，构造后不可变。

```cangjie
public let high: Float64
```

## 运算符

### operator==

当两个区间的 `low` 与 `high` 都相等时返回 `true`。按浮点相等逐字段比较。

```cangjie
public operator func ==(other: Bounds): Bool
```

**参数**

- `other`: `Bounds` — 参与比较的区间。

**返回值** `Bool` — 两端均相等时为 `true`。

### operator!=

`==` 的取反。

```cangjie
public operator func !=(other: Bounds): Bool
```

**参数**

- `other`: `Bounds` — 参与比较的区间。

**返回值** `Bool` — 任一端不相等时为 `true`。

## 另请参阅

- [`Scale.setDomain`](Scale.md#setdomain) — 把区间安到一条标度上。
- [`Ticks.nice`](Ticks.md#nice) — 把区间向外圆整到整刻度。
- [`isFinite`](functions.md#isfinite) — `cover` 所用的有限性判定。
