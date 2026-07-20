package examples

import plot.Figure
import plot.axes.ColorBar
import plot.canvas.{LineStyle, MarkerStyle}
import plot.core.Colormap
import plot.series.{ErrorBarSeries, LineSeries, ScatterSeries, Stats}

/**
 * A scatter with a least-squares trend line.
 *
 * `Stats.linearFit` returns `None` when the fit is undetermined, so the trend line is added only if
 * there is one to draw — the alternative is a NaN line across the panel.
 */
public func buildScatter(): Figure {
    let (figure, axes) = Figure.single(title: "Height against weight")
    figure.subtitle = "120 samples with an ordinary least-squares fit"
    axes.xLabel = "height (cm)"
    axes.yLabel = "weight (kg)"

    let source = Data.random(20260717)
    let heights = Data.normal(source, 172.0, 9.0, 120)
    let weights = Data.map(heights) {h => (h - 100.0) * 0.92 + source.nextGaussianFloat64() * 5.0}

    let points = ScatterSeries(heights, weights, label: "subjects")
    points.marker = MarkerStyle.Circle
    points.size = Some(4.0)
    points.opacity = 0.75
    axes.add(points)

    match (Stats.linearFit(heights, weights)) {
        case Some((slope, intercept)) =>
            let span = Data.linspace(150.0, 195.0, 2)
            let trend = LineSeries(span, Data.map(span) {x => slope * x + intercept}, label: "least-squares fit")
            trend.style = LineStyle.Dashed
            axes.add(trend)
        case None => () // Undetermined fit: better no line than a NaN one.
    }

    figure
}

/**
 * A bubble chart: four dimensions on one panel.
 *
 * Marker size maps to *area* rather than radius, so a value twice as large looks twice as big
 * rather than four times. The colour bar is not decoration — without it the colour axis is unread.
 */
public func buildBubble(): Figure {
    let (figure, axes) = Figure.single(title: "Countries by income, life expectancy and population")
    figure.subtitle = "Marker area is population; colour is region index"
    axes.xLabel = "GDP per capita (thousand USD)"
    axes.yLabel = "life expectancy (years)"

    let source = Data.random(4242)
    let count = 60
    let income = Data.normal(source, 28.0, 14.0, count)
    let lifespan = Data.map(income) {g => 58.0 + 22.0 * (1.0 - 1.0 / (1.0 + g / 12.0)) + source.nextGaussianFloat64() *
        1.6}
    let population = Data.map(income) {_ => 1.0 + source.nextFloat64() * 90.0}
    let region = Data.map(income) {g => g * 0.8 + source.nextGaussianFloat64() * 6.0}

    let bubbles = ScatterSeries(income, lifespan, label: "countries")
    bubbles.sizeBy(population, minSize: 3.0, maxSize: 17.0)
    bubbles.colorBy(region, Colormap.viridis())
    bubbles.opacity = 0.85
    axes.add(bubbles)

    match (bubbles.colorValueBounds()) {
        case Some(range) =>
            let bar = ColorBar(range, Colormap.viridis())
            bar.label = "index"
            axes.setColorBar(bar)
        case None => ()
    }

    figure
}

/** Points with asymmetric uncertainty in both axes. */
public func buildErrorBar(): Figure {
    let (figure, axes) = Figure.single(title: "Reaction rate against temperature")
    figure.subtitle = "Error bars are one standard error; the interval is asymmetric by construction"
    axes.xLabel = "temperature (°C)"
    axes.yLabel = "rate (1/s)"

    let temperature = [20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0]
    let rate = [0.11, 0.19, 0.34, 0.55, 0.92, 1.42, 2.10]
    let below = [0.02, 0.03, 0.04, 0.06, 0.09, 0.13, 0.20]
    let above = [0.03, 0.05, 0.07, 0.11, 0.16, 0.24, 0.38]

    let measured = ErrorBarSeries(temperature, rate, label: "measured")
    measured.setYErrorRange(below, above)
    measured.setXError([1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5])
    measured.marker = MarkerStyle.Circle
    measured.connect = true
    measured.lineStyle = LineStyle.Dashed
    axes.add(measured)

    figure
}
