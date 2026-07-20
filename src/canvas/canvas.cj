package plot.canvas

import std.collection.{ArrayList, HashMap}
import std.math.{cos, sin, sqrt}
import sdl.{Color, FontStyle, Pen, Point, Rect, Renderer, Surface, Texture, TextureBlendMode}
import plot.core.{Colormap, PlotException}

/** Full circle in radians; arcs are sampled against this to pick a segment count. */
const TAU: Float64 = 6.283185307179586

/*
 * Arc sampling: one segment per this many pixels of arc length, clamped by MIN/MAX_ARC_SEGMENTS.
 * Density is what makes a pie edge read as a curve rather than a polygon, and tying it to arc
 * length (not to a fixed count) keeps a small donut cheap and a large one smooth.
 */
const ARC_PIXELS_PER_SEGMENT: Float64 = 3.0
const MIN_ARC_SEGMENTS: Int64 = 8
const MAX_ARC_SEGMENTS: Int64 = 720

/*
 * Cap on distinct cached fill textures. Fills come from series colours, of which a figure has few;
 * the cap only exists so a pathological caller (a per-point colormapped area) cannot leak GPU
 * objects unboundedly. Markers and lines never allocate here — they carry real vertex colours.
 */
const SOLID_CACHE_LIMIT: Int64 = 512

/** Width of the lookup texture backing a gradient fill. 256 stops is past the eye's discrimination. */
const RAMP_TEXTURE_WIDTH: Int64 = 256

/**
 * Width of the anti-aliasing stroke `fillWedge` traces around an opaque wedge. Centred on the
 * boundary, so a wedge grows by half of this on every side — callers spacing wedges apart
 * (`PieAxes.sliceGap`) must budget one full width per gap.
 */
public const WEDGE_EDGE_WIDTH: Float32 = 1.2

/*
 * Texture coordinate for every solid fill. The fill texture is 1x1, so all vertices sample the same
 * lone texel and the coordinate value is irrelevant beyond being in range.
 */
let ORIGIN: Point = Point(0.0, 0.0)

/**
 * The drawing vocabulary every chart type renders through — filled areas, polylines, markers,
 * wedges, and text — layered over `sdl.Renderer`.
 *
 * ## Two fill paths
 *
 * Polygonal fills (`fillPolygon`: radar traces, marker glyphs) go through the renderer's
 * `fillConvexPolygon` — per-vertex coloured, feather-anti-aliased, no texture involved.
 *
 * Band-shaped fills (`fillBand`, `fillWedge`, the gradients) go through `texturedStrip`, a quad
 * strip of (left, right) vertex pairs, because their rung structure is not fan-fillable. That
 * primitive fixes the *vertex* colour to white and `SDL_RenderGeometry` ignores
 * `SDL_SetTextureColorMod`, so the fill colour has to live in the texel: `Canvas` caches a 1x1
 * texture per colour and hands the right one to each fill. Per-vertex alpha still works, which is
 * what makes the gradient area fills possible; continuous colormaps ride a 256-texel lookup ramp.
 *
 * Band fills are therefore the only thing that allocates; polygons, lines, markers, and rectangles
 * go through the renderer's own vertex-coloured paths and cost nothing extra.
 *
 * `Canvas` owns those textures and must be closed. A `PlotWindow` does that for you; construct one
 * directly only if you are driving the render loop yourself.
 *
 * Over `Renderer.headless()` every entry point is a no-op, so layout, measurement, and event
 * handling can be exercised without a window — see `isHeadless`.
 */
public class Canvas <: Resource {
    private let target: Renderer
    private let solidCache = HashMap<Int64, Texture>()
    private let rampCache = HashMap<Int64, Texture>()
    private var closed = false

    /*
     * True over `Renderer.headless()`.
     *
     * The renderer's own primitives no-op without a device, but a fill has to build a texture first
     * and `textureFromSurface` throws on a null device rather than no-opping. Fills therefore need
     * their own guard, or a headless canvas — the documented way to exercise layout in a test —
     * would throw the moment anything filled. `driverName` is the public tell.
     */
    private let deviceless: Bool

    public init(renderer: Renderer) {
        this.target = renderer
        this.deviceless = renderer.driverName() == "headless"
    }

    /** The underlying renderer, for the rare case a caller needs a primitive Canvas does not wrap. */
    public func renderer(): Renderer {
        target
    }

