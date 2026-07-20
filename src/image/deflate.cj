package plot.image

import std.collection.ArrayList

/** DEFLATE's sliding window: a match may point at most 32768 bytes back (RFC 1951 §3.2.5). */
const WINDOW_SIZE: Int64 = 32768

/** Wraps a position into the chain ring; `WINDOW_SIZE` is a power of two, so this is a plain AND. */
const WINDOW_MASK: Int64 = 32767

/** Longest match DEFLATE can encode in one length/distance pair. */
const MAX_MATCH: Int64 = 258

/** Shortest match worth encoding — below three bytes a pair costs more bits than plain literals. */
const MIN_MATCH: Int64 = 3

/** Hash-table size for the three-byte match finder; a power of two so `HASH_MASK` is a plain AND. */
const HASH_SIZE: Int64 = 32768
const HASH_MASK: Int64 = 32767

/**
 * How far down a hash chain to walk before giving up.
 *
 * Chains degenerate to thousands of entries on noisy data while the tail almost never improves on the
 * match already found, so the cap trades a sliver of ratio for a bounded, predictable encode time.
 */
const MAX_CHAIN: Int64 = 128

/** Stop the chain walk once a match this long turns up; the rest of the chain cannot pay for itself. */
const NICE_MATCH: Int64 = 128

/** Past this match length the lazy probe at the next byte practically never wins, so skip it. */
const MAX_LAZY_MATCH: Int64 = 16

/** Literal/length symbol that terminates a DEFLATE block. */
const END_OF_BLOCK: Int64 = 256

/** Sentinel for "no entry" in the hash head/chain tables; positions are never negative. */
const EMPTY_SLOT: Int64 = -1

/** Smallest length each length code 257..285 encodes (RFC 1951 §3.2.5). */
let LENGTH_BASE: Array<Int64> = [
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    13,
    15,
    17,
    19,
    23,
    27,
    31,
    35,
    43,
    51,
    59,
    67,
    83,
    99,
    115,
    131,
    163,
    195,
    227,
    258
]

/** Extra bits carried after each length code, aligned with `LENGTH_BASE`. */
let LENGTH_EXTRA: Array<Int64> = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    3,
    3,
    3,
    3,
    4,
    4,
    4,
    4,
    5,
    5,
    5,
    5,
    0
]

/** Smallest distance each distance code 0..29 encodes (RFC 1951 §3.2.5). */
let DISTANCE_BASE: Array<Int64> = [
    1,
    2,
    3,
    4,
    5,
    7,
    9,
    13,
    17,
    25,
    33,
    49,
    65,
    97,
    129,
    193,
    257,
    385,
    513,
    769,
    1025,
    1537,
    2049,
    3073,
    4097,
    6145,
    8193,
    12289,
    16385,
    24577
]

/** Extra bits carried after each distance code, aligned with `DISTANCE_BASE`. */
let DISTANCE_EXTRA: Array<Int64> = [
    0,
    0,
    0,
    0,
    1,
    1,
    2,
    2,
    3,
    3,
    4,
    4,
    5,
    5,
    6,
    6,
    7,
    7,
    8,
    8,
    9,
    9,
    10,
    10,
    11,
    11,
    12,
    12,
    13,
    13
]

/**
 * Index of the largest entry of the ascending `bases` that does not exceed `value`.
 *
 * Both code tables are scanned once per emitted match, and the distance table is 30 entries long, so
 * a bisection rather than a linear walk keeps the inner loop off the profile. `bases` must be
 * non-empty and `value` at least `bases[0]`.
 */
func largestIndexNotAbove(bases: Array<Int64>, value: Int64): Int64 {
    var low = 0
    var high = bases.size - 1
    while (low < high) {
        let mid = (low + high + 1) / 2
        if (bases[mid] <= value) {
            low = mid
        } else {
            high = mid - 1
        }
    }
    low
}

/**
 * Reverses the low `count` bits of `value`.
 *
 * DEFLATE packs ordinary fields least-significant bit first but Huffman codes most-significant bit
 * first, so pre-reversing a code lets both go through the same LSB-first packer.
 */
func reverseBits(value: UInt32, count: Int64): UInt32 {
    var source = value
    var result: UInt32 = 0
    for (_ in 0..count) {
        result = (result << 1) | (source & 1)
        source >>= 1
    }
    result
}

/** Packs bits into bytes least-significant bit first, the order DEFLATE requires (RFC 1951 §3.1.1). */
class BitWriter {
    private let out: ArrayList<UInt8> = ArrayList<UInt8>()
    private var pending: UInt32 = 0
    private var pendingBits: Int64 = 0

