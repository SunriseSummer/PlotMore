[plot](../../index.md) › [plot.core](index.md) › PlotException

# PlotException

`plot.core` 中的 public class

图表描述无法渲染时抛出的异常。触发它的是系列长度不匹配、颜色字面量不合法、对数轴遇到非正值、必需数据集为空这类情况。

## 声明

```cangjie
public class PlotException <: Exception
```

## 继承

父类为标准库的 `Exception`；异常消息通过继承来的 `message` 属性读取。

## 说明

这类错误是图表描述中的编程错误，不是需要恢复的运行期状况；数据仅仅**缺席**的情况（系列没有有限点、轴上没有数据）改以 `Option` 报告，不抛异常。

## 示例

```cangjie verify
package demo

import plot.core.{Colors, PlotException}

main(): Unit {
    try {
        // 5 位十六进制不是任何合法形状
        let _ = Colors.hex("#12345")
        println("不会执行到这里")
    } catch (e: PlotException) {
        println(e.message)
        // 输出: Invalid hex colour '#12345': expected #rgb, #rrggbb or #rrggbbaa.
    }
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(message: String)`](#init) | 以描述违规状况的消息构造异常。 |

## 构造函数

### init

以描述违规状况的消息构造异常。

```cangjie
public init(message: String)
```

**参数**

- `message`: `String` — 异常消息，之后经 `message` 属性读取。

## 另请参阅

- [`Colors.hex`](Colors.md#hex) — 十六进制字面量不合法时抛出本异常。
- [`LogScale.setDomain`](LogScale.md#setdomain) — 对数标度拒绝非正定义域。
- [`Palette.init`](Palette.md#init)、[`Colormap.init`](Colormap.md#init)、[`CategoryScale.init`](CategoryScale.md#init) — 拒绝空的或不足的输入。
- [`Ticks.log10Scale`](Ticks.md#log10scale) — 对数刻度要求严格为正且有限的区间。
