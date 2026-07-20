package plot

import std.collection.ArrayList
import sdl.{MouseButton, Rect, SdlWindow, UiEvent, WindowSpec}
import sdl.dialogs.{FileDialogFilter, FileDialogOptions, FileDialogRequest, FileDialogResult, FileDialogs}
import plot.axes.Axes
import plot.canvas.{Canvas, HAlign, VAlign}
import plot.core.{Colors, PlotException, Theme}
import plot.ui.{Component, CursorStatus, HoverReadout, InteractionMode, Interactions, Placement, ToolButton, ToolIcon, 
    Toolbar}

/** Idle frame pacing, in milliseconds. Only reached when nothing is animating. */
const FRAME_DELAY_MS: UInt32 = 12

/** Gap between the window edge and docked chrome, in logical pixels. */
const CHROME_MARGIN: Float32 = 10.0

/** How long a status toast stays up. */
const TOAST_MS: UInt64 = 2600

/** Default export resolution, in logical pixels; the file lands at this times the supersample factor. */
const EXPORT_WIDTH: Float32 = 1200.0
const EXPORT_HEIGHT: Float32 = 800.0

/** How the window is sized and titled. */
public struct WindowOptions {
    public let title: String
    public let width: Int64
    public let height: Int64
    public let resizable: Bool

    public init(title!: String = "Plot", width!: Int64 = 980, height!: Int64 = 640, resizable!: Bool = true) {
        this.title = title
        this.width = width
        this.height = height
        this.resizable = resizable
    }
}

/**
 * An interactive window showing a `Figure`.
 *
 * ```
 * let window = PlotWindow(figure)
 * window.addStandardToolbar()   // save / zoom / pan / reset / grid / theme
 * window.show()
 * ```
 *
 * Everything beyond the chart itself is opt-in. A bare `PlotWindow(figure).show()` is a static
 * viewer with no chrome; `addStandardToolbar` adds the usual controls; `addComponent` docks any
 * component you like, including your own.
 *
 * Rendering is on demand — a frame is drawn only when something changes — so a static chart left
 * open costs nothing.
 *
 * `show` blocks until the window is closed, and owns the SDL window, renderer, and canvas for that
 * time.
 */
public class PlotWindow {
    private let figure: Figure
    private let options: WindowOptions
    private let components = ArrayList<Component>()

    /** Zoom, pan, and box-zoom behaviour. Applies to the cartesian panel under the cursor. */
    public let interactions: Interactions = Interactions()

    /** The hover crosshair and value chip. Disabled until `enableHoverReadout` is called. */
    public let hover: HoverReadout = HoverReadout()

    /** Width in logical pixels used when exporting; the file is this times the supersample factor. */
    public var exportWidth: Float32 = EXPORT_WIDTH

    /** Height in logical pixels used when exporting. */
    public var exportHeight: Float32 = EXPORT_HEIGHT

    /** Where the save dialog opens; `None` uses the platform default. */
    public var exportDirectory: ?String = None

    /** The file name offered in the save dialog. */
    public var exportFileName: String = "figure.png"

    private var hoverEnabled = false
    private var running = false
    private var dirty = true
    private var toastText = ""
    private var toastUntil: UInt64 = 0
    private var toastError = false
    private var pendingSave: ?FileDialogRequest = None
    private var window: ?SdlWindow = None
    private var canvas: ?Canvas = None

    public init(figure: Figure, options!: WindowOptions = WindowOptions()) {
        this.figure = figure
        this.options = options
    }

    /** The figure being shown. */
    public func plotFigure(): Figure {
        figure
    }

    // --- composition -------------------------------------------------------------------------

    /** Docks a component over the figure. Returns it so the caller can keep configuring it. */
    public func addComponent(component: Component): Component {
        components.add(component)
        dirty = true
        component
    }

    /** The docked components, in draw order. */
    public func allComponents(): ArrayList<Component> {
        components
    }

    /**
     * Turns on the hover crosshair and value chip, which snap to the nearest data point.
     *
     * Off by default because it makes the window redraw on every pointer move; on a figure with a
     * very large series that is real work per frame.
     */
    public func enableHoverReadout(): HoverReadout {
        hoverEnabled = true
        hover
    }

    /**
     * A save button wired to this window's export flow — the file-saving component.
     *
     * Pressing it opens the platform save dialog and, once a path is chosen, renders the figure
     * *without* any chrome at `exportWidth` x `exportHeight` and writes it there. Add it to a
     * toolbar, or use `addStandardToolbar`, which includes one.
     */
    public func saveImageButton(): ToolButton {
        ToolButton(ToolIcon.Save, tooltip: "Save image…", action: {=> requestSaveImage()})
    }

