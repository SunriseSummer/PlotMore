package plot.series

import plot.core.{Bounds, Colormap, LinearScale, LogScale, PlotException, Projection, Rect, Theme}

func testProjection(): Projection {
    Projection(Rect(0.0, 0.0, 100.0, 100.0), LinearScale(Bounds(0.0, 10.0)), LinearScale(Bounds(0.0, 10.0)))
}

@Test
func requireSameLengthNamesBothLengths(): Unit {
    try {
        requireSameLength([1.0, 2.0], [1.0], "Widget")
        @Fail("expected a PlotException for mismatched lengths")
    } catch (error: PlotException) {
        // The message must name the sizes; "mismatch" alone leaves the caller hunting.
        @Expect(error.message.contains("Widget"))
        @Expect(error.message.contains("2"))
        @Expect(error.message.contains("1"))
    }
}

@Test
func pairedBoundsSkipsPointsWithEitherCoordinateMissing(): Unit {
    // The NaN y must not stretch the x range out to 99.
    match (pairedBounds([1.0, 99.0, 3.0], [4.0, Float64.NaN, 6.0])) {
        case Some((bx, by)) =>
            @Expect(bx.low, 1.0)
            @Expect(bx.high, 3.0)
            @Expect(by.low, 4.0)
            @Expect(by.high, 6.0)
        case None => @Fail("expected bounds from the finite pairs")
    }
}

@Test
func pairedBoundsReportsNoneWithoutFinitePairs(): Unit {
    @Expect(pairedBounds([], []).isNone())
    @Expect(pairedBounds([Float64.NaN], [1.0]).isNone())
}

@Test
func plottableRunsSplitsAtGaps(): Unit {
    let runs = plottableRuns([1.0, 2.0, 3.0, 4.0, 5.0], [1.0, 2.0, Float64.NaN, 4.0, 5.0], testProjection())

    // A gap must break the line rather than being bridged by a straight segment.
    @Expect(runs.size, 2)
    @Expect(runs[0].size, 2)
    @Expect(runs[1].size, 2)
}

@Test
func plottableRunsSplitsOnValuesTheScaleRejects(): Unit {
    let logProjection = Projection(Rect(0.0, 0.0, 100.0, 100.0), LinearScale(Bounds(0.0, 10.0)),
        LogScale(Bounds(1.0, 100.0)))
    let runs = plottableRuns([1.0, 2.0, 3.0], [10.0, 0.0, 50.0], logProjection)

    // Zero has no position on a log axis, so it ends the run just like a NaN does.
    @Expect(runs.size, 2)
}

@Test
func plottableRunsOfAllFinitePointsIsOneRun(): Unit {
    let runs = plottableRuns([1.0, 2.0, 3.0], [1.0, 2.0, 3.0], testProjection())

    @Expect(runs.size, 1)
    @Expect(runs[0].size, 3)
}

@Test
func lineSeriesRejectsMismatchedCoordinates(): Unit {
    try {
        let _ = LineSeries([1.0, 2.0], [1.0])
        @Fail("expected a PlotException for mismatched lengths")
    } catch (error: PlotException) {
        @Expect(error.message.contains("LineSeries"))
    }
}

