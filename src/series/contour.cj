package plot.series

import std.collection.ArrayList
import sdl.{Color, Pen, Point}
import plot.canvas.Canvas
import plot.core.{Bounds, Colormap, Colors, NumberFormat, PlotException, Projection, Theme, Ticks, isFinite}

/**
 * Iso-level contour lines over a 2D scalar field, traced by marching squares.
 *
 * Each cell of the grid is inspected independently and the level crossings on its edges are joined
 * into short segments. That makes the tracing exact per cell and free of any global bookkeeping,
 * at the cost of producing loose segments rather than continuous closed paths — which is invisible
 * for drawing, and the reason no path-stitching pass exists here.
 *
 * The classic ambiguity is the saddle case, where two opposite corners are above the level and two
 * below: the crossings can be joined two ways, and the grid alone cannot say which is right. This
 * resolves it by the centre-average rule (comparing the cell's mean to the level), which is what
 * matplotlib does and is stable across neighbouring cells.
 *
 * ```
 * let contour = ContourSeries(values, rows: 60, columns: 60, xRange: xs, yRange: ys)
 * contour.setLevels([0.2, 0.4, 0.6, 0.8])
 * ```
 */
public class ContourSeries <: Series {
    private let values: Array<Float64>
    private let rowCount: Int64
    private let columnCount: Int64
    private let xRange: Bounds
    private let yRange: Bounds
    private var levelValues: ?Array<Float64> = None

    /** How many levels to place automatically when none are set explicitly. */
    public var levelCount: Int64 = 8

    /** Line width in logical pixels. */
    public var lineWidth: Float32 = 1.4

    /** Colours the lines by level through a ramp; `None` draws every line in the series colour. */
    public var map: ?Colormap = None

    /** Prints each level's value near its line. */
    public var showLabels: Bool = false

    /**
     * Throws `PlotException` when the grid is smaller than 2x2 (marching squares needs a cell) or
     * `values` does not hold exactly `rows * columns` entries.
     */
    public init(
        values: Array<Float64>,
        rows!: Int64,
        columns!: Int64,
        xRange!: Bounds,
        yRange!: Bounds,
        label!: String = ""
    ) {
        super()
        if (rows < 2 || columns < 2) {
            throw PlotException("A contour grid needs at least 2x2 points; got ${rows}x${columns}.")
        }
        if (values.size != rows * columns) {
            throw PlotException("A ${rows}x${columns} contour grid needs ${rows * columns} values; got ${values.size}.")
        }
        this.values = values
        this.rowCount = rows
        this.columnCount = columns
        this.xRange = xRange
        this.yRange = yRange
        this.label = label
    }

    /**
     * Samples `f` over the grid — the usual way to contour an analytic field.
     *
     * `f` is last so the call takes Cangjie's trailing-lambda form:
     * `ContourSeries.fromFunction(60, 60, xr, yr) { x, y => x * y }`. Set `label` on the result.
     */
    public static func fromFunction(
        rows: Int64,
        columns: Int64,
        xRange: Bounds,
        yRange: Bounds,
        f: (Float64, Float64) -> Float64
    ): ContourSeries {
        if (rows < 2 || columns < 2) {
            throw PlotException("A contour grid needs at least 2x2 points; got ${rows}x${columns}.")
        }
        let values = Array<Float64>(rows * columns, repeat: 0.0)
        for (r in 0..rows) {
            let y = sampleAt(yRange, r, rows)
            for (c in 0..columns) {
                values[r * columns + c] = f(sampleAt(xRange, c, columns), y)
            }
        }
        ContourSeries(values, rows: rows, columns: columns, xRange: xRange, yRange: yRange)
    }

    /**
     * Pins the levels to trace.
     *
     * Throws `PlotException` when `levels` is empty.
     */
    public func setLevels(levels: Array<Float64>): Unit {
        if (levels.size == 0) {
            throw PlotException("A contour needs at least one level.")
        }
        levelValues = Some(levels)
    }

