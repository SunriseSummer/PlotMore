package plot.axes

import std.collection.ArrayList
import sdl.{Color, FontStyle, Pen, Rect}
import plot.canvas.{Canvas, HAlign, VAlign}
import plot.core.{Bounds, LinearScale, Projection, Scale, Theme, Tick}
import plot.series.{HitResult, LegendEntry, Series}

/** How a y-axis title is oriented. */
public enum LabelOrientation {
    /** Rotated 90° to read bottom-to-top beside the axis — the scientific convention. */
    | Vertical

    /** Characters stacked upright top-to-bottom beside the axis — the natural form for CJK. */
    | Stacked

    /** Laid out horizontally above the axis, dashboard style. */
    | Horizontal
}

/** Layout spacing, in logical pixels. */
const PANEL_PADDING: Float32 = 14.0
const TICK_LENGTH: Float32 = 5.0
const TICK_LABEL_GAP: Float32 = 7.0
const AXIS_LABEL_GAP: Float32 = 9.0
const TITLE_GAP: Float32 = 10.0
const LEGEND_INSET: Float32 = 10.0
const AUTOSCALE_HEADROOM: Float64 = 0.05
const COLOR_BAR_INSET: Float32 = 16.0

/**
 * A cartesian plotting panel: two scales, a stack of series, gridlines, ticks, and a legend.
 *
 * ```
 * let axes = Axes()
 * axes.title = "Signal"
 * axes.xLabel = "time (s)"
 * axes.yLabel = "amplitude"
 * axes.line(times, values, label: "channel 1")
 * ```
 *
 * ## Ranges
 *
 * By default each axis autoscales to the union of its visible series, rounded outward to whole
 * ticks so the axis ends on a label. `setXLimits`/`setYLimits` pin a range explicitly. Zoom and pan
 * write to a separate *view* range that overrides both and is cleared by `resetView`, so a user who
 * zooms and then resets lands back on the author's intent rather than on whatever the data was.
 */
public class Axes <: Panel {
    /** The x-axis title. */
    public var xLabel: String = ""

    /** The y-axis title. */
    public var yLabel: String = ""

    /**
     * How the y-axis title is oriented.
     *
     * `Vertical` (rotated 90°, reading bottom-to-top on the left) by default — the scientific
     * convention. `Horizontal` places the title above the axis, dashboard style; `Stacked` keeps
     * the glyphs upright in a top-to-bottom column, which is the natural vertical form for CJK.
     */
    public var yLabelOrientation: LabelOrientation = LabelOrientation.Vertical

    /** Draws gridlines at major ticks. */
    public var showGrid: Bool = true

    /** Draws fainter gridlines at minor ticks, when the scale produces any. */
    public var showMinorGrid: Bool = false

    /** Draws vertical gridlines (x ticks). */
    public var showGridX: Bool = true

    /** Draws horizontal gridlines (y ticks). */
    public var showGridY: Bool = true

    /** Draws the axis spines. */
    public var showSpines: Bool = true

    /** Draws tick marks outside the panel. */
    public var showTicks: Bool = true

    /** Draws tick labels. */
    public var showTickLabels: Bool = true

    /** The legend configuration. */
    public let legend: Legend = Legend()

    /**
     * Breathing room added around autoscaled data, as a fraction of the data span, so a peak at the
     * data's maximum is not bisected by the panel edge. Ignored when `niceRange` is on.
     */
    public var headroom: Float64 = AUTOSCALE_HEADROOM

    /**
     * Rounds autoscaled ranges outward to whole ticks, so each axis *ends* on a labelled tick.
     *
     * Off by default: rounding outward is a coarse operation — a 0..10 range with a step of 2 can
     * only grow to the next multiple of 2 — and stacking `headroom` on top of it pads twice. The
     * default instead pads by `headroom` and lets the ticks fall on round numbers *inside* the
     * range, which keeps the data filling the panel.
     */
    public var niceRange: Bool = false

