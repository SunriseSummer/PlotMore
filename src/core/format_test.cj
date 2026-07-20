package plot.core

@Test
func decimalsForFollowsTheTickStep(): Unit {
    @Expect(NumberFormat.decimalsFor(1.0), 0)
    @Expect(NumberFormat.decimalsFor(2.0), 0)
    @Expect(NumberFormat.decimalsFor(10.0), 0)
    @Expect(NumberFormat.decimalsFor(0.5), 1)
    @Expect(NumberFormat.decimalsFor(0.2), 1)
    // log10(0.1) lands a hair below -1 in binary floating point; without the epsilon this asks
    // for two decimals on every 0.1-stepped axis.
    @Expect(NumberFormat.decimalsFor(0.1), 1)
    @Expect(NumberFormat.decimalsFor(0.05), 2)
    @Expect(NumberFormat.decimalsFor(0.01), 2)
}

@Test
func tickLabelsTrimTrailingZeros(): Unit {
    @Expect(NumberFormat.tick(1.0, 1.0), "1")
    @Expect(NumberFormat.tick(1.5, 0.5), "1.5")
    @Expect(NumberFormat.tick(2.0, 0.5), "2")
    @Expect(NumberFormat.tick(0.25, 0.05), "0.25")
}

@Test
func tickLabelsNeverPrintNegativeZero(): Unit {
    // An axis crossing zero computes a -0.0 on the way; "-0" is a visible bug.
    @Expect(NumberFormat.tick(-0.0, 0.5), "0")
    @Expect(NumberFormat.tick(0.0, 0.5), "0")
}

@Test
func tickLabelsSwitchToScientificAtTheExtremes(): Unit {
    @Expect(NumberFormat.tick(2500000.0, 500000.0).contains("e"))
    @Expect(NumberFormat.tick(0.00001, 0.00001).contains("e"))
    // Inside the readable band it stays plain.
    @Expect(!NumberFormat.tick(1500.0, 500.0).contains("e"))
}

@Test
func compactTrimsAndBoundsPrecision(): Unit {
    @Expect(NumberFormat.compact(3.0), "3")
    @Expect(NumberFormat.compact(3.14159), "3.142")
    @Expect(NumberFormat.compact(3.14159, maxDecimals: 1), "3.1")
    @Expect(NumberFormat.compact(-2.5), "-2.5")
}

@Test
func fixedKeepsZerosForStableWidths(): Unit {
    @Expect(NumberFormat.fixed(1.0, 2), "1.00")
    @Expect(NumberFormat.fixed(1.239, 2), "1.24")
}

@Test
func percentScalesAndSuffixes(): Unit {
    @Expect(NumberFormat.percent(0.42), "42%")
    @Expect(NumberFormat.percent(0.4256, decimals: 1), "42.6%")
    @Expect(NumberFormat.percent(1.0), "100%")
}

@Test
func power10ReadsNaturallyNearUnity(): Unit {
    // "10^0" and "10^1" read worse than the numbers they mean.
    @Expect(NumberFormat.power10(0), "1")
    @Expect(NumberFormat.power10(1), "10")
    @Expect(NumberFormat.power10(3), "10^3")
    @Expect(NumberFormat.power10(-2), "10^-2")
}

@Test
func nonFiniteValuesGetReadableLabels(): Unit {
    @Expect(NumberFormat.tick(Float64.NaN, 1.0), "NaN")
    @Expect(NumberFormat.compact(Float64.Inf), "∞")
    @Expect(NumberFormat.compact(-Float64.Inf), "-∞")
}