    /** Appends the low `count` bits of `value`, least-significant first; bits above `count` must be 0. */
    func writeBits(value: UInt32, count: Int64): Unit {
        pending |= (value << UInt32(pendingBits))
        pendingBits += count
        while (pendingBits >= 8) {
            out.add(UInt8(pending & 0xFF))
            pending >>= 8
            pendingBits -= 8
        }
    }

    /** Appends a Huffman code, emitting the most-significant of its `count` bits first. */
    func writeCode(code: UInt32, count: Int64): Unit {
        writeBits(reverseBits(code, count), count)
    }

    /** Zero-pads the final partial byte and yields the packed stream. */
    func finish(): Array<UInt8> {
        if (pendingBits > 0) {
            out.add(UInt8(pending & 0xFF))
            pending = 0
            pendingBits = 0
        }
        out.toArray()
    }
}

/**
 * LZ77 over fixed Huffman codes (RFC 1951), emitting the whole input as a single final block.
 *
 * Fixed codes rather than dynamic ones: they cost nothing to transmit, need no symbol histogram or
 * code-length pass, and on filtered plot scanlines — long runs of zero broken by short gradients —
 * the win a dynamic table would buy is small next to the code it would take to get right.
 */
class Deflater {
    private let data: Array<UInt8>
    private let head: Array<Int64>
    private let chain: Array<Int64>
    private let writer: BitWriter = BitWriter()

    init(source: Array<UInt8>) {
        data = source
        head = Array<Int64>(HASH_SIZE, repeat: EMPTY_SLOT)
        // A ring of WINDOW_SIZE entries, not one per input byte. A match can never reach further
        // back than the window, so a position's chain slot is still valid for exactly as long as
        // that position is reachable — and a full-size table would cost 8 bytes per input byte,
        // which is ~100 MB for a supersampled figure and enough to exhaust the heap on its own.
        chain = Array<Int64>(WINDOW_SIZE, repeat: EMPTY_SLOT)
    }

    /** Encodes the source into one BFINAL fixed-Huffman block and returns the raw DEFLATE bytes. */
    func encode(): Array<UInt8> {
        writer.writeBits(1, 1) // BFINAL: a single block spans the whole stream.
        writer.writeBits(1, 2) // BTYPE = 01, fixed Huffman codes.
        let length = data.size
        var pos = 0
        while (pos < length) {
            let (matchLength, matchDistance) = findMatch(pos)
            if (matchLength < MIN_MATCH) {
                emitSymbol(Int64(data[pos]))
                insert(pos)
                pos += 1
                continue
            }
            insert(pos)
            // Lazy matching: if the byte after this one starts a strictly longer match, spending a
            // literal here and taking that one instead is a net win. A match already near the 258-byte
            // cap cannot be improved on enough to pay for the extra search, hence the MAX_LAZY_MATCH gate.
            var deferToNextByte = false
            if (matchLength < MAX_LAZY_MATCH && pos + 1 < length) {
                let (nextLength, _) = findMatch(pos + 1)
                deferToNextByte = nextLength > matchLength
            }
            if (deferToNextByte) {
                emitSymbol(Int64(data[pos]))
                pos += 1
            } else {
                emitMatch(matchLength, matchDistance)
                // Positions covered by the match still have to enter the chains, or later matches
                // would be blind to everything inside it. `pos` itself is already in.
                for (covered in (pos + 1)..(pos + matchLength)) {
                    insert(covered)
                }
                pos += matchLength
            }
        }
        emitSymbol(END_OF_BLOCK)
        writer.finish()
    }

