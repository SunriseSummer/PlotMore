package plot.series

import std.math.sqrt
import sdl.{Color, Pen, Rect}
import plot.canvas.{Canvas, MarkerStyle}
import plot.core.{Bounds, Colormap, Colors, PlotException, Projection, Theme}

/**
 * Points at `(x, y)`, optionally sized and coloured by further dimensions.
 *
 * A plain scatter uses one colour and one size. `sizeBy` maps a third variable onto marker area
 * (making it a bubble chart) and `colorBy` maps a fourth onto a colormap, so a single panel can
 * carry four dimensions.
 *
 * ```
 * let points = ScatterSeries(xs, ys, label: "samples")
 * points.marker = MarkerStyle.Circle
 * points.sizeBy(weights, minSize: 3.0, maxSize: 14.0)
 * points.colorBy(temperatures, Colormap.viridis())
 * ```
 */
public class ScatterSeries <: Series {
    private let xs: Array<Float64>
    private let ys: Array<Float64>

    /** The glyph drawn at each point. */
    public var marker: MarkerStyle = MarkerStyle.Circle

    /** Marker radius; `None` follows `theme.markerSize`. Overridden per point by `sizeBy`. */
    public var size: ?Float32 = None

    /** Draws a hairline outline around each marker so overlapping points stay countable. */
    public var showEdge: Bool = true

    private var sizeValues: ?Array<Float64> = None
    private var sizeRange: (Float32, Float32) = (3.0, 14.0)
    private var colorValues: ?Array<Float64> = None
    private var colorMap: ?Colormap = None
    private var colorDomain: ?Bounds = None

    /**
     * Throws `PlotException` when `xs` and `ys` differ in length.
     */
    public init(xs: Array<Float64>, ys: Array<Float64>, label!: String = "") {
        super()
        requireSameLength(xs, ys, "ScatterSeries")
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

    /**
     * Sizes each marker by `values`, mapping the data range onto `minSize..maxSize`.
     *
     * The mapping is on **area**, not radius: perceived magnitude tracks area, so scaling the
     * radius linearly would overstate large values roughly quadratically.
     *
     * Throws `PlotException` when `values` does not match the point count.
     */
    public func sizeBy(values: Array<Float64>, minSize!: Float32 = 3.0, maxSize!: Float32 = 14.0): Unit {
        if (values.size != xs.size) {
            throw PlotException("sizeBy needs ${xs.size} values to match the points; got ${values.size}.")
        }
        sizeValues = Some(values)
        sizeRange = (minSize, maxSize)
    }

    /**
     * Colours each marker by `values` through `map`. `domain` pins the colour range; `None`
     * autoscales it to the values.
     *
     * Throws `PlotException` when `values` does not match the point count.
     */
    public func colorBy(values: Array<Float64>, map: Colormap, domain!: ?Bounds = None): Unit {
        if (values.size != xs.size) {
            throw PlotException("colorBy needs ${xs.size} values to match the points; got ${values.size}.")
        }
        colorValues = Some(values)
        colorMap = Some(map)
        colorDomain = domain
    }

    /** The colour-mapped value range, for a colour bar. `None` when `colorBy` was not used. */
    public func colorValueBounds(): ?Bounds {
        match (colorValues) {
            case Some(values) => match (colorDomain) {
                case Some(bounds) => Some(bounds)
                case None => Bounds.cover(values)
            }
            case None => None
        }
    }

    /** The colormap in use, if any. */
    public func colormap(): ?Colormap {
        colorMap
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        pairedBounds(xs, ys)
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let baseColor = resolveColor(theme)
        let baseSize = size ?? theme.markerSize
        let edge: ?Pen = if (showEdge && !marker.isStroked()) {
            Some(Pen(width: 1.0, color: Colors.fade(theme.panel, 0.85)))
        } else {
            None
        }
        let sizeBounds = resolvedSizeBounds()
        let colorBounds = colorValueBounds()
        for (i in 0..xs.size) {
            if (!projection.accepts(xs[i], ys[i])) {
                continue
            }
            let pixel = projection.pixel(xs[i], ys[i])
            canvas.marker(marker, pixel.x, pixel.y, markerSizeAt(i, baseSize, sizeBounds),
                markerColorAt(i, baseColor, colorBounds), edge: edge)
        }
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let glyph = marker
        let glyphColor = resolveColor(theme)
        let glyphSize = size ?? theme.markerSize
        [LegendEntry(label, glyphColor) {
            canvas, rect, _ => canvas.marker(glyph, rect.centerX(), rect.centerY(), glyphSize, glyphColor)
        }]
    }

    public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult {
        nearestPoint(xs, ys, px, py, projection, label, resolveColor(theme))
    }

    private func resolvedSizeBounds(): ?Bounds {
        match (sizeValues) {
            case Some(values) => Bounds.cover(values)
            case None => None
        }
    }

    private func markerSizeAt(index: Int64, baseSize: Float32, bounds: ?Bounds): Float32 {
        let values = match (sizeValues) {
            case Some(v) => v
            case None => return baseSize
        }
        let range = match (bounds) {
            case Some(b) where !b.isDegenerate() => b
            case _ => return baseSize
        }
        let (low, high) = sizeRange
        let t = (values[index] - range.low) / range.span()
        // Interpolate area, then take the root back to a radius.
        let lowArea = Float64(low) * Float64(low)
        let highArea = Float64(high) * Float64(high)
        Float32(sqrt(lowArea + (highArea - lowArea) * clampUnitF(t)))
    }

    private func markerColorAt(index: Int64, baseColor: Color, bounds: ?Bounds): Color {
        let values = match (colorValues) {
            case Some(v) => v
            case None => return baseColor
        }
        let map = match (colorMap) {
            case Some(m) => m
            case None => return baseColor
        }
        let range = match (bounds) {
            case Some(b) => b
            case None => return baseColor
        }
        let mapped = map.sampleIn(values[index], range)
        if (opacity >= 1.0) {
            mapped
        } else {
            Colors.fade(mapped, opacity)
        }
    }
}
