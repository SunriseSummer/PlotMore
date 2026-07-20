package examples

import std.math.{cos, exp, sin}
import plot.Figure
import plot.canvas.{LineStyle, MarkerStyle}
import plot.axes.LegendPosition
import plot.series.{LineSeries, StemSeries, StepSeries}

/**
 * The starting point: a line, a gradient fill, and a legend.
 *
 * `fillTo` is what turns a line into an area chart — the fill fades toward the baseline, which
 * keeps a second series readable underneath it.
 */
public func buildLine(): Figure {
    let (figure, axes) = Figure.single(title: "Damped oscillation")
    figure.subtitle = "Two modes of a decaying signal"
    axes.xLabel = "time (s)"
    axes.yLabel = "amplitude"

    let times = Data.linspace(0.0, 12.0, 300)

    let fast = LineSeries(times, Data.damped(times, 3.0, 0.18), label: "3.0 Hz mode")
    fast.fillTo = Some(0.0)
    axes.add(fast)

    let slow = LineSeries(times, Data.damped(times, 1.2, 0.10), label: "1.2 Hz mode")
    slow.style = LineStyle.Dashed
    axes.add(slow)

    let envelope = LineSeries(times, Data.map(times) {t => exp(-0.18 * t)}, label: "envelope")
    envelope.style = LineStyle.Dotted
    envelope.width = Some(1.4)
    axes.add(envelope)

    figure
}

/** Every stroke style, marker and the smoothing option, side by side. */
public func buildLineStyles(): Figure {
    let (figure, axes) = Figure.single(title: "Line styles and markers")
    figure.subtitle = "Each series is offset so the styles can be compared directly"
    axes.xLabel = "x"
    axes.yLabel = "series (offset)"
    axes.legend.position = LegendPosition.OutsideRight

    let xs = Data.linspace(0.0, 10.0, 60)
    let styles = [LineStyle.Solid, LineStyle.Dashed, LineStyle.Dotted, LineStyle.DashDot]
    let names = ["Solid", "Dashed", "Dotted", "DashDot"]
    for (i in 0..styles.size) {
        let offset = Float64(styles.size - i) * 1.2
        let series = LineSeries(xs, Data.map(xs) {x => sin(x) * 0.35 + offset}, label: names[i])
        series.style = styles[i]
        axes.add(series)
    }

    // A sparse series with markers and no line: the scatter-like form of a LineSeries.
    let sparse = Data.linspace(0.0, 10.0, 12)
    let marked = LineSeries(sparse, Data.map(sparse) {x => cos(x) * 0.35}, label: "markers only")
    marked.style = LineStyle.NoLine
    marked.marker = MarkerStyle.Circle
    axes.add(marked)

    // Smoothing invents values between samples, so it is off by default and shown here beside
    // the raw polyline it replaces.
    let coarse = Data.linspace(0.0, 10.0, 9)
    let raw = LineSeries(coarse, Data.map(coarse) {x => sin(x * 0.8) * 0.4 - 1.4}, label: "raw samples")
    raw.marker = MarkerStyle.Diamond
    axes.add(raw)

    let smoothed = LineSeries(coarse, Data.map(coarse) {x => sin(x * 0.8) * 0.4 - 2.6}, label: "smoothed")
    smoothed.smooth = true
    smoothed.marker = MarkerStyle.Diamond
    axes.add(smoothed)

    figure
}

/** Step and stem plots — the honest renderings for signals that are not continuous. */
public func buildStep(): Figure {
    let figure = Figure("Discrete signals")
    figure.subtitle = "A step holds its value between samples; a stem says the gaps are not data"
    figure.setGrid(2, 1)

    let stepAxes = figure.addAxes()
    stepAxes.title = "Step: a state that holds until it changes"
    stepAxes.xLabel = "time (s)"
    stepAxes.yLabel = "level"
    let times = Data.linspace(0.0, 10.0, 16)
    let levels = Data.map(times) {t => Float64(Int64(sin(t * 0.7) * 3.0 + 3.0))}
    let steps = StepSeries(times, levels, label: "mode")
    steps.marker = MarkerStyle.Circle
    steps.fillTo = Some(0.0)
    stepAxes.add(steps)

    let stemAxes = figure.addAxes()
    stemAxes.title = "Stem: samples of a discrete sequence"
    stemAxes.xLabel = "n"
    stemAxes.yLabel = "amplitude"
    let n = Data.linspace(0.0, 24.0, 25)
    let impulse = Data.map(n) {k => exp(-k * 0.12) * cos(k * 0.9)}
    stemAxes.add(StemSeries(n, impulse, label: "h[n]"))

    figure
}
