package plot.ui

import std.collection.ArrayList
import std.math.{cos, sin}
import sdl.{Color, Pen, Point, Rect}
import plot.canvas.Canvas

/** Full turn in radians, for the icons drawn from arcs. */
const ICON_TAU: Float64 = 6.283185307179586

/**
 * The glyphs a toolbar button can show.
 *
 * These are drawn from primitives rather than loaded from a font or an image: an icon font would be
 * another deployment artifact to ship and keep in sync, and these are simple enough that stroking
 * them keeps the toolbar sharp at any scale and recoloured by the theme for free.
 */
public enum ToolIcon {
    /** A download arrow into a tray — save to a file. */
    | Save

    /** A magnifier with a plus. */
    | ZoomIn

    /** A magnifier with a minus. */
    | ZoomOut

    /** A four-way arrow — drag to pan. */
    | Pan

    /** A dashed rectangle — drag to zoom into a region. */
    | BoxZoom

    /** A house — restore the original view. */
    | Home

    /** A hash — toggle gridlines. */
    | Grid

    /** Stacked rows — toggle the legend. */
    | LegendIcon

    /** A half-filled circle — switch light/dark. */
    | ThemeIcon

    /** A crosshair — toggle the hover readout. */
    | Crosshair
}

/**
 * Draws `icon` centred in `rect`, stroked in `color`.
 *
 * `rect` is the icon's bounding box; each glyph insets itself so strokes stay inside it.
 */
public func drawToolIcon(canvas: Canvas, icon: ToolIcon, rect: Rect, color: Color, weight!: Float32 = 1.6): Unit {
    let box = rect.inset(rect.w * 0.18)
    let pen = Pen(width: weight, color: color)
    match (icon) {
        case Save => drawSave(canvas, box, pen, color)
        case ZoomIn => drawMagnifier(canvas, box, pen, 1)
        case ZoomOut => drawMagnifier(canvas, box, pen, -1)
        case Pan => drawPan(canvas, box, pen)
        case BoxZoom => drawBoxZoom(canvas, box, pen, color)
        case Home => drawHome(canvas, box, pen)
        case Grid => drawGrid(canvas, box, pen)
        case LegendIcon => drawLegendGlyph(canvas, box, pen, color)
        case ThemeIcon => drawTheme(canvas, box, pen, color)
        case Crosshair => drawCrosshair(canvas, box, pen)
    }
}

private func drawSave(canvas: Canvas, box: Rect, pen: Pen, color: Color): Unit {
    let cx = box.centerX()
    let arrowBottom = box.y + box.h * 0.62
    canvas.line(cx, box.y, cx, arrowBottom, pen)
    // The arrowhead, as two strokes meeting at the shaft's tip.
    let head = box.w * 0.22
    canvas.line(cx - head, arrowBottom - head, cx, arrowBottom, pen)
    canvas.line(cx + head, arrowBottom - head, cx, arrowBottom, pen)
    // The tray: an open-topped bracket, which reads as "into storage".
    let trayY = box.y + box.h * 0.78
    canvas.line(box.x, trayY, box.x, box.bottom(), pen)
    canvas.line(box.right(), trayY, box.right(), box.bottom(), pen)
    canvas.line(box.x, box.bottom(), box.right(), box.bottom(), Pen(width: pen.width, color: color))
}

private func drawMagnifier(canvas: Canvas, box: Rect, pen: Pen, sign: Int64): Unit {
    let radius = box.w * 0.33
    let cx = box.x + radius + box.w * 0.04
    let cy = box.y + radius + box.h * 0.04
    canvas.strokeCircle(cx, cy, radius, pen)
    // The handle runs outward along the 45-degree diagonal from the rim.
    let diagonal = radius * 0.707
    canvas.line(cx + diagonal, cy + diagonal, box.right(), box.bottom(), pen)
    let arm = radius * 0.5
    canvas.line(cx - arm, cy, cx + arm, cy, pen)
    if (sign > 0) {
        canvas.line(cx, cy - arm, cx, cy + arm, pen)
    }
}

