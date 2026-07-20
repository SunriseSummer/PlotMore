[plot](../../index.md) › [plot.core](index.md) › NumberFormat

# NumberFormat

`plot.core` 中的 public class

面向坐标轴、图例与读数的数值标签格式化工具。目标始终是仍能区分相邻刻度的最短标签：尾随零被去除，只有当普通十进制不可读时才切换到科学计数法。

## 声明

```cangjie
public class NumberFormat
```

## 说明

- 所有格式化方法对非有限值返回可读标签：NaN 得到 `NaN`，正负无穷得到 `∞` 与 `-∞`。
- [`tick`](#tick) 与 [`compact`](#compact) 在 `|value| ≥ 1e6` 或 `0 < |value| < 1e-4` 时切换为科学计数法；零本身始终按普通十进制输出。
- 各方法的小数位数一律夹取到 `0..15`。

## 示例

```cangjie verify
package demo

import plot.core.NumberFormat

main(): Unit {
    // 刻度标签：小数位数由步长决定
    println(NumberFormat.tick(1.5, 0.5))       // 输出: 1.5
    println(NumberFormat.tick(2.0, 0.5))       // 输出: 2
    println(NumberFormat.decimalsFor(0.05))    // 输出: 2

    // 紧凑标签、固定位数与百分比
    println(NumberFormat.compact(3.14159))     // 输出: 3.142
    println(NumberFormat.fixed(1.239, 2))      // 输出: 1.24
    println(NumberFormat.percent(0.42))        // 输出: 42%

    // 对数轴的 10 的幂标签
    println(NumberFormat.power10(3))           // 输出: 10^3
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
| [`static tick(value: Float64, step: Float64)`](#tick) | 结合相邻刻度的间距为 `value` 生成刻度标签。 |
| [`static compact(value: Float64, maxDecimals!: Int64)`](#compact) | 通用紧凑标签：最多 `maxDecimals` 位小数，去除尾随零。 |
| [`static fixed(value: Float64, decimals: Int64)`](#fixed) | 固定小数位标签，保留尾随零——用于宽度不应抖动的表格与读数。 |
| [`static scientific(value: Float64, decimals: Int64)`](#scientific) | 科学计数法标签，尾数保留 `decimals` 位小数，如 `1.2e+03`。 |
| [`static percent(value: Float64, decimals!: Int64)`](#percent) | 百分比标签；`0.42` 变为 `42%`。 |
| [`static power10(exponent: Int64)`](#power10) | 对数轴的 10 的幂标签：`1000` 渲染为 `10^3`，接近 1 的值保持朴素写法。 |
| [`static decimalsFor(step: Float64)`](#decimalsfor) | 返回适合刻度间距 `step` 的小数位数。 |

## 构造函数

### init

**由编译器生成：** 该类未声明构造函数且没有未初始化的实例字段，仓颉因此合成此公有无参构造函数。

创建无状态的工具对象；通常直接调用静态成员，无需构造实例。

```cangjie
public init()
```

## 方法

### tick

结合相邻刻度的间距为 `value` 生成刻度标签。由步长决定小数位数，因此步长 0.05 的轴标出 `0.05`，而不是按值自身量级四舍五入得到的 `0.1`。`-0.0` 先归一为 `0.0`，穿过零点的轴不会打出 `-0`。

```cangjie
public static func tick(value: Float64, step: Float64): String
```

**参数**

- `value`: `Float64` — 刻度所在的数据值。
- `step`: `Float64` — 相邻刻度的间距，经 [`decimalsFor`](#decimalsfor) 决定小数位数。

**返回值** `String` — 去除尾随零的标签；量级超出普通十进制可读范围时为科学计数法（1 位尾数小数），非有限值为 `NaN`／`∞`／`-∞`。

### compact

通用紧凑标签：最多 `maxDecimals` 位小数，去除尾随零。

```cangjie
public static func compact(value: Float64, maxDecimals!: Int64 = 3): String
```

**参数**

- `value`: `Float64` — 待格式化的值。
- `maxDecimals!`: `Int64` — 小数位数上限，夹取到 `0..15`；默认 `3`。

**返回值** `String` — 紧凑标签；量级超出普通十进制可读范围时为科学计数法（2 位尾数小数），非有限值为 `NaN`／`∞`／`-∞`。

### fixed

固定小数位标签，保留尾随零——用于宽度不应抖动的表格与读数。

```cangjie
public static func fixed(value: Float64, decimals: Int64): String
```

**参数**

- `value`: `Float64` — 待格式化的值。
- `decimals`: `Int64` — 保留的小数位数，夹取到 `0..15`。

**返回值** `String` — 恰好 `decimals` 位小数的标签（`fixed(1.0, 2)` 得到 `1.00`），非有限值为 `NaN`／`∞`／`-∞`。

### scientific

科学计数法标签，尾数保留 `decimals` 位小数，如 `1.2e+03`。

```cangjie
public static func scientific(value: Float64, decimals: Int64): String
```

**参数**

- `value`: `Float64` — 待格式化的值。
- `decimals`: `Int64` — 尾数的小数位数，夹取到 `0..15`。

**返回值** `String` — 科学计数法文本，非有限值为 `NaN`／`∞`／`-∞`。

### percent

百分比标签；`0.42` 变为 `42%`。值乘以 100 后按 `decimals` 位小数格式化并去除尾随零，再接 `%` 后缀。

```cangjie
public static func percent(value: Float64, decimals!: Int64 = 0): String
```

**参数**

- `value`: `Float64` — 以 1 为满值的比例（`1.0` 即 `100%`）。
- `decimals!`: `Int64` — 小数位数，夹取到 `0..15`；默认 `0`。

**返回值** `String` — 形如 `42%`、`42.6%` 的标签，非有限值为 `NaN`／`∞`／`-∞`（无 `%` 后缀）。

### power10

对数轴的 10 的幂标签：`1000` 渲染为 `10^3`，接近 1 的值保持朴素写法。`10^0` 与 `10^1` 比它们代表的数更难读，因此指数 0 与 1 分别得到 `1` 与 `10`。

```cangjie
public static func power10(exponent: Int64): String
```

**参数**

- `exponent`: `Int64` — 10 的指数，可为负（`-2` 得到 `10^-2`）。

**返回值** `String` — `1`、`10` 或 `10^n` 形式的标签。

### decimalsFor

返回适合刻度间距 `step` 的小数位数。刻度步长总是 1、2 或 5 乘以 10 的幂，因此首位数字不需要超出步长自身量级的额外精度；内部加入 `1e-9` 容差，避免二进制浮点里 `log10(0.1)` 略低于 `-1` 导致每条 0.1 步长的轴多要一位小数。

```cangjie
public static func decimalsFor(step: Float64): Int64
```

**参数**

- `step`: `Float64` — 相邻刻度的间距；非有限或非正时结果为 `0`。

**返回值** `Int64` — 小数位数，夹取到 `0..15`（`decimalsFor(0.05)` 为 `2`，`decimalsFor(20.0)` 为 `0`）。

## 另请参阅

- [`Ticks`](Ticks.md) — 刻度放置；[`Ticks.linear`](Ticks.md#linear) 用 `tick` 生成标签。
- [`Tick`](Tick.md) — 承载标签的刻度值。
