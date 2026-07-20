package examples

import std.math.sin
import plot.{Figure, PlotWindow, WindowOptions}
import plot.canvas.LineStyle
import plot.series.LineSeries
import plot.ui.{InteractionMode, Placement, ToolButton, ToolIcon, Toolbar}

/**
 * The interactive components, assembled by hand.
 *
 * `PlotWindow.addStandardToolbar()` does all of this in one line — this example takes the long way
 * round to show what the pieces are, and adds a custom button that the standard set does not have.
 *
 * Every component is optional. A window with none of this is a static viewer.
 */
public func runInteractive(): Unit {
    let figure = buildInteractiveFigure()
    let window = PlotWindow(figure, options: WindowOptions(title: "plot — interactive", width: 1100, height: 720))

    // The save component: opens the platform save dialog, then renders the figure without any
    // chrome on it and writes a PNG. Exported at 1600x1000 logical pixels, which the renderer's
    // 2x supersampling turns into a 3200x2000 file.
    window.exportWidth = 1600.0
    window.exportHeight = 1000.0
    window.exportFileName = "signal.png"

    let toolbar = Toolbar(Placement.TopRight)
    toolbar.add(window.saveImageButton())

    // Pan and box zoom are exclusive modes, so each button clears the other.
    let pan = ToolButton(ToolIcon.Pan, tooltip: "Pan (drag)")
    let box = ToolButton(ToolIcon.BoxZoom, tooltip: "Zoom to region (drag)")
    pan.toggle = true
    pan.active = true
    box.toggle = true
    pan.action = {
        =>
            box.active = false
            pan.active = true
            window.interactions.mode = InteractionMode.PanZoom
            window.interactions.cancelDrag()
    }
    box.action = {
        =>
            pan.active = false
            box.active = true
            window.interactions.mode = InteractionMode.BoxZoom
            window.interactions.cancelDrag()
    }
    toolbar.add(pan)
    toolbar.add(box)

    toolbar.add(
        ToolButton(
            ToolIcon.Home,
            tooltip: "Reset view",
            action: {
                =>
                    window.resetAllViews()
                    window.showStatus("View reset")
            }
        )
    )

    // A custom button the standard toolbar has no notion of: this is the extension point.
    let lockX = ToolButton(ToolIcon.Crosshair, tooltip: "Lock the y axis (zoom x only)")
    lockX.toggle = true
    lockX.action = {
        =>
            window.interactions.lockY = lockX.active
            window.showStatus(if (lockX.active) {
                "Y axis locked — zoom affects x only"
            } else {
                "Both axes unlocked"
            })
    }
    toolbar.add(lockX)

    let theme = ToolButton(ToolIcon.ThemeIcon, tooltip: "Light / dark")
    theme.toggle = true
    theme.action = {=> window.setDarkTheme(theme.active)}
    toolbar.add(theme)

    let _ = window.addComponent(toolbar)

    // The hover inspector snaps to the nearest data point rather than reporting raw cursor
    // position, and the status line reports the raw position. They answer different questions.
    let _ = window.enableHoverReadout()
    let _ = window.addCursorStatus(placement: Placement.BottomRight)

    window.show()
}

func buildInteractiveFigure(): Figure {
    let (figure, axes) = Figure.single(title: "Interactive signal viewer")
    figure.subtitle = "Drag to pan · wheel to zoom · click a legend entry to toggle · save with the toolbar"
    axes.xLabel = "time (s)"
    axes.yLabel = "amplitude"

    let source = Data.random(1234)
    let times = Data.linspace(0.0, 60.0, 1500)

    let carrier = LineSeries(times, Data.map(times) {t => sin(t * 1.1) * 2.0}, label: "carrier")
    carrier.width = Some(1.6)
    axes.add(carrier)

    let modulated = LineSeries(times, Data.map(times) {t => sin(t * 1.1) * sin(t * 0.12) * 2.0}, label: "modulated")
    axes.add(modulated)

    let noisy = LineSeries(times, Data.map(times) {
        t => sin(t * 1.1) * sin(t * 0.12) * 2.0 + source.nextGaussianFloat64() * 0.18
    }, label: "measured")
    noisy.width = Some(0.9)
    noisy.opacity = 0.7
    axes.add(noisy)

    let envelope = LineSeries(times, Data.map(times) {t => sin(t * 0.12) * 2.0}, label: "envelope")
    envelope.style = LineStyle.Dashed
    axes.add(envelope)

    figure
}
