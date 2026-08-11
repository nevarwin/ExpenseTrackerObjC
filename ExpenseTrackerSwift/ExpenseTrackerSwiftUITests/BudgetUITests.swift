import XCTest

// MARK: - Budget Feature UI Tests

/// Comprehensive UI tests covering the full lifecycle of the Budget feature:
/// creating budgets, editing them, adding periods and categories, searching categories,
/// viewing history trends, and deleting budgets.
final class BudgetUITests: TransactionUITestCase {

    // MARK: - 1. Create Budget from Empty State

    /// Verifies that tapping "Create Blank Budget" on the empty state card opens BudgetFormView,
    /// filling the name and saving creates a new budget card in the list.
    @MainActor
    func testCreateBlankBudgetFromEmptyState() throws {
        navigateToBudget()
        sleep(1)

        // If there are already budgets, skip — this tests the empty state path
        guard app.buttons["empty_budget_create_button"].waitForExistence(timeout: 5) else {
            throw XCTSkip("Empty state not visible — budgets already exist.")
        }

        app.buttons["empty_budget_create_button"].tap()

        let nameField = app.textFields["budget_name_field"]
        assertExists(nameField, timeout: 5, message: "BudgetFormView should appear with name field")
        nameField.tap()
        nameField.typeText("Test Budget")

        let saveButton = app.buttons["budget_save_button"]
        assertExists(saveButton)
        saveButton.tap()

        // After saving, BudgetListView should show the new card
        let budgetCard = app.otherElements["budget_card_Test Budget"].firstMatch
        assertExists(budgetCard, timeout: 5, message: "New budget card should appear after creation")
        takeScreenshot(name: "budget_created_from_empty_state")
    }

    // MARK: - 2. Create Budget from Toolbar Menu

