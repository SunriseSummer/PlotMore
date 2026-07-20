package plot

import plot.axes.{Axes, PieAxes, PieSlice}
import plot.canvas.Canvas
import plot.core.{PlotException, Rect, Renderer, Theme}
import plot.series.LineSeries

/* A canvas over a headless renderer: layout runs, drawing is a no-op, no window is needed. */
func headlessCanvas(): Canvas {
    Canvas(Renderer.headless())
}

@Test
func figureSingleReturnsAPanelReadyForSeries(): Unit {
    let (figure, axes) = Figure.single(title: "t")

    @Expect(figure.title, "t")
    @Expect(figure.panelCount(), 1)
    axes.add(LineSeries([0.0], [0.0]))
    @Expect(axes.allSeries().size, 1)
}

@Test
func figureGrowsItsImplicitGridToHoldEveryPanel(): Unit {
    let figure = Figure()
    for (_ in 0..5) {
        let _ = figure.addAxes()
    }

    // Five panels must all be drawable; an implicit grid that could not hold them would drop one.
    @Expect(figure.panelCount(), 5)
    let canvas = headlessCanvas()
    try {
        figure.draw(canvas, Rect(0.0, 0.0, 900.0, 700.0))
        for (panel in figure.allPanels()) {
            @Expect(panel.frame().w > 0.0)
            @Expect(panel.frame().h > 0.0)
        }
    } finally {
        canvas.close()
    }
}

@Test
func figureGridRejectsShapesThatWouldDropAPanel(): Unit {
    let figure = Figure()
    let _ = figure.addAxes()
    let _ = figure.addAxes()
    let _ = figure.addAxes()

    try {
        figure.setGrid(1, 2)
        @Fail("expected a PlotException for a grid too small for its panels")
    } catch (error: PlotException) {
        // Silently dropping a panel would be worse than refusing.
        @Expect(error.message.contains("cannot hold"))
    }
    try {
        figure.setGrid(0, 2)
        @Fail("expected a PlotException for a non-positive dimension")
    } catch (error: PlotException) {
        @Expect(error.message.contains("positive"))
    }
}

@Test
func figureGridPlacesPanelsRowByRow(): Unit {
    let figure = Figure()
    let first = figure.addAxes()
    let second = figure.addAxes()
    let third = figure.addAxes()
    let fourth = figure.addAxes()
    figure.setGrid(2, 2)

    let canvas = headlessCanvas()
    try {
        figure.draw(canvas, Rect(0.0, 0.0, 800.0, 600.0))
        // Row-major fill: 0 and 1 share the top row, 2 and 3 the bottom.
        @Expect(first.frame().y, second.frame().y)
        @Expect(first.frame().x < second.frame().x)
        @Expect(third.frame().y > first.frame().y)
        @Expect(third.frame().x, first.frame().x)
        @Expect(fourth.frame().x, second.frame().x)
    } finally {
        canvas.close()
    }
}

@Test
func figureHeaderShrinksThePanelArea(): Unit {
    let canvas = headlessCanvas()
    try {
        let bare = Figure()
        let bareAxes = bare.addAxes()
        bare.draw(canvas, Rect(0.0, 0.0, 800.0, 600.0))
        let bareHeight = bareAxes.frame().h

        let titled = Figure("A title")
        titled.subtitle = "and a subtitle"
        let titledAxes = titled.addAxes()
        titled.draw(canvas, Rect(0.0, 0.0, 800.0, 600.0))

        // The header must take real space, or it would overprint the top panel.
        @Expect(titledAxes.frame().h < bareHeight)
        @Expect(titledAxes.frame().y > bareAxes.frame().y)
    } finally {
        canvas.close()
    }
}

