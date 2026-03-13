import Combine
import SwiftUI
import GRDB

final class BudgetViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var selectedBudget: Budget?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let selectedBudgetKey = "SelectedBudgetID"
    private let budgetRepo: BudgetRepository
    private let categoryRepo: CategoryRepository
    private let transactionRepo: TransactionRepository

    init(
        budgetRepo: BudgetRepository = BudgetRepository(),
        categoryRepo: CategoryRepository = CategoryRepository(),
        transactionRepo: TransactionRepository = TransactionRepository()
    ) {
        self.budgetRepo = budgetRepo
        self.categoryRepo = categoryRepo
        self.transactionRepo = transactionRepo
    }

    // MARK: - Read

    func loadBudgets() {
        isLoading = true
        errorMessage = nil

        do {
            var fetched = try budgetRepo.fetchAll()

            // Pre-populate relations so computed properties work
            for budget in fetched {
                let cats = try categoryRepo.fetchAll(budgetId: budget.id)
                let txns = try transactionRepo.fetchAll(budgetId: budget.id)
                budget.categories = cats
                budget.transactions = txns
                for cat in cats { cat.budget = budget }
                for txn in txns {
                    txn.budget = budget
                    txn.category = cats.first { $0.id == txn.categoryId }
                }
                for cat in cats {
                    cat.transactions = txns.filter { $0.categoryId == cat.id }
                }
            }

            budgets = fetched

            // Restore or default selection
            if let savedIdString = UserDefaults.standard.string(forKey: selectedBudgetKey),
               let found = budgets.first(where: { $0.id == savedIdString }) {
                selectedBudget = found
            } else {
                selectedBudget = budgets.first(where: { $0.isActive })
            }

        } catch {
            errorMessage = "Failed to load budgets: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Write

    @discardableResult
    func createBudget(name: String, totalAmount: Decimal) throws -> Budget {
        let budget = Budget(name: name, totalAmount: totalAmount)
        try budgetRepo.insert(budget)

        budgets.insert(budget, at: 0)
        selectedBudget = budget
        UserDefaults.standard.set(budget.id, forKey: selectedBudgetKey)

        return budget
    }

    func updateBudget(_ budget: Budget, name: String, totalAmount: Decimal) throws {
        budget.name = name
        budget.totalAmount = totalAmount
        budget.updatedAt = Date()
        try budgetRepo.update(budget)
    }

    func deleteBudget(_ budget: Budget) throws {
        try budgetRepo.delete(id: budget.id)

        if selectedBudget?.id == budget.id {
            selectedBudget = nil
        }
        loadBudgets()
    }

    // MARK: - Category Management (called from BudgetFormView)

    func insertCategory(_ category: Category) throws {
        try categoryRepo.insert(category)
    }

    func updateCategory(_ category: Category) throws {
        try categoryRepo.update(category)
    }

    func deleteCategory(id: String) throws {
        try categoryRepo.delete(id: id)
    }

    func saveBudgetAndCategories(budget: Budget) throws {
        try budgetRepo.save(budget)
    }
}
