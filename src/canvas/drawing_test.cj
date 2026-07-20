package plot.canvas

import std.collection.ArrayList
import plot.core.{Color, Colormap, Pen, PlotException, Point, Rect, Renderer}

/*
 * A headless renderer draws nothing and estimates text, which is what lets the canvas' own logic —
 * the fill-colour cache, the geometry helpers, the guards — be exercised without a window.
 */
func headless(): Canvas {
    Canvas(Renderer.headless())
}

@Test
func headlessCanvasFillsWithoutADevice(): Unit {
    let canvas = headless()
    try {
        @Expect(canvas.isHeadless())
        // Regression: a fill builds a texture first, and textureFromSurface throws on a null device
        // rather than no-opping like the renderer's own primitives. Without a guard every fill threw,
        // which made the documented headless path unusable the moment a chart filled anything.
        let triangle = ArrayList<Point>([Point(0.0, 0.0), Point(10.0, 0.0), Point(5.0, 10.0)])
        canvas.fillPolygon(triangle, Color.rgb(1, 2, 3))
        canvas.fillWedge(10.0, 10.0, 2.0, 8.0, 0.0, 1.0, Color.rgb(1, 2, 3))
        canvas.marker(MarkerStyle.Star, 10.0, 10.0, 6.0, Color.rgb(1, 2, 3))
        let upper = ArrayList<Point>([Point(0.0, 0.0), Point(1.0, 0.0)])
        let lower = ArrayList<Point>([Point(0.0, 1.0), Point(1.0, 1.0)])
        canvas.fillBand(upper, lower, Color.rgb(1, 2, 3))
        canvas.fillBandGradient(upper, lower, Colormap.viridis())
        @Expect(true)
    } finally {
        canvas.close()
    }
}

@Test
func canvasClosesIdempotently(): Unit {
    let canvas = headless()

    @Expect(!canvas.isClosed())
    canvas.close()
    @Expect(canvas.isClosed())
    // A double close must be a no-op, not a double free of the cached textures.
    canvas.close()
    @Expect(canvas.isClosed())
}

@Test
func fillBandRejectsMismatchedBoundaries(): Unit {
    let canvas = headless()
    try {
        let upper = ArrayList<Point>([Point(0.0, 0.0), Point(1.0, 0.0)])
        let lower = ArrayList<Point>([Point(0.0, 1.0)])
        canvas.fillBand(upper, lower, Color.rgb(0, 0, 0))
        @Fail("expected a PlotException for boundaries of differing length")
    } catch (error: PlotException) {
        @Expect(error.message.contains("matching boundaries"))
    } finally {
        canvas.close()
    }
}

@Test
func fillBandGradientRejectsMismatchedBoundaries(): Unit {
    let canvas = headless()
    try {
        let upper = ArrayList<Point>([Point(0.0, 0.0), Point(1.0, 0.0)])
        let lower = ArrayList<Point>([Point(0.0, 1.0)])
        canvas.fillBandGradient(upper, lower, Colormap.viridis())
        @Fail("expected a PlotException for boundaries of differing length")
    } catch (error: PlotException) {
        @Expect(error.message.contains("matching boundaries"))
    } finally {
        canvas.close()
    }
}

