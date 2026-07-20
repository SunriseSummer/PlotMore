[plot](../../index.md) › [plot.core](index.md) › CategoryScale

# CategoryScale

`plot.core` 中的 public class

覆盖命名类别的离散轴，类别落在整数位置 `0 … n-1`。定义域为 `[-0.5, n-0.5]`，因此每个类别都拥有以其序号为中心、一个单位宽的完整类别带——[柱状图](../series/BarSeries.md)与[箱线图](../series/BoxPlotSeries.md)无需知道标度类型就能确定自身的宽度与居中。

## 声明

```cangjie
public class CategoryScale <: Scale
```

## 继承

父类为 [`Scale`](Scale.md)。`domain`、`setDomain`、`niceDomain`、`zoomAround`、`panByFraction`、`accepts` 按 Scale 的默认行为继承——类别轴在数据坐标上是线性的，缩放与平移沿用原始区间运算。

## 示例

```cangjie verify
package demo

import plot.core.CategoryScale

main(): Unit {
    let months = CategoryScale(["一月", "二月", "三月", "四月"])
    println(months.count())          // 输出: 4
    println(months.domain())         // 输出: Bounds(-0.500000, 3.500000)
    println(months.bandWidth())      // 输出: 0.250000

    // 类别 1 位于其类别带的中心
    println(months.normalize(1.0))   // 输出: 0.375000

    // 每个类别一个以类别名为标签的主刻度
    let ticks = months.ticks()
    println(ticks[2].label)          // 输出: 三月
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(categories: Array<String>)`](#init) | 由类别名列表创建标度，定义域随之定为 `[-0.5, n-0.5]`。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`categories()`](#categories) | 返回按轴序排列的类别名。 |
| [`count()`](#count) | 返回轴上类别的数量。 |
| [`bandWidth()`](#bandwidth) | 返回单个类别带的宽度，单位为归一化坐标。 |
| [`normalize(value: Float64)`](#normalize) | 把类别位置按定义域比例映射到 `0..1`；退化定义域返回 `0.5`。 |
| [`denormalize(t: Float64)`](#denormalize) | 线性反变换，把归一化位置还原为类别位置。 |
| [`ticks()`](#ticks) | 返回每个类别一个的主刻度，位于其整数位置、以类别名为标签。 |
| [`padBounds(bounds: Bounds, fraction: Float64)`](#padbounds) | 忽略传入的数据范围，返回完整的类别范围 `[-0.5, n-0.5]`。 |
| [`niceBounds(bounds: Bounds)`](#nicebounds) | 忽略传入的区间，返回完整的类别范围。 |

## 构造函数

### init

由类别名列表创建标度，定义域随之定为 `[-0.5, n-0.5]`。

```cangjie
public init(categories: Array<String>)
```

**参数**

- `categories`: `Array<String>` — 按轴序排列的类别名，至少一个。

**异常**

- [`PlotException`](PlotException.md) — `categories` 为空时抛出，否则轴将没有范围可言。

## 方法

### categories

返回按轴序排列的类别名。

```cangjie
public func categories(): Array<String>
```

**返回值** `Array<String>` — 构造时传入的类别名数组。

### count

返回轴上类别的数量。

```cangjie
public func count(): Int64
```

**返回值** `Int64` — 类别数，构造保证至少为 1。

### bandWidth

返回单个类别带的宽度，单位为归一化坐标。`n` 个类别的轴上即 `1/n`；定义域宽度不为正时返回 `1.0`。

```cangjie
public func bandWidth(): Float64
```

**返回值** `Float64` — 归一化坐标下的类别带宽度。

### normalize

把类别位置按定义域比例映射到 `0..1`；退化定义域返回 `0.5`。类别 `i` 的中心映射到其类别带的中点。

```cangjie
public func normalize(value: Float64): Float64
```

**参数**

- `value`: `Float64` — 数据坐标下的位置；类别 `i` 的中心即 `Float64(i)`。

**返回值** `Float64` — 归一化位置。

### denormalize

线性反变换，把归一化位置还原为类别位置。

```cangjie
public func denormalize(t: Float64): Float64
```

**参数**

- `t`: `Float64` — 归一化位置。

**返回值** `Float64` — 数据坐标下的位置（不取整；四舍五入到最近整数即最近类别）。

### ticks

返回每个类别一个的主刻度，位于其整数位置、以类别名为标签。

```cangjie
public func ticks(): Array<Tick>
```

**返回值** `Array<Tick>` — `count()` 个主[刻度](Tick.md)，`ticks()[i].value` 为 `Float64(i)`、`label` 为对应类别名。

### padBounds

忽略传入的数据范围，返回完整的类别范围 `[-0.5, n-0.5]`。类别轴的范围就是它的类别：全部 `n` 个、每个一条完整类别带，无论系列是否恰好覆盖每一类。改为对**数据**范围留白，会让缺了末尾类别的轴悄悄收缩，也会给完整的轴平添两端的死空间。

```cangjie
public override func padBounds(bounds: Bounds, fraction: Float64): Bounds
```

**参数**

- `bounds`: `Bounds` — 被忽略。
- `fraction`: `Float64` — 被忽略。

**返回值** `Bounds` — 完整的类别范围 `[-0.5, n-0.5]`。

### niceBounds

忽略传入的区间，返回完整的类别范围。

```cangjie
public override func niceBounds(bounds: Bounds): Bounds
```

**参数**

- `bounds`: `Bounds` — 被忽略。

**返回值** `Bounds` — 完整的类别范围 `[-0.5, n-0.5]`。

## 另请参阅

- [`Scale`](Scale.md) — 抽象基类。
- [`Tick`](Tick.md) — 类别刻度的载体。
- [`BarSeries`](../series/BarSeries.md)、[`BoxPlotSeries`](../series/BoxPlotSeries.md) — 依赖类别带几何的系列。
