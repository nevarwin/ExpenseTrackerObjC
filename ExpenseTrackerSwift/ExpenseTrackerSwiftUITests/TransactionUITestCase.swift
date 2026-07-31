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

    // MARK: - Screenshot Helper

    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
