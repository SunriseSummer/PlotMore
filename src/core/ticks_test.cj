package plot.core

import std.math.{abs, floor}

@Test
func niceStepRoundsToOneTwoOrFive(): Unit {
    // Every step must be 1, 2 or 5 times a power of ten; that is what keeps labels divisible.
    @Expect(Ticks.niceStep(1.0), 1.0)
    @Expect(Ticks.niceStep(1.4), 2.0)
    @Expect(Ticks.niceStep(2.0), 2.0)
    @Expect(Ticks.niceStep(3.0), 5.0)
    @Expect(Ticks.niceStep(5.0), 5.0)
    @Expect(Ticks.niceStep(7.0), 10.0)
    @Expect(Ticks.niceStep(0.03), 0.05)
    @Expect(Ticks.niceStep(230.0), 500.0)
}

@Test
func niceStepGuardsAgainstNonPositiveInput(): Unit {
    @Expect(Ticks.niceStep(0.0), 1.0)
    @Expect(Ticks.niceStep(-5.0), 1.0)
    @Expect(Ticks.niceStep(Float64.NaN), 1.0)
}

@Test
func linearTicksLandOnRoundNumbers(): Unit {
    let ticks = Ticks.linear(Bounds(0.0, 10.0), target: 5)

    @Expect(ticks.size, 6)
    @Expect(ticks[0].value, 0.0)
    @Expect(ticks[1].value, 2.0)
    @Expect(ticks[5].value, 10.0)
    @Expect(ticks[0].label, "0")
    @Expect(ticks[5].label, "10")
}

@Test
func linearTicksStayInsideTheBounds(): Unit {
    // A padded axis ticks on round numbers *within* it, not out to its ragged edges.
    for (tick in Ticks.linear(Bounds(-0.5, 10.5), target: 6)) {
        @Expect(tick.value >= -0.5)
        @Expect(tick.value <= 10.5)
    }
}

@Test
func linearTicksSnapTheZeroCrossing(): Unit {
    // 3 * 0.1 is 0.30000000000000004 in binary floating point; an axis must not label that.
    var sawZero = false
    for (tick in Ticks.linear(Bounds(-0.5, 0.5), target: 5)) {
        if (tick.label == "0") {
            sawZero = true
            @Expect(tick.value, 0.0)
        }
        // No label may leak a float artifact.
        @Expect(tick.label.size <= 5)
    }
    @Expect(sawZero)
}

@Test
func linearTicksHandleADegenerateRange(): Unit {
    let ticks = Ticks.linear(Bounds(5.0, 5.0), target: 5)

    // A zero span has no meaningful subdivision; producing nothing beats producing infinity.
    @Expect(ticks.size <= 1)
}

@Test
func linearMinorTicksSkipTheMajorPositions(): Unit {
    let minor = Ticks.linearMinor(Bounds(0.0, 10.0), target: 5, divisions: 2)

    @Expect(minor.size > 0)
    for (tick in minor) {
        @Expect(tick.major, false)
        @Expect(tick.label, "")
    }
}

@Test
func linearMinorTicksAreEmptyBelowTwoDivisions(): Unit {
    @Expect(Ticks.linearMinor(Bounds(0.0, 10.0), divisions: 1).size, 0)
    @Expect(Ticks.linearMinor(Bounds(0.0, 10.0), divisions: 0).size, 0)
}

/**
 * The skip has to key off each value's own multiple of the minor step, not off its position in the
 * list: an axis whose first minor tick is not itself a major — any axis not starting on a round
 * number — otherwise drops a real minor tick and draws a minor gridline over every major one.
 */
