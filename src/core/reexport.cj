package plot.core

/*
 * Geometry and colour re-exports.
 *
 * These types come from `sdl`, but they are part of `plot`'s own surface: a caller sets a series
 * colour, insets a rectangle, or builds a pen for a custom annotation. Re-exporting them here means
 * a consumer declares one dependency and writes `import plot.core.Color` rather than taking a
 * direct dependency on `sdl` — which cjpm requires for any package named in an import — just to
 * name the colour of a line.
 */
public import sdl.Color
public import sdl.Insets
public import sdl.Pen
public import sdl.Point
public import sdl.Rect
public import sdl.Size
public import sdl.FontStyle

/*
 * `Renderer` is here for the same reason: `Canvas` is public and takes one, so driving a custom
 * render loop — or building a Canvas over `Renderer.headless()` in a test — would otherwise force a
 * direct `sdl` dependency on the consumer.
 */
public import sdl.Renderer

/* Raised by the sdl layer on a native failure; callers catching plot errors need to name it too. */
public import sdl.CuiException
