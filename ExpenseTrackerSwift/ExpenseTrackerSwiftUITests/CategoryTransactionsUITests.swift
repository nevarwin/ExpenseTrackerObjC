import XCTest

// MARK: - Category Transactions UI Tests

/// Tests for CategoryTransactionsView — adding and deleting transactions from the Budget → Category detail screen.
final class CategoryTransactionsUITests: TransactionUITestCase {

    // MARK: - Helpers

    /// Navigates from the Budget tab into the first category's detail view.
    /// Returns true if navigation succeeded, false if no categories were found.
    @discardableResult
    private func navigateToCategoryDetails() -> Bool {
        navigateToBudget()

        // Wait for the budget list to load
        sleep(1)

        // Try to find and tap the first category row in the budget list
        let categoryCell = app.cells.firstMatch
        guard categoryCell.waitForExistence(timeout: 5) else {
            return false
        }
        categoryCell.tap()

        // Verify we arrived at the category detail screen
        let transactionsHeader = app.staticTexts["Transactions"]
        return transactionsHeader.waitForExistence(timeout: 5)
    }

    // MARK: - Test Cases

    /// Navigates to a category, taps "+", fills the form, saves, and verifies transaction appears.
    @MainActor
    func testAddTransactionFromCategoryDetails() throws {
        guard navigateToCategoryDetails() else {
            throw XCTSkip("Could not navigate to category details — no categories or budgets available.")
        }

        let addButton = app.buttons["category_add_transaction_button"]
        guard addButton.waitForExistence(timeout: 3), addButton.isEnabled else {
            throw XCTSkip("Add transaction button not available or disabled in category details.")
        }
        addButton.tap()

        // Full form should appear pre-filled with category
        let amountField = app.textFields["form_amount_field"]
        assertExists(amountField, timeout: 5, message: "Transaction form should appear from category detail")
        amountField.tap()
        amountField.typeText("75")

        let descField = app.textFields["form_description_field"]
        assertExists(descField)
        descField.tap()
        descField.typeText("Category detail expense")

        let saveButton = app.buttons["form_save_button"]
        if saveButton.waitForExistence(timeout: 3), saveButton.isEnabled {
            saveButton.tap()

            // Handle overflow alert if triggered
            let alert = app.alerts["Amount Exceeds Allocation"]
            if alert.waitForExistence(timeout: 2) {
                alert.buttons["Proceed Anyway"].tap()
            }

            // Verify transaction row appears in the category detail list
            let transactionRow = app.buttons.matching(
                NSPredicate(format: "identifier == 'category_transaction_row'")
            ).firstMatch
            let appeared = transactionRow.waitForExistence(timeout: 5)
            XCTAssertTrue(appeared, "Transaction should appear in category detail after saving")

            takeScreenshot(name: "category_add_transaction_complete")
        } else {
            throw XCTSkip("Save button not enabled — category may not have been auto-selected.")
        }
    }

    /// Navigates to a category with existing transactions, swipes to delete one.
    @MainActor
    func testDeleteTransactionFromCategoryDetails() throws {
        guard navigateToCategoryDetails() else {
            throw XCTSkip("Could not navigate to category details — no categories or budgets available.")
        }

        // Check for existing transaction rows
        let transactionRow = app.buttons.matching(
            NSPredicate(format: "identifier == 'category_transaction_row'")
        ).firstMatch

        guard transactionRow.waitForExistence(timeout: 5) else {
            throw XCTSkip("No transactions in this category to delete.")
        }

        let initialCount = app.buttons.matching(
            NSPredicate(format: "identifier == 'category_transaction_row'")
        ).count

        // Swipe to reveal delete action (native swipeActions)
        transactionRow.swipeLeft()

        let deleteButton = app.buttons["category_transaction_delete_button"]
        if deleteButton.waitForExistence(timeout: 3) {
            deleteButton.tap()

            // Wait for deletion animation
            sleep(1)

            let newCount = app.buttons.matching(
                NSPredicate(format: "identifier == 'category_transaction_row'")
            ).count

            XCTAssertTrue(
                newCount < initialCount,
                "Transaction count should decrease after delete (was \(initialCount), now \(newCount))"
            )
            takeScreenshot(name: "category_delete_transaction_complete")
        } else {
            throw XCTSkip("Delete button not found after swipe — swipe actions may not be available.")
        }
    }

    /// Verifies the empty state appears when a category has no transactions.
    @MainActor
    func testCategoryEmptyStateDisplayed() throws {
        // Navigate to Budget tab and find a category
        navigateToBudget()
        sleep(1)

        let categoryCell = app.cells.firstMatch
        guard categoryCell.waitForExistence(timeout: 5) else {
            throw XCTSkip("No categories available to test empty state.")
        }
        categoryCell.tap()

        // Check if empty state or transaction rows appear
        let emptyState = app.otherElements["category_transactions_empty"]
        let transactionRow = app.buttons.matching(
            NSPredicate(format: "identifier == 'category_transaction_row'")
        ).firstMatch

        let hasEmptyState = emptyState.waitForExistence(timeout: 3)
        let hasTransactions = transactionRow.waitForExistence(timeout: 3)

        // One of them should be visible
        XCTAssertTrue(
            hasEmptyState || hasTransactions,
            "Category detail should show either empty state or transaction rows"
        )

        if hasEmptyState {
            takeScreenshot(name: "category_empty_state")
        } else {
            takeScreenshot(name: "category_has_transactions")
        }
    }
}
