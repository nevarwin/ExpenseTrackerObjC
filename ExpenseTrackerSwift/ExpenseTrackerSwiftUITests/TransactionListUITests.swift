import XCTest

// MARK: - Transaction List UI Tests

/// Tests for TransactionListView — the main Transactions screen.
/// Covers: empty states, adding, deleting, editing, searching, and calendar navigation.
final class TransactionListUITests: TransactionUITestCase {

    // MARK: - Empty State Tests

    /// Verifies the initial "Select a Date" prompt is visible before any date is tapped.
    @MainActor
    func testTransactionListShowsSelectDateInitially() throws {
        navigateToTransactions()

        assertExists(
            app.otherElements["transaction_empty_select_date"].firstMatch,
            timeout: 3,
            message: "Expected 'Select a Date' empty state on first load"
        )
        takeScreenshot(name: "initial_select_date_state")
    }

    /// Verifies that tapping a calendar date shows either the list or an empty-results state.
    @MainActor
    func testTapDateShowsTransactionsOrEmptyState() throws {
        navigateToTransactions()

        // Tap any visible day cell (today)
        let todayButton = app.buttons["calendar_today_button"]
        assertExists(todayButton)
        todayButton.tap()

        // After tapping today, either transactions or "No Transactions" should appear
        let list = app.scrollViews["transaction_list"]
        let emptyNoResults = app.staticTexts["No Transactions"]

        let appeared = list.waitForExistence(timeout: 5) || emptyNoResults.waitForExistence(timeout: 5)
        XCTAssertTrue(appeared, "Expected transaction list or empty state after selecting a date")
        takeScreenshot(name: "after_tap_date")
    }

    // MARK: - Add Transaction Test

    /// Verifies the full quick-add flow: open sheet → fill → save → row appears in list.
    /// Note: Requires an active budget + category to be set up. Adjust categoryName to match your seed data.
    @MainActor
    func testAddTransactionViaQuickAdd() throws {
        navigateToTransactions()

        // Tap today so the list is visible after adding
        let todayButton = app.buttons["calendar_today_button"]
        assertExists(todayButton)
        todayButton.tap()

        // Verify add button is enabled (requires active budget)
        let addButton = app.buttons["transaction_add_button"]
        assertExists(addButton)
        guard addButton.isEnabled else {
            throw XCTSkip("Skipping: no active budget found. Set up a budget before running this test.")
        }

        addButton.tap()

        // Fill quick-add form
        let amountField = app.textFields["quickadd_amount_field"]
        assertExists(amountField, timeout: 3)
        amountField.tap()
        amountField.typeText("25")

        // Tap first available category button
        let firstCategory = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'quickadd_category_'")).firstMatch
        if firstCategory.waitForExistence(timeout: 3) {
            firstCategory.tap()
        }

        // Save
        let saveButton = app.buttons["quickadd_save_button"]
        assertExists(saveButton, timeout: 3)
        saveButton.tap()

        // Verify a transaction row appears
        let transactionRow = app.otherElements["transaction_row"].firstMatch
        assertExists(transactionRow, timeout: 5, message: "Transaction row should appear after saving")
        takeScreenshot(name: "after_add_transaction")
    }

    // MARK: - Swipe Action Tests

    /// Verifies swipe-left delete removes the transaction row.
    @MainActor
    func testSwipeToDeleteTransaction() throws {
        navigateToTransactions()

        // Tap today to see transactions
        app.buttons["calendar_today_button"].tap()

        let firstRow = app.otherElements["transaction_row"].firstMatch
        guard firstRow.waitForExistence(timeout: 5) else {
            throw XCTSkip("Skipping: no transactions present for today. Add one first or use seed data.")
        }

        firstRow.swipeLeft()

        // Tap the Delete button revealed by the custom SwipeActionView
        let deleteButton = app.buttons["swipe_action_delete"]
        assertExists(deleteButton, timeout: 3)
        deleteButton.tap()

        // Confirm row is gone — either list is empty or row no longer matches
        let stillExists = firstRow.waitForExistence(timeout: 2)
        XCTAssertFalse(stillExists, "Transaction row should be removed after delete")
        takeScreenshot(name: "after_delete_transaction")
    }

