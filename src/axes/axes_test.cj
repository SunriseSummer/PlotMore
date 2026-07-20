package plot.axes

import sdl.Rect
import plot.canvas.Canvas
import plot.core.{Bounds, CategoryScale, Colormap, LinearScale, LogScale, PlotException, Renderer, Theme}
import plot.series.{BarSeries, HeatmapSeries, LineSeries}

/*
 * A canvas over a headless renderer: drawing is a no-op and text falls back to a proportional
 * estimate, which is exactly what layout needs to be exercised without a window.
 */
func headlessCanvas(): Canvas {
    Canvas(Renderer.headless())
}

@Test
func axesAutoscalesToTheUnionOfItsSeries(): Unit {
    let axes = Axes()
    axes.add(LineSeries([0.0, 1.0], [0.0, 5.0]))
    axes.add(LineSeries([-2.0, 3.0], [1.0, 2.0]))

    let x = axes.effectiveXBounds()
    // Union is [-2, 3]; the default 5% headroom opens it a quarter unit either side.
    @Expect(x.low < -2.0)
    @Expect(x.high > 3.0)
    @Expect(x.low > -2.5)
    @Expect(axes.effectiveYBounds().high > 5.0)
}

@Test
func axesSkipsInvisibleSeriesWhenAutoscaling(): Unit {
    let axes = Axes()
    axes.add(LineSeries([0.0, 1.0], [0.0, 1.0]))
    let hidden = axes.add(LineSeries([0.0, 1000.0], [0.0, 1000.0]))
    hidden.visible = false

    // A toggled-off series must not keep stretching the axis; that is the point of toggling it.
    @Expect(axes.effectiveXBounds().high < 10.0)
}

@Test
func axesLimitsOverrideAutoscale(): Unit {
    let axes = Axes()
    axes.add(LineSeries([0.0, 1.0], [0.0, 5.0]))
    axes.setYLimits(Bounds(-100.0, 100.0))

    @Expect(axes.effectiveYBounds().low, -100.0)
    @Expect(axes.effectiveYBounds().high, 100.0)

    axes.autoscaleY()
    @Expect(axes.effectiveYBounds().high < 10.0)
}

@Test
func axesViewOverridesLimitsAndResetRestoresThem(): Unit {
    let axes = Axes()
    axes.add(LineSeries([0.0, 1.0], [0.0, 5.0]))
    axes.setYLimits(Bounds(0.0, 10.0))
    @Expect(!axes.hasView())

    axes.setView(Bounds(0.0, 1.0), Bounds(2.0, 3.0))
    @Expect(axes.hasView())
    @Expect(axes.effectiveYBounds().low, 2.0)

    // Reset must land back on the author's limits, not on whatever the data happens to be.
    axes.resetView()
    @Expect(!axes.hasView())
    @Expect(axes.effectiveYBounds().low, 0.0)
    @Expect(axes.effectiveYBounds().high, 10.0)
}

@Test
func axesWithNoSeriesFallsBackToTheScaleDomain(): Unit {
    let axes = Axes()
    axes.setXScale(LinearScale(Bounds(3.0, 7.0)))

    // An empty panel still needs an axis; inventing 0..1 would contradict a caller who set one.
    @Expect(axes.effectiveXBounds().low, 3.0)
    @Expect(axes.effectiveXBounds().high, 7.0)
}

@Test
func axesAssignsPaletteSlotsInAdditionOrder(): Unit {
    let axes = Axes()
    let first = axes.add(LineSeries([0.0], [0.0]))
    let second = axes.add(LineSeries([0.0], [0.0]))
    let third = axes.add(LineSeries([0.0], [0.0]))

    @Expect(first.indexInPalette(), 0)
    @Expect(second.indexInPalette(), 1)
    @Expect(third.indexInPalette(), 2)
}

