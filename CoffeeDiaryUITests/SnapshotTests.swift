import XCTest

/// App Store screenshots via Fastlane `snapshot`. Skipped in normal CI / Xcode test runs.
final class SnapshotTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool { false }

    override func setUpWithError() throws {
        continueAfterFailure = false
        try XCTSkipUnless(
            Self.isSnapshotRun,
            "Snapshot tests run only under Fastlane snapshot (or SNAPSHOT_FORCE=YES)"
        )
    }

    /// Fastlane normally sets FASTLANE_SNAPSHOT=YES on the test process. Some local setups
    /// drop that env; fall back to SNAPSHOT_FORCE (env or cache marker written by the lane).
    private static var isSnapshotRun: Bool {
        let env = ProcessInfo.processInfo.environment
        if env["FASTLANE_SNAPSHOT"] == "YES" { return true }
        if env["SNAPSHOT_FORCE"] == "YES" { return true }

        let hostHome = env["SIMULATOR_HOST_HOME"] ?? NSHomeDirectory()
        let marker = (hostHome as NSString)
            .appendingPathComponent("Library/Caches/tools.fastlane/SNAPSHOT_FORCE")
        return FileManager.default.fileExists(atPath: marker)
    }

    @MainActor
    func testAppStoreScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments.append("--snapshot")
        app.launchArguments += ["-AppleInterfaceStyle", "Light"]
        app.launch()

        // Slow Intel Macs / cold Simulator boots need generous timeouts.
        let diaryReady = app.navigationBars.firstMatch.waitForExistence(timeout: 90)
        XCTAssertTrue(diaryReady, "Diary should appear after snapshot seed")

        let featuredID = "A1111111-1111-1111-1111-111111111111"
        // Prefer buttons + firstMatch: the row ID can appear on nested AX nodes.
        let brewRow = app.buttons["brewRow_\(featuredID)"].firstMatch
        let station = app.descendants(matching: .any)["stationMachineTile"].firstMatch
        XCTAssertTrue(
            brewRow.waitForExistence(timeout: 40) || station.waitForExistence(timeout: 15),
            "Seeded diary content should be visible"
        )

        snapshot("01Diary")

        if brewRow.exists {
            brewRow.tap()
        } else {
            let cells = app.cells
            if cells.count > 0 {
                cells.element(boundBy: min(1, cells.count - 1)).tap()
            }
        }

        let detailNav = app.navigationBars["Bezug"]
        let detailFallback = app.navigationBars["Brew"]
        XCTAssertTrue(
            detailNav.waitForExistence(timeout: 20) || detailFallback.waitForExistence(timeout: 10),
            "Brew detail should open"
        )
        snapshot("02Detail")

        if app.tabBars.firstMatch.exists == false {
            app.navigationBars.buttons.firstMatch.tap()
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 10)
        }

        tapTab(app, identifier: "tabStats", labels: ["Statistik", "Stats"])
        XCTAssertTrue(
            app.navigationBars["Statistik"].waitForExistence(timeout: 20)
                || app.navigationBars["Stats"].waitForExistence(timeout: 10)
        )
        // Prefer Espresso so KPIs/charts stay on ~1:2 / ~28s (marketing-ready).
        selectSegment(app, labels: ["Espresso"])
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        snapshot("03Stats")

        tapTab(app, identifier: "tabGear", labels: ["Ausrüstung", "Gear", "Equipment"])
        XCTAssertTrue(
            app.navigationBars["Ausrüstung"].waitForExistence(timeout: 20)
                || app.navigationBars["Equipment"].waitForExistence(timeout: 10)
                || app.navigationBars["Gear"].waitForExistence(timeout: 10)
        )
        snapshot("04Gear")
    }

    @MainActor
    private func tapTab(_ app: XCUIApplication, identifier: String, labels: [String]) {
        let byID = app.tabBars.buttons[identifier]
        if byID.waitForExistence(timeout: 5) {
            byID.tap()
            return
        }
        for label in labels {
            let button = app.tabBars.buttons[label]
            if button.waitForExistence(timeout: 2) {
                button.tap()
                return
            }
        }
        XCTFail("Tab not found for \(identifier) / \(labels)")
    }

    @MainActor
    private func selectSegment(_ app: XCUIApplication, labels: [String]) {
        for label in labels {
            let button = app.segmentedControls.buttons[label]
            if button.waitForExistence(timeout: 3), button.isHittable {
                button.tap()
                return
            }
        }
    }
}
