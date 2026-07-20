package examples

import plot.Figure
import plot.axes.LegendPosition
import plot.core.CategoryScale
import plot.series.{BarGroup, BarOrientation, BarSeries}

/** The simplest bar chart: one series over categories, with the values printed. */
public func buildBar(): Figure {
    let (figure, axes) = Figure.single(title: "Quarterly revenue")
    axes.xLabel = "quarter"
    axes.yLabel = "revenue (M USD)"
    // A category scale gives each name a unit-wide band; the bars size themselves to it.
    axes.setXScale(CategoryScale(["Q1", "Q2", "Q3", "Q4"]))
    axes.showGridX = false

    let bars = BarSeries([12.4, 19.1, 7.8, 22.6])
    bars.showValues = true
    bars.valueDecimals = Some(1)
    axes.add(bars)

    figure
}

/** Several series side by side within each category band. */
public func buildGroupedBar(): Figure {
    let (figure, axes) = Figure.single(title: "Revenue by region")
    figure.subtitle = "Grouped bars compare series within a category"
    axes.xLabel = "quarter"
    axes.yLabel = "revenue (M USD)"
    axes.setXScale(CategoryScale(["Q1", "Q2", "Q3", "Q4"]))
    axes.showGridX = false

    // BarGroup assigns the slots: a bar cannot know its position from its own values alone.
    let grouped = BarGroup.grouped(
        [
            BarSeries([12.4, 19.1, 7.8, 22.6], label: "EMEA"),
            BarSeries([9.2, 14.8, 11.3, 18.1], label: "Americas"),
            BarSeries([5.7, 8.2, 9.9, 12.4], label: "APAC")
        ]
    )
    for (series in grouped) {
        axes.add(series)
    }

    figure
}

/**
 * Stacked bars, including negative values.
 *
 * Positive and negative segments stack away from zero independently, so a mixed-sign column grows
 * both up and down rather than cancelling into an unreadable overlap.
 */
public func buildStackedBar(): Figure {
    let (figure, axes) = Figure.single(title: "Cash flow by quarter")
    figure.subtitle = "Positive and negative segments stack away from zero"
    axes.xLabel = "quarter"
    axes.yLabel = "flow (M USD)"
    axes.setXScale(CategoryScale(["Q1", "Q2", "Q3", "Q4"]))
    axes.showGridX = false
    axes.legend.position = LegendPosition.OutsideRight

    let stacked = BarGroup.stacked(
        [
            BarSeries([8.0, 11.0, 6.0, 14.0], label: "product"),
            BarSeries([4.0, 5.5, 3.2, 7.1], label: "services"),
            BarSeries([-3.1, -4.2, -5.8, -3.4], label: "operating cost"),
            BarSeries([-1.2, -1.5, -2.1, -1.8], label: "tax")
        ]
    )
    for (series in stacked) {
        axes.add(series)
    }

    figure
}

/**
 * Horizontal bars.
 *
 * The right choice when category names are long: they get the full panel width to read across,
 * instead of being crushed under a vertical axis.
 */
public func buildHorizontalBar(): Figure {
    let (figure, axes) = Figure.single(title: "Time spent per stage")
    axes.xLabel = "duration (ms)"
    // The category axis is y for horizontal bars, so the scales swap.
    axes.setYScale(CategoryScale(["parse", "type check", "optimise", "codegen", "link", "package"]))
    axes.showGridY = false

    let bars = BarSeries([142.0, 388.0, 265.0, 431.0, 96.0, 58.0])
    bars.orientation = BarOrientation.Horizontal
    bars.showValues = true
    bars.valueDecimals = Some(0)
    axes.add(bars)

    figure
}