    /**
     * True when this canvas has no render device, so fills are skipped.
     *
     * Lets a caller driving its own loop tell a headless canvas from a real one; the chart types do
     * not need it, since every drawing entry point already no-ops.
     */
    public func isHeadless(): Bool {
        deviceless
    }

    // --- fills -------------------------------------------------------------------------------

    /**
     * Fills a band between two same-length pixel boundaries — `upper[i]` to `lower[i]` at each
     * station. This is the general fill: an area chart passes the series and the baseline, a violin
     * passes the two mirrored densities, a confidence ribbon passes its two envelopes.
     *
     * The boundaries need not be x-monotone, but each rung is filled independently, so the shape is
     * only well defined when consecutive rungs do not cross.
     *
     * `upperAlpha`/`lowerAlpha` fade the fill across each rung, which is how the area charts get
     * their gradient toward the baseline. Nothing is drawn for fewer than two stations.
     *
     * Throws `PlotException` when the two boundaries differ in length.
     */
    public func fillBand(
        upper: ArrayList<Point>,
        lower: ArrayList<Point>,
        color: Color,
        upperAlpha!: Float32 = 1.0,
        lowerAlpha!: Float32 = 1.0
    ): Unit {
        if (upper.size != lower.size) {
            throw PlotException("fillBand needs matching boundaries; got ${upper.size} and ${lower.size} points.")
        }
        // Validate first, then bail: a headless caller should still hear about a bad argument.
        if (upper.size < 2 || deviceless) {
            return
        }
        let points = ArrayList<Point>()
        let texPoints = ArrayList<Point>()
        let alphas = ArrayList<Float32>()
        for (i in 0..upper.size) {
            points.add(upper[i])
            points.add(lower[i])
            texPoints.add(ORIGIN)
            texPoints.add(ORIGIN)
            alphas.add(upperAlpha)
            alphas.add(lowerAlpha)
        }
        target.texturedStrip(solidTexture(color), points, texPoints, alphas: alphas)
    }

    /**
     * Fills a polygon by fanning from its first vertex.
     *
     * Correct for convex outlines and for concave ones that stay star-shaped about `points[0]` —
     * which covers the shapes charts actually build (wedges, radar polygons, closed areas). A
     * general concave outline would need real triangulation and is not supported; use `fillBand`,
     * whose rung structure expresses those shapes directly.
     */
    public func fillPolygon(points: ArrayList<Point>, color: Color): Unit {
        // Delegates to the renderer's feathered polygon fill, so the edge is analytically
        // anti-aliased instead of leaning on the supersample resolve alone. No texture is
        // involved, so this works headless and never touches the fill-colour cache.
        target.fillConvexPolygon(points, color)
    }

    /**
     * Fills an annular wedge: the pie slice from `startAngle` to `endAngle` between `innerRadius`
     * and `outerRadius`, with angles in radians measured clockwise from twelve o'clock.
     *
     * An `innerRadius` of zero gives a solid pie slice; anything larger gives a donut segment.
     *
     * `smoothEdge` (on by default) restrokes the wedge boundary with the fill colour. The fill
     * itself is a hard-edged triangle strip whose only anti-aliasing is the frame's supersample
     * resolve, and at four samples per pixel a saturated slice against a light panel still shows
     * stair-stepping; the strokes are feathered stadium meshes, so tracing the boundary with them
     * is what makes the rim read as a smooth curve. Skipped automatically for translucent fills,
     * where restroking would double the alpha along the rim into a visible dark outline.
     */
    public func fillWedge(
        centerX: Float32,
        centerY: Float32,
        innerRadius: Float32,
        outerRadius: Float32,
        startAngle: Float64,
        endAngle: Float64,
        color: Color,
        smoothEdge!: Bool = true
    ): Unit {
        if (outerRadius <= 0.0 || deviceless) {
            return
        }
        let inner = maxF(innerRadius, 0.0)
        let segments = arcSegments(endAngle - startAngle, outerRadius)
        let points = ArrayList<Point>()
        let texPoints = ArrayList<Point>()
        let innerArc = ArrayList<Point>()
        let outerArc = ArrayList<Point>()
        for (i in 0..=segments) {
            let t = Float64(i) / Float64(segments)
            let angle = startAngle + (endAngle - startAngle) * t
            let dx = Float32(sin(angle))
            let dy = Float32(-cos(angle))
            let innerPoint = Point(centerX + dx * inner, centerY + dy * inner)
            let outerPoint = Point(centerX + dx * outerRadius, centerY + dy * outerRadius)
            points.add(innerPoint)
            points.add(outerPoint)
            texPoints.add(ORIGIN)
            texPoints.add(ORIGIN)
            innerArc.add(innerPoint)
            outerArc.add(outerPoint)
        }
        target.texturedStrip(solidTexture(color), points, texPoints)
        if (smoothEdge && color.a == 255) {
            strokeWedgeBoundary(innerArc, outerArc, inner, color)
        }
    }

