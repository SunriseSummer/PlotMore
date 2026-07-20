package plot.ui

import std.collection.ArrayList
import sdl.{Color, MouseButton, Pen, Rect, Size, UiEvent}
import plot.canvas.{Canvas, HAlign, VAlign}
import plot.core.{Colors, Theme}

/** Toolbar geometry, in logical pixels. */
const BUTTON_SIZE: Float32 = 28.0
const BUTTON_GAP: Float32 = 3.0
const BAR_PADDING: Float32 = 5.0
const TOOLTIP_GAP: Float32 = 7.0
const TOOLTIP_PADDING: Float32 = 7.0

/**
 * One toolbar button: an icon, a hover tooltip, and an action.
 *
 * A button can be a *toggle*, in which case it keeps an on/off state and paints itself active; the
 * distinction matters because a mode button (pan, box zoom) must show that the mode is engaged,
 * whereas a one-shot (save, reset) has nothing to show.
 */
public class ToolButton {
    /** The glyph. */
    public let icon: ToolIcon

    /** The hover tooltip. Worth writing: an icon alone is a guess. */
    public var tooltip: String

    /** What pressing the button does. */
    public var action: () -> Unit

    /** True when the button holds an on/off state rather than firing once. */
    public var toggle: Bool = false

    /** The toggle state, when `toggle` is set. */
    public var active: Bool = false

    /** Whether the button responds; a disabled button greys out. */
    public var enabled: Bool = true

    var hovered: Bool = false
    var pressed: Bool = false
    var bounds: Rect = Rect.zero()

    public init(icon: ToolIcon, tooltip!: String = "", action!: () -> Unit = {=> ()}) {
        this.icon = icon
        this.tooltip = tooltip
        this.action = action
    }
}

/**
 * A floating row of icon buttons docked over the figure.
 *
 * Entirely optional — construct one and hand it to `PlotWindow.addComponent`, or call
 * `PlotWindow.addStandardToolbar` for the usual set. Buttons are added by the caller, so a
 * domain-specific toolbar is a matter of `add(ToolButton(...))` rather than of subclassing.
 */
public class Toolbar <: Component {
    private let buttons = ArrayList<ToolButton>()
    private var dock: Placement = Placement.TopRight
    private var hoverIndex: Int64 = -1

    /** Draws the rounded backdrop behind the buttons. */
    public var showBackground: Bool = true

    /** Shows the hovered button's tooltip. */
    public var showTooltips: Bool = true

    public init() {
        super()
    }

    public init(placement: Placement) {
        super()
        this.dock = placement
    }

    /** Adds a button and returns it, so the caller can keep configuring it. */
    public func add(button: ToolButton): ToolButton {
        buttons.add(button)
        button
    }

    /** The buttons, in order. */
    public func allButtons(): ArrayList<ToolButton> {
        buttons
    }

    /** Docks the toolbar somewhere else. */
    public func setPlacement(placement: Placement): Unit {
        dock = placement
    }

    public override func placement(): Placement {
        dock
    }

    public func measure(canvas: Canvas, theme: Theme): Size {
        let _ = canvas
        let _ = theme
        if (buttons.isEmpty()) {
            return Size.zero()
        }
        let width = Float32(buttons.size) * BUTTON_SIZE + Float32(buttons.size - 1) * BUTTON_GAP + BAR_PADDING * 2.0
        Size(width, BUTTON_SIZE + BAR_PADDING * 2.0)
    }

