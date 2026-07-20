package plot.core

@Test
func hexParsesAllThreeShapes(): Unit {
    let short = Colors.hex("#f80")
    @Expect(short.r, UInt8(255))
    @Expect(short.g, UInt8(136))
    @Expect(short.b, UInt8(0))
    @Expect(short.a, UInt8(255))

    let full = Colors.hex("#3B82F6")
    @Expect(full.r, UInt8(59))
    @Expect(full.g, UInt8(130))
    @Expect(full.b, UInt8(246))

    let withAlpha = Colors.hex("#3B82F680")
    @Expect(withAlpha.a, UInt8(128))
}

@Test
func hexAcceptsNoLeadingHashAndAnyCase(): Unit {
    @Expect(Colors.hex("ff0000").r, UInt8(255))
    @Expect(Colors.hex("#AbCdEf").g, Colors.hex("#abcdef").g)
}

@Test
func hexRejectsMalformedLiterals(): Unit {
    try {
        let _ = Colors.hex("#12345")
        @Fail("expected a PlotException for a five-digit hex colour")
    } catch (error: PlotException) {
        @Expect(error.message.contains("Invalid hex"))
    }
    try {
        let _ = Colors.hex("#gg0000")
        @Fail("expected a PlotException for a non-hex digit")
    } catch (error: PlotException) {
        @Expect(error.message.contains("Invalid hex"))
    }
}

@Test
func hslProducesTheExpectedPrimaries(): Unit {
    let red = Colors.hsl(0.0, 1.0, 0.5)
    @Expect(red.r, UInt8(255))
    @Expect(red.g, UInt8(0))
    @Expect(red.b, UInt8(0))

    let green = Colors.hsl(120.0, 1.0, 0.5)
    @Expect(green.g, UInt8(255))
    @Expect(green.r, UInt8(0))

    let blue = Colors.hsl(240.0, 1.0, 0.5)
    @Expect(blue.b, UInt8(255))
}

@Test
func hslWrapsHueAndClampsTheRest(): Unit {
    // A negative hue must wrap forward, not fold back to zero.
    @Expect(Colors.hsl(-120.0, 1.0, 0.5).b, Colors.hsl(240.0, 1.0, 0.5).b)
    @Expect(Colors.hsl(480.0, 1.0, 0.5).g, Colors.hsl(120.0, 1.0, 0.5).g)

    let white = Colors.hsl(200.0, 1.0, 2.0)
    @Expect(white.r, UInt8(255))
    @Expect(white.b, UInt8(255))
}

@Test
func floorModWrapsForwardForNegatives(): Unit {
    @Expect(floorMod(370.0, 360.0), 10.0)
    @Expect(floorMod(-10.0, 360.0), 350.0)
    @Expect(floorMod(0.0, 360.0), 0.0)
    // A non-positive modulus has no meaningful answer; zero beats dividing by it.
    @Expect(floorMod(5.0, 0.0), 0.0)
}

@Test
func fadeSetsOpacityFromAUnitFraction(): Unit {
    let base = Colors.hex("#3B82F6")

    @Expect(Colors.fade(base, 1.0).a, UInt8(255))
    @Expect(Colors.fade(base, 0.0).a, UInt8(0))
    @Expect(Colors.fade(base, 0.5).a, UInt8(128))
    // The colour itself must survive the alpha change.
    @Expect(Colors.fade(base, 0.5).r, base.r)
}

@Test
func lightenAndDarkenMoveTowardTheExtremes(): Unit {
    let base = Colors.hex("#808080")

    @Expect(Colors.lighten(base, 1.0).r, UInt8(255))
    @Expect(Colors.darken(base, 1.0).r, UInt8(0))
    @Expect(Colors.lighten(base, 0.5).r > base.r)
    @Expect(Colors.darken(base, 0.5).r < base.r)
}

@Test
func luminanceOrdersBlackBelowWhite(): Unit {
    let black = Colors.luminance(Colors.hex("#000000"))
    let white = Colors.luminance(Colors.hex("#FFFFFF"))

    @Expect(black < 0.01)
    @Expect(white > 0.99)
    // Green carries most of the perceived brightness, per the WCAG weights.
    @Expect(Colors.luminance(Colors.hex("#00FF00")) > Colors.luminance(Colors.hex("#0000FF")))
}

@Test
func contrastTextFlipsWithTheBackground(): Unit {
    let onLight = Colors.contrastText(Colors.hex("#FFFFFF"))
    let onDark = Colors.contrastText(Colors.hex("#111827"))

    @Expect(onLight.r < UInt8(60))
    @Expect(onDark.r, UInt8(255))
}

@Test
func paletteWrapsRatherThanRunningOut(): Unit {
    let palette = Palette.modern()
    let size = palette.size()

    @Expect(palette.at(0).r, palette.at(size).r)
    // A negative index must still land in range, not throw.
    @Expect(palette.at(-1).r, palette.at(size - 1).r)
}

