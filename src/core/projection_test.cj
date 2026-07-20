package plot.core

@Test
func projectionMapsDataOntoThePanelRect(): Unit {
    let area = Rect(100.0, 50.0, 400.0, 200.0)
    let projection = Projection(area, LinearScale(Bounds(0.0, 10.0)), LinearScale(Bounds(0.0, 20.0)))

    @Expect(projection.pixelX(0.0), 100.0)
    @Expect(projection.pixelX(10.0), 500.0)
    @Expect(projection.pixelX(5.0), 300.0)
}

@Test
func projectionFlipsTheYAxis(): Unit {
    let area = Rect(0.0, 0.0, 100.0, 200.0)
    let projection = Projection(area, LinearScale(Bounds(0.0, 1.0)), LinearScale(Bounds(0.0, 20.0)))

    // Data grows upward; pixels grow downward. Higher data must land on a smaller y.
    @Expect(projection.pixelY(0.0), 200.0)
    @Expect(projection.pixelY(20.0), 0.0)
    @Expect(projection.pixelY(10.0), 100.0)
}

@Test
func projectionInvertsBackToData(): Unit {
    let area = Rect(30.0, 10.0, 300.0, 150.0)
    let projection = Projection(area, LinearScale(Bounds(-5.0, 5.0)), LinearScale(Bounds(0.0, 100.0)))

    // Pixels are Float32, so a data -> pixel -> data round trip is lossy by design; the tolerance
    // is far below one pixel of the 150 px axis, which is all a hit test or readout needs.
    @Expect(approximately(projection.dataX(projection.pixelX(2.5)), 2.5, 1.0e-3))
    @Expect(approximately(projection.dataY(projection.pixelY(42.0)), 42.0, 1.0e-3))
}

/** Compares floats within `tolerance`; exact `==` on floats is meaningless after a Float32 trip. */
func approximately(actual: Float64, expected: Float64, tolerance: Float64): Bool {
    let delta = actual - expected
    if (delta < 0.0) {
        -delta <= tolerance
    } else {
        delta <= tolerance
    }
}

@Test
func projectionInvertsAtThePanelCorners(): Unit {
    let area = Rect(0.0, 0.0, 200.0, 100.0)
    let projection = Projection(area, LinearScale(Bounds(0.0, 4.0)), LinearScale(Bounds(0.0, 8.0)))

    @Expect(projection.dataX(0.0), 0.0)
    @Expect(projection.dataX(200.0), 4.0)
    @Expect(projection.dataY(100.0), 0.0)
    @Expect(projection.dataY(0.0), 8.0)
}

@Test
func projectionMeasuresDataSpansInPixels(): Unit {
    let area = Rect(0.0, 0.0, 400.0, 200.0)
    let projection = Projection(area, LinearScale(Bounds(0.0, 10.0)), LinearScale(Bounds(0.0, 10.0)))

    // One data unit of a ten-unit domain across 400 px is 40 px — how a bar sizes to its band.
    @Expect(projection.pixelWidth(1.0), 40.0)
    @Expect(projection.pixelHeight(1.0), 20.0)
}

@Test
func projectionRejectsPointsItsScalesCannotExpress(): Unit {
    let area = Rect(0.0, 0.0, 100.0, 100.0)
    let projection = Projection(area, LogScale(Bounds(1.0, 100.0)), LinearScale(Bounds(0.0, 10.0)))

    @Expect(projection.accepts(10.0, 5.0))
    // Zero has no place on a log axis, so the point is unplottable rather than clamped.
    @Expect(!projection.accepts(0.0, 5.0))
    @Expect(!projection.accepts(10.0, Float64.NaN))
}

@Test
func projectionSurvivesAZeroSizedPanel(): Unit {
    let projection = Projection(Rect(0.0, 0.0, 0.0, 0.0), LinearScale(Bounds(0.0, 10.0)), LinearScale(Bounds(0.0, 10.0)))

    // A panel can legitimately measure to zero mid-layout; inverting must not divide by it.
    @Expect(projection.dataX(0.0), 5.0)
    @Expect(projection.dataY(0.0), 5.0)
}