    /**
     * Adds the usual toolbar: save, box zoom, pan, reset view, grid, and theme.
     *
     * Returns the toolbar, so buttons can be removed or added. Build a `Toolbar` yourself for a
     * different set.
     */
    public func addStandardToolbar(placement!: Placement = Placement.TopRight): Toolbar {
        let toolbar = Toolbar(placement)
        toolbar.add(saveImageButton())

        // Pan and box zoom are mutually exclusive modes, so each clears the other.
        let pan = ToolButton(ToolIcon.Pan, tooltip: "Pan (drag)")
        let box = ToolButton(ToolIcon.BoxZoom, tooltip: "Zoom to region (drag)")
        pan.toggle = true
        pan.active = true
        box.toggle = true
        pan.action = {
            =>
                box.active = false
                pan.active = true
                interactions.mode = InteractionMode.PanZoom
                interactions.cancelDrag()
        }
        box.action = {
            =>
                pan.active = false
                box.active = true
                interactions.mode = InteractionMode.BoxZoom
                interactions.cancelDrag()
        }
        toolbar.add(pan)
        toolbar.add(box)

        toolbar.add(ToolButton(ToolIcon.Home, tooltip: "Reset view", action: {=> resetAllViews()}))

        let grid = ToolButton(ToolIcon.Grid, tooltip: "Toggle grid")
        grid.toggle = true
        grid.active = true
        grid.action = {=> setGridVisible(grid.active)}
        toolbar.add(grid)

        let theme = ToolButton(ToolIcon.ThemeIcon, tooltip: "Light / dark")
        theme.toggle = true
        theme.active = figure.theme.isDark
        theme.action = {=> setDarkTheme(theme.active)}
        toolbar.add(theme)

        addComponent(toolbar)
        toolbar
    }

    /** Adds a cursor position readout, docked at `placement`. */
    public func addCursorStatus(placement!: Placement = Placement.BottomRight): CursorStatus {
        let status = CursorStatus(placement)
        addComponent(status)
        status
    }

    // --- actions -----------------------------------------------------------------------------

    /**
     * Opens the platform save dialog. The export happens once the user picks a path, driven from
     * the event loop — the dialog runs on its own thread and answers asynchronously.
     *
     * A no-op while a save dialog is already open.
     */
    public func requestSaveImage(): Unit {
        if (pendingSave.isSome()) {
            return
        }
        let host = match (window) {
            case Some(value) => value
            case None => return
        }
        let filters = [FileDialogFilter("PNG image", "png"), FileDialogFilter("Bitmap image", "bmp")]
        let dialogOptions = FileDialogOptions(filters: filters, defaultLocation: exportDirectory)
        pendingSave = Some(FileDialogs.saveFile(options: dialogOptions, window: Some(host)))
    }

    /**
     * Writes the figure to `path` immediately, with no dialog — the scripted export path.
     *
     * The extension picks the format: `.bmp` writes a bitmap, anything else writes a PNG.
     *
     * Throws `PlotException` when called before `show` has opened the window, or when the write
     * fails.
     */
    public func saveImage(path: String): Unit {
        let renderer = match (window) {
            case Some(value) => value.renderer
            case None => throw PlotException("saveImage needs an open window; call it from a button or after show().")
        }
        let surface = match (canvas) {
            case Some(value) => value
            case None => throw PlotException("saveImage needs an open window; call it from a button or after show().")
        }
        if (isBmpPath(path)) {
            FigureExport.saveBmp(figure, renderer, surface, path, width: exportWidth, height: exportHeight)
        } else {
            FigureExport.savePng(figure, renderer, surface, path, width: exportWidth, height: exportHeight)
        }
    }

    /** Drops any zoom or pan on every cartesian panel. */
    public func resetAllViews(): Unit {
        for (panel in figure.allPanels()) {
            if (let Some(axes) <- (panel as Axes)) {
                axes.resetView()
            }
        }
        dirty = true
    }

    /** Shows or hides the grid on every cartesian panel. */
    public func setGridVisible(visible: Bool): Unit {
        for (panel in figure.allPanels()) {
            if (let Some(axes) <- (panel as Axes)) {
                axes.showGrid = visible
            }
        }
        dirty = true
    }

    /** Switches the figure between the dark and light presets. */
    public func setDarkTheme(useDark: Bool): Unit {
        figure.theme = if (useDark) {
            Theme.dark()
        } else {
            Theme.light()
        }
        dirty = true
    }

    /** Shows a transient message over the figure. */
    public func showStatus(message: String, error!: Bool = false): Unit {
        toastText = message
        toastError = error
        toastUntil = currentTicks() + TOAST_MS
        dirty = true
    }

    /** Forces a redraw on the next loop turn. */
    public func invalidate(): Unit {
        dirty = true
    }