@Test
func paletteRejectsAnEmptyColourList(): Unit {
    try {
        let _ = Palette([])
        @Fail("expected a PlotException for an empty palette")
    } catch (error: PlotException) {
        @Expect(error.message.contains("at least one"))
    }
}

@Test
func colormapSamplesItsEndsAndClamps(): Unit {
    let map = Colormap.viridis()
    let low = map.sample(0.0)
    let high = map.sample(1.0)

    @Expect(map.sample(-1.0).r, low.r)
    @Expect(map.sample(2.0).r, high.r)
    // Viridis runs dark purple to bright yellow.
    @Expect(high.g > low.g)
}

@Test
func colormapSampleInMapsThroughADomain(): Unit {
    let map = Colormap.viridis()
    let domain = Bounds(100.0, 200.0)

    @Expect(map.sampleIn(100.0, domain).r, map.sample(0.0).r)
    @Expect(map.sampleIn(200.0, domain).r, map.sample(1.0).r)
    // A collapsed domain has no gradient to place a value on; the midpoint is the honest answer.
    @Expect(map.sampleIn(5.0, Bounds(3.0, 3.0)).r, map.sample(0.5).r)
}

@Test
func colormapReversedSwapsTheEnds(): Unit {
    let map = Colormap.viridis()
    let flipped = map.reversed()

    @Expect(flipped.sample(0.0).r, map.sample(1.0).r)
    @Expect(flipped.sample(1.0).r, map.sample(0.0).r)
}

@Test
func colormapRampReturnsEvenlySpacedStops(): Unit {
    let ramp = Colormap.viridis().ramp(5)

    @Expect(ramp.size, 5)
    @Expect(ramp[0].r, Colormap.viridis().sample(0.0).r)
    @Expect(ramp[4].r, Colormap.viridis().sample(1.0).r)
}

@Test
func colormapRejectsFewerThanTwoStops(): Unit {
    try {
        let _ = Colormap([Colors.hex("#000000")])
        @Fail("expected a PlotException for a single-stop colormap")
    } catch (error: PlotException) {
        @Expect(error.message.contains("at least two"))
    }
}

@Test
func themeCopyIsIndependentOfItsSource(): Unit {
    let base = Theme.light()
    let derived = base.copy()
    derived.lineWidth = 9.0
    derived.isDark = true

    // A derived theme must never mutate the preset it came from.
    @Expect(base.lineWidth, 2.0)
    @Expect(base.isDark, false)
    @Expect(derived.lineWidth, 9.0)
}

@Test
func darkThemeContrastsAgainstItsPanel(): Unit {
    let dark = Theme.dark()

    @Expect(dark.isDark)
    @Expect(Colors.luminance(dark.panel) < 0.2)
    @Expect(Colors.luminance(dark.text) > 0.7)
}

/**
 * NaN fails both of a clamp's comparisons, so it slips through any `< 0 / > 1` pair untouched and
 * reaches the Int64 casts in `sample` and `fade`, which trap on it. A heatmap carrying missing data
 * — which it is meant to carry, and which `draw` skips — must not be able to bring a frame down by
 * being sampled.
 */
@Test
func colormapSampleTreatsNaNAsTheLowEnd(): Unit {
    let ramp = Colormap.viridis()
    let atNaN = ramp.sample(Float64.NaN)
    let atZero = ramp.sample(0.0)

    @Expect(atNaN.r, atZero.r)
    @Expect(atNaN.g, atZero.g)
    @Expect(atNaN.b, atZero.b)
}

@Test
func colormapSampleInToleratesANonFiniteValue(): Unit {
    let ramp = Colormap.viridis()
    let domain = Bounds(0.0, 100.0)

    // None of these may throw; each is a value a real field can hold.
    let _ = ramp.sampleIn(Float64.NaN, domain)
    let _ = ramp.sampleIn(Float64.Inf, domain)
    let _ = ramp.sampleIn(-Float64.Inf, domain)
    @Expect(true)
}

@Test
func fadeAndMixToleratesANonFiniteAmount(): Unit {
    let base = Colors.hex("#3B82F6")

    // `fade` runs `Int64(clamp * 255 + 0.5)`, so an unclamped NaN would trap on the cast.
    @Expect(Colors.fade(base, Float64.NaN).a, 0)
    @Expect(Colors.fade(base, 2.0).a, 255)
    @Expect(Colors.fade(base, -1.0).a, 0)
    let _ = Colors.mix(base, Colors.hex("#FFFFFF"), Float64.NaN)
    let _ = Colors.hsl(Float64.NaN, Float64.NaN, Float64.NaN)
    @Expect(true)
}
