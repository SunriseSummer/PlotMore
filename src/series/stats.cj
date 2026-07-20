package plot.series

import std.collection.ArrayList
import std.math.{ceil, exp, floor, log, pow, sqrt}
import std.sort.sort
import plot.core.{Bounds, PlotException, isFinite}

/** The five-number summary plus outliers that a box plot draws. */
public struct BoxStats {
    /** The lower quartile (25th percentile). */
    public let q1: Float64

    /** The median (50th percentile). */
    public let median: Float64

    /** The upper quartile (75th percentile). */
    public let q3: Float64

    /** The lowest sample still within the whisker reach. */
    public let lowerWhisker: Float64

    /** The highest sample still within the whisker reach. */
    public let upperWhisker: Float64

    /** Samples beyond the whiskers. */
    public let outliers: Array<Float64>

    /** The arithmetic mean of the samples. */
    public let mean: Float64

    public init(
        q1: Float64,
        median: Float64,
        q3: Float64,
        lowerWhisker: Float64,
        upperWhisker: Float64,
        outliers: Array<Float64>,
        mean: Float64
    ) {
        this.q1 = q1
        this.median = median
        this.q3 = q3
        this.lowerWhisker = lowerWhisker
        this.upperWhisker = upperWhisker
        this.outliers = outliers
        this.mean = mean
    }

    /** The interquartile range. */
    public func iqr(): Float64 {
        q3 - q1
    }
}

/**
 * Descriptive statistics used by the distribution chart types.
 *
 * Every entry point filters non-finite values first, so a dataset with gaps summarises its real
 * samples instead of producing NaN.
 */
public class Stats {
    /** The finite subset of `values`, sorted ascending — the input every other method here expects. */
    public static func sortedFinite(values: Array<Float64>): Array<Float64> {
        let kept = ArrayList<Float64>()
        for (value in values) {
            if (isFinite(value)) {
                kept.add(value)
            }
        }
        let result = kept.toArray()
        sort(result)
        result
    }

    /**
     * The `p`-th quantile (`p` in `0..1`) of an already-sorted array, by linear interpolation
     * between the two straddling order statistics — the R type-7 definition, which is what
     * numpy.percentile and most spreadsheets use.
     *
     * Throws `PlotException` when `sorted` is empty.
     */
    public static func quantile(sorted: Array<Float64>, p: Float64): Float64 {
        if (sorted.size == 0) {
            throw PlotException("Cannot take a quantile of an empty sample.")
        }
        if (sorted.size == 1) {
            return sorted[0]
        }
        let clamped = clampUnitF(p)
        let position = clamped * Float64(sorted.size - 1)
        let lower = Int64(floor(position))
        let upper = Int64(ceil(position))
        if (lower == upper) {
            return sorted[lower]
        }
        let weight = position - Float64(lower)
        sorted[lower] * (1.0 - weight) + sorted[upper] * weight
    }

    /** The arithmetic mean of the finite values, or `None` when there are none. */
    public static func mean(values: Array<Float64>): ?Float64 {
        var total = 0.0
        var count = 0
        for (value in values) {
            if (isFinite(value)) {
                total += value
                count += 1
            }
        }
        if (count == 0) {
            None
        } else {
            Some(total / Float64(count))
        }
    }

    /** The sample standard deviation (dividing by n-1), or `None` with fewer than two values. */
    public static func standardDeviation(values: Array<Float64>): ?Float64 {
        let finite = ArrayList<Float64>()
        for (value in values) {
            if (isFinite(value)) {
                finite.add(value)
            }
        }
        if (finite.size < 2) {
            return None
        }
        var total = 0.0
        for (value in finite) {
            total += value
        }
        let average = total / Float64(finite.size)
        var sumSquares = 0.0
        for (value in finite) {
            let delta = value - average
            sumSquares += delta * delta
        }
        Some(sqrt(sumSquares / Float64(finite.size - 1)))
    }