    // --- lifecycle ---------------------------------------------------------------------------

    /**
     * Opens the window and runs the event loop until the user closes it.
     *
     * Throws `PlotException` when this window is already showing.
     */
    public func show(): Unit {
        if (running) {
            throw PlotException("This PlotWindow is already showing.")
        }
        running = true
        let host = SdlWindow(
            WindowSpec(options.title, Int32(options.width), Int32(options.height), resizable: options.resizable))
        window = Some(host)
        try {
            let surface = Canvas(host.renderer)
            canvas = Some(surface)
            try {
                runLoop(host, surface)
            } finally {
                surface.close()
                canvas = None
            }
        } finally {
            running = false
            window = None
            host.close()
        }
    }

    private func runLoop(host: SdlWindow, surface: Canvas): Unit {
        var alive = true
        dirty = true
        while (alive) {
            var current = host.pollEvent()
            while (let Some(event) <- current) {
                match (event) {
                    case UiEvent.Quit => alive = false
                    case UiEvent.WindowResized(_, _) =>
                        let _ = host.refreshSize()
                        dirty = true
                    case _ => routeEvent(event)
                }
                current = host.pollEvent()
            }
            pollPendingSave()
            // A live toast expires on a clock, not on an event, so it needs a frame to clear itself.
            if (toastActive()) {
                dirty = true
            }
            if (dirty) {
                renderFrame(host, surface)
                dirty = false
            }
            host.delay(FRAME_DELAY_MS)
        }
    }

    /*
     * Chrome first, then the chart. A click on a toolbar button must not also pan the axes
     * underneath it, and a component that reports `consumed` stops exactly that.
     */
    private func routeEvent(event: UiEvent): Unit {
        for (component in components) {
            if (!component.visible) {
                continue
            }
            let response = component.handle(event)
            if (response.redraw) {
                dirty = true
            }
            if (response.consumed) {
                return
            }
        }
        for (component in components) {
            if (let Some(status) <- (component as CursorStatus)) {
                if (let Some(axes) <- firstAxes()) {
                    if (status.update(event, axes)) {
                        dirty = true
                    }
                }
            }
        }
        if (pointerOverChrome(event)) {
            return
        }
        let axes = match (targetAxes(event)) {
            case Some(value) => value
            case None => return
        }
        if (handleLegendClick(event, axes)) {
            dirty = true
            return
        }
        if (interactions.handle(event, axes)) {
            dirty = true
        }
        if (hoverEnabled && hover.handle(event, axes)) {
            dirty = true
        }
    }

    // A press inside docked chrome must not start a pan on the chart behind it. Only pointer
    // events carry a position; everything else routes normally.
    private func pointerOverChrome(event: UiEvent): Bool {
        let (x, y) = match (event) {
            case UiEvent.MouseDown(_, px, py) => (px, py)
            case UiEvent.MouseWheel(_, _, px, py) => (px, py)
            case _ => return false
        }
        for (component in components) {
            if (component.containsPixel(x, y)) {
                return true
            }
        }
        false
    }

    private func handleLegendClick(event: UiEvent, axes: Axes): Bool {
        let (x, y) = match (event) {
            case UiEvent.MouseDown(button, px, py) => match (button) {
                case MouseButton.Left => (px, py)
                case _ => return false
            }
            case _ => return false
        }
        match (axes.legend.entryAt(x, y)) {
            case Some(index) => axes.toggleLegendEntry(index, figure.theme)
            case None => false
        }
    }

    private func targetAxes(event: UiEvent): ?Axes {
        let (x, y) = match (event) {
            case UiEvent.MouseDown(_, px, py) => (px, py)
            case UiEvent.MouseUp(_, px, py) => (px, py)
            case UiEvent.MouseMove(px, py) => (px, py)
            case UiEvent.MouseWheel(_, _, px, py) => (px, py)
            case _ => return firstAxes()
        }
        match (figure.panelAt(x, y)) {
            case Some(panel) => panel as Axes
            case None => None
        }
    }

    private func firstAxes(): ?Axes {
        for (panel in figure.allPanels()) {
            if (let Some(axes) <- (panel as Axes)) {
                return Some(axes)
            }
        }
        None
    }

    private func pollPendingSave(): Unit {
        let request = match (pendingSave) {
            case Some(value) => value
            case None => return
        }
        if (!request.isDone()) {
            return
        }
        pendingSave = None
        match (request.result()) {
            case FileDialogResult.FileDialogSelected(paths, _) =>
                if (paths.size > 0) {
                    completeSave(withPngExtension(paths[0]))
                }
            case FileDialogResult.FileDialogFailed(message) => showStatus("Save failed: ${message}", error: true)
            case _ => () // Canceled, or still pending after isDone — nothing to report.
        }
    }

