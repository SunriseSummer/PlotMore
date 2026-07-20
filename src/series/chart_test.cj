package plot.series

import plot.core.{Bounds, Colormap, LinearScale, PlotException, Projection, Rect, Theme}

func unitProjection(): Projection {
    Projection(Rect(0.0, 0.0, 400.0, 200.0), LinearScale(Bounds(-0.5, 3.5)), LinearScale(Bounds(0.0, 10.0)))
}

@Test
func barSeriesSpansOneBandPerCategory(): Unit {
    let bars = BarSeries([1.0, 2.0, 3.0])

    match (bars.dataBounds()) {
        case Some((bx, by)) =>
            // Categories occupy [-0.5, n-0.5]; the value axis reaches the baseline.
            @Expect(bx.low, -0.5)
            @Expect(bx.high, 2.5)
            @Expect(by.low, 0.0)
            @Expect(by.high, 3.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func barSeriesBoundsCoverNegativeValues(): Unit {
    let bars = BarSeries([-4.0, 2.0])

    match (bars.dataBounds()) {
        case Some((_, by)) =>
            @Expect(by.low, -4.0)
            @Expect(by.high, 2.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func barRectCentresOnItsCategory(): Unit {
    let bars = BarSeries([5.0, 5.0, 5.0, 5.0])
    let rect = bars.barRect(1, unitProjection())

    // Category 1 sits at data x=1, which is pixel 150 of a 400 px panel over [-0.5, 3.5].
    @Expect(rect.centerX() > 149.0 && rect.centerX() < 151.0)
    // Default bandFraction is 0.7 of a 100 px band.
    @Expect(rect.w > 69.0 && rect.w < 71.0)
}

@Test
func groupedBarsShareTheBandWithoutOverlapping(): Unit {
    let first = BarSeries([1.0, 1.0])
    let second = BarSeries([2.0, 2.0])
    let _ = BarGroup.grouped([first, second])

    let projection = unitProjection()
    let a = first.barRect(0, projection)
    let b = second.barRect(0, projection)

    // Two slots in one band: the first sits left of the second and they must not overlap.
    @Expect(a.right() <= b.x + 0.01)
    @Expect(a.centerX() < b.centerX())
}

@Test
func stackedBarsRestOnTheRunningTotal(): Unit {
    let first = BarSeries([1.0, 2.0])
    let second = BarSeries([3.0, 4.0])
    let _ = BarGroup.stacked([first, second])

    match (second.dataBounds()) {
        case Some((_, by)) =>
            // The second layer runs from the first layer's top to the combined total.
            @Expect(by.high, 6.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func stackedBarsSeparatePositiveAndNegativeRuns(): Unit {
    // Mixed signs must grow away from zero in both directions rather than cancelling.
    let first = BarSeries([2.0, -2.0])
    let second = BarSeries([3.0, -3.0])
    let _ = BarGroup.stacked([first, second])

    match (second.dataBounds()) {
        case Some((_, by)) =>
            @Expect(by.high, 5.0)
            @Expect(by.low, -5.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func barGroupRejectsRaggedSeries(): Unit {
    try {
        let _ = BarGroup.grouped([BarSeries([1.0, 2.0]), BarSeries([1.0])])
        @Fail("expected a PlotException for differing bar counts")
    } catch (error: PlotException) {
        @Expect(error.message.contains("same bar count"))
    }
}

@Test
func barSeriesRejectsAMismatchedStackBase(): Unit {
    try {
        BarSeries([1.0, 2.0]).setStackBase([0.0])
        @Fail("expected a PlotException for a short stack base")
    } catch (error: PlotException) {
        @Expect(error.message.contains("stack base"))
    }
}

@Test
func histogramBinsAndNormalises(): Unit {
    let hist = HistogramSeries([1.0, 1.0, 2.0, 2.0], bins: 2)
    hist.setRange(Bounds(1.0, 3.0))

    let counts = hist.heights()
    @Expect(counts.size, 2)
    @Expect(counts[0], 2.0)
    @Expect(counts[1], 2.0)

    hist.norm = HistogramNorm.Frequency
    let frequencies = hist.heights()
    @Expect(frequencies[0], 0.5)
    @Expect(frequencies[1], 0.5)
}

@Test
func histogramDensityIntegratesToOne(): Unit {
    let hist = HistogramSeries([1.0, 1.0, 2.0, 2.0], bins: 2)
    hist.setRange(Bounds(1.0, 3.0))
    hist.norm = HistogramNorm.Density

    // Bin width is 1.0, so each density is 0.5 and the total area is 1.
    let densities = hist.heights()
    var area = 0.0
    for (value in densities) {
        area += value * 1.0
    }
    @Expect(area > 0.999 && area < 1.001)
}

@Test
func histogramChoosesABinCountWhenNotToldOne(): Unit {
    let hist = HistogramSeries([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])

    @Expect(hist.bins() >= 1)
}

@Test
func histogramSeriesRejectsANonPositiveBinCount(): Unit {
    try {
        let _ = HistogramSeries([1.0], bins: 0)
        @Fail("expected a PlotException for a zero bin count")
    } catch (error: PlotException) {
        @Expect(error.message.contains("positive"))
    }
}

@Test
func boxPlotSummarisesEachGroup(): Unit {
    let box = BoxPlotSeries([[1.0, 2.0, 3.0], [10.0, 20.0, 30.0]])

    @Expect(box.count(), 2)
    @Expect(box.stats()[0].median, 2.0)
    @Expect(box.stats()[1].median, 20.0)

    match (box.dataBounds()) {
        case Some((bx, by)) =>
            @Expect(bx.low, -0.5)
            @Expect(bx.high, 1.5)
            @Expect(by.low, 1.0)
            @Expect(by.high, 30.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func boxPlotRejectsEmptyInput(): Unit {
    try {
        let _ = BoxPlotSeries([])
        @Fail("expected a PlotException for no groups")
    } catch (error: PlotException) {
        @Expect(error.message.contains("at least one group"))
    }
    try {
        let _ = BoxPlotSeries([[Float64.NaN]])
        @Fail("expected a PlotException for a group with no finite samples")
    } catch (error: PlotException) {
        @Expect(error.message.contains("no finite samples"))
    }
}

@Test
func violinNeedsTwoSamplesToEstimateADensity(): Unit {
    try {
        let _ = ViolinSeries([[1.0]])
        @Fail("expected a PlotException for a single-sample violin group")
    } catch (error: PlotException) {
        @Expect(error.message.contains("at least two"))
    }
}

@Test
func violinBoundsCoverEveryGroup(): Unit {
    let violin = ViolinSeries([[1.0, 2.0, 3.0], [8.0, 9.0, 10.0]])

    @Expect(violin.count(), 2)
    match (violin.dataBounds()) {
        case Some((bx, by)) =>
            @Expect(bx.low, -0.5)
            @Expect(bx.high, 1.5)
            // The density range is padded past the extreme samples so the tails close.
            @Expect(by.low < 1.0)
            @Expect(by.high > 10.0)
        case None => @Fail("expected bounds")
    }
}

@Test
func heatmapValidatesItsShape(): Unit {
    try {
        let _ = HeatmapSeries([1.0, 2.0, 3.0], rows: 2, columns: 2)
        @Fail("expected a PlotException for a value count that is not rows*columns")
    } catch (error: PlotException) {
        @Expect(error.message.contains("needs 4 values"))
    }
    try {
        let _ = HeatmapSeries([], rows: 0, columns: 2)
        @Fail("expected a PlotException for a zero dimension")
    } catch (error: PlotException) {
        @Expect(error.message.contains("positive"))
    }
}

@Test
func heatmapIndexesRowMajor(): Unit {
    let heat = HeatmapSeries([1.0, 2.0, 3.0, 4.0, 5.0, 6.0], rows: 2, columns: 3)

    @Expect(heat.rows(), 2)
    @Expect(heat.columns(), 3)
    @Expect(heat.value(0, 0), 1.0)
    @Expect(heat.value(0, 2), 3.0)
    @Expect(heat.value(1, 0), 4.0)
}

@Test
func heatmapAutoscalesItsColourRange(): Unit {
    let heat = HeatmapSeries([1.0, 5.0, 3.0, 9.0], rows: 2, columns: 2)
    let range = heat.resolvedValueRange()

    @Expect(range.low, 1.0)
    @Expect(range.high, 9.0)

    heat.valueRange = Some(Bounds(0.0, 100.0))
    @Expect(heat.resolvedValueRange().high, 100.0)
}

@Test
func heatmapFromFunctionSamplesTheGrid(): Unit {
    let heat = HeatmapSeries.fromFunction(3, 3, Bounds(0.0, 2.0), Bounds(0.0, 2.0)) {x, y => x + y}

    @Expect(heat.value(0, 0), 0.0)
    @Expect(heat.value(2, 2), 4.0)
}

@Test
func tiledSeriesReportAnExactExtentAndPointCloudsDoNot(): Unit {
    // Axes reads this to decide whether to pad: a tiled field must reach the panel edge, while a
    // scatter needs margin so its outermost markers are not bisected by the frame.
    let heat = HeatmapSeries([1.0, 2.0, 3.0, 4.0], rows: 2, columns: 2)
    let contour = ContourSeries.fromFunction(3, 3, Bounds(0.0, 1.0), Bounds(0.0, 1.0)) {x, _ => x}

    @Expect(heat.fillsExtent())
    @Expect(contour.fillsExtent())
    @Expect(!LineSeries([0.0], [0.0]).fillsExtent())
    @Expect(!ScatterSeries([0.0], [0.0]).fillsExtent())
    @Expect(!BarSeries([1.0]).fillsExtent())
}

@Test
func contourLegendSwatchFollowsItsColormap(): Unit {
    let theme = Theme.light()
    let contour = ContourSeries.fromFunction(3, 3, Bounds(0.0, 1.0), Bounds(0.0, 1.0)) {x, _ => x}
    contour.label = "level"
    // Palette slot 3 is what resolveColor would give; with a ramp set, the lines are coloured by
    // level instead, so the swatch must sample the ramp or it advertises a colour never drawn.
    contour.setPaletteIndex(3)
    contour.map = Some(Colormap.viridis())

    let swatch = contour.legend(theme)[0].color
    let rampHigh = Colormap.viridis().sample(0.75)
    @Expect(swatch.r, rampHigh.r)
    @Expect(swatch.g, rampHigh.g)
    @Expect(swatch.b, rampHigh.b)
}

@Test
func heatmapBoundsExtendHalfACellPastTheCentres(): Unit {
    // Otherwise the outermost cells are half off the panel.
    let heat = HeatmapSeries([1.0, 2.0, 3.0, 4.0], rows: 2, columns: 2)

    match (heat.dataBounds()) {
        case Some((bx, _)) =>
            @Expect(bx.low, -0.5)
            @Expect(bx.high, 1.5)
        case None => @Fail("expected bounds")
    }
}

@Test
func contourNeedsACellToMarchOver(): Unit {
    try {
        let _ = ContourSeries([1.0], rows: 1, columns: 1, xRange: Bounds(0.0, 1.0), yRange: Bounds(0.0, 1.0))
        @Fail("expected a PlotException for a 1x1 contour grid")
    } catch (error: PlotException) {
        @Expect(error.message.contains("at least 2x2"))
    }
}

@Test
func contourTracesALevelThroughACell(): Unit {
    // A single cell rising 0..1 across x; the 0.5 level must cross it exactly down the middle.
    let contour = ContourSeries([0.0, 1.0, 0.0, 1.0], rows: 2, columns: 2, xRange: Bounds(0.0, 1.0),
        yRange: Bounds(0.0, 1.0))
    let segments = contour.trace(0.5)

    @Expect(segments.size, 1)
    let (ax, _, bx, _) = segments[0]
    @Expect(ax > 0.49 && ax < 0.51)
    @Expect(bx > 0.49 && bx < 0.51)
}

@Test
func contourProducesNothingForALevelOutsideTheField(): Unit {
    let contour = ContourSeries([0.0, 1.0, 0.0, 1.0], rows: 2, columns: 2, xRange: Bounds(0.0, 1.0),
        yRange: Bounds(0.0, 1.0))

    // Every corner is below 5, so the cell is uniformly outside and has no crossing.
    @Expect(contour.trace(5.0).size, 0)
    @Expect(contour.trace(-5.0).size, 0)
}

@Test
func contourSkipsCellsTouchingMissingData(): Unit {
    let contour = ContourSeries([0.0, 1.0, Float64.NaN, 1.0], rows: 2, columns: 2, xRange: Bounds(0.0, 1.0),
        yRange: Bounds(0.0, 1.0))

    // A cell with an unknown corner cannot be interpolated; drawing nothing is the honest choice.
    @Expect(contour.trace(0.5).size, 0)
}

@Test
func contourAutoLevelsStayInsideTheField(): Unit {
    let contour = ContourSeries.fromFunction(10, 10, Bounds(0.0, 1.0), Bounds(0.0, 1.0)) {x, y => x + y}
    let levels = contour.levels()

    @Expect(levels.size > 0)
    for (level in levels) {
        // A level at the exact extreme degenerates to a point and is not worth drawing.
        @Expect(level > 0.0)
        @Expect(level < 2.0)
    }
}

@Test
func contourRejectsAnEmptyLevelList(): Unit {
    let contour = ContourSeries.fromFunction(3, 3, Bounds(0.0, 1.0), Bounds(0.0, 1.0)) {x, _ => x}

    try {
        contour.setLevels([])
        @Fail("expected a PlotException for no levels")
    } catch (error: PlotException) {
        @Expect(error.message.contains("at least one level"))
    }
}

@Test
func seriesOpacityFadesTheResolvedColour(): Unit {
    let theme = Theme.light()
    let series = LineSeries([0.0], [0.0])
    series.setColor(Colormap.viridis().sample(0.5))
    series.opacity = 0.5

    // Opacity multiplies the resolved colour rather than replacing it.
    let entries = series.legend(theme)
    @Expect(entries.size, 0) // no label, so no legend entry
}

@Test
func invisibleSeriesStillReportsItsBounds(): Unit {
    // Visibility is the axes' concern at draw and autoscale time, not the series' own.
    let series = LineSeries([0.0, 1.0], [0.0, 1.0])
    series.visible = false

    @Expect(series.dataBounds().isSome())
}

/**
 * `whiskerRange` is a knob on the series, and the summaries are built once rather than per frame —
 * so setting it has to rebuild them. A field would silently leave the fences at their default and
 * the documented control would do nothing at all.
 */
@Test
func boxPlotWhiskerRangeActuallyMovesTheFences(): Unit {
    // 20 sits well outside 1.5 IQR of this sample, and well inside 5 IQR of it.
    let samples = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 20.0]
    let plot = BoxPlotSeries([samples])
    @Expect(plot.whiskerRange, 1.5)
    @Expect(plot.stats()[0].outliers.size, 1)

    // Widening the fences must pull the outlier back inside and push the whisker out to it.
    plot.whiskerRange = 5.0
    @Expect(plot.whiskerRange, 5.0)
    @Expect(plot.stats()[0].outliers.size, 0)
    @Expect(plot.stats()[0].upperWhisker, 20.0)

    // ...and narrowing them must put it back.
    plot.whiskerRange = 1.5
    @Expect(plot.stats()[0].outliers.size, 1)
    @Expect(plot.stats()[0].outliers[0], 20.0)
    @Expect(plot.stats()[0].upperWhisker, 9.0)
}

/** Changing the fences must not disturb the quartiles, which do not depend on them. */
@Test
func boxPlotWhiskerRangeLeavesTheQuartilesAlone(): Unit {
    let plot = BoxPlotSeries([[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 20.0]])
    let before = plot.stats()[0]

    plot.whiskerRange = 3.0
    let after = plot.stats()[0]

    @Expect(after.q1, before.q1)
    @Expect(after.median, before.median)
    @Expect(after.q3, before.q3)
    @Expect(after.mean, before.mean)
}

/**
 * NaN is a supported heatmap value standing for a missing cell, and `draw` skips those. The hit
 * test has to skip them too: it colours its result through the colormap, and sampling a ramp at NaN
 * used to trap on the Int64 cast inside `sample` — so hovering a gap in the data killed the frame.
 */
@Test
func heatmapHitTestSkipsMissingCells(): Unit {
    let heat = HeatmapSeries([1.0, Float64.NaN, 3.0, 4.0], rows: 2, columns: 2)
    let projection = Projection(Rect(0.0, 0.0, 100.0, 100.0), LinearScale(Bounds(-0.5, 1.5)),
        LinearScale(Bounds(-0.5, 1.5)))

    // Column 1 of row 0 is the NaN cell; nothing is drawn there, so nothing may be reported there.
    @Expect(heat.hitTest(75.0, 75.0, projection, Theme.light()).isNone())

    // The finite cells around it still answer.
    match (heat.hitTest(25.0, 75.0, projection, Theme.light())) {
        case Some(hit) => @Expect(hit.text.contains("[0, 0]"))
        case None => @Fail("expected a hit on the finite cell at [0, 0]")
    }
}

/** A heatmap of nothing but missing data still has to draw, autoscale and hit-test without dying. */
@Test
func heatmapOfEntirelyMissingDataStaysQuiet(): Unit {
    let heat = HeatmapSeries([Float64.NaN, Float64.NaN, Float64.NaN, Float64.NaN], rows: 2, columns: 2)
    let projection = Projection(Rect(0.0, 0.0, 100.0, 100.0), LinearScale(Bounds(-0.5, 1.5)),
        LinearScale(Bounds(-0.5, 1.5)))

    // With no finite value to cover, the ramp domain falls back rather than collapsing.
    @Expect(!heat.resolvedValueRange().isDegenerate())
    @Expect(heat.hitTest(25.0, 25.0, projection, Theme.light()).isNone())
}
