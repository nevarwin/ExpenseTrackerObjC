import XCTest

// MARK: - Transaction Calendar UI Tests

/// Tests for TransactionCalendarView — calendar navigation, scope toggle, range mode, and month picker.
final class TransactionCalendarUITests: TransactionUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        navigateToTransactions()
    }

    // MARK: - Scope Toggle Tests

    /// Toggles the scope segmented control between Week and Month, verifying the picker updates.
    @MainActor
    func testCalendarScopeToggleWeekAndMonth() throws {
        let scopePicker = app.segmentedControls["calendar_scope_picker"]
        assertExists(scopePicker, timeout: 5)

        // Default should be Month
        XCTAssertTrue(
            scopePicker.buttons["Month"].isSelected,
            "Calendar should default to Month scope"
        )

        // Switch to Week
        scopePicker.buttons["Week"].tap()
        XCTAssertTrue(
            scopePicker.buttons["Week"].isSelected,
            "Week scope should be selected after tapping"
        )
        takeScreenshot(name: "calendar_scope_week")

        // Switch back to Month
        scopePicker.buttons["Month"].tap()
        XCTAssertTrue(
            scopePicker.buttons["Month"].isSelected,
            "Month scope should be re-selected after tapping"
        )
        takeScreenshot(name: "calendar_scope_month")
    }

    // MARK: - Range Mode Tests

    /// Enables Range mode via the toggle switch and verifies it's active.
    @MainActor
    func testCalendarRangeModeToggle() throws {
        let rangeToggle = app.switches["calendar_range_toggle"]
        assertExists(rangeToggle, timeout: 5)

        // Verify initial state is off
        let initialValue = rangeToggle.value as? String
        XCTAssertEqual(initialValue, "0", "Range toggle should be off by default")

        // Enable range mode
        rangeToggle.tap()

        let enabledValue = rangeToggle.value as? String
        XCTAssertEqual(enabledValue, "1", "Range toggle should be on after tapping")
        takeScreenshot(name: "calendar_range_enabled")

        // Disable range mode
        rangeToggle.tap()
        let disabledValue = rangeToggle.value as? String
        XCTAssertEqual(disabledValue, "0", "Range toggle should be off after second tap")
        takeScreenshot(name: "calendar_range_disabled")
    }

    // MARK: - Month/Year Picker Tests

    /// Opens the month/year picker sheet, selects a different month, taps Done, and verifies the title updates.
    @MainActor
    func testMonthYearPickerSheet() throws {
        let monthYearButton = app.buttons["calendar_month_year_button"]
        assertExists(monthYearButton, timeout: 5)
        let initialLabel = monthYearButton.label

        // Tap to open the month/year picker sheet
        monthYearButton.tap()

        // Verify the sheet appeared with the "Select Month & Year" title
        let sheetTitle = app.staticTexts["Select Month & Year"]
        assertExists(sheetTitle, timeout: 5, message: "Month/Year picker sheet should appear")

        // Find and interact with the Month picker wheel
        let monthPicker = app.pickerWheels.element(boundBy: 0)
        if monthPicker.waitForExistence(timeout: 3) {
            monthPicker.adjust(toPickerWheelValue: "January")
        }

        takeScreenshot(name: "calendar_month_picker_sheet")

        // Tap Done to apply
        let doneButton = app.buttons["Done"]
        assertExists(doneButton, timeout: 3)
        doneButton.tap()

        // Verify the month label has changed
        let updatedLabel = monthYearButton.label
        XCTAssertNotEqual(initialLabel, updatedLabel, "Month/year label should update after picking a new month")
        takeScreenshot(name: "calendar_month_picker_applied")
    }

    // MARK: - Today Button Test

    /// Navigates to a future month, then taps "Today" and verifies the date resets.
    @MainActor
    func testTodayButtonResetsSelection() throws {
        let monthYearButton = app.buttons["calendar_month_year_button"]
        assertExists(monthYearButton, timeout: 5)
        let initialLabel = monthYearButton.label

        // Navigate forward twice
        let nextButton = app.buttons["calendar_next_button"]
        assertExists(nextButton)
        nextButton.tap()
        nextButton.tap()

        // Verify we moved away from the initial month
        let movedLabel = monthYearButton.label
        XCTAssertNotEqual(initialLabel, movedLabel, "Should have navigated away from initial month")

        // Tap Today button
        let todayButton = app.buttons["calendar_today_button"]
        assertExists(todayButton)
        todayButton.tap()

        // Verify we returned to the current month
        let restoredLabel = monthYearButton.label
        XCTAssertEqual(
            initialLabel, restoredLabel,
            "Tapping Today should reset calendar to the current month"
        )
        takeScreenshot(name: "calendar_today_reset")
    }

    // MARK: - Navigation Gesture Test

    /// Verifies previous/next navigation buttons cycle through months correctly.
    @MainActor
    func testCalendarPrevNextNavigation() throws {
        let monthYearButton = app.buttons["calendar_month_year_button"]
        assertExists(monthYearButton, timeout: 5)
        let initialLabel = monthYearButton.label

        // Navigate back
        let prevButton = app.buttons["calendar_prev_button"]
        assertExists(prevButton)
        prevButton.tap()

        let prevLabel = monthYearButton.label
        XCTAssertNotEqual(initialLabel, prevLabel, "Label should change after tapping prev")
        takeScreenshot(name: "calendar_prev_navigated")

        // Navigate forward twice to go 1 month ahead of start
        let nextButton = app.buttons["calendar_next_button"]
        assertExists(nextButton)
        nextButton.tap()
        nextButton.tap()

        let nextLabel = monthYearButton.label
        XCTAssertNotEqual(initialLabel, nextLabel, "Label should change after navigating forward past initial")
        takeScreenshot(name: "calendar_next_navigated")
    }
}
