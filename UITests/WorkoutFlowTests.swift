import XCTest

/// Starts a workout, pauses and resumes it, then finishes it and checks that it
/// lands in the history.
@MainActor
final class WorkoutFlowTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        app.launchArguments = ["-demoData"]
        app.launch()
        app.tabBars.buttons["Workouts"].tap()
    }

    func testStartPauseResumeAndFinishAWorkout() {
        XCTAssertTrue(app.staticTexts["Finished sessions will appear here."].exists || app.staticTexts["History"].exists)

        app.buttons["Start Run"].tap()
        XCTAssertTrue(app.staticTexts["In progress"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Elapsed time"].exists || app.otherElements["Elapsed time"].exists)

        app.buttons["Pause"].tap()
        XCTAssertTrue(app.staticTexts["Paused"].waitForExistence(timeout: 5))
        attachScreenshot(named: "workout-paused")

        app.buttons["Resume"].tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))

        app.buttons["Finish"].tap()
        // The start grid comes back and the run is now listed in the history.
        XCTAssertTrue(app.buttons["Start Run"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Finish"].exists)
        XCTAssertTrue(app.staticTexts["Run"].waitForExistence(timeout: 5))
        attachScreenshot(named: "workout-finished")
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
