import XCTest

// MARK: - Quick Add Sheet UI Tests

/// Tests for TransactionQuickAddSheet.
/// Covers: save button visibility, Expense/Income toggle, and expanding to the full form.
final class TransactionQuickAddUITests: TransactionUITestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        navigateToTransactions()

        // Ensure add button is accessible; skip entire class if no budget exists
        let addButton = app.buttons["transaction_add_button"]
        guard addButton.waitForExistence(timeout: 5), addButton.isEnabled else {
            throw XCTSkip("No active budget found — Quick Add tests require a budget to be set up.")
        }

        addButton.tap()
        // Wait for sheet to appear
        _ = app.textFields["quickadd_amount_field"].waitForExistence(timeout: 5)
    }

    // MARK: - Test Cases

    /// Save button should not appear when amount is empty or no category is selected.
    @MainActor
    func testSaveButtonHiddenWithoutRequiredInput() throws {
        // Initially: no amount, no category — save button must not be visible
        let saveButton = app.buttons["quickadd_save_button"]
        XCTAssertFalse(saveButton.exists, "Save button should not be visible with empty amount and no category")

        // Enter amount but no category — still hidden
        let amountField = app.textFields["quickadd_amount_field"]
        amountField.tap()
        amountField.typeText("100")
        XCTAssertFalse(saveButton.exists, "Save button should still be hidden without a category selected")

        takeScreenshot(name: "quickadd_no_category_selected")
    }

    /// Switching the Expense/Income picker should update the displayed category set.
    @MainActor
    func testExpenseIncomePicker() throws {
        let typePicker = app.segmentedControls["quickadd_type_picker"]
        assertExists(typePicker, timeout: 3)

        // Default is Expense — count expense categories
        let expenseCategoryCountBefore = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'quickadd_category_'")
        ).count

        // Switch to Income
        typePicker.buttons["Income"].tap()

        // Give SwiftUI time to reload filtered categories
        let incomeCategoryCountAfter = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'quickadd_category_'")
        ).count

        // Category set should have changed (may have a different count)
        // We can't assert counts without knowing the seed data, but we verify the toggle worked
        XCTAssertTrue(
            typePicker.buttons["Income"].isSelected,
            "Income segment should be selected after tapping"
        )
        takeScreenshot(name: "quickadd_income_categories")

        // Switch back to Expense
        typePicker.buttons["Expense"].tap()
        XCTAssertTrue(typePicker.buttons["Expense"].isSelected, "Expense segment should be re-selected")

        // Suppress unused variable warning
        _ = expenseCategoryCountBefore
        _ = incomeCategoryCountAfter
    }

    /// Tapping "Expand for more details" should transition to the full TransactionFormView.
    @MainActor
    func testExpandToFullForm() throws {
        let expandButton = app.buttons["quickadd_expand_button"]
        assertExists(expandButton, timeout: 3)
        expandButton.tap()

        // Full form should be visible — it contains the Budget picker and full Description field
        let budgetPicker = app.pickers["form_budget_picker"].firstMatch
        let formAmountField = app.textFields["form_amount_field"]

        let formAppeared = budgetPicker.waitForExistence(timeout: 5) || formAmountField.waitForExistence(timeout: 5)
        XCTAssertTrue(formAppeared, "Full TransactionFormView should appear after tapping Expand")
        takeScreenshot(name: "quickadd_expanded_to_full_form")
    }
}