    /**
     * The box-plot summary of `values`.
     *
     * Whiskers reach to the furthest sample within `whiskerRange` interquartile ranges of the
     * quartiles (Tukey's rule, 1.5 by convention); anything past that is reported as an outlier.
     * The whiskers land on real data points rather than on the fence itself, so a whisker always
     * marks an observation.
     *
     * Throws `PlotException` when no finite value is present.
     */
    public static func box(values: Array<Float64>, whiskerRange!: Float64 = 1.5): BoxStats {
        let sorted = sortedFinite(values)
        if (sorted.size == 0) {
            throw PlotException("Cannot summarise an empty sample.")
        }
        let q1 = quantile(sorted, 0.25)
        let median = quantile(sorted, 0.5)
        let q3 = quantile(sorted, 0.75)
        let fence = (q3 - q1) * whiskerRange
        let lowFence = q1 - fence
        let highFence = q3 + fence
        var lowerWhisker = sorted[sorted.size - 1]
        var upperWhisker = sorted[0]
        let outliers = ArrayList<Float64>()
        for (value in sorted) {
            if (value < lowFence || value > highFence) {
                outliers.add(value)
            } else {
                if (value < lowerWhisker) {
                    lowerWhisker = value
                }
                if (value > upperWhisker) {
                    upperWhisker = value
                }
            }
        }
        // Every sample outside the fences leaves the whiskers crossed; collapse them onto the median.
        if (lowerWhisker > upperWhisker) {
            lowerWhisker = median
            upperWhisker = median
        }
        var total = 0.0
        for (value in sorted) {
            total += value
        }
        BoxStats(q1, median, q3, lowerWhisker, upperWhisker, outliers.toArray(), total / Float64(sorted.size))
    }

    /**
     * Bins `values` into `count` equal-width buckets across `range`, returning per-bin counts.
     *
     * Values on a boundary fall in the upper bin, except at the very top edge where they fall in
     * the last bin — otherwise the maximum sample would land in a bin that does not exist.
     */
    public static func histogram(values: Array<Float64>, range: Bounds, count: Int64): Array<Int64> {
        if (count < 1) {
            throw PlotException("A histogram needs at least one bin; got ${count}.")
        }
        let counts = Array<Int64>(count, repeat: 0)
        let span = range.span()
        if (span <= 0.0) {
            return counts
        }
        for (value in values) {
            if (!isFinite(value) || value < range.low || value > range.high) {
                continue
            }
            var index = Int64((value - range.low) / span * Float64(count))
            if (index >= count) {
                index = count - 1
            }
            if (index < 0) {
                index = 0
            }
            counts[index] += 1
        }
        counts
    }

    /**
     * A bin count chosen by the Freedman-Diaconis rule, clamped to a sane range.
     *
     * Bin width `2 * IQR / n^(1/3)` adapts to spread rather than to sample count alone, which is
     * what keeps a heavy-tailed distribution from being shredded into noise. Falls back to Sturges'
     * rule when the IQR is zero (a sample with more than half its mass on one value).
     */
    public static func suggestBinCount(values: Array<Float64>): Int64 {
        let sorted = sortedFinite(values)
        if (sorted.size < 2) {
            return 1
        }
        let iqr = quantile(sorted, 0.75) - quantile(sorted, 0.25)
        let span = sorted[sorted.size - 1] - sorted[0]
        if (span <= 0.0) {
            return 1
        }
        var count = if (iqr <= 0.0) {
            Int64(ceil(log2Approx(Float64(sorted.size)))) + 1
        } else {
            let width = 2.0 * iqr / pow(Float64(sorted.size), 1.0 / 3.0)
            // Clamped in float space, before the cast rather than after it: a sample whose span is
            // many orders of magnitude wider than its IQR — a tight cluster beside a far outlier —
            // makes this ratio exceed Int64, and the cast traps instead of saturating.
            clampBinCount(ceil(span / width))
        }
        if (count < 1) {
            count = 1
        }
        if (count > 200) {
            count = 200
        }
        count
    }