    /// Verifies swipe-left edit opens the full edit form pre-filled with data.
    @MainActor
    func testSwipeToEditTransaction() throws {
        navigateToTransactions()

        app.buttons["calendar_today_button"].tap()

        let firstRow = app.otherElements["transaction_row"].firstMatch
        guard firstRow.waitForExistence(timeout: 5) else {
            throw XCTSkip("Skipping: no transactions present for today.")
        }

        firstRow.swipeLeft()

        // Tap the Edit button revealed by the custom SwipeActionView
        let editButton = app.buttons["swipe_action_edit"]
        assertExists(editButton, timeout: 3)
        editButton.tap()

        // Confirm the edit form is shown with the Save/Cancel toolbar
        let cancelButton = app.buttons["form_cancel_button"]
        assertExists(cancelButton, timeout: 3, message: "Edit form should be presented with Cancel button")
        let saveButton = app.buttons["form_save_button"]
        assertExists(saveButton, message: "Edit form should have a Save button")

        // Confirm amount field is pre-filled (not empty)
        let amountField = app.textFields["form_amount_field"]
        assertExists(amountField)
        XCTAssertFalse((amountField.value as? String ?? "").isEmpty, "Amount field should be pre-filled")

        takeScreenshot(name: "edit_form_prefilled")
        cancelButton.tap()
    }

    // MARK: - Search Test

    /// Verifies the search bar filters transactions and highlights matching dates.
    @MainActor
    func testSearchTransaction() throws {
        navigateToTransactions()

        let searchField = app.searchFields.firstMatch
        assertExists(searchField, timeout: 3)
        searchField.tap()
        searchField.typeText("a") // Generic single character to trigger search

        // After search, either results or "No Results" empty state should be visible
        let listExists = app.scrollViews["transaction_list"].waitForExistence(timeout: 5)
        let noResultsExists = app.staticTexts["No Results"].waitForExistence(timeout: 5)
        XCTAssertTrue(listExists || noResultsExists, "Expected search results or 'No Results' state")

        takeScreenshot(name: "search_active")

        // Clear search
        let clearButton = app.buttons["Clear text"]
        if clearButton.waitForExistence(timeout: 2) {
            clearButton.tap()
        } else {
            // Fallback: clear field manually
            searchField.clearText()
        }

        // Cancel search to dismiss keyboard
        let cancelSearch = app.buttons["Cancel"]
        if cancelSearch.waitForExistence(timeout: 2) {
            cancelSearch.tap()
        }

        // Verify we're back to the initial state
        let emptyState = app.otherElements["transaction_empty_select_date"].firstMatch
        XCTAssertTrue(
            emptyState.waitForExistence(timeout: 3),
            "Should return to 'Select a Date' state after clearing search"
        )
    }

    // MARK: - Calendar Navigation Test

    /// Verifies tapping next/prev arrows updates the displayed month/year.
    @MainActor
    func testCalendarNavigationNextAndPrevious() throws {
        navigateToTransactions()

        // Record current month label
        let monthYearButton = app.buttons["calendar_month_year_button"]
        assertExists(monthYearButton)
        let initialLabel = monthYearButton.label

        // Navigate forward
        let nextButton = app.buttons["calendar_next_button"]
        assertExists(nextButton)
        nextButton.tap()

        // Label should change
        let updatedLabel = monthYearButton.label
        XCTAssertNotEqual(initialLabel, updatedLabel, "Month/year label should change after tapping next")
        takeScreenshot(name: "calendar_next_month")

        // Navigate back
        let prevButton = app.buttons["calendar_prev_button"]
        assertExists(prevButton)
        prevButton.tap()

        let restoredLabel = monthYearButton.label
        XCTAssertEqual(initialLabel, restoredLabel, "Month/year label should return to initial after tapping prev")
        takeScreenshot(name: "calendar_prev_month")
    }
}

// MARK: - XCUIElement Helpers

private extension XCUIElement {
    /// Clears all text in a text field.
    func clearText() {
        guard let stringValue = self.value as? String else { return }
        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