    /// Verifies that tapping the "⋯" toolbar menu → "Add Budget" opens BudgetFormView
    /// and saving creates a new budget in the list.
    @MainActor
    func testCreateBudgetFromToolbarMenu() throws {
        navigateToBudget()
        sleep(1)

        let menuButton = app.buttons["budget_menu_button"]
        assertExists(menuButton, timeout: 5, message: "Toolbar menu button not found")
        menuButton.tap()

        let addMenuItem = app.buttons["budget_add_menu_item"]
        guard addMenuItem.waitForExistence(timeout: 3) else {
            throw XCTSkip("Add Budget menu item not visible.")
        }
        addMenuItem.tap()

        let nameField = app.textFields["budget_name_field"]
        assertExists(nameField, timeout: 5, message: "Budget form name field should be visible")
        nameField.tap()
        nameField.typeText("Menu Budget")

        let saveButton = app.buttons["budget_save_button"]
        assertExists(saveButton)
        saveButton.tap()

        // Verify budget appeared in list
        let budgetCard = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'budget_card_'")
        ).firstMatch
        assertExists(budgetCard, timeout: 5, message: "Budget card should appear after creating from menu")
        takeScreenshot(name: "budget_created_from_menu")
    }

    // MARK: - 3. Edit Budget Name

    /// Verifies that navigating into a budget detail, opening the edit form, and changing
    /// the name saves the update.
    @MainActor
    func testEditBudgetName() throws {
        navigateToBudget()
        sleep(1)

        let firstCard = app.cells.firstMatch
        guard firstCard.waitForExistence(timeout: 5) else {
            throw XCTSkip("No budgets available to edit.")
        }
        firstCard.tap()

        // Open the detail menu
        let detailMenuButton = app.buttons["budget_detail_menu_button"]
        assertExists(detailMenuButton, timeout: 5, message: "Detail menu button not found")
        detailMenuButton.tap()

        let editItem = app.buttons["budget_edit_menu_item"]
        guard editItem.waitForExistence(timeout: 3) else {
            throw XCTSkip("Edit Budget menu item not visible.")
        }
        editItem.tap()

        // Edit form appears
        let nameField = app.textFields["budget_name_field"]
        assertExists(nameField, timeout: 5, message: "Budget name field should be visible in edit form")
        nameField.tap()

        // Clear existing name using triple-tap select-all
        nameField.press(forDuration: 1.2)
        if app.menuItems["Select All"].waitForExistence(timeout: 2) {
            app.menuItems["Select All"].tap()
        }
        nameField.typeText("Renamed Budget")

        let saveButton = app.buttons["budget_save_button"]
        assertExists(saveButton)
        saveButton.tap()

        sleep(1)
        takeScreenshot(name: "budget_name_edited")
    }

    // MARK: - 4. Add New Budget Period

    /// Verifies that tapping "Add Month" in BudgetDetailView and confirming creates a new period row.
    @MainActor
    func testAddNewBudgetPeriod() throws {
        navigateToBudget()
        sleep(1)

        let firstCard = app.cells.firstMatch
        guard firstCard.waitForExistence(timeout: 5) else {
            throw XCTSkip("No budgets available to test period addition.")
        }
        firstCard.tap()

        let addMonthButton = app.buttons["budget_add_month_button"]
        assertExists(addMonthButton, timeout: 5, message: "Add Month button not found")
        addMonthButton.tap()

        // Month picker sheet should appear
        let initializeButton = app.buttons["Initialize Month"]
        assertExists(initializeButton, timeout: 5, message: "Month picker sheet should appear")
        initializeButton.tap()

        sleep(1)
        // Period list should now show at least one row (beyond the Add Month row)
        XCTAssertTrue(app.cells.count > 1, "At least one budget period row should appear after initialization")
        takeScreenshot(name: "budget_period_added")
    }

    // MARK: - 5. Quick Add Category (Expense and Income)

    /// Verifies that the inline quick-add form in MonthlyBudgetDetailView adds expense and income categories.
    @MainActor
    func testQuickAddCategoryInMonthlyDetail() throws {
        guard openFirstBudgetPeriod() else {
            throw XCTSkip("Could not navigate to a monthly budget period.")
        }

        // Add expense category
        quickAddCategory(name: "Groceries", amount: "500")
        sleep(1)

        let groceriesText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Groceries'")
        ).firstMatch
        XCTAssertTrue(
            groceriesText.waitForExistence(timeout: 5),
            "Expense category 'Groceries' should appear after quick add"
        )
        takeScreenshot(name: "expense_category_added")

        // Add income category
        quickAddCategory(name: "Salary", amount: "3000", isIncome: true)
        sleep(1)

        let salaryText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Salary'")
        ).firstMatch
        XCTAssertTrue(
            salaryText.waitForExistence(timeout: 5),
            "Income category 'Salary' should appear after quick add"
        )
        takeScreenshot(name: "income_category_added")
    }

    // MARK: - 6. Search Categories

    /// Verifies that the search bar in MonthlyBudgetDetailView filters the category list.
    @MainActor
    func testSearchCategoriesInMonthlyDetail() throws {
        guard openFirstBudgetPeriod() else {
            throw XCTSkip("Could not navigate to a monthly budget period.")
        }

        guard app.cells.element(boundBy: 0).waitForExistence(timeout: 5) else {
            throw XCTSkip("No categories available to search.")
        }

        let searchField = app.searchFields.firstMatch
        assertExists(searchField, timeout: 5, message: "Search field should be present in monthly detail")
        searchField.tap()
        searchField.typeText("zzz_nonexistent_cat")

        let noMatchText = app.staticTexts["No matching categories"]
        XCTAssertTrue(
            noMatchText.waitForExistence(timeout: 5),
            "Empty search result text should appear when no categories match"
        )
        takeScreenshot(name: "category_search_empty")

        // Clear search
        searchField.clearAndEnterText("")
        let cell = app.cells.element(boundBy: 0)
        XCTAssertTrue(
            cell.waitForExistence(timeout: 5),
            "Categories should reappear after clearing search"
        )
        takeScreenshot(name: "category_search_cleared")
    }

    // MARK: - 7. Budget History & Range Picker

    /// Verifies navigating to BudgetHistoryView and switching between date range segments.
    @MainActor
    func testNavigateToBudgetHistoryAndChangeRange() throws {
        navigateToBudget()
        sleep(1)

        let firstCard = app.cells.firstMatch
        guard firstCard.waitForExistence(timeout: 5) else {
            throw XCTSkip("No budgets available to view history.")
        }
        firstCard.tap()

        let detailMenuButton = app.buttons["budget_detail_menu_button"]
        assertExists(detailMenuButton, timeout: 5, message: "Detail menu button not found")
        detailMenuButton.tap()

        let historyItem = app.buttons["budget_history_menu_item"]
        guard historyItem.waitForExistence(timeout: 3) else {
            throw XCTSkip("View History menu item not visible.")
        }
        historyItem.tap()

        let navTitle = app.navigationBars["Budget History"]
        assertExists(navTitle, timeout: 5, message: "Budget History navigation bar should appear")

        let rangePicker = app.segmentedControls["budget_history_range_picker"]
        assertExists(rangePicker, timeout: 5, message: "Range picker should be visible in history view")
        takeScreenshot(name: "budget_history_default")

        for range in ["3M", "6M", "1Y", "All"] {
            let rangeButton = rangePicker.buttons[range]
            if rangeButton.waitForExistence(timeout: 3) {
                rangeButton.tap()
                sleep(1)
                takeScreenshot(name: "budget_history_range_\(range)")
            }
        }

        let breakdownHeader = app.staticTexts["Monthly Breakdown"]
        XCTAssertTrue(
            breakdownHeader.waitForExistence(timeout: 5),
            "Monthly Breakdown section should always be visible"
        )
    }

    // MARK: - 8. Delete Budget with Confirmation

    /// Verifies that deleting from the detail menu shows a confirmation alert and removing
    /// the budget reduces the list count.
    @MainActor
    func testDeleteBudgetWithConfirmation() throws {
        navigateToBudget()
        sleep(1)

        guard app.cells.firstMatch.waitForExistence(timeout: 5) else {
            throw XCTSkip("No budgets available to delete.")
        }

        let initialCount = app.cells.count
        app.cells.firstMatch.tap()

        let detailMenuButton = app.buttons["budget_detail_menu_button"]
        assertExists(detailMenuButton, timeout: 5, message: "Detail menu button not found")
        detailMenuButton.tap()

        let deleteMenuItem = app.buttons["budget_delete_menu_item"]
        guard deleteMenuItem.waitForExistence(timeout: 3) else {
            throw XCTSkip("Delete Budget menu item not visible.")
        }
        deleteMenuItem.tap()

        let alert = app.alerts["Delete Budget"]
        assertExists(alert, timeout: 3, message: "Delete confirmation alert should appear")
        takeScreenshot(name: "budget_delete_confirmation_alert")

        alert.buttons["Delete"].tap()
        sleep(1)

        let newCount = app.cells.count
        XCTAssertTrue(
            newCount < initialCount,
            "Budget count should decrease after deletion (was \(initialCount), now \(newCount))"
        )
        takeScreenshot(name: "budget_deleted_from_detail")
    }
}

// MARK: - XCUIElement Extension

private extension XCUIElement {
    /// Clears all text in a text field then optionally types new text.
    func clearAndEnterText(_ newText: String) {
        tap()
        press(forDuration: 1.2)
        let app = XCUIApplication()
        if app.menuItems["Select All"].waitForExistence(timeout: 2) {
            app.menuItems["Select All"].tap()
            typeText(XCUIKeyboardKey.delete.rawValue)
        }
        if !newText.isEmpty {
            typeText(newText)
        }
    }
}