    /**
     * Longest match for the three-or-more bytes at `pos`, as `(length, distance)`, or `(0, 0)`.
     *
     * Every position below `pos` must already be in the chains; positions at or above it must not be.
     */
    private func findMatch(pos: Int64): (Int64, Int64) {
        let length = data.size
        if (pos + MIN_MATCH > length) {
            return (0, 0)
        }
        let oldest = if (pos > WINDOW_SIZE) {
            pos - WINDOW_SIZE
        } else {
            0
        }
        let maxLength = min(MAX_MATCH, length - pos)
        var bestLength = MIN_MATCH - 1
        var bestDistance = 0
        var remaining = MAX_CHAIN
        var candidate = head[hashAt(pos)]
        // `bestLength < maxLength` holds on entry to every iteration (the loop breaks otherwise), which
        // is what keeps the `+ bestLength` probes below inside the array.
        while (candidate >= oldest && remaining > 0) {
            remaining -= 1
            // Cheap reject first: a candidate can only win by matching at least at the current best
            // length, and that single byte rules out the overwhelming majority of chain entries.
            if (data[candidate + bestLength] == data[pos + bestLength]) {
                var run = 0
                while (run < maxLength && data[candidate + run] == data[pos + run]) {
                    run += 1
                }
                if (run > bestLength) {
                    bestLength = run
                    bestDistance = pos - candidate
                    if (bestLength >= NICE_MATCH || bestLength >= maxLength) {
                        break
                    }
                }
            }
            // Safe against the ring wrapping: `candidate >= oldest` bounds the walk to the window,
            // and within the window a slot still holds the entry written when that position went in.
            candidate = chain[candidate & WINDOW_MASK]
        }
        if (bestLength >= MIN_MATCH) {
            (bestLength, bestDistance)
        } else {
            (0, 0)
        }
    }

    /** Links `pos` into the hash chain for the three bytes starting there. */
    private func insert(pos: Int64): Unit {
        if (pos + MIN_MATCH > data.size) {
            return // No three-byte key at the tail, and nothing could match there anyway.
        }
        let bucket = hashAt(pos)
        chain[pos & WINDOW_MASK] = head[bucket]
        head[bucket] = pos
    }

    /** Hashes the three bytes at `pos`; `MIN_MATCH` is 3, so three bytes is the shortest useful key. */
    private func hashAt(pos: Int64): Int64 {
        ((Int64(data[pos]) << 10) ^ (Int64(data[pos + 1]) << 5) ^ Int64(data[pos + 2])) & HASH_MASK
    }

    /** Emits one literal/length symbol under the fixed Huffman code table (RFC 1951 §3.2.6). */
    private func emitSymbol(symbol: Int64): Unit {
        if (symbol <= 143) {
            writer.writeCode(UInt32(0x30 + symbol), 8)
        } else if (symbol <= 255) {
            writer.writeCode(UInt32(0x190 + symbol - 144), 9)
        } else if (symbol <= 279) {
            writer.writeCode(UInt32(symbol - 256), 7)
        } else {
            writer.writeCode(UInt32(0xC0 + symbol - 280), 8)
        }
    }

    /** Emits a length/distance pair: each code, then its extra bits packed least-significant first. */
    private func emitMatch(length: Int64, distance: Int64): Unit {
        let lengthCode = largestIndexNotAbove(LENGTH_BASE, length)
        emitSymbol(257 + lengthCode)
        let lengthExtra = LENGTH_EXTRA[lengthCode]
        if (lengthExtra > 0) {
            writer.writeBits(UInt32(length - LENGTH_BASE[lengthCode]), lengthExtra)
        }
        let distanceCode = largestIndexNotAbove(DISTANCE_BASE, distance)
        // Under fixed Huffman every distance code is its own 5-bit value, most-significant bit first.
        writer.writeCode(UInt32(distanceCode), 5)
        let distanceExtra = DISTANCE_EXTRA[distanceCode]
        if (distanceExtra > 0) {
            writer.writeBits(UInt32(distance - DISTANCE_BASE[distanceCode]), distanceExtra)
        }
    }
}

/**
 * Compresses `data` into a zlib stream (RFC 1950) — exactly the framing a PNG IDAT payload carries.
 */
func compressToZlib(data: Array<UInt8>): Array<UInt8> {
    let body = Deflater(data).encode()
    let checksum = adler32(data)
    let out = Array<UInt8>(2 + body.size + 4, repeat: 0)
    // CMF: compression method 8 (deflate) with CINFO 7, i.e. the full 32K window the encoder uses.
    out[0] = 0x78
    // FLG: no preset dictionary, level 0. The pair is also chosen so (0x78 << 8 | 0x01) is a multiple
    // of 31, which RFC 1950 §2.2 requires of the header and every decoder checks first.
    out[1] = 0x01
    for (i in 0..body.size) {
        out[2 + i] = body[i]
    }
    // Adler-32 of the *uncompressed* data, big-endian, closes the stream (RFC 1950 §2.2).
    let tail = 2 + body.size
    out[tail] = UInt8((checksum >> 24) & 0xFF)
    out[tail + 1] = UInt8((checksum >> 16) & 0xFF)
    out[tail + 2] = UInt8((checksum >> 8) & 0xFF)
    out[tail + 3] = UInt8(checksum & 0xFF)
    out
}
