package plot.core

import sdl.Color

/**
 * Every colour, type size, and weight a figure draws with.
 *
 * A theme is deliberately a mutable class rather than an immutable value: it is configuration, and
 * the common gesture is to take a preset and adjust two fields (`palette`, `background`) rather
 * than restate thirty. Start from `light()` or `dark()` and override what you need.
 */
public class Theme {
    /** The figure-wide backdrop, behind titles and legends as well as the plot panel. */
    public var background: Color = Colors.hex("#FFFFFF")

    /** The plotting panel itself; slightly offset from `background` gives the panel definition. */
    public var panel: Color = Colors.hex("#FFFFFF")

    /** Primary text: titles and axis labels. */
    public var text: Color = Colors.hex("#111827")

    /** Secondary text: tick labels, captions, annotations. */
    public var mutedText: Color = Colors.hex("#6B7280")

    /** Major gridlines. Kept faint: the data should outweigh the scaffolding. */
    public var grid: Color = Colors.hex("#E5E7EB")

    /** Minor gridlines, fainter still. */
    public var gridMinor: Color = Colors.hex("#F3F4F6")

    /** Axis spines and tick marks. */
    public var axis: Color = Colors.hex("#D1D5DB")

    /** Panel border and separators. */
    public var border: Color = Colors.hex("#E5E7EB")

    /** Interactive accent: focus rings, selection, crosshair. */
    public var accent: Color = Colors.hex("#3B82F6")

    /** Surface for floating chrome — toolbars, tooltips, legend backdrops. */
    public var surface: Color = Colors.hex("#FFFFFF")

    /** Hover state for interactive chrome. */
    public var surfaceHover: Color = Colors.hex("#F3F4F6")

    /** Pressed/active state for interactive chrome. */
    public var surfaceActive: Color = Colors.hex("#E5E7EB")

    /** Categorical series colours. */
    public var palette: Palette = Palette.modern()

    /** Default continuous ramp for heatmaps and value-mapped colouring. */
    public var colormap: Colormap = Colormap.viridis()

    /** Figure title size. */
    public var titleSize: Float32 = 21.0

    /** Figure subtitle size. */
    public var subtitleSize: Float32 = 14.5

    /** Axis title size. */
    public var labelSize: Float32 = 14.5

    /** Tick label size. */
    public var tickSize: Float32 = 13.5

    /** Legend entry size. */
    public var legendSize: Float32 = 13.5

    /** Annotation and readout size. */
    public var annotationSize: Float32 = 13.0

    /** Default width of data lines, in logical pixels. */
    public var lineWidth: Float32 = 2.0

    /** Default marker radius, in logical pixels. */
    public var markerSize: Float32 = 3.5

    /** Corner radius for panels, tooltips, and toolbar buttons. */
    public var cornerRadius: Float32 = 8.0

    /** True when the theme is dark; lets components pick shadow/overlay strength sensibly. */
    public var isDark: Bool = false

    /** True when the plot panel draws a filled background distinct from the figure. */
    public var panelFilled: Bool = false

    /** True when the plot panel draws a border. */
    public var panelBordered: Bool = true

    public init() {}

    /** A clean light theme with restrained greys — the default. */
    public static func light(): Theme {
        Theme()
    }

    /** A light theme with a tinted panel, closer to the classic scientific look. */
    public static func lightPanel(): Theme {
        let theme = Theme()
        theme.background = Colors.hex("#FFFFFF")
        theme.panel = Colors.hex("#F9FAFB")
        theme.panelFilled = true
        theme
    }

    /** A dark theme tuned so the palette keeps its contrast against the panel. */
    public static func dark(): Theme {
        let theme = Theme()
        theme.background = Colors.hex("#0F1117")
        theme.panel = Colors.hex("#161922")
        theme.text = Colors.hex("#F3F4F6")
        theme.mutedText = Colors.hex("#9CA3AF")
        theme.grid = Colors.hex("#262B36")
        theme.gridMinor = Colors.hex("#1C202A")
        theme.axis = Colors.hex("#374151")
        theme.border = Colors.hex("#262B36")
        theme.accent = Colors.hex("#60A5FA")
        theme.surface = Colors.hex("#1B1F2A")
        theme.surfaceHover = Colors.hex("#262B36")
        theme.surfaceActive = Colors.hex("#323845")
        theme.palette = Palette.vivid()
        theme.isDark = true
        theme.panelFilled = true
        theme
    }

    /** A high-contrast, colour-vision-safe theme for publication figures. */
    public static func publication(): Theme {
        let theme = Theme()
        theme.text = Colors.hex("#000000")
        theme.mutedText = Colors.hex("#333333")
        theme.grid = Colors.hex("#DDDDDD")
        theme.gridMinor = Colors.hex("#EFEFEF")
        theme.axis = Colors.hex("#000000")
        theme.border = Colors.hex("#000000")
        theme.palette = Palette.colorblindSafe()
        theme.colormap = Colormap.cividis()
        theme.lineWidth = 1.6
        theme.cornerRadius = 0.0
        theme
    }

    /** An independent copy, so tweaking a derived theme never mutates the preset it came from. */
    public func copy(): Theme {
        let clone = Theme()
        clone.background = background
        clone.panel = panel
        clone.text = text
        clone.mutedText = mutedText
        clone.grid = grid
        clone.gridMinor = gridMinor
        clone.axis = axis
        clone.border = border
        clone.accent = accent
        clone.surface = surface
        clone.surfaceHover = surfaceHover
        clone.surfaceActive = surfaceActive
        clone.palette = palette
        clone.colormap = colormap
        clone.titleSize = titleSize
        clone.subtitleSize = subtitleSize
        clone.labelSize = labelSize
        clone.tickSize = tickSize
        clone.legendSize = legendSize
        clone.annotationSize = annotationSize
        clone.lineWidth = lineWidth
        clone.markerSize = markerSize
        clone.cornerRadius = cornerRadius
        clone.isDark = isDark
        clone.panelFilled = panelFilled
        clone.panelBordered = panelBordered
        clone
    }
}
