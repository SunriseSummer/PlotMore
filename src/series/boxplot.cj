package plot.series

import std.collection.ArrayList
import sdl.{Color, Pen, Rect}
import plot.canvas.{Canvas, MarkerStyle}
import plot.core.{Bounds, Colors, NumberFormat, PlotException, Projection, Theme}

/**
 * Tukey box plots, one box per group, at integer category positions.
 *
 * Each box spans the interquartile range with the median marked; whiskers reach the furthest
 * observation within 1.5 IQR of the quartiles, and anything beyond is drawn as an outlier point.
 * The whiskers land on real observations rather than on the fences, so every whisker end is a
 * datum.
 *
 * ```
 * axes.setXScale(CategoryScale(["control", "treated"]))
 * axes.add(BoxPlotSeries([controlSamples, treatedSamples]))
 * ```
 */
public class BoxPlotSeries <: Series {
    private let groups: Array<Array<Float64>>
    private let summaries: ArrayList<BoxStats> = ArrayList<BoxStats>()

    /** Fraction of the category band the box occupies, `0..1`. */
    public var bandFraction: Float64 = 0.5

    private var whiskerRangeValue: Float64 = 1.5

    /**
     * Multiplier on the IQR that sets the whisker fences. Tukey's 1.5 by convention.
     *
     * A property rather than a field because the summaries are computed up front — once per group,
     * not once per frame — so changing the fences has to recompute them. Setting it back to the
     * value it already holds still recomputes; that costs one pass and keeps the setter honest.
     */
    public mut prop whiskerRange: Float64 {
        get() {
            whiskerRangeValue
        }
        set(value) {
            whiskerRangeValue = value
            summarise()
        }
    }

    /** Draws samples beyond the fences as individual points. */
    public var showOutliers: Bool = true

    /** The glyph for outliers. */
    public var outlierMarker: MarkerStyle = MarkerStyle.Circle

    /** Marks each group's mean with a diamond, alongside the median line. */
    public var showMean: Bool = false

    /** Box fill opacity, `0..1`. */
    public var fillOpacity: Float64 = 0.45

    /** Colours each box from the palette by its index, rather than all from one colour. */
    public var colorByGroup: Bool = true

    /**
     * Throws `PlotException` when `groups` is empty or any group has no finite sample, since a box
     * cannot be summarised from nothing.
     */
    public init(groups: Array<Array<Float64>>, label!: String = "") {
        super()
        if (groups.size == 0) {
            throw PlotException("A box plot needs at least one group.")
        }
        this.groups = groups
        this.label = label
        for (i in 0..groups.size) {
            if (Stats.sortedFinite(groups[i]).size == 0) {
                throw PlotException("Box plot group ${i} has no finite samples.")
            }
        }
        summarise()
    }

    // Rebuilds every group's summary at the current whisker range.
    private func summarise(): Unit {
        summaries.clear()
        for (group in groups) {
            summaries.add(Stats.box(group, whiskerRange: whiskerRangeValue))
        }
    }

    /** The computed summary for each group. */
    public func stats(): ArrayList<BoxStats> {
        summaries
    }

    /** How many groups the series holds. */
    public func count(): Int64 {
        groups.size
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        var low = summaries[0].lowerWhisker
        var high = summaries[0].upperWhisker
        for (summary in summaries) {
            low = minOf(low, summary.lowerWhisker)
            high = maxOf(high, summary.upperWhisker)
            for (outlier in summary.outliers) {
                low = minOf(low, outlier)
                high = maxOf(high, outlier)
            }
        }
        Some((Bounds(-0.5, Float64(groups.size) - 0.5), Bounds(low, high)))
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let half = clampUnitF(bandFraction) / 2.0
        for (i in 0..summaries.size) {
            let summary = summaries[i]
            let color = groupColor(i, theme)
            let left = projection.pixelX(Float64(i) - half)
            let right = projection.pixelX(Float64(i) + half)
            let centerX = (left + right) / 2.0
            let pen = Pen(width: 1.4, color: color)

            let q1Y = projection.pixelY(summary.q1)
            let q3Y = projection.pixelY(summary.q3)
            let boxRect = Rect(left, minOfF(q1Y, q3Y), right - left, absF(q3Y - q1Y))

            drawWhisker(canvas, centerX, projection.pixelY(summary.upperWhisker), minOfF(q1Y, q3Y), left, right, pen)
            drawWhisker(canvas, centerX, projection.pixelY(summary.lowerWhisker), maxOfF(q1Y, q3Y), left, right, pen)

            canvas.fillRoundedRect(boxRect, 2.0, Colors.fade(color, fillOpacity))
            canvas.strokeRoundedRect(boxRect, 2.0, pen)

            let medianY = projection.pixelY(summary.median)
            canvas.line(left, medianY, right, medianY, Pen(width: 2.2, color: Colors.darken(color, 0.25)))

            if (showMean) {
                canvas.marker(MarkerStyle.Diamond, centerX, projection.pixelY(summary.mean), 4.0, theme.panel,
                    edge: Some(pen))
            }
            if (showOutliers) {
                for (outlier in summary.outliers) {
                    canvas.marker(outlierMarker, centerX, projection.pixelY(outlier), 2.6, Colors.fade(color, 0.85))
                }
            }
        }
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let color = resolveColor(theme)
        [
            LegendEntry(label, color) {
                canvas, rect, _ =>
                    canvas.fillRoundedRect(rect, 2.0, Colors.fade(color, 0.45))
                    canvas.strokeRoundedRect(rect, 2.0, Pen(width: 1.2, color: color))
                    canvas.line(rect.x, rect.centerY(), rect.right(), rect.centerY(), Pen(width: 1.6, color: color))
            }
        ]
    }

    public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult {
        // A box spans its whole category band vertically, so only the horizontal position selects it.
        let _ = py
        let half = clampUnitF(bandFraction) / 2.0
        for (i in 0..summaries.size) {
            let left = projection.pixelX(Float64(i) - half)
            let right = projection.pixelX(Float64(i) + half)
            if (px < left || px > right) {
                continue
            }
            let summary = summaries[i]
            let text = "median ${NumberFormat.compact(summary.median)}  IQR ${NumberFormat.compact(summary.iqr())}"
            return Some(
                HitResult(label, Float64(i), summary.median, (left + right) / 2.0, projection.pixelY(summary.median),
                    0.0, groupColor(i, theme), text))
        }
        None
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

    // The stem from the box edge out to the whisker end, plus the cap that terminates it.
    private func drawWhisker(
        canvas: Canvas,
        centerX: Float32,
        endY: Float32,
        boxEdgeY: Float32,
        left: Float32,
        right: Float32,
        pen: Pen
    ): Unit {
        canvas.line(centerX, boxEdgeY, centerX, endY, pen)
        let capInset = (right - left) * 0.25
        canvas.line(left + capInset, endY, right - capInset, endY, pen)
    }
}

func maxOfF(a: Float32, b: Float32): Float32 {
    if (a > b) {
        a
    } else {
        b
    }
}
