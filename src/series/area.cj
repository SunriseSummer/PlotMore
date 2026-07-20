package plot.series

import std.collection.ArrayList
import sdl.{Color, Pen, Point, Rect}
import plot.canvas.Canvas
import plot.core.{Bounds, Colors, Projection, Theme, isFinite}

/**
 * A filled region between a series and a baseline, or between two series.
 *
 * `AreaSeries(xs, ys)` fills from the curve down to zero. `AreaSeries(xs, upper, lower)` fills the
 * band between two curves — a confidence interval, a min/max envelope, a tolerance corridor.
 *
 * Stacking several areas is `AreaStack`'s job, since a stack's baselines depend on its neighbours.
 *
 * ```
 * let band = AreaSeries.between(xs, lowerBound, upperBound, label: "95% CI")
 * band.opacity = 0.25
 * ```
 */
public class AreaSeries <: Series {
    private let xs: Array<Float64>
    private let upper: Array<Float64>
    private let lower: Array<Float64>

    /** Fill opacity at the upper edge, `0..1`. */
    public var fillOpacity: Float64 = 0.3

    /** Fill opacity at the lower edge; below `fillOpacity` gives a gradient fade. */
    public var fadeOpacity: Float64 = 0.3

    /** Strokes the upper boundary, so the series' own curve stays legible against its fill. */
    public var showEdge: Bool = true

    /** Edge width; `None` follows `theme.lineWidth`. */
    public var edgeWidth: ?Float32 = None

    /**
     * Throws `PlotException` when the arrays differ in length.
     */
    public init(xs: Array<Float64>, ys: Array<Float64>, baseline!: Float64 = 0.0, label!: String = "") {
        super()
        requireSameLength(xs, ys, "AreaSeries")
        this.xs = xs
        this.upper = ys
        this.lower = Array<Float64>(ys.size, repeat: baseline)
        this.label = label
        this.fadeOpacity = 0.04
    }

    /**
     * A band between two boundaries.
     *
     * Throws `PlotException` when the three arrays differ in length.
     */
    public static func between(
        xs: Array<Float64>,
        lower: Array<Float64>,
        upper: Array<Float64>,
        label!: String = ""
    ): AreaSeries {
        AreaSeries(xs, lower, upper, label)
    }

    private init(xs: Array<Float64>, lower: Array<Float64>, upper: Array<Float64>, label: String) {
        super()
        requireSameLength(xs, lower, "AreaSeries.between")
        requireSameLength(xs, upper, "AreaSeries.between")
        this.xs = xs
        this.upper = upper
        this.lower = lower
        this.label = label
        this.showEdge = false
    }

    /** The x coordinates. */
    public func xValues(): Array<Float64> {
        xs
    }

    /** The upper boundary values. */
    public func upperValues(): Array<Float64> {
        upper
    }

    /** The lower boundary values. */
    public func lowerValues(): Array<Float64> {
        lower
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        var lowX = 0.0
        var highX = 0.0
        var lowY = 0.0
        var highY = 0.0
        var seen = false
        for (i in 0..xs.size) {
            if (!isFinite(xs[i]) || !isFinite(upper[i]) || !isFinite(lower[i])) {
                continue
            }
            let top = maxOf(upper[i], lower[i])
            let bottom = minOf(upper[i], lower[i])
            if (!seen) {
                lowX = xs[i]
                highX = xs[i]
                lowY = bottom
                highY = top
                seen = true
            } else {
                lowX = minOf(lowX, xs[i])
                highX = maxOf(highX, xs[i])
                lowY = minOf(lowY, bottom)
                highY = maxOf(highY, top)
            }
        }
        if (seen) {
            Some((Bounds(lowX, highX), Bounds(lowY, highY)))
        } else {
            None
        }
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let fill = resolveColor(theme)
        // Split at any station where either boundary is unusable, so a gap stays a gap.
        var upperRun = ArrayList<Point>()
        var lowerRun = ArrayList<Point>()
        for (i in 0..xs.size) {
            let usable = projection.accepts(xs[i], upper[i]) && projection.accepts(xs[i], lower[i])
            if (usable) {
                upperRun.add(projection.pixel(xs[i], upper[i]))
                lowerRun.add(projection.pixel(xs[i], lower[i]))
            } else if (!upperRun.isEmpty()) {
                flushRun(canvas, upperRun, lowerRun, fill, theme)
                upperRun = ArrayList<Point>()
                lowerRun = ArrayList<Point>()
            }
        }
        flushRun(canvas, upperRun, lowerRun, fill, theme)
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let fill = resolveColor(theme)
        let alpha = fillOpacity
        let edged = showEdge
        let width = edgeWidth ?? theme.lineWidth
        [
            LegendEntry(label, fill) {
                canvas, rect, _ =>
                    canvas.fillRoundedRect(rect, 2.0, Colors.fade(fill, maxOf(alpha, 0.25)))
                    if (edged) {
                        canvas.line(rect.x, rect.y + 1.0, rect.right(), rect.y + 1.0, Pen(width: width, color: fill))
                    }
            }
        ]
    }

    private func flushRun(
        canvas: Canvas,
        upperRun: ArrayList<Point>,
        lowerRun: ArrayList<Point>,
        fill: Color,
        theme: Theme
    ): Unit {
        if (upperRun.size < 2) {
            return
        }
        canvas.fillBand(upperRun, lowerRun, Colors.fade(fill, fillOpacity), upperAlpha: 1.0,
            lowerAlpha: Float32(fadeOpacity / maxOf(fillOpacity, 1.0e-6)))
        if (showEdge) {
            canvas.polyline(upperRun, Pen(width: edgeWidth ?? theme.lineWidth, color: fill))
        }
    }
}

/**
 * Stacks several `AreaSeries` so each sits on the cumulative total of those before it.
 *
 * Like `BarGroup`, this is a relationship between series rather than a property of one, so it is
 * arranged here rather than configured on each area and left to agree by coincidence.
 */
public class AreaStack {
    /**
     * Builds stacked areas from shared `xs` and one value array per layer, in bottom-to-top order.
     *
     * Throws `PlotException` when any layer's length differs from `xs`.
     */
    public static func build(xs: Array<Float64>, layers: Array<Array<Float64>>, labels!: Array<String> = []): Array<AreaSeries> {
        let result = ArrayList<AreaSeries>()
        let totals = Array<Float64>(xs.size, repeat: 0.0)
        for (index in 0..layers.size) {
            let layer = layers[index]
            requireSameLength(xs, layer, "AreaStack.build")
            let base = Array<Float64>(xs.size, repeat: 0.0)
            let top = Array<Float64>(xs.size, repeat: 0.0)
            for (i in 0..xs.size) {
                base[i] = totals[i]
                // A non-finite sample contributes nothing rather than poisoning every layer above it.
                let value = if (isFinite(layer[i])) {
                    layer[i]
                } else {
                    0.0
                }
                totals[i] += value
                top[i] = totals[i]
            }
            let label = if (index < labels.size) {
                labels[index]
            } else {
                ""
            }
            let area = AreaSeries.between(xs, base, top, label: label)
            area.fillOpacity = 0.85
            area.fadeOpacity = 0.85
            area.showEdge = false
            result.add(area)
        }
        result.toArray()
    }
}