@Test
func axesCategoryScaleIgnoresDataWhenSizingTheAxis(): Unit {
    let axes = Axes()
    axes.setXScale(CategoryScale(["a", "b", "c", "d"]))
    axes.add(BarSeries([1.0, 2.0, 3.0, 4.0]))

    // Four categories means [-0.5, 3.5] exactly — no headroom on a category axis.
    @Expect(axes.effectiveXBounds().low, -0.5)
    @Expect(axes.effectiveXBounds().high, 3.5)
}

@Test
func axesLogScaleAutoscaleStaysPositive(): Unit {
    let axes = Axes()
    axes.setYScale(LogScale(Bounds(1.0, 10.0)))
    axes.add(LineSeries([0.0, 1.0], [1.0, 1.0e6]))

    // The regression: additive padding of [1, 1e6] would give a negative low edge and throw.
    let y = axes.effectiveYBounds()
    @Expect(y.low > 0.0)
    @Expect(y.high > 1.0e6)
}

@Test
func axesTiledSeriesFillsThePanelWithoutHeadroom(): Unit {
    let axes = Axes()
    let heat = HeatmapSeries([1.0, 2.0, 3.0, 4.0], rows: 2, columns: 2)
    heat.xRange = Some(Bounds(0.0, 10.0))
    heat.yRange = Some(Bounds(0.0, 10.0))
    axes.add(heat)

    // A field must reach the panel edge; padding would ring it with background.
    let x = axes.effectiveXBounds()
    @Expect(x.low, -5.0)
    @Expect(x.high, 15.0)
}

@Test
func axesDrawsAndReportsAPlotAreaInsideItsFrame(): Unit {
    let canvas = headlessCanvas()
    try {
        let axes = Axes()
        axes.title = "t"
        axes.xLabel = "x"
        axes.yLabel = "y"
        axes.add(LineSeries([0.0, 1.0], [0.0, 1.0], label: "s"))
        let frame = Rect(0.0, 0.0, 800.0, 600.0)
        axes.draw(canvas, frame, Theme.light())

        let area = axes.dataArea()
        // Labels and ticks must have carved real space out of the frame.
        @Expect(area.w > 0.0)
        @Expect(area.h > 0.0)
        @Expect(area.x > frame.x)
        @Expect(area.right() <= frame.right())
        @Expect(area.bottom() < frame.bottom())
        @Expect(axes.frame().w, 800.0)
    } finally {
        canvas.close()
    }
}

@Test
func axesSurvivesADegenerateFrame(): Unit {
    let canvas = headlessCanvas()
    try {
        let axes = Axes()
        axes.add(LineSeries([0.0, 1.0], [0.0, 1.0]))
        // A panel can legitimately measure to nothing mid-layout; it must not divide by zero.
        axes.draw(canvas, Rect(0.0, 0.0, 4.0, 4.0), Theme.light())

        @Expect(axes.dataArea().w >= 1.0)
        @Expect(axes.dataArea().h >= 1.0)
    } finally {
        canvas.close()
    }
}

/**
 * The right margin has to be measured from the rightmost *labelled* tick.
 *
 * A scale with minor divisions appends its minors after its majors, so the last entry is normally an
 * unlabelled minor — measuring that reserves no margin and clips the final x label off the panel.
 */
@Test
func axesReservesTheRightMarginEvenWithMinorTicks(): Unit {
    let canvas = headlessCanvas()
    try {
        let theme = Theme.light()
        let frame = Rect(0.0, 0.0, 800.0, 600.0)

        let plain = Axes()
        plain.add(LineSeries([0.0, 1000.0], [0.0, 1.0]))
        plain.draw(canvas, frame, theme)
        let plainRight = frame.right() - plain.dataArea().right()

        let withMinors = Axes()
        let scale = LinearScale()
        scale.setMinorDivisions(5)
        withMinors.setXScale(scale)
        withMinors.add(LineSeries([0.0, 1000.0], [0.0, 1.0]))
        withMinors.draw(canvas, frame, theme)
        let minorRight = frame.right() - withMinors.dataArea().right()

        // Minor ticks carry no labels, so they must not change what the margin needs to be.
        @Expect(minorRight > 0.0)
        @Expect(near32(minorRight, plainRight, 0.5))
    } finally {
        canvas.close()
    }
}

