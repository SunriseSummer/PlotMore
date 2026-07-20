package examples

import std.collection.ArrayList
import std.math.{log, pow, sin}
import plot.Figure
import plot.axes.{ColorBar, HorizontalLine, HorizontalSpan, LegendPosition, TextNote, VerticalLine, VerticalSpan}
import plot.canvas.{LineStyle, MarkerStyle}
import plot.axes.Axes
import plot.core.{Bounds, CategoryScale, Colormap, Colors, LogScale, Palette, Theme}
import plot.series.{AreaSeries, BarGroup, BarSeries, HistogramSeries, LineSeries, ScatterSeries}

/**
 * A logarithmic y axis across six decades.
 *
 * A log scale cannot express zero or a negative value. Rather than dropping such points silently,
 * the scale reports what it accepts and the series breaks its line there — visible as a gap.
 */
public func buildLogScale(): Figure {
    let (figure, axes) = Figure.single(title: "Algorithmic complexity")
    figure.subtitle = "A log axis makes ratios comparable across six decades"
    axes.xLabel = "input size n"
    axes.yLabel = "operations"
    axes.setYScale(LogScale(Bounds(1.0, 1.0e6)))

    let sizes = Data.linspace(1.0, 1000.0, 200)
    axes.add(LineSeries(sizes, Data.map(sizes) {n => n}, label: "O(n)"))
    let logLinear = LineSeries(sizes, Data.map(sizes) {n => n * logOf(n)}, label: "O(n log n)")
    logLinear.style = LineStyle.Dashed
    axes.add(logLinear)
    let quadratic = LineSeries(sizes, Data.map(sizes) {n => n * n}, label: "O(n²)")
    quadratic.style = LineStyle.DashDot
    axes.add(quadratic)
    let root = LineSeries(sizes, Data.map(sizes) {n => pow(n, 0.5)}, label: "O(√n)")
    root.style = LineStyle.Dotted
    axes.add(root)

    figure
}

/** Reference lines, shaded spans and anchored notes — everything in `plot.axes` annotations. */
public func buildAnnotations(): Figure {
    let (figure, axes) = Figure.single(title: "Service latency with SLO")
    figure.subtitle = "Annotations live in data coordinates, so they track the data through zoom and pan"
    axes.xLabel = "time (minutes)"
    axes.yLabel = "p99 latency (ms)"

    let minutes = Data.linspace(0.0, 120.0, 241)
    let source = Data.random(5150)
    let latency = Data.map(minutes) {
        t =>
            // A deliberate incident window, so the annotations have something to point at.
            let spike = if (t > 62.0 && t < 78.0) {
                180.0 * sin((t - 62.0) / 16.0 * 3.14159)
            } else {
                0.0
            }
            95.0 + sin(t / 9.0) * 12.0 + source.nextGaussianFloat64() * 6.0 + spike
    }

    let series = LineSeries(minutes, latency, label: "p99")
    series.width = Some(1.8)
    axes.add(series)

    let slo = HorizontalLine(150.0)
    slo.label = "SLO 150 ms"
    slo.color = Some(Colors.hex("#DC2626"))
    let _ = axes.annotate(slo)

    let healthy = HorizontalSpan(0.0, 150.0)
    healthy.color = Some(Colors.hex("#10B981"))
    healthy.opacity = 0.07
    let _ = axes.annotate(healthy)

    // The band is left unlabelled on purpose: the deploy line already sits at its leading edge, and
    // a span labels at its centre, so two captions would land on top of each other.
    let incident = VerticalSpan(62.0, 78.0)
    incident.color = Some(Colors.hex("#F59E0B"))
    incident.opacity = 0.16
    let _ = axes.annotate(incident)

    let deploy = VerticalLine(62.0)
    deploy.label = "deploy v2.4"
    let _ = axes.annotate(deploy)

    let note = TextNote(70.0, 268.0, "p99 peaked at 268 ms")
    note.offsetX = 12.0
    note.offsetY = -6.0
    let _ = axes.annotate(note)

    figure
}

