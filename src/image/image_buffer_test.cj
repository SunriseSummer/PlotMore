package plot.image

import plot.core.PlotException

/**
 * True when `action` rejects its input with a `PlotException`.
 *
 * Hand-rolled rather than reached for via `@ExpectThrows`, because that macro expands to a shape the
 * compiler flags as unreachable and this project holds its build to zero warnings.
 */
func throwsPlotException<T>(action: () -> T): Bool {
    try {
        action()
        return false
    } catch (_: PlotException) {
        return true
    }
}

@Test
func imageBufferExposesItsDimensionsAndPixels(): Unit {
    let image = ImageBuffer(2, 3, Array<UInt8>(24, repeat: 7))

    @Expect(image.width(), 2)
    @Expect(image.height(), 3)
    @Expect(image.pixels().size, 24)
    @Expect(image.pixels()[0], UInt8(7))
}

@Test
func imageBufferRejectsAPixelArrayOfTheWrongSize(): Unit {
    @Expect(throwsPlotException({=> ImageBuffer(2, 3, Array<UInt8>(23, repeat: 0))}))
    @Expect(throwsPlotException({=> ImageBuffer(2, 3, Array<UInt8>(25, repeat: 0))}))
    @Expect(throwsPlotException({=> ImageBuffer(2, 3, Array<UInt8>())}))
}

@Test
func imageBufferRejectsNonPositiveDimensions(): Unit {
    @Expect(throwsPlotException({=> ImageBuffer(0, 3, Array<UInt8>())}))
    @Expect(throwsPlotException({=> ImageBuffer(2, -1, Array<UInt8>())}))
}

/**
 * A side that would overflow the `width * height * 4` multiply has to surface as a `PlotException`,
 * not as the arithmetic trap Cangjie would otherwise raise from inside the constructor.
 */
@Test
func imageBufferRejectsDimensionsThatWouldOverflowTheAreaMultiply(): Unit {
    @Expect(throwsPlotException({=> ImageBuffer(4611686018427387904, 4, Array<UInt8>())}))
    @Expect(throwsPlotException({=> ImageBuffer(4, 4611686018427387904, Array<UInt8>())}))
}
