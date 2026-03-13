import XCTest
import SwiftData
@testable import ExpenseTrackerSwift

/// Tests for Budget's computed properties:
/// currentMonthExpenses, currentMonthIncome, currentMonthRemaining,
/// updateRemainingAmount, expensesInMonth, and inactive-transaction exclusion.
final class BudgetComputedPropertyTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    // Fixed reference dates
    let thisMonth: Date = {
        // Use the start of the current month as the budgetPeriod
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: comps)!
    }()

    var lastMonth: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: thisMonth)!
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([Budget.self, Category.self, Transaction.self, BudgetAllocation.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    // MARK: - Helpers

    /// Insert a Budget + expense Category + a Transaction for the given budgetPeriod.
    @discardableResult
    private func addExpense(
        to budget: Budget,
        amount: Decimal,
        budgetPeriod: Date,
        isActive: Bool = true
    ) throws -> Transaction {
        let category = Category(name: "Expense Cat", allocatedAmount: 9999, isIncome: false, budget: budget)
        context.insert(category)

        let txn = Transaction(
            amount: amount,
            description: "Test expense",
            date: budgetPeriod,       // date doesn't drive period filtering — budgetPeriod does
            budget: budget,
            category: category,
            budgetPeriod: budgetPeriod
        )
        txn.isActive = isActive
        context.insert(txn)
        try context.save()
        return txn
    }

    @discardableResult
    private func addIncome(
        to budget: Budget,
        amount: Decimal,
        budgetPeriod: Date,
        isActive: Bool = true
    ) throws -> Transaction {
        let category = Category(name: "Income Cat", allocatedAmount: 9999, isIncome: true, budget: budget)
        context.insert(category)

        let txn = Transaction(
            amount: amount,
            description: "Test income",
            date: budgetPeriod,
            budget: budget,
            category: category,
            budgetPeriod: budgetPeriod
        )
        txn.isActive = isActive
        context.insert(txn)
        try context.save()
        return txn
    }

    // MARK: - currentMonthExpenses

    func testCurrentMonthExpenses_onlyThisMonth() throws {
        let budget = Budget(name: "B", totalAmount: 1000)
        context.insert(budget)

        try addExpense(to: budget, amount: 200, budgetPeriod: thisMonth)
        try addExpense(to: budget, amount: 100, budgetPeriod: thisMonth)
        try addExpense(to: budget, amount: 500, budgetPeriod: lastMonth)   // should be excluded

        XCTAssertEqual(budget.currentMonthExpenses, 300,
                       "currentMonthExpenses should only sum expenses in the current month")
    }

    // MARK: - currentMonthIncome

    func testCurrentMonthIncome_onlyThisMonth() throws {
        let budget = Budget(name: "B", totalAmount: 1000)
        context.insert(budget)

        try addIncome(to: budget, amount: 500, budgetPeriod: thisMonth)
        try addIncome(to: budget, amount: 300, budgetPeriod: lastMonth)   // should be excluded

        XCTAssertEqual(budget.currentMonthIncome, 500,
                       "currentMonthIncome should only sum income in the current month")
    }

    // MARK: - currentMonthRemaining

    func testCurrentMonthRemaining_calculation() throws {
        // remaining = totalAmount + income - expenses
        let budget = Budget(name: "B", totalAmount: 1000)
        context.insert(budget)

        try addExpense(to: budget, amount: 300, budgetPeriod: thisMonth)
        try addIncome(to: budget, amount: 200, budgetPeriod: thisMonth)

        // Expected: 1000 + 200 - 300 = 900
        XCTAssertEqual(budget.currentMonthRemaining, 900,
                       "currentMonthRemaining = totalAmount(1000) + income(200) - expenses(300)")
    }

    // MARK: - updateRemainingAmount (all-time)

    func testUpdateRemainingAmount_allTime() throws {
        let budget = Budget(name: "B", totalAmount: 1000)
        context.insert(budget)

        // Transactions across different months — all should count all-time
        try addExpense(to: budget, amount: 400, budgetPeriod: thisMonth)
        try addExpense(to: budget, amount: 100, budgetPeriod: lastMonth)
        try addIncome(to: budget,  amount: 600, budgetPeriod: thisMonth)

        budget.updateRemainingAmount()

        // Expected: 1000 + 600 - (400 + 100) = 1100
        XCTAssertEqual(budget.remainingAmount, 1100,
                       "updateRemainingAmount() should reflect all-time income and expenses")
    }

    // MARK: - expensesInMonth (specific month)

    func testExpensesInMonth_specificMonth() throws {
        let budget = Budget(name: "B", totalAmount: 1000)
        context.insert(budget)

        try addExpense(to: budget, amount: 250, budgetPeriod: lastMonth)
        try addExpense(to: budget, amount: 750, budgetPeriod: thisMonth)  // should NOT appear

        let result = budget.expensesInMonth(lastMonth)

        XCTAssertEqual(result, 250,
                       "expensesInMonth(lastMonth) should only sum expenses for that period")
    }

    // MARK: - Inactive transaction exclusion

    func testInactiveTransactions_excluded() throws {
        let budget = Budget(name: "B", totalAmount: 1000)
        context.insert(budget)

        try addExpense(to: budget, amount: 100, budgetPeriod: thisMonth, isActive: true)
        try addExpense(to: budget, amount: 999, budgetPeriod: thisMonth, isActive: false) // soft-deleted

        XCTAssertEqual(budget.currentMonthExpenses, 100,
                       "Soft-deleted (isActive=false) transactions should be excluded from computed totals")
    }
}
