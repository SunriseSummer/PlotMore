package plot.core

import std.collection.ArrayList
import std.math.{abs, ceil, floor, log10, pow}

/** 2^53: where Float64 stops resolving consecutive integers, and so where tick multiples stop meaning anything. */
const EXACT_INTEGER: Float64 = 9.007199254740992e15

/**
 * One axis tick: where it sits in data space, what it is labelled, and whether it carries a label
 * and a full gridline (`major`) or is a bare minor subdivision.
 */
public struct Tick {
    public let value: Float64
    public let label: String
    public let major: Bool

    public init(value: Float64, label: String, major!: Bool = true) {
        this.value = value
        this.label = label
        this.major = major
    }
}

/**
 * Tick placement.
 *
 * Ticks land on *round* numbers rather than on the data's own extremes: an axis over `[3.7, 91.2]`
 * ticks at 0, 20, 40, 60, 80, not at 3.7 and 91.2. Round positions are what make a chart readable
 * at a glance, and the cost — ticks that do not reach the very edge of the panel — is invisible.
 */
public class Ticks {
    /**
     * Rounds a raw spacing up to the next 1, 2, 5 or 10 times a power of ten. Restricting steps to
     * this set is what keeps labels short and mentally divisible; arbitrary steps like 3.7 are
     * technically valid and practically unreadable.
     */
    public static func niceStep(rawStep: Float64): Float64 {
        if (!isFinite(rawStep) || rawStep <= 0.0) {
            return 1.0
        }
        let magnitude = pow(10.0, floor(log10(rawStep)))
        let residual = rawStep / magnitude
        let factor = if (residual <= 1.0) {
            1.0
        } else if (residual <= 2.0) {
            2.0
        } else if (residual <= 5.0) {
            5.0
        } else {
            10.0
        }
        factor * magnitude
    }

    /**
     * Major ticks across `bounds`, aiming for about `target` of them. The count is approximate by
     * design: honouring it exactly would require unround steps.
     */
    public static func linear(bounds: Bounds, target!: Int64 = 6): Array<Tick> {
        let step = linearStep(bounds, target)
        let result = ArrayList<Tick>()
        for ((_, value) in stepValues(bounds, step)) {
            result.add(Tick(value, NumberFormat.tick(value, step)))
        }
        result.toArray()
    }

    /** The spacing `linear` would use — needed by callers that format their own labels. */
    public static func linearStep(bounds: Bounds, target: Int64): Float64 {
        let count = if (target < 2) {
            2
        } else {
            target
        }
        let span = bounds.span()
        if (!isFinite(span) || span <= 0.0) {
            return 1.0
        }
        niceStep(span / Float64(count))
    }

    /**
     * Minor ticks subdividing each major interval into `divisions`, excluding the major positions
     * themselves. Empty when `divisions` is below 2.
     */
    public static func linearMinor(bounds: Bounds, target!: Int64 = 6, divisions!: Int64 = 5): Array<Tick> {
        if (divisions < 2) {
            return []
        }
        let step = linearStep(bounds, target)
        let minorStep = step / Float64(divisions)
        let result = ArrayList<Tick>()
        for ((multiple, value) in stepValues(bounds, minorStep)) {
            // Skip positions that coincide with a major tick. What decides that is the value's own
            // multiple of the minor step — every `divisions`-th multiple is a major — not its
            // position in this list, which is offset by wherever the axis happens to start.
            // Comparing multiples avoids the float equality test that CJ-EXP-08 rules out.
            if (multiple % divisions != 0) {
                result.add(Tick(value, "", major: false))
            }
        }
        result.toArray()
    }

