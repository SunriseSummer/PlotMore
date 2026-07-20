package plot.series

import sdl.{Pen, Rect}
import plot.canvas.Canvas
import plot.core.{Bounds, Colors, PlotException, Projection, Theme}

/** What a histogram's bar heights mean. */
public enum HistogramNorm {
    /** Raw sample counts per bin. */
    | Count

    /** Counts divided by the total, so the bars sum to 1. */
    | Frequency

    /** Counts divided by (total x bin width), so the bars integrate to 1 — comparable to a PDF. */
    | Density
}

/**
 * The distribution of one sample, binned into equal-width buckets.
 *
 * The bin count defaults to the Freedman-Diaconis rule rather than a fixed number: bin width drives
 * what a histogram appears to say, and a fixed count will shred one dataset while flattening the
 * next. Pass `bins` explicitly when comparing distributions, so they share a binning.
 *
 * ```
 * let hist = HistogramSeries(measurements, label: "trial A")
 * hist.norm = HistogramNorm.Density
 * ```
 */
public class HistogramSeries <: Series {
    private let values: Array<Float64>
    private var binCount: Int64
    private var explicitRange: ?Bounds = None

    /** What the bar heights represent. */
    public var norm: HistogramNorm = HistogramNorm.Count

    /** Gap between adjacent bars as a fraction of bin width, `0..1`. Zero draws them touching. */
    public var barGap: Float64 = 0.06

    /** Corner rounding at each bar's top, in logical pixels. */
    public var cornerRadius: Float32 = 2.0

    /** Outlines each bar, which keeps adjacent bins distinct when `barGap` is zero. */
    public var showEdge: Bool = false

    /** Fill opacity, `0..1`. Lower it to overlay several distributions. */
    public var fillOpacity: Float64 = 0.85

    /**
     * `bins` of `None` chooses a count by the Freedman-Diaconis rule.
     *
     * Throws `PlotException` when `bins` is given as zero or negative.
     */
    public init(values: Array<Float64>, bins!: ?Int64 = None, label!: String = "") {
        super()
        this.values = values
        this.binCount = match (bins) {
            case Some(count) where count > 0 => count
            case Some(count) => throw PlotException("A histogram needs a positive bin count; got ${count}.")
            case None => Stats.suggestBinCount(values)
        }
        this.label = label
    }

    /** Pins the binning range; `None` (the default) covers the data. */
    public func setRange(range: Bounds): Unit {
        explicitRange = Some(range)
    }

    /** The number of bins in use. */
    public func bins(): Int64 {
        binCount
    }

    /** The binning range actually used. */
    public func range(): ?Bounds {
        match (explicitRange) {
            case Some(bounds) => Some(bounds)
            case None => match (Bounds.cover(values)) {
                case Some(bounds) => Some(bounds.nonDegenerate())
                case None => None
            }
        }
    }

    /** The bar heights, already normalised per `norm`. */
    public func heights(): Array<Float64> {
        let bounds = match (range()) {
            case Some(b) => b
            case None => return []
        }
        let counts = Stats.histogram(values, bounds, binCount)
        var total = 0
        for (count in counts) {
            total += count
        }
        let result = Array<Float64>(binCount, repeat: 0.0)
        if (total == 0) {
            return result
        }
        let binWidth = bounds.span() / Float64(binCount)
        for (i in 0..binCount) {
            result[i] = match (norm) {
                case Count => Float64(counts[i])
                case Frequency => Float64(counts[i]) / Float64(total)
                case Density => Float64(counts[i]) / (Float64(total) * binWidth)
            }
        }
        result
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        let bounds = match (range()) {
            case Some(b) => b
            case None => return None
        }
        var peak = 0.0
        for (height in heights()) {
            if (height > peak) {
                peak = height
            }
        }
        Some((bounds, Bounds(0.0, peak)))
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let bounds = match (range()) {
            case Some(b) => b
            case None => return
        }
        let fill = Colors.fade(resolveColor(theme), fillOpacity * opacity)
        let binWidth = bounds.span() / Float64(binCount)
        let gap = binWidth * clampUnitF(barGap) / 2.0
        let baseY = projection.pixelY(0.0)
        let barHeights = heights()
        for (i in 0..binCount) {
            if (barHeights[i] <= 0.0) {
                continue
            }
            let left = projection.pixelX(bounds.low + Float64(i) * binWidth + gap)
            let right = projection.pixelX(bounds.low + Float64(i + 1) * binWidth - gap)
            let top = projection.pixelY(barHeights[i])
            let rect = Rect(left, top, right - left, baseY - top)
            if (rect.w <= 0.0 || rect.h <= 0.0) {
                continue
            }
            let radius = minOfF(cornerRadius, minOfF(rect.w, rect.h) / 2.0)
            if (radius > 0.5) {
                canvas.fillPerCornerRect(rect, fill, topLeft: radius, topRight: radius, bottomRight: 0.0,
                    bottomLeft: 0.0)
            } else {
                canvas.fillRect(rect, fill)
            }
            if (showEdge) {
                canvas.strokeRect(rect, Pen(width: 1.0, color: theme.panel))
            }
        }
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let fill = Colors.fade(resolveColor(theme), fillOpacity)
        [LegendEntry(label, fill) {canvas, rect, _ => canvas.fillRoundedRect(rect, 2.0, fill)}]
    }
}