    /*
     * The closed boundary of a wedge, traced with round-capped strokes: out along the start edge,
     * around the outer arc, back along the end edge, and home along the inner arc. A pie (inner
     * radius zero) collapses the inner arc to the centre point, which the polyline handles as a
     * pair of radial edges meeting there.
     */
    private func strokeWedgeBoundary(
        innerArc: ArrayList<Point>,
        outerArc: ArrayList<Point>,
        inner: Float32,
        color: Color
    ): Unit {
        let boundary = ArrayList<Point>(outerArc)
        if (inner > 0.5) {
            var i = innerArc.size - 1
            while (i >= 0) {
                boundary.add(innerArc[i])
                i -= 1
            }
        } else {
            boundary.add(innerArc[0])
        }
        boundary.add(outerArc[0])
        polyline(boundary, Pen(width: WEDGE_EDGE_WIDTH, color: color))
    }

    /**
     * Fills a band whose colour follows `map` along the rungs, sampling the ramp from `fromT` at
     * the first station to `toT` at the last.
     *
     * Vertex colour is fixed to white by the strip primitive, so a true multi-colour gradient has to
     * come from the texture: this builds a 256-stop lookup texture for the ramp and walks the
     * texture coordinate across it. Sampling lands on texel centres so neighbouring stops never
     * bleed together.
     *
     * Throws `PlotException` when the two boundaries differ in length.
     */
    public func fillBandGradient(
        upper: ArrayList<Point>,
        lower: ArrayList<Point>,
        map: Colormap,
        fromT!: Float64 = 0.0,
        toT!: Float64 = 1.0,
        upperAlpha!: Float32 = 1.0,
        lowerAlpha!: Float32 = 1.0
    ): Unit {
        if (upper.size != lower.size) {
            throw PlotException(
                "fillBandGradient needs matching boundaries; got ${upper.size} and ${lower.size} points.")
        }
        if (upper.size < 2 || deviceless) {
            return
        }
        let texture = rampTexture(map)
        let points = ArrayList<Point>()
        let texPoints = ArrayList<Point>()
        let alphas = ArrayList<Float32>()
        let last = Float64(upper.size - 1)
        for (i in 0..upper.size) {
            let t = fromT + (toT - fromT) * (Float64(i) / last)
            let u = Float32(clampUnit(t) * Float64(RAMP_TEXTURE_WIDTH - 1)) + 0.5
            points.add(upper[i])
            points.add(lower[i])
            texPoints.add(Point(u, 0.5))
            texPoints.add(Point(u, 0.5))
            alphas.add(upperAlpha)
            alphas.add(lowerAlpha)
        }
        target.texturedStrip(texture, points, texPoints, alphas: alphas)
    }

    /** A filled axis-aligned rectangle. */
    public func fillRect(rect: Rect, color: Color): Unit {
        target.fill(rect, color)
    }

    /** A filled rectangle with rounded corners; falls back to a plain fill at radius zero. */
    public func fillRoundedRect(rect: Rect, radius: Float32, color: Color): Unit {
        target.fillRoundedRect(rect, radius, color)
    }

    /** A filled rectangle with independent corner radii — used for stacked-bar end caps. */
    public func fillPerCornerRect(
        rect: Rect,
        color: Color,
        topLeft!: Float32,
        topRight!: Float32,
        bottomRight!: Float32,
        bottomLeft!: Float32
    ): Unit {
        target.fillPerCornerRoundedRect(rect, color, topLeft: topLeft, topRight: topRight, bottomRight: bottomRight,
            bottomLeft: bottomLeft)
    }