    /** The levels in use — pinned, or `levelCount` round values across the field's range. */
    public func levels(): Array<Float64> {
        match (levelValues) {
            case Some(explicit) => return explicit
            case None => ()
        }
        let range = match (Bounds.cover(values)) {
            case Some(bounds) => bounds.nonDegenerate()
            case None => return []
        }
        // Round levels, and drop any that graze the extremes where the contour degenerates to a point.
        let result = ArrayList<Float64>()
        for (tick in Ticks.linear(range, target: levelCount)) {
            if (tick.major && tick.value > range.low && tick.value < range.high) {
                result.add(tick.value)
            }
        }
        if (result.isEmpty()) {
            for (i in 1..levelCount) {
                result.add(range.low + range.span() * Float64(i) / Float64(levelCount))
            }
        }
        result.toArray()
    }

    /** The value at a grid point. */
    public func value(row: Int64, column: Int64): Float64 {
        values[row * columnCount + column]
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        Some((xRange, yRange))
    }

    /** The field covers its rectangle exactly; padding it would band the panel with background. */
    public override func fillsExtent(): Bool {
        true
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let all = levels()
        if (all.size == 0) {
            return
        }
        let range = match (Bounds.cover(all)) {
            case Some(bounds) => bounds.nonDegenerate()
            case None => return
        }
        for (i in 0..all.size) {
            let color = levelColor(i, all.size, all[i], range, theme)
            let pen = Pen(width: lineWidth, color: color)
            let segments = trace(all[i])
            var labelled = !showLabels
            for (segment in segments) {
                let (ax, ay, bx, by) = segment
                let p1 = projection.pixel(ax, ay)
                let p2 = projection.pixel(bx, by)
                canvas.line(p1.x, p1.y, p2.x, p2.y, pen)
                if (!labelled) {
                    // One label per level, on its first segment: labelling every segment would
                    // bury the field under text.
                    canvas.textAnchored(NumberFormat.compact(all[i], maxDecimals: 2), p1.x, p1.y, color,
                        size: theme.annotationSize)
                    labelled = true
                }
            }
        }
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        // The swatch has to show what is actually drawn. With a ramp set, the lines are coloured by
        // level and the palette slot this series happens to hold is not on the panel at all — so
        // the two rings sample the ramp rather than taking `resolveColor`.
        let (inner, outer) = match (map) {
            case Some(ramp) => (ramp.sample(0.3), ramp.sample(0.75))
            case None =>
                let base = resolveColor(theme)
                (Colors.fade(base, 0.5), base)
        }
        let width = lineWidth
        [
            LegendEntry(label, outer) {
                canvas, rect, _ =>
                    // Two nested arcs read as "contour" more clearly than a straight line.
                    canvas.arc(rect.centerX(), rect.centerY(), rect.h * 0.32, 0.0, 6.28, Pen(width: width, color: inner))
                    canvas.arc(rect.centerX(), rect.centerY(), rect.h * 0.62, 0.0, 6.28, Pen(width: width, color: outer))
            }
        ]
    }

    /**
     * The level's crossings, as `(x1, y1, x2, y2)` segments in data space.
     *
     * Exposed because it is worth testing directly: contour correctness is invisible in a rendered
     * image until it is wrong in a way that looks plausible.
     */
    public func trace(level: Float64): ArrayList<(Float64, Float64, Float64, Float64)> {
        let segments = ArrayList<(Float64, Float64, Float64, Float64)>()
        for (r in 0..rowCount - 1) {
            for (c in 0..columnCount - 1) {
                traceCell(segments, level, r, c)
            }
        }
        segments
    }

