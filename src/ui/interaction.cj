package plot.ui

import sdl.{MouseButton, Pen, Rect, UiEvent}
import plot.axes.Axes
import plot.canvas.Canvas
import plot.core.{Bounds, Colors, Theme}

/** What a drag on the plot area does. */
public enum InteractionMode {
    /** Dragging pans; the wheel zooms. The default. */
    | PanZoom

    /** Dragging draws a rectangle and zooms to it on release. */
    | BoxZoom

    /** Dragging does nothing. */
    | Inspect
}

/** How fast one wheel notch zooms. 1.15 is a comfortable ~13% step. */
const WHEEL_ZOOM_STEP: Float64 = 1.15

/**
 * Zoom, pan, and box-zoom over a cartesian panel.
 *
 * All of it works by rewriting the axes' *view* bounds and nothing else, which is why it composes
 * with every chart type for free: a series draws through the projection, and the projection reads
 * the view. `reset` drops the view and the axes fall back to the author's limits or to autoscale.
 *
 * Zoom is anchored at the cursor — the data under the pointer stays under the pointer — because
 * zooming about the panel centre makes it impossible to magnify a corner.
 */
public class Interactions {
    /** What dragging does. */
    public var mode: InteractionMode = InteractionMode.PanZoom

    /** Enables wheel zoom. */
    public var wheelZoom: Bool = true

    /** Enables drag-to-pan in `PanZoom` mode. */
    public var dragPan: Bool = true

    /** Constrains zoom and pan to the x axis — the right choice for time series. */
    public var lockY: Bool = false

    /** Constrains zoom and pan to the y axis. */
    public var lockX: Bool = false

    private var dragging = false
    private var dragStartX: Float32 = 0.0
    private var dragStartY: Float32 = 0.0
    private var dragCurrentX: Float32 = 0.0
    private var dragCurrentY: Float32 = 0.0
    private var dragStartXBounds: Bounds = Bounds(0.0, 1.0)
    private var dragStartYBounds: Bounds = Bounds(0.0, 1.0)

    public init() {}

    /** True while a box-zoom rectangle is being dragged, so the window knows to draw it. */
    public func isBoxing(): Bool {
        dragging && isBoxMode()
    }

    /** The box-zoom rectangle currently being dragged. */
    public func boxRect(): Rect {
        let x = minF(dragStartX, dragCurrentX)
        let y = minF(dragStartY, dragCurrentY)
        Rect(x, y, absF32(dragCurrentX - dragStartX), absF32(dragCurrentY - dragStartY))
    }

    /**
     * Routes an event to `axes`. Returns true when the view changed and the window should redraw.
     */
    public func handle(event: UiEvent, axes: Axes): Bool {
        match (event) {
            case UiEvent.MouseWheel(_, dy, x, y) => handleWheel(dy, x, y, axes)
            case UiEvent.MouseDown(button, x, y) => match (button) {
                case MouseButton.Left => beginDrag(x, y, axes)
                case _ => false
            }
            case UiEvent.MouseMove(x, y) => continueDrag(x, y, axes)
            case UiEvent.MouseUp(button, x, y) => match (button) {
                case MouseButton.Left => endDrag(x, y, axes)
                case _ => false
            }
            case _ => false
        }
    }

    /** Draws the box-zoom rectangle. Called by the window while a box drag is live. */
    public func drawOverlay(canvas: Canvas, theme: Theme): Unit {
        if (!isBoxing()) {
            return
        }
        let rect = boxRect()
        if (rect.w < 1.0 || rect.h < 1.0) {
            return
        }
        canvas.fillRect(rect, Colors.fade(theme.accent, 0.12))
        canvas.renderer().strokeRoundedRectDashed(rect, 2.0, Pen(width: 1.2, color: theme.accent), dash: 5.0, gap: 3.5)
    }

    /** Clears any drag in progress — called when the mode changes out from under it. */
    public func cancelDrag(): Unit {
        dragging = false
    }

