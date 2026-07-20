package plot.series

import std.collection.ArrayList
import sdl.{Color, Pen, Point}
import plot.canvas.{Canvas, MarkerStyle}
import plot.core.{Bounds, Colors, PlotException, Projection, Theme}

/**
 * Violin plots: a kernel density estimate mirrored about each category position.
 *
 * A violin shows the *shape* of a distribution where a box plot shows only its quartiles — which is
 * the difference between seeing a bimodal sample and seeing a wide box. The cost is that the
 * density is an estimate: its smoothness is a choice of bandwidth, not a property of the data. Set
 * `bandwidth` explicitly when the shape carries the argument.
 *
 * ```
 * let violins = ViolinSeries([groupA, groupB, groupC])
 * violins.showBox = true
 * ```
 */
public class ViolinSeries <: Series {
    private let groups: Array<Array<Float64>>
    private let summaries = ArrayList<BoxStats>()
    private let ranges = ArrayList<Bounds>()

    /** Fraction of the category band a full-width violin occupies, `0..1`. */
    public var bandFraction: Float64 = 0.8

    /** How many points sample each density curve. Higher is smoother and slower. */
    public var resolution: Int64 = 96

    /** Kernel bandwidth; `None` uses Silverman's rule of thumb. */
    public var bandwidth: ?Float64 = None

    /** Overlays a miniature box plot showing the quartiles inside each violin. */
    public var showBox: Bool = true

    /** Marks each median with a dot. */
    public var showMedian: Bool = true

    /** Fill opacity, `0..1`. */
    public var fillOpacity: Float64 = 0.4

    /** Outlines each violin. */
    public var showEdge: Bool = true

    /** Colours each violin from the palette by its index. */
    public var colorByGroup: Bool = true

    /**
     * Throws `PlotException` when `groups` is empty or any group has fewer than two finite samples,
     * which is too few to estimate a density from.
     */
    public init(groups: Array<Array<Float64>>, label!: String = "") {
        super()
        if (groups.size == 0) {
            throw PlotException("A violin plot needs at least one group.")
        }
        this.groups = groups
        this.label = label
        for (i in 0..groups.size) {
            let sorted = Stats.sortedFinite(groups[i])
            if (sorted.size < 2) {
                throw PlotException("Violin group ${i} needs at least two finite samples; got ${sorted.size}.")
            }
            summaries.add(Stats.box(groups[i]))
            // Extend the sampling range past the data so the density tails close instead of being
            // cut off flat at the extreme samples.
            let span = Bounds(sorted[0], sorted[sorted.size - 1]).nonDegenerate()
            ranges.add(span.expanded(0.12))
        }
    }

    /** The per-group summaries used for the inner box overlay. */
    public func stats(): ArrayList<BoxStats> {
        summaries
    }

    /** How many groups the series holds. */
    public func count(): Int64 {
        groups.size
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        var bounds = ranges[0]
        for (range in ranges) {
            bounds = bounds.union(range)
        }
        Some((Bounds(-0.5, Float64(groups.size) - 0.5), bounds))
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let halfBand = clampUnitF(bandFraction) / 2.0
        for (i in 0..groups.size) {
            let color = groupColor(i, theme)
            let range = ranges[i]
            let densities = Stats.kernelDensity(groups[i], range, resolution, bandwidth: bandwidth)
            let peak = peakOf(densities)
            if (peak <= 0.0) {
                continue
            }
            let left = ArrayList<Point>()
            let right = ArrayList<Point>()
            for (s in 0..resolution) {
                // `sampleAt`, not the division spelled out: at a resolution of 1 that divides by
                // zero and puts the whole violin at a NaN pixel. It is also exactly how
                // `kernelDensity` places its own stations, so the two stay aligned by construction.
                let value = sampleAt(range, s, resolution)
                let py = projection.pixelY(value)
                // Normalise each violin to its own peak so groups are comparable in shape; the
                // widths then say nothing about relative sample size, which `showBox` compensates.
                let halfWidth = densities[s] / peak * halfBand
                left.add(Point(projection.pixelX(Float64(i) - halfWidth), py))
                right.add(Point(projection.pixelX(Float64(i) + halfWidth), py))
            }
            canvas.fillBand(left, right, Colors.fade(color, fillOpacity))
            if (showEdge) {
                let pen = Pen(width: 1.3, color: color)
                canvas.polyline(left, pen)
                canvas.polyline(right, pen)
                canvas.line(left[0].x, left[0].y, right[0].x, right[0].y, pen)
                let last = resolution - 1
                canvas.line(left[last].x, left[last].y, right[last].x, right[last].y, pen)
            }
            drawInnerBox(canvas, projection, i, color, theme)
        }
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let color = resolveColor(theme)
        [LegendEntry(label, color) {canvas, rect, _ => canvas.fillRoundedRect(rect, 4.0, Colors.fade(color, 0.4))}]
    }

    private func drawInnerBox(canvas: Canvas, projection: Projection, index: Int64, color: Color, theme: Theme): Unit {
        let summary = summaries[index]
        let centerX = projection.pixelX(Float64(index))
        if (showBox) {
            let pen = Pen(width: 5.0, color: Colors.darken(color, 0.35))
            canvas.line(centerX, projection.pixelY(summary.q1), centerX, projection.pixelY(summary.q3), pen)
            let thin = Pen(width: 1.2, color: Colors.darken(color, 0.35))
            canvas.line(centerX, projection.pixelY(summary.lowerWhisker), centerX,
                projection.pixelY(summary.upperWhisker), thin)
        }
        if (showMedian) {
            canvas.marker(MarkerStyle.Circle, centerX, projection.pixelY(summary.median), 2.8, theme.panel)
        }
    }

    private func groupColor(index: Int64, theme: Theme): Color {
        match (color()) {
            case Some(fixed) => fixed
            case None =>
                if (colorByGroup) {
                    theme.palette.at(index)
                } else {
                    theme.palette.at(indexInPalette())
                }
        }
    }
}

func peakOf(values: Array<Float64>): Float64 {
    var peak = 0.0
    for (value in values) {
        if (value > peak) {
            peak = value
        }
    }
    peak
}
