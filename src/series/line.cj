package plot.series

import std.collection.ArrayList
import std.math.sqrt
import sdl.{Color, Pen, Point, Rect}
import plot.canvas.{Canvas, LineStyle, MarkerStyle}
import plot.core.{Bounds, Colors, NumberFormat, Projection, Theme}

/**
 * A line through `(x, y)` points, optionally marked and optionally filled to a baseline.
 *
 * Non-finite points break the line into separate runs rather than being bridged, so gaps in a
 * dataset stay visible as gaps. Points the axis cannot express — a zero or negative on a log axis —
 * break it the same way.
 *
 * ```
 * let series = LineSeries(xs, ys, label: "sin(x)")
 * series.style = LineStyle.Dashed
 * series.marker = MarkerStyle.Circle
 * axes.add(series)
 * ```
 */
public class LineSeries <: Series {
    private let xs: Array<Float64>
    private let ys: Array<Float64>

    /** How the connecting line is stroked; `NoLine` leaves only the markers. */
    public var style: LineStyle = LineStyle.Solid

    /** The glyph at each point; `NoMarker` by default, since dense lines read better bare. */
    public var marker: MarkerStyle = MarkerStyle.NoMarker

    /** Line width in logical pixels; `None` follows `theme.lineWidth`. */
    public var width: ?Float32 = None

    /** Marker radius in logical pixels; `None` follows `theme.markerSize`. */
    public var markerSize: ?Float32 = None

    /** Fills between the line and `baseline` when set — the area-chart form of a line. */
    public var fillTo: ?Float64 = None

    /** Opacity of the area fill at the line edge, fading to `fillFadeOpacity` at the baseline. */
    public var fillOpacity: Float64 = 0.22

    /** Opacity of the area fill at the baseline; below `fillOpacity` gives the modern fade. */
    public var fillFadeOpacity: Float64 = 0.02

    /** Draws every `markerEvery`-th marker; keeps dense series legible. 1 marks every point. */
    public var markerEvery: Int64 = 1

    /**
     * Rounds the line through a centripetal Catmull-Rom spline instead of straight segments.
     *
     * Off by default and deliberately so: smoothing invents data between the samples. Turn it on
     * for presentation of a genuinely continuous signal, not for sparse measurements.
     */
    public var smooth: Bool = false

    /**
     * Throws `PlotException` when `xs` and `ys` differ in length.
     */
    public init(xs: Array<Float64>, ys: Array<Float64>, label!: String = "") {
        super()
        requireSameLength(xs, ys, "LineSeries")
        this.xs = xs
        this.ys = ys
        this.label = label
    }

    /** The x coordinates, as supplied. */
    public func xValues(): Array<Float64> {
        xs
    }

    /** The y coordinates, as supplied. */
    public func yValues(): Array<Float64> {
        ys
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        match (pairedBounds(xs, ys)) {
            case Some((bx, by)) => match (fillTo) {
                // A fill baseline is part of the drawn extent, so it has to be in the autoscale.
                case Some(baseline) => Some((bx, by.union(Bounds.of(baseline, baseline))))
                case None => Some((bx, by))
            }
            case None => None
        }
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let lineColor = resolveColor(theme)
        let lineWidth = width ?? theme.lineWidth
        let runs = plottableRuns(xs, ys, projection)
        for (run in runs) {
            let path = if (smooth) {
                smoothPath(run)
            } else {
                run
            }
            drawFill(canvas, projection, path, lineColor)
            canvas.styledPolyline(path, Pen(width: lineWidth, color: lineColor), style)
        }
        drawMarkers(canvas, runs, lineColor, theme)
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let lineColor = resolveColor(theme)
        let lineWidth = width ?? theme.lineWidth
        let glyph = marker
        let glyphSize = markerSize ?? theme.markerSize
        let lineStyle = style
        let filled = fillTo.isSome()
        let fillAlpha = fillOpacity
        [
            LegendEntry(label, lineColor) {
                canvas, rect, _ =>
                    let midY = rect.centerY()
                    if (filled) {
                        canvas.fillRect(Rect(rect.x, midY, rect.w, rect.bottom() - midY),
                            Colors.fade(lineColor, fillAlpha * 3.0))
                    }
                    let path = ArrayList<Point>([Point(rect.x, midY), Point(rect.right(), midY)])
                    canvas.styledPolyline(path, Pen(width: lineWidth, color: lineColor), lineStyle)
                    if (!glyph.isHidden()) {
                        canvas.marker(glyph, rect.centerX(), midY, glyphSize, lineColor)
                    }
            }
        ]
    }

    public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult {
        nearestPoint(xs, ys, px, py, projection, label, resolveColor(theme))
    }

    private func drawFill(canvas: Canvas, projection: Projection, path: ArrayList<Point>, lineColor: Color): Unit {
        let baseline = match (fillTo) {
            case Some(value) => value
            case None => return
        }
        if (path.size < 2) {
            return
        }
        let baseY = projection.pixelY(baseline)
        let lower = ArrayList<Point>()
        for (point in path) {
            lower.add(Point(point.x, baseY))
        }
        canvas.fillBand(path, lower, Colors.fade(lineColor, fillOpacity), upperAlpha: 1.0,
            lowerAlpha: Float32(fillFadeOpacity / maxNonZero(fillOpacity)))
    }

