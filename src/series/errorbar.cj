package plot.series

import std.collection.ArrayList
import sdl.{Pen, Point}
import plot.canvas.{Canvas, LineStyle, MarkerStyle}
import plot.core.{Bounds, PlotException, Projection, Theme, isFinite}

/**
 * Points with uncertainty bars in y, x, or both.
 *
 * Errors are given as half-widths — the distance from the point to one end of the bar — which is
 * the form a standard deviation or standard error already takes. Asymmetric intervals use
 * `setYErrorRange`, whose two arrays are the distances below and above.
 *
 * ```
 * let series = ErrorBarSeries(xs, ys, label: "trial A")
 * series.setYError(standardErrors)
 * series.marker = MarkerStyle.Circle
 * ```
 */
public class ErrorBarSeries <: Series {
    private let xs: Array<Float64>
    private let ys: Array<Float64>
    private var yLow: ?Array<Float64> = None
    private var yHigh: ?Array<Float64> = None
    private var xLow: ?Array<Float64> = None
    private var xHigh: ?Array<Float64> = None

    /** The glyph at each point. */
    public var marker: MarkerStyle = MarkerStyle.Circle

    /** Marker radius; `None` follows `theme.markerSize`. */
    public var markerSize: ?Float32 = None

    /** Bar line width in logical pixels. */
    public var barWidth: Float32 = 1.3

    /** Half-length of the perpendicular cap at each bar end, in pixels. Zero draws no cap. */
    public var capSize: Float32 = 4.0

    /** Connects the points with a line as well as marking them. */
    public var connect: Bool = false

    /** Style of the connecting line, when `connect` is on. */
    public var lineStyle: LineStyle = LineStyle.Solid

    /**
     * Throws `PlotException` when `xs` and `ys` differ in length.
     */
    public init(xs: Array<Float64>, ys: Array<Float64>, label!: String = "") {
        super()
        requireSameLength(xs, ys, "ErrorBarSeries")
        this.xs = xs
        this.ys = ys
        this.label = label
    }

    /**
     * Symmetric y uncertainty: each bar spans `y - e` to `y + e`.
     *
     * Throws `PlotException` when `errors` does not match the point count.
     */
    public func setYError(errors: Array<Float64>): Unit {
        requireMatching(errors, "setYError")
        yLow = Some(errors)
        yHigh = Some(errors)
    }

    /**
     * Asymmetric y uncertainty: each bar spans `y - below` to `y + above`.
     *
     * Throws `PlotException` when either array does not match the point count.
     */
    public func setYErrorRange(below: Array<Float64>, above: Array<Float64>): Unit {
        requireMatching(below, "setYErrorRange")
        requireMatching(above, "setYErrorRange")
        yLow = Some(below)
        yHigh = Some(above)
    }

    /**
     * Symmetric x uncertainty.
     *
     * Throws `PlotException` when `errors` does not match the point count.
     */
    public func setXError(errors: Array<Float64>): Unit {
        requireMatching(errors, "setXError")
        xLow = Some(errors)
        xHigh = Some(errors)
    }

