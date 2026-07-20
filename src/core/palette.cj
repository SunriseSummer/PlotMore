package plot.core

import std.collection.ArrayList
import sdl.Color

/**
 * An ordered set of categorical colours, indexed by series position.
 *
 * `at` wraps, so a palette never runs out: the eleventh series in a ten-colour palette reuses the
 * first colour rather than throwing or going invisible.
 */
public struct Palette {
    private let colors: Array<Color>

    /**
     * Throws `PlotException` when `colors` is empty, since `at` could not then return anything.
     */
    public init(colors: Array<Color>) {
        if (colors.size == 0) {
            throw PlotException("A palette needs at least one colour.")
        }
        this.colors = colors
    }

    /** The colour for series `index`, wrapping once the palette is exhausted. */
    public func at(index: Int64): Color {
        let count = colors.size
        var i = index % count
        if (i < 0) {
            i += count
        }
        colors[i]
    }

    /** How many distinct colours the palette holds before it repeats. */
    public func size(): Int64 {
        colors.size
    }

    /**
     * A calm, high-contrast qualitative set that stays distinguishable on both light and dark
     * backgrounds — the default for series colouring.
     */
    public static func modern(): Palette {
        Palette(
            [
                Colors.hex("#3B82F6"),
                Colors.hex("#EF4444"),
                Colors.hex("#10B981"),
                Colors.hex("#F59E0B"),
                Colors.hex("#8B5CF6"),
                Colors.hex("#06B6D4"),
                Colors.hex("#EC4899"),
                Colors.hex("#84CC16"),
                Colors.hex("#F97316"),
                Colors.hex("#6366F1")
            ]
        )
    }

    /** A muted, print-friendly set for dense multi-series figures. */
    public static func muted(): Palette {
        Palette(
            [
                Colors.hex("#4C78A8"),
                Colors.hex("#F58518"),
                Colors.hex("#E45756"),
                Colors.hex("#72B7B2"),
                Colors.hex("#54A24B"),
                Colors.hex("#EECA3B"),
                Colors.hex("#B279A2"),
                Colors.hex("#FF9DA6"),
                Colors.hex("#9D755D"),
                Colors.hex("#BAB0AC")
            ]
        )
    }

    /**
     * Okabe-Ito: eight colours chosen to stay separable under the common forms of colour vision
     * deficiency. The right default for figures meant for publication.
     */
    public static func colorblindSafe(): Palette {
        Palette(
            [
                Colors.hex("#0072B2"),
                Colors.hex("#E69F00"),
                Colors.hex("#009E73"),
                Colors.hex("#CC79A7"),
                Colors.hex("#56B4E9"),
                Colors.hex("#D55E00"),
                Colors.hex("#F0E442"),
                Colors.hex("#000000")
            ]
        )
    }

    /** A saturated set with enough punch to read on a dark background or a projector. */
    public static func vivid(): Palette {
        Palette(
            [
                Colors.hex("#00C2FF"),
                Colors.hex("#FF4D6D"),
                Colors.hex("#3DDC97"),
                Colors.hex("#FFC145"),
                Colors.hex("#C77DFF"),
                Colors.hex("#4CC9F0"),
                Colors.hex("#FF9F1C"),
                Colors.hex("#B5E48C")
            ]
        )
    }
}

/**
 * A continuous colour scale: `sample(t)` maps `0..1` onto a colour ramp, interpolating between the
 * anchor stops. Used for heatmaps, contour fills, and any value-mapped colouring.
 *
 * The perceptual maps (`viridis`, `magma`, `plasma`, `inferno`, `cividis`) are sampled from the
 * matplotlib originals; each is approximately perceptually uniform, so equal steps in `t` read as
 * equal steps in colour — the property that makes them honest for quantitative data. `coolWarm` and
 * `spectral` are diverging maps for signed data around a midpoint.
 */
public struct Colormap {
    private let stops: Array<Color>

    /**
     * Throws `PlotException` when fewer than two stops are supplied, since a ramp needs an
     * interval to interpolate across.
     */
    public init(stops: Array<Color>) {
        if (stops.size < 2) {
            throw PlotException("A colormap needs at least two stops.")
        }
        this.stops = stops
    }

    /** The colour at `t`, clamped to `0..1` and interpolated between neighbouring stops. */
    public func sample(t: Float64): Color {
        let clamped = clamp01f(t)
        let last = stops.size - 1
        let scaled = clamped * Float64(last)
        var index = Int64(scaled)
        if (index >= last) {
            return stops[last]
        }
        if (index < 0) {
            index = 0
        }
        stops[index].lerp(stops[index + 1], Float32(scaled - Float64(index)))
    }

    /**
     * The colour for `value` positioned within `domain`; values outside the domain clamp to the
     * end stops. Degenerate domains map everything to the ramp midpoint rather than dividing by
     * zero.
     */
    public func sampleIn(value: Float64, domain: Bounds): Color {
        if (domain.isDegenerate()) {
            return sample(0.5)
        }
        sample((value - domain.low) / domain.span())
    }

