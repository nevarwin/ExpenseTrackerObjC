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

    // MARK: - Screenshot Helper

    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
