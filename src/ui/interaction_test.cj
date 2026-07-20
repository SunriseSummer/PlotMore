package plot.ui

import std.collection.ArrayList
import sdl.{MouseButton, Rect, UiEvent}
import plot.axes.Axes
import plot.canvas.Canvas
import plot.core.{Bounds, Renderer, Theme}
import plot.series.LineSeries

/* A laid-out axes over a headless renderer: interactions need a real dataArea to work against. */
func preparedAxes(): Axes {
    let canvas = Canvas(Renderer.headless())
    try {
        let axes = Axes()
        axes.showTickLabels = false
        axes.showTicks = false
        axes.add(LineSeries([0.0, 10.0], [0.0, 10.0]))
        axes.setXLimits(Bounds(0.0, 10.0))
        axes.setYLimits(Bounds(0.0, 10.0))
        axes.draw(canvas, Rect(0.0, 0.0, 400.0, 400.0), Theme.light())
        return axes
    } finally {
        canvas.close()
    }
}

func nearly(actual: Float64, expected: Float64, tolerance: Float64): Bool {
    let delta = actual - expected
    if (delta < 0.0) {
        -delta <= tolerance
    } else {
        delta <= tolerance
    }
}

@Test
func wheelZoomNarrowsTheRange(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    let center = axes.dataArea()

    let before = axes.effectiveXBounds().span()
    @Expect(interactions.handle(UiEvent.MouseWheel(0.0, 1.0, center.centerX(), center.centerY()), axes))

    // Wheel up magnifies, so the visible range must shrink.
    @Expect(axes.effectiveXBounds().span() < before)
}

@Test
func wheelZoomOutWidensTheRange(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    let center = axes.dataArea()

    let before = axes.effectiveXBounds().span()
    @Expect(interactions.handle(UiEvent.MouseWheel(0.0, -1.0, center.centerX(), center.centerY()), axes))

    @Expect(axes.effectiveXBounds().span() > before)
}

@Test
func wheelZoomKeepsTheDataUnderTheCursorFixed(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    let area = axes.dataArea()
    // A point well off centre: zooming about the panel centre would move it, which is the bug
    // this anchoring exists to avoid.
    let cursorX = area.x + area.w * 0.25
    let cursorY = area.y + area.h * 0.25
    let anchorBefore = axes.projection().dataX(cursorX)

    let _ = interactions.handle(UiEvent.MouseWheel(0.0, 1.0, cursorX, cursorY), axes)
    let anchorAfter = axes.projection().dataX(cursorX)

    @Expect(nearly(anchorAfter, anchorBefore, 0.02))
}

@Test
func wheelZoomIgnoresTheCursorOutsideThePanel(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()

    // Off-panel scrolls belong to whatever is under the pointer, not to the chart.
    @Expect(!interactions.handle(UiEvent.MouseWheel(0.0, 1.0, -20.0, -20.0), axes))
    @Expect(!axes.hasView())
}

@Test
func wheelZoomCanBeDisabled(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    interactions.wheelZoom = false
    let area = axes.dataArea()

    @Expect(!interactions.handle(UiEvent.MouseWheel(0.0, 1.0, area.centerX(), area.centerY()), axes))
    @Expect(!axes.hasView())
}

@Test
func lockedAxisDoesNotZoom(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    interactions.lockY = true
    let area = axes.dataArea()
    let yBefore = axes.effectiveYBounds().span()

    let _ = interactions.handle(UiEvent.MouseWheel(0.0, 1.0, area.centerX(), area.centerY()), axes)

    @Expect(nearly(axes.effectiveYBounds().span(), yBefore, 1.0e-9))
    @Expect(axes.effectiveXBounds().span() < 10.0)
}

@Test
func dragPansOppositeToThePointer(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    let area = axes.dataArea()

    let _ = interactions.handle(UiEvent.MouseDown(MouseButton.Left, area.centerX(), area.centerY()), axes)
    // Dragging right pulls earlier data into view, so the x range must move down.
    @Expect(interactions.handle(UiEvent.MouseMove(area.centerX() + area.w / 4.0, area.centerY()), axes))

    let x = axes.effectiveXBounds()
    @Expect(x.low < 0.0)
    @Expect(nearly(x.span(), 10.0, 0.05))
}

@Test
func dragPansVerticallyInTheDataDirection(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    let area = axes.dataArea()

    let _ = interactions.handle(UiEvent.MouseDown(MouseButton.Left, area.centerX(), area.centerY()), axes)
    // Dragging down moves the view toward higher data: pixels grow downward, data grows upward.
    let _ = interactions.handle(UiEvent.MouseMove(area.centerX(), area.centerY() + area.h / 4.0), axes)

    @Expect(axes.effectiveYBounds().low > 0.0)
}

