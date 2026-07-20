package examples

import plot.Figure
import plot.axes.{LegendPosition, PieAxes, PieLabelMode, PieSlice, RadarAxes, RadarTrace}
import plot.canvas.MarkerStyle
import plot.core.Bounds

/**
 * A pie chart.
 *
 * Worth knowing: angle is a poor encoding for comparison, and a bar chart beats a pie for almost
 * any "which is bigger" question. A pie earns its place when the message is part-of-whole across a
 * handful of slices, which is the case shown here.
 */
public func buildPie(): Figure {
    let figure = Figure("Browser share")
    figure.subtitle = "A pie answers 'what fraction', not 'which is bigger'"

    let pie = PieAxes(
        [
            PieSlice(64.2, label: "Chrome"),
            PieSlice(18.7, label: "Safari"),
            PieSlice(9.1, label: "Edge"),
            PieSlice(5.0, label: "Firefox"),
            PieSlice(3.0, label: "Other", explode: 0.08)
        ]
    )
    pie.labelMode = PieLabelMode.Percent
    pie.percentDecimals = 1
    let _ = figure.addPanel(pie)

    figure
}

/**
 * A donut, with the total in the hole.
 *
 * That hole is the donut's real advantage over a pie: it is the one place on the chart where an
 * absolute number can sit and be read directly, rather than inferred from an angle.
 */
public func buildDonut(): Figure {
    let figure = Figure("Storage by category")

    let donut = PieAxes(
        [
            PieSlice(412.0, label: "Media"),
            PieSlice(268.0, label: "Backups"),
            PieSlice(154.0, label: "Documents"),
            PieSlice(96.0, label: "Applications"),
            PieSlice(48.0, label: "System")
        ]
    )
    donut.innerRadius = 0.58
    donut.labelMode = PieLabelMode.NoLabel
    donut.donutLabel = "978 GB"
    donut.donutSublabel = "of 2 TB used"
    donut.legend.position = LegendPosition.OutsideRight
    let _ = figure.addPanel(donut)

    figure
}

/**
 * A radar chart comparing profiles across commensurable axes.
 *
 * Every spoke shares one radial scale, so the variables have to be on the same footing — these are
 * all normalised scores. Plot raw units of different magnitudes here and the polygon's shape says
 * more about the units than about the data.
 */
public func buildRadar(): Figure {
    let figure = Figure("Model comparison")
    figure.subtitle = "All axes are normalised scores, which is what makes one radial scale honest"

    let radar = RadarAxes(["accuracy", "speed", "memory", "robustness", "simplicity", "cost"])
    radar.valueRange = Some(Bounds(0.0, 1.0))
    radar.rings = 5

    let baseline = RadarTrace([0.62, 0.88, 0.80, 0.55, 0.90, 0.85], label: "baseline")
    baseline.marker = MarkerStyle.Circle
    let _ = radar.add(baseline)

    let tuned = RadarTrace([0.91, 0.54, 0.45, 0.82, 0.48, 0.40], label: "tuned")
    tuned.marker = MarkerStyle.Diamond
    let _ = radar.add(tuned)

    let hybrid = RadarTrace([0.78, 0.72, 0.62, 0.70, 0.66, 0.60], label: "hybrid")
    hybrid.marker = MarkerStyle.Square
    let _ = radar.add(hybrid)

    let _ = figure.addPanel(radar)
    figure
}