func near32(actual: Float32, expected: Float32, tolerance: Float32): Bool {
    let delta = actual - expected
    if (delta < 0.0) {
        -delta <= tolerance
    } else {
        delta <= tolerance
    }
}

@Test
func yLabelOrientationsReserveTheSpaceTheyDrawIn(): Unit {
    let canvas = headlessCanvas()
    try {
        let theme = Theme.light()
        let frame = Rect(0.0, 0.0, 800.0, 600.0)

        let bare = Axes()
        bare.add(LineSeries([0.0, 1.0], [0.0, 1.0]))
        bare.draw(canvas, frame, theme)

        // The default: rotated vertical on the left must carve out left margin, and only that.
        let vertical = Axes()
        vertical.yLabel = "amplitude"
        vertical.add(LineSeries([0.0, 1.0], [0.0, 1.0]))
        vertical.draw(canvas, frame, theme)
        @Expect(vertical.dataArea().x > bare.dataArea().x)
        @Expect(near32(vertical.dataArea().y, bare.dataArea().y, 0.5))

        // The dashboard alternative reserves headroom above the panel instead of left margin.
        let horizontal = Axes()
        horizontal.yLabel = "amplitude"
        horizontal.yLabelOrientation = LabelOrientation.Horizontal
        horizontal.add(LineSeries([0.0, 1.0], [0.0, 1.0]))
        horizontal.draw(canvas, frame, theme)
        @Expect(horizontal.dataArea().y > vertical.dataArea().y)
        @Expect(horizontal.dataArea().x < vertical.dataArea().x)

        // Stacked reserves a glyph-wide left band, like vertical does.
        let stacked = Axes()
        stacked.yLabel = "幅度"
        stacked.yLabelOrientation = LabelOrientation.Stacked
        stacked.add(LineSeries([0.0, 1.0], [0.0, 1.0]))
        stacked.draw(canvas, frame, theme)
        @Expect(stacked.dataArea().x > bare.dataArea().x)
    } finally {
        canvas.close()
    }
}

@Test
func axesLegendTogglesTheSeriesBehindAnEntry(): Unit {
    let theme = Theme.light()
    let axes = Axes()
    let first = axes.add(LineSeries([0.0], [0.0], label: "a"))
    let second = axes.add(LineSeries([0.0], [0.0], label: "b"))
    // An unlabelled series contributes no entry, so indices track entries, not series.
    let _ = axes.add(LineSeries([0.0], [0.0]))

    @Expect(axes.legendEntries(theme).size, 2)
    @Expect(axes.toggleLegendEntry(1, theme))
    @Expect(first.visible)
    @Expect(!second.visible)
    @Expect(axes.legendHiddenFlags(theme)[1])
    @Expect(!axes.toggleLegendEntry(9, theme))
}

@Test
func axesHitTestFindsTheNearestPointAcrossSeries(): Unit {
    let canvas = headlessCanvas()
    try {
        let theme = Theme.light()
        let axes = Axes()
        axes.add(LineSeries([0.0, 5.0, 10.0], [0.0, 5.0, 10.0], label: "diagonal"))
        axes.draw(canvas, Rect(0.0, 0.0, 800.0, 600.0), theme)

        let target = axes.projection().pixel(5.0, 5.0)
        match (axes.hitTest(target.x + 2.0, target.y + 2.0, theme)) {
            case Some(hit) =>
                @Expect(hit.label, "diagonal")
                @Expect(hit.dataX, 5.0)
            case None => @Fail("expected a hit near the middle point")
        }
        // Outside the plot area there is nothing to report.
        @Expect(axes.hitTest(-50.0, -50.0, theme).isNone())
    } finally {
        canvas.close()
    }
}

@Test
func axesClearRemovesSeriesButKeepsConfiguration(): Unit {
    let axes = Axes()
    axes.setYLimits(Bounds(0.0, 42.0))
    axes.add(LineSeries([0.0], [0.0]))
    axes.clear()

    @Expect(axes.allSeries().size, 0)
    @Expect(axes.effectiveYBounds().high, 42.0)
}

