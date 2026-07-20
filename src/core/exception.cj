package plot.core

/**
 * Raised when a plot is described in a way that cannot be rendered — mismatched series lengths, an
 * unparseable colour literal, a non-positive value on a log axis, or an empty required dataset.
 *
 * These are programming errors in the chart description, not runtime conditions to recover from;
 * conditions that are merely *absent* (a series with no finite points, an axis with no data) are
 * reported as `Option` instead.
 */
public class PlotException <: Exception {
    public init(message: String) {
        super(message)
    }
}
