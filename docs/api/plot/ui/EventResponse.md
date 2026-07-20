[plot](../../index.md) › [plot.ui](index.md) › EventResponse

# EventResponse

`plot.ui` 中的 public struct

组件事件处理的结果：告知窗口事件是否已被消费、画面是否需要重绘。两个标志真正独立——悬停只改变外观而不消费事件，点击则既消费又要求重绘。三个静态工厂 [ignored](#ignored)、[repaint](#repaint)、[handled](#handled) 覆盖常见组合。

## 声明

```cangjie
public struct EventResponse
```

## 示例

```cangjie verify
package demo

import plot.ui.EventResponse

main(): Unit {
    let hover = EventResponse.repaint() // 悬停：外观变了，但事件继续传递
    println("${hover.consumed} ${hover.redraw}") // 输出: false true
    let click = EventResponse.handled() // 点击：既消费也要求重绘
    println("${click.consumed} ${click.redraw}") // 输出: true true
    let custom = EventResponse(consumed: true) // 消费但无需重绘
    println("${custom.consumed} ${custom.redraw}") // 输出: true false
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 按给定标志构造响应。 |

**方法**

| 成员 | 说明 |
|---|---|
| [`static ignored()`](#ignored) | 返回表示事件未被使用、也未改变任何状态的响应。 |
| [`static repaint()`](#repaint) | 返回表示事件改变了外观、但仍应继续传给其他处理者的响应。 |
| [`static handled()`](#handled) | 返回表示事件已被完全处理的响应。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`consumed`](#consumed) | 为 `true` 时组件已处理该事件，窗口不应再继续分发。 |
| [`redraw`](#redraw) | 为 `true` 时窗口应当重绘。 |

## 构造函数

### init

按给定标志构造响应。两个具名参数默认均为 `false`，等价于 `ignored()`。

```cangjie
public init(consumed!: Bool = false, redraw!: Bool = false)
```

**参数**

- `consumed!`: `Bool` — 事件是否已被消费，默认 `false`。
- `redraw!`: `Bool` — 是否需要重绘，默认 `false`。

## 方法

### ignored

返回表示事件未被使用、也未改变任何状态的响应。[Component.handle](Component.md#handle) 的默认实现返回它。

```cangjie
public static func ignored(): EventResponse
```

**返回值** `EventResponse` — `consumed` 与 `redraw` 均为 `false`。

### repaint

返回表示事件改变了外观、但仍应继续传给其他处理者的响应。悬停高亮是典型场景：组件要重绘，但窗口自己的十字光标仍需要这次指针移动。

```cangjie
public static func repaint(): EventResponse
```

**返回值** `EventResponse` — `consumed` 为 `false`，`redraw` 为 `true`。

### handled

返回表示事件已被完全处理的响应。窗口不再继续分发，并安排一次重绘。

```cangjie
public static func handled(): EventResponse
```

**返回值** `EventResponse` — `consumed` 与 `redraw` 均为 `true`。

## 字段

### consumed

为 `true` 时组件已处理该事件，窗口不应再继续分发。

```cangjie
public let consumed: Bool
```

### redraw

为 `true` 时窗口应当重绘。

```cangjie
public let redraw: Bool
```

## 另请参阅

- [Component.handle](Component.md#handle)
- [Toolbar.handle](Toolbar.md#handle)
