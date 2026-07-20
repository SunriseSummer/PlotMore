package plot.image

/** The check value every CRC-32/ISO-HDLC implementation is expected to reproduce. */
@Test
func crc32ReproducesTheStandardCheckValue(): Unit {
    @Expect(crc32("123456789".toArray(), Array<UInt8>()), UInt32(0xCBF43926))
}

/** PNG hands the chunk type and the chunk data in separately, so the split must not be observable. */
@Test
func crc32IsIndifferentToWhereItsInputIsSplit(): Unit {
    @Expect(crc32("1234".toArray(), "56789".toArray()), UInt32(0xCBF43926))
    @Expect(crc32(Array<UInt8>(), "123456789".toArray()), UInt32(0xCBF43926))
}

@Test
func crc32OfNothingIsZero(): Unit {
    @Expect(crc32(Array<UInt8>(), Array<UInt8>()), UInt32(0))
}

/** The check value from RFC 1950 §9. */
@Test
func adler32ReproducesTheStandardCheckValue(): Unit {
    @Expect(adler32("123456789".toArray()), UInt32(0x091E01DE))
}

@Test
func adler32OfNothingIsOne(): Unit {
    @Expect(adler32(Array<UInt8>()), UInt32(1))
}

/**
 * A megabyte of 0xFF is where checksum arithmetic that ignores Cangjie's overflow trapping falls
 * over: both Adler sums climb as fast as they can and the CRC register stays saturated. A wrong
 * answer here would be a bug, but a *trap* here would be the failure this guards against.
 */
@Test
func checksumsDoNotTrapOnALongAllOnesBuffer(): Unit {
    let bytes = Array<UInt8>(1048576, repeat: 0xFF)

    @Expect(adler32(bytes) != UInt32(0))
    @Expect(crc32(bytes, Array<UInt8>()) != UInt32(0))
}
