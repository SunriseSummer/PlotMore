package plot.image

import std.collection.ArrayList
import std.fs.File
import std.math.abs

/** The fixed 8-byte PNG signature (RFC 2083 §3.1). */
let PNG_SIGNATURE: Array<UInt8> = [137, 80, 78, 71, 13, 10, 26, 10]

/** Filter 0: the row is stored as-is. */
const FILTER_NONE: Int64 = 0

/** Filter 1: predict each byte from the same channel one pixel to the left. */
const FILTER_SUB: Int64 = 1

/** Filter 2: predict each byte from the byte directly above. */
const FILTER_UP: Int64 = 2

/** Filter 3: predict from the mean of left and above. */
const FILTER_AVERAGE: Int64 = 3

/** Filter 4: predict with the Paeth function of left, above and above-left. */
const FILTER_PAETH: Int64 = 4

/** How many filter types exist; the encoder tries every one on every row. */
const FILTER_COUNT: Int64 = 5

/** PNG colour type 6: truecolour with an alpha channel. */
const COLOUR_TYPE_RGBA: Int64 = 6

/** PNG bit depth 8: one byte per channel, the only depth this encoder emits. */
const BIT_DEPTH_EIGHT: Int64 = 8

/** IHDR is always these 13 bytes: width, height, depth, colour type, compression, filter, interlace. */
const IHDR_DATA_SIZE: Int64 = 13

/**
 * A minimal PNG encoder: 8-bit RGBA, no interlacing, one IDAT.
 *
 * It exists because the `sdl` renderer can only capture BMP and no zlib binding is available, so the
 * whole path from filtered scanlines down to DEFLATE is implemented in this package.
 */
public class Png {
    /**
     * Encodes to PNG bytes — colour type 6 (RGBA), 8-bit, a single IDAT holding the zlib stream of
     * the adaptively filtered scanlines.
     */
    public static func encode(image: ImageBuffer): Array<UInt8> {
        let compressed = compressToZlib(filterScanlines(image))
        let out = ArrayList<UInt8>()
        for (byte in PNG_SIGNATURE) {
            out.add(byte)
        }
        appendChunk(out, "IHDR", buildHeaderData(image))
        appendChunk(out, "IDAT", compressed)
        appendChunk(out, "IEND", Array<UInt8>())
        out.toArray()
    }

    /** Encodes and writes to `path`, truncating any file already there. */
    public static func write(image: ImageBuffer, path: String): Unit {
        File.writeTo(path, encode(image))
    }

    private static func buildHeaderData(image: ImageBuffer): Array<UInt8> {
        let data = Array<UInt8>(IHDR_DATA_SIZE, repeat: 0)
        writeUInt32Be(data, 0, UInt32(image.width()))
        writeUInt32Be(data, 4, UInt32(image.height()))
        data[8] = UInt8(BIT_DEPTH_EIGHT)
        data[9] = UInt8(COLOUR_TYPE_RGBA)
        data[10] = 0 // Compression method 0 (zlib/deflate) is the only one PNG defines.
        data[11] = 0 // Filter method 0 (per-scanline adaptive) is the only one PNG defines.
        data[12] = 0 // Interlace method 0: none.
        data
    }

    private static func appendChunk(out: ArrayList<UInt8>, chunkType: String, data: Array<UInt8>): Unit {
        let typeBytes = chunkType.toArray()
        appendUInt32Be(out, UInt32(data.size))
        for (byte in typeBytes) {
            out.add(byte)
        }
        for (byte in data) {
            out.add(byte)
        }
        // The CRC covers the type and the data but not the length field (RFC 2083 §3.2).
        appendUInt32Be(out, crc32(typeBytes, data))
    }
}

/**
 * Prefixes every scanline with the filter type that minimises the sum of absolute *signed* filtered
 * bytes — the heuristic the PNG spec recommends, and a good proxy for how much DEFLATE will then get
 * out of the row: it rewards rows that collapse toward zero, which is what LZ77 and the fixed Huffman
 * table both handle best. On a flat plot background every row filters to zeros; on a gradient the
 * left/above predictors turn a ramp into a constant.
 */
