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
}
