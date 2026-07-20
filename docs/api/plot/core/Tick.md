[plot](../../index.md) › [plot.core](index.md) › Tick

# Tick

`plot.core` 中的 public struct

一个轴刻度：它在数据空间中的位置、标签文本，以及它是带标签与完整网格线的主刻度，还是裸的次级细分。

## 声明

```cangjie
public struct Tick
```

## 示例

```cangjie verify
package demo

import plot.core.Tick

main(): Unit {
    let major = Tick(20.0, "20")
    let minor = Tick(24.0, "", major: false)
    println("${major.label} 主刻度=${major.major}")   // 输出: 20 主刻度=true
    println("${minor.value} 主刻度=${minor.major}")   // 输出: 24.000000 主刻度=false
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(value: Float64, label: String, major!: Bool)`](#init) | 由位置、标签与主/次标记构造刻度；`major` 默认 `true`。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`value`](#value) | 刻度在数据空间中的位置。 |
| [`label`](#label) | 刻度的标签文本。 |
| [`major`](#major) | 是否为主刻度。 |

## 构造函数

### init

由位置、标签与主/次标记构造刻度；`major` 默认 `true`。

```cangjie
public init(value: Float64, label: String, major!: Bool = true)
```

**参数**

- `value`: `Float64` — 刻度所在的数据坐标。
- `label`: `String` — 标签文本。
- `major!`: `Bool` — 是否为主刻度；默认 `true`。

## 字段

### value

刻度在数据空间中的位置。声明为 `let`，构造后不可变。

```cangjie
public let value: Float64
```

### label

刻度的标签文本。本包生成的次刻度以空字符串为标签（见 [`Ticks.linearMinor`](Ticks.md#linearminor)）。

```cangjie
public let label: String
```

### major

是否为主刻度。主刻度携带标签与完整网格线；次刻度只是裸的细分。

```cangjie
public let major: Bool
```

## 另请参阅

- [`Ticks`](Ticks.md) — 生成刻度的放置算法。
- [`Scale.ticks`](Scale.md#ticks) — 每条标度报告自己刻度的入口。
