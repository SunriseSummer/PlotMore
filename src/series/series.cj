package plot.series

import std.collection.ArrayList
import sdl.{Color, Point, Rect}
import plot.canvas.Canvas
import plot.core.{Bounds, Colors, PlotException, Projection, Theme, isFinite}

/**
 * One entry in a figure's legend: a swatch drawn by the series that produced it, and its label.
 *
 * The `draw` callback lets each series render its own swatch — a line series draws a line segment
 * with its dash pattern and marker, a bar series draws a filled chip — so the legend always matches
 * what is actually on the panel instead of approximating it.
 */
public struct LegendEntry {
    public let label: String
    public let color: Color
    public let draw: (Canvas, Rect, Theme) -> Unit

    public init(label: String, color: Color, draw: (Canvas, Rect, Theme) -> Unit) {
        this.label = label
        this.color = color
        this.draw = draw
    }
}

/** A data point identified under the cursor, used to build tooltips and readouts. */
public struct HitResult {
    /** The series that owns the point. */
    public let label: String

    /** The point in data space. */
    public let dataX: Float64
    public let dataY: Float64

    /** Where the point landed on screen. */
    public let pixelX: Float32
    public let pixelY: Float32

    /** Pixel distance from the cursor — the caller keeps the nearest across series. */
    public let distance: Float32

    /** The series colour, so the tooltip can key itself to the data. */
    public let color: Color

    /** A ready-made description, e.g. `sin(x): (1.20, 0.93)`. */
    public let text: String

    public init(
        label: String,
        dataX: Float64,
        dataY: Float64,
        pixelX: Float32,
        pixelY: Float32,
        distance: Float32,
        color: Color,
        text: String
    ) {
        this.label = label
        this.dataX = dataX
        this.dataY = dataY
        this.pixelX = pixelX
        this.pixelY = pixelY
        this.distance = distance
        this.color = color
        this.text = text
    }
}

/**
 * A drawable data layer inside an `Axes`.
 *
 * A series reports the data range it needs (`dataBounds`, driving autoscale), draws itself through
 * a `Projection` (which owns the data-to-pixel transform, so no series does its own arithmetic on
 * the panel rectangle), contributes legend entries, and optionally answers hit tests.
 *
 * Colour resolution is deferred: a series without an explicit colour takes `theme.palette` at the
 * index its `Axes` assigned when it was added. That is what makes the palette a theme decision
 * rather than something every caller restates.
 */
public abstract class Series {
    /** The legend label. An empty label keeps the series out of the legend. */
    public var label: String = ""

    /** When false the series is skipped entirely — drawing, autoscale, legend, and hit tests. */
    public var visible: Bool = true

    /** Opacity multiplier applied on top of the resolved colour, `0..1`. */
    public var opacity: Float64 = 1.0

    // An explicit colour overrides the palette; None defers to `paletteIndex`.
    protected var explicitColor: ?Color = None
    protected var paletteIndex: Int64 = 0

    /** Pins this series to a colour, overriding the theme palette. */
    public func setColor(color: Color): Unit {
        explicitColor = Some(color)
    }

    /** The explicit colour, if one was pinned. */
    public func color(): ?Color {
        explicitColor
    }

    /** Called by `Axes` when the series is added; selects the palette slot for an unpinned series. */
    public func setPaletteIndex(index: Int64): Unit {
        paletteIndex = index
    }

    /** The palette slot assigned to this series. */
    public func indexInPalette(): Int64 {
        paletteIndex
    }

    /**
     * The x and y data ranges this series occupies, or `None` when it holds no finite data — an
     * empty series, or one whose every point was filtered out. `Axes` unions these across visible
     * series to autoscale.
     */
    public func dataBounds(): ?(Bounds, Bounds)

    /** Renders the series. The panel clip is already active. */
    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit

