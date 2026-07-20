package plot.ui

import sdl.{Pen, Rect, Size, UiEvent}
import plot.axes.Axes
import plot.canvas.{Canvas, HAlign, MarkerStyle, VAlign}
import plot.core.{Colors, NumberFormat, Theme}
import plot.series.HitResult

/** Readout geometry, in logical pixels. */
const READOUT_PADDING: Float32 = 8.0
const READOUT_GAP: Float32 = 12.0
const HIT_RADIUS: Float32 = 28.0

/**
 * The hover inspector: a crosshair through the cursor, a highlight on the nearest data point, and a
 * chip naming its value.
 *
 * Snapping to the nearest point rather than reporting the raw cursor position is the whole value of
 * this: a reading of "3.97, 1.02" when the sample is at exactly (4, 1) is noise. `HIT_RADIUS`
 * bounds the snap so the chip disappears in empty regions instead of pointing at something far away.
 */
public class HoverReadout {
    /** Draws the crosshair lines through the cursor. */
    public var showCrosshair: Bool = true

    /** Draws the value chip for the snapped point. */
    public var showChip: Bool = true

    /** Highlights the snapped point with a ring. */
    public var showHighlight: Bool = true

    /** How near the cursor a point must be, in pixels, to be reported. */
    public var hitRadius: Float32 = HIT_RADIUS

    private var cursorX: Float32 = 0.0
    private var cursorY: Float32 = 0.0
    private var inside = false

    public init() {}

    /** Records the cursor. Returns true when the frame needs a redraw. */
    public func handle(event: UiEvent, axes: Axes): Bool {
        match (event) {
            case UiEvent.MouseMove(x, y) =>
                let nowInside = axes.dataArea().contains(x, y)
                let moved = nowInside || inside
                cursorX = x
                cursorY = y
                inside = nowInside
                moved
            case _ => false
        }
    }

    /** Forgets the cursor, e.g. when the pointer leaves the panel. */
    public func clear(): Unit {
        inside = false
    }

    /** Draws the crosshair, highlight, and chip over `axes`. */
    public func draw(canvas: Canvas, axes: Axes, theme: Theme): Unit {
        if (!inside) {
            return
        }
        let area = axes.dataArea()
        if (showCrosshair) {
            let pen = Pen(width: 1.0, color: Colors.fade(theme.accent, 0.45))
            canvas.line(area.x, cursorY, area.right(), cursorY, pen)
            canvas.line(cursorX, area.y, cursorX, area.bottom(), pen)
        }
        let hit = match (axes.hitTest(cursorX, cursorY, theme)) {
            case Some(result) where result.distance <= hitRadius => result
            case _ => return
        }
        if (showHighlight) {
            canvas.marker(MarkerStyle.Circle, hit.pixelX, hit.pixelY, 5.0, Colors.fade(hit.color, 0.28))
            canvas.marker(MarkerStyle.Ring, hit.pixelX, hit.pixelY, 4.5, hit.color,
                edge: Some(Pen(width: 1.8, color: hit.color)))
        }
        if (showChip) {
            drawChip(canvas, area, hit, theme)
        }
    }

    private func drawChip(canvas: Canvas, area: Rect, hit: HitResult, theme: Theme): Unit {
        let text = if (hit.label.isEmpty()) {
            hit.text
        } else {
            "${hit.label}  ${hit.text}"
        }
        let textWidth = canvas.textWidth(text, size: theme.annotationSize)
        let textHeight = canvas.textHeight(size: theme.annotationSize)
        let swatch = 7.0f32
        let width = textWidth + READOUT_PADDING * 2.0 + swatch + 6.0
        let height = textHeight + READOUT_PADDING
        // Place the chip clear of the point, then keep it inside the panel — a chip clipped at the
        // edge is exactly where the interesting data usually is.
        var x = hit.pixelX + READOUT_GAP
        var y = hit.pixelY - height - READOUT_GAP / 2.0
        if (x + width > area.right()) {
            x = hit.pixelX - width - READOUT_GAP
        }
        if (y < area.y) {
            y = hit.pixelY + READOUT_GAP
        }
        x = clampF(x, area.x, area.right() - width)
        y = clampF(y, area.y, area.bottom() - height)
        let frame = Rect(x, y, width, height)
        canvas.fillRoundedRect(frame, 5.0, tooltipSurface(theme))
        canvas.fillCircle(x + READOUT_PADDING + swatch / 2.0, frame.centerY(), swatch / 2.0, hit.color)
        canvas.textAnchored(text, x + READOUT_PADDING + swatch + 6.0, frame.centerY(), tooltipText(theme),
            size: theme.annotationSize, hAlign: HAlign.Left, vAlign: VAlign.Middle)
    }
}

/**
 * A status line reporting the cursor's position in data coordinates.
 *
 * Complements `HoverReadout`: that one snaps to data, this one reports where the pointer actually
 * is, which is what you want when reading off a region rather than a sample.
 */
public class CursorStatus <: Component {
    private var dock: Placement = Placement.BottomRight
    private var text: String = ""

    /** A prefix, e.g. the axis names. */
    public var prefix: String = ""

    public init() {
        super()
    }

    public init(placement: Placement) {
        super()
        this.dock = placement
    }

    public override func placement(): Placement {
        dock
    }

    /** Updates the reading from the cursor over `axes`. Returns true when the text changed. */
    public func update(event: UiEvent, axes: Axes): Bool {
        match (event) {
            case UiEvent.MouseMove(x, y) =>
                let next = if (axes.dataArea().contains(x, y)) {
                    let projection = axes.projection()
                    "${prefix}${NumberFormat.compact(projection.dataX(x))}, ${NumberFormat.compact(projection.dataY(y))}"
                } else {
                    ""
                }
                let changed = next != text
                text = next
                changed
            case _ => false
        }
    }

    public func measure(canvas: Canvas, theme: Theme): Size {
        if (text.isEmpty()) {
            return Size.zero()
        }
        Size(canvas.textWidth(text, size: theme.annotationSize) + READOUT_PADDING * 2.0,
            canvas.textHeight(size: theme.annotationSize) + READOUT_PADDING)
    }

    public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        setFrame(rect)
        if (text.isEmpty()) {
            return
        }
        canvas.fillRoundedRect(rect, 5.0, Colors.fade(theme.surface, 0.9))
        canvas.strokeRoundedRect(rect, 5.0, Pen(width: 1.0, color: theme.border))
        canvas.textAnchored(text, rect.centerX(), rect.centerY(), theme.mutedText, size: theme.annotationSize,
            hAlign: HAlign.Center, vAlign: VAlign.Middle)
    }
}
