package plot.series

import sdl.{Color, Rect}
import plot.canvas.{Canvas, HAlign, VAlign}
import plot.core.{Bounds, Colormap, Colors, NumberFormat, PlotException, Projection, Theme, isFinite}

/**
 * A 2D scalar field on a regular grid, coloured through a colormap.
 *
 * Values are row-major: `value(row, column)` sits at grid position `(column, row)`, with row 0 at
 * the *bottom* by default so the y axis reads upward like every other chart. `originTop` flips that
 * for data that is naturally an image or a matrix.
 *
 * ```
 * let heat = HeatmapSeries(values, rows: 12, columns: 20)
 * heat.map = Colormap.magma()
 * heat.showValues = true
 * ```
 */
public class HeatmapSeries <: Series {
    private let values: Array<Float64>
    private let rowCount: Int64
    private let columnCount: Int64

    /** The colour ramp; `None` follows `theme.colormap`. */
    public var map: ?Colormap = None

    /** The value range mapped across the ramp; `None` autoscales to the data. */
    public var valueRange: ?Bounds = None

    /** Places row 0 at the top, matrix style, rather than at the bottom. */
    public var originTop: Bool = false

    /** Pixel gap between cells; a hairline gap reads as a grid without drawing one. */
    public var cellGap: Float32 = 0.5

    /** Corner rounding per cell, in logical pixels. */
    public var cornerRadius: Float32 = 0.0

    /** Prints each cell's value, in a colour chosen to contrast with the cell. */
    public var showValues: Bool = false

    /** Decimal places for `showValues`; `None` picks a compact form. */
    public var valueDecimals: ?Int64 = None

    /** The data x range the grid spans; `None` uses `0 .. columns-1` at cell centres. */
    public var xRange: ?Bounds = None

    /** The data y range the grid spans; `None` uses `0 .. rows-1` at cell centres. */
    public var yRange: ?Bounds = None

    /**
     * Throws `PlotException` when the dimensions are non-positive or `values` does not hold exactly
     * `rows * columns` entries.
     */
    public init(values: Array<Float64>, rows!: Int64, columns!: Int64, label!: String = "") {
        super()
        if (rows < 1 || columns < 1) {
            throw PlotException("A heatmap needs positive dimensions; got ${rows}x${columns}.")
        }
        if (values.size != rows * columns) {
            throw PlotException("A ${rows}x${columns} heatmap needs ${rows * columns} values; got ${values.size}.")
        }
        this.values = values
        this.rowCount = rows
        this.columnCount = columns
        this.label = label
    }

    /**
     * Builds a heatmap from a function sampled over the grid — the common case for a field defined
     * analytically rather than measured.
     */
    public static func fromFunction(
        rows: Int64,
        columns: Int64,
        xRange: Bounds,
        yRange: Bounds,
        f: (Float64, Float64) -> Float64
    ): HeatmapSeries {
        if (rows < 1 || columns < 1) {
            throw PlotException("A heatmap needs positive dimensions; got ${rows}x${columns}.")
        }
        let values = Array<Float64>(rows * columns, repeat: 0.0)
        for (r in 0..rows) {
            let y = sampleAt(yRange, r, rows)
            for (c in 0..columns) {
                values[r * columns + c] = f(sampleAt(xRange, c, columns), y)
            }
        }
        let heat = HeatmapSeries(values, rows: rows, columns: columns)
        heat.xRange = Some(xRange)
        heat.yRange = Some(yRange)
        heat
    }

    /** The value at a grid cell. */
    public func value(row: Int64, column: Int64): Float64 {
        values[row * columnCount + column]
    }

    /** The grid's row count. */
    public func rows(): Int64 {
        rowCount
    }

    /** The grid's column count. */
    public func columns(): Int64 {
        columnCount
    }

    /** The value range mapped across the ramp — pinned, or autoscaled to the finite data. */
    public func resolvedValueRange(): Bounds {
        match (valueRange) {
            case Some(bounds) => bounds
            case None => match (Bounds.cover(values)) {
                case Some(bounds) => bounds.nonDegenerate()
                case None => Bounds(0.0, 1.0)
            }
        }
    }

    /** The colormap in use. */
    public func resolvedColormap(theme: Theme): Colormap {
        map ?? theme.colormap
    }

    public func dataBounds(): ?(Bounds, Bounds) {
        // Bounds reach half a cell past the centres, so the outermost cells are fully on the panel.
        let x = xRange ?? Bounds(0.0, Float64(columnCount - 1))
        let y = yRange ?? Bounds(0.0, Float64(rowCount - 1))
        Some((x.padded(halfCell(x, columnCount)), y.padded(halfCell(y, rowCount))))
    }

