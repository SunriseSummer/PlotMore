package plot.core

import sdl.{Point, Rect}

/**
 * The data-to-pixel transform for one plotting panel: a rectangle plus the two scales that fill it.
 *
 * The y axis is flipped here and nowhere else — data grows upward, screen pixels grow downward — so
 * no chart type has to remember to invert. Every series draws through this, which is also what makes
 * zoom and pan work uniformly: they only replace the scales' domains.
 */
public class Projection {
    /** The pixel rectangle the panel occupies. */
    public let area: Rect

    private let xScale: Scale
    private let yScale: Scale

    public init(area: Rect, xScale: Scale, yScale: Scale) {
        this.area = area
        this.xScale = xScale
        this.yScale = yScale
    }

    /** The horizontal scale. */
    public func x(): Scale {
        xScale
    }

    /** The vertical scale. */
    public func y(): Scale {
        yScale
    }

    /** The pixel column for a data x value. */
    public func pixelX(value: Float64): Float32 {
        area.x + Float32(xScale.normalize(value)) * area.w
    }

    /** The pixel row for a data y value; higher data sits higher on screen. */
    public func pixelY(value: Float64): Float32 {
        area.bottom() - Float32(yScale.normalize(value)) * area.h
    }

    /** The pixel position of a data point. */
    public func pixel(dataX: Float64, dataY: Float64): Point {
        Point(pixelX(dataX), pixelY(dataY))
    }

    /** The data x value under a pixel column — the inverse of `pixelX`, for hit tests and readouts. */
    public func dataX(px: Float32): Float64 {
        if (area.w <= 0.0) {
            return xScale.domain().center()
        }
        xScale.denormalize(Float64((px - area.x) / area.w))
    }

    /** The data y value under a pixel row. */
    public func dataY(py: Float32): Float64 {
        if (area.h <= 0.0) {
            return yScale.domain().center()
        }
        yScale.denormalize(Float64((area.bottom() - py) / area.h))
    }

    /** A pixel length along x for a data-space distance, e.g. sizing a bar to a category band. */
    public func pixelWidth(dataSpan: Float64): Float32 {
        let domain = xScale.domain()
        if (domain.span() <= 0.0) {
            return 0.0
        }
        Float32(dataSpan / domain.span()) * area.w
    }

    /** A pixel length along y for a data-space distance. */
    public func pixelHeight(dataSpan: Float64): Float32 {
        let domain = yScale.domain()
        if (domain.span() <= 0.0) {
            return 0.0
        }
        Float32(dataSpan / domain.span()) * area.h
    }

    /** True when both scales can express the point and both coordinates are finite. */
    public func accepts(dataX: Float64, dataY: Float64): Bool {
        xScale.accepts(dataX) && yScale.accepts(dataY)
    }

    /** True when the point falls inside the panel rectangle. */
    public func containsPixel(px: Float32, py: Float32): Bool {
        area.contains(px, py)
    }
}
