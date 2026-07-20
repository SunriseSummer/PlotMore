package plot.core

@Test
func boundsOfOrdersItsArguments(): Unit {
    let ascending = Bounds.of(1.0, 5.0)
    let descending = Bounds.of(5.0, 1.0)

    @Expect(ascending.low, 1.0)
    @Expect(ascending.high, 5.0)
    @Expect(descending.low, 1.0)
    @Expect(descending.high, 5.0)
}

@Test
func boundsCoverSkipsNonFiniteValues(): Unit {
    let covered = Bounds.cover([3.0, Float64.NaN, -2.0, Float64.Inf, 7.0])

    match (covered) {
        case Some(bounds) =>
            @Expect(bounds.low, -2.0)
            @Expect(bounds.high, 7.0)
        case None => @Fail("expected bounds covering the finite values")
    }
}

@Test
func boundsCoverReturnsNoneWithoutFiniteValues(): Unit {
    @Expect(Bounds.cover([Float64.NaN, Float64.Inf]).isNone())
    @Expect(Bounds.cover([]).isNone())
}

@Test
func boundsSpanAndCenterDescribeTheInterval(): Unit {
    let bounds = Bounds(-4.0, 6.0)

    @Expect(bounds.span(), 10.0)
    @Expect(bounds.center(), 1.0)
    @Expect(bounds.contains(-4.0))
    @Expect(bounds.contains(6.0))
    @Expect(!bounds.contains(6.5))
}

@Test
func boundsUnionCoversBothIntervals(): Unit {
    let union = Bounds(0.0, 2.0).union(Bounds(-3.0, 1.0))

    @Expect(union.low, -3.0)
    @Expect(union.high, 2.0)
}

@Test
func boundsExpandedGrowsByAFractionOfTheSpan(): Unit {
    let expanded = Bounds(0.0, 10.0).expanded(0.1)

    @Expect(expanded.low, -1.0)
    @Expect(expanded.high, 11.0)
}

@Test
func nonDegenerateOpensUpASinglePoint(): Unit {
    let fromValue = Bounds(4.0, 4.0).nonDegenerate()

    @Expect(fromValue.isDegenerate(), false)
    @Expect(fromValue.low, 2.0)
    @Expect(fromValue.high, 6.0)
}

@Test
func nonDegenerateWidensZeroToUnitRange(): Unit {
    // A relative pad of a zero-magnitude value is still zero, so this case needs its own rule.
    let fromZero = Bounds(0.0, 0.0).nonDegenerate()

    @Expect(fromZero.low, -1.0)
    @Expect(fromZero.high, 1.0)
}

@Test
func nonDegenerateLeavesRealIntervalsAlone(): Unit {
    let bounds = Bounds(1.0, 3.0)
    let result = bounds.nonDegenerate()

    @Expect(result.low, 1.0)
    @Expect(result.high, 3.0)
}

@Test
func scaledAroundKeepsThePivotFixed(): Unit {
    let zoomed = Bounds(0.0, 10.0).scaledAround(5.0, 0.5)

    @Expect(zoomed.low, 2.5)
    @Expect(zoomed.high, 7.5)
    // The pivot must stay put — this is what anchors a wheel zoom under the cursor.
    @Expect(zoomed.center(), 5.0)
}

@Test
func scaledAroundOffCentrePivotHoldsThatPoint(): Unit {
    let zoomed = Bounds(0.0, 10.0).scaledAround(2.0, 0.5)

    @Expect(zoomed.low, 1.0)
    @Expect(zoomed.high, 6.0)
}

@Test
func shiftedMovesBothEdges(): Unit {
    let shifted = Bounds(0.0, 10.0).shifted(-3.0)

    @Expect(shifted.low, -3.0)
    @Expect(shifted.high, 7.0)
}

@Test
func isFiniteRejectsNaNAndInfinities(): Unit {
    @Expect(isFinite(1.5))
    @Expect(isFinite(0.0))
    @Expect(!isFinite(Float64.NaN))
    @Expect(!isFinite(Float64.Inf))
    @Expect(!isFinite(-Float64.Inf))
}