@Test
func pieRejectsInputAnAngleCannotRepresent(): Unit {
    try {
        let _ = PieAxes([])
        @Fail("expected a PlotException for no slices")
    } catch (error: PlotException) {
        @Expect(error.message.contains("at least one slice"))
    }
    try {
        let _ = PieAxes([PieSlice(1.0), PieSlice(-1.0)])
        @Fail("expected a PlotException for a negative slice")
    } catch (error: PlotException) {
        @Expect(error.message.contains("negative"))
    }
    try {
        let _ = PieAxes([PieSlice(0.0), PieSlice(0.0)])
        @Fail("expected a PlotException for slices summing to zero")
    } catch (error: PlotException) {
        @Expect(error.message.contains("sum to zero"))
    }
}

@Test
func pieFractionsSumToOne(): Unit {
    let pie = PieAxes([PieSlice(25.0, label: "a"), PieSlice(50.0, label: "b"), PieSlice(25.0, label: "c")])

    @Expect(pie.sum(), 100.0)
    @Expect(pie.fraction(0), 0.25)
    @Expect(pie.fraction(1), 0.5)
    @Expect(pie.allSlices().size, 3)
}

@Test
func radarNeedsThreeSpokesToEncloseAnArea(): Unit {
    try {
        let _ = RadarAxes(["a", "b"])
        @Fail("expected a PlotException for two spokes")
    } catch (error: PlotException) {
        @Expect(error.message.contains("at least three"))
    }
}

@Test
func radarRejectsATraceThatDoesNotMatchItsSpokes(): Unit {
    let radar = RadarAxes(["a", "b", "c"])
    try {
        let _ = radar.add(RadarTrace([1.0, 2.0]))
        @Fail("expected a PlotException for a short trace")
    } catch (error: PlotException) {
        @Expect(error.message.contains("one value per spoke"))
    }
}

@Test
func radarAutoscalesFromZeroToARoundTick(): Unit {
    let radar = RadarAxes(["a", "b", "c"])
    let _ = radar.add(RadarTrace([0.3, 0.7, 0.42]))

    let range = radar.resolvedRange()
    // Rings read as a scale, so the outer ring must land on a round number at or past the peak.
    @Expect(range.low, 0.0)
    @Expect(range.high >= 0.7)
    @Expect(radar.toggleTrace(0))
    @Expect(!radar.allTraces()[0].visible)
    @Expect(!radar.toggleTrace(5))
}

@Test
func colorBarReservesSpaceForItsLabels(): Unit {
    let canvas = headlessCanvas()
    try {
        let bar = ColorBar(Bounds(0.0, 100.0), Colormap.viridis())
        let plain = bar.extent(canvas, Theme.light())
        bar.label = "value"
        let labelled = bar.extent(canvas, Theme.light())

        @Expect(plain > bar.thickness)
        // A caption needs its own band, or it would overprint the tick labels.
        @Expect(labelled > plain)
    } finally {
        canvas.close()
    }
}

@Test
func axesReservesSpaceForAColorBar(): Unit {
    let canvas = headlessCanvas()
    try {
        let theme = Theme.light()
        let withoutBar = Axes()
        withoutBar.add(LineSeries([0.0, 1.0], [0.0, 1.0]))
        withoutBar.draw(canvas, Rect(0.0, 0.0, 800.0, 600.0), theme)
        let wide = withoutBar.dataArea().w

        let withBar = Axes()
        withBar.add(LineSeries([0.0, 1.0], [0.0, 1.0]))
        let _ = withBar.setColorBar(ColorBar(Bounds(0.0, 1.0), Colormap.viridis()))
        withBar.draw(canvas, Rect(0.0, 0.0, 800.0, 600.0), theme)

        // The bar must narrow the plot, or it would overlap the data.
        @Expect(withBar.dataArea().w < wide)
    } finally {
        canvas.close()
    }
}
