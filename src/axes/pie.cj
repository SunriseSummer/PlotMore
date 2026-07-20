package plot.axes

import std.collection.ArrayList
import std.math.{cos, sin}
import sdl.{Color, FontStyle, Pen, Rect}
import plot.canvas.{Canvas, HAlign, VAlign, WEDGE_EDGE_WIDTH}
import plot.core.{Colors, NumberFormat, PlotException, Theme, isFinite}
import plot.series.LegendEntry

/** Full turn in radians. Wedge angles are measured clockwise from twelve o'clock. */
const FULL_TURN: Float64 = 6.283185307179586

/** Layout spacing for the pie panel, in logical pixels. */
const PIE_PADDING: Float32 = 16.0
const PIE_TITLE_GAP: Float32 = 10.0
const LEADER_LENGTH: Float32 = 14.0

/** One slice of a pie: a magnitude, a name, and optional styling. */
public struct PieSlice {
    public let value: Float64
    public let label: String

    /** An explicit colour; `None` takes the palette slot matching the slice's position. */
    public let color: ?Color

    /** Pulls the slice out of the pie by this fraction of the radius, to call it out. */
    public let explode: Float64

    public init(value: Float64, label!: String = "", color!: ?Color = None, explode!: Float64 = 0.0) {
        this.value = value
        this.label = label
        this.color = color
        this.explode = explode
    }
}

/** What a slice's label shows. */
public enum PieLabelMode {
    /** The slice name only. */
    | Name

    /** The share of the total, as a percentage. */
    | Percent

    /** The raw value. */
    | Value

    /** Name and percentage. */
    | NameAndPercent

    /** No labels on the slices; use the legend instead. */
    | NoLabel
}

/**
 * A pie or donut chart.
 *
 * ```
 * let pie = PieAxes([
 *     PieSlice(42.0, label: "Chrome"),
 *     PieSlice(31.0, label: "Safari"),
 *     PieSlice(27.0, label: "Firefox")
 * ])
 * pie.innerRadius = 0.55   // a donut
 * figure.addPanel(pie)
 * ```
 *
 * ## A caveat worth knowing
 *
 * Pie charts encode magnitude as angle, which people compare far less accurately than length. A bar
 * chart is a better default for comparing categories. A pie earns its place when the message is
 * *part-of-whole* with a handful of slices — which is why `donutLabel` exists, to put the total in
 * the hole where it reads directly.
 */
public class PieAxes <: Panel {
    private let slices: Array<PieSlice>
    private var total: Float64 = 0.0

    /** Inner radius as a fraction of the outer, `0..1`. Zero is a pie; ~0.5-0.6 a donut. */
    public var innerRadius: Float64 = 0.0

    /** Where the first slice starts, in radians clockwise from twelve o'clock. */
    public var startAngle: Float64 = 0.0

    /** What each slice's label shows. */
    public var labelMode: PieLabelMode = PieLabelMode.NameAndPercent

    /** Places labels outside the ring with leader lines, instead of inside the slices. */
    public var labelsOutside: Bool = false

    /** Slices below this share of the total go unlabelled, since the text would not fit. */
    public var labelThreshold: Float64 = 0.03

    /** Decimal places on percentage labels. */
    public var percentDecimals: Int64 = 0

    /** Pixel gap between neighbouring slices; a small gap reads as separation without borders. */
    public var sliceGap: Float32 = 1.5

    /** A caption drawn in a donut's hole — the natural spot for the total. Ignored for a pie. */
    public var donutLabel: String = ""

    /** A smaller second line under `donutLabel`. */
    public var donutSublabel: String = ""

    /** The legend configuration. */
    public let legend: Legend = Legend()

    /**
     * Throws `PlotException` when `slices` is empty, when any value is negative (an angle cannot
     * represent it), or when the values sum to zero (there is no whole to take parts of).
     */
    public init(slices: Array<PieSlice>) {
        super()
        if (slices.size == 0) {
            throw PlotException("A pie chart needs at least one slice.")
        }
        var sum = 0.0
        for (i in 0..slices.size) {
            let value = slices[i].value
            if (!isFinite(value)) {
                throw PlotException("Pie slice ${i} ('${slices[i].label}') is not a finite value.")
            }
            if (value < 0.0) {
                throw PlotException(
                    "Pie slice ${i} ('${slices[i].label}') is negative (${value}). A pie encodes parts of a " +
                        "whole as angles, which cannot represent a negative share; use a bar chart.")
            }
            sum += value
        }
        if (sum <= 0.0) {
            throw PlotException("Pie slice values sum to zero, so there are no proportions to draw.")
        }
        this.slices = slices
        this.total = sum
        this.legend.position = LegendPosition.OutsideRight
    }

