package plot.series

import std.collection.ArrayList
import sdl.{Pen, Point}
import plot.canvas.{Canvas, LineStyle, MarkerStyle}
import plot.core.{Bounds, Colors, Projection, Theme}

/** Where a step series changes level between two samples. */
public enum StepWhere {
    /** The level changes at the left sample: the value holds until the next x. */
    | Post

    /** The level changes at the right sample: the value is reached at its own x. */
    | Pre

    /** The level changes midway between samples. */
    | Mid
}

/**
 * A piecewise-constant line — the honest rendering for quantities that hold a value between
 * samples rather than sliding between them: a counter, a discrete state, a rate held over an
 * interval.
 *
 * ```
 * let series = StepSeries(times, states, label: "mode")
 * series.changeAt = StepWhere.Post
 * ```
 */
public class StepSeries <: Series {
    private let xs: Array<Float64>
    private let ys: Array<Float64>

    /** Where the level changes between samples. */
    public var changeAt: StepWhere = StepWhere.Post

    /** How the line is stroked. */
    public var style: LineStyle = LineStyle.Solid

    /** The glyph at each sample. */
    public var marker: MarkerStyle = MarkerStyle.NoMarker

    /** Line width; `None` follows `theme.lineWidth`. */
    public var width: ?Float32 = None

    /** Fills between the steps and this baseline when set. */
    public var fillTo: ?Float64 = None

    /** Fill opacity at the step edge. */
    public var fillOpacity: Float64 = 0.18

    /**
     * Throws `PlotException` when `xs` and `ys` differ in length.
     */
    public init(xs: Array<Float64>, ys: Array<Float64>, label!: String = "") {
        super()
        requireSameLength(xs, ys, "StepSeries")
        this.xs = xs
        this.ys = ys
        this.label = label
    }

    /** The x coordinates. */
    public func xValues(): Array<Float64> {
        xs
    }

    /** The y coordinates. */
    public func yValues(): Array<Float64> {
        ys
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        match (pairedBounds(xs, ys)) {
            case Some((bx, by)) => match (fillTo) {
                case Some(baseline) => Some((bx, by.union(Bounds.of(baseline, baseline))))
                case None => Some((bx, by))
            }
            case None => None
        }
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let color = resolveColor(theme)
        let runs = plottableRuns(xs, ys, projection)
        for (run in runs) {
            let path = stepPath(run)
            match (fillTo) {
                case Some(baseline) =>
                    let baseY = projection.pixelY(baseline)
                    let lower = ArrayList<Point>()
                    for (point in path) {
                        lower.add(Point(point.x, baseY))
                    }
                    canvas.fillBand(path, lower, Colors.fade(color, fillOpacity))
                case None => ()
            }
            canvas.styledPolyline(path, Pen(width: width ?? theme.lineWidth, color: color), style)
            if (!marker.isHidden()) {
                for (point in run) {
                    canvas.marker(marker, point.x, point.y, theme.markerSize, color)
                }
            }
        }
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let color = resolveColor(theme)
        let lineWidth = width ?? theme.lineWidth
        [
            LegendEntry(label, color) {
                canvas, rect, _ =>
                    // A miniature step, so the legend says "piecewise constant" rather than "line".
                    let path = ArrayList<Point>(
                        [
                            Point(rect.x, rect.bottom() - 1.0),
                            Point(rect.centerX(), rect.bottom() - 1.0),
                            Point(rect.centerX(), rect.y + 1.0),
                            Point(rect.right(), rect.y + 1.0)
                        ]
                    )
                    canvas.polyline(path, Pen(width: lineWidth, color: color))
            }
        ]
    }

    public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult {
        nearestPoint(xs, ys, px, py, projection, label, resolveColor(theme))
    }

    // Expands samples into the corner points the chosen step convention implies.
    private func stepPath(run: ArrayList<Point>): ArrayList<Point> {
        if (run.size < 2) {
            return run
        }
        let path = ArrayList<Point>()
        path.add(run[0])
        for (i in 0..run.size - 1) {
            let from = run[i]
            let to = run[i + 1]
            match (changeAt) {
                case Post => path.add(Point(to.x, from.y))
                case Pre => path.add(Point(from.x, to.y))
                case Mid =>
                    let midX = (from.x + to.x) / 2.0
                    path.add(Point(midX, from.y))
                    path.add(Point(midX, to.y))
            }
            path.add(to)
        }
        path
    }
}

/**
 * Vertical stems from a baseline to each point, capped with a marker — the discrete-signal
 * counterpart to a line, where the samples are the data and the space between them is not.
 */
public class StemSeries <: Series {
    private let xs: Array<Float64>
    private let ys: Array<Float64>

    /** The value stems rise from. */
    public var baseline: Float64 = 0.0

    /** The glyph capping each stem. */
    public var marker: MarkerStyle = MarkerStyle.Circle

    /** Stem width in logical pixels. */
    public var stemWidth: Float32 = 1.4

    /** Marker radius; `None` follows `theme.markerSize`. */
    public var markerSize: ?Float32 = None

    /** Draws the baseline itself. */
    public var showBaseline: Bool = true

    /**
     * Throws `PlotException` when `xs` and `ys` differ in length.
     */
    public init(xs: Array<Float64>, ys: Array<Float64>, label!: String = "") {
        super()
        requireSameLength(xs, ys, "StemSeries")
        this.xs = xs
        this.ys = ys
        this.label = label
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        match (pairedBounds(xs, ys)) {
            case Some((bx, by)) => Some((bx, by.union(Bounds.of(baseline, baseline))))
            case None => None
        }
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let color = resolveColor(theme)
        let baseY = projection.pixelY(baseline)
        if (showBaseline) {
            canvas.line(projection.area.x, baseY, projection.area.right(), baseY, Pen(width: 1.0, color: theme.axis))
        }
        let pen = Pen(width: stemWidth, color: color)
        let size = markerSize ?? theme.markerSize
        for (i in 0..xs.size) {
            if (!projection.accepts(xs[i], ys[i])) {
                continue
            }
            let pixel = projection.pixel(xs[i], ys[i])
            canvas.line(pixel.x, baseY, pixel.x, pixel.y, pen)
            canvas.marker(marker, pixel.x, pixel.y, size, color)
        }
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let color = resolveColor(theme)
        let glyph = marker
        let size = markerSize ?? theme.markerSize
        let pen = Pen(width: stemWidth, color: color)
        [
            LegendEntry(label, color) {
                canvas, rect, _ =>
                    canvas.line(rect.centerX(), rect.bottom(), rect.centerX(), rect.y + 2.0, pen)
                    canvas.marker(glyph, rect.centerX(), rect.y + 2.0, size, color)
            }
        ]
    }

    public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult {
        nearestPoint(xs, ys, px, py, projection, label, resolveColor(theme))
    }
}
