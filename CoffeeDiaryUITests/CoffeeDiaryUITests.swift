//
//  CoffeeDiaryUITests.swift
//  CoffeeDiaryUITests
//
//  Created by Yannik Chlechowitz on 16.11.25.
//

import XCTest

final class CoffeeDiaryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesToMainOrOnboarding() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        // Smoke test that runs in CI: app should show a navigation bar or onboarding content.
        let navigationBar = app.navigationBars.firstMatch
        let launched = navigationBar.waitForExistence(timeout: 45)
        XCTAssertTrue(launched, "App should present a navigation bar after launch")
    }

    @MainActor
    func testNewEntryControlsVisible() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        let navigationBar = app.navigationBars.firstMatch
        guard navigationBar.waitForExistence(timeout: 45) else {
            XCTFail("App did not launch in time")
            return
        }

        let toolbarButton = app.buttons["toolbarNewEntryButton"]
        let emptyStateButton = app.buttons["emptyStateAddButton"]

        let hasToolbarButton = toolbarButton.waitForExistence(timeout: 10)
        let hasEmptyStateButton = emptyStateButton.waitForExistence(timeout: 5)

        XCTAssertTrue(
            hasToolbarButton || hasEmptyStateButton,
            "At least one new-entry control should exist (toolbar: \(hasToolbarButton), empty state: \(hasEmptyStateButton))"
        )
    }

    @MainActor
    func testEspressoFlowSkipsCoffeeNameAndAvoidsSliders() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launchArguments.append("-AppleLanguages")
        app.launchArguments.append("(en)")
        app.launch()

        let emptyStateButton = app.buttons["emptyStateAddButton"]
        let toolbarButton = app.buttons["toolbarNewEntryButton"]
        if emptyStateButton.waitForExistence(timeout: 10) {
            emptyStateButton.tap()
        } else {
            XCTAssertTrue(toolbarButton.waitForExistence(timeout: 10))
            toolbarButton.tap()
        }

        let espresso = app.buttons["flowOptionEspresso"]
        XCTAssertTrue(espresso.waitForExistence(timeout: 8), "Espresso option should appear")
        espresso.tap()

        XCTAssertTrue(app.segmentedControls.firstMatch.waitForExistence(timeout: 8), "Shot picker should be the first step")
        XCTAssertFalse(app.textFields["Coffee name"].exists)
        XCTAssertEqual(app.sliders.count, 0)

        let next = app.buttons["flowNextButton"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        next.tap()

        var foundNumericField = false
        for _ in 0..<8 {
            XCTAssertEqual(app.sliders.count, 0, "Flow should not use sliders for brew metrics")
            if app.textFields.count > 0 {
                foundNumericField = true
                break
            }
            guard next.exists, next.isEnabled else { break }
            next.tap()
        }
        XCTAssertTrue(foundNumericField, "Dose or timer step should expose a numeric text field")
    }
}
