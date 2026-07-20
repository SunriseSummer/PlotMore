[plot](../index.md) › [plot](index.md) › WindowOptions

# WindowOptions

`plot` 中的 public struct

窗口的标题、初始尺寸与是否可调整大小。传给 [PlotWindow](PlotWindow.md) 的构造函数，在 [show](PlotWindow.md#show) 打开系统窗口时生效；各字段均为只读，需要不同配置就构造新值。

## 声明

```cangjie
public struct WindowOptions
```

## 示例

```cangjie verify
package demo

import plot.{Figure, PlotWindow, WindowOptions}

main(): Unit {
    let options = WindowOptions(title: "传感器面板", width: 1280, height: 720, resizable: false)
    // 构造 PlotWindow 不创建任何系统资源；系统窗口在 show() 时才打开。
    let window = PlotWindow(Figure("传感器读数"), options: options)
    window.show()
    // 交互结果：显示 1280×720 的不可缩放窗口，标题为「传感器面板」。
}
```

## 成员概览

**构造函数**

| 成员 | 说明 |
|---|---|
| [`init(...)`](#init) | 以命名参数构造窗口选项；未给出的参数取默认值。 |

**字段**

| 成员 | 说明 |
|---|---|
| [`title`](#title) | 窗口标题栏文字。 |
| [`width`](#width) | 窗口的初始宽度，单位像素。 |
| [`height`](#height) | 窗口的初始高度，单位像素。 |
| [`resizable`](#resizable) | 用户能否拖拽调整窗口大小。 |

## 构造函数

### init

以命名参数构造窗口选项；未给出的参数取默认值。

```cangjie
public init(title!: String = "Plot", width!: Int64 = 980, height!: Int64 = 640, resizable!: Bool = true)
```

**参数**

- `title!`: `String` — 窗口标题栏文字；默认 `"Plot"`。
- `width!`: `Int64` — 窗口初始宽度，单位像素；默认 `980`。
- `height!`: `Int64` — 窗口初始高度，单位像素；默认 `640`。
- `resizable!`: `Bool` — 用户能否拖拽调整窗口大小；默认 `true`。

## 字段

### title

窗口标题栏文字。

```cangjie
public let title: String
```

### width

窗口的初始宽度，单位像素。

```cangjie
public let width: Int64
```

### height

窗口的初始高度，单位像素。

```cangjie
public let height: Int64
```

### resizable

用户能否拖拽调整窗口大小。

```cangjie
public let resizable: Bool
```

## 另请参阅

- [PlotWindow](PlotWindow.md) —— 使用这些选项打开窗口
