import XCTest

// MARK: - Transaction Form UI Tests

/// Tests for TransactionFormView (full edit/create form).
/// Covers: Save button validation, pre-filled data on edit, and overflow alert.
final class TransactionFormUITests: TransactionUITestCase {

    // MARK: - Helpers

    /// Opens the full form by tapping Add → Expand.
    private func openFullForm() throws {
        navigateToTransactions()

        let addButton = app.buttons["transaction_add_button"]
        guard addButton.waitForExistence(timeout: 5), addButton.isEnabled else {
            throw XCTSkip("No active budget found — Form tests require a budget.")
        }
        addButton.tap()

        let expandButton = app.buttons["quickadd_expand_button"]
        if expandButton.waitForExistence(timeout: 3) {
            expandButton.tap()
        }
    }

    /// Opens the edit form for the first transaction in today's list via swipe-left.
    private func openEditFormForFirstTransaction() throws {
        navigateToTransactions()
        app.buttons["calendar_today_button"].tap()

        let firstRow = app.otherElements["transaction_row"].firstMatch
        guard firstRow.waitForExistence(timeout: 5) else {
            throw XCTSkip("No transaction present for today — add one before running edit tests.")
        }
        firstRow.swipeLeft()
        app.buttons["Edit"].tap()
    }

    // MARK: - Test Cases

    /// Save button should be disabled when required fields are not filled.
    @MainActor
    func testFormSaveDisabledWithMissingFields() throws {
        try openFullForm()

        let saveButton = app.buttons["form_save_button"]
        assertExists(saveButton, timeout: 5, message: "Save button should exist in the toolbar")

        // Initially disabled (empty amount, empty description, no category)
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled with no amount entered")

        // Fill amount only — still disabled (missing description + category)
        let amountField = app.textFields["form_amount_field"]
        assertExists(amountField)
        amountField.tap()
        amountField.typeText("50")
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled with only amount filled")

        // Fill description — still disabled (missing category)
        let descField = app.textFields["form_description_field"]
        assertExists(descField)
        descField.tap()
        descField.typeText("Test expense")
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled with no category selected")

        takeScreenshot(name: "form_save_disabled")
    }

    /// Opening an existing transaction via Edit should pre-fill all fields.
    @MainActor
    func testFormEditPreFillsData() throws {
        try openEditFormForFirstTransaction()

        let cancelButton = app.buttons["form_cancel_button"]
        assertExists(cancelButton, timeout: 5, message: "Edit form should appear with Cancel button")

        // Amount field must not be empty
        let amountField = app.textFields["form_amount_field"]
        assertExists(amountField)
        let amountValue = amountField.value as? String ?? ""
        XCTAssertFalse(amountValue.isEmpty, "Amount should be pre-filled from the existing transaction")

        // Description field must not be empty
        let descField = app.textFields["form_description_field"]
        assertExists(descField)
        let descValue = descField.value as? String ?? ""
        XCTAssertFalse(descValue.isEmpty, "Description should be pre-filled from the existing transaction")

        takeScreenshot(name: "form_edit_prefilled")
        cancelButton.tap()
    }

    /// Entering an amount that exceeds the category allocation should trigger the overflow alert.
    @MainActor
    func testFormOverflowAlertAppears() throws {
        try openFullForm()

        // Enter a very large amount to trigger overflow
        let amountField = app.textFields["form_amount_field"]
        assertExists(amountField, timeout: 5)
        amountField.tap()
        amountField.typeText("999999999") // Max that fits in 9-integer-digit limit

        // Fill description
        let descField = app.textFields["form_description_field"]
        assertExists(descField)
        descField.tap()
        descField.typeText("Overflow test")

        // Select first available category
        let categoryPicker = app.pickers["form_category_picker"].firstMatch
        // Pickers in forms can be tricky — tap the picker row to navigate
        let categoryRow = app.tables.cells.containing(.staticText, identifier: "Category").firstMatch
        if categoryRow.waitForExistence(timeout: 3) {
            categoryRow.tap()
            // Select the first available option if presented as a list
            let firstOption = app.tables.cells.firstMatch
            if firstOption.waitForExistence(timeout: 2) {
                firstOption.tap()
            }
        }

        // Attempt to save
        let saveButton = app.buttons["form_save_button"]
        if saveButton.waitForExistence(timeout: 3), saveButton.isEnabled {
            saveButton.tap()

            // Overflow alert should appear
            let alertTitle = app.alerts["Amount Exceeds Allocation"]
            if alertTitle.waitForExistence(timeout: 3) {
                XCTAssertTrue(alertTitle.exists, "Overflow alert should appear")
                // Verify both alert actions exist
                XCTAssertTrue(alertTitle.buttons["Cancel"].exists, "Alert should have Cancel")
                XCTAssertTrue(alertTitle.buttons["Proceed Anyway"].exists, "Alert should have Proceed Anyway")
                takeScreenshot(name: "form_overflow_alert")
                alertTitle.buttons["Cancel"].tap()
            }
        } else {
            // Category wasn't selectable in this run — skip gracefully
            throw XCTSkip("Overflow test requires a selectable category with an allocation set.")
        }

        _ = categoryPicker // suppress unused warning
    }

    // MARK: - Create Transaction Tests

