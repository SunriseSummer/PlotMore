package plot.core

import std.math.{abs, floor, pow}
import sdl.Color

/**
 * Colour construction and blending helpers layered over `sdl.Color`.
 *
 * `sdl.Color` lives in another package and Cangjie's orphan rule keeps direct extensions with the
 * type, so these are free functions rather than methods.
 */
public class Colors {
    /**
     * Parses `#rgb`, `#rrggbb` or `#rrggbbaa` (the leading `#` optional, case-insensitive).
     *
     * Throws `PlotException` when the string is not one of those three shapes, because a malformed
     * literal in a theme is a programming error rather than an expected condition.
     */
    public static func hex(code: String): Color {
        let text = if (code.startsWith("#")) {
            code[1..code.size]
        } else {
            code
        }
        match (text.size) {
            case 3 => Color.rgb(nibble(text, 0), nibble(text, 1), nibble(text, 2))
            case 6 => Color.rgb(byteAt(text, 0), byteAt(text, 2), byteAt(text, 4))
            case 8 => Color.rgba(byteAt(text, 0), byteAt(text, 2), byteAt(text, 4), byteAt(text, 6))
            case _ => throw PlotException("Invalid hex colour '${code}': expected #rgb, #rrggbb or #rrggbbaa.")
        }
    }

    /**
     * Builds a colour from hue (degrees, wrapped), saturation and lightness (both `0..1`).
     * Useful for generating evenly spaced series colours beyond a fixed palette.
     */
    public static func hsl(hue: Float64, saturation: Float64, lightness: Float64): Color {
        let h = floorMod(hue, 360.0)
        let s = clamp01f(saturation)
        let l = clamp01f(lightness)
        let c = (1.0 - abs(2.0 * l - 1.0)) * s
        let hp = h / 60.0
        let x = c * (1.0 - abs(floorMod(hp, 2.0) - 1.0))
        var r = 0.0
        var g = 0.0
        var b = 0.0
        if (hp < 1.0) {
            r = c
            g = x
        } else if (hp < 2.0) {
            r = x
            g = c
        } else if (hp < 3.0) {
            g = c
            b = x
        } else if (hp < 4.0) {
            g = x
            b = c
        } else if (hp < 5.0) {
            r = x
            b = c
        } else {
            r = c
            b = x
        }
        let m = l - c / 2.0
        Color.rgb(channel(r + m), channel(g + m), channel(b + m))
    }

    /** Blends `from` toward `to`; `t` is clamped to `0..1`. */
    public static func mix(from: Color, to: Color, t: Float64): Color {
        from.lerp(to, Float32(clamp01f(t)))
    }

    /** The same colour at a new opacity, given as `0..1` rather than a byte. */
    public static func fade(color: Color, opacity: Float64): Color {
        color.withAlpha(Int64(clamp01f(opacity) * 255.0 + 0.5))
    }

    /** Mixes `color` toward white by `amount` (`0..1`). */
    public static func lighten(color: Color, amount: Float64): Color {
        mix(color, Color.rgb(255, 255, 255), amount)
    }

    /** Mixes `color` toward black by `amount` (`0..1`). */
    public static func darken(color: Color, amount: Float64): Color {
        mix(color, Color.rgb(0, 0, 0), amount)
    }

    /**
     * Relative luminance per WCAG 2.1, in `0..1`. Drives `contrastText`, so a label placed on a
     * data-coloured surface stays legible whatever the palette does.
     */
    public static func luminance(color: Color): Float64 {
        0.2126 * linearize(color.r) + 0.7152 * linearize(color.g) + 0.0722 * linearize(color.b)
    }

    /** Black or white, whichever reads better on `background`. */
    public static func contrastText(background: Color): Color {
        if (luminance(background) > 0.45) {
            Color.rgb(16, 20, 28)
        } else {
            Color.rgb(255, 255, 255)
        }
    }

    private static func linearize(channelValue: UInt8): Float64 {
        let v = Float64(channelValue) / 255.0
        if (v <= 0.04045) {
            v / 12.92
        } else {
            pow((v + 0.055) / 1.055, 2.4)
        }
    }

    private static func nibble(text: String, index: Int64): Int64 {
        let value = hexDigit(text, index)
        value * 16 + value
    }

    private static func byteAt(text: String, index: Int64): Int64 {
        hexDigit(text, index) * 16 + hexDigit(text, index + 1)
    }

    private static func hexDigit(text: String, index: Int64): Int64 {
        let c = text[index]
        if (c >= b'0' && c <= b'9') {
            Int64(c - b'0')
        } else if (c >= b'a' && c <= b'f') {
            Int64(c - b'a') + 10
        } else if (c >= b'A' && c <= b'F') {
            Int64(c - b'A') + 10
        } else {
            throw PlotException("Invalid hex colour digit '${text}'.")
        }
    }

    private static func channel(value: Float64): Int64 {
        Int64(clamp01f(value) * 255.0 + 0.5)
    }
}

/*
 * NaN is caught explicitly because it fails *both* comparisons and would otherwise pass straight
 * through — into `Colormap.sample`'s `Int64(scaled)` and `fade`'s `Int64(...)`, which trap on it.
 * A colormap sampled at a missing value should give an end stop, not bring the frame down.
 */
func clamp01f(value: Float64): Float64 {
    if (value.isNaN() || value < 0.0) {
        0.0
    } else if (value > 1.0) {
        1.0
    } else {
        value
    }
}

/**
 * `value` reduced into `[0, modulus)`. Cangjie's `%` is integer-only, and this keeps the sign
 * convention of a true floor-mod so negative hues wrap forward instead of backward.
 */
public func floorMod(value: Float64, modulus: Float64): Float64 {
    if (modulus <= 0.0) {
        return 0.0
    }
    let result = value - floor(value / modulus) * modulus
    if (result < 0.0) {
        0.0
    } else {
        result
    }
}
