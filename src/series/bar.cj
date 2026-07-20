package plot.series

import sdl.{Color, Rect}
import plot.canvas.{Canvas, HAlign, VAlign}
import plot.core.{Bounds, Colors, NumberFormat, PlotException, Projection, Theme, isFinite}

/** Which way bars grow. */
public enum BarOrientation {
    /** Bars rise from the x axis; categories along x. */
    | Vertical

    /** Bars extend from the y axis; categories along y. */
    | Horizontal
}

/**
 * Bars at integer category positions.
 *
 * The category axis is expected to be a `CategoryScale`, which places category `i` at data
 * coordinate `i` inside a unit-wide band — this series sizes itself to that band, so bar width
 * follows the axis rather than being guessed in pixels.
 *
 * Grouping and stacking are properties of a *set* of bar series, not of one bar series, so they are
 * arranged by `BarGroup` rather than configured here.
 *
 * ```
 * axes.setXScale(CategoryScale(["Q1", "Q2", "Q3", "Q4"]))
 * axes.add(BarSeries([12.0, 19.0, 7.0, 15.0], label: "revenue"))
 * ```
 */
public class BarSeries <: Series {
    private let values: Array<Float64>

    /** Which way the bars grow. Must match how the owning axes assigned its scales. */
    public var orientation: BarOrientation = BarOrientation.Vertical

    /** Fraction of the category band the bar occupies, `0..1`. The remainder is the gap. */
    public var bandFraction: Float64 = 0.7

    /** Corner rounding on the bar's growing end, in logical pixels. */
    public var cornerRadius: Float32 = 3.0

    /** The value bars grow from; usually zero. */
    public var baseline: Float64 = 0.0

    /** Prints each bar's value at its tip. */
    public var showValues: Bool = false

    /** Decimal places for `showValues`; `None` picks a compact form per value. */
    public var valueDecimals: ?Int64 = None

    // Set by BarGroup when several series share the category axis.
    private var slot: Int64 = 0
    private var slotCount: Int64 = 1
    private var stackBase: ?Array<Float64> = None

    public init(values: Array<Float64>, label!: String = "") {
        super()
        this.values = values
        this.label = label
    }

    /** The bar values, in category order. */
    public func barValues(): Array<Float64> {
        values
    }

    /** How many bars this series holds. */
    public func count(): Int64 {
        values.size
    }

    /**
     * Places this series in slot `index` of `total` side-by-side slots within each category band.
     * Called by `BarGroup.grouped`; calling it directly is only useful for custom arrangements.
     */
    public func setSlot(index: Int64, total: Int64): Unit {
        slot = index
        slotCount = if (total < 1) {
            1
        } else {
            total
        }
    }

    /**
     * Stacks this series on top of `base`, one running total per category. Called by
     * `BarGroup.stacked`.
     *
     * Throws `PlotException` when `base` does not match the bar count.
     */
    public func setStackBase(base: Array<Float64>): Unit {
        if (base.size != values.size) {
            throw PlotException("A stack base needs ${values.size} entries to match the bars; got ${base.size}.")
        }
        stackBase = Some(base)
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        if (values.size == 0) {
            return None
        }
        var low = baseline
        var high = baseline
        var seen = false
        for (i in 0..values.size) {
            if (!isFinite(values[i])) {
                continue
            }
            let bottom = stackBaseAt(i)
            let top = bottom + values[i]
            if (!seen) {
                low = minOf(baseline, minOf(bottom, top))
                high = maxOf(baseline, maxOf(bottom, top))
                seen = true
            } else {
                low = minOf(low, minOf(bottom, top))
                high = maxOf(high, maxOf(bottom, top))
            }
        }
        if (!seen) {
            return None
        }
        let categoryBounds = Bounds(-0.5, Float64(values.size) - 0.5)
        let valueBounds = Bounds(low, high)
        match (orientation) {
            case Vertical => Some((categoryBounds, valueBounds))
            case Horizontal => Some((valueBounds, categoryBounds))
        }
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let fill = resolveColor(theme)
        for (i in 0..values.size) {
            if (!isFinite(values[i])) {
                continue
            }
            let rect = barRect(i, projection)
            if (rect.w <= 0.0 || rect.h <= 0.0) {
                continue
            }
            drawBar(canvas, rect, fill, values[i] >= 0.0)
            if (showValues) {
                drawValueLabel(canvas, rect, i, theme)
            }
        }
    }