    /*
     * One cell. Corners are indexed counter-clockwise from the bottom-left; the four "is this corner
     * above the level" bits form a 16-case table. Cases 0 and 15 are entirely inside or outside and
     * produce nothing; 5 and 10 are the saddles.
     */
    private func traceCell(
        segments: ArrayList<(Float64, Float64, Float64, Float64)>,
        level: Float64,
        row: Int64,
        column: Int64
    ): Unit {
        let bl = value(row, column)
        let br = value(row, column + 1)
        let tr = value(row + 1, column + 1)
        let tl = value(row + 1, column)
        // A cell touching missing data cannot be interpolated; leaving it blank is honest.
        if (!isFinite(bl) || !isFinite(br) || !isFinite(tr) || !isFinite(tl)) {
            return
        }
        var code = 0
        if (bl > level) {
            code |= 1
        }
        if (br > level) {
            code |= 2
        }
        if (tr > level) {
            code |= 4
        }
        if (tl > level) {
            code |= 8
        }
        if (code == 0 || code == 15) {
            return
        }
        let x0 = sampleAt(xRange, column, columnCount)
        let x1 = sampleAt(xRange, column + 1, columnCount)
        let y0 = sampleAt(yRange, row, rowCount)
        let y1 = sampleAt(yRange, row + 1, rowCount)
        // The crossing on each edge, by linear interpolation between its two corners.
        let bottom = (interpolateAt(x0, x1, bl, br, level), y0)
        let right = (x1, interpolateAt(y0, y1, br, tr, level))
        let top = (interpolateAt(x0, x1, tl, tr, level), y1)
        let left = (x0, interpolateAt(y0, y1, bl, tl, level))
        match (code) {
            case 1 => addSegment(segments, left, bottom)
            case 2 => addSegment(segments, bottom, right)
            case 3 => addSegment(segments, left, right)
            case 4 => addSegment(segments, right, top)
            case 5 =>
                // Saddle: the centre average decides which pair of crossings joins.
                if ((bl + br + tr + tl) / 4.0 > level) {
                    addSegment(segments, left, top)
                    addSegment(segments, bottom, right)
                } else {
                    addSegment(segments, left, bottom)
                    addSegment(segments, right, top)
                }
            case 6 => addSegment(segments, bottom, top)
            case 7 => addSegment(segments, left, top)
            case 8 => addSegment(segments, top, left)
            case 9 => addSegment(segments, top, bottom)
            case 10 =>
                if ((bl + br + tr + tl) / 4.0 > level) {
                    addSegment(segments, bottom, left)
                    addSegment(segments, top, right)
                } else {
                    addSegment(segments, bottom, right)
                    addSegment(segments, top, left)
                }
            case 11 => addSegment(segments, top, right)
            case 12 => addSegment(segments, right, left)
            case 13 => addSegment(segments, right, bottom)
            case 14 => addSegment(segments, bottom, left)
            case _ => () // 0 and 15 returned above; the match must still be exhaustive.
        }
    }

    private func addSegment(
        segments: ArrayList<(Float64, Float64, Float64, Float64)>,
        from: (Float64, Float64),
        to: (Float64, Float64)
    ): Unit {
        let (ax, ay) = from
        let (bx, by) = to
        segments.add((ax, ay, bx, by))
    }

    private func levelColor(index: Int64, count: Int64, level: Float64, range: Bounds, theme: Theme): Color {
        match (map) {
            case Some(ramp) => ramp.sampleIn(level, range)
            case None =>
                let base = resolveColor(theme)
                if (count <= 1) {
                    return base
                }
                // Without a ramp, fade the low levels so the nesting order still reads.
                Colors.fade(base, 0.45 + 0.55 * Float64(index) / Float64(count - 1))
        }
    }
}

/** The level crossing on an edge, by linear interpolation between the two corner values. */
func interpolateAt(a: Float64, b: Float64, valueA: Float64, valueB: Float64, level: Float64): Float64 {
    let delta = valueB - valueA
    // Equal corners means the level runs along the edge; the midpoint is the stable choice.
    if (delta == 0.0) {
        return (a + b) / 2.0
    }
    a + (b - a) * (level - valueA) / delta
}
