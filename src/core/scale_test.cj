package plot.core

import std.math.{abs, log10}

@Test
func linearScaleNormalizesProportionally(): Unit {
    let scale = LinearScale(Bounds(0.0, 100.0))

    @Expect(scale.normalize(0.0), 0.0)
    @Expect(scale.normalize(50.0), 0.5)
    @Expect(scale.normalize(100.0), 1.0)
    // Values outside the domain map outside 0..1 rather than clamping; the panel clip handles it.
    @Expect(scale.normalize(150.0), 1.5)
}

@Test
func linearScaleRoundTripsThroughDenormalize(): Unit {
    let scale = LinearScale(Bounds(-20.0, 60.0))

    @Expect(scale.denormalize(scale.normalize(13.5)), 13.5)
    @Expect(scale.denormalize(0.0), -20.0)
    @Expect(scale.denormalize(1.0), 60.0)
}

@Test
func linearScaleHandlesADegenerateDomain(): Unit {
    let scale = LinearScale(Bounds(5.0, 5.0))

    // No division by zero: a collapsed domain reports the midpoint.
    @Expect(scale.normalize(5.0), 0.5)
    @Expect(scale.normalize(9.0), 0.5)
}

@Test
func linearScaleAcceptsAnyFiniteValue(): Unit {
    let scale = LinearScale(Bounds(-10.0, 10.0))

    @Expect(scale.accepts(0.0))
    @Expect(scale.accepts(-500.0))
    @Expect(!scale.accepts(Float64.NaN))
    @Expect(!scale.accepts(Float64.Inf))
}

/**
 * Wheel zoom's whole contract: the data under the cursor stays under the cursor. On a log axis that
 * only holds if the zoom happens in log space — scaling the raw interval instead drags the anchor
 * across the panel and can hand back a low of zero or less, which the scale then rejects outright.
 */
@Test
func logScaleZoomKeepsTheAnchorUnderTheCursor(): Unit {
    let view = Bounds(1.0, 1.0e6)
    let scale = LogScale(view)
    // The cursor sits mid-panel, which on a six-decade axis is data x = 1000.
    let anchor = scale.denormalize(0.5)
    @Expect(abs(anchor - 1000.0) < 1.0e-6)

    for (factor in [1.15, 1.0 / 1.15, 1.15 * 1.15, 0.5]) {
        let zoomed = scale.zoomAround(view, anchor, factor)
        // A log scale cannot express a domain reaching zero; the zoom must never produce one.
        @Expect(zoomed.low > 0.0)
        @Expect(abs(LogScale(zoomed).normalize(anchor) - 0.5) < 1.0e-9)
    }

    // ...and off-centre too, where an additive zoom drifts worst.
    let corner = scale.denormalize(0.9)
    let zoomed = scale.zoomAround(view, corner, 1.15)
    @Expect(zoomed.low > 0.0)
    @Expect(abs(LogScale(zoomed).normalize(corner) - 0.9) < 1.0e-9)
}

/** Panning a log axis moves it by whole decades, and can never walk the range down through zero. */
@Test
func logScalePanMovesInDecadesAndStaysPositive(): Unit {
    let view = Bounds(1.0, 1.0e6)
    let scale = LogScale(view)

    // Dragging 10% of the panel width shifts the view by 10% of its six decades.
    let panned = scale.panByFraction(view, -0.1)
    @Expect(panned.low > 0.0)
    @Expect(abs(log10(panned.low) - -0.6) < 1.0e-9)
    @Expect(abs(log10(panned.high) - 5.4) < 1.0e-9)

    // Dragging clean off the panel still cannot walk the range down to zero, which the additive
    // shift did after a tenth of one panel width. (The exponent underflows pow() to zero eventually,
    // but only past ~50 panel widths of drag, which no pointer can deliver in one gesture.)
    for (fraction in [-1.0, -3.0, -8.0, 1.0, 8.0]) {
        let far = scale.panByFraction(view, fraction)
        @Expect(far.low > 0.0)
        // The view keeps its width in decades however far it is pushed.
        @Expect(abs((log10(far.high) - log10(far.low)) - 6.0) < 1.0e-9)
    }
}

/** The linear path must be exactly the raw-interval maths it was before the scale took it over. */
@Test
func linearScaleZoomAndPanAreTheRawIntervalMaths(): Unit {
    let scale = LinearScale(Bounds(0.0, 100.0))
    let view = Bounds(0.0, 100.0)

    let zoomed = scale.zoomAround(view, 25.0, 0.5)
    @Expect(zoomed.low, view.scaledAround(25.0, 0.5).low)
    @Expect(zoomed.high, view.scaledAround(25.0, 0.5).high)
    // The anchor holds here too, which is what made the raw maths right for this scale all along.
    @Expect(abs(LinearScale(zoomed).normalize(25.0) - scale.normalize(25.0)) < 1.0e-12)

    let panned = scale.panByFraction(view, -0.1)
    @Expect(panned.low, -10.0)
    @Expect(panned.high, 90.0)
}

/** A category axis is linear in data space, so it inherits the raw maths unchanged. */
@Test
func categoryScaleZoomFollowsTheLinearPath(): Unit {
    let scale = CategoryScale(["a", "b", "c"])
    let view = scale.domain()

    let zoomed = scale.zoomAround(view, 1.0, 0.5)
    @Expect(zoomed.low, view.scaledAround(1.0, 0.5).low)
    @Expect(zoomed.high, view.scaledAround(1.0, 0.5).high)
}

