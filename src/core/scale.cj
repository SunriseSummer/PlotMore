package plot.core

import std.collection.ArrayList
import std.math.{log10, pow}

/**
 * The mapping between a data range and the normalized `0..1` axis position, plus the ticks that
 * annotate it.
 *
 * A scale owns only the data side of the transform. Turning `0..1` into pixels is `Projection`'s
 * job, which is what lets the same scale drive a panel, a legend swatch, and a colour bar.
 */
public abstract class Scale {
    protected var range: Bounds = Bounds(0.0, 1.0)

    /** The data interval this scale currently covers. */
    public func domain(): Bounds {
        range
    }

    /**
     * Replaces the data interval. Implementations reject domains they cannot express — a log scale
     * rejects a domain reaching zero — by throwing `PlotException`.
     */
    public open func setDomain(bounds: Bounds): Unit {
        range = bounds
    }

    /** Maps a data value to `0..1` across the domain. Values outside the domain map outside `0..1`. */
    public func normalize(value: Float64): Float64

    /** The inverse of `normalize`. */
    public func denormalize(t: Float64): Float64

    /** The ticks annotating the current domain. */
    public func ticks(): Array<Tick>

    /** The domain rounded outward to whole ticks, or the domain unchanged when that has no meaning. */
    public open func niceDomain(): Bounds {
        range
    }

    /**
     * Pads a raw data range outward by `fraction` of its extent, ready to display.
     *
     * Additive by default. This is on the scale rather than on `Axes` because the meaning of
     * "5% headroom" depends entirely on the scale's geometry: additive padding is right for a
     * linear axis, meaningless on a log axis (where it can even push the range through zero), and
     * simply wrong on a category axis (whose extent is its categories, not its data).
     */
    public open func padBounds(bounds: Bounds, fraction: Float64): Bounds {
        bounds.expanded(fraction)
    }

    /** Rounds a raw data range outward to whole ticks, ready to display. */
    public open func niceBounds(bounds: Bounds): Bounds {
        Ticks.nice(bounds)
    }

    /**
     * `bounds` zoomed by `factor` about `pivot`, keeping `pivot` at the same normalized position —
     * the transform behind wheel zoom, which has to leave the data under the cursor under the cursor.
     *
     * On the scale for the same reason `padBounds` is: scaling the raw interval is only the right
     * move when the axis is proportional. A log axis has to scale in log space, and scaling it
     * additively instead both drags the anchor off the cursor and can push the range through zero,
     * which the scale then rejects outright.
     */
    public open func zoomAround(bounds: Bounds, pivot: Float64, factor: Float64): Bounds {
        bounds.scaledAround(pivot, factor)
    }

    /** `bounds` slid by `fraction` of the visible extent — the transform behind drag-to-pan. */
    public open func panByFraction(bounds: Bounds, fraction: Float64): Bounds {
        bounds.shifted(bounds.span() * fraction)
    }

    /** True when this scale can express `value` at all (a log scale cannot express zero). */
    public open func accepts(value: Float64): Bool {
        isFinite(value)
    }
}

/**
 * A proportional axis: equal data intervals occupy equal pixel intervals. The default for both
 * axes, and the only correct choice when the data crosses zero.
 */
public class LinearScale <: Scale {
    private var tickTarget: Int64 = 6
    private var minorDivisions: Int64 = 0

    public init() {
        super()
    }

    public init(domain: Bounds) {
        super()
        this.range = domain
    }

    /** Sets roughly how many major ticks to aim for; the exact count depends on the round step. */
    public func setTickTarget(target: Int64): Unit {
        tickTarget = if (target < 2) {
            2
        } else {
            target
        }
    }

    /** How many minor subdivisions sit between majors; 0 disables minor ticks. */
    public func setMinorDivisions(divisions: Int64): Unit {
        minorDivisions = if (divisions < 0) {
            0
        } else {
            divisions
        }
    }

    public func normalize(value: Float64): Float64 {
        let span = range.span()
        if (span <= 0.0) {
            return 0.5
        }
        (value - range.low) / span
    }

    public func denormalize(t: Float64): Float64 {
        range.low + t * range.span()
    }

