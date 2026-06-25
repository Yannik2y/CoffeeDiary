//
//  CoffeeDiaryUITestsLaunchTests.swift
//  CoffeeDiaryUITests
//
//  Created by Yannik Chlechowitz on 16.11.25.
//

import XCTest

final class CoffeeDiaryUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool { false }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
