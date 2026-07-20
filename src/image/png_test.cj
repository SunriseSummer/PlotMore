package plot.image

/** Reads back a big-endian u32, mirroring what the encoder writes, to keep structure checks legible. */
func beUInt32At(bytes: Array<UInt8>, offset: Int64): Int64 {
    (Int64(bytes[offset]) << 24) | (Int64(bytes[offset + 1]) << 16) | (Int64(bytes[offset + 2]) << 8) | Int64(bytes[offset +
            3])
}

func asciiAt(bytes: Array<UInt8>, offset: Int64, length: Int64): String {
    String.fromUtf8(bytes[offset..(offset + length)])
}

@Test
func pngEncodeEmitsSignatureIhdrIdatAndIend(): Unit {
    let png = Png.encode(ImageBuffer(3, 2, Array<UInt8>(24, repeat: 0)))

    for (i in 0..PNG_SIGNATURE.size) {
        @Expect(png[i], PNG_SIGNATURE[i])
    }

    // IHDR: a 4-byte length, the type, 13 bytes of data, then the CRC of type and data together.
    @Expect(beUInt32At(png, 8), 13)
    @Expect(asciiAt(png, 12, 4), "IHDR")
    @Expect(beUInt32At(png, 16), 3) // width
    @Expect(beUInt32At(png, 20), 2) // height
    @Expect(png[24], UInt8(8)) // bit depth
    @Expect(png[25], UInt8(6)) // colour type: truecolour with alpha
    @Expect(png[26], UInt8(0)) // compression method
    @Expect(png[27], UInt8(0)) // filter method
    @Expect(png[28], UInt8(0)) // interlace method
    @Expect(UInt32(beUInt32At(png, 29)), crc32(png[12..29], Array<UInt8>()))

    // IDAT follows immediately and opens with the zlib header.
    let idatLength = beUInt32At(png, 33)
    @Expect(asciiAt(png, 37, 4), "IDAT")
    @Expect(png[41], UInt8(0x78))
    @Expect(png[42], UInt8(0x01))
    @Expect(UInt32(beUInt32At(png, 41 + idatLength)), crc32(png[37..(41 + idatLength)], Array<UInt8>()))

    // IEND closes the file: empty, and therefore always carrying this same well-known CRC.
    let iend = png.size - 12
    @Expect(png.size, 45 + idatLength + 12)
    @Expect(beUInt32At(png, iend), 0)
    @Expect(asciiAt(png, iend + 4, 4), "IEND")
    @Expect(beUInt32At(png, iend + 8), 0xAE426082)
}

/**
 * Two identical pixels in a row: Sub drives the second to zero for a cost of 100 where None and Up
 * both cost 200, so Sub has to win and the row has to arrive prefixed with its filter-type byte.
 */
@Test
func filterSelectionPrefersSubOnAHorizontallyRepeatingRow(): Unit {
    let image = ImageBuffer(2, 1, [10, 20, 30, 40, 10, 20, 30, 40])
    let filtered = filterScanlines(image)

    @Expect(filtered.size, 9)
    @Expect(filtered[0], UInt8(FILTER_SUB))
    @Expect(filtered[1], UInt8(10))
    @Expect(filtered[2], UInt8(20))
    @Expect(filtered[3], UInt8(30))
    @Expect(filtered[4], UInt8(40))
    @Expect(filtered[5], UInt8(0))
    @Expect(filtered[6], UInt8(0))
    @Expect(filtered[7], UInt8(0))
    @Expect(filtered[8], UInt8(0))
}

/** The same pixel stacked on two rows: nothing beats None on row 0, and Up zeroes row 1 outright. */
@Test
func filterSelectionPrefersUpOnAVerticallyRepeatingColumn(): Unit {
    let image = ImageBuffer(1, 2, [10, 20, 30, 40, 10, 20, 30, 40])
    let filtered = filterScanlines(image)

    @Expect(filtered.size, 10)
    @Expect(filtered[0], UInt8(FILTER_NONE))
    @Expect(filtered[1], UInt8(10))
    @Expect(filtered[4], UInt8(40))
    @Expect(filtered[5], UInt8(FILTER_UP))
    @Expect(filtered[6], UInt8(0))
    @Expect(filtered[7], UInt8(0))
    @Expect(filtered[8], UInt8(0))
    @Expect(filtered[9], UInt8(0))
}

/** Filtered bytes are defined mod 256, so a predictor above the actual value wraps, never traps. */
@Test
func filteredBytesWrapInsteadOfGoingNegative(): Unit {
    let src: Array<UInt8> = [200, 0, 0, 0, 10, 0, 0, 0]

    // Sub at byte 4 computes 10 - 200 = -190, which has to land as 66.
    @Expect(filteredByte(FILTER_SUB, src, 0, 4, 8, false), 66)
}

@Test
func paethPredictorPicksTheNeighbourNearestTheEstimate(): Unit {
    @Expect(paethPredictor(0, 0, 0), 0)
    // Estimate 7 sits nearest the left neighbour.
    @Expect(paethPredictor(5, 3, 1), 5)
    // Estimate 15 hits above-left exactly, and only it is at zero distance.
    @Expect(paethPredictor(10, 20, 15), 15)
    // A pure vertical gradient: the byte above predicts it exactly.
    @Expect(paethPredictor(0, 10, 0), 10)
}

/** The point of the whole path: a flat image must not land anywhere near its raw byte count. */
@Test
func encodingAFlatImageCompressesHeavily(): Unit {
    let png = Png.encode(ImageBuffer(200, 200, Array<UInt8>(200 * 200 * BYTES_PER_PIXEL, repeat: 0x20)))

    @Expect(png.size < 2000)
}
