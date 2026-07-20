package plot.axes

import std.collection.ArrayList
import std.math.{cos, sin}
import sdl.{Color, FontStyle, Pen, Point, Rect}
import plot.canvas.{Canvas, HAlign, MarkerStyle, VAlign}
import plot.core.{Bounds, Colors, NumberFormat, PlotException, Theme, Ticks, isFinite}
import plot.series.LegendEntry

/** Layout spacing for the radar panel, in logical pixels. */
const RADAR_PADDING: Float32 = 16.0
const RADAR_TITLE_GAP: Float32 = 10.0
const SPOKE_LABEL_GAP: Float32 = 12.0

/** One radar trace: a value per spoke, plus its styling. */
public class RadarTrace {
    /** The value on each spoke, in spoke order. */
    public let values: Array<Float64>

    /** The legend label. */
    public var label: String

    /** An explicit colour; `None` takes the palette slot matching the trace's position. */
    public var color: ?Color = None

    /** Fill opacity of the enclosed polygon, `0..1`. Zero draws the outline only. */
    public var fillOpacity: Float64 = 0.2

    /** Outline width in logical pixels. */
    public var lineWidth: Float32 = 2.0

    /** The glyph at each vertex. */
    public var marker: MarkerStyle = MarkerStyle.Circle

    /** Whether this trace is drawn. */
    public var visible: Bool = true

    public init(values: Array<Float64>, label!: String = "") {
        this.values = values
        this.label = label
    }
}

/**
 * A radar (spider) chart: several variables on spokes radiating from a shared centre, with each
 * trace drawn as a closed polygon.
 *
 * Every spoke shares one radial scale, so the variables must be commensurable — normalise them
 * first if they are not, or the polygon's shape is an artifact of the units rather than the data.
 *
 * ```
 * let radar = RadarAxes(["speed", "power", "range", "cost", "weight"])
 * radar.add(RadarTrace([0.8, 0.6, 0.9, 0.4, 0.7], label: "model A"))
 * figure.addPanel(radar)
 * ```
 */
public class RadarAxes <: Panel {
    private let spokes: Array<String>
    private let traces = ArrayList<RadarTrace>()

    /** The radial range; `None` autoscales from zero to the largest value. */
    public var valueRange: ?Bounds = None

    /** How many concentric rings mark the radial scale. */
    public var rings: Int64 = 4

    /** Draws the polygonal grid rings. Circular rings would misrepresent the polygon geometry. */
    public var showGrid: Bool = true

    /** Draws the spokes themselves. */
    public var showSpokes: Bool = true

    /** Labels each ring with its value, along the first spoke. */
    public var showRingLabels: Bool = true

    /** The legend configuration. */
    public let legend: Legend = Legend()

    /**
     * Throws `PlotException` when fewer than three spokes are given — two spokes degenerate to a
     * line and cannot enclose an area.
     */
    public init(spokes: Array<String>) {
        super()
        if (spokes.size < 3) {
            throw PlotException("A radar chart needs at least three spokes; got ${spokes.size}.")
        }
        this.spokes = spokes
        this.legend.position = LegendPosition.OutsideRight
    }

    /**
     * Adds a trace.
     *
     * Throws `PlotException` when its value count does not match the spoke count.
     */
    public func add(trace: RadarTrace): RadarTrace {
        if (trace.values.size != spokes.size) {
            throw PlotException(
                "A radar trace needs one value per spoke: expected ${spokes.size}, got ${trace.values.size}.")
        }
        traces.add(trace)
        trace
    }

    /** The spoke names. */
    public func spokeNames(): Array<String> {
        spokes
    }

    /** The traces, in draw order. */
    public func allTraces(): ArrayList<RadarTrace> {
        traces
    }

    /** The radial range in use — pinned, or autoscaled from zero to a round tick past the peak. */
    public func resolvedRange(): Bounds {
        match (valueRange) {
            case Some(bounds) => return bounds
            case None => ()
        }
        var peak = 0.0
        for (trace in traces) {
            if (!trace.visible) {
                continue
            }
            for (value in trace.values) {
                if (isFinite(value) && value > peak) {
                    peak = value
                }
            }
        }
        if (peak <= 0.0) {
            return Bounds(0.0, 1.0)
        }
        // Radar rings read as a scale, so the outer ring should be a round number.
        Bounds(0.0, Ticks.nice(Bounds(0.0, peak)).high)
    }

