package plot.image

import plot.core.PlotException
import std.fs.File

/** BITMAPFILEHEADER is a fixed 14 bytes; the DIB header starts immediately after it. */
const BMP_FILE_HEADER_SIZE: Int64 = 14

/** Offset of the pixel-data pointer within BITMAPFILEHEADER. */
const BMP_DATA_OFFSET_FIELD: Int64 = 10

/** Size of BITMAPINFOHEADER, the smallest DIB header this decoder accepts. */
const BMP_INFO_HEADER_SIZE: Int64 = 40

/** BI_RGB: uncompressed, channel layout implied by the bit count. */
const BMP_COMPRESSION_RGB: Int64 = 0

/** BI_BITFIELDS: uncompressed, channel layout declared by explicit masks. */
const BMP_COMPRESSION_BITFIELDS: Int64 = 3

/**
 * A decoder for the BMP files the `sdl` renderer captures.
 *
 * Only the uncompressed 24bpp and 32bpp shapes are handled — that is what `renderer.captureBmp` ever
 * produces, and it is the whole of what the PNG export path needs to read back.
 */
public class Bmp {
    /**
     * Decodes a BMP file's bytes into RGBA.
     *
     * Handles 24bpp and 32bpp under BI_RGB and BI_BITFIELDS, bottom-up and top-down row order, and
     * DIB headers at least as large as BITMAPINFOHEADER. Throws `PlotException` on anything else.
     */
    public static func decode(bytes: Array<UInt8>): ImageBuffer {
        if (bytes.size < BMP_FILE_HEADER_SIZE + BMP_INFO_HEADER_SIZE) {
            throw PlotException("Not a BMP: ${bytes.size} bytes is too short to hold the headers.")
        }
        if (bytes[0] != b'B' || bytes[1] != b'M') {
            throw PlotException("Not a BMP: the 'BM' signature is missing.")
        }
        let dataOffset = readUInt32Le(bytes, BMP_DATA_OFFSET_FIELD)
        let headerSize = readUInt32Le(bytes, BMP_FILE_HEADER_SIZE)
        // BITMAPV4/V5 only append fields to BITMAPINFOHEADER, so every field read below sits at the
        // same offset whatever the declared size; the size itself is only a floor to validate here,
        // since it is the file header's own data offset that locates the pixels.
        if (headerSize < BMP_INFO_HEADER_SIZE) {
            throw PlotException("Unsupported BMP DIB header of ${headerSize} bytes; need at least 40.")
        }
        let width = readInt32Le(bytes, 18)
        let rawHeight = readInt32Le(bytes, 22)
        let bitCount = readUInt16Le(bytes, 28)
        let compression = readUInt32Le(bytes, 30)
        if (compression != BMP_COMPRESSION_RGB && compression != BMP_COMPRESSION_BITFIELDS) {
            throw PlotException("Unsupported BMP compression ${compression}; only BI_RGB and BI_BITFIELDS are read.")
        }
        if (bitCount != 24 && bitCount != 32) {
            throw PlotException("Unsupported BMP depth of ${bitCount} bits; only 24 and 32 are read.")
        }
        // A negative height is BMP's flag for top-down row order instead of its usual bottom-up.
        let topDown = rawHeight < 0
        let height = if (topDown) {
            -rawHeight
        } else {
            rawHeight
        }
        // Bound the sides before any area arithmetic: `rowSize * height` on a corrupt header would
        // otherwise overflow Int64 and trap rather than surface as a PlotException.
        if (width <= 0 || height <= 0 || width > MAX_IMAGE_SIDE || height > MAX_IMAGE_SIDE) {
            throw PlotException("Invalid BMP dimensions ${width}x${rawHeight}.")
        }
        let sourceBytesPerPixel = bitCount / 8
        // Every BMP row is padded out to the next 4-byte boundary.
        let rowSize = ((bitCount * width + 31) / 32) * 4
        if (dataOffset < BMP_FILE_HEADER_SIZE || dataOffset + rowSize * height > bytes.size) {
            throw PlotException(
                "Truncated BMP: ${rowSize * height} pixel bytes claimed from offset ${dataOffset}, " +
                    "but the file is only ${bytes.size} bytes.")
        }
        return buildImage(bytes, width, height, topDown, rowSize, sourceBytesPerPixel, dataOffset)
    }

    /** Reads and decodes a BMP file. */
    public static func read(path: String): ImageBuffer {
        decode(File.readFrom(path))
    }

    private static func buildImage(bytes: Array<UInt8>, width: Int64, height: Int64, topDown: Bool, rowSize: Int64,
        sourceBytesPerPixel: Int64, dataOffset: Int64): ImageBuffer {
        let pixels = Array<UInt8>(width * height * BYTES_PER_PIXEL, repeat: 0)
        var sawOpaqueByte = false
        for (y in 0..height) {
            // Bottom-up files store the last image row first.
            let sourceRow = if (topDown) {
                y
            } else {
                height - 1 - y
            }
            var source = dataOffset + sourceRow * rowSize
            var dest = y * width * BYTES_PER_PIXEL
            for (_ in 0..width) {
                // BMP channel order is B, G, R and then A, the reverse of the RGBA we hand back. Under
                // BI_BITFIELDS the masks could in principle say otherwise, but every 24/32bpp producer
                // in practice — the `sdl` capture included — writes the canonical BGR(A) layout.
                pixels[dest] = bytes[source + 2]
                pixels[dest + 1] = bytes[source + 1]
                pixels[dest + 2] = bytes[source]
                let alpha = if (sourceBytesPerPixel == 4) {
                    bytes[source + 3]
                } else {
                    UInt8(255) // 24bpp carries no alpha channel at all.
                }
                if (alpha != 0) {
                    sawOpaqueByte = true
                }
                pixels[dest + 3] = alpha
                source += sourceBytesPerPixel
                dest += BYTES_PER_PIXEL
            }
        }
        // SDL writes 32bpp BMPs with an alpha channel it never fills in, so a captured plot arrives
        // with every alpha byte zero. Read literally that is a fully transparent image, and exporting
        // it would produce a PNG showing nothing at all. An entirely zero alpha channel is far more
        // plausibly "this file carries no alpha" than "this image is invisible", so force it opaque.
        if (!sawOpaqueByte) {
            for (pixel in 0..(width * height)) {
                pixels[pixel * BYTES_PER_PIXEL + 3] = 255
            }
        }
        return ImageBuffer(width, height, pixels)
    }
}

/** Little-endian u16 at `offset`, widened to Int64. BMP is little-endian throughout, unlike PNG. */
func readUInt16Le(bytes: Array<UInt8>, offset: Int64): Int64 {
    Int64(bytes[offset]) | (Int64(bytes[offset + 1]) << 8)
}

/** Little-endian u32 at `offset`, widened to Int64 so the full unsigned range stays positive. */
func readUInt32Le(bytes: Array<UInt8>, offset: Int64): Int64 {
    Int64(bytes[offset]) | (Int64(bytes[offset + 1]) << 8) | (Int64(bytes[offset + 2]) << 16) | (Int64(bytes[offset + 3]) <<
        24)
}

/** Little-endian i32 at `offset`; BMP encodes a top-down image by making its height negative. */
func readInt32Le(bytes: Array<UInt8>, offset: Int64): Int64 {
    let value = readUInt32Le(bytes, offset)
    if (value >= 2147483648) {
        value - 4294967296
    } else {
        value
    }
}
