package plot.series

import plot.core.{Bounds, PlotException}

func near(actual: Float64, expected: Float64, tolerance!: Float64 = 1.0e-9): Bool {
    let delta = actual - expected
    if (delta < 0.0) {
        -delta <= tolerance
    } else {
        delta <= tolerance
    }
}

@Test
func sortedFiniteDropsNonFiniteAndOrders(): Unit {
    let sorted = Stats.sortedFinite([3.0, Float64.NaN, 1.0, Float64.Inf, 2.0])

    @Expect(sorted.size, 3)
    @Expect(sorted[0], 1.0)
    @Expect(sorted[1], 2.0)
    @Expect(sorted[2], 3.0)
}

@Test
func quantileInterpolatesBetweenOrderStatistics(): Unit {
    let sorted = Stats.sortedFinite([1.0, 2.0, 3.0, 4.0])

    @Expect(Stats.quantile(sorted, 0.0), 1.0)
    @Expect(Stats.quantile(sorted, 1.0), 4.0)
    // Type-7: position = p*(n-1) = 1.5, so halfway between 2 and 3.
    @Expect(near(Stats.quantile(sorted, 0.5), 2.5))
    @Expect(near(Stats.quantile(sorted, 0.25), 1.75))
}

@Test
func quantileClampsOutOfRangeProbabilities(): Unit {
    let sorted = Stats.sortedFinite([1.0, 2.0, 3.0])

    @Expect(Stats.quantile(sorted, -1.0), 1.0)
    @Expect(Stats.quantile(sorted, 2.0), 3.0)
}

@Test
func quantileOfEmptySampleThrows(): Unit {
    try {
        let _ = Stats.quantile([], 0.5)
        @Fail("expected a PlotException for an empty sample")
    } catch (error: PlotException) {
        @Expect(error.message.contains("empty"))
    }
}

@Test
func meanAndStandardDeviationIgnoreNonFinite(): Unit {
    match (Stats.mean([2.0, 4.0, Float64.NaN, 6.0])) {
        case Some(value) => @Expect(near(value, 4.0))
        case None => @Fail("expected a mean of the finite values")
    }
    // Sample standard deviation of 2,4,6 divides by n-1: sqrt(8/2) = 2.
    match (Stats.standardDeviation([2.0, 4.0, 6.0])) {
        case Some(value) => @Expect(near(value, 2.0, tolerance: 1.0e-9))
        case None => @Fail("expected a standard deviation")
    }
}

@Test
func statisticsOfInsufficientSamplesReportNone(): Unit {
    @Expect(Stats.mean([Float64.NaN]).isNone())
    // A sample standard deviation needs at least two observations to divide by n-1.
    @Expect(Stats.standardDeviation([5.0]).isNone())
}

@Test
func boxSummarisesTheFiveNumbers(): Unit {
    let stats = Stats.box([1.0, 2.0, 3.0, 4.0, 5.0])

    @Expect(near(stats.median, 3.0))
    @Expect(near(stats.q1, 2.0))
    @Expect(near(stats.q3, 4.0))
    @Expect(near(stats.iqr(), 2.0))
    @Expect(near(stats.mean, 3.0))
    @Expect(stats.outliers.size, 0)
    @Expect(near(stats.lowerWhisker, 1.0))
    @Expect(near(stats.upperWhisker, 5.0))
}

@Test
func boxIsolatesOutliersBeyondTheFences(): Unit {
    // q1=2, q3=4, iqr=2, fences at 2-3=-1 and 4+3=7, so 100 is an outlier and 5 is not.
    let stats = Stats.box([1.0, 2.0, 3.0, 4.0, 5.0, 100.0])

    @Expect(stats.outliers.size, 1)
    @Expect(stats.outliers[0], 100.0)
    // The whisker must land on a real observation, not on the fence itself.
    @Expect(stats.upperWhisker, 5.0)
}

@Test
func boxOfAConstantSampleCollapsesCleanly(): Unit {
    let stats = Stats.box([7.0, 7.0, 7.0])

    @Expect(near(stats.median, 7.0))
    @Expect(near(stats.iqr(), 0.0))
    @Expect(stats.outliers.size, 0)
}

@Test
func boxOfEmptySampleThrows(): Unit {
    try {
        let _ = Stats.box([Float64.NaN])
        @Fail("expected a PlotException for a sample with no finite values")
    } catch (error: PlotException) {
        @Expect(error.message.contains("empty"))
    }
}

@Test
func histogramCountsIntoEqualWidthBins(): Unit {
    let counts = Stats.histogram([0.5, 1.5, 1.6, 2.5], Bounds(0.0, 3.0), 3)

    @Expect(counts.size, 3)
    @Expect(counts[0], 1)
    @Expect(counts[1], 2)
    @Expect(counts[2], 1)
}

@Test
func histogramPutsTheTopEdgeInTheLastBin(): Unit {
    // The maximum sample would otherwise index one bin past the end.
    let counts = Stats.histogram([3.0], Bounds(0.0, 3.0), 3)

    @Expect(counts[2], 1)
}

@Test
func histogramSkipsValuesOutsideTheRange(): Unit {
    let counts = Stats.histogram([-1.0, 0.5, 9.0, Float64.NaN], Bounds(0.0, 1.0), 2)

    @Expect(counts[0], 0)
    @Expect(counts[1], 1)
}

@Test
func histogramRejectsANonPositiveBinCount(): Unit {
    try {
        let _ = Stats.histogram([1.0], Bounds(0.0, 1.0), 0)
        @Fail("expected a PlotException for a zero bin count")
    } catch (error: PlotException) {
        @Expect(error.message.contains("at least one"))
    }
}