@Test
func lineSeriesBoundsCoverTheFillBaseline(): Unit {
    let series = LineSeries([0.0, 1.0], [5.0, 7.0])
    series.fillTo = Some(0.0)

    // The fill reaches the baseline, so autoscale has to include it or the fill clips.
    match (series.dataBounds()) {
        case Some((_, by)) =>
            @Expect(by.low, 0.0)
            @Expect(by.high, 7.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func lineSeriesTakesItsPaletteSlotUnlessPinned(): Unit {
    let theme = Theme.light()
    let series = LineSeries([0.0], [0.0])
    series.setPaletteIndex(2)

    @Expect(series.color().isNone())
    @Expect(series.indexInPalette(), 2)

    series.setColor(theme.palette.at(5))
    @Expect(series.color().isSome())
}

@Test
func lineSeriesLegendIsEmptyWithoutALabel(): Unit {
    let theme = Theme.light()

    @Expect(LineSeries([0.0], [0.0]).legend(theme).size, 0)
    @Expect(LineSeries([0.0], [0.0], label: "named").legend(theme).size, 1)
}

@Test
func scatterSeriesRejectsMismatchedMappingArrays(): Unit {
    let series = ScatterSeries([1.0, 2.0], [1.0, 2.0])

    try {
        series.sizeBy([1.0])
        @Fail("expected a PlotException for a short sizeBy array")
    } catch (error: PlotException) {
        @Expect(error.message.contains("sizeBy"))
    }
    try {
        series.colorBy([1.0], Colormap.viridis())
        @Fail("expected a PlotException for a short colorBy array")
    } catch (error: PlotException) {
        @Expect(error.message.contains("colorBy"))
    }
}

@Test
func scatterSeriesReportsItsColourDomainForABar(): Unit {
    let series = ScatterSeries([1.0, 2.0], [1.0, 2.0])
    @Expect(series.colorValueBounds().isNone())

    series.colorBy([10.0, 30.0], Colormap.viridis())
    match (series.colorValueBounds()) {
        case Some(bounds) =>
            @Expect(bounds.low, 10.0)
            @Expect(bounds.high, 30.0)
        case None => @Fail("expected a colour domain once colorBy is set")
    }
}

@Test
func scatterSeriesHonoursAnExplicitColourDomain(): Unit {
    let series = ScatterSeries([1.0, 2.0], [1.0, 2.0])
    series.colorBy([10.0, 30.0], Colormap.viridis(), domain: Bounds(0.0, 100.0))

    match (series.colorValueBounds()) {
        case Some(bounds) =>
            @Expect(bounds.low, 0.0)
            @Expect(bounds.high, 100.0)
        case None => @Fail("expected the pinned domain")
    }
}

@Test
func hitTestFindsTheNearestPointInPixelSpace(): Unit {
    let theme = Theme.light()
    let series = LineSeries([0.0, 5.0, 10.0], [0.0, 5.0, 10.0], label: "s")
    // Panel is 100x100 over a 0..10 domain, so data (5,5) sits at pixel (50, 50).
    match (series.hitTest(52.0, 48.0, testProjection(), theme)) {
        case Some(hit) =>
            @Expect(hit.dataX, 5.0)
            @Expect(hit.dataY, 5.0)
            @Expect(hit.label, "s")
        case None => @Fail("expected a hit near the middle point")
    }
}

@Test
func stepSeriesBoundsIncludeItsFillBaseline(): Unit {
    let series = StepSeries([0.0, 1.0], [3.0, 4.0])
    series.fillTo = Some(0.0)

    match (series.dataBounds()) {
        case Some((_, by)) => @Expect(by.low, 0.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func stemSeriesBoundsIncludeItsBaseline(): Unit {
    let series = StemSeries([0.0, 1.0], [3.0, 4.0])

    match (series.dataBounds()) {
        case Some((_, by)) =>
            @Expect(by.low, 0.0)
            @Expect(by.high, 4.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func errorBarBoundsReachTheBarEnds(): Unit {
    let series = ErrorBarSeries([1.0, 2.0], [10.0, 20.0])
    series.setYError([1.0, 2.0])

    // Autoscale must cover the bars, not just the points, or the caps clip at the panel edge.
    match (series.dataBounds()) {
        case Some((_, by)) =>
            @Expect(by.low, 9.0)
            @Expect(by.high, 22.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func errorBarAsymmetricRangesApplyIndependently(): Unit {
    let series = ErrorBarSeries([1.0], [10.0])
    series.setYErrorRange([3.0], [1.0])

    match (series.dataBounds()) {
        case Some((_, by)) =>
            @Expect(by.low, 7.0)
            @Expect(by.high, 11.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func errorBarRejectsMismatchedErrorArrays(): Unit {
    let series = ErrorBarSeries([1.0, 2.0], [1.0, 2.0])

    try {
        series.setYError([1.0])
        @Fail("expected a PlotException for a short error array")
    } catch (error: PlotException) {
        @Expect(error.message.contains("setYError"))
    }
}

@Test
func areaSeriesBetweenCoversBothBoundaries(): Unit {
    let band = AreaSeries.between([0.0, 1.0], [1.0, 2.0], [5.0, 6.0], label: "ci")

    match (band.dataBounds()) {
        case Some((bx, by)) =>
            @Expect(bx.low, 0.0)
            @Expect(bx.high, 1.0)
            @Expect(by.low, 1.0)
            @Expect(by.high, 6.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func areaStackAccumulatesLayersInOrder(): Unit {
    let layers = AreaStack.build([0.0, 1.0], [[1.0, 2.0], [3.0, 4.0]], labels: ["a", "b"])

    @Expect(layers.size, 2)
    @Expect(layers[0].lowerValues()[0], 0.0)
    @Expect(layers[0].upperValues()[0], 1.0)
    // The second layer starts where the first ended.
    @Expect(layers[1].lowerValues()[0], 1.0)
    @Expect(layers[1].upperValues()[0], 4.0)
    @Expect(layers[1].upperValues()[1], 6.0)
}

@Test
func areaStackTreatsMissingSamplesAsZeroContribution(): Unit {
    // A NaN in one layer must not poison every layer stacked above it.
    let layers = AreaStack.build([0.0], [[Float64.NaN], [2.0]])

    @Expect(layers[1].lowerValues()[0], 0.0)
    @Expect(layers[1].upperValues()[0], 2.0)
}
