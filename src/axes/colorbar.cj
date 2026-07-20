package plot.axes

import sdl.{Pen, Rect}
import plot.canvas.{Canvas, HAlign, VAlign}
import plot.core.{Bounds, Colormap, Theme, Tick, Ticks}

/** Where a colour bar attaches to its panel. */
public enum ColorBarSide {
    /** A vertical bar to the right of the plot. */
    | Right

    /** A horizontal bar below the plot. */
    | Bottom
}

/** Colour bar geometry, in logical pixels. */
const BAR_THICKNESS: Float32 = 12.0
const BAR_GAP: Float32 = 14.0
const BAR_TICK_GAP: Float32 = 5.0

/**
 * The legend for a continuous colour scale: the ramp itself, with a labelled axis.
 *
 * A heatmap or colour-mapped scatter is unreadable without one — the colours carry the quantity,
 * and nothing else on the panel says what they mean.
 *
 * ```
 * let heat = HeatmapSeries(values, rows: 20, columns: 20)
 * axes.add(heat)
 * axes.setColorBar(ColorBar(heat.resolvedValueRange(), heat.resolvedColormap(figure.theme)))
 * ```
 */
public class ColorBar {
    private let range: Bounds
    private let map: Colormap

    /** Which edge the bar attaches to. */
    public var side: ColorBarSide = ColorBarSide.Right

    /** A caption for the mapped quantity. */
    public var label: String = ""

    /** Roughly how many labelled ticks to place along the bar. */
    public var tickTarget: Int64 = 5

    /** Bar thickness in logical pixels. */
    public var thickness: Float32 = BAR_THICKNESS

    /** How many bands the ramp is drawn with. Higher is smoother. */
    public var resolution: Int64 = 128

    public init(range: Bounds, map: Colormap) {
        this.range = range
        this.map = map
    }

    /** The value range the bar spans. */
    public func valueRange(): Bounds {
        range
    }

    /** The total space the bar needs along its short axis, including labels. */
    public func extent(canvas: Canvas, theme: Theme): Float32 {
        let labels = maxTickLabelExtent(canvas, theme)
        var total = thickness + BAR_TICK_GAP + labels + BAR_GAP
        if (!label.isEmpty()) {
            total += canvas.textHeight(size: theme.labelSize) + BAR_TICK_GAP
        }
        total
    }

    /** Draws the bar into `rect`, which should be the strip reserved by `extent`. */
    public func draw(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        match (side) {
            case Right => drawVertical(canvas, rect, theme)
            case Bottom => drawHorizontal(canvas, rect, theme)
        }
    }

    private func drawVertical(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        let bar = Rect(rect.x, rect.y, thickness, rect.h)
        // Draw the ramp as stacked bands. A single gradient primitive only interpolates two colours,
        // and a colormap is a many-stop curve, so banding it finely is what keeps the ramp faithful.
        let step = bar.h / Float32(resolution)
        for (i in 0..resolution) {
            // Value increases upward, matching the y axis it usually sits beside.
            let t = 1.0 - Float64(i) / Float64(resolution - 1)
            canvas.fillRect(Rect(bar.x, bar.y + Float32(i) * step, bar.w, step + 0.6), map.sample(t))
        }
        canvas.strokeRect(bar, Pen(width: 1.0, color: theme.border))
        for (tick in ticks()) {
            let t = normalized(tick.value)
            let y = bar.bottom() - Float32(t) * bar.h
            canvas.line(bar.right(), y, bar.right() + 3.0, y, Pen(width: 1.0, color: theme.axis))
            canvas.textAnchored(tick.label, bar.right() + 3.0 + BAR_TICK_GAP, y, theme.mutedText, size: theme.tickSize,
                hAlign: HAlign.Left, vAlign: VAlign.Middle)
        }
        if (!label.isEmpty()) {
            canvas.textAnchored(label, bar.x, bar.y - BAR_TICK_GAP, theme.text, size: theme.labelSize,
                hAlign: HAlign.Left, vAlign: VAlign.Bottom)
        }
    }

    private func drawHorizontal(canvas: Canvas, rect: Rect, theme: Theme): Unit {
        let bar = Rect(rect.x, rect.y, rect.w, thickness)
        let step = bar.w / Float32(resolution)
        for (i in 0..resolution) {
            let t = Float64(i) / Float64(resolution - 1)
            canvas.fillRect(Rect(bar.x + Float32(i) * step, bar.y, step + 0.6, bar.h), map.sample(t))
        }
        canvas.strokeRect(bar, Pen(width: 1.0, color: theme.border))
        for (tick in ticks()) {
            let x = bar.x + Float32(normalized(tick.value)) * bar.w
            canvas.line(x, bar.bottom(), x, bar.bottom() + 3.0, Pen(width: 1.0, color: theme.axis))
            canvas.textAnchored(tick.label, x, bar.bottom() + 3.0 + BAR_TICK_GAP, theme.mutedText, size: theme.tickSize,
                hAlign: HAlign.Center, vAlign: VAlign.Top)
        }
        if (!label.isEmpty()) {
            canvas.textAnchored(label, bar.centerX(),
                bar.bottom() + 3.0 + BAR_TICK_GAP + canvas.textHeight(size: theme.tickSize) + BAR_TICK_GAP, theme.text,
                size: theme.labelSize, hAlign: HAlign.Center, vAlign: VAlign.Top)
        }
    }

    private func ticks(): Array<Tick> {
        Ticks.linear(range, target: tickTarget)
    }

    private func normalized(value: Float64): Float64 {
        if (range.span() <= 0.0) {
            return 0.5
        }
        (value - range.low) / range.span()
    }

    private func maxTickLabelExtent(canvas: Canvas, theme: Theme): Float32 {
        match (side) {
            case Right =>
                var widest = 0.0f32
                for (tick in ticks()) {
                    let width = canvas.textWidth(tick.label, size: theme.tickSize)
                    if (width > widest) {
                        widest = width
                    }
                }
                widest
            case Bottom => canvas.textHeight(size: theme.tickSize)
        }
    }
}