@Test
func degenerateShapesDrawNothingRatherThanThrowing(): Unit {
    let canvas = headless()
    try {
        // Layout legitimately produces these mid-frame; every one must be a quiet no-op.
        canvas.fillBand(ArrayList<Point>(), ArrayList<Point>(), Color.rgb(0, 0, 0))
        canvas.fillBand(ArrayList<Point>([Point(0.0, 0.0)]), ArrayList<Point>([Point(0.0, 1.0)]), Color.rgb(0, 0, 0))
        canvas.fillPolygon(ArrayList<Point>([Point(0.0, 0.0), Point(1.0, 1.0)]), Color.rgb(0, 0, 0))
        canvas.fillWedge(0.0, 0.0, 0.0, 0.0, 0.0, 1.0, Color.rgb(0, 0, 0))
        canvas.polyline(ArrayList<Point>([Point(0.0, 0.0)]), Pen(width: 1.0, color: Color.rgb(0, 0, 0)))
        canvas.marker(MarkerStyle.Circle, 0.0, 0.0, 0.0, Color.rgb(0, 0, 0))
        canvas.marker(MarkerStyle.NoMarker, 0.0, 0.0, 5.0, Color.rgb(0, 0, 0))
        canvas.text("", 0.0, 0.0, Color.rgb(0, 0, 0))
        canvas.textAnchored("", 0.0, 0.0, Color.rgb(0, 0, 0))
        canvas.textStacked("", 0.0, 0.0, Color.rgb(0, 0, 0))
        @Expect(true)
    } finally {
        canvas.close()
    }
}

@Test
func negativeInnerRadiusClampsToASolidWedge(): Unit {
    let canvas = headless()
    try {
        // A pie slice passes zero and a donut passes a positive radius; a negative one must not
        // invert the geometry.
        canvas.fillWedge(10.0, 10.0, -5.0, 8.0, 0.0, 1.0, Color.rgb(0, 0, 0))
        @Expect(true)
    } finally {
        canvas.close()
    }
}

@Test
func dashedPolylineFallsBackToSolidOnANonPositivePattern(): Unit {
    let canvas = headless()
    try {
        let path = ArrayList<Point>([Point(0.0, 0.0), Point(10.0, 0.0)])
        let pen = Pen(width: 1.0, color: Color.rgb(0, 0, 0))
        // A zero dash would otherwise spin the marching loop forever.
        canvas.dashedPolyline(path, pen, 0.0, 5.0)
        canvas.dashedPolyline(path, pen, 5.0, 0.0)
        @Expect(true)
    } finally {
        canvas.close()
    }
}

@Test
func dashedPolylineToleratesZeroLengthSegments(): Unit {
    let canvas = headless()
    try {
        // Repeated points arise from clamped or constant data; the unit vector must not divide by zero.
        let path = ArrayList<Point>([Point(5.0, 5.0), Point(5.0, 5.0), Point(9.0, 5.0)])
        canvas.dashedPolyline(path, Pen(width: 1.0, color: Color.rgb(0, 0, 0)), 2.0, 2.0)
        @Expect(true)
    } finally {
        canvas.close()
    }
}

@Test
func styledPolylineHonoursTheStyle(): Unit {
    let canvas = headless()
    try {
        let path = ArrayList<Point>([Point(0.0, 0.0), Point(10.0, 10.0)])
        let pen = Pen(width: 1.0, color: Color.rgb(0, 0, 0))
        for (style in [LineStyle.Solid, LineStyle.Dashed, LineStyle.Dotted, LineStyle.DashDot, LineStyle.NoLine]) {
            canvas.styledPolyline(path, pen, style)
        }
        @Expect(true)
    } finally {
        canvas.close()
    }
}

@Test
func everyMarkerStyleDraws(): Unit {
    let canvas = headless()
    try {
        let styles = [
            MarkerStyle.Circle,
            MarkerStyle.Square,
            MarkerStyle.Diamond,
            MarkerStyle.Triangle,
            MarkerStyle.TriangleDown,
            MarkerStyle.Cross,
            MarkerStyle.Plus,
            MarkerStyle.Star,
            MarkerStyle.Ring,
            MarkerStyle.NoMarker
        ]
        for (style in styles) {
            canvas.marker(style, 20.0, 20.0, 5.0, Color.rgb(10, 20, 30))
            canvas.marker(style, 20.0, 20.0, 5.0, Color.rgb(10, 20, 30),
                edge: Some(Pen(width: 1.0, color: Color.rgb(0, 0, 0))))
        }
        @Expect(true)
    } finally {
        canvas.close()
    }
}

