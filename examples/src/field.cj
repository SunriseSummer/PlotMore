package examples

import std.collection.ArrayList
import plot.Figure
import plot.axes.ColorBar
import plot.core.{Bounds, CategoryScale, Colormap}
import plot.series.{ContourSeries, HeatmapSeries}

/** A heatmap of a scalar field, with the colour bar that makes it readable. */
public func buildHeatmap(): Figure {
    let (figure, axes) = Figure.single(title: "Scalar field")
    figure.subtitle = "A heatmap without a colour bar is a picture, not a measurement"
    axes.xLabel = "x"
    axes.yLabel = "y"
    axes.showGrid = false

    let heat = HeatmapSeries.fromFunction(80, 110, Bounds(-3.0, 3.0), Bounds(-3.0, 3.0)) {
        x, y => Data.peakAt(x, y)
    }
    heat.map = Some(Colormap.magma())
    heat.cellGap = 0.0
    axes.add(heat)

    let bar = ColorBar(heat.resolvedValueRange(), Colormap.magma())
    bar.label = "value"
    axes.setColorBar(bar)

    figure
}

/**
 * A labelled correlation matrix.
 *
 * `originTop` puts row 0 at the top, matching how a matrix is written; a diverging colormap centres
 * the scale on zero so positive and negative correlations read as opposites rather than as
 * "more" and "less".
 */
public func buildMatrix(): Figure {
    let (figure, axes) = Figure.single(title: "Feature correlation")
    figure.subtitle = "A diverging map centred on zero: sign is the message"
    axes.showGrid = false
    axes.showTicks = false

    let names = ["temp", "humidity", "pressure", "wind", "rainfall", "yield"]
    let values = [
        1.00,
        -0.42,
        0.18,
        0.05,
        -0.61,
        0.72,
        -0.42,
        1.00,
        -0.23,
        -0.11,
        0.68,
        -0.35,
        0.18,
        -0.23,
        1.00,
        -0.55,
        -0.12,
        0.09,
        0.05,
        -0.11,
        -0.55,
        1.00,
        0.21,
        -0.04,
        -0.61,
        0.68,
        -0.12,
        0.21,
        1.00,
        -0.48,
        0.72,
        -0.35,
        0.09,
        -0.04,
        -0.48,
        1.00
    ]

    axes.setXScale(CategoryScale(names))
    axes.setYScale(CategoryScale(reversedNames(names)))

    let matrix = HeatmapSeries(values, rows: 6, columns: 6)
    matrix.map = Some(Colormap.coolWarm())
    // Pin the range symmetrically so the map's neutral midpoint lands exactly on zero.
    matrix.valueRange = Some(Bounds(-1.0, 1.0))
    matrix.originTop = true
    matrix.showValues = true
    matrix.valueDecimals = Some(2)
    matrix.cellGap = 1.5
    matrix.cornerRadius = 3.0
    axes.add(matrix)

    let bar = ColorBar(Bounds(-1.0, 1.0), Colormap.coolWarm())
    bar.label = "r"
    axes.setColorBar(bar)

    figure
}

/** Contour lines traced by marching squares, over a shaded field. */
public func buildContour(): Figure {
    let (figure, axes) = Figure.single(title: "Contour lines")
    figure.subtitle = "Marching squares over the same field, shaded underneath for context"
    axes.xLabel = "x"
    axes.yLabel = "y"
    axes.showGrid = false

    // The heatmap gives the field a background; the contours give it readable levels.
    let heat = HeatmapSeries.fromFunction(70, 70, Bounds(-3.0, 3.0), Bounds(-3.0, 3.0)) {
        x, y => Data.peakAt(x, y)
    }
    heat.map = Some(Colormap.viridis())
    heat.opacity = 0.55
    heat.cellGap = 0.0
    axes.add(heat)

    let contour = ContourSeries.fromFunction(90, 90, Bounds(-3.0, 3.0), Bounds(-3.0, 3.0)) {
        x, y => Data.peakAt(x, y)
    }
    contour.label = "level"
    contour.levelCount = 12
    contour.lineWidth = 1.2
    contour.map = Some(Colormap.viridis())
    axes.add(contour)

    let bar = ColorBar(heat.resolvedValueRange(), Colormap.viridis())
    bar.label = "value"
    axes.setColorBar(bar)

    figure
}

func reversedNames(names: Array<String>): Array<String> {
    let result = ArrayList<String>()
    var i = names.size - 1
    while (i >= 0) {
        result.add(names[i])
        i -= 1
    }
    result.toArray()
}