    /** `count` evenly spaced samples across the ramp — used to build lookup textures and legends. */
    public func ramp(count: Int64): Array<Color> {
        if (count <= 1) {
            return [sample(0.5)]
        }
        let result = ArrayList<Color>()
        for (i in 0..count) {
            result.add(sample(Float64(i) / Float64(count - 1)))
        }
        result.toArray()
    }

    /** Reverses the ramp direction. */
    public func reversed(): Colormap {
        let flipped = ArrayList<Color>()
        var i = stops.size - 1
        while (i >= 0) {
            flipped.add(stops[i])
            i -= 1
        }
        Colormap(flipped.toArray())
    }

    /** Perceptually uniform blue-green-yellow; the safe default for sequential data. */
    public static func viridis(): Colormap {
        Colormap(
            [
                Colors.hex("#440154"),
                Colors.hex("#482878"),
                Colors.hex("#3E4A89"),
                Colors.hex("#31688E"),
                Colors.hex("#26828E"),
                Colors.hex("#1F9E89"),
                Colors.hex("#35B779"),
                Colors.hex("#6DCD59"),
                Colors.hex("#B4DE2C"),
                Colors.hex("#FDE725")
            ]
        )
    }

    /** Perceptually uniform black-purple-white. */
    public static func magma(): Colormap {
        Colormap(
            [
                Colors.hex("#000004"),
                Colors.hex("#180F3D"),
                Colors.hex("#440F76"),
                Colors.hex("#721F81"),
                Colors.hex("#9E2F7F"),
                Colors.hex("#CD4071"),
                Colors.hex("#F1605D"),
                Colors.hex("#FD9668"),
                Colors.hex("#FECE91"),
                Colors.hex("#FCFDBF")
            ]
        )
    }

    /** Perceptually uniform blue-red-yellow. */
    public static func plasma(): Colormap {
        Colormap(
            [
                Colors.hex("#0D0887"),
                Colors.hex("#41049D"),
                Colors.hex("#6A00A8"),
                Colors.hex("#8F0DA4"),
                Colors.hex("#B12A90"),
                Colors.hex("#CC4778"),
                Colors.hex("#E16462"),
                Colors.hex("#F2844B"),
                Colors.hex("#FCA636"),
                Colors.hex("#F0F921")
            ]
        )
    }

    /** Perceptually uniform black-red-yellow. */
    public static func inferno(): Colormap {
        Colormap(
            [
                Colors.hex("#000004"),
                Colors.hex("#1B0C41"),
                Colors.hex("#4A0C6B"),
                Colors.hex("#781C6D"),
                Colors.hex("#A52C60"),
                Colors.hex("#CF4446"),
                Colors.hex("#ED6925"),
                Colors.hex("#FB9A06"),
                Colors.hex("#F7D13D"),
                Colors.hex("#FCFFA4")
            ]
        )
    }

    /** Perceptually uniform and colour-vision-deficiency friendly blue-yellow. */
    public static func cividis(): Colormap {
        Colormap(
            [
                Colors.hex("#00224E"),
                Colors.hex("#123570"),
                Colors.hex("#3B496C"),
                Colors.hex("#575D6D"),
                Colors.hex("#707173"),
                Colors.hex("#8A8678"),
                Colors.hex("#A59C74"),
                Colors.hex("#C3B369"),
                Colors.hex("#E1CC55"),
                Colors.hex("#FEE838")
            ]
        )
    }

    /** Diverging blue-white-red, for signed data centred on zero. */
    public static func coolWarm(): Colormap {
        Colormap(
            [
                Colors.hex("#3B4CC0"),
                Colors.hex("#6788EE"),
                Colors.hex("#9ABBFF"),
                Colors.hex("#C9D7F0"),
                Colors.hex("#EDEDED"),
                Colors.hex("#F7B89C"),
                Colors.hex("#E7745B"),
                Colors.hex("#D6404E"),
                Colors.hex("#B40426")
            ]
        )
    }

    /** Diverging red-yellow-blue. */
    public static func spectral(): Colormap {
        Colormap(
            [
                Colors.hex("#9E0142"),
                Colors.hex("#D53E4F"),
                Colors.hex("#F46D43"),
                Colors.hex("#FDAE61"),
                Colors.hex("#FEE08B"),
                Colors.hex("#E6F598"),
                Colors.hex("#ABDDA4"),
                Colors.hex("#66C2A5"),
                Colors.hex("#3288BD"),
                Colors.hex("#5E4FA2")
            ]
        )
    }

    /** A simple light-to-dark ramp of a single hue, derived from `base`. */
    public static func monochrome(base: Color): Colormap {
        Colormap([Colors.lighten(base, 0.85), Colors.lighten(base, 0.45), base, Colors.darken(base, 0.45)])
    }
}