@Test
func linearMinorTicksNeverLandOnAMajorPosition(): Unit {
    // [0.05, 1] steps by 0.2, and the first minor inside it is 0.08 — four minors past a major.
    let bounds = Bounds(0.05, 1.0)
    let step = Ticks.linearStep(bounds, 6)
    @Expect(step, 0.2)

    let minor = Ticks.linearMinor(bounds, target: 6, divisions: 5)
    @Expect(minor.size > 0)
    for (tick in minor) {
        // Distance to the nearest major position, which no minor may sit on.
        let multiples = tick.value / step
        let nearest = floor(multiples + 0.5)
        @Expect(abs(multiples - nearest) > 1.0e-6)
    }

    // ...and the minors that belong there are all present: 0.08 is one, and it used to be the very
    // tick the index comparison threw away.
    var sawFirstMinor = false
    for (tick in minor) {
        if (abs(tick.value - 0.08) < 1.0e-9) {
            sawFirstMinor = true
        }
    }
    @Expect(sawFirstMinor)
    // The 0.04 multiples inside [0.05, 1.0] run 2..25, and five of those (5, 10, 15, 20, 25) are
    // majors. The count alone does not catch the bug — skipping the wrong five leaves 19 too — so
    // it is the positions above that carry this test; this only pins the arithmetic down.
    @Expect(minor.size, 19)
}

/** An axis starting on a round number is the case the index comparison happened to get right. */
@Test
func linearMinorTicksStillSubdivideAnAxisStartingOnAMajor(): Unit {
    let minor = Ticks.linearMinor(Bounds(0.0, 10.0), target: 5, divisions: 2)

    // Step is 2, so the minors are the odd multiples of 1: 1, 3, 5, 7, 9.
    @Expect(minor.size, 5)
    @Expect(minor[0].value, 1.0)
    @Expect(minor[4].value, 9.0)
}

/**
 * Padding a range that already spans most of Float64 overflows its span to infinity, and the tick
 * walk has to hand that back as "no ticks" rather than trapping in the Int64 cast on the way.
 */
@Test
func linearTicksSurviveBoundsThatPaddingPushedToInfinity(): Unit {
    // Exactly what autoscale hands over for data at both ends of the range: the span is infinite.
    let padded = LinearScale().padBounds(Bounds(-1.0e308, 1.0e308), 0.05)
    @Expect(padded.low.isInf())

    @Expect(Ticks.linear(padded, target: 6).size, 0)
    @Expect(Ticks.linear(Bounds(0.0, Float64.Inf), target: 6).size, 0)
    @Expect(Ticks.linearMinor(padded, target: 6, divisions: 5).size, 0)
}

/** A log axis cannot place an infinite bound; it owes the caller the exception it documents. */
@Test
func log10ScaleRejectsNonFiniteBounds(): Unit {
    try {
        let _ = Ticks.log10Scale(Bounds(1.0, Float64.Inf))
        @Fail("expected a PlotException for an infinite high bound")
    } catch (error: PlotException) {
        @Expect(error.message.contains("finite"))
    }
}

@Test
func niceRoundsBoundsOutwardToWholeSteps(): Unit {
    let rounded = Ticks.nice(Bounds(3.7, 91.2), target: 5)

    // Step lands on 20, so the range opens out to the enclosing multiples.
    @Expect(rounded.low, 0.0)
    @Expect(rounded.high, 100.0)
}

@Test
func niceLeavesAlreadyRoundBoundsAlone(): Unit {
    let rounded = Ticks.nice(Bounds(0.0, 10.0), target: 5)

    @Expect(rounded.low, 0.0)
    @Expect(rounded.high, 10.0)
}

@Test
func log10ScaleTicksMarkTheDecades(): Unit {
    let ticks = Ticks.log10Scale(Bounds(1.0, 1000.0), minorTicks: false)

    @Expect(ticks.size, 4)
    @Expect(ticks[0].value, 1.0)
    @Expect(ticks[0].label, "1")
    @Expect(ticks[1].label, "10")
    @Expect(ticks[2].label, "10^2")
    @Expect(ticks[3].value, 1000.0)
}

@Test
func log10ScaleAddsMinorTicksOverANarrowRange(): Unit {
    let ticks = Ticks.log10Scale(Bounds(1.0, 10.0), minorTicks: true)

    var minors = 0
    for (tick in ticks) {
        if (!tick.major) {
            minors += 1
        }
    }
    // 2..9 subdivide the single decade.
    @Expect(minors, 8)
}

@Test
func log10ScaleRejectsNonPositiveBounds(): Unit {
    // A log axis cannot place zero at any finite position; failing loudly beats drawing a lie.
    try {
        let _ = Ticks.log10Scale(Bounds(0.0, 10.0))
        @Fail("expected a PlotException for a domain reaching zero")
    } catch (error: PlotException) {
        @Expect(error.message.contains("positive"))
    }
}
