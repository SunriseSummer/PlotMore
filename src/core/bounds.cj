package plot.core

import std.math.abs

/**
 * A closed numeric interval `[low, high]` on a single axis — the data range a scale maps from.
 *
 * Bounds are always constructed in ascending order (`of` swaps reversed input), so `span` is never
 * negative. A bound whose `low` equals `high` is *degenerate*: a single data value, or a constant
 * series. Degenerate bounds are legal to construct but cannot be mapped to a pixel range without
 * dividing by zero, so callers pad them with `padded` before building a projection.
 */
public struct Bounds <: ToString & Equatable<Bounds> {
    public let low: Float64
    public let high: Float64

    /** Creates bounds from an already-ordered pair; prefer `of` unless the order is known. */
    public init(low: Float64, high: Float64) {
        this.low = low
        this.high = high
    }

    /** Creates bounds from two values in any order. */
    public static func of(a: Float64, b: Float64): Bounds {
        if (a <= b) {
            Bounds(a, b)
        } else {
            Bounds(b, a)
        }
    }

    /**
     * The tightest bounds covering every finite value, or `None` when the input holds no finite
     * value at all. NaN and infinities are skipped rather than poisoning the range, which is what
     * lets a series carry gaps.
     */
    public static func cover(values: Array<Float64>): ?Bounds {
        var low = 0.0
        var high = 0.0
        var seen = false
        for (value in values) {
            if (!isFinite(value)) {
                continue
            }
            if (!seen) {
                low = value
                high = value
                seen = true
            } else {
                if (value < low) {
                    low = value
                }
                if (value > high) {
                    high = value
                }
            }
        }
        if (seen) {
            Some(Bounds(low, high))
        } else {
            None
        }
    }

    /** The width of the interval; zero for degenerate bounds. */
    public func span(): Float64 {
        high - low
    }

    /** The arithmetic midpoint. */
    public func center(): Float64 {
        low + (high - low) / 2.0
    }

    /** True when `value` lies within the interval, edges included. */
    public func contains(value: Float64): Bool {
        value >= low && value <= high
    }

    /** True when the interval covers a single point and so cannot be mapped to a pixel range. */
    public func isDegenerate(): Bool {
        span() <= 0.0
    }

    /** The smallest bounds covering both intervals. */
    public func union(other: Bounds): Bounds {
        Bounds(min2(low, other.low), max2(high, other.high))
    }

    /** Grows the interval by `fraction` of its span on both sides (0.05 = 5% headroom each side). */
    public func expanded(fraction: Float64): Bounds {
        let delta = span() * fraction
        Bounds(low - delta, high + delta)
    }

    /** Grows the interval by an absolute amount on both sides. */
    public func padded(amount: Float64): Bounds {
        Bounds(low - amount, high + amount)
    }

    /**
     * A non-degenerate version of these bounds: already-wide bounds are returned unchanged, while a
     * single-point interval is opened up around that point. A zero value widens to `[-1, 1]` rather
     * than staying collapsed, since a relative pad of zero is still zero.
     */
    public func nonDegenerate(): Bounds {
        if (!isDegenerate()) {
            return this
        }
        let magnitude = abs(low)
        if (magnitude <= 0.0) {
            Bounds(-1.0, 1.0)
        } else {
            padded(magnitude * 0.5)
        }
    }

    /** Moves both edges by `delta`. */
    public func shifted(delta: Float64): Bounds {
        Bounds(low + delta, high + delta)
    }

    /** Scales the interval around `pivot` by `factor` (< 1 zooms in, > 1 zooms out). */
    public func scaledAround(pivot: Float64, factor: Float64): Bounds {
        Bounds(pivot + (low - pivot) * factor, pivot + (high - pivot) * factor)
    }

    public func toString(): String {
        "Bounds(${low}, ${high})"
    }

    public operator func ==(other: Bounds): Bool {
        low == other.low && high == other.high
    }

    public operator func !=(other: Bounds): Bool {
        !(this == other)
    }
}

/** True when `value` is neither NaN nor infinite — the guard every data ingest path runs first. */
public func isFinite(value: Float64): Bool {
    !value.isNaN() && !value.isInf()
}

func min2(a: Float64, b: Float64): Float64 {
    if (a < b) {
        a
    } else {
        b
    }
}

func max2(a: Float64, b: Float64): Float64 {
    if (a > b) {
        a
    } else {
        b
    }
}