    /** A vertically or horizontally graded rectangle fill. */
    public func fillRectGradient(rect: Rect, radius: Float32, from: Color, to: Color, vertical!: Bool = true): Unit {
        target.fillRoundedRectGradient(rect, radius, from, to, vertical: vertical)
    }

    /** A rounded rectangle whose edge fades across `feather` pixels — the soft-shadow primitive. */
    public func fillSoftRect(rect: Rect, radius: Float32, color: Color, feather!: Float32): Unit {
        target.fillRoundedRectSoft(rect, radius, color, feather: feather)
    }

    /** A filled circle. */
    public func fillCircle(centerX: Float32, centerY: Float32, radius: Float32, color: Color): Unit {
        target.fillCircle(centerX, centerY, radius, color)
    }

    // --- strokes -----------------------------------------------------------------------------

    /** A single anti-aliased, round-capped segment. */
    public func line(x1: Float32, y1: Float32, x2: Float32, y2: Float32, pen: Pen): Unit {
        target.strokeLine(x1, y1, x2, y2, pen)
    }

    /** Connects `points` with round-capped segments, which join without notches at any angle. */
    public func polyline(points: ArrayList<Point>, pen: Pen): Unit {
        if (points.size < 2) {
            return
        }
        for (i in 0..points.size - 1) {
            target.strokeLine(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y, pen)
        }
    }

    /**
     * Connects `points` with a dashed stroke, marching the on/off pattern continuously across
     * segment boundaries so the rhythm does not restart at every vertex.
     */
    public func dashedPolyline(points: ArrayList<Point>, pen: Pen, dash: Float32, gap: Float32): Unit {
        if (points.size < 2 || dash <= 0.0 || gap <= 0.0) {
            polyline(points, pen)
            return
        }
        let period = dash + gap
        var phase: Float32 = 0.0
        for (i in 0..points.size - 1) {
            let from = points[i]
            let to = points[i + 1]
            let dx = to.x - from.x
            let dy = to.y - from.y
            let length = Float32(sqrt(Float64(dx * dx + dy * dy)))
            if (length <= 0.0) {
                continue
            }
            let ux = dx / length
            let uy = dy / length
            var travelled: Float32 = 0.0
            while (travelled < length) {
                // `phase` carries the pattern position across the vertex, so a polyline of many
                // short segments dashes as if it were one long path.
                let inDash = phase < dash
                let remaining = if (inDash) {
                    dash - phase
                } else {
                    period - phase
                }
                let step = minF(remaining, length - travelled)
                if (inDash) {
                    let sx = from.x + ux * travelled
                    let sy = from.y + uy * travelled
                    target.strokeLine(sx, sy, sx + ux * step, sy + uy * step, pen)
                }
                travelled += step
                phase += step
                if (phase >= period) {
                    phase -= period
                }
            }
        }
    }

    /** Strokes `points` in the given `style`; a `NoLine` style draws nothing. */
    public func styledPolyline(points: ArrayList<Point>, pen: Pen, style: LineStyle): Unit {
        if (style.isHidden()) {
            return
        }
        match (style.dashPattern(pen.width)) {
            case Some((dash, gap)) => dashedPolyline(points, pen, dash, gap)
            case None => polyline(points, pen)
        }
    }

    /** A rectangle outline. */
    public func strokeRect(rect: Rect, pen: Pen): Unit {
        target.strokeRect(rect, pen)
    }

    /** A rounded-rectangle outline. */
    public func strokeRoundedRect(rect: Rect, radius: Float32, pen: Pen): Unit {
        target.strokeRoundedRect(rect, radius, pen)
    }

    /** A circle outline. */
    public func strokeCircle(centerX: Float32, centerY: Float32, radius: Float32, pen: Pen): Unit {
        target.strokeCircle(centerX, centerY, radius, pen)
    }

    /** An arc outline, sampled densely enough to read as a curve at `radius`. */
    public func arc(
        centerX: Float32,
        centerY: Float32,
        radius: Float32,
        startAngle: Float64,
        endAngle: Float64,
        pen: Pen
    ): Unit {
        let segments = arcSegments(endAngle - startAngle, radius)
        let points = ArrayList<Point>()
        for (i in 0..=segments) {
            let angle = startAngle + (endAngle - startAngle) * (Float64(i) / Float64(segments))
            points.add(Point(centerX + Float32(sin(angle)) * radius, centerY - Float32(cos(angle)) * radius))
        }
        polyline(points, pen)
    }

