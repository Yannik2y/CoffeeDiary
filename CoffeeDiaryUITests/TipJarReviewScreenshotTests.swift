import XCTest

/// Captures a Tip Jar screenshot for App Store Connect IAP review metadata.
final class TipJarReviewScreenshotTests: XCTestCase {
    @MainActor
    func testCaptureTipJarReviewScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "--ui-testing",
            "-OpenTipJar",
            "-AppleInterfaceStyle", "Light"
        ]
        app.launch()

        let tipTitle = app.navigationBars["Support Coffee Diary"]
            .firstMatch
        let tipTitleDE = app.navigationBars["Coffee Diary unterstützen"].firstMatch
        XCTAssertTrue(
            tipTitle.waitForExistence(timeout: 30) || tipTitleDE.waitForExistence(timeout: 5),
            "Tip Jar should open via -OpenTipJar"
        )

        // Wait for StoreKit products (local .storekit via xcodebuild -storekitConfigurationPath).
        let espresso = app.staticTexts["Espresso"].firstMatch
        let linea = app.staticTexts["Linea Mini"].firstMatch
        XCTAssertTrue(
            espresso.waitForExistence(timeout: 45) || linea.waitForExistence(timeout: 5),
            "Tip products should load from StoreKit configuration"
        )

        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        let shot = XCUIScreen.main.screenshot()
        let url = URL(fileURLWithPath: "/tmp/tipjar_review.png")
        try shot.pngRepresentation.write(to: url)
        NSLog("Wrote Tip Jar review screenshot to \(url.path)")
    }
}
