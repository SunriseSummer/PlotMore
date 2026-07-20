package examples

import std.collection.ArrayList
import plot.Figure
import plot.core.{Bounds, CategoryScale}
import plot.series.{BoxPlotSeries, HistogramNorm, HistogramSeries, LineSeries, Stats, ViolinSeries}

/**
 * A histogram with a kernel density estimate over it.
 *
 * Both are normalised to density so they share a y axis — a count histogram and a density curve
 * have different units and overlaying them without normalising is simply wrong.
 */
public func buildHistogram(): Figure {
    let (figure, axes) = Figure.single(title: "Measurement distribution")
    figure.subtitle = "Histogram normalised to density, with a Gaussian kernel estimate"
    axes.xLabel = "value"
    axes.yLabel = "density"

    let source = Data.random(31337)
    let samples = Data.normal(source, 100.0, 15.0, 1200)

    let hist = HistogramSeries(samples, bins: 32, label: "samples")
    hist.norm = HistogramNorm.Density
    hist.fillOpacity = 0.75
    axes.add(hist)

    let range = match (Bounds.cover(samples)) {
        case Some(bounds) => bounds.expanded(0.05)
        case None => Bounds(0.0, 1.0)
    }
    let grid = Data.linspace(range.low, range.high, 200)
    let density = Stats.kernelDensity(samples, range, 200)
    let curve = LineSeries(grid, density, label: "kernel density")
    curve.width = Some(2.2)
    axes.add(curve)

    figure
}

/** Two distributions overlaid, which is what a low fill opacity is for. */
public func buildBoxPlot(): Figure {
    let (figure, axes) = Figure.single(title: "Latency by deployment")
    figure.subtitle = "Whiskers reach the furthest sample within 1.5 IQR; the rest are drawn as outliers"
    axes.xLabel = "deployment"
    axes.yLabel = "latency (ms)"
    axes.setXScale(CategoryScale(["baseline", "cache", "pooling", "both"]))
    axes.showGridX = false

    let source = Data.random(777)
    let groups = [
        withOutliers(Data.normal(source, 120.0, 18.0, 90), [260.0, 240.0]),
        Data.normal(source, 92.0, 14.0, 90),
        withOutliers(Data.normal(source, 78.0, 11.0, 90), [150.0]),
        Data.normal(source, 61.0, 9.0, 90)
    ]

    let boxes = BoxPlotSeries(groups)
    boxes.showMean = true
    axes.add(boxes)

    figure
}

/**
 * Violins, which show the *shape* a box plot hides.
 *
 * The bimodal group is the point: its box would look like a wide, unremarkable spread.
 */
public func buildViolin(): Figure {
    let (figure, axes) = Figure.single(title: "Response time by cohort")
    figure.subtitle = "A violin shows structure a box plot averages away — note the bimodal cohort"
    axes.xLabel = "cohort"
    axes.yLabel = "response (ms)"
    axes.setXScale(CategoryScale(["A", "B", "C (bimodal)"]))
    axes.showGridX = false

    let source = Data.random(99)
    let unimodalA = Data.normal(source, 100.0, 12.0, 200)
    let unimodalB = Data.normal(source, 118.0, 20.0, 200)
    // Two well-separated modes: the case that motivates a violin over a box.
    let bimodal = concat(Data.normal(source, 82.0, 8.0, 100), Data.normal(source, 132.0, 9.0, 100))

    let violins = ViolinSeries([unimodalA, unimodalB, bimodal])
    violins.showBox = true
    axes.add(violins)

    figure
}

func withOutliers(samples: Array<Float64>, extra: Array<Float64>): Array<Float64> {
    concat(samples, extra)
}

func concat(a: Array<Float64>, b: Array<Float64>): Array<Float64> {
    let result = ArrayList<Float64>()
    for (value in a) {
        result.add(value)
    }
    for (value in b) {
        result.add(value)
    }
    result.toArray()
}