@Test
func suggestBinCountStaysWithinSaneLimits(): Unit {
    let count = Stats.suggestBinCount([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])

    @Expect(count >= 1)
    @Expect(count <= 200)
    // A constant sample has no spread to subdivide.
    @Expect(Stats.suggestBinCount([5.0, 5.0, 5.0]), 1)
}

@Test
func kernelDensityIsPositiveAndPeaksNearTheData(): Unit {
    let samples = Stats.kernelDensity([0.0, 0.0, 0.0], Bounds(-3.0, 3.0), 61, bandwidth: 0.5)

    @Expect(samples.size, 61)
    // The density of a sample concentrated at zero must peak at zero (index 30 of 61).
    var peakIndex = 0
    for (i in 0..samples.size) {
        @Expect(samples[i] >= 0.0)
        if (samples[i] > samples[peakIndex]) {
            peakIndex = i
        }
    }
    @Expect(peakIndex, 30)
}

@Test
func kernelDensityOfAnEmptySampleIsAllZero(): Unit {
    let samples = Stats.kernelDensity([], Bounds(0.0, 1.0), 5)

    @Expect(samples.size, 5)
    for (value in samples) {
        @Expect(value, 0.0)
    }
}

@Test
func linearFitRecoversAKnownLine(): Unit {
    // y = 3x + 2 exactly.
    match (Stats.linearFit([0.0, 1.0, 2.0, 3.0], [2.0, 5.0, 8.0, 11.0])) {
        case Some((slope, intercept)) =>
            @Expect(near(slope, 3.0, tolerance: 1.0e-9))
            @Expect(near(intercept, 2.0, tolerance: 1.0e-9))
        case None => @Fail("expected a fit for a perfectly linear sample")
    }
}

@Test
func linearFitIgnoresNonFinitePairs(): Unit {
    match (Stats.linearFit([0.0, 1.0, 2.0, 3.0], [2.0, 5.0, Float64.NaN, 11.0])) {
        case Some((slope, _)) => @Expect(near(slope, 3.0, tolerance: 1.0e-9))
        case None => @Fail("expected a fit from the finite pairs")
    }
}

@Test
func linearFitReportsNoneWhenUndetermined(): Unit {
    // A vertical line has no slope, and one point has no line at all.
    @Expect(Stats.linearFit([1.0, 1.0, 1.0], [1.0, 2.0, 3.0]).isNone())
    @Expect(Stats.linearFit([1.0], [1.0]).isNone())
}

@Test
func linearFitRejectsMismatchedLengths(): Unit {
    try {
        let _ = Stats.linearFit([1.0, 2.0], [1.0])
        @Fail("expected a PlotException for mismatched lengths")
    } catch (error: PlotException) {
        @Expect(error.message.contains("matching"))
    }
}

/**
 * Freedman-Diaconis divides the span by a width derived from the IQR, and a sample whose span is
 * many orders of magnitude wider than its IQR — a tight cluster beside a far outlier — makes that
 * ratio exceed Int64. The clamp to 200 has to happen before the cast, since the cast traps rather
 * than saturating.
 */
@Test
func suggestBinCountClampsInsteadOfOverflowing(): Unit {
    // 800 samples inside [0, 8e-10] and 200 at 1e9: the IQR is ~1e-10, the span is 1e9.
    let values = Array<Float64>(1000, repeat: 0.0)
    for (i in 0..800) {
        values[i] = Float64(i) * 1.0e-12
    }
    for (i in 800..1000) {
        values[i] = 1.0e9
    }

    let bins = Stats.suggestBinCount(values)
    @Expect(bins >= 1)
    @Expect(bins <= 200)
}

/** The same shape reaching the series, which picks its bin count by that rule when none is given. */
@Test
func histogramSeriesSurvivesAClusterBesideAFarOutlier(): Unit {
    let values = Array<Float64>(1000, repeat: 0.0)
    for (i in 0..800) {
        values[i] = Float64(i) * 1.0e-12
    }
    for (i in 800..1000) {
        values[i] = 1.0e9
    }

    let histogram = HistogramSeries(values)
    @Expect(histogram.bins() >= 1)
    @Expect(histogram.bins() <= 200)
    // The heights still have to add up to the samples that landed in range.
    var total = 0.0
    for (height in histogram.heights()) {
        total += height
    }
    @Expect(total, 1000.0)
}

@Test
func kernelDensityRejectsANonPositiveSampleCountQuietly(): Unit {
    // The samples array is allocated from `count`, so a negative one has to be caught before it.
    @Expect(Stats.kernelDensity([1.0, 2.0, 3.0], Bounds(0.0, 4.0), -1).size, 0)
    @Expect(Stats.kernelDensity([1.0, 2.0, 3.0], Bounds(0.0, 4.0), 0).size, 0)
    @Expect(Stats.kernelDensity([1.0, 2.0, 3.0], Bounds(0.0, 4.0), 1).size, 1)
}

/** At one station the position formula divides by `count - 1`; both sides must agree on the centre. */
@Test
func singleStationSamplingLandsOnTheRangeCentre(): Unit {
    let range = Bounds(2.0, 6.0)

    let at = sampleAt(range, 0, 1)
    @Expect(!at.isNaN())
    @Expect(at, 4.0)
    // kernelDensity places its one station at the same spot, which is what keeps a violin aligned.
    @Expect(Stats.kernelDensity([2.0, 6.0], range, 1).size, 1)
}