    /**
     * A Gaussian kernel density estimate of `values`, sampled at `count` points across `range`.
     *
     * `bandwidth` is the kernel standard deviation; `None` uses Silverman's rule of thumb, which is
     * a reasonable default for roughly unimodal data and over-smooths multimodal data — pass an
     * explicit bandwidth when the shape matters.
     */
    public static func kernelDensity(
        values: Array<Float64>,
        range: Bounds,
        count: Int64,
        bandwidth!: ?Float64 = None
    ): Array<Float64> {
        // Checked before the allocation, not after: Array rejects a negative size outright.
        if (count < 1) {
            return []
        }
        let sorted = sortedFinite(values)
        let samples = Array<Float64>(count, repeat: 0.0)
        if (sorted.size == 0) {
            return samples
        }
        let h = match (bandwidth) {
            case Some(value) where value > 0.0 => value
            case _ => silvermanBandwidth(sorted)
        }
        if (h <= 0.0) {
            return samples
        }
        let scale = 1.0 / (Float64(sorted.size) * h * sqrt(2.0 * 3.141592653589793))
        for (i in 0..count) {
            let x = if (count == 1) {
                range.center()
            } else {
                range.low + range.span() * Float64(i) / Float64(count - 1)
            }
            var total = 0.0
            for (value in sorted) {
                let z = (x - value) / h
                total += exp(-0.5 * z * z)
            }
            samples[i] = total * scale
        }
        samples
    }

    /** Silverman's rule-of-thumb bandwidth: `0.9 * min(sd, IQR/1.34) * n^(-1/5)`. */
    public static func silvermanBandwidth(sorted: Array<Float64>): Float64 {
        if (sorted.size < 2) {
            return 1.0
        }
        let spread = match (standardDeviation(sorted)) {
            case Some(value) => value
            case None => 0.0
        }
        let iqr = quantile(sorted, 0.75) - quantile(sorted, 0.25)
        var measure = spread
        if (iqr > 0.0) {
            let scaled = iqr / 1.34
            if (scaled < measure || measure <= 0.0) {
                measure = scaled
            }
        }
        if (measure <= 0.0) {
            return 1.0
        }
        0.9 * measure * pow(Float64(sorted.size), -0.2)
    }

    /**
     * Ordinary least-squares fit of `y = slope * x + intercept`, or `None` when fewer than two
     * points are finite or every x is identical (a vertical line has no slope).
     */
    public static func linearFit(xs: Array<Float64>, ys: Array<Float64>): ?(Float64, Float64) {
        requireSameLength(xs, ys, "linearFit")
        var n = 0.0
        var sumX = 0.0
        var sumY = 0.0
        var sumXY = 0.0
        var sumXX = 0.0
        for (i in 0..xs.size) {
            let x = xs[i]
            let y = ys[i]
            if (!isFinite(x) || !isFinite(y)) {
                continue
            }
            n += 1.0
            sumX += x
            sumY += y
            sumXY += x * y
            sumXX += x * x
        }
        if (n < 2.0) {
            return None
        }
        let denominator = n * sumXX - sumX * sumX
        if (denominator == 0.0) {
            return None
        }
        let slope = (n * sumXY - sumX * sumY) / denominator
        Some((slope, (sumY - slope * sumX) / n))
    }
}

func clampUnitF(value: Float64): Float64 {
    if (value < 0.0) {
        0.0
    } else if (value > 1.0) {
        1.0
    } else {
        value
    }
}

// Saturates rather than trapping: `suggestBinCount` clamps to 200 anyway, so anything at or above
// that — including a ratio too large for Int64, or a non-finite one — is already the same answer.
func clampBinCount(estimate: Float64): Int64 {
    if (estimate.isNaN()) {
        return 1
    }
    if (estimate >= 200.0) {
        return 200
    }
    if (estimate < 1.0) {
        return 1
    }
    Int64(estimate)
}

// std.math has no log2; the change-of-base form is exact enough for a bin-count heuristic.
func log2Approx(value: Float64): Float64 {
    if (value <= 0.0) {
        return 0.0
    }
    log(value) / log(2.0)
}