    // --- markers -----------------------------------------------------------------------------

    /**
     * Draws a marker glyph centred on the point. `size` is the circumscribed radius, so shapes stay
     * visually comparable. Filled shapes take `edge` as an outline; stroked shapes ignore it.
     */
    public func marker(
        style: MarkerStyle,
        x: Float32,
        y: Float32,
        size: Float32,
        color: Color,
        edge!: ?Pen = None
    ): Unit {
        if (style.isHidden() || size <= 0.0) {
            return
        }
        match (style) {
            case Circle =>
                target.fillCircle(x, y, size, color)
                strokeEdge(edge) {pen => target.strokeCircle(x, y, size, pen)}
            case Ring => target.strokeCircle(x, y, size, edgePen(edge, color, size))
            case Square =>
                let side = size * 1.6
                let rect = Rect(x - side / 2.0, y - side / 2.0, side, side)
                target.fill(rect, color)
                strokeEdge(edge) {pen => target.strokeRect(rect, pen)}
            case Diamond => fillAndEdge(x, y, polygonPoints(x, y, size * 1.25, 4, 0.0), color, edge)
            case Triangle => fillAndEdge(x, y, polygonPoints(x, y, size * 1.25, 3, 0.0), color, edge)
            case TriangleDown => fillAndEdge(x, y, polygonPoints(x, y, size * 1.25, 3, TAU / 2.0), color, edge)
            case Star => fillAndEdge(x, y, starPoints(x, y, size * 1.35, size * 0.55, 5), color, edge)
            case Plus =>
                let pen = edgePen(edge, color, size)
                target.strokeLine(x - size, y, x + size, y, pen)
                target.strokeLine(x, y - size, x, y + size, pen)
            case Cross =>
                let pen = edgePen(edge, color, size)
                let d = size * 0.75
                target.strokeLine(x - d, y - d, x + d, y + d, pen)
                target.strokeLine(x - d, y + d, x + d, y - d, pen)
            case NoMarker => ()
        }
    }

    // --- text --------------------------------------------------------------------------------

    /** Draws text with its top-left corner at `(x, y)`. */
    public func text(
        content: String,
        x: Float32,
        y: Float32,
        color: Color,
        size!: Float32 = 13.0,
        style!: FontStyle = FontStyle.regular
    ): Unit {
        target.text(content, x, y, color, pointSize: size, style: style)
    }

    /** Draws text anchored at `(x, y)` according to the two alignments. */
    public func textAnchored(
        content: String,
        x: Float32,
        y: Float32,
        color: Color,
        size!: Float32 = 13.0,
        hAlign!: HAlign = HAlign.Left,
        vAlign!: VAlign = VAlign.Top,
        style!: FontStyle = FontStyle.regular
    ): Unit {
        if (content.isEmpty()) {
            return
        }
        let width = target.textWidth(content, pointSize: size, style: style)
        let height = target.textHeight(pointSize: size, style: style)
        let tx = match (hAlign) {
            case Left => x
            case Center => x - width / 2.0
            case Right => x - width
        }
        let ty = match (vAlign) {
            case Top => y
            case Middle => y - height / 2.0
            case Bottom => y - height
        }
        target.text(content, tx, ty, color, pointSize: size, style: style)
    }

    /** Draws text centred in a rectangle. */
    public func textCentered(
        content: String,
        rect: Rect,
        color: Color,
        size!: Float32 = 13.0,
        style!: FontStyle = FontStyle.regular
    ): Unit {
        target.textCenter(content, rect, color, pointSize: size, style: style)
    }

    /**
     * Draws text rotated by `angleDegrees` (clockwise; -90 reads bottom-to-top), centred on
     * `(centerX, centerY)` — the primitive behind rotated axis titles.
     *
     * The renderer rasterizes the string once into a cached texture and draws it through the
     * rotating texture pipeline, so a static rotated label costs one rasterization, not one per
     * frame. Headless and empty text no-op.
     */
    public func textRotated(
        content: String,
        centerX: Float32,
        centerY: Float32,
        angleDegrees: Float64,
        color: Color,
        size!: Float32 = 13.0,
        style!: FontStyle = FontStyle.regular
    ): Unit {
        target.textRotated(content, centerX, centerY, angleDegrees, color, pointSize: size, style: style)
    }