/** A 2x2 grid: independent panels laid out by the figure. */
public func buildSubplots(): Figure {
    let figure = Figure("Sensor overview")
    figure.subtitle = "Four independent panels on one figure grid"
    figure.setGrid(2, 2)

    let source = Data.random(8080)
    let times = Data.linspace(0.0, 48.0, 145)

    let temperature = figure.addAxes()
    temperature.title = "Temperature"
    temperature.xLabel = "hour"
    temperature.yLabel = "°C"
    let tempSeries = LineSeries(times, Data.map(times) {
        t => 18.0 + sin(t / 24.0 * 6.283) * 6.0 + source.nextGaussianFloat64() * 0.4
    }, label: "outdoor")
    tempSeries.fillTo = Some(0.0)
    temperature.add(tempSeries)

    let humidity = figure.addAxes()
    humidity.title = "Humidity"
    humidity.xLabel = "hour"
    humidity.yLabel = "%"
    humidity.add(LineSeries(times, Data.map(times) {
        t => 58.0 - sin(t / 24.0 * 6.283) * 12.0 + source.nextGaussianFloat64() * 1.2
    }, label: "relative"))

    let wind = figure.addAxes()
    wind.title = "Wind by direction"
    wind.setXScale(CategoryScale(["N", "NE", "E", "SE", "S", "SW", "W", "NW"]))
    wind.yLabel = "m/s"
    wind.showGridX = false
    wind.add(BarSeries([3.1, 4.8, 6.2, 5.1, 2.9, 3.6, 7.4, 5.9]))

    let pressure = figure.addAxes()
    pressure.title = "Pressure distribution"
    pressure.xLabel = "hPa"
    pressure.yLabel = "count"
    pressure.add(HistogramSeries(Data.normal(source, 1013.0, 6.0, 500), bins: 24))

    figure
}

/** Several chart types sharing one panel — the composition the Series abstraction is for. */
public func buildMixed(): Figure {
    let (figure, axes) = Figure.single(title: "Monthly revenue and trend")
    figure.subtitle = "Bars, a band and a line share one panel and one pair of scales"
    axes.setXScale(CategoryScale(Data.months()))
    axes.yLabel = "revenue (M USD)"
    axes.showGridX = false
    axes.legend.position = LegendPosition.TopLeft

    let actual = [8.2, 9.1, 11.4, 10.2, 12.8, 14.1, 13.2, 15.6, 17.2, 16.1, 18.9, 21.4]
    let bars = BarSeries(actual, label: "actual")
    bars.bandFraction = 0.55
    axes.add(bars)

    let index = Data.linspace(0.0, 11.0, 12)
    let target = Data.map(index) {i => 8.0 + i * 1.15}
    let lower = Data.map(index) {i => 8.0 + i * 1.15 - 1.6}
    let upper = Data.map(index) {i => 8.0 + i * 1.15 + 1.6}

    let band = AreaSeries.between(index, lower, upper, label: "target range")
    band.fillOpacity = 0.18
    band.fadeOpacity = 0.18
    axes.add(band)

    let trend = LineSeries(index, target, label: "target")
    trend.style = LineStyle.Dashed
    trend.marker = MarkerStyle.Circle
    trend.markerSize = Some(3.0)
    axes.add(trend)

    figure
}

/** Every built-in theme on one figure, so the differences are visible side by side. */
public func buildThemes(): Figure {
    // A figure carries one theme, so this shows the light presets together and names the dark one;
    // `dashboard` and the interactive example show dark in full.
    let figure = Figure("Built-in themes")
    figure.subtitle = "Theme.light() shown here; also lightPanel(), publication() and dark()"
    figure.setGrid(1, 3)
    figure.theme = Theme.lightPanel()

    let xs = Data.linspace(0.0, 10.0, 120)

    let first = figure.addAxes()
    first.title = "Palette.modern()"
    addPaletteDemo(first, xs, Palette.modern())

    let second = figure.addAxes()
    second.title = "Palette.colorblindSafe()"
    addPaletteDemo(second, xs, Palette.colorblindSafe())

    let third = figure.addAxes()
    third.title = "Palette.muted()"
    addPaletteDemo(third, xs, Palette.muted())

    figure
}

func addPaletteDemo(axes: Axes, xs: Array<Float64>, palette: Palette): Unit {
    for (i in 0..5) {
        let phase = Float64(i) * 0.6
        let series = LineSeries(xs, Data.map(xs) {x => sin(x + phase) + Float64(i) * 0.9})
        series.setColor(palette.at(i))
        axes.add(series)
    }
    axes.showTickLabels = false
}

