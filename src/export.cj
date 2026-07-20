package plot

import std.fs.{Path, removeIfExists}
import sdl.{Rect, Renderer, SdlWindow, WindowSpec}
import plot.canvas.Canvas
import plot.core.PlotException
import plot.image.{Bmp, Png}

/**
 * Writing a figure to an image file.
 *
 * ## Why this takes the route it does
 *
 * `sdl` can read the render target back only as a BMP file (`Renderer.captureBmp`), and the Cangjie
 * toolchain here ships no zlib, so PNG cannot be delegated to a library. `savePng` therefore
 * captures a BMP to a temporary file, decodes it, and re-encodes it as PNG with the encoder in
 * `plot.image`. The temporary file is always removed, including on failure.
 *
 * `saveBmp` skips the round trip when the extra fidelity of PNG is not wanted.
 *
 * ## Resolution
 *
 * Capturing between `beginScene` and `endScene` reads the renderer's *supersampled* target, which
 * is `Renderer.supersampleFactor()` times the requested size per axis. An export at 1200x800 lands
 * on disk at 2400x1600 by default — genuinely rendered at that resolution, not upscaled, because
 * text is rasterized at the supersampled size too. That is what makes the exports usable in a
 * document rather than only on screen.
 */
public class FigureExport {
    /**
     * Renders `figure` at `width` x `height` logical pixels and writes it to `path` as a PNG.
     *
     * Reuses `renderer` — the caller's live window — so the export costs one extra frame and no new
     * GPU context. The frame is never presented, so nothing flickers on screen.
     *
     * Throws `PlotException` when the capture or the encode fails.
     */
    public static func savePng(figure: Figure, renderer: Renderer, canvas: Canvas, path: String, width!: Float32,
        height!: Float32): Unit {
        let temporary = temporaryBmpPath(path)
        try {
            captureFigure(figure, renderer, canvas, temporary, width, height)
            Png.write(Bmp.read(temporary), path)
        } finally {
            // The temporary is an implementation detail and must not survive a failure.
            removeQuietly(temporary)
        }
    }

    /**
     * Renders `figure` and writes it as a BMP — the format `sdl` captures natively, so no decode or
     * re-encode is involved. Larger files; useful when the encoder is not wanted in the path.
     *
     * Throws `PlotException` when the capture fails.
     */
    public static func saveBmp(figure: Figure, renderer: Renderer, canvas: Canvas, path: String, width!: Float32,
        height!: Float32): Unit {
        captureFigure(figure, renderer, canvas, path, width, height)
    }

    /**
     * Renders `figure` to a PNG without an existing window, by opening a hidden one.
     *
     * For batch or headless-style figure generation. A window is still created because SDL needs a
     * renderer to rasterize text and geometry; it is hidden and closed before this returns.
     *
     * Throws `PlotException` when the window cannot be created or the encode fails.
     */
    public static func renderToPng(figure: Figure, path: String, width!: Int64 = 1200, height!: Int64 = 800): Unit {
        if (width < 1 || height < 1) {
            throw PlotException("Export size must be positive; got ${width}x${height}.")
        }
        let window = SdlWindow(WindowSpec("plot export", Int32(width), Int32(height), resizable: false))
        try {
            window.hide()
            let canvas = Canvas(window.renderer)
            try {
                savePng(figure, window.renderer, canvas, path, width: Float32(width), height: Float32(height))
            } finally {
                canvas.close()
            }
        } finally {
            window.close()
        }
    }

    /*
     * One full render into the offscreen target, captured before the scene resolves.
     *
     * The capture sits between beginScene and endScene deliberately: that is when the render target
     * is the high-resolution one. It also means `present` is never called, so the export frame —
     * which has no toolbar or crosshair on it — never reaches the screen.
     */
    private static func captureFigure(figure: Figure, renderer: Renderer, canvas: Canvas, path: String, width: Float32,
        height: Float32): Unit {
        if (width < 1.0 || height < 1.0) {
            throw PlotException("Export size must be positive; got ${width}x${height}.")
        }
        renderer.beginScene(width, height, figure.theme.background)
        try {
            figure.draw(canvas, Rect(0.0, 0.0, width, height))
            renderer.captureBmp(path)
        } finally {
            // Every beginScene owes an endScene. A figure that throws mid-draw would otherwise
            // leave the render target bound to the offscreen supersample texture — the next
            // beginScene rebinds it, but a live window would be drawing into limbo until then.
            renderer.endScene()
        }
    }

    // A sibling of the target so the rename-free write stays on one filesystem, and so a
    // permission problem surfaces at the real destination rather than in a temp directory.
    private static func temporaryBmpPath(path: String): String {
        "${path}.capture.tmp.bmp"
    }

    private static func removeQuietly(path: String): Unit {
        // A failure to clean up a temporary must not mask the real error from the try block.
        try {
            let _ = removeIfExists(Path(path))
        } catch (_: Exception) {
            ()
        }
    }
}

/**
 * Appends `.png` when `path` names no extension, so a caller typing "figure" in a save dialog gets
 * a file the OS can open.
 */
public func withPngExtension(path: String): String {
    let lower = path.toAsciiLower()
    if (lower.endsWith(".png")) {
        return path
    }
    if (lower.endsWith(".bmp")) {
        return path
    }
    "${path}.png"
}

/** True when `path` names a BMP, and so should skip the PNG encoder. */
public func isBmpPath(path: String): Bool {
    path.toAsciiLower().endsWith(".bmp")
}

/** The file name component of `path`, for status messages. */
public func fileNameOf(path: String): String {
    try {
        Path(path).fileName
    } catch (_: Exception) {
        path
    }
}
