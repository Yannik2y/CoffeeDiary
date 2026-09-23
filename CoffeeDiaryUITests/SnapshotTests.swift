import XCTest

/// App Store screenshots via Fastlane `snapshot`. Skipped in normal CI runs.
final class SnapshotTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool { false }

    override func setUpWithError() throws {
        continueAfterFailure = false

        let env = ProcessInfo.processInfo.environment["FASTLANE_SNAPSHOT"]
        let args = ProcessInfo.processInfo.arguments
        let isSnapshotRun = env == "YES" || args.contains("FASTLANE_SNAPSHOT")
        try XCTSkipUnless(isSnapshotRun, "Snapshot tests run only under Fastlane snapshot")
    }

    @MainActor
    func testAppStoreScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments.append("--snapshot")
        app.launchArguments += ["-AppleInterfaceStyle", "Light"]
        app.launch()

        let diaryReady = app.navigationBars.firstMatch.waitForExistence(timeout: 45)
        XCTAssertTrue(diaryReady, "Diary should appear after snapshot seed")

        // Wait for seeded list content (Coffee Station or a brew row).
        let featuredID = "A1111111-1111-1111-1111-111111111111"
        let brewRow = app.descendants(matching: .any)["brewRow_\(featuredID)"]
        let station = app.descendants(matching: .any)["stationMachineTile"]
        XCTAssertTrue(
            brewRow.waitForExistence(timeout: 20) || station.waitForExistence(timeout: 5),
            "Seeded diary content should be visible"
        )

        snapshot("01Diary")

        if brewRow.exists {
            brewRow.tap()
        } else {
            // Fallback: first brew-looking cell in the list
            let cells = app.cells
            if cells.count > 0 {
                cells.element(boundBy: min(1, cells.count - 1)).tap()
            }
        }

        let detailNav = app.navigationBars["Bezug"]
        let detailFallback = app.navigationBars["Brew"]
        XCTAssertTrue(
            detailNav.waitForExistence(timeout: 10) || detailFallback.waitForExistence(timeout: 5),
            "Brew detail should open"
        )
        snapshot("02Detail")

        // Back to tab root on compact; on iPad split view tabs stay visible.
        if app.tabBars.firstMatch.exists == false {
            app.navigationBars.buttons.firstMatch.tap()
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)
        }

        tapTab(app, identifier: "tabStats", labels: ["Statistik", "Stats"])
        XCTAssertTrue(app.navigationBars["Statistik"].waitForExistence(timeout: 10)
            || app.navigationBars["Stats"].waitForExistence(timeout: 5))
        // Allow charts to lay out
        RunLoop.current.run(until: Date().addingTimeInterval(1.2))
        snapshot("03Stats")

        tapTab(app, identifier: "tabGear", labels: ["Ausrüstung", "Gear", "Equipment"])
        XCTAssertTrue(
            app.navigationBars["Ausrüstung"].waitForExistence(timeout: 10)
                || app.navigationBars["Equipment"].waitForExistence(timeout: 5)
                || app.navigationBars["Gear"].waitForExistence(timeout: 5)
        )
        snapshot("04Gear")
    }

    @MainActor
    private func tapTab(_ app: XCUIApplication, identifier: String, labels: [String]) {
        let byID = app.tabBars.buttons[identifier]
        if byID.waitForExistence(timeout: 2) {
            byID.tap()
            return
        }
        for label in labels {
            let button = app.tabBars.buttons[label]
            if button.exists {
                button.tap()
                return
            }
        }
        XCTFail("Tab not found for \(identifier) / \(labels)")
    }
}
