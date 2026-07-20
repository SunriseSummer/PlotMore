package plot.image

import std.collection.ArrayList

/*
 * A fixed-Huffman DEFLATE decoder, written for these tests alone.
 *
 * The encoder's own tests measure the *size* of what it emits, which says nothing about whether a
 * decoder can read it back: a match at a wrong distance still compresses, and still lands in the
 * size band those tests accept. Only an independent decode proves the stream means what the input
 * said. This one handles exactly what `Deflater` emits — a single BFINAL block, BTYPE=01 — so it
 * stays short enough to be obviously right, and it shares no code with the encoder, which is the
 * whole point of it.
 */
class Inflater {
    private let data: Array<UInt8>
    private var pos: Int64 = 0
    private var bit: Int64 = 0
    private let out = ArrayList<UInt8>()

    init(source: Array<UInt8>) {
        data = source
    }

    /** Inflates a raw DEFLATE stream (no zlib wrapper). */
    func run(): Array<UInt8> {
        let final = readBits(1)
        let kind = readBits(2)
        if (final != 1) {
            throw InflateCheckException("expected a single BFINAL block, got BFINAL=${final}")
        }
        if (kind != 1) {
            throw InflateCheckException("expected BTYPE=01 (fixed Huffman), got ${kind}")
        }
        while (true) {
            let symbol = readLiteralOrLength()
            if (symbol == END_OF_BLOCK) {
                break
            }
            if (symbol < END_OF_BLOCK) {
                out.add(UInt8(symbol))
                continue
            }
            let lengthCode = symbol - 257
            if (lengthCode >= LENGTH_BASE.size) {
                throw InflateCheckException("length code ${symbol} is outside 257..285")
            }
            let length = LENGTH_BASE[lengthCode] + readBits(LENGTH_EXTRA[lengthCode])
            let distanceCode = readReversed(5)
            if (distanceCode >= DISTANCE_BASE.size) {
                throw InflateCheckException("distance code ${distanceCode} is outside 0..29")
            }
            let distance = DISTANCE_BASE[distanceCode] + readBits(DISTANCE_EXTRA[distanceCode])
            if (distance > out.size) {
                throw InflateCheckException("distance ${distance} reaches back past the ${out.size} bytes decoded so far")
            }
            // Byte at a time, deliberately: an overlapping copy is legal and has to repeat.
            let from = out.size - distance
            for (i in 0..length) {
                out.add(out[from + i])
            }
        }
        out.toArray()
    }

    // Plain fields arrive least-significant bit first.
    private func readBits(count: Int64): Int64 {
        var value = 0
        for (i in 0..count) {
            value |= readBit() << i
        }
        value
    }

    // Huffman codes arrive most-significant bit first.
    private func readReversed(count: Int64): Int64 {
        var value = 0
        for (_ in 0..count) {
            value = (value << 1) | readBit()
        }
        value
    }

    private func readBit(): Int64 {
        if (pos >= data.size) {
            throw InflateCheckException("the stream ran out of bits before the block ended")
        }
        let value = (Int64(data[pos]) >> bit) & 1
        bit += 1
        if (bit == 8) {
            bit = 0
            pos += 1
        }
        value
    }

    /*
     * The fixed literal/length table, decoded by walking its four length ranges (RFC 1951 §3.2.6).
     * The ranges are prefix-free, so reading 7 bits and widening on a miss is unambiguous.
     */
    private func readLiteralOrLength(): Int64 {
        let seven = readReversed(7)
        if (seven <= 0b0010111) {
            return 256 + seven // 0000000..0010111 -> 256..279
        }
        let eight = (seven << 1) | readBit()
        if (eight >= 0b00110000 && eight <= 0b10111111) {
            return eight - 0b00110000 // 00110000..10111111 -> 0..143
        }
        if (eight >= 0b11000000 && eight <= 0b11000111) {
            return 280 + eight - 0b11000000 // 11000000..11000111 -> 280..287
        }
        let nine = (eight << 1) | readBit()
        if (nine >= 0b110010000 && nine <= 0b111111111) {
            return 144 + nine - 0b110010000 // 110010000..111111111 -> 144..255
        }
        throw InflateCheckException("no fixed-Huffman code matches the bits at byte ${pos}")
    }
}

class InflateCheckException <: Exception {
    init(message: String) {
        super(message)
    }
}

/** Strips the RFC 1950 wrapper and checks the Adler-32 the encoder appended actually matches. */
func inflateZlib(stream: Array<UInt8>): Array<UInt8> {
    if (stream.size < 6) {
        throw InflateCheckException("a zlib stream needs at least a 2-byte header and a 4-byte tail")
    }
    let body = Array<UInt8>(stream.size - 6, repeat: 0)
    for (i in 0..body.size) {
        body[i] = stream[2 + i]
    }
    let plain = Inflater(body).run()
    var tail: UInt32 = 0
    for (i in 0..4) {
        tail = (tail << 8) | UInt32(stream[stream.size - 4 + i])
    }
    if (tail != adler32(plain)) {
        throw InflateCheckException("the Adler-32 tail does not match what actually inflated")
    }
    plain
}