    /**
     * Draws text as a vertical stack of characters, centred on `x` and starting at `y`.
     *
     * This is how y-axis titles are drawn. SDL3_ttf rasterizes into the render target and the
     * wrapper exposes no way to rotate that, so a true 90-degree label is out of reach; a stack
     * reads cleanly and is the conventional vertical form for CJK text anyway. `Axes` offers a
     * horizontal y-title as the alternative.
     */
    public func textStacked(
        content: String,
        x: Float32,
        y: Float32,
        color: Color,
        size!: Float32 = 13.0,
        style!: FontStyle = FontStyle.regular
    ): Unit {
        if (content.isEmpty()) {
            return
        }
        let lineHeight = target.textHeight(pointSize: size, style: style) * 0.92
        var row = y
        // Iterate runes, not bytes: a byte walk would split every multi-byte character.
        for (glyph in content.runes()) {
            let glyphText = String(glyph)
            if (glyphText == " ") {
                row += lineHeight * 0.5
                continue
            }
            let width = target.textWidth(glyphText, pointSize: size, style: style)
            target.text(glyphText, x - width / 2.0, row, color, pointSize: size, style: style)
            row += lineHeight
        }
    }

    /** The rendered width of `content` at `size`. */
    public func textWidth(content: String, size!: Float32 = 13.0, style!: FontStyle = FontStyle.regular): Float32 {
        target.textWidth(content, pointSize: size, style: style)
    }

    /** The line height at `size`. */
    public func textHeight(size!: Float32 = 13.0, style!: FontStyle = FontStyle.regular): Float32 {
        target.textHeight(pointSize: size, style: style)
    }

    /** The height a `textStacked` call would occupy. */
    public func stackedTextHeight(content: String, size!: Float32 = 13.0): Float32 {
        var count = 0
        for (_ in content.runes()) {
            count += 1
        }
        target.textHeight(pointSize: size) * 0.92 * Float32(count)
    }

    // --- clipping ----------------------------------------------------------------------------

    /** Narrows drawing to `rect` intersected with any active clip. Pair with `popClip`. */
    public func pushClip(rect: Rect): Unit {
        target.pushClip(rect)
    }

    /** Restores the clip from before the matching `pushClip`. */
    public func popClip(): Unit {
        target.popClip()
    }

    // --- lifecycle ---------------------------------------------------------------------------

    public func isClosed(): Bool {
        closed
    }

    /** Releases every cached fill texture. Idempotent. */
    public func close(): Unit {
        if (closed) {
            return
        }
        closed = true
        for ((_, texture) in solidCache) {
            texture.close()
        }
        solidCache.clear()
        for ((_, texture) in rampCache) {
            texture.close()
        }
        rampCache.clear()
    }

    // --- internals ---------------------------------------------------------------------------

    /*
     * The 1x1 texture carrying `color`, created on first use. Keyed by the packed RGBA so two
     * fills of the same colour share one texture; see the class comment for why the colour cannot
     * simply be a colour-mod.
     */
    private func solidTexture(color: Color): Texture {
        let key = packColor(color)
        match (solidCache.get(key)) {
            case Some(texture) => return texture
            case None => ()
        }
        if (solidCache.size >= SOLID_CACHE_LIMIT) {
            throw PlotException(
                "Fill-colour cache exhausted at ${SOLID_CACHE_LIMIT} entries. Filled shapes cache one " +
                    "texture per distinct colour; colour markers or lines instead of filled areas for " +
                    "per-point colouring.")
        }
        let texture = makeTexture(1, 1) {surface => surface.clear(color)}
        solidCache[key] = texture
        texture
    }

    // The lookup texture for a ramp, keyed by the ramp's sampled endpoints and midpoint. Two
    // Colormaps that sample identically at those points share a texture, which is what makes
    // repeated `Colormap.viridis()` calls in a draw loop free.
    private func rampTexture(map: Colormap): Texture {
        let key = packColor(map.sample(0.0)) ^ (packColor(map.sample(0.5)) * 31) ^ (packColor(map.sample(1.0)) * 131)
        match (rampCache.get(key)) {
            case Some(texture) => return texture
            case None => ()
        }
        let stops = map.ramp(RAMP_TEXTURE_WIDTH)
        let texture = makeTexture(Int32(RAMP_TEXTURE_WIDTH), 1) {
            surface => for (i in 0..RAMP_TEXTURE_WIDTH) {
                surface.writePixel(Int32(i), 0, stops[i])
            }
        }
        rampCache[key] = texture
        texture
    }

