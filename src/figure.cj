package plot

import std.collection.ArrayList
import sdl.{FontStyle, Rect}
import plot.axes.{Axes, Panel}
import plot.canvas.{Canvas, HAlign, VAlign}
import plot.core.{PlotException, Theme}

/** Outer figure margins and title spacing, in logical pixels. */
const FIGURE_PADDING: Float32 = 8.0
const FIGURE_TITLE_GAP: Float32 = 4.0

/**
 * The top-level drawing: a title, a theme, and a grid of panels.
 *
 * A figure with one panel is the common case and `Figure.single` builds it in a line. Multi-panel
 * figures lay out on a `rows x columns` grid, filling row by row.
 *
 * ```
 * let figure = Figure("Measurements")
 * let axes = figure.addAxes()
 * axes.line(xs, ys, label: "run 1")
 * ```
 *
 * A figure is pure description — it holds no window, no renderer, and no GPU resource — which is
 * what lets the same figure be shown interactively and exported to a file at a different size.
 */
public class Figure {
    /** The heading drawn across the top of the figure; empty draws none. */
    public var title: String = ""

    /** A smaller line under the title. */
    public var subtitle: String = ""

    /** Colours, type sizes, and palette for every panel. */
    public var theme: Theme = Theme.light()

    private let panels = ArrayList<Panel>()
    private var gridRows: Int64 = 1
    private var gridColumns: Int64 = 1

    public init() {}

    public init(title: String) {
        this.title = title
    }

    /** A figure holding one cartesian panel, returned ready to receive series. */
    public static func single(title!: String = ""): (Figure, Axes) {
        let figure = Figure(title)
        (figure, figure.addAxes())
    }

    /** Adds a cartesian panel and returns it. */
    public func addAxes(): Axes {
        let axes = Axes()
        panels.add(axes)
        reflowGrid()
        axes
    }

    /** Adds a panel of any kind — a `PieAxes` or `RadarAxes` as readily as an `Axes`. */
    public func addPanel(panel: Panel): Panel {
        panels.add(panel)
        reflowGrid()
        panel
    }

    /**
     * Arranges panels on an explicit grid, filled row by row.
     *
     * Throws `PlotException` for a non-positive dimension, or when the grid cannot hold the panels
     * already added — silently dropping a panel would be worse than refusing.
     */
    public func setGrid(rows: Int64, columns: Int64): Unit {
        if (rows < 1 || columns < 1) {
            throw PlotException("Figure grid needs positive dimensions; got ${rows}x${columns}.")
        }
        if (rows * columns < panels.size) {
            throw PlotException("Figure grid ${rows}x${columns} cannot hold ${panels.size} panels.")
        }
        gridRows = rows
        gridColumns = columns
    }

    /** The panels, in draw order. */
    public func allPanels(): ArrayList<Panel> {
        panels
    }

    /** The panel count. */
    public func panelCount(): Int64 {
        panels.size
    }

    /**
     * The panel at a pixel, for routing interaction. `None` when the pixel is outside every panel.
     */
    public func panelAt(px: Float32, py: Float32): ?Panel {
        for (panel in panels) {
            if (panel.containsPixel(px, py)) {
                return Some(panel)
            }
        }
        None
    }

    /**
     * Renders the whole figure into `rect`.
     *
     * This is the single entry point for both the live window and image export, which is why the
     * saved file always matches the screen: they call the same function with a different rectangle.
     */
    public func draw(canvas: Canvas, rect: Rect): Unit {
        canvas.fillRect(rect, theme.background)
        let body = layoutHeader(canvas, rect)
        if (panels.isEmpty()) {
            return
        }
        let cellWidth = body.w / Float32(gridColumns)
        let cellHeight = body.h / Float32(gridRows)
        for (i in 0..panels.size) {
            let row = i / gridColumns
            let column = i % gridColumns
            let cell = Rect(body.x + Float32(column) * cellWidth, body.y + Float32(row) * cellHeight, cellWidth,
                cellHeight)
            panels[i].draw(canvas, cell, theme)
        }
    }

    // Draws the title block and returns the rectangle left for panels.
    private func layoutHeader(canvas: Canvas, rect: Rect): Rect {
        let area = rect.inset(FIGURE_PADDING)
        var top = area.y
        if (!title.isEmpty()) {
            canvas.textAnchored(title, area.centerX(), top, theme.text, size: theme.titleSize, hAlign: HAlign.Center,
                vAlign: VAlign.Top, style: FontStyle.regular.withBold())
            top += canvas.textHeight(size: theme.titleSize) + FIGURE_TITLE_GAP
        }
        if (!subtitle.isEmpty()) {
            canvas.textAnchored(subtitle, area.centerX(), top, theme.mutedText, size: theme.subtitleSize,
                hAlign: HAlign.Center, vAlign: VAlign.Top)
            top += canvas.textHeight(size: theme.subtitleSize) + FIGURE_TITLE_GAP
        }
        if (top > area.y) {
            top += FIGURE_TITLE_GAP
        }
        Rect(area.x, top, area.w, maxF(1.0, area.bottom() - top))
    }

    /*
     * Keeps the grid able to hold every panel. Only grows the implicit grid — an explicit `setGrid`
     * is a layout decision and stays put unless it would drop a panel.
     */
    private func reflowGrid(): Unit {
        if (gridRows * gridColumns >= panels.size) {
            return
        }
        // Prefer wide-ish layouts: 2 panels side by side, 4 as 2x2, 6 as 2x3.
        var columns = 1
        while (columns * columns < panels.size) {
            columns += 1
        }
        var rows = panels.size / columns
        if (rows * columns < panels.size) {
            rows += 1
        }
        gridColumns = columns
        gridRows = rows
    }
}

func maxF(a: Float32, b: Float32): Float32 {
    if (a > b) {
        a
    } else {
        b
    }
}
