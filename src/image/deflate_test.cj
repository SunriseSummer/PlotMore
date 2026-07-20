package plot.image

@Test
func reverseBitsFlipsOnlyTheRequestedWidth(): Unit {
    @Expect(reverseBits(0b001, 3), UInt32(0b100))
    @Expect(reverseBits(0b110, 3), UInt32(0b011))
    // 0x30 is the fixed-Huffman code for literal 0; 0x0C is the order it has to reach the stream in.
    @Expect(reverseBits(0x30, 8), UInt32(0x0C))
}

/** DEFLATE packs plain fields least-significant bit first, so BFINAL=1 then BTYPE=01 gives 0b011. */
@Test
func bitWriterPacksPlainFieldsLeastSignificantBitFirst(): Unit {
    let writer = BitWriter()
    writer.writeBits(1, 1)
    writer.writeBits(1, 2)
    let bytes = writer.finish()

    @Expect(bytes.size, 1)
    @Expect(bytes[0], UInt8(0b011))
}

/** Huffman codes are the one field DEFLATE stores most-significant bit first. */
@Test
func bitWriterEmitsHuffmanCodesMostSignificantBitFirst(): Unit {
    let writer = BitWriter()
    writer.writeCode(0b1011, 4)
    writer.writeCode(0b0001, 4)
    let bytes = writer.finish()

    @Expect(bytes.size, 1)
    // 1011 reversed fills the low nibble as 1101; 0001 reversed fills the high nibble as 1000.
    @Expect(bytes[0], UInt8(0b10001101))
}

@Test
func lengthAndDistanceCodesLandOnTheRfc1951Boundaries(): Unit {
    // Code 257 (index 0) starts at length 3, 264 (index 7) is the last with no extra bits, and
    // 265 (index 8) opens the two-length runs.
    @Expect(largestIndexNotAbove(LENGTH_BASE, 3), 0)
    @Expect(largestIndexNotAbove(LENGTH_BASE, 10), 7)
    @Expect(largestIndexNotAbove(LENGTH_BASE, 11), 8)
    @Expect(largestIndexNotAbove(LENGTH_BASE, 12), 8)
    @Expect(largestIndexNotAbove(LENGTH_BASE, 13), 9)
    // 258 owns code 285 outright, while 257 is code 284 with its five extra bits maxed out.
    @Expect(largestIndexNotAbove(LENGTH_BASE, 257), 27)
    @Expect(largestIndexNotAbove(LENGTH_BASE, 258), 28)

    @Expect(largestIndexNotAbove(DISTANCE_BASE, 1), 0)
    @Expect(largestIndexNotAbove(DISTANCE_BASE, 4), 3)
    @Expect(largestIndexNotAbove(DISTANCE_BASE, 5), 4)
    @Expect(largestIndexNotAbove(DISTANCE_BASE, 6), 4)
    @Expect(largestIndexNotAbove(DISTANCE_BASE, 32768), 29)
}

@Test
func zlibStreamCarriesItsHeaderAndAdlerTail(): Unit {
    let data = "the quick brown fox jumps over the lazy dog".toArray()
    let stream = compressToZlib(data)

    @Expect(stream[0], UInt8(0x78))
    @Expect(stream[1], UInt8(0x01))
    // RFC 1950 §2.2: a decoder rejects the stream outright unless the header pair divides by 31.
    @Expect((Int64(stream[0]) * 256 + Int64(stream[1])) % 31, 0)

    // The tail checksums the uncompressed data, big-endian.
    let expected = adler32(data)
    let tail = stream.size - 4
    @Expect(stream[tail], UInt8((expected >> 24) & 0xFF))
    @Expect(stream[tail + 1], UInt8((expected >> 16) & 0xFF))
    @Expect(stream[tail + 2], UInt8((expected >> 8) & 0xFF))
    @Expect(stream[tail + 3], UInt8(expected & 0xFF))
}

/** Empty input still owes the decoder a complete block and a checksum. */
@Test
func zlibStreamOfEmptyInputIsStillWellFormed(): Unit {
    let stream = compressToZlib(Array<UInt8>())

    // Two header bytes, then three block-header bits plus a seven-bit end-of-block padded into two
    // bytes, then the four-byte Adler tail.
    @Expect(stream.size, 8)
    @Expect(stream[0], UInt8(0x78))
    @Expect(stream[stream.size - 1], UInt8(1)) // Adler-32 of nothing is 1.
}

/**
 * A long run of one byte is the case LZ77 has to nail: ~390 maximum-length matches at 12 bits each.
 * If the match finder or the code tables were wrong this would land near the 100000-byte input.
 */
@Test
func compressionCollapsesALongRunOfIdenticalBytes(): Unit {
    let stream = compressToZlib(Array<UInt8>(100000, repeat: 0))

    @Expect(stream.size < 1000)
}

/** Incompressible input must not blow up: fixed Huffman caps the damage at roughly 12.5% growth. */
@Test
func compressionOfNoisyInputStaysCloseToTheInputSize(): Unit {
    let data = Array<UInt8>(4096, repeat: 0)
    var state: Int64 = 12345
    for (i in 0..data.size) {
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF
        data[i] = UInt8((state >> 16) & 0xFF)
    }

    let stream = compressToZlib(data)

    @Expect(stream.size < 4096 + 600)
}
