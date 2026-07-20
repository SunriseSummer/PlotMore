package plot.canvas

/**
 * How a data line is stroked. Dash patterns are expressed in multiples of the line width, so a
 * dashed line keeps its rhythm when the width changes.
 */
public enum LineStyle <: Equatable<LineStyle> {
    | Solid
    | Dashed
    | Dotted
    | DashDot
    | NoLine

    /** The on/off run lengths for this style at `width`, or `None` for a continuous stroke. */
    public func dashPattern(width: Float32): ?(Float32, Float32) {
        match (this) {
            case Solid => None
            case NoLine => None
            case Dashed => Some((width * 3.5, width * 2.5))
            case Dotted => Some((width * 0.6, width * 2.0))
            case DashDot => Some((width * 3.5, width * 2.0))
        }
    }

    /** True when the style draws nothing, letting markers stand alone. */
    public func isHidden(): Bool {
        match (this) {
            case NoLine => true
            case _ => false
        }
    }

    public operator func ==(other: LineStyle): Bool {
        match ((this, other)) {
            case (Solid, Solid) => true
            case (Dashed, Dashed) => true
            case (Dotted, Dotted) => true
            case (DashDot, DashDot) => true
            case (NoLine, NoLine) => true
            case _ => false
        }
    }

    public operator func !=(other: LineStyle): Bool {
        !(this == other)
    }
}

/**
 * The glyph drawn at a data point. `None` leaves the line unmarked; every other shape is drawn
 * centred on the point and sized by its circumscribed radius, so different shapes at the same size
 * carry similar visual weight.
 */
public enum MarkerStyle <: Equatable<MarkerStyle> {
    | Circle
    | Square
    | Diamond
    | Triangle
    | TriangleDown
    | Cross
    | Plus
    | Star
    | Ring
    | NoMarker

    /** True when the style draws nothing. */
    public func isHidden(): Bool {
        match (this) {
            case NoMarker => true
            case _ => false
        }
    }

    /** True when the shape is a stroked outline rather than a filled area. */
    public func isStroked(): Bool {
        match (this) {
            case Cross => true
            case Plus => true
            case Ring => true
            case _ => false
        }
    }

    public operator func ==(other: MarkerStyle): Bool {
        match ((this, other)) {
            case (Circle, Circle) => true
            case (Square, Square) => true
            case (Diamond, Diamond) => true
            case (Triangle, Triangle) => true
            case (TriangleDown, TriangleDown) => true
            case (Cross, Cross) => true
            case (Plus, Plus) => true
            case (Star, Star) => true
            case (Ring, Ring) => true
            case (NoMarker, NoMarker) => true
            case _ => false
        }
    }

    public operator func !=(other: MarkerStyle): Bool {
        !(this == other)
    }
}

/** Horizontal anchoring for `Canvas.textAnchored`. */
public enum HAlign {
    | Left
    | Center
    | Right
}

/** Vertical anchoring for `Canvas.textAnchored`. */
public enum VAlign {
    | Top
    | Middle
    | Bottom
}
