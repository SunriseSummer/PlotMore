package examples

import std.collection.ArrayList
import std.math.{cos, exp, sin, sqrt}
import std.random.Random

/**
 * Sample data shared by the gallery.
 *
 * Every generator is seeded and deterministic: an example that redraws differently on each run is
 * useless as a visual reference, and a gallery is exactly the place where a reader compares what
 * they see against what the code says.
 */
public class Data {
    /** `count` evenly spaced values from `from` to `to`, both ends included. */
    public static func linspace(from: Float64, to: Float64, count: Int64): Array<Float64> {
        if (count < 2) {
            return [from]
        }
        let result = ArrayList<Float64>()
        for (i in 0..count) {
            result.add(from + (to - from) * Float64(i) / Float64(count - 1))
        }
        result.toArray()
    }

    /** `f` applied to every element. */
    public static func map(values: Array<Float64>, f: (Float64) -> Float64): Array<Float64> {
        let result = ArrayList<Float64>()
        for (value in values) {
            result.add(f(value))
        }
        result.toArray()
    }

    /** A seeded random source, so a run is reproducible. */
    public static func random(seed: UInt64): Random {
        Random(seed)
    }

    /** `count` normal samples with the given mean and standard deviation. */
    public static func normal(source: Random, mean: Float64, deviation: Float64, count: Int64): Array<Float64> {
        let result = ArrayList<Float64>()
        for (_ in 0..count) {
            result.add(mean + source.nextGaussianFloat64() * deviation)
        }
        result.toArray()
    }

    /** A random walk starting at `start`, stepping by a normal increment. */
    public static func randomWalk(source: Random, start: Float64, step: Float64, count: Int64): Array<Float64> {
        let result = ArrayList<Float64>()
        var value = start
        for (_ in 0..count) {
            result.add(value)
            value += source.nextGaussianFloat64() * step
        }
        result.toArray()
    }

    /** A damped sine — the stand-in for a decaying physical signal. */
    public static func damped(times: Array<Float64>, frequency: Float64, decay: Float64): Array<Float64> {
        map(times) {t => exp(-decay * t) * sin(frequency * t)}
    }

    /** A two-peak field, sampled row-major over a grid — the classic contour/heatmap subject. */
    public static func peaks(rows: Int64, columns: Int64): Array<Float64> {
        let values = ArrayList<Float64>()
        for (r in 0..rows) {
            let y = -3.0 + 6.0 * Float64(r) / Float64(rows - 1)
            for (c in 0..columns) {
                let x = -3.0 + 6.0 * Float64(c) / Float64(columns - 1)
                values.add(peakAt(x, y))
            }
        }
        values.toArray()
    }

    /** The analytic form behind `peaks`, for the contour example to sample directly. */
    public static func peakAt(x: Float64, y: Float64): Float64 {
        3.0 * (1.0 - x) * (1.0 - x) * exp(-(x * x) - (y + 1.0) * (y + 1.0)) - 10.0 * (x / 5.0 - x * x * x - y * y * y * y *
            y) * exp(-(x * x) - (y * y)) - 1.0 / 3.0 * exp(-(x + 1.0) * (x + 1.0) - (y * y))
    }

    /** A radially symmetric bowl, for a clean contour demonstration. */
    public static func ripple(x: Float64, y: Float64): Float64 {
        let r = sqrt(x * x + y * y)
        if (r < 1.0e-9) {
            return 1.0
        }
        sin(r * 3.0) / (r * 3.0)
    }

    /** Twelve month abbreviations, for category axes. */
    public static func months(): Array<String> {
        ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    }

    /** A smooth seasonal curve over `count` samples, for time-series examples. */
    public static func seasonal(count: Int64, amplitude: Float64, offset: Float64): Array<Float64> {
        let result = ArrayList<Float64>()
        for (i in 0..count) {
            let phase = 6.283185307179586 * Float64(i) / 12.0
            result.add(offset + amplitude * sin(phase) + amplitude * 0.35 * cos(phase * 2.0))
        }
        result.toArray()
    }
}