func filterScanlines(image: ImageBuffer): Array<UInt8> {
    let width = image.width()
    let height = image.height()
    let src = image.pixels()
    let stride = width * BYTES_PER_PIXEL
    let out = Array<UInt8>(height * (stride + 1), repeat: 0)
    for (y in 0..height) {
        let rowStart = y * stride
        let hasPrior = y > 0
        var bestKind = FILTER_NONE
        var bestCost = -1
        for (kind in 0..FILTER_COUNT) {
            let cost = filterRowCost(kind, src, rowStart, stride, hasPrior)
            if (bestCost < 0 || cost < bestCost) {
                bestCost = cost
                bestKind = kind
            }
        }
        let outStart = y * (stride + 1)
        out[outStart] = UInt8(bestKind)
        for (i in 0..stride) {
            out[outStart + 1 + i] = UInt8(filteredByte(bestKind, src, rowStart, i, stride, hasPrior))
        }
    }
    out
}

/** Cost of filtering a row with `kind` under the spec's minimum-sum-of-absolute-differences rule. */
func filterRowCost(kind: Int64, src: Array<UInt8>, rowStart: Int64, stride: Int64, hasPrior: Bool): Int64 {
    var sum = 0
    for (i in 0..stride) {
        let value = filteredByte(kind, src, rowStart, i, stride, hasPrior)
        // The heuristic reads each filtered byte as a signed char, so 0xC8 weighs 56 rather than 200.
        sum += if (value < 128) {
            value
        } else {
            256 - value
        }
    }
    sum
}

/** One filtered byte, reduced mod 256 as the PNG spec requires of every filter. */
func filteredByte(kind: Int64, src: Array<UInt8>, rowStart: Int64, i: Int64, stride: Int64, hasPrior: Bool): Int64 {
    (Int64(src[rowStart + i]) - filterPredictor(kind, src, rowStart, i, stride, hasPrior)) & 0xFF
}

/**
 * The predicted value filter `kind` subtracts at byte `i` of the row starting at `rowStart`.
 *
 * Predictors read the *original* bytes of the row above, not its filtered form, and bytes off the top
 * or left edge of the image are defined to be zero.
 */
func filterPredictor(kind: Int64, src: Array<UInt8>, rowStart: Int64, i: Int64, stride: Int64, hasPrior: Bool): Int64 {
    if (kind == FILTER_NONE) {
        return 0
    }
    // `a` is the byte one whole pixel back in this row, `b` the byte above, `c` the byte above-left.
    let a = if (i >= BYTES_PER_PIXEL) {
        Int64(src[rowStart + i - BYTES_PER_PIXEL])
    } else {
        0
    }
    let b = if (hasPrior) {
        Int64(src[rowStart - stride + i])
    } else {
        0
    }
    if (kind == FILTER_SUB) {
        return a
    }
    if (kind == FILTER_UP) {
        return b
    }
    if (kind == FILTER_AVERAGE) {
        return (a + b) / 2
    }
    let c = if (i >= BYTES_PER_PIXEL && hasPrior) {
        Int64(src[rowStart - stride + i - BYTES_PER_PIXEL])
    } else {
        0
    }
    paethPredictor(a, b, c)
}

/**
 * The PNG spec's Paeth predictor: of left, above and above-left, return whichever is nearest the
 * initial estimate `a + b - c`. That tracks a horizontal ramp, a vertical ramp or a flat region
 * without the encoder having to know which it is looking at.
 */
func paethPredictor(a: Int64, b: Int64, c: Int64): Int64 {
    let estimate = a + b - c
    let nearA = abs(estimate - a)
    let nearB = abs(estimate - b)
    let nearC = abs(estimate - c)
    if (nearA <= nearB && nearA <= nearC) {
        a
    } else if (nearB <= nearC) {
        b
    } else {
        c
    }
}

/** Stores `value` big-endian at `offset`; PNG is big-endian throughout, unlike BMP. */
func writeUInt32Be(dest: Array<UInt8>, offset: Int64, value: UInt32): Unit {
    dest[offset] = UInt8((value >> 24) & 0xFF)
    dest[offset + 1] = UInt8((value >> 16) & 0xFF)
    dest[offset + 2] = UInt8((value >> 8) & 0xFF)
    dest[offset + 3] = UInt8(value & 0xFF)
}

/** Appends `value` big-endian. */
func appendUInt32Be(out: ArrayList<UInt8>, value: UInt32): Unit {
    out.add(UInt8((value >> 24) & 0xFF))
    out.add(UInt8((value >> 16) & 0xFF))
    out.add(UInt8((value >> 8) & 0xFF))
    out.add(UInt8(value & 0xFF))
}
