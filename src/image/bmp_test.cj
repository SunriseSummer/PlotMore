package plot.image

import std.fs.{File, removeIfExists}

/** Assembles a BITMAPINFOHEADER BMP around `pixelData`, which must already carry its row padding. */
func buildTestBmp(width: Int64, height: Int64, bitCount: Int64, compression: Int64, pixelData: Array<UInt8>): Array<UInt8> {
    let dataOffset = 54
    let bytes = Array<UInt8>(dataOffset + pixelData.size, repeat: 0)
    bytes[0] = b'B'
    bytes[1] = b'M'
    putUInt32Le(bytes, 2, bytes.size)
    putUInt32Le(bytes, 10, dataOffset)
    putUInt32Le(bytes, 14, 40)
    putUInt32Le(bytes, 18, toUnsigned32(width))
    putUInt32Le(bytes, 22, toUnsigned32(height))
    putUInt16Le(bytes, 26, 1)
    putUInt16Le(bytes, 28, bitCount)
    putUInt32Le(bytes, 30, compression)
    for (i in 0..pixelData.size) {
        bytes[dataOffset + i] = pixelData[i]
    }
    bytes
}

func toUnsigned32(value: Int64): Int64 {
    if (value < 0) {
        value + 4294967296
    } else {
        value
    }
}

func putUInt16Le(bytes: Array<UInt8>, offset: Int64, value: Int64): Unit {
    bytes[offset] = UInt8(value & 0xFF)
    bytes[offset + 1] = UInt8((value >> 8) & 0xFF)
}

func putUInt32Le(bytes: Array<UInt8>, offset: Int64, value: Int64): Unit {
    bytes[offset] = UInt8(value & 0xFF)
    bytes[offset + 1] = UInt8((value >> 8) & 0xFF)
    bytes[offset + 2] = UInt8((value >> 16) & 0xFF)
    bytes[offset + 3] = UInt8((value >> 24) & 0xFF)
}

/** The pixel at (x, y) as "r,g,b,a", so a failure prints both whole pixels rather than one channel. */
func pixelAt(image: ImageBuffer, x: Int64, y: Int64): String {
    let at = (y * image.width() + x) * BYTES_PER_PIXEL
    let pixels = image.pixels()
    "${pixels[at]},${pixels[at + 1]},${pixels[at + 2]},${pixels[at + 3]}"
}

/** 24bpp bottom-up: rows arrive last-first, and each 6-byte row is padded out to 8. */
@Test
func decodes24BitBottomUpBmp(): Unit {
    let pixels: Array<UInt8> = [
        255,
        0,
        0,
        255,
        255,
        255,
        0,
        0, // stored first, so the BOTTOM row: blue, white, 2 pad bytes
        0,
        0,
        255,
        0,
        255,
        0,
        0,
        0 // the top row: red, green, 2 pad bytes
    ]
    let image = Bmp.decode(buildTestBmp(2, 2, 24, BMP_COMPRESSION_RGB, pixels))

    @Expect(image.width(), 2)
    @Expect(image.height(), 2)
    @Expect(pixelAt(image, 0, 0), "255,0,0,255")
    @Expect(pixelAt(image, 1, 0), "0,255,0,255")
    @Expect(pixelAt(image, 0, 1), "0,0,255,255")
    @Expect(pixelAt(image, 1, 1), "255,255,255,255")
}

/** 32bpp under BI_BITFIELDS carrying a real alpha channel, which must survive untouched. */
@Test
func decodes32BitBitfieldsBmpPreservingAlpha(): Unit {
    let pixels: Array<UInt8> = [
        255,
        0,
        0,
        64,
        255,
        255,
        255,
        128, // bottom row: blue at alpha 64, white at alpha 128
        0,
        0,
        255,
        255,
        0,
        255,
        0,
        32 // top row: red at alpha 255, green at alpha 32
    ]
    let image = Bmp.decode(buildTestBmp(2, 2, 32, BMP_COMPRESSION_BITFIELDS, pixels))

    @Expect(pixelAt(image, 0, 0), "255,0,0,255")
    @Expect(pixelAt(image, 1, 0), "0,255,0,32")
    @Expect(pixelAt(image, 0, 1), "0,0,255,64")
    @Expect(pixelAt(image, 1, 1), "255,255,255,128")
}

/**
 * SDL captures 32bpp as BI_BITFIELDS and leaves every alpha byte at zero. Read literally that is a
 * fully transparent image and the export would be a blank PNG, so an all-zero alpha channel has to
 * be understood as "this file carries no alpha" instead.
 */
@Test
func decodes32BitBmpWithAllZeroAlphaAsOpaque(): Unit {
    let pixels: Array<UInt8> = [
        255,
        0,
        0,
        0,
        255,
        255,
        255,
        0,
        0,
        0,
        255,
        0,
        0,
        255,
        0,
        0
    ]
    let image = Bmp.decode(buildTestBmp(2, 2, 32, BMP_COMPRESSION_BITFIELDS, pixels))

    @Expect(pixelAt(image, 0, 0), "255,0,0,255")
    @Expect(pixelAt(image, 1, 0), "0,255,0,255")
    @Expect(pixelAt(image, 0, 1), "0,0,255,255")
    @Expect(pixelAt(image, 1, 1), "255,255,255,255")
}