@Test
func panIsIgnoredWhenDragPanIsOff(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    interactions.dragPan = false
    let area = axes.dataArea()

    let _ = interactions.handle(UiEvent.MouseDown(MouseButton.Left, area.centerX(), area.centerY()), axes)
    let _ = interactions.handle(UiEvent.MouseMove(area.centerX() + 50.0, area.centerY()), axes)

    @Expect(!axes.hasView())
}

@Test
func inspectModeNeitherPansNorBoxes(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    interactions.mode = InteractionMode.Inspect
    let area = axes.dataArea()

    let _ = interactions.handle(UiEvent.MouseDown(MouseButton.Left, area.centerX(), area.centerY()), axes)
    let _ = interactions.handle(UiEvent.MouseMove(area.centerX() + 50.0, area.centerY()), axes)

    @Expect(!interactions.isBoxing())
    @Expect(!axes.hasView())
}

@Test
func boxZoomSelectsTheDraggedRegion(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    interactions.mode = InteractionMode.BoxZoom
    let area = axes.dataArea()

    let from = axes.projection().pixel(2.0, 8.0)
    let to = axes.projection().pixel(6.0, 3.0)
    let _ = interactions.handle(UiEvent.MouseDown(MouseButton.Left, from.x, from.y), axes)
    let _ = interactions.handle(UiEvent.MouseMove(to.x, to.y), axes)
    @Expect(interactions.isBoxing())
    // The rectangle must normalise whichever corner the drag started from.
    @Expect(interactions.boxRect().w > 0.0)
    @Expect(interactions.boxRect().h > 0.0)

    let _ = interactions.handle(UiEvent.MouseUp(MouseButton.Left, to.x, to.y), axes)
    @Expect(!interactions.isBoxing())

    let x = axes.effectiveXBounds()
    let y = axes.effectiveYBounds()
    @Expect(nearly(x.low, 2.0, 0.1))
    @Expect(nearly(x.high, 6.0, 0.1))
    // The drag went top-to-bottom in pixels, i.e. high-to-low in data; the range must come out ordered.
    @Expect(nearly(y.low, 3.0, 0.1))
    @Expect(nearly(y.high, 8.0, 0.1))
    @Expect(area.w > 0.0)
}

@Test
func boxZoomIgnoresASliverSelection(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    interactions.mode = InteractionMode.BoxZoom
    let area = axes.dataArea()

    // A stray click must not zoom to a meaningless 2-px box the user then has to undo.
    let _ = interactions.handle(UiEvent.MouseDown(MouseButton.Left, area.centerX(), area.centerY()), axes)
    let _ = interactions.handle(UiEvent.MouseMove(area.centerX() + 2.0, area.centerY() + 2.0), axes)
    let _ = interactions.handle(UiEvent.MouseUp(MouseButton.Left, area.centerX() + 2.0, area.centerY() + 2.0), axes)

    @Expect(!axes.hasView())
}

@Test
func cancelDragAbandonsASelectionInProgress(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    interactions.mode = InteractionMode.BoxZoom
    let area = axes.dataArea()

    let _ = interactions.handle(UiEvent.MouseDown(MouseButton.Left, area.x + 10.0, area.y + 10.0), axes)
    let _ = interactions.handle(UiEvent.MouseMove(area.x + 90.0, area.y + 90.0), axes)
    @Expect(interactions.isBoxing())

    // Switching mode out from under a live drag must not leave a stale rectangle on screen.
    interactions.cancelDrag()
    @Expect(!interactions.isBoxing())
}

@Test
func rightButtonDragDoesNothing(): Unit {
    let axes = preparedAxes()
    let interactions = Interactions()
    let area = axes.dataArea()

    let _ = interactions.handle(UiEvent.MouseDown(MouseButton.Right, area.centerX(), area.centerY()), axes)
    let _ = interactions.handle(UiEvent.MouseMove(area.centerX() + 50.0, area.centerY()), axes)

    @Expect(!axes.hasView())
}

@Test
func toolbarFiresOnlyWhenPressAndReleaseShareAButton(): Unit {
    let canvas = Canvas(Renderer.headless())
    try {
        let theme = Theme.light()
        let toolbar = Toolbar(Placement.TopRight)
        // A lambda cannot capture a mutable local in Cangjie, so the counter is a reference type.
        let fired = ArrayList<Int64>()
        let button = ToolButton(ToolIcon.Save, tooltip: "Save")
        button.action = {=> fired.add(1)}
        toolbar.add(button)
        let size = toolbar.measure(canvas, theme)
        toolbar.draw(canvas, Rect(0.0, 0.0, size.w, size.h), theme)

        let target = button.bounds
        let _ = toolbar.handle(UiEvent.MouseDown(MouseButton.Left, target.centerX(), target.centerY()))
        let _ = toolbar.handle(UiEvent.MouseUp(MouseButton.Left, target.centerX(), target.centerY()))
        @Expect(fired.size, 1)

        // Dragging off the button before releasing cancels — the standard "changed my mind" gesture.
        let _ = toolbar.handle(UiEvent.MouseDown(MouseButton.Left, target.centerX(), target.centerY()))
        let _ = toolbar.handle(UiEvent.MouseUp(MouseButton.Left, target.centerX() + 500.0, target.centerY()))
        @Expect(fired.size, 1)
    } finally {
        canvas.close()
    }
}

