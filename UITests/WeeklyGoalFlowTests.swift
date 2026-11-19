import XCTest

/// Drives the weekly-goal flow end to end on the demo data: add a habit with a
/// goal, check it off, read the detail tiles, then switch it back to daily.
@MainActor
final class WeeklyGoalFlowTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() async throws {
        continueAfterFailure = false
        // `-demoData` wipes the store first, so every run starts from the same state.
        app.launchArguments = ["-demoData"]
        app.launch()
    }

    func testAddingAWeeklyHabitShowsProgressAndTiles() {
        addHabit(named: "Stretch break", goal: "3 days a week")
        XCTAssertTrue(app.staticTexts["0 of 3 this week"].waitForExistence(timeout: 5))

        app.buttons["Stretch break"].tap()
        XCTAssertTrue(app.staticTexts["1 of 3 this week"].waitForExistence(timeout: 5))

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Stretch break'")).element(boundBy: 1).tap()
        XCTAssertTrue(app.staticTexts["This week"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1/3"].exists)
        XCTAssertTrue(app.staticTexts["0 wk"].exists)
        attachScreenshot(named: "habit-detail-weekly")
    }

    func testChangingTheGoalFromTheHabitMenu() {
        addHabit(named: "Evening walk", goal: "2 days a week")
        XCTAssertTrue(app.staticTexts["0 of 2 this week"].waitForExistence(timeout: 5))

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Evening walk'")).element(boundBy: 1).tap()
        app.buttons["More"].tap()
        // The picker's options are listed inline in the menu.
        XCTAssertTrue(app.buttons["Every day"].waitForExistence(timeout: 5))
        app.buttons["Every day"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Back on Today the habit is still listed, now without a weekly caption.
        XCTAssertTrue(app.staticTexts["Evening walk"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["0 of 2 this week"].exists)
    }

    func testDemoDataHasWeeklyGoalCaptions() {
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ENDSWITH 'of 5 this week'")).firstMatch
            .waitForExistence(timeout: 5))
        attachScreenshot(named: "today-weekly-goals")
    }

    // MARK: - Helpers

    private func addHabit(named name: String, goal: String) {
        app.buttons["Add Habit"].firstMatch.tap()
        let field = app.textFields["e.g. Drink 2L water"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name)

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Goal'")).firstMatch.tap()
        app.buttons[goal].tap()
        app.buttons["Add"].tap()
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