func roundTrips(data: Array<UInt8>): Bool {
    let back = inflateZlib(compressToZlib(data))
    if (back.size != data.size) {
        return false
    }
    for (i in 0..data.size) {
        if (back[i] != data[i]) {
            return false
        }
    }
    true
}

// Deterministic pseudo-noise, so any failure is reproducible.
func scramble(i: Int64): UInt8 {
    var state = (i * 1103515245 + 12345) & 0x7FFFFFFF
    state = (state ^ (state >> 13)) * 2654435761
    UInt8((state >> 16) & 0xFF)
}

@Test
func zlibRoundTripsTheShapesAPngActuallyCarries(): Unit {
    @Expect(roundTrips(Array<UInt8>()))
    @Expect(roundTrips([0]))
    @Expect(roundTrips([1, 2]))
    // Below MIN_MATCH nothing can be encoded as a match; these must survive as literals.
    @Expect(roundTrips([7, 7]))
    @Expect(roundTrips([7, 7, 7]))
    @Expect(roundTrips("the quick brown fox jumps over the lazy dog".toArray()))
    // A flat background: one enormous run, which is most of a real figure.
    @Expect(roundTrips(Array<UInt8>(100000, repeat: 0)))
    // Every byte value, so all four fixed-Huffman code ranges are exercised.
    let all = Array<UInt8>(256, repeat: 0)
    for (i in 0..256) {
        all[i] = UInt8(i)
    }
    @Expect(roundTrips(all))
}

@Test
func zlibRoundTripsIncompressibleInput(): Unit {
    // Noise walks the hash chains to MAX_CHAIN everywhere and matches almost nothing.
    let noise = Array<UInt8>(60000, repeat: 0)
    for (i in 0..noise.size) {
        noise[i] = scramble(i)
    }
    @Expect(roundTrips(noise))
}

/**
 * The sliding-window edge, which is where the match finder is least forgiving.
 *
 * `chain` is a ring of WINDOW_SIZE entries indexed by `pos & WINDOW_MASK`, so a position's slot is
 * reused by the position exactly WINDOW_SIZE later. What keeps that sound is that `findMatch` only
 * ever reads slots for candidates at or above `pos - WINDOW_SIZE`, and those are WINDOW_SIZE
 * consecutive positions, hence WINDOW_SIZE distinct slots — none of which can have been overwritten,
 * because overwriting one would mean inserting a position at or beyond `pos`, and nothing at or
 * beyond `pos` is ever inserted. A period at the window limit is what would break if that were off
 * by one: the encoder would either miss a legal match or, worse, emit a stale one.
 */
@Test
func zlibRoundTripsAtEveryDistanceAroundTheWindowEdge(): Unit {
    for (period in [WINDOW_SIZE - 2, WINDOW_SIZE - 1, WINDOW_SIZE, WINDOW_SIZE + 1, WINDOW_SIZE + 2]) {
        let data = Array<UInt8>(period * 3, repeat: 0)
        for (i in 0..data.size) {
            data[i] = scramble(i % period)
        }
        @Expect(roundTrips(data))
    }
}

/**
 * A match at exactly 32768 bytes back is legal (RFC 1951 §3.2.5) and must be found; one byte
 * further is not addressable and must not be. Compressing the two says which side of the line the
 * encoder actually draws.
 */
@Test
func theWindowReachesExactly32768BytesAndNoFurther(): Unit {
    let inside = Array<UInt8>(200000, repeat: 0)
    for (i in 0..inside.size) {
        inside[i] = scramble(i % WINDOW_SIZE)
    }
    let outside = Array<UInt8>(200000, repeat: 0)
    for (i in 0..outside.size) {
        outside[i] = scramble(i % (WINDOW_SIZE + 1))
    }

    // Repeating at the window limit: every byte past the first period is one long match.
    @Expect(compressToZlib(inside).size < inside.size / 2)
    // One byte past it: nothing is addressable, so this can only grow.
    @Expect(compressToZlib(outside).size > outside.size)
    @Expect(roundTrips(inside))
    @Expect(roundTrips(outside))
}

/** The whole encoder, through the filters, on the kind of image the exporter actually hands it. */
@Test
func pngIdatInflatesBackToItsFilteredScanlines(): Unit {
    let width = 64
    let height = 48
    let pixels = Array<UInt8>(width * height * BYTES_PER_PIXEL, repeat: 0)
    for (i in 0..pixels.size) {
        // A gradient with noise on it: the adaptive filter picks different kinds per row.
        pixels[i] = UInt8((Int64(scramble(i / 97)) + i / 16) & 0xFF)
    }
    let image = ImageBuffer(width, height, pixels)
    let filtered = filterScanlines(image)

    @Expect(filtered.size, height * (width * BYTES_PER_PIXEL + 1))
    let back = inflateZlib(compressToZlib(filtered))
    @Expect(back.size, filtered.size)
    for (i in 0..filtered.size) {
        @Expect(back[i], filtered[i])
    }
    // Every row must declare a filter type PNG actually defines (RFC 2083 §6).
    for (y in 0..height) {
        @Expect(Int64(filtered[y * (width * BYTES_PER_PIXEL + 1)]) < FILTER_COUNT)
    }
}
