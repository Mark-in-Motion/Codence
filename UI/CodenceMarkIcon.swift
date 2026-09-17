import AppKit
import SwiftUI

/// Shared app mark. The menu-bar variant is transparent monochrome artwork;
/// the full-color bundled icon is only used outside the menu bar.
struct CodenceMarkIcon: View {
    enum Style {
        case menuBar
        case about
    }

    let style: Style

    var body: some View {
        Image(nsImage: style.image)
            .interpolation(.high)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .accessibilityHidden(true)
    }
}

private extension CodenceMarkIcon.Style {
    var image: NSImage {
        switch self {
        case .menuBar:
            return CodenceMenuBarSymbol.image
        case .about:
            return CodenceIconLoader.aboutIcon ?? CodenceMarkFallbackRenderer.aboutImage
        }
    }
}

private enum CodenceIconLoader {
    static let aboutIcon = loadImage(named: "codence-about")

    private static func loadImage(named baseName: String) -> NSImage? {
        let fileNames = [
            "\(baseName).pdf",
            "\(baseName).png"
        ]

        for fileName in fileNames {
            if let url = resourceURL(for: fileName),
               let image = NSImage(contentsOf: url) {
                return image
            }
        }

        return nil
    }

    private static func resourceURL(for fileName: String) -> URL? {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif

        if let directURL = bundle.resourceURL?.appendingPathComponent("Icons/\(fileName)"),
           FileManager.default.fileExists(atPath: directURL.path) {
            return directURL
        }

        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        return bundle.url(forResource: name, withExtension: ext, subdirectory: "Icons")
    }
}

/// The source artwork contains an opaque square, which becomes a solid block
/// when macOS tints it as a template. Draw only the C/chevron mark instead.
enum CodenceMenuBarSymbol {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 20, height: 20), flipped: false) { _ in
            NSColor.black.setStroke()

            let letter = NSBezierPath()
            letter.lineWidth = 2.2
            letter.lineCapStyle = .round
            letter.appendArc(
                withCenter: NSPoint(x: 9.2, y: 10),
                radius: 5.8,
                startAngle: 52,
                endAngle: 308,
                clockwise: false
            )
            letter.stroke()

            let chevron = NSBezierPath()
            chevron.lineWidth = 2.2
            chevron.lineCapStyle = .round
            chevron.lineJoinStyle = .round
            chevron.move(to: NSPoint(x: 13.6, y: 6.6))
            chevron.line(to: NSPoint(x: 16.4, y: 10))
            chevron.line(to: NSPoint(x: 13.6, y: 13.4))
            chevron.stroke()

            NSColor.black.setFill()
            NSBezierPath(ovalIn: NSRect(x: 8.3, y: 9.1, width: 1.8, height: 1.8)).fill()
            return true
        }
        image.isTemplate = true
        return image
    }()
}

private enum CodenceMarkFallbackRenderer {
    static let aboutImage = render(size: NSSize(width: 160, height: 128), interpolation: .none)

    private static let columns = 10
    private static let rows = 8

    private static let pixels: [NSColor?] = """
        ..llllll..
        .lbbbbbbd.
        eebbkbbkee
        eebbbbbbee
        ..bbbbbb..
        ..b.b.b.b.
        ..b.b.b.b.
        ..........
        """
        .filter { $0 != "\n" }
        .map { pixelColor(for: $0) }

    private static func render(size: NSSize, interpolation: NSImageInterpolation) -> NSImage {
        let source = NSImage(size: NSSize(width: columns, height: rows))
        source.lockFocus()

        for row in 0..<rows {
            for column in 0..<columns {
                guard let color = pixels[(row * columns) + column] else {
                    continue
                }

                color.setFill()
                NSRect(x: column, y: rows - row - 1, width: 1, height: 1).fill()
            }
        }

        source.unlockFocus()

        let target = NSImage(size: size)
        target.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = interpolation
        source.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(x: 0, y: 0, width: columns, height: rows),
            operation: .sourceOver,
            fraction: 1
        )
        target.unlockFocus()
        return target
    }

    private static func pixelColor(for character: Character) -> NSColor? {
        switch character {
        case ".":
            return nil
        case "l":
            return NSColor(calibratedRed: 0.95, green: 0.80, blue: 0.74, alpha: 1)
        case "b":
            return NSColor(calibratedRed: 0.84, green: 0.47, blue: 0.33, alpha: 1)
        case "d":
            return NSColor(calibratedRed: 0.73, green: 0.38, blue: 0.27, alpha: 1)
        case "e":
            return NSColor(calibratedRed: 0.89, green: 0.62, blue: 0.55, alpha: 1)
        case "k":
            return NSColor(calibratedRed: 0.10, green: 0.08, blue: 0.07, alpha: 1)
        default:
            return nil
        }
    }
}