@Test
func linearScaleMinorTicksAppearOnlyWhenAsked(): Unit {
    let scale = LinearScale(Bounds(0.0, 10.0))
    let withoutMinor = scale.ticks().size

    scale.setMinorDivisions(5)
    let withMinor = scale.ticks().size

    @Expect(withMinor > withoutMinor)
}

@Test
func logScaleNormalizesByDecade(): Unit {
    let scale = LogScale(Bounds(1.0, 1000.0))

    @Expect(scale.normalize(1.0), 0.0)
    @Expect(scale.normalize(1000.0), 1.0)
    // 10 sits one decade of three along, not a tenth of the way.
    let atTen = scale.normalize(10.0)
    @Expect(atTen > 0.32 && atTen < 0.34)
}

@Test
func logScaleRoundTripsThroughDenormalize(): Unit {
    let scale = LogScale(Bounds(1.0, 10000.0))
    let value = scale.denormalize(scale.normalize(250.0))

    @Expect(value > 249.99 && value < 250.01)
}

@Test
func logScaleRejectsNonPositiveValuesAndDomains(): Unit {
    let scale = LogScale(Bounds(1.0, 100.0))

    @Expect(!scale.accepts(0.0))
    @Expect(!scale.accepts(-1.0))
    @Expect(scale.accepts(0.5))

    try {
        scale.setDomain(Bounds(-1.0, 10.0))
        @Fail("expected a PlotException for a non-positive log domain")
    } catch (error: PlotException) {
        @Expect(error.message.contains("positive"))
    }
}

@Test
func logScaleNiceDomainSnapsToWholeDecades(): Unit {
    let scale = LogScale(Bounds(3.0, 4000.0))
    let nice = scale.niceDomain()

    @Expect(nice.low, 1.0)
    @Expect(nice.high, 10000.0)
}

@Test
func categoryScalePlacesEachCategoryInAUnitBand(): Unit {
    let scale = CategoryScale(["a", "b", "c"])

    @Expect(scale.count(), 3)
    @Expect(scale.domain().low, -0.5)
    @Expect(scale.domain().high, 2.5)
    // Category 1 sits at data coordinate 1, centred in the middle of a three-wide axis.
    @Expect(scale.normalize(1.0), 0.5)
}

@Test
func categoryScaleTicksNameEachCategory(): Unit {
    let ticks = CategoryScale(["alpha", "beta"]).ticks()

    @Expect(ticks.size, 2)
    @Expect(ticks[0].value, 0.0)
    @Expect(ticks[0].label, "alpha")
    @Expect(ticks[1].value, 1.0)
    @Expect(ticks[1].label, "beta")
}

@Test
func linearScalePadsAdditively(): Unit {
    let padded = LinearScale().padBounds(Bounds(0.0, 10.0), 0.05)

    @Expect(padded.low, -0.5)
    @Expect(padded.high, 10.5)
}

@Test
func logScalePadsMultiplicativelyAndStaysPositive(): Unit {
    // The regression this exists for: additive padding of [1, 1e6] by 5% gives a low edge of
    // -49999, which no log axis can express — it crashed the whole figure.
    let padded = LogScale().padBounds(Bounds(1.0, 1.0e6), 0.05)

    @Expect(padded.low > 0.0)
    @Expect(padded.low < 1.0)
    @Expect(padded.high > 1.0e6)
    // 5% of six decades is 0.3 decades either side.
    @Expect(padded.low > 0.4 && padded.low < 0.6)
}

@Test
func logScalePadIsAcceptedBySetDomain(): Unit {
    // The end-to-end shape of the bug: whatever padBounds returns must be a legal log domain.
    let scale = LogScale()
    scale.setDomain(scale.padBounds(Bounds(1.0, 1.0e6), 0.05))

    @Expect(scale.domain().low > 0.0)
}

@Test
func logScaleFloorsARangeReachingZero(): Unit {
    // A series' dataBounds reports raw data and cannot know it will land on a log axis, so a
    // range reaching zero can still arrive here. Six decades below the peak is the floor.
    let padded = LogScale().padBounds(Bounds(0.0, 1000.0), 0.05)

    @Expect(padded.low > 0.0)
    @Expect(padded.high > 1000.0)
}

@Test
func logScaleRejectsAnEntirelyNonPositiveRange(): Unit {
    try {
        let _ = LogScale().padBounds(Bounds(-100.0, -1.0), 0.05)
        @Fail("expected a PlotException when no value could be placed")
    } catch (error: PlotException) {
        @Expect(error.message.contains("positive data"))
    }
}

@Test
func categoryScalePadsToItsCategoriesNotItsData(): Unit {
    let scale = CategoryScale(["a", "b", "c", "d"])
    // A category axis's extent is its categories: a series covering only 0..1 must not shrink it,
    // and a complete one must not gain dead space at the ends.
    let fromPartialData = scale.padBounds(Bounds(0.0, 1.0), 0.05)

    @Expect(fromPartialData.low, -0.5)
    @Expect(fromPartialData.high, 3.5)
    @Expect(scale.niceBounds(Bounds(0.0, 1.0)).high, 3.5)
}

@Test
func categoryScaleRejectsAnEmptyCategoryList(): Unit {
    try {
        let _ = CategoryScale([])
        @Fail("expected a PlotException for an empty category scale")
    } catch (error: PlotException) {
        @Expect(error.message.contains("at least one"))
    }
}