    private func handleWheel(dy: Float32, x: Float32, y: Float32, axes: Axes): Bool {
        if (!wheelZoom || !axes.dataArea().contains(x, y)) {
            return false
        }
        if (dy == 0.0) {
            return false
        }
        // Wheel up magnifies, so the factor shrinks the visible range.
        let factor = if (dy > 0.0) {
            1.0 / WHEEL_ZOOM_STEP
        } else {
            WHEEL_ZOOM_STEP
        }
        let projection = axes.projection()
        let anchorX = projection.dataX(x)
        let anchorY = projection.dataY(y)
        let currentX = axes.effectiveXBounds()
        let currentY = axes.effectiveYBounds()
        // Scaling about the cursor's data coordinate is what pins that point in place on screen —
        // but only the scale knows what "scaling" means on its own geometry, so it does the work.
        let nextX = if (lockX) {
            currentX
        } else {
            axes.x().zoomAround(currentX, anchorX, factor)
        }
        let nextY = if (lockY) {
            currentY
        } else {
            axes.y().zoomAround(currentY, anchorY, factor)
        }
        axes.setView(nextX, nextY)
        true
    }

    private func beginDrag(x: Float32, y: Float32, axes: Axes): Bool {
        if (!axes.dataArea().contains(x, y) || isInspectMode()) {
            return false
        }
        if (!isBoxMode() && !dragPan) {
            return false
        }
        dragging = true
        dragStartX = x
        dragStartY = y
        dragCurrentX = x
        dragCurrentY = y
        // Freeze the bounds at grab time and offset from them, so a pan tracks the pointer exactly
        // instead of accumulating rounding drift across the drag.
        dragStartXBounds = axes.effectiveXBounds()
        dragStartYBounds = axes.effectiveYBounds()
        false
    }

    private func continueDrag(x: Float32, y: Float32, axes: Axes): Bool {
        if (!dragging) {
            return false
        }
        dragCurrentX = x
        dragCurrentY = y
        if (isBoxMode()) {
            return true
        }
        let area = axes.dataArea()
        if (area.w <= 0.0 || area.h <= 0.0) {
            return false
        }
        // Convert the drag to a fraction of the panel and let each scale turn that into its own
        // shift, then move opposite to the drag: dragging right pulls earlier data into view.
        let fractionX = Float64((x - dragStartX) / area.w)
        let fractionY = Float64((y - dragStartY) / area.h)
        let nextX = if (lockX) {
            dragStartXBounds
        } else {
            axes.x().panByFraction(dragStartXBounds, -fractionX)
        }
        let nextY = if (lockY) {
            dragStartYBounds
        } else {
            axes.y().panByFraction(dragStartYBounds, fractionY)
        }
        axes.setView(nextX, nextY)
        true
    }

    private func endDrag(x: Float32, y: Float32, axes: Axes): Bool {
        if (!dragging) {
            return false
        }
        dragging = false
        if (!isBoxMode()) {
            return true
        }
        dragCurrentX = x
        dragCurrentY = y
        let rect = boxRect()
        // Ignore a stray click or a sliver: zooming to a 2-px box would leave a meaningless view
        // the user then has to undo.
        if (rect.w < 6.0 || rect.h < 6.0) {
            return true
        }
        let projection = axes.projection()
        let x0 = projection.dataX(rect.x)
        let x1 = projection.dataX(rect.right())
        let y0 = projection.dataY(rect.bottom())
        let y1 = projection.dataY(rect.y)
        let nextX = if (lockX) {
            axes.effectiveXBounds()
        } else {
            Bounds.of(x0, x1)
        }
        let nextY = if (lockY) {
            axes.effectiveYBounds()
        } else {
            Bounds.of(y0, y1)
        }
        axes.setView(nextX, nextY)
        true
    }

    private func isBoxMode(): Bool {
        match (mode) {
            case BoxZoom => true
            case _ => false
        }
    }

    private func isInspectMode(): Bool {
        match (mode) {
            case Inspect => true
            case _ => false
        }
    }
}

func minF(a: Float32, b: Float32): Float32 {
    if (a < b) {
        a
    } else {
        b
    }
}

func absF32(value: Float32): Float32 {
    if (value < 0.0) {
        -value
    } else {
        value
    }
}