    private func drawMarkers(canvas: Canvas, runs: ArrayList<ArrayList<Point>>, lineColor: Color, theme: Theme): Unit {
        if (marker.isHidden()) {
            return
        }
        let size = markerSize ?? theme.markerSize
        let stride = if (markerEvery < 1) {
            1
        } else {
            markerEvery
        }
        // A thin ring in the panel colour separates overlapping markers without a second palette
        // colour; on filled shapes only, since stroked glyphs have no interior to ring.
        let edge: ?Pen = if (marker.isStroked()) {
            None
        } else {
            Some(Pen(width: 1.2, color: theme.panel))
        }
        for (run in runs) {
            var index = 0
            for (point in run) {
                if (index % stride == 0) {
                    canvas.marker(marker, point.x, point.y, size, lineColor, edge: edge)
                }
                index += 1
            }
        }
    }
}

/** Guards the fill-fade ratio against a zero denominator when `fillOpacity` is set to zero. */
func maxNonZero(value: Float64): Float64 {
    if (value <= 1.0e-6) {
        1.0e-6
    } else {
        value
    }
}

/**
 * Resamples a polyline through a centripetal Catmull-Rom spline.
 *
 * Centripetal parameterisation (exponent 0.5) is the variant that cannot form cusps or
 * self-intersections between control points, which the uniform variant does on unevenly spaced
 * data — exactly the case a chart hits.
 */
func smoothPath(points: ArrayList<Point>): ArrayList<Point> {
    let count = points.size
    if (count < 3) {
        return points
    }
    let result = ArrayList<Point>()
    result.add(points[0])
    for (i in 0..count - 1) {
        // Duplicate the endpoints so the first and last spans have control points on both sides.
        let p0 = points[maxIndex(i - 1)]
        let p1 = points[i]
        let p2 = points[i + 1]
        let p3 = points[minIndex(i + 2, count - 1)]
        let segments = splineSegments(p1, p2)
        for (step in 1..=segments) {
            result.add(catmullRom(p0, p1, p2, p3, Float32(step) / Float32(segments)))
        }
    }
    result
}

// One sample per ~6 px of chord keeps a smoothed curve visually continuous without flooding the
// batch on a long series.
func splineSegments(a: Point, b: Point): Int64 {
    let dx = Float64(b.x - a.x)
    let dy = Float64(b.y - a.y)
    let chord = sqrt(dx * dx + dy * dy)
    var segments = Int64(chord / 6.0) + 1
    if (segments < 2) {
        segments = 2
    }
    if (segments > 24) {
        segments = 24
    }
    segments
}

func catmullRom(p0: Point, p1: Point, p2: Point, p3: Point, t: Float32): Point {
    let t0 = 0.0f32
    let t1 = t0 + knotSpan(p0, p1)
    let t2 = t1 + knotSpan(p1, p2)
    let t3 = t2 + knotSpan(p2, p3)
    let ti = t1 + (t2 - t1) * t
    let a1 = interpolate(p0, p1, t0, t1, ti)
    let a2 = interpolate(p1, p2, t1, t2, ti)
    let a3 = interpolate(p2, p3, t2, t3, ti)
    let b1 = interpolate(a1, a2, t0, t2, ti)
    let b2 = interpolate(a2, a3, t1, t3, ti)
    interpolate(b1, b2, t1, t2, ti)
}

// The centripetal knot spacing: |P_{i+1} - P_i|^0.5.
func knotSpan(a: Point, b: Point): Float32 {
    let dx = Float64(b.x - a.x)
    let dy = Float64(b.y - a.y)
    let distance = sqrt(sqrt(dx * dx + dy * dy))
    if (distance < 1.0e-4) {
        1.0e-4f32
    } else {
        Float32(distance)
    }
}

func interpolate(a: Point, b: Point, ta: Float32, tb: Float32, t: Float32): Point {
    let span = tb - ta
    if (span == 0.0) {
        return a
    }
    let k = (t - ta) / span
    Point(a.x + (b.x - a.x) * k, a.y + (b.y - a.y) * k)
}

func maxIndex(value: Int64): Int64 {
    if (value < 0) {
        0
    } else {
        value
    }
}

func minIndex(value: Int64, limit: Int64): Int64 {
    if (value > limit) {
        limit
    } else {
        value
    }
}

/**
 * The point of `(xs, ys)` closest to a pixel, measured in pixel space.
 *
 * Pixel space, not data space: the axes have unrelated units and often wildly different scales, so
 * data-space distance would make the tooltip snap to whichever axis happens to have small numbers.
 */
func nearestPoint(
    xs: Array<Float64>,
    ys: Array<Float64>,
    px: Float32,
    py: Float32,
    projection: Projection,
    label: String,
    color: Color
): ?HitResult {
    var best: ?HitResult = None
    var bestDistance = Float32.Max
    for (i in 0..xs.size) {
        if (!projection.accepts(xs[i], ys[i])) {
            continue
        }
        let pixel = projection.pixel(xs[i], ys[i])
        let dx = pixel.x - px
        let dy = pixel.y - py
        let distance = Float32(sqrt(Float64(dx * dx + dy * dy)))
        if (distance < bestDistance) {
            bestDistance = distance
            let text = "${NumberFormat.compact(xs[i])}, ${NumberFormat.compact(ys[i])}"
            best = Some(HitResult(label, xs[i], ys[i], pixel.x, pixel.y, distance, color, text))
        }
    }
    best
}
