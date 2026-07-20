package plot.core

import std.convert.Formattable
import std.math.{abs, floor, log10}

/**
 * Number-to-label formatting for axes, legends, and readouts.
 *
 * The goal throughout is the shortest label that still distinguishes neighbouring ticks: trailing
 * zeros are trimmed, and scientific notation appears only once plain decimal would be unreadable.
 */
public class NumberFormat {
    // Beyond these magnitudes a plain decimal label grows longer than it is informative.
    private static let SCIENTIFIC_HIGH: Float64 = 1.0e6
    private static let SCIENTIFIC_LOW: Float64 = 1.0e-4

    /**
     * A tick label for `value`, given the spacing between neighbouring ticks. The step decides the
     * decimal places, so a 0.05 step labels `0.05` rather than the `0.1` that rounding to the
     * value's own magnitude would produce.
     */
    public static func tick(value: Float64, step: Float64): String {
        if (!isFinite(value)) {
            return nonFiniteLabel(value)
        }
        let magnitude = abs(value)
        if (magnitude > 0.0 && (magnitude >= SCIENTIFIC_HIGH || magnitude < SCIENTIFIC_LOW)) {
            return scientific(value, 1)
        }
        let normalized = if (value == 0.0) {
            // Round-trip -0.0 to 0.0 so an axis crossing zero never prints "-0".
            0.0
        } else {
            value
        }
        trimZeros(normalized.format(".${decimalsFor(step)}"))
    }

    /** A general-purpose compact label: up to `maxDecimals` places, trailing zeros removed. */
    public static func compact(value: Float64, maxDecimals!: Int64 = 3): String {
        if (!isFinite(value)) {
            return nonFiniteLabel(value)
        }
        let magnitude = abs(value)
        if (magnitude > 0.0 && (magnitude >= SCIENTIFIC_HIGH || magnitude < SCIENTIFIC_LOW)) {
            return scientific(value, 2)
        }
        trimZeros(value.format(".${clampDecimals(maxDecimals)}"))
    }

    /** A fixed-decimal label, zeros kept — for tables and readouts that should not jitter in width. */
    public static func fixed(value: Float64, decimals: Int64): String {
        if (!isFinite(value)) {
            return nonFiniteLabel(value)
        }
        value.format(".${clampDecimals(decimals)}")
    }

    /** Scientific notation with `decimals` places in the mantissa, e.g. `1.2e+03`. */
    public static func scientific(value: Float64, decimals: Int64): String {
        if (!isFinite(value)) {
            return nonFiniteLabel(value)
        }
        value.format(".${clampDecimals(decimals)}e")
    }

    /** A percentage label; `0.42` becomes `42%`. */
    public static func percent(value: Float64, decimals!: Int64 = 0): String {
        if (!isFinite(value)) {
            return nonFiniteLabel(value)
        }
        "${trimZeros((value * 100.0).format(".${clampDecimals(decimals)}"))}%"
    }

    /**
     * A power-of-ten label for log axes: `1000` renders as `10^3`, while values near unity stay
     * plain because `10^0` reads worse than `1`.
     */
    public static func power10(exponent: Int64): String {
        match (exponent) {
            case 0 => "1"
            case 1 => "10"
            case _ => "10^${exponent}"
        }
    }

    /**
     * Decimal places appropriate for a tick spacing of `step`. Tick steps are always 1, 2 or 5
     * times a power of ten, so the leading digit never needs extra precision beyond the step's own
     * magnitude.
     */
    public static func decimalsFor(step: Float64): Int64 {
        if (!isFinite(step) || step <= 0.0) {
            return 0
        }
        // The epsilon absorbs log10(0.1) landing a hair below -1 in binary floating point, which
        // would otherwise ask for one decimal too many on every 0.1-stepped axis.
        let places = Int64(-floor(log10(step) + 1.0e-9))
        clampDecimals(places)
    }

    private static func clampDecimals(decimals: Int64): Int64 {
        if (decimals < 0) {
            0
        } else if (decimals > 15) {
            15
        } else {
            decimals
        }
    }

    private static func nonFiniteLabel(value: Float64): String {
        if (value.isNaN()) {
            "NaN"
        } else if (value > 0.0) {
            "∞"
        } else {
            "-∞"
        }
    }

    /** Drops a trailing `.000…` tail, and any trailing zeros after a real decimal digit. */
    private static func trimZeros(text: String): String {
        if (!text.contains(".")) {
            return text
        }
        var end = text.size
        while (end > 0 && text[end - 1] == b'0') {
            end -= 1
        }
        if (end > 0 && text[end - 1] == b'.') {
            end -= 1
        }
        if (end == 0) {
            return "0"
        }
        text[0..end]
    }
}
