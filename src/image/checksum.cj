package plot.image

/** Reflected CRC-32 polynomial (IEEE 802.3) — the variant PNG chunk CRCs use (RFC 2083 annex D). */
private const CRC32_POLYNOMIAL: UInt32 = 0xEDB88320

/** Initial CRC-32 register value, and the mask XORed back in to close the register. */
private const CRC32_SEED: UInt32 = 0xFFFFFFFF

/** Largest prime below 2^16, the modulus Adler-32 reduces both of its sums by (RFC 1950 §9). */
private const ADLER32_MODULUS: UInt32 = 65521

/**
 * Byte-at-a-time CRC-32 lookup table, one entry per possible low byte of the register.
 *
 * Computed at start-up rather than spelled out as a 256-entry literal, and preferred over the
 * bit-at-a-time loop because PNG checksums every chunk — including a multi-megabyte IDAT — and the
 * unrolled form would cost eight times as many iterations for no benefit.
 */
private let CRC32_TABLE: Array<UInt32> = buildCrc32Table()

private func buildCrc32Table(): Array<UInt32> {
    let table = Array<UInt32>(256, repeat: 0)
    for (n in 0..256) {
        var register = UInt32(n)
        for (_ in 0..8) {
            if ((register & 1) == 1) {
                register = CRC32_POLYNOMIAL ^ (register >> 1)
            } else {
                register >>= 1
            }
        }
        table[n] = register
    }
    table
}

private func updateCrc32(seed: UInt32, bytes: Array<UInt8>): UInt32 {
    var register = seed
    for (byte in bytes) {
        register = CRC32_TABLE[Int64((register ^ UInt32(byte)) & 0xFF)] ^ (register >> 8)
    }
    register
}

/**
 * CRC-32 of `first` followed by `second`, as PNG writes after the data of every chunk.
 *
 * The input arrives in two pieces because that is the shape PNG asks for — a chunk's CRC covers its
 * type and then its data — and concatenating a four-byte type onto a multi-megabyte IDAT purely to
 * hash it would double the encoder's peak memory to no end. Pass an empty `second` for a plain
 * one-shot checksum.
 */
func crc32(first: Array<UInt8>, second: Array<UInt8>): UInt32 {
    updateCrc32(updateCrc32(CRC32_SEED, first), second) ^ CRC32_SEED
}

/**
 * Adler-32 of `bytes` — the checksum a zlib stream carries over its *uncompressed* data.
 *
 * Both sums are reduced on every byte rather than in the customary 5552-byte batches. That costs two
 * divisions per byte, but it holds `low` under 65776 and `high` under 131296, so neither can overflow
 * `UInt32` — and in Cangjie an overflow is a trap, not a wrap, so the batched form would need explicit
 * wrapping arithmetic just to stay correct.
 */
func adler32(bytes: Array<UInt8>): UInt32 {
    var low: UInt32 = 1
    var high: UInt32 = 0
    for (byte in bytes) {
        low = (low + UInt32(byte)) % ADLER32_MODULUS
        high = (high + low) % ADLER32_MODULUS
    }
    (high << 16) | low
}
