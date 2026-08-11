import XCTest

// MARK: - Base Class

/// Shared base for all Transaction UI tests.
/// Handles app launch with test arguments and provides reusable helpers.
class TransactionUITestCase: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Setup / Teardown

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        // -skipOnboarding: bypass the onboarding gate in ContentView
        // -UITestMode: future hook for seed data (ready for Option B seeding)
        app.launchArguments = ["-skipOnboarding", "-UITestMode"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Helpers

    /// Taps the Transactions tab to ensure we're on the right screen.
    func navigateToTransactions() {
        let transactionsTab = app.tabBars.buttons["Transactions"]
        if transactionsTab.exists {
            transactionsTab.tap()
        }
    }

    /// Taps a calendar day cell by accessibility label prefix (e.g. "July 15").
    /// DayCell labels are formatted as "<Month> <Day> Has/No transactions".
    func tapCalendarDate(monthDay: String) {
        let matchingCells = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", monthDay))
        if matchingCells.count > 0 {
            matchingCells.firstMatch.tap()
        }
    }

    // MARK: - Wait Helpers

    /// Asserts an element appears within the timeout, failing with a descriptive message if not.
    func assertExists(_ element: XCUIElement, timeout: TimeInterval = 5, message: String = "") {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, message.isEmpty ? "\(element) did not appear within \(timeout)s" : message)
    }

    // MARK: - Quick Add Flow Helper

    /// Opens the Quick Add sheet via the toolbar Add button.
    /// Precondition: An active budget must exist.
    func openQuickAddSheet() {
        let addButton = app.buttons["transaction_add_button"]
        assertExists(addButton, message: "Add Transaction button not found — is a budget configured?")
        addButton.tap()
    }

    /// Completes a full quick-add transaction flow.
    func addTransactionViaQuickAdd(amount: String, categoryName: String) {
        openQuickAddSheet()

        let amountField = app.textFields["quickadd_amount_field"]
        assertExists(amountField)
        amountField.tap()
        amountField.typeText(amount)

        let categoryButton = app.otherElements["quickadd_category_\(categoryName)"]
        assertExists(categoryButton)
        categoryButton.tap()

        let saveButton = app.buttons["quickadd_save_button"]
        assertExists(saveButton)
        saveButton.tap()
    }

    // MARK: - Full Form Helpers

    /// Opens the full TransactionFormView by tapping Add → Expand.
    func openFullFormFromList() {
        let addButton = app.buttons["transaction_add_button"]
        assertExists(addButton, message: "Add Transaction button not found — is a budget configured?")
        addButton.tap()

        let expandButton = app.buttons["quickadd_expand_button"]
        assertExists(expandButton, timeout: 3)
        expandButton.tap()
    }

    /// Fills the full form with specified values.
    /// - Parameters:
    ///   - amount: Text to enter in the amount field.
    ///   - description: Text to enter in the description field.
    ///   - categoryName: Name of the category to select (matched from the picker).
    func fillFullForm(amount: String, description: String, categoryName: String? = nil) {
        let amountField = app.textFields["form_amount_field"]
        assertExists(amountField, timeout: 5)
        amountField.tap()
        amountField.typeText(amount)

        let descField = app.textFields["form_description_field"]
        assertExists(descField)
        descField.tap()
        descField.typeText(description)

        // Select category by tapping the picker and choosing the specified name
        if let categoryName = categoryName {
            let categoryPicker = app.buttons["form_category_picker"]
            if categoryPicker.waitForExistence(timeout: 3) {
                categoryPicker.tap()
                let option = app.buttons[categoryName]
                if option.waitForExistence(timeout: 3) {
                    option.tap()
                }
            }
        }
    }

    /// Verifies that at least one transaction row appears in the current list.
    func verifyTransactionRowAppears(timeout: TimeInterval = 5) {
        let transactionRow = app.otherElements["transaction_row"].firstMatch
        assertExists(transactionRow, timeout: timeout, message: "Transaction row should appear")
    }

    // MARK: - Calendar Helpers

    /// Taps "Today" on the calendar to select the current date.
    func tapTodayButton() {
        let todayButton = app.buttons["calendar_today_button"]
        assertExists(todayButton)
        todayButton.tap()
    }

    /// Selects the calendar scope (Week or Month) via the segmented control.
    func selectCalendarScope(_ scope: String) {
        let scopePicker = app.segmentedControls["calendar_scope_picker"]
        assertExists(scopePicker, timeout: 3)
        scopePicker.buttons[scope].tap()
    }

    /// Toggles range mode on or off.
    func toggleRangeMode(isOn: Bool) {
        let toggle = app.switches["calendar_range_toggle"]
        assertExists(toggle, timeout: 3)

        let currentValue = toggle.value as? String
        let isCurrentlyOn = currentValue == "1"
        if isCurrentlyOn != isOn {
            toggle.tap()
        }
    }

    // MARK: - Budget Tab Navigation

    /// Navigates to the Budget tab.
    func navigateToBudget() {
        let budgetTab = app.tabBars.buttons["Budget"]
        if budgetTab.exists {
            budgetTab.tap()
        }
    }

    // MARK: - Budget Helpers

    /// Opens the budget menu from the toolbar and taps "Add Budget".
    func openAddBudgetForm() {
        let menuButton = app.buttons["budget_menu_button"]
        assertExists(menuButton, message: "Budget menu button not found")
        menuButton.tap()

        let addItem = app.buttons["budget_add_menu_item"]
        assertExists(addItem, timeout: 3, message: "Add Budget menu item not found")
        addItem.tap()
    }

    /// Creates a new budget by filling BudgetFormView with the given name.
    func createBudget(name: String) {
        openAddBudgetForm()

        let nameField = app.textFields["budget_name_field"]
        assertExists(nameField, timeout: 5, message: "Budget name field not found")
        nameField.tap()
        nameField.typeText(name)

        let saveButton = app.buttons["budget_save_button"]
        assertExists(saveButton, message: "Budget save button not found")
        saveButton.tap()
    }

    /// Taps the budget card with the given name to navigate to BudgetDetailView.
    func openBudgetDetail(named name: String) {
        let card = app.otherElements["budget_card_\(name)"].firstMatch
        if card.waitForExistence(timeout: 5) {
            card.tap()
        } else {
            // Fallback: tap first budget cell
            app.cells.firstMatch.tap()
        }
    }

    /// Navigates through Budget → BudgetDetail → first month row → MonthlyBudgetDetailView.
    /// Returns false if navigation could not be completed.
    @discardableResult
    func openFirstBudgetPeriod() -> Bool {
        navigateToBudget()
        sleep(1)

        let firstCard = app.cells.firstMatch
        guard firstCard.waitForExistence(timeout: 5) else { return false }
        firstCard.tap()

        // In BudgetDetailView, tap the first period row (skip the Add Month button cell)
        let periodRow = app.cells.element(boundBy: 1)
        guard periodRow.waitForExistence(timeout: 5) else { return false }
        periodRow.tap()

        // Confirm we landed on MonthlyBudgetDetailView by finding the searchable field or a known section
        return app.otherElements["quickadd_category_name_field"].waitForExistence(timeout: 5)
            || app.staticTexts["Expense Overview"].waitForExistence(timeout: 5)
    }

    /// Quick-adds a category using MonthlyBudgetDetailView's inline form.
    /// Precondition: Must already be on MonthlyBudgetDetailView.
    func quickAddCategory(name: String, amount: String, isIncome: Bool = false) {
        let nameField = app.textFields["quickadd_category_name_field"]
        assertExists(nameField, timeout: 5, message: "Category name field not found")
        nameField.tap()
        nameField.typeText(name)

        let amountField = app.textFields["quickadd_category_amount_field"]
        assertExists(amountField, message: "Category amount field not found")
        amountField.tap()
        amountField.typeText(amount)

        if isIncome {
            let typePicker = app.segmentedControls["quickadd_category_type_picker"]
            if typePicker.waitForExistence(timeout: 3) {
                typePicker.buttons["Income"].tap()
            }
        }

        let saveButton = app.buttons["quickadd_category_save_button"]
        assertExists(saveButton, message: "Category save button not found")
        saveButton.tap()
    }

    // MARK: - Screenshot Helper

    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