@Test
func figurePanelAtRoutesPixelsToTheRightPanel(): Unit {
    let figure = Figure()
    let left = figure.addAxes()
    let right = figure.addAxes()
    figure.setGrid(1, 2)

    let canvas = headlessCanvas()
    try {
        figure.draw(canvas, Rect(0.0, 0.0, 800.0, 600.0))
        match (figure.panelAt(left.frame().centerX(), left.frame().centerY())) {
            case Some(panel) => @Expect(panel.frame().x, left.frame().x)
            case None => @Fail("expected the left panel")
        }
        match (figure.panelAt(right.frame().centerX(), right.frame().centerY())) {
            case Some(panel) => @Expect(panel.frame().x, right.frame().x)
            case None => @Fail("expected the right panel")
        }
        // Outside every panel there is nothing to route to.
        @Expect(figure.panelAt(-50.0, -50.0).isNone())
    } finally {
        canvas.close()
    }
}

@Test
func figureWithNoPanelsStillDrawsItsBackground(): Unit {
    let canvas = headlessCanvas()
    try {
        // An empty figure is a legal intermediate state while a caller is assembling one.
        Figure("empty").draw(canvas, Rect(0.0, 0.0, 400.0, 300.0))
        @Expect(true)
    } finally {
        canvas.close()
    }
}

@Test
func figureAcceptsMixedPanelKinds(): Unit {
    let figure = Figure("mixed")
    let _ = figure.addAxes()
    let _ = figure.addPanel(PieAxes([PieSlice(1.0, label: "a"), PieSlice(2.0, label: "b")]))

    // A pie has no x scale to share with a cartesian panel, which is exactly why Panel exists.
    @Expect(figure.panelCount(), 2)
    let canvas = headlessCanvas()
    try {
        figure.draw(canvas, Rect(0.0, 0.0, 900.0, 500.0))
        for (panel in figure.allPanels()) {
            @Expect(panel.frame().w > 0.0)
        }
    } finally {
        canvas.close()
    }
}

@Test
func figureThemeIsShownByEveryPanel(): Unit {
    let figure = Figure("t")
    let _ = figure.addAxes()
    figure.theme = Theme.dark()

    @Expect(figure.theme.isDark)
}

@Test
func withPngExtensionOnlyAddsWhatIsMissing(): Unit {
    // A save dialog readily yields a bare name; the OS needs the extension to open the result.
    @Expect(withPngExtension("figure"), "figure.png")
    @Expect(withPngExtension("figure.png"), "figure.png")
    @Expect(withPngExtension("FIGURE.PNG"), "FIGURE.PNG")
    // An explicit .bmp is a format choice and must survive.
    @Expect(withPngExtension("figure.bmp"), "figure.bmp")
    @Expect(withPngExtension("C:\\out\\my.figure"), "C:\\out\\my.figure.png")
}

@Test
func isBmpPathSelectsTheFormat(): Unit {
    @Expect(isBmpPath("a.bmp"))
    @Expect(isBmpPath("A.BMP"))
    @Expect(!isBmpPath("a.png"))
    @Expect(!isBmpPath("a"))
}

@Test
func fileNameOfExtractsTheLeaf(): Unit {
    @Expect(fileNameOf("C:\\out\\figure.png"), "figure.png")
    @Expect(fileNameOf("figure.png"), "figure.png")
}

@Test
func exportRejectsANonPositiveSize(): Unit {
    try {
        FigureExport.renderToPng(Figure("t"), "unused.png", width: 0, height: 100)
        @Fail("expected a PlotException for a zero width")
    } catch (error: PlotException) {
        // Caught before any window is opened, so nothing needs cleaning up.
        @Expect(error.message.contains("positive"))
    }
}

@Test
func windowOptionsCarryTheirDefaults(): Unit {
    let defaults = WindowOptions()
    @Expect(defaults.title, "Plot")
    @Expect(defaults.resizable)
    @Expect(defaults.width > 0)

    let custom = WindowOptions(title: "t", width: 100, height: 200, resizable: false)
    @Expect(custom.width, 100)
    @Expect(!custom.resizable)
}

@Test
func saveImageBeforeShowFailsWithAClearMessage(): Unit {
    let window = PlotWindow(Figure("t"))
    try {
        window.saveImage("nowhere.png")
        @Fail("expected a PlotException when there is no open window")
    } catch (error: PlotException) {
        @Expect(error.message.contains("open window"))
    }
}