    private var xScale: Scale = LinearScale()
    private var yScale: Scale = LinearScale()
    private var xLimits: ?Bounds = None
    private var yLimits: ?Bounds = None
    private var xView: ?Bounds = None
    private var yView: ?Bounds = None
    private let seriesList = ArrayList<Series>()
    private let annotations = ArrayList<Annotation>()
    private var plotRect: Rect = Rect.zero()
    private var bar: ?ColorBar = None

    public init() {
        super()
    }

    // --- composition -------------------------------------------------------------------------

    /**
     * Adds a series, assigning it the next palette slot. Returns the series so the caller can keep
     * configuring it.
     */
    public func add(series: Series): Series {
        series.setPaletteIndex(seriesList.size)
        seriesList.add(series)
        series
    }

    /** Adds an annotation drawn above the data. */
    public func annotate(annotation: Annotation): Annotation {
        annotations.add(annotation)
        annotation
    }

    /**
     * Attaches a colour bar, narrowing the plot area to make room. Needed whenever a series encodes
     * a quantity as colour — without it, nothing on the panel says what the colours mean.
     */
    public func setColorBar(colorBar: ColorBar): ColorBar {
        bar = Some(colorBar)
        colorBar
    }

    /** The attached colour bar, if any. */
    public func colorBar(): ?ColorBar {
        bar
    }

    /** The series in this panel, in draw order. */
    public func allSeries(): ArrayList<Series> {
        seriesList
    }

    /** Removes every series and annotation, keeping scales and styling. */
    public func clear(): Unit {
        seriesList.clear()
        annotations.clear()
    }

    // --- scales ------------------------------------------------------------------------------

    /** Replaces the x scale — pass a `LogScale` or `CategoryScale` to change axis behaviour. */
    public func setXScale(scale: Scale): Unit {
        xScale = scale
    }

    /** Replaces the y scale. */
    public func setYScale(scale: Scale): Unit {
        yScale = scale
    }

    /** The x scale. */
    public func x(): Scale {
        xScale
    }

    /** The y scale. */
    public func y(): Scale {
        yScale
    }

    /** Pins the x range, disabling autoscale for that axis. */
    public func setXLimits(bounds: Bounds): Unit {
        xLimits = Some(bounds)
    }

    /** Pins the y range. */
    public func setYLimits(bounds: Bounds): Unit {
        yLimits = Some(bounds)
    }

    /** Returns the x axis to autoscaling. */
    public func autoscaleX(): Unit {
        xLimits = None
    }

    /** Returns the y axis to autoscaling. */
    public func autoscaleY(): Unit {
        yLimits = None
    }

    /** Overrides both ranges — the write path for zoom and pan. */
    public func setView(xBounds: Bounds, yBounds: Bounds): Unit {
        xView = Some(xBounds)
        yView = Some(yBounds)
    }

    /** Drops any zoom/pan view, restoring the pinned or autoscaled ranges. */
    public func resetView(): Unit {
        xView = None
        yView = None
    }

    /** True when zoom or pan has overridden the ranges. */
    public func hasView(): Bool {
        xView.isSome() || yView.isSome()
    }

    /** The x range that would be drawn right now: view, else pinned limits, else autoscale. */
    public func effectiveXBounds(): Bounds {
        resolveBounds(xView, xLimits, true)
    }

    /** The y range that would be drawn right now. */
    public func effectiveYBounds(): Bounds {
        resolveBounds(yView, yLimits, false)
    }

    /** The plotting rectangle from the last draw — the region the data occupies. */
    public func dataArea(): Rect {
        plotRect
    }

    /** A projection for the last drawn layout, for hit tests between frames. */
    public func projection(): Projection {
        applyDomains()
        Projection(plotRect, xScale, yScale)
    }

    // --- drawing -----------------------------------------------------------------------------

    public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        lastRect = rect
        applyDomains()
        let entries = legendEntries(theme)
        plotRect = layout(canvas, rect, theme, entries)
        let projection = Projection(plotRect, xScale, yScale)