    public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult {
        for (i in 0..values.size) {
            if (!isFinite(values[i])) {
                continue
            }
            let rect = barRect(i, projection)
            // A bar is a target over its whole area, not just at its tip — the nearest-point rule
            // that suits lines would make a tall bar unhittable except at the very top.
            if (!rect.contains(px, py)) {
                continue
            }
            let bottom = stackBaseAt(i)
            let top = bottom + values[i]
            let (dataX, dataY) = match (orientation) {
                case Vertical => (Float64(i), top)
                case Horizontal => (top, Float64(i))
            }
            let text = "${label}: ${NumberFormat.compact(values[i])}"
            return Some(HitResult(label, dataX, dataY, rect.centerX(), rect.y, 0.0, resolveColor(theme), text))
        }
        None
    }

    /** The pixel rectangle of bar `index` under `projection`. */
    public func barRect(index: Int64, projection: Projection): Rect {
        let bottom = stackBaseAt(index)
        let top = bottom + values[index]
        let band = bandFraction / Float64(slotCount)
        // Centre the slot group on the category, then offset to this series' slot.
        let offset = (Float64(slot) - Float64(slotCount - 1) / 2.0) * band
        let center = Float64(index) + offset
        let half = band / 2.0
        match (orientation) {
            case Vertical =>
                let x1 = projection.pixelX(center - half)
                let x2 = projection.pixelX(center + half)
                let y1 = projection.pixelY(bottom)
                let y2 = projection.pixelY(top)
                Rect(minOfF(x1, x2), minOfF(y1, y2), absF(x2 - x1), absF(y2 - y1))
            case Horizontal =>
                let y1 = projection.pixelY(center - half)
                let y2 = projection.pixelY(center + half)
                let x1 = projection.pixelX(bottom)
                let x2 = projection.pixelX(top)
                Rect(minOfF(x1, x2), minOfF(y1, y2), absF(x2 - x1), absF(y2 - y1))
        }
    }

    private func stackBaseAt(index: Int64): Float64 {
        match (stackBase) {
            case Some(base) => base[index]
            case None => baseline
        }
    }

    /*
     * Rounds only the growing end, so a stack reads as one column with a single rounded cap rather
     * than as a pile of separate lozenges. A bar shorter than its own radius gets none, which is
     * what stops a tiny value from rendering as a circle.
     */
    private func drawBar(canvas: Canvas, rect: Rect, fill: Color, positive: Bool): Unit {
        let radius = minOfF(cornerRadius, minOfF(rect.w, rect.h) / 2.0)
        if (radius <= 0.5) {
            canvas.fillRect(rect, fill)
            return
        }
        match (orientation) {
            case Vertical =>
                if (positive) {
                    canvas.fillPerCornerRect(rect, fill, topLeft: radius, topRight: radius, bottomRight: 0.0,
                        bottomLeft: 0.0)
                } else {
                    canvas.fillPerCornerRect(rect, fill, topLeft: 0.0, topRight: 0.0, bottomRight: radius,
                        bottomLeft: radius)
                }
            case Horizontal =>
                if (positive) {
                    canvas.fillPerCornerRect(rect, fill, topLeft: 0.0, topRight: radius, bottomRight: radius,
                        bottomLeft: 0.0)
                } else {
                    canvas.fillPerCornerRect(rect, fill, topLeft: radius, topRight: 0.0, bottomRight: 0.0,
                        bottomLeft: radius)
                }
        }
    }