/** One non-zero alpha byte anywhere is enough to mean the file really does carry alpha. */
@Test
func decodes32BitBmpWithOneOpaqueByteWithoutForcingTheRestOpaque(): Unit {
    let pixels: Array<UInt8> = [
        255,
        0,
        0,
        0,
        255,
        255,
        255,
        0,
        0,
        0,
        255,
        0,
        0,
        255,
        0,
        7
    ]
    let image = Bmp.decode(buildTestBmp(2, 2, 32, BMP_COMPRESSION_BITFIELDS, pixels))

    @Expect(pixelAt(image, 0, 0), "255,0,0,0")
    @Expect(pixelAt(image, 1, 0), "0,255,0,7")
    @Expect(pixelAt(image, 0, 1), "0,0,255,0")
    @Expect(pixelAt(image, 1, 1), "255,255,255,0")
}

/** A negative height means the rows are stored top-down; the same image, rows the other way up. */
@Test
func decodesNegativeHeightBmpAsTopDown(): Unit {
    let pixels: Array<UInt8> = [
        0,
        0,
        255,
        0,
        255,
        0,
        0,
        0, // stored first, and top-down, so the TOP row: red, green
        255,
        0,
        0,
        255,
        255,
        255,
        0,
        0 // the bottom row: blue, white
    ]
    let image = Bmp.decode(buildTestBmp(2, -2, 24, BMP_COMPRESSION_RGB, pixels))

    @Expect(image.width(), 2)
    @Expect(image.height(), 2)
    @Expect(pixelAt(image, 0, 0), "255,0,0,255")
    @Expect(pixelAt(image, 1, 0), "0,255,0,255")
    @Expect(pixelAt(image, 0, 1), "0,0,255,255")
    @Expect(pixelAt(image, 1, 1), "255,255,255,255")
}

/** BITMAPV4/V5 only append fields, so a larger declared header leaves every field read here in place. */
@Test
func decodesBmpWithALargerV5Header(): Unit {
    let bytes = buildTestBmp(1, 1, 24, BMP_COMPRESSION_RGB, [0, 0, 255, 0])
    putUInt32Le(bytes, 14, 124)

    @Expect(pixelAt(Bmp.decode(bytes), 0, 0), "255,0,0,255")
}

@Test
func rejectsNonBmpAndUnsupportedBmpVariants(): Unit {
    @Expect(throwsPlotException({=> Bmp.decode(Array<UInt8>(8, repeat: 0))})) // shorter than the headers
    @Expect(throwsPlotException({=> Bmp.decode(Array<UInt8>(60, repeat: 0))})) // no 'BM' signature

    @Expect(throwsPlotException({=> Bmp.decode(buildTestBmp(1, 1, 24, 1, [0, 0, 255, 0]))})) // BI_RLE8
    @Expect(throwsPlotException({=> Bmp.decode(buildTestBmp(1, 1, 16, BMP_COMPRESSION_RGB, [0, 0, 255, 0]))}))

    let coreHeader = buildTestBmp(1, 1, 24, BMP_COMPRESSION_RGB, [0, 0, 255, 0])
    putUInt32Le(coreHeader, 14, 12) // BITMAPCOREHEADER, which lays its fields out differently
    @Expect(throwsPlotException({=> Bmp.decode(coreHeader)}))

    let valid = buildTestBmp(1, 1, 24, BMP_COMPRESSION_RGB, [0, 0, 255, 0])
    @Expect(throwsPlotException({=> Bmp.decode(valid[0..(valid.size - 2)])}))
}

/**
 * The only check on the shape of `std.fs`'s one-shot read and write, and on the two file-level entry
 * points the exporter actually calls.
 */
@Test
func fileEntryPointsRoundTripThroughTheFilesystem(): Unit {
    let bmpPath = "plot_image_roundtrip_test.bmp"
    let pngPath = "plot_image_roundtrip_test.png"
    let pixels: Array<UInt8> = [
        255,
        0,
        0,
        255,
        255,
        255,
        0,
        0,
        0,
        0,
        255,
        0,
        255,
        0,
        0,
        0
    ]
    try {
        File.writeTo(bmpPath, buildTestBmp(2, 2, 24, BMP_COMPRESSION_RGB, pixels))
        let image = Bmp.read(bmpPath)

        @Expect(image.width(), 2)
        @Expect(pixelAt(image, 0, 0), "255,0,0,255")
        @Expect(pixelAt(image, 1, 1), "255,255,255,255")

        Png.write(image, pngPath)
        let png = File.readFrom(pngPath)

        @Expect(png[0], UInt8(137))
        @Expect(String.fromUtf8(png[12..16]), "IHDR")
    } finally {
        removeIfExists(bmpPath)
        removeIfExists(pngPath)
    }
}
