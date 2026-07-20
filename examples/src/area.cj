package examples

import std.collection.ArrayList
import std.math.sin
import plot.Figure
import plot.axes.{LabelOrientation, LegendPosition}
import plot.series.{AreaSeries, AreaStack, LineSeries}

/** A single area with a gradient fade to the baseline — the modern default for a filled series. */
public func buildArea(): Figure {
    let (figure, axes) = Figure.single(title: "Daily active users")
    axes.xLabel = "day"
    axes.yLabel = "users (thousands)"
    // The default y-title is rotated vertical on the left; this panel shows the dashboard-style
    // horizontal alternative, which sits above the axis instead.
    axes.yLabelOrientation = LabelOrientation.Horizontal

    let days = Data.linspace(0.0, 90.0, 91)
    let source = Data.random(2468)
    let users = Data.map(days) {d => 40.0 + d * 0.42 + sin(d / 6.0) * 5.0 + source.nextGaussianFloat64() * 1.6}

    let area = AreaSeries(days, users, label: "active users")
    axes.add(area)

    figure
}

/**
 * Stacked areas: composition over time.
 *
 * Each layer's baseline is the total of those below it, so the top edge is the overall total. That
 * relationship is between layers, which is why `AreaStack.build` computes it rather than each area
 * being told its own baseline.
 */
public func buildStackedArea(): Figure {
    let (figure, axes) = Figure.single(title: "Traffic by source")
    figure.subtitle = "Stacked areas: the top edge is the total"
    axes.xLabel = "week"
    axes.yLabel = "sessions (thousands)"
    axes.legend.position = LegendPosition.OutsideRight

    let weeks = Data.linspace(0.0, 52.0, 53)
    let source = Data.random(1357)
    let organic = Data.map(weeks) {w => 20.0 + w * 0.30 + sin(w / 8.0) * 3.0 + source.nextFloat64() * 1.5}
    let referral = Data.map(weeks) {w => 8.0 + sin(w / 5.0) * 2.0 + source.nextFloat64() * 1.0}
    let paid = Data.map(weeks) {w => 5.0 + w * 0.12 + source.nextFloat64() * 1.0}
    let social = Data.map(weeks) {w => 3.0 + sin(w / 3.0 + 1.0) * 1.5 + source.nextFloat64() * 0.8}

    let layers = AreaStack.build(weeks, [organic, referral, paid, social],
        labels: ["organic", "referral", "paid", "social"])
    for (layer in layers) {
        axes.add(layer)
    }

    figure
}

/**
 * A confidence band around a mean curve.
 *
 * `AreaSeries.between` fills between two boundaries rather than to a baseline — the shape an
 * interval, an envelope, or a tolerance corridor actually has.
 */
public func buildConfidenceBand(): Figure {
    let (figure, axes) = Figure.single(title: "Model forecast with uncertainty")
    figure.subtitle = "The band is a 95% interval; it widens as the forecast extends"
    axes.xLabel = "horizon (days)"
    axes.yLabel = "predicted load"

    let days = Data.linspace(0.0, 30.0, 121)
    let mean = Data.map(days) {d => 100.0 + d * 1.8 + sin(d / 2.0) * 6.0}
    // Uncertainty grows with the horizon, which is the whole point of drawing it.
    let width = Data.map(days) {d => 4.0 + d * 0.55}

    let lower = ArrayList<Float64>()
    let upper = ArrayList<Float64>()
    for (i in 0..days.size) {
        lower.add(mean[i] - width[i])
        upper.add(mean[i] + width[i])
    }

    let band = AreaSeries.between(days, lower.toArray(), upper.toArray(), label: "95% interval")
    band.fillOpacity = 0.22
    band.fadeOpacity = 0.22
    axes.add(band)

    let curve = LineSeries(days, mean, label: "mean forecast")
    curve.width = Some(2.2)
    // Pin the curve to the band's colour so they read as one statement rather than two series.
    curve.setColor(figure.theme.palette.at(0))
    axes.add(curve)

    figure
}
