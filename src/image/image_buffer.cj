package plot.image

import plot.core.PlotException

/** Bytes per pixel throughout this package: 8-bit red, green, blue and alpha, in that order. */
const BYTES_PER_PIXEL: Int64 = 4

/**
 * Largest accepted side length, 2^24 px.
 *
 * Every decoder here multiplies out `width * height * 4`, and Cangjie traps on `Int64` overflow, so a
 * corrupt header claiming a two-billion-pixel side has to be rejected *before* the multiply or it
 * escapes as an arithmetic trap instead of the `PlotException` a caller can handle. This bound keeps
 * the product below 2^50 while sitting far above any plot anyone will render.
 */
const MAX_IMAGE_SIDE: Int64 = 16777216

/**
 * An 8-bit RGBA image in row-major order, 4 bytes per pixel.
 *
 * The pixel array is retained by reference rather than copied: a full-size plot is several megabytes,
 * and every producer in this package hands over an array it has just built and does not keep.
 */
public class ImageBuffer {
    private let imageWidth: Int64
    private let imageHeight: Int64
    private let data: Array<UInt8>

    /**
     * Throws `PlotException` unless `pixels` holds exactly `width * height * 4` bytes.
     *
     * A mismatch means the caller's stride arithmetic is wrong, and a buffer that is off by even one
     * byte would silently skew every row index downstream rather than fail anywhere near the cause.
     */
    public init(width: Int64, height: Int64, pixels: Array<UInt8>) {
        if (width <= 0 || height <= 0) {
            throw PlotException("Image dimensions must be positive, got ${width}x${height}.")
        }
        if (width > MAX_IMAGE_SIDE || height > MAX_IMAGE_SIDE) {
            throw PlotException("Image dimensions ${width}x${height} exceed the ${MAX_IMAGE_SIDE} px limit.")
        }
        let expected = width * height * BYTES_PER_PIXEL
        if (pixels.size != expected) {
            throw PlotException("A ${width}x${height} RGBA image needs ${expected} bytes, got ${pixels.size}.")
        }
        imageWidth = width
        imageHeight = height
        data = pixels
    }

    /** Width in pixels; always positive. */
    public func width(): Int64 {
        imageWidth
    }

    /** Height in pixels; always positive. */
    public func height(): Int64 {
        imageHeight
    }

    /** The backing RGBA bytes — not a copy, so callers must treat them as read-only. */
    public func pixels(): Array<UInt8> {
        data
    }
}
