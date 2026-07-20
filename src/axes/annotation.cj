package plot.axes

import std.collection.ArrayList
import sdl.{Color, Pen, Point, Rect}
import plot.canvas.{Canvas, HAlign, LineStyle, VAlign}
import plot.core.{Colors, Projection, Theme}

/**
 * A marking drawn over the data — a threshold line, a highlighted interval, a label on a feature.
 *
 * Annotations are positioned in *data* coordinates, so they track the data through zoom and pan
 * rather than sitting at a fixed pixel. They draw after every series and are clipped to the panel.
 */
public abstract class Annotation {
    /** Renders the annotation. The panel clip is already active. */
    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit
}

/** A horizontal reference line at a fixed y — a limit, a mean, a target. */
public class HorizontalLine <: Annotation {
    private let value: Float64

    /** The line colour; `None` uses the theme's muted text colour. */
    public var color: ?Color = None

    /** Dash pattern; dashed by default so a reference reads as annotation, not data. */
    public var style: LineStyle = LineStyle.Dashed

    /** Line width in logical pixels. */
    public var width: Float32 = 1.4

    /** An optional caption drawn at the line's right end. */
    public var label: String = ""

    public init(value: Float64) {
        this.value = value
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        if (!projection.y().accepts(value)) {
            return
        }
        let py = projection.pixelY(value)
        let area = projection.area
        let lineColor = color ?? theme.mutedText
        let path = ArrayList<Point>([Point(area.x, py), Point(area.right(), py)])
        canvas.styledPolyline(path, Pen(width: width, color: lineColor), style)
        if (!label.isEmpty()) {
            canvas.textAnchored(label, area.right() - 6.0, py - 4.0, lineColor, size: theme.annotationSize,
                hAlign: HAlign.Right, vAlign: VAlign.Bottom)
        }
    }
}

/** A vertical reference line at a fixed x — an event time, a boundary. */
public class VerticalLine <: Annotation {
    private let value: Float64

    /** The line colour; `None` uses the theme's muted text colour. */
    public var color: ?Color = None

    /** Dash pattern. */
    public var style: LineStyle = LineStyle.Dashed

    /** Line width in logical pixels. */
    public var width: Float32 = 1.4

    /** An optional caption drawn at the line's top. */
    public var label: String = ""

    public init(value: Float64) {
        this.value = value
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        if (!projection.x().accepts(value)) {
            return
        }
        let px = projection.pixelX(value)
        let area = projection.area
        let lineColor = color ?? theme.mutedText
        let path = ArrayList<Point>([Point(px, area.y), Point(px, area.bottom())])
        canvas.styledPolyline(path, Pen(width: width, color: lineColor), style)
        if (!label.isEmpty()) {
            canvas.textAnchored(label, px + 5.0, area.y + 3.0, lineColor, size: theme.annotationSize,
                hAlign: HAlign.Left, vAlign: VAlign.Top)
        }
    }
}

/** A shaded band between two x values — a highlighted interval, a region of interest. */
public class VerticalSpan <: Annotation {
    private let from: Float64
    private let to: Float64

    /** The band colour; `None` uses a faded theme accent. */
    public var color: ?Color = None

    /** Fill opacity, `0..1`. */
    public var opacity: Float64 = 0.12

    /** An optional caption drawn at the band's top centre. */
    public var label: String = ""

    public init(from: Float64, to: Float64) {
        this.from = from
        this.to = to
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let area = projection.area
        let x1 = projection.pixelX(from)
        let x2 = projection.pixelX(to)
        let left = minF32(x1, x2)
        let right = maxOf(x1, x2)
        let fill = Colors.fade(color ?? theme.accent, opacity)
        canvas.fillRect(Rect(left, area.y, right - left, area.h), fill)
        if (!label.isEmpty()) {
            canvas.textAnchored(label, (left + right) / 2.0, area.y + 4.0, theme.mutedText, size: theme.annotationSize,
                hAlign: HAlign.Center, vAlign: VAlign.Top)
        }
    }
}

/** A shaded band between two y values. */
public class HorizontalSpan <: Annotation {
    private let from: Float64
    private let to: Float64

    /** The band colour; `None` uses a faded theme accent. */
    public var color: ?Color = None

    /** Fill opacity, `0..1`. */
    public var opacity: Float64 = 0.12

    public init(from: Float64, to: Float64) {
        this.from = from
        this.to = to
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        let area = projection.area
        let y1 = projection.pixelY(from)
        let y2 = projection.pixelY(to)
        let top = minF32(y1, y2)
        let bottom = maxOf(y1, y2)
        canvas.fillRect(Rect(area.x, top, area.w, bottom - top), Colors.fade(color ?? theme.accent, opacity))
    }
}

/** A text note anchored at a data point, optionally on a rounded backdrop. */
public class TextNote <: Annotation {
    private let dataX: Float64
    private let dataY: Float64
    private let content: String

    /** The text colour; `None` uses the theme's primary text colour. */
    public var color: ?Color = None

    /** Pixel offset from the anchor, letting the note clear the point it describes. */
    public var offsetX: Float32 = 8.0
    public var offsetY: Float32 = -8.0

    /** Draws a backdrop chip so the note stays readable over data. */
    public var boxed: Bool = true

    /** Horizontal anchoring relative to the offset point. */
    public var hAlign: HAlign = HAlign.Left

    /** Vertical anchoring relative to the offset point. */
    public var vAlign: VAlign = VAlign.Bottom

    public init(dataX: Float64, dataY: Float64, content: String) {
        this.dataX = dataX
        this.dataY = dataY
        this.content = content
    }

    public func draw(canvas: Canvas, projection: Projection, theme: Theme): Unit {
        if (!projection.accepts(dataX, dataY) || content.isEmpty()) {
            return
        }
        let anchor = projection.pixel(dataX, dataY)
        let px = anchor.x + offsetX
        let py = anchor.y + offsetY
        if (boxed) {
            let w = canvas.textWidth(content, size: theme.annotationSize)
            let h = canvas.textHeight(size: theme.annotationSize)
            let bx = match (hAlign) {
                case Left => px
                case Center => px - w / 2.0
                case Right => px - w
            }
            let by = match (vAlign) {
                case Top => py
                case Middle => py - h / 2.0
                case Bottom => py - h
            }
            canvas.fillRoundedRect(Rect(bx - 5.0, by - 3.0, w + 10.0, h + 6.0), 4.0, Colors.fade(theme.surface, 0.9))
        }
        canvas.textAnchored(content, px, py, color ?? theme.text, size: theme.annotationSize, hAlign: hAlign,
            vAlign: vAlign)
    }
}

func minF32(a: Float32, b: Float32): Float32 {
    if (a < b) {
        a
    } else {
        b
    }
}