private func drawPan(canvas: Canvas, box: Rect, pen: Pen): Unit {
    let cx = box.centerX()
    let cy = box.centerY()
    canvas.line(cx, box.y, cx, box.bottom(), pen)
    canvas.line(box.x, cy, box.right(), cy, pen)
    let head = box.w * 0.16
    // An arrowhead on each of the four ends.
    canvas.line(cx - head, box.y + head, cx, box.y, pen)
    canvas.line(cx + head, box.y + head, cx, box.y, pen)
    canvas.line(cx - head, box.bottom() - head, cx, box.bottom(), pen)
    canvas.line(cx + head, box.bottom() - head, cx, box.bottom(), pen)
    canvas.line(box.x + head, cy - head, box.x, cy, pen)
    canvas.line(box.x + head, cy + head, box.x, cy, pen)
    canvas.line(box.right() - head, cy - head, box.right(), cy, pen)
    canvas.line(box.right() - head, cy + head, box.right(), cy, pen)
}

private func drawBoxZoom(canvas: Canvas, box: Rect, pen: Pen, color: Color): Unit {
    canvas.renderer().strokeRoundedRectDashed(box, 2.0, pen, dash: 3.0, gap: 2.5)
    let inner = box.inset(box.w * 0.3)
    canvas.fillRoundedRect(inner, 1.5, color)
}

private func drawHome(canvas: Canvas, box: Rect, pen: Pen): Unit {
    let cx = box.centerX()
    let eaves = box.y + box.h * 0.45
    canvas.line(box.x, eaves, cx, box.y, pen)
    canvas.line(cx, box.y, box.right(), eaves, pen)
    let wallTop = eaves
    canvas.line(box.x + box.w * 0.14, wallTop, box.x + box.w * 0.14, box.bottom(), pen)
    canvas.line(box.right() - box.w * 0.14, wallTop, box.right() - box.w * 0.14, box.bottom(), pen)
    canvas.line(box.x + box.w * 0.14, box.bottom(), box.right() - box.w * 0.14, box.bottom(), pen)
}

private func drawGrid(canvas: Canvas, box: Rect, pen: Pen): Unit {
    for (i in 1..3) {
        let t = Float32(i) / 3.0
        canvas.line(box.x + box.w * t, box.y, box.x + box.w * t, box.bottom(), pen)
        canvas.line(box.x, box.y + box.h * t, box.right(), box.y + box.h * t, pen)
    }
}

private func drawLegendGlyph(canvas: Canvas, box: Rect, pen: Pen, color: Color): Unit {
    let rows = 3
    let gap = box.h / Float32(rows)
    for (i in 0..rows) {
        let y = box.y + gap * (Float32(i) + 0.5)
        let chip = box.w * 0.26
        canvas.fillRoundedRect(Rect(box.x, y - 1.5, chip, 3.0), 1.5, color)
        canvas.line(box.x + chip + box.w * 0.14, y, box.right(), y, pen)
    }
}

private func drawTheme(canvas: Canvas, box: Rect, pen: Pen, color: Color): Unit {
    let radius = box.w * 0.42
    let cx = box.centerX()
    let cy = box.centerY()
    canvas.strokeCircle(cx, cy, radius, pen)
    // Half filled: the clearest two-state "light vs dark" mark at 16 px.
    let left = ArrayList<Point>()
    let right = ArrayList<Point>()
    let steps = 24
    for (i in 0..=steps) {
        let angle = ICON_TAU / 2.0 * Float64(i) / Float64(steps)
        let y = cy - Float32(cos(angle)) * radius
        left.add(Point(cx, y))
        right.add(Point(cx + Float32(sin(angle)) * radius, y))
    }
    canvas.fillBand(left, right, color)
}

private func drawCrosshair(canvas: Canvas, box: Rect, pen: Pen): Unit {
    let cx = box.centerX()
    let cy = box.centerY()
    canvas.strokeCircle(cx, cy, box.w * 0.28, pen)
    canvas.line(cx, box.y, cx, box.y + box.h * 0.18, pen)
    canvas.line(cx, box.bottom() - box.h * 0.18, cx, box.bottom(), pen)
    canvas.line(box.x, cy, box.x + box.w * 0.18, cy, pen)
    canvas.line(box.right() - box.w * 0.18, cy, box.right(), cy, pen)
}