        drawPanelBackground(canvas, theme)
        drawGrid(canvas, projection, theme)
        drawSeries(canvas, projection, theme)
        drawAnnotations(canvas, projection, theme)
        drawSpines(canvas, theme)
        drawTicks(canvas, projection, theme)
        drawLabels(canvas, rect, theme)
        drawColorBar(canvas, theme)
        drawLegend(canvas, rect, theme, entries)
    }

    /** The nearest data point to a pixel across all visible series, for tooltips. */
    public func hitTest(px: Float32, py: Float32, theme: Theme): ?HitResult {
        if (!plotRect.contains(px, py)) {
            return None
        }
        let projection = projection()
        var best: ?HitResult = None
        var bestDistance = Float32.Max
        for (series in seriesList) {
            if (!series.visible) {
                continue
            }
            match (series.hitTest(px, py, projection, theme)) {
                case Some(hit) where hit.distance < bestDistance =>
                    bestDistance = hit.distance
                    best = Some(hit)
                case _ => ()
            }
        }
        best
    }

    /** The legend entries of every visible, labelled series. */
    public func legendEntries(theme: Theme): Array<LegendEntry> {
        let result = ArrayList<LegendEntry>()
        for (series in seriesList) {
            for (entry in series.legend(theme)) {
                result.add(entry)
            }
        }
        result.toArray()
    }

    /** Series whose legend entries are currently toggled off, aligned with `legendEntries`. */
    public func legendHiddenFlags(theme: Theme): Array<Bool> {
        let result = ArrayList<Bool>()
        for (series in seriesList) {
            for (_ in series.legend(theme)) {
                result.add(!series.visible)
            }
        }
        result.toArray()
    }

    /**
     * Toggles the series behind legend entry `index`. Returns true when something changed, so the
     * caller knows whether to redraw.
     */
    public func toggleLegendEntry(index: Int64, theme: Theme): Bool {
        var cursor = 0
        for (series in seriesList) {
            for (_ in series.legend(theme)) {
                if (cursor == index) {
                    series.visible = !series.visible
                    return true
                }
                cursor += 1
            }
        }
        false
    }

    // --- internals ---------------------------------------------------------------------------

    private func applyDomains(): Unit {
        xScale.setDomain(effectiveXBounds())
        yScale.setDomain(effectiveYBounds())
    }

    private func resolveBounds(view: ?Bounds, limits: ?Bounds, horizontal: Bool): Bounds {
        match (view) {
            case Some(bounds) => return bounds
            case None => ()
        }
        match (limits) {
            case Some(bounds) => return bounds
            case None => ()
        }
        autoBounds(horizontal)
    }

    /*
     * The union of every visible series' data range. Falls back to the scale's current domain when
     * nothing is plottable — an empty panel still needs an axis to draw, and inventing 0..1 would
     * silently contradict a caller who set a domain on the scale directly.
     */
    private func autoBounds(horizontal: Bool): Bounds {
        var result: ?Bounds = None
        var exact = false
        for (series in seriesList) {
            if (!series.visible) {
                continue
            }
            if (series.fillsExtent()) {
                exact = true
            }
            match (series.dataBounds()) {
                case Some((bx, by)) =>
                    let candidate = if (horizontal) {
                        bx
                    } else {
                        by
                    }
                    result = match (result) {
                        case Some(current) => Some(current.union(candidate))
                        case None => Some(candidate)
                    }
                case None => ()
            }
        }
        let scale = if (horizontal) {
            xScale
        } else {
            yScale
        }
        match (result) {
            case Some(bounds) =>
                let usable = bounds.nonDegenerate()
                // A series that tiles its rectangle (a heatmap, a contour) reports an exact extent,
                // and padding it would ring the field with background that reads as missing data.
                if (exact) {
                    return usable
                }
                // The scale decides how to open the range up, because what "5% headroom" means
                // depends on its geometry — additive on a linear axis, multiplicative on a log
                // axis, and nothing at all on a category axis.
                //
                // Exactly one of the two paddings applies. Rounding to whole ticks already opens the
                // range up to the next round number; adding `headroom` first would then push it a
                // further whole step, which is what leaves a 0..10 series sitting inside a -2..12 axis.
                if (niceRange) {
                    scale.niceBounds(usable)
                } else {
                    scale.padBounds(usable, headroom)
                }
            case None => scale.domain()
        }
    }

    /*
     * Carves the plot rectangle out of the panel: title on top, tick labels and axis titles on the
     * left and bottom, legend wherever it asked to be. Measured against the actual rendered text
     * rather than a guess, so a panel with wide tick labels ("1.25e+06") does not clip them.
     */
    private func layout(canvas: Canvas, rect: Rect, theme: Theme, entries: Array<LegendEntry>): Rect {
        var area = rect.inset(PANEL_PADDING)
        if (!title.isEmpty()) {
            area = Rect(area.x, area.y + canvas.textHeight(size: theme.titleSize) + TITLE_GAP, area.w,
                area.h - canvas.textHeight(size: theme.titleSize) - TITLE_GAP)
        }
        let (legendW, legendH) = legend.measure(canvas, entries, theme)
        match (legend.position) {
            case OutsideRight => area = Rect(area.x, area.y, maxOf(0.0, area.w - legendW - LEGEND_INSET), area.h)
            case OutsideBottom => area = Rect(area.x, area.y, area.w, maxOf(0.0, area.h - legendH - LEGEND_INSET))
            case _ => ()
        }

        var left = 0.0f32
        var bottom = 0.0f32
        // The right and top edges need room for the outermost tick label to overhang the corner.
        var right = 0.0f32
        var top = 0.0f32
        if (showTickLabels) {
            left += maxTickLabelWidth(canvas, yScale.ticks(), theme) + TICK_LABEL_GAP
            bottom += canvas.textHeight(size: theme.tickSize) + TICK_LABEL_GAP
            right += halfTickLabelWidth(canvas, xScale.ticks(), theme)
            top += canvas.textHeight(size: theme.tickSize) / 2.0
        }
        if (showTicks) {
            left += TICK_LENGTH
            bottom += TICK_LENGTH
        }
        if (!yLabel.isEmpty()) {
            match (yLabelOrientation) {
                case Vertical => left += yLabelExtent(canvas, theme) + AXIS_LABEL_GAP
                case Stacked => left += yLabelExtent(canvas, theme) + AXIS_LABEL_GAP
                case Horizontal => top += canvas.textHeight(size: theme.labelSize) + AXIS_LABEL_GAP
            }
        }
        if (!xLabel.isEmpty()) {
            bottom += canvas.textHeight(size: theme.labelSize) + AXIS_LABEL_GAP
        }
        match (bar) {
            case Some(colorBar) => match (colorBar.side) {
                case Right => right += colorBar.extent(canvas, theme)
                case Bottom => bottom += colorBar.extent(canvas, theme)
            }
            case None => ()
        }
        Rect(area.x + left, area.y + top, maxOf(1.0, area.w - left - right), maxOf(1.0, area.h - bottom - top))
    }

    private func drawPanelBackground(canvas: Canvas, theme: Theme): Unit {
        if (theme.panelFilled) {
            canvas.fillRoundedRect(plotRect, theme.cornerRadius / 2.0, theme.panel)
        }
    }

    private func drawGrid(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        if (!showGrid) {
            return
        }
        if (showGridY) {
            for (tick in yScale.ticks()) {
                let color = gridColor(tick, theme)
                if (!tick.major && !showMinorGrid) {
                    continue
                }
                let py = projection.pixelY(tick.value)
                canvas.line(plotRect.x, py, plotRect.right(), py, Pen(width: 1.0, color: color))
            }
        }
        if (showGridX) {
            for (tick in xScale.ticks()) {
                if (!tick.major && !showMinorGrid) {
                    continue
                }
                let color = gridColor(tick, theme)
                let px = projection.pixelX(tick.value)
                canvas.line(px, plotRect.y, px, plotRect.bottom(), Pen(width: 1.0, color: color))
            }
        }
    }

    private func gridColor(tick: Tick, theme: Theme): Color {
        if (tick.major) {
            theme.grid
        } else {
            theme.gridMinor
        }
    }

    private func drawSeries(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        // Data is clipped to the panel so a zoomed-in series cannot paint over the axes.
        canvas.pushClip(plotRect)
        try {
            for (series in seriesList) {
                if (series.visible) {
                    series.draw(canvas, projection, theme)
                }
            }
        } finally {
            canvas.popClip()
        }
    }

    private func drawAnnotations(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        if (annotations.isEmpty()) {
            return
        }
        canvas.pushClip(plotRect)
        try {
            for (annotation in annotations) {
                annotation.draw(canvas, projection, theme)
            }
        } finally {
            canvas.popClip()
        }
    }

    private func drawSpines(canvas: Canvas, theme: Theme): Unit {
        if (!showSpines) {
            return
        }
        let pen = Pen(width: 1.0, color: theme.axis)
        if (theme.panelBordered) {
            canvas.strokeRect(plotRect, pen)
        } else {
            canvas.line(plotRect.x, plotRect.bottom(), plotRect.right(), plotRect.bottom(), pen)
            canvas.line(plotRect.x, plotRect.y, plotRect.x, plotRect.bottom(), pen)
        }
    }

    private func drawTicks(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let pen = Pen(width: 1.0, color: theme.axis)
        for (tick in xScale.ticks()) {
            let px = projection.pixelX(tick.value)
            if (px < plotRect.x - 0.5 || px > plotRect.right() + 0.5) {
                continue
            }
            let length = tickLength(tick)
            if (showTicks) {
                canvas.line(px, plotRect.bottom(), px, plotRect.bottom() + length, pen)
            }
            if (showTickLabels && !tick.label.isEmpty()) {
                canvas.textAnchored(tick.label, px, plotRect.bottom() + length + TICK_LABEL_GAP, theme.mutedText,
                    size: theme.tickSize, hAlign: HAlign.Center, vAlign: VAlign.Top)
            }
        }
        for (tick in yScale.ticks()) {
            let py = projection.pixelY(tick.value)
            if (py < plotRect.y - 0.5 || py > plotRect.bottom() + 0.5) {
                continue
            }
            let length = tickLength(tick)
            if (showTicks) {
                canvas.line(plotRect.x - length, py, plotRect.x, py, pen)
            }
            if (showTickLabels && !tick.label.isEmpty()) {
                canvas.textAnchored(tick.label, plotRect.x - length - TICK_LABEL_GAP, py, theme.mutedText,
                    size: theme.tickSize, hAlign: HAlign.Right, vAlign: VAlign.Middle)
            }
        }
    }

    private func tickLength(tick: Tick): Float32 {
        if (tick.major) {
            TICK_LENGTH
        } else {
            TICK_LENGTH * 0.55
        }
    }

    private func drawLabels(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        if (!title.isEmpty()) {
            canvas.textAnchored(title, plotRect.centerX(), rect.y + PANEL_PADDING, theme.text, size: theme.titleSize,
                hAlign: HAlign.Center, vAlign: VAlign.Top, style: FontStyle.regular.withBold())
        }
        if (!xLabel.isEmpty()) {
            canvas.textAnchored(xLabel, plotRect.centerX(), rect.bottom() - PANEL_PADDING, theme.text,
                size: theme.labelSize, hAlign: HAlign.Center, vAlign: VAlign.Bottom)
        }
        if (yLabel.isEmpty()) {
            return
        }
        match (yLabelOrientation) {
            case Vertical => canvas.textRotated(yLabel, rect.x + PANEL_PADDING + yLabelExtent(canvas, theme) / 2.0,
                plotRect.centerY(), -90.0, theme.text, size: theme.labelSize)
            case Stacked =>
                let height = canvas.stackedTextHeight(yLabel, size: theme.labelSize)
                canvas.textStacked(yLabel, rect.x + PANEL_PADDING + yLabelExtent(canvas, theme) / 2.0,
                    plotRect.centerY() - height / 2.0, theme.text, size: theme.labelSize)
            case Horizontal => canvas.textAnchored(yLabel, plotRect.x, plotRect.y - TICK_LABEL_GAP, theme.text,
                size: theme.labelSize, hAlign: HAlign.Left, vAlign: VAlign.Bottom)
        }
    }

    private func drawColorBar(canvas: Canvas, theme: Theme): Unit {
        let colorBar = match (bar) {
            case Some(value) => value
            case None => return
        }
        // The bar hugs the plot rectangle on the side `layout` reserved for it.
        let frame = match (colorBar.side) {
            case Right => Rect(plotRect.right() + COLOR_BAR_INSET, plotRect.y, colorBar.thickness, plotRect.h)
            case Bottom => Rect(plotRect.x, plotRect.bottom() + COLOR_BAR_INSET, plotRect.w, colorBar.thickness)
        }
        colorBar.draw(canvas, frame, theme)
    }

    private func drawLegend(canvas: Canvas, rect: Rect, theme: Theme, entries: Array<LegendEntry>): Unit {
        if (legend.isHidden() || entries.size == 0) {
            return
        }
        let (w, h) = legend.measure(canvas, entries, theme)
        let frame = match (legend.position) {
            case TopLeft => Rect(plotRect.x + LEGEND_INSET, plotRect.y + LEGEND_INSET, w, h)
            case TopRight => Rect(plotRect.right() - w - LEGEND_INSET, plotRect.y + LEGEND_INSET, w, h)
            case BottomLeft => Rect(plotRect.x + LEGEND_INSET, plotRect.bottom() - h - LEGEND_INSET, w, h)
            case BottomRight => Rect(plotRect.right() - w - LEGEND_INSET, plotRect.bottom() - h - LEGEND_INSET, w, h)
            case OutsideRight => Rect(plotRect.right() + LEGEND_INSET, plotRect.y, w, h)
            case OutsideBottom => Rect(plotRect.centerX() - w / 2.0, rect.bottom() - PANEL_PADDING - h, w, h)
            case Hidden => return
        }
        legend.draw(canvas, frame, entries, theme, legendHiddenFlags(theme))
    }

    private func maxTickLabelWidth(canvas: Canvas, ticks: Array<Tick>, theme: Theme): Float32 {
        var width = 0.0f32
        for (tick in ticks) {
            if (!tick.label.isEmpty()) {
                width = maxOf(width, canvas.textWidth(tick.label, size: theme.tickSize))
            }
        }
        width
    }

    /*
     * Half the width of the *rightmost labelled* tick — the room its label needs to overhang the
     * panel's right edge.
     *
     * This has to search rather than take the last entry: a scale with minor divisions appends its
     * minors after its majors, so the final entry is normally an unlabelled minor. Measuring that
     * reserves nothing and clips the last x label off the panel.
     */
    private func halfTickLabelWidth(canvas: Canvas, ticks: Array<Tick>, theme: Theme): Float32 {
        var found = false
        var rightmost = 0.0
        var label = ""
        for (tick in ticks) {
            if (tick.label.isEmpty()) {
                continue
            }
            if (!found || tick.value > rightmost) {
                found = true
                rightmost = tick.value
                label = tick.label
            }
        }
        if (!found) {
            return 0.0
        }
        canvas.textWidth(label, size: theme.tickSize) / 2.0
    }

    private func yLabelExtent(canvas: Canvas, theme: Theme): Float32 {
        match (yLabelOrientation) {
            // A rotated title occupies one line height of width; a stacked one a glyph's width.
            case Vertical => canvas.textHeight(size: theme.labelSize)
            case Stacked => canvas.textWidth("国", size: theme.labelSize)
            case Horizontal => 0.0
        }
    }
}