    public func ticks(): Array<Tick> {
        let major = Ticks.linear(range, target: tickTarget)
        if (minorDivisions < 2) {
            return major
        }
        let all = ArrayList<Tick>(major)
        for (minor in Ticks.linearMinor(range, target: tickTarget, divisions: minorDivisions)) {
            all.add(minor)
        }
        all.toArray()
    }

    public override func niceDomain(): Bounds {
        Ticks.nice(range, target: tickTarget)
    }

    public override func niceBounds(bounds: Bounds): Bounds {
        Ticks.nice(bounds, target: tickTarget)
    }
}

/**
 * A base-10 logarithmic axis, for data spanning orders of magnitude.
 *
 * Zero and negative values have no position on a log axis. Rather than silently dropping them,
 * `setDomain` rejects a non-positive domain and `accepts` reports which values a series may plot,
 * so the caller can decide whether to filter or to switch scales.
 */
public class LogScale <: Scale {
    private var showMinor: Bool = true

    public init() {
        super()
        this.range = Bounds(1.0, 10.0)
    }

    /**
     * Throws `PlotException` when `domain` reaches zero or below.
     */
    public init(domain: Bounds) {
        super()
        requirePositive(domain)
        this.range = domain
    }

    /** Whether the 2…9 subdivisions inside each decade are drawn. */
    public func setMinorTicks(enabled: Bool): Unit {
        showMinor = enabled
    }

    /**
     * Throws `PlotException` when `bounds` reaches zero or below.
     */
    public override func setDomain(bounds: Bounds): Unit {
        requirePositive(bounds)
        super.setDomain(bounds)
    }

    public func normalize(value: Float64): Float64 {
        if (value <= 0.0) {
            return 0.0
        }
        let lowLog = log10(range.low)
        let span = log10(range.high) - lowLog
        if (span <= 0.0) {
            return 0.5
        }
        (log10(value) - lowLog) / span
    }

    public func denormalize(t: Float64): Float64 {
        let lowLog = log10(range.low)
        pow(10.0, lowLog + t * (log10(range.high) - lowLog))
    }

    public func ticks(): Array<Tick> {
        Ticks.log10Scale(range, minorTicks: showMinor)
    }

    public override func niceDomain(): Bounds {
        decadeBounds(range)
    }

    public override func niceBounds(bounds: Bounds): Bounds {
        decadeBounds(clampPositive(bounds))
    }

    /**
     * Pads multiplicatively: the range grows by `fraction` of its extent *in decades*.
     *
     * Additive padding is what a linear axis wants and is meaningless here — 5% of a `[1, 1e6]`
     * span is 50000, which would push the low edge to -49999 and off the axis entirely. Growing by
     * a fraction of a decade is the log-space equivalent, and it cannot cross zero.
     */
    public override func padBounds(bounds: Bounds, fraction: Float64): Bounds {
        let usable = clampPositive(bounds)
        let decades = log10(usable.high) - log10(usable.low)
        // A single-decade range still deserves visible headroom, hence the floor on the pad.
        let pad = max2(decades * fraction, 0.02)
        Bounds(pow(10.0, log10(usable.low) - pad), pow(10.0, log10(usable.high) + pad))
    }

    /**
     * Zooms in log space, which is the only way to keep the anchor under the cursor here: a decade
     * occupies a fixed slice of the axis, so it is the *exponents* that scale, not the values.
     * Scaling the raw interval instead moves the anchor and can hand back a negative low.
     */
    public override func zoomAround(bounds: Bounds, pivot: Float64, factor: Float64): Bounds {
        let usable = clampPositive(bounds)
        if (!isFinite(pivot) || pivot <= 0.0) {
            return usable
        }
        let pivotLog = log10(pivot)
        Bounds(pow(10.0, pivotLog + (log10(usable.low) - pivotLog) * factor),
            pow(10.0, pivotLog + (log10(usable.high) - pivotLog) * factor))
    }

    /** Pans in log space, by a fraction of the visible *decades*; the result cannot reach zero. */
    public override func panByFraction(bounds: Bounds, fraction: Float64): Bounds {
        let usable = clampPositive(bounds)
        let lowLog = log10(usable.low)
        let highLog = log10(usable.high)
        let delta = (highLog - lowLog) * fraction
        Bounds(pow(10.0, lowLog + delta), pow(10.0, highLog + delta))
    }