@Test
func toolbarToggleFlipsItsStateAndDisabledButtonsIgnorePresses(): Unit {
    let canvas = Canvas(Renderer.headless())
    try {
        let theme = Theme.light()
        let toolbar = Toolbar()
        let toggle = ToolButton(ToolIcon.Grid)
        toggle.toggle = true
        toolbar.add(toggle)
        let disabledFired = ArrayList<Int64>()
        let disabled = ToolButton(ToolIcon.ZoomOut)
        disabled.enabled = false
        disabled.action = {=> disabledFired.add(1)}
        toolbar.add(disabled)
        let size = toolbar.measure(canvas, theme)
        toolbar.draw(canvas, Rect(0.0, 0.0, size.w, size.h), theme)

        @Expect(!toggle.active)
        let _ = toolbar.handle(UiEvent.MouseDown(MouseButton.Left, toggle.bounds.centerX(), toggle.bounds.centerY()))
        let _ = toolbar.handle(UiEvent.MouseUp(MouseButton.Left, toggle.bounds.centerX(), toggle.bounds.centerY()))
        @Expect(toggle.active)

        let _ = toolbar.handle(UiEvent.MouseDown(MouseButton.Left, disabled.bounds.centerX(), disabled.bounds.centerY()))
        let _ = toolbar.handle(UiEvent.MouseUp(MouseButton.Left, disabled.bounds.centerX(), disabled.bounds.centerY()))
        @Expect(disabledFired.size, 0)
    } finally {
        canvas.close()
    }
}

@Test
func toolbarConsumesClicksOnItselfButNotHovers(): Unit {
    let canvas = Canvas(Renderer.headless())
    try {
        let theme = Theme.light()
        let toolbar = Toolbar()
        let button = ToolButton(ToolIcon.Save, tooltip: "Save")
        toolbar.add(button)
        let size = toolbar.measure(canvas, theme)
        toolbar.draw(canvas, Rect(0.0, 0.0, size.w, size.h), theme)

        // A press on chrome must not also reach the chart underneath.
        let press = toolbar.handle(UiEvent.MouseDown(MouseButton.Left, button.bounds.centerX(), button.bounds.centerY()))
        @Expect(press.consumed)

        // A hover repaints but must keep flowing, or the crosshair would freeze crossing the bar.
        let hover = toolbar.handle(UiEvent.MouseMove(button.bounds.centerX(), button.bounds.centerY()))
        @Expect(!hover.consumed)
        @Expect(hover.redraw)
    } finally {
        canvas.close()
    }
}

@Test
func emptyToolbarMeasuresToNothing(): Unit {
    let canvas = Canvas(Renderer.headless())
    try {
        let size = Toolbar().measure(canvas, Theme.light())

        @Expect(size.w, 0.0)
        @Expect(size.h, 0.0)
    } finally {
        canvas.close()
    }
}

@Test
func hoverReadoutTracksOnlyInsideThePanel(): Unit {
    let axes = preparedAxes()
    let hover = HoverReadout()
    let area = axes.dataArea()

    @Expect(hover.handle(UiEvent.MouseMove(area.centerX(), area.centerY()), axes))
    // Leaving the panel still needs one redraw, to clear the crosshair that was drawn.
    @Expect(hover.handle(UiEvent.MouseMove(-99.0, -99.0), axes))
    // Once out, further outside moves change nothing.
    @Expect(!hover.handle(UiEvent.MouseMove(-120.0, -120.0), axes))
}

@Test
func cursorStatusReportsCoordinatesOnlyOverThePanel(): Unit {
    let axes = preparedAxes()
    let status = CursorStatus()
    let area = axes.dataArea()

    @Expect(status.update(UiEvent.MouseMove(area.centerX(), area.centerY()), axes))
    let canvas = Canvas(Renderer.headless())
    try {
        @Expect(status.measure(canvas, Theme.light()).w > 0.0)
        // Off the panel the readout empties, and an empty readout takes no space.
        @Expect(status.update(UiEvent.MouseMove(-99.0, -99.0), axes))
        @Expect(status.measure(canvas, Theme.light()).w, 0.0)
    } finally {
        canvas.close()
    }
}

@Test
func eventResponseFactoriesCarryTheRightIntent(): Unit {
    @Expect(!EventResponse.ignored().consumed)
    @Expect(!EventResponse.ignored().redraw)
    @Expect(!EventResponse.repaint().consumed)
    @Expect(EventResponse.repaint().redraw)
    @Expect(EventResponse.handled().consumed)
    @Expect(EventResponse.handled().redraw)
}
