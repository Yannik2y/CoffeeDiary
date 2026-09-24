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

        // iPhone: push detail hides the tab bar — pop first.
        // iPad: NavigationSplitView keeps tabs; still try a soft dismiss if needed.
        ensureTabsReachable(app)

        tapTab(app, identifier: "tabStats", labels: ["Statistik", "Stats"])
        XCTAssertTrue(
            app.navigationBars["Statistik"].waitForExistence(timeout: 20)
                || app.navigationBars["Stats"].waitForExistence(timeout: 10),
            "Stats tab should open"
        )
        // Prefer Espresso so KPIs/charts stay on ~1:2 / ~28s (marketing-ready).
        selectSegment(app, labels: ["Espresso"])
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        snapshot("03Stats")

        tapTab(app, identifier: "tabGear", labels: ["Ausrüstung", "Gear", "Equipment"])
        XCTAssertTrue(
            app.navigationBars["Ausrüstung"].waitForExistence(timeout: 20)
                || app.navigationBars["Equipment"].waitForExistence(timeout: 10)
                || app.navigationBars["Gear"].waitForExistence(timeout: 10),
            "Gear tab should open"
        )
        snapshot("04Gear")
    }

    @MainActor
    private func ensureTabsReachable(_ app: XCUIApplication) {
        if tabControl(app, identifier: "tabStats", labels: ["Statistik", "Stats"]).waitForExistence(timeout: 2) {
            return
        }

        // Pop pushed detail (iPhone) or try common dismiss controls.
        let back = app.navigationBars.buttons.firstMatch
        if back.exists, back.isHittable {
            back.tap()
        }
        if tabControl(app, identifier: "tabStats", labels: ["Statistik", "Stats"]).waitForExistence(timeout: 3) {
            return
        }

        // Last resort: activate Diary tab via coordinate-less label search anywhere.
        let diary = tabControl(app, identifier: "tabDiary", labels: ["Tagebuch", "Diary"])
        if diary.exists {
            diary.tap()
        }
        _ = tabControl(app, identifier: "tabStats", labels: ["Statistik", "Stats"]).waitForExistence(timeout: 5)
    }

    @MainActor
    private func tapTab(_ app: XCUIApplication, identifier: String, labels: [String]) {
        let control = tabControl(app, identifier: identifier, labels: labels)
        XCTAssertTrue(control.waitForExistence(timeout: 8), "Tab not found for \(identifier) / \(labels)")
        control.tap()
    }

    /// iPad TabView / split layouts don't always expose tabs as `tabBars.buttons`.
    @MainActor
    private func tabControl(
        _ app: XCUIApplication,
        identifier: String,
        labels: [String]
    ) -> XCUIElement {
        let byIDInTabs = app.tabBars.buttons[identifier]
        if byIDInTabs.exists { return byIDInTabs }

        let byIDAnywhere = app.buttons[identifier]
        if byIDAnywhere.exists { return byIDAnywhere.firstMatch }

        let byIDDescendant = app.descendants(matching: .any)[identifier]
        if byIDDescendant.exists { return byIDDescendant.firstMatch }

        for label in labels {
            let inTabs = app.tabBars.buttons[label]
            if inTabs.exists { return inTabs }
            let asButton = app.buttons[label]
            if asButton.exists { return asButton.firstMatch }
        }

        return app.tabBars.buttons[identifier]
    }

    @MainActor
    private func selectSegment(_ app: XCUIApplication, labels: [String]) {
        for label in labels {
            let button = app.segmentedControls.buttons[label]
            if button.waitForExistence(timeout: 3), button.isHittable {
                button.tap()
                return
            }
            // iPad may surface the segment outside a segmented control query.
            let loose = app.buttons[label].firstMatch
            if loose.exists, loose.isHittable {
                loose.tap()
                return
            }
        }
    }
}
