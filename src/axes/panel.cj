package plot.axes

import sdl.Rect
import plot.canvas.Canvas
import plot.core.Theme

/**
 * One self-contained plotting region inside a `Figure`.
 *
 * A figure lays panels out on a grid and hands each one a rectangle; what a panel does inside that
 * rectangle is entirely its own. This is the seam that lets a cartesian `Axes`, a `PieAxes`, and a
 * `RadarAxes` sit in the same figure despite having nothing in common geometrically — a pie has no
 * x scale to share, so forcing all three through one axes type would mean a cartesian API with half
 * its methods documented as "not meaningful here".
 */
public abstract class Panel {
    /** The heading drawn above the panel; empty draws none and reclaims the space. */
    public var title: String = ""

    // The rectangle from the last draw. Interaction arrives between frames and needs to know where
    // the panel actually landed, which only layout knows.
    protected var lastRect: Rect = Rect.zero()

    /** Renders the panel into `rect`. */
    public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit

    /** The rectangle this panel occupied when it was last drawn. */
    public func frame(): Rect {
        lastRect
    }

    /** True when `(px, py)` falls inside the panel's last frame. */
    public func containsPixel(px: Float32, py: Float32): Bool {
        lastRect.contains(px, py)
    }
}
