package examples

import std.collection.ArrayList
import plot.Figure

/**
 * One gallery entry: a short name for the command line, a description, and a builder.
 *
 * Every example is a pure `() -> Figure`. That is what lets the gallery both *show* a figure in a
 * window and *export* it to a file from the same definition — and it is also the shape a reader
 * should copy: building a figure never needs a window.
 */
public struct Example {
    public let name: String
    public let title: String
    public let build: () -> Figure

    public init(name: String, title: String, build: () -> Figure) {
        this.name = name
        this.title = title
        this.build = build
    }
}

/** Every example in the gallery, in a sensible reading order. */
public func allExamples(): Array<Example> {
    let list = ArrayList<Example>()
    list.add(Example("line", "Line chart with markers, dashes and a gradient fill", buildLine))
    list.add(Example("line-styles", "Every line style, marker and smoothing option", buildLineStyles))
    list.add(Example("scatter", "Scatter plot with a fitted trend line", buildScatter))
    list.add(Example("bubble", "Bubble chart: size and colour as extra dimensions", buildBubble))
    list.add(Example("bar", "Vertical bars with value labels", buildBar))
    list.add(Example("bar-grouped", "Grouped bars across categories", buildGroupedBar))
    list.add(Example("bar-stacked", "Stacked bars, including negative values", buildStackedBar))
    list.add(Example("bar-horizontal", "Horizontal bars for long category names", buildHorizontalBar))
    list.add(Example("area", "Area chart with a gradient fade to the baseline", buildArea))
    list.add(Example("area-stacked", "Stacked areas showing composition over time", buildStackedArea))
    list.add(Example("band", "Confidence band around a mean curve", buildConfidenceBand))
    list.add(Example("histogram", "Histogram with a density overlay", buildHistogram))
    list.add(Example("boxplot", "Box plots comparing distributions", buildBoxPlot))
    list.add(Example("violin", "Violin plots showing distribution shape", buildViolin))
    list.add(Example("errorbar", "Measurements with asymmetric error bars", buildErrorBar))
    list.add(Example("step", "Step and stem plots for discrete signals", buildStep))
    list.add(Example("pie", "Pie chart", buildPie))
    list.add(Example("donut", "Donut chart with a total in the hole", buildDonut))
    list.add(Example("heatmap", "Heatmap with a colour bar", buildHeatmap))
    list.add(Example("matrix", "Labelled correlation matrix", buildMatrix))
    list.add(Example("contour", "Contour lines over a scalar field", buildContour))
    list.add(Example("radar", "Radar chart comparing profiles", buildRadar))
    list.add(Example("log", "Logarithmic axis across six decades", buildLogScale))
    list.add(Example("annotations", "Reference lines, spans and text notes", buildAnnotations))
    list.add(Example("subplots", "A 2x2 grid of panels", buildSubplots))
    list.add(Example("mixed", "Several chart types on one panel", buildMixed))
    list.add(Example("themes", "The four built-in themes", buildThemes))
    list.add(Example("dashboard", "A composite report page", buildDashboard))
    list.toArray()
}

/** The example with this name, or `None`. */
public func findExample(name: String): ?Example {
    for (example in allExamples()) {
        if (example.name == name) {
            return Some(example)
        }
    }
    None
}
