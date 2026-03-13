import XCTest
import SwiftData
@testable import ExpenseTrackerSwift

/// Tests for TransactionViewModel.checkOverflow(amount:budget:category:existing:)
final class OverflowTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var budget: Budget!
    var category: Category!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([Budget.self, Category.self, Transaction.self, BudgetAllocation.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)

        // Create a fresh Budget + Category for each test
        budget = Budget(name: "Test Budget", totalAmount: 1000)
        category = Category(name: "Groceries", allocatedAmount: 100, isIncome: false, budget: budget)
        context.insert(budget)
        context.insert(category)
        try context.save()
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        budget = nil
        category = nil
        try super.tearDownWithError()
    }

    // Helper: create a TransactionViewModel attached to the in-memory context
    private func makeViewModel() -> TransactionViewModel {
        TransactionViewModel(modelContext: context)
    }

    // MARK: - Tests

    /// Adding 49 when 50 is already used (100 allocated) → within budget
    func testCheckOverflow_withinBudget() {
        category.usedAmount = 50
        let vm = makeViewModel()
        XCTAssertFalse(vm.checkOverflow(amount: 49, budget: budget, category: category),
                       "50 used + 49 new = 99, should NOT overflow (alloc: 100)")
    }

    /// Adding exactly the remaining amount → should NOT overflow
    func testCheckOverflow_exactlyAtLimit() {
        category.usedAmount = 50
        let vm = makeViewModel()
        XCTAssertFalse(vm.checkOverflow(amount: 50, budget: budget, category: category),
                       "50 used + 50 new = 100, should NOT overflow (exactly at limit)")
    }

    /// Adding 1 more than remaining → overflows
    func testCheckOverflow_exceedsLimit() {
        category.usedAmount = 50
        let vm = makeViewModel()
        XCTAssertTrue(vm.checkOverflow(amount: 51, budget: budget, category: category),
                      "50 used + 51 new = 101, SHOULD overflow (alloc: 100)")
    }

    /// Editing an existing transaction in the same category:
    /// old amount (50) is deducted before checking — new amount (90) should be within 100
    func testCheckOverflow_whenEditing_sameCategory() throws {
        category.usedAmount = 50

        let existing = Transaction(
            amount: 50,
            description: "Existing",
            date: Date(),
            budget: budget,
            category: category
        )
        context.insert(existing)
        try context.save()

        let vm = makeViewModel()
        // Editing 50 → 90: effective used = (50 - 50) + 90 = 90 ≤ 100 → no overflow
        XCTAssertFalse(
            vm.checkOverflow(amount: 90, budget: budget, category: category, existing: existing),
            "Editing 50→90 in same category (allocated 100) should NOT overflow"
        )
    }

    /// Editing same-category transaction where new amount goes over the limit
    func testCheckOverflow_whenEditing_sameCategory_overflows() throws {
        category.usedAmount = 50

        let existing = Transaction(
            amount: 50,
            description: "Existing",
            date: Date(),
            budget: budget,
            category: category
        )
        context.insert(existing)
        try context.save()

        let vm = makeViewModel()
        // Editing 50 → 110: effective used = (50 - 50) + 110 = 110 > 100 → overflow
        XCTAssertTrue(
            vm.checkOverflow(amount: 110, budget: budget, category: category, existing: existing),
            "Editing 50→110 in same category (allocated 100) SHOULD overflow"
        )
    }
}