    private func drawValueLabel(canvas: Canvas, rect: Rect, index: Int64, theme: Theme): Unit {
        let text = match (valueDecimals) {
            case Some(places) => NumberFormat.fixed(values[index], places)
            case None => NumberFormat.compact(values[index])
        }
        let positive = values[index] >= 0.0
        // A stacked segment labels inside itself; a free-standing bar labels just past its tip.
        let inside = stackBase.isSome()
        match (orientation) {
            case Vertical =>
                let y = if (inside) {
                    rect.centerY()
                } else if (positive) {
                    rect.y - 4.0
                } else {
                    rect.bottom() + 4.0
                }
                let align = if (inside) {
                    VAlign.Middle
                } else if (positive) {
                    VAlign.Bottom
                } else {
                    VAlign.Top
                }
                canvas.textAnchored(text, rect.centerX(), y, labelColor(theme, inside), size: theme.annotationSize,
                    hAlign: HAlign.Center, vAlign: align)
            case Horizontal =>
                let x = if (inside) {
                    rect.centerX()
                } else if (positive) {
                    rect.right() + 4.0
                } else {
                    rect.x - 4.0
                }
                let align = if (inside) {
                    HAlign.Center
                } else if (positive) {
                    HAlign.Left
                } else {
                    HAlign.Right
                }
                canvas.textAnchored(text, x, rect.centerY(), labelColor(theme, inside), size: theme.annotationSize,
                    hAlign: align, vAlign: VAlign.Middle)
        }
    }

    private func labelColor(theme: Theme, inside: Bool): Color {
        if (inside) {
            Colors.contrastText(resolveColor(theme))
        } else {
            theme.mutedText
        }
    }
}

/**
 * Arranges several `BarSeries` that share one category axis.
 *
 * Grouping and stacking are relationships *between* series — a bar cannot know its slot or its
 * stack base from its own values alone — so they are set here, once, rather than being configured
 * on each series and left to agree by luck.
 */
public class BarGroup {
    /**
     * Places the series side by side within each category band, in argument order.
     *
     * Throws `PlotException` when the series have differing bar counts, which would misalign the
     * groups against the categories.
     */
    public static func grouped(series: Array<BarSeries>): Array<BarSeries> {
        requireUniformCounts(series, "grouped")
        for (i in 0..series.size) {
            series[i].setSlot(i, series.size)
        }
        series
    }

    /**
     * Stacks the series in argument order, each starting where the previous one ended.
     *
     * Throws `PlotException` when the series have differing bar counts.
     */
    public static func stacked(series: Array<BarSeries>): Array<BarSeries> {
        requireUniformCounts(series, "stacked")
        if (series.size == 0) {
            return series
        }
        let count = series[0].count()
        // Positive and negative values stack away from the baseline independently, so a mixed-sign
        // stack grows up and down from zero instead of cancelling into an unreadable overlap.
        let positiveTotals = Array<Float64>(count, repeat: 0.0)
        let negativeTotals = Array<Float64>(count, repeat: 0.0)
        for (current in series) {
            let base = Array<Float64>(count, repeat: 0.0)
            let values = current.barValues()
            for (i in 0..count) {
                let value = values[i]
                if (!isFinite(value)) {
                    continue
                }
                if (value >= 0.0) {
                    base[i] = positiveTotals[i]
                    positiveTotals[i] += value
                } else {
                    base[i] = negativeTotals[i]
                    negativeTotals[i] += value
                }
            }
            current.setStackBase(base)
            current.setSlot(0, 1)
        }
        series
    }

    private static func requireUniformCounts(series: Array<BarSeries>, context: String): Unit {
        if (series.size <= 1) {
            return
        }
        let expected = series[0].count()
        for (i in 1..series.size) {
            if (series[i].count() != expected) {
                throw PlotException(
                    "BarGroup.${context} needs every series to have the same bar count; " +
                        "series 0 has ${expected} and series ${i} has ${series[i].count()}.")
            }
        }
    }
}

func minOf(a: Float64, b: Float64): Float64 {
    if (a < b) {
        a
    } else {
        b
    }
}

func maxOf(a: Float64, b: Float64): Float64 {
    if (a > b) {
        a
    } else {
        b
    }
}

func minOfF(a: Float32, b: Float32): Float32 {
    if (a < b) {
        a
    } else {
        b
    }
}

func absF(value: Float32): Float32 {
    if (value < 0.0) {
        -value
    } else {
        value
    }
}
