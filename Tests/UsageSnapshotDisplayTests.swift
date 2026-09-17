import AppKit
import XCTest
@testable import Codence

@MainActor
final class UsageSnapshotDisplayTests: XCTestCase {
    func testMenuBarMarkIsTransparentTemplateArtwork() {
        let image = CodenceMenuBarSymbol.image
        XCTAssertTrue(image.isTemplate)

        guard let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data) else {
            return XCTFail("Menu-bar icon could not be rasterized")
        }

        let totalPixels = bitmap.pixelsWide * bitmap.pixelsHigh
        let filledPixels = (0..<bitmap.pixelsHigh).reduce(0) { count, y in
            count + (0..<bitmap.pixelsWide).filter { x in
                (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.5
            }.count
        }
        XCTAssertGreaterThan(filledPixels, totalPixels / 10)
        XCTAssertLessThan(filledPixels, totalPixels / 2)
        XCTAssertEqual(bitmap.colorAt(x: 0, y: 0)?.alphaComponent ?? 0, 0, accuracy: 0.01)
    }

    func testResetCountdownUsesShortAlignedLabels() {
        let now = Date(timeIntervalSince1970: 1_710_000_000)

        XCTAssertEqual(ResetCountdown.label(until: now.addingTimeInterval(5 * 86_400 + 3_600), now: now), "5 days left")
        XCTAssertEqual(ResetCountdown.label(until: now.addingTimeInterval(86_400), now: now), "1 day left")
        XCTAssertEqual(ResetCountdown.label(until: now.addingTimeInterval(4 * 3_600 + 50 * 60), now: now), "4h 50m left")
        XCTAssertEqual(ResetCountdown.label(until: now.addingTimeInterval(45), now: now), "1m left")
        XCTAssertEqual(ResetCountdown.label(until: now, now: now), "Reset due now")
    }

    func testRemainingAllowanceMatchesWebsitePercentages() {
        let snapshot = SnapshotFactory.make(sessionUsagePercent: 11, weeklyUsagePercent: 73)

        XCTAssertEqual(snapshot.sessionRemainingPercent, 89)
        XCTAssertEqual(snapshot.weeklyRemainingPercent, 27)
        XCTAssertEqual(snapshot.sessionUsagePercent, 11)
        XCTAssertEqual(snapshot.weeklyUsagePercent, 73)
    }

    func testAdditionalBucketUsesRemainingAllowance() {
        let bucket = ModelWeeklyLimit(displayName: "Codex Spark", usagePercent: 35, resetsAt: nil)

        XCTAssertEqual(bucket.remainingPercent, 65)
    }

    func testMenuBarModesShowRemainingAllowance() {
        let snapshot = SnapshotFactory.make(sessionUsagePercent: 11, weeklyUsagePercent: 73)
        let weekly = AppState(currentSnapshot: snapshot)
        XCTAssertEqual(weekly.menuBarDisplayText, "W 27% left")

        let session = AppState(
            currentSnapshot: snapshot,
            settings: AppSettings(refreshInterval: 300, menuBarDisplayMode: .sessionPercent)
        )
        XCTAssertEqual(session.menuBarDisplayText, "S 89% left")

        let both = AppState(
            currentSnapshot: snapshot,
            settings: AppSettings(refreshInterval: 300, menuBarDisplayMode: .compactBoth)
        )
        XCTAssertEqual(both.menuBarDisplayText, "S89% W27% left")
    }
}