    private func completeSave(path: String): Unit {
        try {
            saveImage(path)
            showStatus("Saved ${fileNameOf(path)}")
        } catch (error: PlotException) {
            // The export is a user action, so a failure belongs on screen, not on stderr.
            showStatus("Save failed: ${error.message}", error: true)
        } catch (error: Exception) {
            showStatus("Save failed: ${error.message}", error: true)
        }
    }

    private func renderFrame(host: SdlWindow, surface: Canvas): Unit {
        let renderer = host.renderer
        let width = Float32(host.width)
        let height = Float32(host.height)
        renderer.beginScene(width, height, figure.theme.background)
        figure.draw(surface, Rect(0.0, 0.0, width, height))
        drawOverlays(surface)
        drawComponents(surface, Rect(0.0, 0.0, width, height))
        drawToast(surface, Rect(0.0, 0.0, width, height))
        renderer.endScene()
        renderer.present()
    }

    private func drawOverlays(surface: Canvas): Unit {
        let axes = match (firstAxes()) {
            case Some(value) => value
            case None => return
        }
        interactions.drawOverlay(surface, figure.theme)
        if (hoverEnabled) {
            hover.draw(surface, axes, figure.theme)
        }
    }

    /*
     * Docks each component at its placement, stacking multiples at the same corner. Measuring every
     * frame keeps a variable-width component (the cursor readout grows with its text) from
     * flickering against a stale size.
     */
    private func drawComponents(surface: Canvas, bounds: Rect): Unit {
        var topLeft = CHROME_MARGIN
        var topCenter = CHROME_MARGIN
        var topRight = CHROME_MARGIN
        var bottomLeft = CHROME_MARGIN
        var bottomCenter = CHROME_MARGIN
        var bottomRight = CHROME_MARGIN
        for (component in components) {
            if (!component.visible) {
                continue
            }
            let size = component.measure(surface, figure.theme)
            if (size.w <= 0.0 || size.h <= 0.0) {
                continue
            }
            let frame = match (component.placement()) {
                case TopLeft =>
                    let rect = Rect(bounds.x + CHROME_MARGIN, bounds.y + topLeft, size.w, size.h)
                    topLeft += size.h + CHROME_MARGIN
                    rect
                case TopCenter =>
                    let rect = Rect(bounds.centerX() - size.w / 2.0, bounds.y + topCenter, size.w, size.h)
                    topCenter += size.h + CHROME_MARGIN
                    rect
                case TopRight =>
                    let rect = Rect(bounds.right() - size.w - CHROME_MARGIN, bounds.y + topRight, size.w, size.h)
                    topRight += size.h + CHROME_MARGIN
                    rect
                case BottomLeft =>
                    let rect = Rect(bounds.x + CHROME_MARGIN, bounds.bottom() - bottomLeft - size.h, size.w, size.h)
                    bottomLeft += size.h + CHROME_MARGIN
                    rect
                case BottomCenter =>
                    let rect = Rect(bounds.centerX() - size.w / 2.0, bounds.bottom() - bottomCenter - size.h, size.w,
                        size.h)
                    bottomCenter += size.h + CHROME_MARGIN
                    rect
                case BottomRight =>
                    let rect = Rect(bounds.right() - size.w - CHROME_MARGIN, bounds.bottom() - bottomRight - size.h,
                        size.w, size.h)
                    bottomRight += size.h + CHROME_MARGIN
                    rect
            }
            component.draw(surface, frame, figure.theme)
        }
    }

    private func drawToast(surface: Canvas, bounds: Rect): Unit {
        if (!toastActive()) {
            return
        }
        let theme = figure.theme
        let textWidth = surface.textWidth(toastText, size: theme.annotationSize)
        let width = textWidth + 24.0
        let height = surface.textHeight(size: theme.annotationSize) + 14.0
        let frame = Rect(bounds.centerX() - width / 2.0, bounds.bottom() - height - 24.0, width, height)
        let fill = if (toastError) {
            Colors.hex("#DC2626")
        } else if (theme.isDark) {
            Colors.hex("#E5E7EB")
        } else {
            Colors.hex("#111827")
        }
        surface.fillRoundedRect(frame, height / 2.0, Colors.fade(fill, 0.95))
        surface.textAnchored(toastText, frame.centerX(), frame.centerY(), Colors.contrastText(fill),
            size: theme.annotationSize, hAlign: HAlign.Center, vAlign: VAlign.Middle)
    }

    private func toastActive(): Bool {
        !toastText.isEmpty() && currentTicks() < toastUntil
    }

    private func currentTicks(): UInt64 {
        match (window) {
            case Some(host) => host.ticks()
            case None => 0
        }
    }
}
