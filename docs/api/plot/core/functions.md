[plot](../../index.md) › [plot.core](index.md) › 函数

# 函数 — plot.core

### isFinite

当 `value` 既非 NaN 也非无穷时返回 `true`——每条数据摄入路径最先执行的守卫。[`Bounds.cover`](Bounds.md#cover) 靠它跳过缺口值，[`Scale.accepts`](Scale.md#accepts) 的默认实现就是它。

```cangjie
public func isFinite(value: Float64): Bool
```

**参数**

- `value`: `Float64` — 待检验的值。

**返回值** `Bool` — `value` 为有限数时为 `true`；NaN、`∞`、`-∞` 均为 `false`。

```cangjie
isFinite(1.5)            // true
isFinite(Float64.NaN)    // false
isFinite(Float64.Inf)    // false
```

### floorMod

把 `value` 归约到大于等于 `0` 且小于 `modulus` 的范围。仓颉的 `%` 只支持整数，而本函数保持真正 floor 取模的符号约定：负的色相向前回绕而不是向后——[`Colors.hsl`](Colors.md#hsl) 用它回绕色相。非正的 `modulus` 没有有意义的答案，直接返回 `0.0` 而不是除以它。

```cangjie
public func floorMod(value: Float64, modulus: Float64): Float64
```

**参数**

- `value`: `Float64` — 待归约的值，可为负。
- `modulus`: `Float64` — 模数；为零或负时结果为 `0.0`。

**返回值** `Float64` — 落在 `[0, modulus)` 内的余数。

```cangjie
floorMod(370.0, 360.0)   // 10.0
floorMod(-10.0, 360.0)   // 350.0（负值向前回绕）
floorMod(5.0, 0.0)       // 0.0（非正模数返回 0）
```