    public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        setFrame(rect)
        if (buttons.isEmpty()) {
            return
        }
        if (showBackground) {
            // A soft shadow lifts the bar off the data underneath; skipped on dark themes, where a
            // black halo reads as grime rather than as elevation.
            if (!theme.isDark) {
                canvas.fillSoftRect(rect.shift(0.0, 1.0), theme.cornerRadius, Colors.fade(Color.rgb(15, 23, 42), 0.1),
                    feather: 6.0)
            }
            canvas.fillRoundedRect(rect, theme.cornerRadius, Colors.fade(theme.surface, 0.97))
            canvas.strokeRoundedRect(rect, theme.cornerRadius, Pen(width: 1.0, color: theme.border))
        }
        var x = rect.x + BAR_PADDING
        for (button in buttons) {
            button.bounds = Rect(x, rect.y + BAR_PADDING, BUTTON_SIZE, BUTTON_SIZE)
            drawButton(canvas, button, theme)
            x += BUTTON_SIZE + BUTTON_GAP
        }
        drawTooltip(canvas, rect, theme)
    }

    public override func handle(event: UiEvent): EventResponse {
        if (!visible || buttons.isEmpty()) {
            return EventResponse.ignored()
        }
        match (event) {
            case UiEvent.MouseMove(x, y) => updateHover(x, y)
            case UiEvent.MouseDown(button, x, y) => match (button) {
                case MouseButton.Left => press(x, y)
                case _ => EventResponse.ignored()
            }
            case UiEvent.MouseUp(button, x, y) => match (button) {
                case MouseButton.Left => release(x, y)
                case _ => EventResponse.ignored()
            }
            case _ => EventResponse.ignored()
        }
    }

    private func updateHover(x: Float32, y: Float32): EventResponse {
        var found = -1
        for (i in 0..buttons.size) {
            let inside = buttons[i].bounds.contains(x, y)
            buttons[i].hovered = inside && buttons[i].enabled
            if (inside) {
                found = i
            }
        }
        let changed = found != hoverIndex
        hoverIndex = found
        // Hovering repaints but does not consume: the window still needs the move for its own
        // crosshair, and swallowing it would freeze the readout whenever the pointer crossed the bar.
        if (changed) {
            EventResponse.repaint()
        } else {
            EventResponse.ignored()
        }
    }

    private func press(x: Float32, y: Float32): EventResponse {
        for (button in buttons) {
            if (button.enabled && button.bounds.contains(x, y)) {
                button.pressed = true
                return EventResponse.handled()
            }
        }
        EventResponse.ignored()
    }

    private func release(x: Float32, y: Float32): EventResponse {
        var fired = false
        for (button in buttons) {
            // Only fire when press and release land on the same button, so a drag off the button
            // cancels — the standard affordance for "changed my mind".
            let hit = button.pressed && button.enabled && button.bounds.contains(x, y)
            button.pressed = false
            if (hit) {
                if (button.toggle) {
                    button.active = !button.active
                }
                (button.action)()
                fired = true
            }
        }
        if (fired) {
            EventResponse.handled()
        } else {
            EventResponse.ignored()
        }
    }

    private func drawButton(canvas: Canvas, button: ToolButton, theme: Theme): Unit {
        let radius = theme.cornerRadius * 0.7
        if (button.pressed && button.enabled) {
            canvas.fillRoundedRect(button.bounds, radius, theme.surfaceActive)
        } else if (button.active) {
            canvas.fillRoundedRect(button.bounds, radius, Colors.fade(theme.accent, 0.16))
        } else if (button.hovered) {
            canvas.fillRoundedRect(button.bounds, radius, theme.surfaceHover)
        }
        let tint = if (!button.enabled) {
            Colors.fade(theme.mutedText, 0.4)
        } else if (button.active) {
            theme.accent
        } else {
            theme.text
        }
        drawToolIcon(canvas, button.icon, button.bounds.inset(6.0), tint)
    }

    private func drawTooltip(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        if (!showTooltips || hoverIndex < 0 || hoverIndex >= buttons.size) {
            return
        }
        let button = buttons[hoverIndex]
        if (button.tooltip.isEmpty() || !button.enabled) {
            return
        }
        let textWidth = canvas.textWidth(button.tooltip, size: theme.annotationSize)
        let textHeight = canvas.textHeight(size: theme.annotationSize)
        let width = textWidth + TOOLTIP_PADDING * 2.0
        let height = textHeight + TOOLTIP_PADDING
        // Flip below the bar when it is docked at the top, so the tip never leaves the window.
        let above = isBottomDocked()
        let y = if (above) {
            rect.y - height - TOOLTIP_GAP
        } else {
            rect.bottom() + TOOLTIP_GAP
        }
        var x = button.bounds.centerX() - width / 2.0
        x = clampF(x, rect.x - width * 0.5, rect.right() + width * 0.5 - width)
        let frame = Rect(x, y, width, height)
        canvas.fillRoundedRect(frame, 5.0, tooltipSurface(theme))
        canvas.textAnchored(button.tooltip, frame.centerX(), frame.centerY(), tooltipText(theme),
            size: theme.annotationSize, hAlign: HAlign.Center, vAlign: VAlign.Middle)
    }

    private func isBottomDocked(): Bool {
        match (dock) {
            case BottomLeft => true
            case BottomCenter => true
            case BottomRight => true
            case _ => false
        }
    }
}

/** A tooltip chip inverts against the theme, which is what separates it from the surface below. */
func tooltipSurface(theme: Theme): Color {
    if (theme.isDark) {
        Colors.fade(Color.rgb(240, 244, 250), 0.96)
    } else {
        Colors.fade(Color.rgb(17, 24, 39), 0.94)
    }
}

func tooltipText(theme: Theme): Color {
    if (theme.isDark) {
        Color.rgb(17, 24, 39)
    } else {
        Color.rgb(255, 255, 255)
    }
}

func clampF(value: Float32, low: Float32, high: Float32): Float32 {
    if (high < low) {
        return low
    }
    if (value < low) {
        low
    } else if (value > high) {
        high
    } else {
        value
    }
}