    /** The slices, in draw order. */
    public func allSlices(): Array<PieSlice> {
        slices
    }

    /** The sum of every slice value. */
    public func sum(): Float64 {
        total
    }

    /** The share of the total held by slice `index`, `0..1`. */
    public func fraction(index: Int64): Float64 {
        slices[index].value / total
    }

    public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        lastRect = rect
        var area = rect.inset(PIE_PADDING)
        if (!title.isEmpty()) {
            canvas.textAnchored(title, area.centerX(), area.y, theme.text, size: theme.titleSize, hAlign: HAlign.Center,
                vAlign: VAlign.Top, style: FontStyle.regular.withBold())
            let used = canvas.textHeight(size: theme.titleSize) + PIE_TITLE_GAP
            area = Rect(area.x, area.y + used, area.w, area.h - used)
        }
        let entries = legendEntries(theme)
        let (legendW, legendH) = legend.measure(canvas, entries, theme)
        match (legend.position) {
            case OutsideRight => area = Rect(area.x, area.y, maxOf(1.0, area.w - legendW - PIE_PADDING), area.h)
            case OutsideBottom => area = Rect(area.x, area.y, area.w, maxOf(1.0, area.h - legendH - PIE_PADDING))
            case _ => ()
        }
        // Outside labels need a margin all round for the text and its leader line.
        let margin = if (labelsOutside && !isLabelHidden()) {
            LEADER_LENGTH + canvas.textWidth("100%", size: theme.legendSize)
        } else {
            0.0f32
        }
        let radius = minOfF(area.w, area.h) / 2.0 - margin
        if (radius <= 2.0) {
            return
        }
        let cx = area.centerX()
        let cy = area.centerY()
        drawSlices(canvas, cx, cy, radius, theme)
        drawDonutCaption(canvas, cx, cy, radius, theme)
        drawLegend(canvas, rect, area, theme, entries)
    }

    /** The legend entries, one per named slice. */
    public func legendEntries(theme: Theme): Array<LegendEntry> {
        let result = ArrayList<LegendEntry>()
        for (i in 0..slices.size) {
            if (slices[i].label.isEmpty()) {
                continue
            }
            let color = sliceColor(i, theme)
            result.add(LegendEntry(slices[i].label, color) {
                canvas, rect, _ => canvas.fillRoundedRect(rect, 2.0, color)
            })
        }
        result.toArray()
    }

    private func drawSlices(canvas: Canvas, cx: Float32, cy: Float32, radius: Float32, theme: Theme): Unit {
        let inner = Float32(clampUnitF(innerRadius)) * radius
        var angle = startAngle
        for (i in 0..slices.size) {
            let sweep = fraction(i) * FULL_TURN
            // Convert the pixel gap to an angle at this radius, and never let it eat the whole
            // slice — a hairline sliver must still be visible. The smoothing stroke each wedge
            // traces around itself straddles the boundary, so one full stroke width is added on
            // top of the requested gap to keep `sliceGap` meaning the *visible* separation.
            let effectiveGap = Float64(sliceGap + WEDGE_EDGE_WIDTH)
            let gapAngle = if (radius > 0.0) {
                minOf(effectiveGap / Float64(radius), sweep * 0.25)
            } else {
                0.0
            }
            let (ox, oy) = explodeOffset(i, angle + sweep / 2.0, radius)
            canvas.fillWedge(cx + ox, cy + oy, inner, radius, angle + gapAngle / 2.0, angle + sweep - gapAngle / 2.0,
                sliceColor(i, theme))
            drawSliceLabel(canvas, cx + ox, cy + oy, inner, radius, angle + sweep / 2.0, i, theme)
            angle += sweep
        }
    }

    private func drawSliceLabel(
        canvas: Canvas,
        cx: Float32,
        cy: Float32,
        inner: Float32,
        radius: Float32,
        midAngle: Float64,
        index: Int64,
        theme: Theme
    ): Unit {
        let share = fraction(index)
        if (isLabelHidden() || share < labelThreshold) {
            return
        }
        let text = labelText(index)
        if (text.isEmpty()) {
            return
        }
        let dx = Float32(sin(midAngle))
        let dy = Float32(-cos(midAngle))
        if (labelsOutside) {
            let from = radius
            let to = radius + LEADER_LENGTH
            canvas.line(cx + dx * from, cy + dy * from, cx + dx * to, cy + dy * to, Pen(width: 1.0, color: theme.axis))
            // Flip the anchor across the vertical so labels read outward on both sides.
            let align = if (dx >= 0.0) {
                HAlign.Left
            } else {
                HAlign.Right
            }
            let nudge = if (dx >= 0.0) {
                4.0f32
            } else {
                -4.0f32
            }
            canvas.textAnchored(text, cx + dx * to + nudge, cy + dy * to, theme.text, size: theme.legendSize,
                hAlign: align, vAlign: VAlign.Middle)
        } else {
            let mid = (inner + radius) / 2.0
            let fill = sliceColor(index, theme)
            canvas.textAnchored(text, cx + dx * mid, cy + dy * mid, Colors.contrastText(fill), size: theme.legendSize,
                hAlign: HAlign.Center, vAlign: VAlign.Middle)
        }
    }

    private func drawDonutCaption(canvas: Canvas, cx: Float32, cy: Float32, radius: Float32, theme: Theme): Unit {
        if (donutLabel.isEmpty() || innerRadius <= 0.05) {
            return
        }
        let hasSub = !donutSublabel.isEmpty()
        let offset = if (hasSub) {
            canvas.textHeight(size: theme.titleSize) / 2.0
        } else {
            0.0f32
        }
        canvas.textAnchored(donutLabel, cx, cy - offset, theme.text, size: theme.titleSize, hAlign: HAlign.Center,
            vAlign: VAlign.Middle, style: FontStyle.regular.withBold())
        if (hasSub) {
            canvas.textAnchored(donutSublabel, cx, cy + offset, theme.mutedText, size: theme.legendSize,
                hAlign: HAlign.Center, vAlign: VAlign.Middle)
        }
        let _ = radius
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
            case OutsideRight => Rect(area.right() + PIE_PADDING, area.centerY() - h / 2.0, w, h)
            case OutsideBottom => Rect(area.centerX() - w / 2.0, rect.bottom() - PIE_PADDING - h, w, h)
            case Hidden => return
        }
        legend.draw(canvas, frame, entries, theme, Array<Bool>(entries.size, repeat: false))
    }

    private func explodeOffset(index: Int64, midAngle: Float64, radius: Float32): (Float32, Float32) {
        let amount = slices[index].explode
        if (amount <= 0.0) {
            return (0.0, 0.0)
        }
        let distance = Float32(amount) * radius
        (Float32(sin(midAngle)) * distance, Float32(-cos(midAngle)) * distance)
    }

    private func sliceColor(index: Int64, theme: Theme): Color {
        match (slices[index].color) {
            case Some(color) => color
            case None => theme.palette.at(index)
        }
    }

    private func labelText(index: Int64): String {
        let share = fraction(index)
        match (labelMode) {
            case Name => slices[index].label
            case Percent => NumberFormat.percent(share, decimals: percentDecimals)
            case Value => NumberFormat.compact(slices[index].value)
            case NameAndPercent =>
                let percent = NumberFormat.percent(share, decimals: percentDecimals)
                if (slices[index].label.isEmpty()) {
                    percent
                } else {
                    "${slices[index].label} ${percent}"
                }
            case NoLabel => ""
        }
    }

    private func isLabelHidden(): Bool {
        match (labelMode) {
            case NoLabel => true
            case _ => false
        }
    }
}

func clampUnitF(value: Float64): Float64 {
    if (value < 0.0) {
        0.0
    } else if (value > 1.0) {
        1.0
    } else {
        value
    }
}

func minOf(a: Float64, b: Float64): Float64 {
    if (a < b) {
        a
    } else {
        b
    }
}

func minOfF(a: Float32, b: Float32): Float32 {
    if (a < b) {
        a
    } else {
        b
    }
}