/** A realistic composite page: the kind of figure the library exists to produce. */
public func buildDashboard(): Figure {
    let figure = Figure("Service report — week 27")
    figure.subtitle = "Generated with plot for Cangjie"
    figure.theme = Theme.dark()
    figure.setGrid(2, 2)

    let source = Data.random(20260714)
    let hours = Data.linspace(0.0, 168.0, 337)

    let traffic = figure.addAxes()
    traffic.title = "Requests per second"
    traffic.xLabel = "hour of week"
    traffic.yLabel = "req/s"
    let rps = Data.map(hours) {
        h => 400.0 + 260.0 * sin(h / 24.0 * 6.283 - 1.6) + 90.0 * sin(h / 168.0 * 6.283) +
            source.nextGaussianFloat64() * 22.0
    }
    let rpsSeries = LineSeries(hours, rps, label: "observed")
    rpsSeries.width = Some(1.4)
    rpsSeries.fillTo = Some(0.0)
    traffic.add(rpsSeries)

    let latency = figure.addAxes()
    latency.title = "Latency percentiles"
    latency.setXScale(CategoryScale(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]))
    latency.yLabel = "ms"
    latency.showGridX = false
    let percentiles = BarGroup.grouped(
        [
            BarSeries([42.0, 44.0, 41.0, 46.0, 52.0, 38.0, 36.0], label: "p50"),
            BarSeries([88.0, 92.0, 86.0, 99.0, 121.0, 74.0, 69.0], label: "p95"),
            BarSeries([142.0, 151.0, 138.0, 168.0, 214.0, 118.0, 109.0], label: "p99")
        ]
    )
    for (series in percentiles) {
        latency.add(series)
    }

    let errors = figure.addAxes()
    errors.title = "Error budget burn"
    errors.xLabel = "hour of week"
    errors.yLabel = "% consumed"
    // A running total needs mutable state across samples, which a lambda cannot capture in
    // Cangjie, so the accumulation is an explicit loop.
    let budget = ArrayList<Float64>()
    var burned = 0.0
    for (_ in 0..hours.size) {
        burned += source.nextFloat64() * 0.22
        budget.add(burned)
    }
    let burn = AreaSeries(hours, budget.toArray(), label: "consumed")
    burn.setColor(Colors.hex("#F59E0B"))
    errors.add(burn)
    // Annotations deliberately do not stretch the axis — a reference line is not data. So the
    // limit has to be pinned, or a budget the week never approached would sit off-panel and the
    // chart would silently lose its point.
    errors.setYLimits(Bounds(0.0, 110.0))
    errors.legend.position = LegendPosition.TopLeft
    let limit = HorizontalLine(100.0)
    limit.label = "budget"
    limit.color = Some(Colors.hex("#EF4444"))
    let _ = errors.annotate(limit)

    let saturation = figure.addAxes()
    saturation.title = "CPU by instance"
    saturation.xLabel = "utilisation"
    saturation.yLabel = "memory (GB)"
    // The cloud runs up to the top right, so the legend goes where the data is not.
    saturation.legend.position = LegendPosition.TopLeft
    let cpu = Data.map(Data.linspace(0.0, 1.0, 90)) {_ => source.nextFloat64() * 0.9 + 0.05}
    let memory = Data.map(cpu) {c => c * 12.0 + source.nextGaussianFloat64() * 1.5 + 2.0}
    let load = Data.map(cpu) {c => c * 100.0}
    let instances = ScatterSeries(cpu, memory, label: "instances")
    instances.colorBy(load, Colormap.plasma())
    instances.sizeBy(load, minSize: 3.0, maxSize: 10.0)
    saturation.add(instances)
    match (instances.colorValueBounds()) {
        case Some(range) =>
            let bar = ColorBar(range, Colormap.plasma())
            bar.label = "load %"
            saturation.setColorBar(bar)
        case None => ()
    }

    figure
}

// std.math has no natural-log-of-n helper that reads well inline; n >= 1 here by construction.
func logOf(n: Float64): Float64 {
    if (n <= 1.0) {
        return 1.0
    }
    log(n)
}