    /** The grid tiles its rectangle exactly; padding it would band the panel with background. */
    public override func fillsExtent(): Bool {
        true
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let ramp = resolvedColormap(theme)
        let range = resolvedValueRange()
        let x = xRange ?? Bounds(0.0, Float64(columnCount - 1))
        let y = yRange ?? Bounds(0.0, Float64(rowCount - 1))
        let halfX = halfCell(x, columnCount)
        let halfY = halfCell(y, rowCount)
        for (r in 0..rowCount) {
            let dataRow = if (originTop) {
                rowCount - 1 - r
            } else {
                r
            }
            let centerY = sampleAt(y, r, rowCount)
            for (c in 0..columnCount) {
                let raw = value(dataRow, c)
                if (!isFinite(raw)) {
                    continue
                }
                let centerX = sampleAt(x, c, columnCount)
                let left = projection.pixelX(centerX - halfX)
                let right = projection.pixelX(centerX + halfX)
                let top = projection.pixelY(centerY + halfY)
                let bottom = projection.pixelY(centerY - halfY)
                let rect = Rect(minOfF(left, right) + cellGap, minOfF(top, bottom) + cellGap,
                    absF(right - left) - cellGap * 2.0, absF(bottom - top) - cellGap * 2.0)
                if (rect.w <= 0.0 || rect.h <= 0.0) {
                    continue
                }
                let cellColor = tint(ramp.sampleIn(raw, range))
                if (cornerRadius > 0.5) {
                    canvas.fillRoundedRect(rect, cornerRadius, cellColor)
                } else {
                    canvas.fillRect(rect, cellColor)
                }
                if (showValues) {
                    drawCellValue(canvas, rect, raw, cellColor, theme)
                }
            }
        }
    }

    public override func legend(theme: Theme): Array<LegendEntry> {
        if (label.isEmpty()) {
            return []
        }
        let ramp = resolvedColormap(theme)
        [
            LegendEntry(label, ramp.sample(0.5)) {
                canvas, rect, _ =>
                    // A miniature ramp, since one chip cannot represent a continuous scale.
                    let steps = 12
                    let step = rect.w / Float32(steps)
                    for (i in 0..steps) {
                        canvas.fillRect(Rect(rect.x + Float32(i) * step, rect.y, step + 0.5, rect.h),
                            ramp.sample(Float64(i) / Float64(steps - 1)))
                    }
            }
        ]
    }

    public override func hitTest(px: Float32, py: Float32, projection: Projection, theme: Theme): ?HitResult {
        let x = xRange ?? Bounds(0.0, Float64(columnCount - 1))
        let y = yRange ?? Bounds(0.0, Float64(rowCount - 1))
        let dataX = projection.dataX(px)
        let dataY = projection.dataY(py)
        let column = nearestIndex(x, dataX, columnCount)
        let row = nearestIndex(y, dataY, rowCount)
        if (column < 0 || column >= columnCount || row < 0 || row >= rowCount) {
            return None
        }
        let dataRow = if (originTop) {
            rowCount - 1 - row
        } else {
            row
        }
        let raw = value(dataRow, column)
        // `draw` skips non-finite cells, so there is no cell on screen here to report a hit on.
        if (!isFinite(raw)) {
            return None
        }
        let text = "[${dataRow}, ${column}] ${NumberFormat.compact(raw)}"
        Some(
            HitResult(label, sampleAt(x, column, columnCount), sampleAt(y, row, rowCount), px, py, 0.0,
                resolvedColormap(theme).sampleIn(raw, resolvedValueRange()), text))
    }

    private func tint(base: Color): Color {
        if (opacity >= 1.0) {
            base
        } else {
            Colors.fade(base, opacity)
        }
    }

    private func drawCellValue(canvas: Canvas, rect: Rect, raw: Float64, cellColor: Color, theme: Theme): Unit {
        let text = match (valueDecimals) {
            case Some(places) => NumberFormat.fixed(raw, places)
            case None => NumberFormat.compact(raw, maxDecimals: 2)
        }
        if (canvas.textWidth(text, size: theme.annotationSize) > rect.w) {
            return
        }
        canvas.textAnchored(text, rect.centerX(), rect.centerY(), Colors.contrastText(cellColor),
            size: theme.annotationSize, hAlign: HAlign.Center, vAlign: VAlign.Middle)
    }

    private func nearestIndex(range: Bounds, value: Float64, count: Int64): Int64 {
        if (count == 1) {
            return 0
        }
        let step = range.span() / Float64(count - 1)
        if (step <= 0.0) {
            return 0
        }
        Int64((value - range.low) / step + 0.5)
    }
}

/** The data coordinate of grid index `i` of `count`, spread across `range`. */
func sampleAt(range: Bounds, index: Int64, count: Int64): Float64 {
    if (count <= 1) {
        return range.center()
    }
    range.low + range.span() * Float64(index) / Float64(count - 1)
}

/** Half a cell's extent, so cells drawn at their centres tile without overlapping. */
func halfCell(range: Bounds, count: Int64): Float64 {
    if (count <= 1) {
        return maxOf(range.span() / 2.0, 0.5)
    }
    range.span() / Float64(count - 1) / 2.0
}