    /** A log axis can only place strictly positive, finite values. */
    public override func accepts(value: Float64): Bool {
        isFinite(value) && value > 0.0
    }

    /*
     * A displayable positive range from raw data bounds.
     *
     * Series skip non-positive points when drawing (see `accepts`), but `dataBounds` reports the
     * raw data and cannot know which scale it will land on — so autoscale can still hand a range
     * reaching zero here. Flooring six decades below the maximum is what matplotlib does with
     * masked non-positive data, and it beats both throwing (the plottable points are fine) and
     * silently producing an empty axis.
     */
    private static func clampPositive(bounds: Bounds): Bounds {
        if (bounds.low > 0.0) {
            return bounds
        }
        if (bounds.high <= 0.0) {
            throw PlotException(
                "A log axis needs positive data; every value in [${bounds.low}, ${bounds.high}] is zero or " +
                    "negative. Use a linear scale.")
        }
        Bounds(bounds.high * 1.0e-6, bounds.high)
    }

    private static func decadeBounds(bounds: Bounds): Bounds {
        Bounds(pow(10.0, floorTo(log10(bounds.low))), pow(10.0, ceilTo(log10(bounds.high))))
    }

    private static func requirePositive(bounds: Bounds): Unit {
        if (bounds.low <= 0.0) {
            throw PlotException(
                "A log scale needs a strictly positive domain; got [${bounds.low}, ${bounds.high}]. " +
                    "Filter non-positive values or use a linear scale.")
        }
    }
}

/**
 * A discrete axis over named categories, laid out at integer positions `0 … n-1`.
 *
 * The domain is `[-0.5, n-0.5]` so each category owns a full unit-wide band centred on its index —
 * the geometry bar and box charts need to size and centre themselves without knowing the scale type.
 */
public class CategoryScale <: Scale {
    private let labels: Array<String>

    /**
     * Throws `PlotException` when `categories` is empty, which would leave the axis with no extent.
     */
    public init(categories: Array<String>) {
        super()
        if (categories.size == 0) {
            throw PlotException("A category scale needs at least one category.")
        }
        this.labels = categories
        this.range = Bounds(-0.5, Float64(categories.size) - 0.5)
    }

    /** The category names, in axis order. */
    public func categories(): Array<String> {
        labels
    }

    /** How many categories the axis holds. */
    public func count(): Int64 {
        labels.size
    }

    /** The width of one category band in normalized units. */
    public func bandWidth(): Float64 {
        let span = range.span()
        if (span <= 0.0) {
            return 1.0
        }
        1.0 / span
    }

    public func normalize(value: Float64): Float64 {
        let span = range.span()
        if (span <= 0.0) {
            return 0.5
        }
        (value - range.low) / span
    }

    public func denormalize(t: Float64): Float64 {
        range.low + t * range.span()
    }

    public func ticks(): Array<Tick> {
        let result = ArrayList<Tick>()
        for (i in 0..labels.size) {
            result.add(Tick(Float64(i), labels[i]))
        }
        result.toArray()
    }

    /**
     * The category range, ignoring the data.
     *
     * A category axis's extent is its categories: all `n` of them, each in a full band, whether or
     * not a series happens to carry a value for every one. Padding the *data's* range instead would
     * make an axis with a missing trailing category silently shrink, and would add dead space at
     * both ends of one that is complete.
     */
    public override func padBounds(bounds: Bounds, fraction: Float64): Bounds {
        let _ = bounds
        let _ = fraction
        categoryRange()
    }

    public override func niceBounds(bounds: Bounds): Bounds {
        let _ = bounds
        categoryRange()
    }

    private func categoryRange(): Bounds {
        Bounds(-0.5, Float64(labels.size) - 0.5)
    }
}

func floorTo(value: Float64): Float64 {
    let truncated = Float64(Int64(value))
    if (value < 0.0 && truncated != value) {
        truncated - 1.0
    } else {
        truncated
    }
}

func ceilTo(value: Float64): Float64 {
    let truncated = Float64(Int64(value))
    if (value > 0.0 && truncated != value) {
        truncated + 1.0
    } else {
        truncated
    }
}