@Test
func lineStyleDashPatternsScaleWithWidth(): Unit {
    // Dash runs are multiples of the line width, so a dashed line keeps its rhythm when it thickens.
    match (LineStyle.Dashed.dashPattern(2.0)) {
        case Some((dash, gap)) =>
            @Expect(dash, 7.0)
            @Expect(gap, 5.0)
        case None => @Fail("expected a dash pattern for Dashed")
    }
    @Expect(LineStyle.Solid.dashPattern(2.0).isNone())
    @Expect(LineStyle.NoLine.dashPattern(2.0).isNone())
    @Expect(LineStyle.NoLine.isHidden())
    @Expect(!LineStyle.Solid.isHidden())
}

@Test
func markerStyleClassification(): Unit {
    @Expect(MarkerStyle.NoMarker.isHidden())
    @Expect(!MarkerStyle.Circle.isHidden())
    // Stroked glyphs have no interior, so callers must not try to ring them.
    @Expect(MarkerStyle.Cross.isStroked())
    @Expect(MarkerStyle.Plus.isStroked())
    @Expect(MarkerStyle.Ring.isStroked())
    @Expect(!MarkerStyle.Circle.isStroked())
    @Expect(!MarkerStyle.Square.isStroked())
}

@Test
func lineStyleEqualityIsByCase(): Unit {
    @Expect(LineStyle.Dashed == LineStyle.Dashed)
    @Expect(LineStyle.Dashed != LineStyle.Dotted)
    @Expect(MarkerStyle.Circle == MarkerStyle.Circle)
    @Expect(MarkerStyle.Circle != MarkerStyle.Square)
}

@Test
func textMeasurementGrowsWithContentAndSize(): Unit {
    let canvas = headless()
    try {
        @Expect(canvas.textWidth("mm", size: 12.0) > canvas.textWidth("m", size: 12.0))
        @Expect(canvas.textWidth("m", size: 24.0) > canvas.textWidth("m", size: 12.0))
        @Expect(canvas.textHeight(size: 24.0) > canvas.textHeight(size: 12.0))
        // A stacked label is one line per rune, which is how the y-axis title reserves its width.
        @Expect(canvas.stackedTextHeight("abc", size: 12.0) > canvas.textHeight(size: 12.0))
        @Expect(canvas.stackedTextHeight("", size: 12.0), 0.0)
    } finally {
        canvas.close()
    }
}

@Test
func stackedTextCountsRunesNotBytes(): Unit {
    let canvas = headless()
    try {
        // A byte walk would split every multi-byte character and overcount the height.
        let latin = canvas.stackedTextHeight("abc", size: 12.0)
        let cjk = canvas.stackedTextHeight("中文字", size: 12.0)
        @Expect(latin, cjk)
    } finally {
        canvas.close()
    }
}

@Test
func clipPushAndPopAreBalancedThroughTheCanvas(): Unit {
    let canvas = headless()
    try {
        canvas.pushClip(Rect(0.0, 0.0, 100.0, 100.0))
        canvas.pushClip(Rect(10.0, 10.0, 50.0, 50.0))
        canvas.popClip()
        canvas.popClip()
        // An unbalanced pop must not underflow the stack.
        canvas.popClip()
        @Expect(true)
    } finally {
        canvas.close()
    }
}

@Test
func fillsReuseOneTexturePerColour(): Unit {
    let canvas = headless()
    try {
        let triangle = ArrayList<Point>([Point(0.0, 0.0), Point(10.0, 0.0), Point(5.0, 10.0)])
        // Many fills in few colours is the real shape of a figure; the cache must not grow per call.
        for (_ in 0..200) {
            canvas.fillPolygon(triangle, Color.rgb(1, 2, 3))
            canvas.fillPolygon(triangle, Color.rgb(4, 5, 6))
        }
        @Expect(true)
    } finally {
        canvas.close()
    }
}