    public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        lastRect = rect
        var area = rect.inset(RADAR_PADDING)
        if (!title.isEmpty()) {
            canvas.textAnchored(title, area.centerX(), area.y, theme.text, size: theme.titleSize, hAlign: HAlign.Center,
                vAlign: VAlign.Top, style: FontStyle.regular.withBold())
            let used = canvas.textHeight(size: theme.titleSize) + RADAR_TITLE_GAP
            area = Rect(area.x, area.y + used, area.w, area.h - used)
        }
        let entries = legendEntries(theme)
        let (legendW, legendH) = legend.measure(canvas, entries, theme)
        match (legend.position) {
            case OutsideRight => area = Rect(area.x, area.y, maxOf(1.0, area.w - legendW - RADAR_PADDING), area.h)
            case OutsideBottom => area = Rect(area.x, area.y, area.w, maxOf(1.0, area.h - legendH - RADAR_PADDING))
            case _ => ()
        }
        // Spoke labels sit outside the outermost ring and need room for the widest of them.
        let labelMargin = widestSpokeLabel(canvas, theme) + SPOKE_LABEL_GAP
        let radius = minOfF(area.w, area.h) / 2.0 - labelMargin
        if (radius <= 4.0) {
            return
        }
        let cx = area.centerX()
        let cy = area.centerY()
        let range = resolvedRange()
        drawGrid(canvas, cx, cy, radius, range, theme)
        drawSpokeLabels(canvas, cx, cy, radius, theme)
        for (i in 0..traces.size) {
            drawTrace(canvas, cx, cy, radius, range, i, theme)
        }
        drawLegend(canvas, rect, area, theme, entries)
    }

    /** The legend entries, one per labelled trace. */
    public func legendEntries(theme: Theme): Array<LegendEntry> {
        let result = ArrayList<LegendEntry>()
        for (i in 0..traces.size) {
            let trace = traces[i]
            if (trace.label.isEmpty()) {
                continue
            }
            let color = traceColor(i, theme)
            let alpha = trace.fillOpacity
            let width = trace.lineWidth
            result.add(
                LegendEntry(trace.label, color) {
                    canvas, swatch, _ =>
                        canvas.fillRoundedRect(swatch, 2.0, Colors.fade(color, alpha + 0.15))
                        canvas.line(swatch.x, swatch.centerY(), swatch.right(), swatch.centerY(),
                            Pen(width: width, color: color))
                }
            )
        }
        result.toArray()
    }

    /** Toggles trace `index`; returns true when the index was valid. */
    public func toggleTrace(index: Int64): Bool {
        if (index < 0 || index >= traces.size) {
            return false
        }
        traces[index].visible = !traces[index].visible
        true
    }

    private func drawGrid(canvas: Canvas, cx: Float32, cy: Float32, radius: Float32, range: Bounds, theme: Theme): Unit {
        if (showGrid) {
            let ringCount = if (rings < 1) {
                1
            } else {
                rings
            }
            for (r in 1..=ringCount) {
                let ringRadius = radius * Float32(r) / Float32(ringCount)
                // A polygonal ring, not a circle: the traces are polygons, and a circular
                // reference would sit outside their vertices and misstate the values between spokes.
                let ring = ArrayList<Point>()
                for (s in 0..spokes.size) {
                    ring.add(spokePoint(cx, cy, ringRadius, s))
                }
                ring.add(ring[0])
                canvas.polyline(ring, Pen(width: 1.0, color: theme.grid))
                if (showRingLabels) {
                    let value = range.low + range.span() * Float64(r) / Float64(ringCount)
                    canvas.textAnchored(NumberFormat.compact(value), cx + 4.0, cy - ringRadius, theme.mutedText,
                        size: theme.tickSize, hAlign: HAlign.Left, vAlign: VAlign.Middle)
                }
            }
        }
        if (showSpokes) {
            for (s in 0..spokes.size) {
                let end = spokePoint(cx, cy, radius, s)
                canvas.line(cx, cy, end.x, end.y, Pen(width: 1.0, color: theme.axis))
            }
        }
    }

    private func drawSpokeLabels(canvas: Canvas, cx: Float32, cy: Float32, radius: Float32, theme: Theme): Unit {
        for (s in 0..spokes.size) {
            let angle = spokeAngle(s)
            let dx = Float32(sin(angle))
            let dy = Float32(-cos(angle))
            let px = cx + dx * (radius + SPOKE_LABEL_GAP)
            let py = cy + dy * (radius + SPOKE_LABEL_GAP)
            // Anchor away from the centre so labels never overlap the chart.
            let hAlign = if (dx > 0.15) {
                HAlign.Left
            } else if (dx < -0.15) {
                HAlign.Right
            } else {
                HAlign.Center
            }
            let vAlign = if (dy > 0.15) {
                VAlign.Top
            } else if (dy < -0.15) {
                VAlign.Bottom
            } else {
                VAlign.Middle
            }
            canvas.textAnchored(spokes[s], px, py, theme.text, size: theme.legendSize, hAlign: hAlign, vAlign: vAlign)
        }
    }

    private func drawTrace(canvas: Canvas, cx: Float32, cy: Float32, radius: Float32, range: Bounds, index: Int64,
        theme: Theme): Unit {
        let trace = traces[index]
        if (!trace.visible) {
            return
        }
        let color = traceColor(index, theme)
        let vertices = ArrayList<Point>()
        for (s in 0..spokes.size) {
            let value = if (isFinite(trace.values[s])) {
                trace.values[s]
            } else {
                range.low
            }
            let t = if (range.span() > 0.0) {
                (value - range.low) / range.span()
            } else {
                0.0
            }
            vertices.add(spokePoint(cx, cy, radius * Float32(clampUnitF(t)), s))
        }
        if (trace.fillOpacity > 0.0) {
            // The polygon is star-shaped about the centre, so a fan fill from a centre-anchored
            // vertex list is exact — no general triangulation needed.
            let fan = ArrayList<Point>()
            fan.add(Point(cx, cy))
            for (vertex in vertices) {
                fan.add(vertex)
            }
            fan.add(vertices[0])
            canvas.fillPolygon(fan, Colors.fade(color, trace.fillOpacity))
        }
        let outline = ArrayList<Point>(vertices)
        outline.add(vertices[0])
        canvas.polyline(outline, Pen(width: trace.lineWidth, color: color))
        if (!trace.marker.isHidden()) {
            for (vertex in vertices) {
                canvas.marker(trace.marker, vertex.x, vertex.y, theme.markerSize, color)
            }
        }
    }

    private func drawLegend(canvas: Canvas, rect: Rect, area: Rect, theme: Theme, entries: Array<LegendEntry>): Unit {
        if (legend.isHidden() || entries.size == 0) {
            return
        }
        let (w, h) = legend.measure(canvas, entries, theme)
        let frame = match (legend.position) {
            case TopLeft => Rect(area.x, area.y, w, h)
            case TopRight => Rect(area.right() - w, area.y, w, h)
            case BottomLeft => Rect(area.x, area.bottom() - h, w, h)
            case BottomRight => Rect(area.right() - w, area.bottom() - h, w, h)
            case OutsideRight => Rect(area.right() + RADAR_PADDING, area.centerY() - h / 2.0, w, h)
            case OutsideBottom => Rect(area.centerX() - w / 2.0, rect.bottom() - RADAR_PADDING - h, w, h)
            case Hidden => return
        }
        let hidden = ArrayList<Bool>()
        for (trace in traces) {
            if (!trace.label.isEmpty()) {
                hidden.add(!trace.visible)
            }
        }
        legend.draw(canvas, frame, entries, theme, hidden.toArray())
    }

    private func spokeAngle(index: Int64): Float64 {
        FULL_TURN * Float64(index) / Float64(spokes.size)
    }

    private func spokePoint(cx: Float32, cy: Float32, radius: Float32, index: Int64): Point {
        let angle = spokeAngle(index)
        Point(cx + Float32(sin(angle)) * radius, cy - Float32(cos(angle)) * radius)
    }

    private func traceColor(index: Int64, theme: Theme): Color {
        match (traces[index].color) {
            case Some(color) => color
            case None => theme.palette.at(index)
        }
    }

    private func widestSpokeLabel(canvas: Canvas, theme: Theme): Float32 {
        var widest = 0.0f32
        for (name in spokes) {
            let width = canvas.textWidth(name, size: theme.legendSize)
            if (width > widest) {
                widest = width
            }
        }
        // Only the labels at the sides consume full width; halving avoids a needlessly small chart.
        widest / 2.0
    }
}