    private func makeTexture(width: Int32, height: Int32, paint: (Surface) -> Unit): Texture {
        let surface = Surface.create(width, height)
        try {
            paint(surface)
            let texture = target.textureFromSurface(surface)
            texture.setBlendMode(TextureBlendMode.Blend)
            return texture
        } finally {
            surface.close()
        }
    }

    /*
     * Fills a marker outline and strokes its edge.
     *
     * The fill fans about the marker's centre, not about its first vertex. A star is star-shaped
     * about its centre but NOT about a tip: with the tip as the anchor, the chord between two tips
     * passes outside the notch between them, and the fan paints over it — a visibly blobby star
     * inside a correct outline. Convex glyphs are indifferent to the anchor, so routing all of them
     * through the centre costs two degenerate triangles and removes the trap.
     */
    private func fillAndEdge(centerX: Float32, centerY: Float32, points: ArrayList<Point>, color: Color, edge: ?Pen): Unit {
        let fan = ArrayList<Point>()
        fan.add(Point(centerX, centerY))
        for (point in points) {
            fan.add(point)
        }
        fan.add(points[0])
        fillPolygon(fan, color)
        strokeEdge(edge) {
            pen =>
                let closedPath = ArrayList<Point>(points)
                closedPath.add(points[0])
                polyline(closedPath, pen)
        }
    }

    private func strokeEdge(edge: ?Pen, draw: (Pen) -> Unit): Unit {
        match (edge) {
            case Some(pen) => draw(pen)
            case None => ()
        }
    }

    private func edgePen(edge: ?Pen, color: Color, size: Float32): Pen {
        match (edge) {
            case Some(pen) => pen
            case None => Pen(width: maxF(1.2, size * 0.45), color: color)
        }
    }
}

/** Segments to sample an arc of `sweep` radians at `radius` pixels, dense enough to read as smooth. */
func arcSegments(sweep: Float64, radius: Float32): Int64 {
    let arcLength = absF64(sweep) * Float64(radius)
    var segments = Int64(arcLength / ARC_PIXELS_PER_SEGMENT) + 1
    if (segments < MIN_ARC_SEGMENTS) {
        segments = MIN_ARC_SEGMENTS
    }
    if (segments > MAX_ARC_SEGMENTS) {
        segments = MAX_ARC_SEGMENTS
    }
    segments
}

/** The vertices of a regular `sides`-gon, first vertex at `rotation` radians from twelve o'clock. */
func polygonPoints(cx: Float32, cy: Float32, radius: Float32, sides: Int64, rotation: Float64): ArrayList<Point> {
    let points = ArrayList<Point>()
    for (i in 0..sides) {
        let angle = rotation + TAU * Float64(i) / Float64(sides)
        points.add(Point(cx + Float32(sin(angle)) * radius, cy - Float32(cos(angle)) * radius))
    }
    points
}

/** The vertices of a star alternating between `outer` and `inner` radii. */
func starPoints(cx: Float32, cy: Float32, outer: Float32, inner: Float32, points: Int64): ArrayList<Point> {
    let result = ArrayList<Point>()
    let total = points * 2
    for (i in 0..total) {
        let radius = if (i % 2 == 0) {
            outer
        } else {
            inner
        }
        let angle = TAU * Float64(i) / Float64(total)
        result.add(Point(cx + Float32(sin(angle)) * radius, cy - Float32(cos(angle)) * radius))
    }
    result
}

func packColor(color: Color): Int64 {
    (Int64(color.r) << 24) | (Int64(color.g) << 16) | (Int64(color.b) << 8) | Int64(color.a)
}

func clampUnit(value: Float64): Float64 {
    if (value < 0.0) {
        0.0
    } else if (value > 1.0) {
        1.0
    } else {
        value
    }
}

func absF64(value: Float64): Float64 {
    if (value < 0.0) {
        -value
    } else {
        value
    }
}

func minF(a: Float32, b: Float32): Float32 {
    if (a < b) {
        a
    } else {
        b
    }
}

func maxF(a: Float32, b: Float32): Float32 {
    if (a > b) {
        a
    } else {
        b
    }
}