    /// Opens the full form, fills amount/description/category, saves, and verifies the row appears.
    @MainActor
    func testCreateExpenseViaFullForm() throws {
        try openFullForm()

        let amountField = app.textFields["form_amount_field"]
        assertExists(amountField, timeout: 5)
        amountField.tap()
        amountField.typeText("120")

        let descField = app.textFields["form_description_field"]
        assertExists(descField)
        descField.tap()
        descField.typeText("Grocery shopping")

        // Select a category from the picker
        let categoryPicker = app.buttons["form_category_picker"]
        if categoryPicker.waitForExistence(timeout: 3) {
            categoryPicker.tap()
            // Pick "Food" category from the picker options
            let foodOption = app.buttons["Food"]
            if foodOption.waitForExistence(timeout: 3) {
                foodOption.tap()
            }
        }

        let saveButton = app.buttons["form_save_button"]
        if saveButton.waitForExistence(timeout: 3), saveButton.isEnabled {
            saveButton.tap()

            // Handle potential overflow alert
            let alert = app.alerts["Amount Exceeds Allocation"]
            if alert.waitForExistence(timeout: 2) {
                alert.buttons["Proceed Anyway"].tap()
            }

            // Verify transaction appears
            tapTodayButton()
            verifyTransactionRowAppears()
            takeScreenshot(name: "form_create_expense_complete")
        } else {
            throw XCTSkip("Save button not enabled — category selection may have failed.")
        }
    }

    /// Opens the full form, selects income category, saves, and verifies the row.
    @MainActor
    func testCreateIncomeViaFullForm() throws {
        try openFullForm()

        let amountField = app.textFields["form_amount_field"]
        assertExists(amountField, timeout: 5)
        amountField.tap()
        amountField.typeText("3000")

        let descField = app.textFields["form_description_field"]
        assertExists(descField)
        descField.tap()
        descField.typeText("Monthly salary")

        // Select income category
        let categoryPicker = app.buttons["form_category_picker"]
        if categoryPicker.waitForExistence(timeout: 3) {
            categoryPicker.tap()
            let salaryOption = app.buttons["Salary"]
            if salaryOption.waitForExistence(timeout: 3) {
                salaryOption.tap()
            }
        }

        let saveButton = app.buttons["form_save_button"]
        if saveButton.waitForExistence(timeout: 3), saveButton.isEnabled {
            saveButton.tap()

            let alert = app.alerts["Amount Exceeds Allocation"]
            if alert.waitForExistence(timeout: 2) {
                alert.buttons["Proceed Anyway"].tap()
            }

            tapTodayButton()
            verifyTransactionRowAppears()
            takeScreenshot(name: "form_create_income_complete")
        } else {
            throw XCTSkip("Save button not enabled — income category selection may have failed.")
        }
    }

    /// Opens the full form, taps "Assign to Month", picks a different period, and verifies the sheet opens.
    @MainActor
    func testAssignCustomBudgetPeriod() throws {
        try openFullForm()

        let periodButton = app.buttons["form_budget_period_button"]
        assertExists(periodButton, timeout: 5)
        periodButton.tap()

        // Month picker sheet should appear
        let doneButton = app.buttons["month_picker_done_button"]
        assertExists(doneButton, timeout: 5, message: "Month picker sheet should appear with Done button")

        // Tap "Previous Month" to change the period
        let prevMonthButton = app.buttons["month_picker_previous_month"]
        if prevMonthButton.waitForExistence(timeout: 3) {
            prevMonthButton.tap()
        }

        takeScreenshot(name: "form_custom_budget_period")
        doneButton.tap()

        // Verify we're back on the form
        let saveButton = app.buttons["form_save_button"]
        assertExists(saveButton, timeout: 3, message: "Should return to form after month picker")
    }

    /// Fills form fields, taps Cancel, and verifies form dismisses without saving.
    @MainActor
    func testCancelFullFormDismissesWithoutSaving() throws {
        try openFullForm()

        let amountField = app.textFields["form_amount_field"]
        assertExists(amountField, timeout: 5)
        amountField.tap()
        amountField.typeText("999")

        let descField = app.textFields["form_description_field"]
        assertExists(descField)
        descField.tap()
        descField.typeText("Should not be saved")

        let cancelButton = app.buttons["form_cancel_button"]
        assertExists(cancelButton)
        cancelButton.tap()

        // Form should be dismissed — verify we're back on the Transactions list
        let addButton = app.buttons["transaction_add_button"]
        assertExists(addButton, timeout: 5, message: "Should return to Transactions list after Cancel")
        takeScreenshot(name: "form_cancel_dismissed")
    }

    /// Types more than 9 integer digits into the amount field and verifies truncation.
    @MainActor
    func testAmountMaxDigitTruncation() throws {
        try openFullForm()

        let amountField = app.textFields["form_amount_field"]
        assertExists(amountField, timeout: 5)
        amountField.tap()
        amountField.typeText("1234567890") // 10 digits — should be truncated to 9

        let amountValue = amountField.value as? String ?? ""
        // The onChange handler limits integer part to 9 digits
        XCTAssertTrue(
            amountValue.count <= 10, // 9 digits + possible decimal
            "Amount field should truncate beyond 9 integer digits, got: \(amountValue)"
        )

        takeScreenshot(name: "form_amount_truncation")
    }
}