    /**
     * True when `dataBounds` is an exact extent that should fill the panel rather than a cloud of
     * points needing breathing room.
     *
     * A heatmap or a contour tiles a rectangle: padding it by 5% leaves a band of empty background
     * between the field and the panel edge, which reads as missing data rather than as margin. A
     * scatter, by contrast, wants the margin so its outermost markers are not bisected by the
     * frame. `Axes` skips its headroom when any visible series says true.
     */
    public open func fillsExtent(): Bool {
        false
    }

    /** The legend entries this series contributes; empty when it has no label. */
    public open func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let swatchColor = resolveColor(theme)
        [LegendEntry(label, swatchColor, {canvas, rect, _ => canvas.fillRoundedRect(rect, 2.0, swatchColor)})]
    }

    /**
     * The nearest data point to a pixel, or `None` when this series has nothing near it. The
     * default finds nothing; series with discrete points override it.
     */
    public open func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult {
        let _ = px
        let _ = py
        let _ = projection
        let _ = theme
        None
    }

    /** The colour this series draws with: the pinned colour, else its palette slot. */
    protected func resolveColor(theme: Theme): Color {
        let base = match (explicitColor) {
            case Some(value) => value
            case None => theme.palette.at(paletteIndex)
        }
        if (opacity >= 1.0) {
            base
        } else {
            Colors.fade(base, opacity * Float64(base.a) / 255.0)
        }
    }
}

/**
 * Validates that paired coordinate arrays line up.
 *
 * Throws `PlotException` naming both lengths when they differ — a mismatch is always a caller bug,
 * and silently truncating to the shorter array would hide it while drawing a subtly wrong chart.
 */
public func requireSameLength(xs: Array<Float64>, ys: Array<Float64>, context: String): Unit {
    if (xs.size != ys.size) {
        throw PlotException("${context} needs matching x and y lengths; got ${xs.size} and ${ys.size}.")
    }
}

/**
 * The x/y bounds of the finite points in a coordinate pair, or `None` when none are finite.
 *
 * Points where either coordinate is non-finite are skipped as a unit: a NaN y at a valid x must not
 * stretch the x range to a gap the data never occupies.
 */
public func pairedBounds(xs: Array<Float64>, ys: Array<Float64>): ?(Bounds, Bounds) {
    var lowX = 0.0
    var highX = 0.0
    var lowY = 0.0
    var highY = 0.0
    var seen = false
    for (i in 0..xs.size) {
        let x = xs[i]
        let y = ys[i]
        if (!isFinite(x) || !isFinite(y)) {
            continue
        }
        if (!seen) {
            lowX = x
            highX = x
            lowY = y
            highY = y
            seen = true
        } else {
            if (x < lowX) {
                lowX = x
            }
            if (x > highX) {
                highX = x
            }
            if (y < lowY) {
                lowY = y
            }
            if (y > highY) {
                highY = y
            }
        }
    }
    if (seen) {
        Some((Bounds(lowX, highX), Bounds(lowY, highY)))
    } else {
        None
    }
}

/**
 * Splits a coordinate pair into runs of consecutive plottable points.
 *
 * Non-finite coordinates, and values the projection's scales cannot express (a zero on a log axis),
 * end the current run. Drawing each run as its own polyline is what makes a gap in the data read as
 * a gap rather than as a straight line bridging it.
 */
public func plottableRuns(
    xs: Array<Float64>,
    ys: Array<Float64>,
    projection: Projection
): ArrayList<ArrayList<Point>> {
    let runs = ArrayList<ArrayList<Point>>()
    var current = ArrayList<Point>()
    for (i in 0..xs.size) {
        if (projection.accepts(xs[i], ys[i])) {
            current.add(projection.pixel(xs[i], ys[i]))
        } else if (!current.isEmpty()) {
            runs.add(current)
            current = ArrayList<Point>()
        }
    }
    if (!current.isEmpty()) {
        runs.add(current)
    }
    runs
}
