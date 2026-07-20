package examples

import std.fs.{Directory, Path, exists}
import plot.{FigureExport, PlotWindow, WindowOptions}
import plot.core.PlotException

/**
 * The gallery entry point.
 *
 * ```text
 * cjpm run                     list every example
 * cjpm run -- line             open one in an interactive window
 * cjpm run -- --export out     render every example to out/<name>.png
 * ```
 */
main(args: Array<String>): Int64 {
    if (args.size == 0) {
        printCatalogue()
        return 0
    }
    match (args[0]) {
        case "--export" =>
            let directory = if (args.size > 1) {
                args[1]
            } else {
                "gallery"
            }
            exportAll(directory)
        case "--list" => printCatalogue()
        case name => openExample(name)
    }
}

private func printCatalogue(): Int64 {
    println("plot gallery — ${allExamples().size} examples")
    println("")
    for (example in allExamples()) {
        println("  ${padded(example.name, 16)}${example.title}")
    }
    println("")
    println("  cjpm run -- <name>            open an example in an interactive window")
    println("  cjpm run -- --export <dir>    render every example to <dir>/<name>.png")
    0
}

private func openExample(name: String): Int64 {
    let example = match (findExample(name)) {
        case Some(value) => value
        case None =>
            eprintln("No example named '${name}'. Run with --list to see them all.")
            return 1
    }
    if (name == "interactive") {
        runInteractive()
        return 0
    }
    let figure = (example.build)()
    let window = PlotWindow(figure, options: WindowOptions(title: "plot — ${example.name}", width: 1080, height: 700))
    // Every gallery window gets the full toolbar, so any example can be saved, zoomed, or panned.
    let _ = window.addStandardToolbar()
    let _ = window.enableHoverReadout()
    let _ = window.addCursorStatus()
    window.show()
    0
}

/**
 * Renders every example to a PNG.
 *
 * This is the gallery's own regression check as much as a feature: it exercises every chart type
 * and the whole export path in one run, and a broken chart shows up as a broken file.
 */
private func exportAll(directory: String): Int64 {
    try {
        if (!exists(Path(directory))) {
            Directory.create(Path(directory), recursive: true)
        }
    } catch (error: Exception) {
        eprintln("Cannot create '${directory}': ${error.message}")
        return 1
    }
    var failures = 0
    for (example in allExamples()) {
        let path = "${directory}/${example.name}.png"
        try {
            FigureExport.renderToPng((example.build)(), path, width: 1100, height: 700)
            println("  ok    ${path}")
        } catch (error: PlotException) {
            eprintln("  FAIL  ${path}: ${error.message}")
            failures += 1
        } catch (error: Exception) {
            eprintln("  FAIL  ${path}: ${error.message}")
            failures += 1
        }
    }
    println("")
    if (failures == 0) {
        println("Rendered ${allExamples().size} examples to ${directory}/")
        0
    } else {
        eprintln("${failures} of ${allExamples().size} examples failed")
        1
    }
}

private func padded(text: String, width: Int64): String {
    var result = text
    while (result.size < width) {
        result += " "
    }
    result
}
