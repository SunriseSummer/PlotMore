package plot.ui

import sdl.{Rect, Size, UiEvent}
import plot.canvas.Canvas
import plot.core.Theme

/** Where a component docks inside the window. */
public enum Placement {
    | TopLeft
    | TopCenter
    | TopRight
    | BottomLeft
    | BottomCenter
    | BottomRight
}

/**
 * What a component's event handler tells the window to do next.
 *
 * A component reports whether it *used* the event and whether the frame needs redrawing, which are
 * genuinely different: a hover changes appearance without consuming the event, while a click both
 * consumes and redirties.
 */
public struct EventResponse {
    /** True when the component handled the event and the window should not route it further. */
    public let consumed: Bool

    /** True when the window should redraw. */
    public let redraw: Bool

    public init(consumed!: Bool = false, redraw!: Bool = false) {
        this.consumed = consumed
        this.redraw = redraw
    }

    /** The event was neither used nor changed anything. */
    public static func ignored(): EventResponse {
        EventResponse()
    }

    /** The event changed appearance but should still reach other handlers. */
    public static func repaint(): EventResponse {
        EventResponse(consumed: false, redraw: true)
    }

    /** The event was fully handled here. */
    public static func handled(): EventResponse {
        EventResponse(consumed: true, redraw: true)
    }
}

/**
 * A piece of interactive chrome docked over the figure — a toolbar, a readout, a status line.
 *
 * Components are entirely optional: a `PlotWindow` with none is a plain chart viewer. The window
 * measures each one, docks it at its `Placement`, draws it after the figure, and routes events to
 * it before the figure sees them, so chrome sits above the data in both senses.
 */
public abstract class Component {
    /** Whether the component is drawn and receives events. */
    public var visible: Bool = true

    // Where the component last drew. Events arrive in window coordinates and have to be tested
    // against the docked rectangle, which only layout knows.
    protected var lastFrame: Rect = Rect.zero()

    /** The size the component wants, given the theme's metrics. */
    public func measure(canvas: Canvas, theme: Theme): Size

    /** Draws the component into the rectangle the window docked it at. */
    public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit

    /** Where the component sits in the window. */
    public open func placement(): Placement {
        Placement.TopRight
    }

    /** Handles an event. The default ignores everything. */
    public open func handle(event: UiEvent): EventResponse {
        let _ = event
        EventResponse.ignored()
    }

    /** The rectangle this component last occupied. */
    public func frame(): Rect {
        lastFrame
    }

    /** True when `(px, py)` is inside the component's last frame. */
    public func containsPixel(px: Float32, py: Float32): Bool {
        visible && lastFrame.contains(px, py)
    }

    /** Records the docked rectangle; call from `draw`. */
    protected func setFrame(rect: Rect): Unit {
        lastFrame = rect
    }
}