    /**
     * Asymmetric x uncertainty.
     *
     * Throws `PlotException` when either array does not match the point count.
     */
    public func setXErrorRange(below: Array<Float64>, above: Array<Float64>): Unit {
        requireMatching(below, "setXErrorRange")
        requireMatching(above, "setXErrorRange")
        xLow = Some(below)
        xHigh = Some(above)
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        var lowX = 0.0
        var highX = 0.0
        var lowY = 0.0
        var highY = 0.0
        var seen = false
        for (i in 0..xs.size) {
            if (!isFinite(xs[i]) || !isFinite(ys[i])) {
                continue
            }
            // The bars are part of the drawn extent, so autoscale has to include their ends.
            let x0 = xs[i] - errorAt(xLow, i)
            let x1 = xs[i] + errorAt(xHigh, i)
            let y0 = ys[i] - errorAt(yLow, i)
            let y1 = ys[i] + errorAt(yHigh, i)
            if (!seen) {
                lowX = x0
                highX = x1
                lowY = y0
                highY = y1
                seen = true
            } else {
                lowX = minOf(lowX, x0)
                highX = maxOf(highX, x1)
                lowY = minOf(lowY, y0)
                highY = maxOf(highY, y1)
            }
        }
        if (seen) {
            Some((Bounds(lowX, highX), Bounds(lowY, highY)))
        } else {
            None
        }
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let color = resolveColor(theme)
        let pen = Pen(width: barWidth, color: color)
        if (connect) {
            canvas.styledPolyline(plottableRunsFlat(projection), Pen(width: theme.lineWidth, color: color), lineStyle)
        }
        for (i in 0..xs.size) {
            if (!projection.accepts(xs[i], ys[i])) {
                continue
            }
            let center = projection.pixel(xs[i], ys[i])
            drawYBar(canvas, projection, i, center, pen)
            drawXBar(canvas, projection, i, center, pen)
            canvas.marker(marker, center.x, center.y, markerSize ?? theme.markerSize, color,
                edge: Some(Pen(width: 1.0, color: theme.panel)))
        }
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let color = resolveColor(theme)
        let glyph = marker
        let size = markerSize ?? theme.markerSize
        let pen = Pen(width: barWidth, color: color)
        [
            LegendEntry(label, color) {
                canvas, rect, _ =>
                    let cx = rect.centerX()
                    canvas.line(cx, rect.y, cx, rect.bottom(), pen)
                    canvas.line(cx - 3.0, rect.y, cx + 3.0, rect.y, pen)
                    canvas.line(cx - 3.0, rect.bottom(), cx + 3.0, rect.bottom(), pen)
                    canvas.marker(glyph, cx, rect.centerY(), size, color)
            }
        ]
    }

    public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult {
        nearestPoint(xs, ys, px, py, projection, label, resolveColor(theme))
    }

    private func drawYBar(canvas: Canvas, projection: Projection, index: Int64, center: Point, pen: Pen): Unit {
        if (yLow.isNone() && yHigh.isNone()) {
            return
        }
        let top = projection.pixelY(ys[index] + errorAt(yHigh, index))
        let bottom = projection.pixelY(ys[index] - errorAt(yLow, index))
        canvas.line(center.x, top, center.x, bottom, pen)
        if (capSize > 0.0) {
            canvas.line(center.x - capSize, top, center.x + capSize, top, pen)
            canvas.line(center.x - capSize, bottom, center.x + capSize, bottom, pen)
        }
    }

    private func drawXBar(canvas: Canvas, projection: Projection, index: Int64, center: Point, pen: Pen): Unit {
        if (xLow.isNone() && xHigh.isNone()) {
            return
        }
        let left = projection.pixelX(xs[index] - errorAt(xLow, index))
        let right = projection.pixelX(xs[index] + errorAt(xHigh, index))
        canvas.line(left, center.y, right, center.y, pen)
        if (capSize > 0.0) {
            canvas.line(left, center.y - capSize, left, center.y + capSize, pen)
            canvas.line(right, center.y - capSize, right, center.y + capSize, pen)
        }
    }

    private func plottableRunsFlat(projection: Projection): ArrayList<Point> {
        let path = ArrayList<Point>()
        for (i in 0..xs.size) {
            if (projection.accepts(xs[i], ys[i])) {
                path.add(projection.pixel(xs[i], ys[i]))
            }
        }
        path
    }

    // A missing or non-finite error is no error, not a NaN bar.
    private func errorAt(source: ?Array<Float64>, index: Int64): Float64 {
        match (source) {
            case Some(values) where isFinite(values[index]) => absOf(values[index])
            case _ => 0.0
        }
    }

    private func requireMatching(values: Array<Float64>, context: String): Unit {
        if (values.size != xs.size) {
            throw PlotException("${context} needs ${xs.size} values to match the points; got ${values.size}.")
        }
    }
}

func absOf(value: Float64): Float64 {
    if (value < 0.0) {
        -value
    } else {
        value
    }
}
