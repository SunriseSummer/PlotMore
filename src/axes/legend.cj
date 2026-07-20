package plot.axes

import std.collection.ArrayList
import sdl.{Pen, Rect}
import plot.canvas.{Canvas, VAlign}
import plot.core.{Colors, Theme}
import plot.series.LegendEntry

/** Where a legend sits relative to the plotting area. */
public enum LegendPosition {
    /** Floating inside the plot area, in the named corner. */
    | TopLeft
    | TopRight
    | BottomLeft
    | BottomRight

    /** In its own column to the right of the plot area, which is narrowed to make room. */
    | OutsideRight

    /** In its own row below the plot area. */
    | OutsideBottom

    /** Not drawn. */
    | Hidden
}

/** Swatch geometry, shared by layout and drawing so the two cannot drift apart. */
const SWATCH_WIDTH: Float32 = 22.0
const SWATCH_HEIGHT: Float32 = 11.0
const SWATCH_GAP: Float32 = 7.0
const ENTRY_GAP: Float32 = 5.0
const LEGEND_PADDING: Float32 = 9.0

/**
 * The key mapping swatches to series labels.
 *
 * Each entry draws its own swatch through the callback the series supplied, so a dashed line with
 * circular markers appears in the legend as a dashed line with a circular marker rather than as a
 * generic colour chip.
 *
 * A floating legend draws on a translucent backdrop of the panel colour: inside placement is what
 * keeps the plot area wide, and the backdrop is what keeps the labels readable when data passes
 * underneath.
 */
public class Legend {
    /** Where the legend sits; `Hidden` skips it entirely. */
    public var position: LegendPosition = LegendPosition.TopRight

    /** Lays entries in a row rather than a column. Forced on for `OutsideBottom`. */
    public var horizontal: Bool = false

    /** Draws the rounded backdrop behind a floating legend. */
    public var showBackground: Bool = true

    /** Draws a hairline border around the backdrop. */
    public var showBorder: Bool = true

    public init() {}

    /** The space this legend needs for `entries`, or a zero size when it draws nothing. */
    public func measure(canvas: Canvas, entries: Array<LegendEntry>, theme: Theme): (Float32, Float32) {
        if (isHidden() || entries.size == 0) {
            return (0.0, 0.0)
        }
        let lineHeight = maxOf(canvas.textHeight(size: theme.legendSize), SWATCH_HEIGHT)
        if (isHorizontal()) {
            var width: Float32 = 0.0
            for (entry in entries) {
                width += entryWidth(canvas, entry, theme) + ENTRY_GAP * 2.0
            }
            (width + LEGEND_PADDING * 2.0 - ENTRY_GAP * 2.0, lineHeight + LEGEND_PADDING * 2.0)
        } else {
            var width: Float32 = 0.0
            for (entry in entries) {
                width = maxOf(width, entryWidth(canvas, entry, theme))
            }
            let height = lineHeight * Float32(entries.size) + ENTRY_GAP * Float32(entries.size - 1)
            (width + LEGEND_PADDING * 2.0, height + LEGEND_PADDING * 2.0)
        }
    }

    /**
     * Draws the legend into `rect`, which must be at least the size `measure` reported. Records the
     * hit rectangle of each entry so `entryAt` can answer clicks.
     */
    public func draw(canvas: Canvas, rect: Rect, entries: Array<LegendEntry>, theme: Theme, hidden: Array<Bool>): Unit {
        hitRects.clear()
        if (isHidden() || entries.size == 0) {
            return
        }
        if (showBackground) {
            canvas.fillRoundedRect(rect, theme.cornerRadius, Colors.fade(theme.surface, 0.88))
        }
        if (showBorder) {
            canvas.strokeRoundedRect(rect, theme.cornerRadius, Pen(width: 1.0, color: theme.border))
        }
        let lineHeight = maxOf(canvas.textHeight(size: theme.legendSize), SWATCH_HEIGHT)
        var cursorX = rect.x + LEGEND_PADDING
        var cursorY = rect.y + LEGEND_PADDING
        for (i in 0..entries.size) {
            let entry = entries[i]
            let width = entryWidth(canvas, entry, theme)
            let row = Rect(cursorX, cursorY, width, lineHeight)
            hitRects.add(row)
            // A toggled-off series keeps its slot and label but drops to a ghost, so the legend
            // does not reflow and the click target stays where the user last clicked.
            let dimmed = i < hidden.size && hidden[i]
            let swatch = Rect(cursorX, cursorY + (lineHeight - SWATCH_HEIGHT) / 2.0, SWATCH_WIDTH, SWATCH_HEIGHT)
            if (dimmed) {
                canvas.fillRoundedRect(swatch, 2.0, Colors.fade(theme.mutedText, 0.3))
            } else {
                (entry.draw)(canvas, swatch, theme)
            }
            let textColor = if (dimmed) {
                Colors.fade(theme.mutedText, 0.55)
            } else {
                theme.text
            }
            canvas.textAnchored(entry.label, cursorX + SWATCH_WIDTH + SWATCH_GAP, cursorY + lineHeight / 2.0, textColor,
                size: theme.legendSize, vAlign: VAlign.Middle)
            if (isHorizontal()) {
                cursorX += width + ENTRY_GAP * 2.0
            } else {
                cursorY += lineHeight + ENTRY_GAP
            }
        }
    }

    /** The index of the entry whose row contains the pixel, for click-to-toggle. */
    public func entryAt(px: Float32, py: Float32): ?Int64 {
        for (i in 0..hitRects.size) {
            if (hitRects[i].contains(px, py)) {
                return Some(i)
            }
        }
        None
    }

    /** True when the legend is configured not to draw. */
    public func isHidden(): Bool {
        match (position) {
            case Hidden => true
            case _ => false
        }
    }

    /** True when the legend needs its own band outside the plot area. */
    public func isOutside(): Bool {
        match (position) {
            case OutsideRight => true
            case OutsideBottom => true
            case _ => false
        }
    }

    private func isHorizontal(): Bool {
        match (position) {
            case OutsideBottom => true
            case _ => horizontal
        }
    }

    private func entryWidth(canvas: Canvas, entry: LegendEntry, theme: Theme): Float32 {
        SWATCH_WIDTH + SWATCH_GAP + canvas.textWidth(entry.label, size: theme.legendSize)
    }

    // Per-entry hit rectangles from the last draw; rebuilt every frame because layout can move.
    private let hitRects = ArrayList<Rect>()
}

func maxOf(a: Float32, b: Float32): Float32 {
    if (a > b) {
        a
    } else {
        b
    }
}