    /**
     * Decade ticks (…, 0.1, 1, 10, 100, …) covering `bounds`, which must be strictly positive.
     * When the range spans few decades, the 2…9 subdivisions are added as labelled minor ticks so
     * a two-decade axis is not left with three lonely labels.
     *
     * Throws `PlotException` when `bounds` reaches zero or below, which no log axis can express.
     */
    public static func log10Scale(bounds: Bounds, minorTicks!: Bool = true): Array<Tick> {
        if (bounds.low <= 0.0) {
            throw PlotException("A log axis needs strictly positive bounds; got [${bounds.low}, ${bounds.high}].")
        }
        // Finiteness is checked here too, not just positivity: an infinite bound would reach the
        // Int64 casts below and trap there instead of surfacing as the exception this documents.
        if (!isFinite(bounds.low) || !isFinite(bounds.high)) {
            throw PlotException("A log axis needs finite bounds; got [${bounds.low}, ${bounds.high}].")
        }
        let lowExp = Int64(floor(log10(bounds.low)))
        let highExp = Int64(ceil(log10(bounds.high)))
        let decades = highExp - lowExp
        let result = ArrayList<Tick>()
        var exp = lowExp
        while (exp <= highExp) {
            let base = pow(10.0, Float64(exp))
            if (base >= bounds.low && base <= bounds.high) {
                result.add(Tick(base, NumberFormat.power10(exp)))
            }
            if (minorTicks && decades <= 3) {
                var multiple = 2
                while (multiple <= 9) {
                    let value = base * Float64(multiple)
                    if (value >= bounds.low && value <= bounds.high) {
                        // Only 2 and 5 get labels: nine labels per decade collide at any sane width.
                        let label = if (decades <= 2 && (multiple == 2 || multiple == 5)) {
                            NumberFormat.compact(value)
                        } else {
                            ""
                        }
                        result.add(Tick(value, label, major: false))
                    }
                    multiple += 1
                }
            }
            exp += 1
        }
        result.toArray()
    }

    /**
     * Bounds widened outward to the nearest round step, so the axis ends on a labelled tick rather
     * than mid-interval. This is what `Axes` applies when a range is left to the data.
     */
    public static func nice(bounds: Bounds, target!: Int64 = 6): Bounds {
        let usable = bounds.nonDegenerate()
        let step = linearStep(usable, target)
        if (!isFinite(step) || step <= 0.0) {
            return usable
        }
        Bounds(floor(usable.low / step) * step, ceil(usable.high / step) * step)
    }

    /*
     * Every multiple of `step` inside `bounds`, each paired with the multiple itself. Iterating by
     * index rather than accumulating keeps rounding error from drifting across a long axis, and the
     * multiple is what lets `linearMinor` tell a minor position from a major one.
     */
    private static func stepValues(bounds: Bounds, step: Float64): Array<(Int64, Float64)> {
        let result = ArrayList<(Int64, Float64)>()
        if (!isFinite(step) || step <= 0.0) {
            return result.toArray()
        }
        let first = ceil(bounds.low / step - 1.0e-9)
        let last = floor(bounds.high / step + 1.0e-9)
        // Everything is bounded in float space before any conversion: Int64() traps on a non-finite
        // or out-of-range cast, so bounds reaching infinity — which padding a range that already
        // spans most of Float64 produces — would escape as an OverflowException rather than as the
        // empty tick list this guard is here to return. Past EXACT_INTEGER a Float64 no longer
        // resolves consecutive integers, so a tick multiple has no meaning there either.
        if (!isFinite(first) || !isFinite(last) || abs(first) > EXACT_INTEGER) {
            return result.toArray()
        }
        let count = last - first
        if (count < 0.0 || count > 10000.0) {
            return result.toArray()
        }
        let firstMultiple = Int64(first)
        for (i in 0..=Int64(count)) {
            let multiple = firstMultiple + i
            let value = Float64(multiple) * step
            // Snap the zero crossing: 3*0.1 is 0.30000000000000004, and an axis labelled
            // "0.30000000000000004" is a bug the user sees.
            let snapped = if (abs(value) < step * 1.0e-9) {
                0.0
            } else {
                value
            }
            if (snapped >= bounds.low - step * 1.0e-9 && snapped <= bounds.high + step * 1.0e-9) {
                result.add((multiple, snapped))
            }
        }
        result.toArray()
    }
}
