import SwiftData
import Foundation

@Model
final class Budget {
    var id: UUID = UUID()
    var name: String
    var startDate: Date
    var totalAmount: Decimal
    var remainingAmount: Decimal
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Category.budget)
    var categories: [Category] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.budget)
    var transactions: [Transaction] = []
    
    
    init(
        name: String,
        startDate: Date? = nil,
        totalAmount: Decimal,
        remainingAmount: Decimal? = nil,
        isActive: Bool = true
    ) {
        self.name = name
        self.startDate = startDate ?? Date()
        self.totalAmount = totalAmount
        self.remainingAmount = remainingAmount ?? totalAmount
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    
    func transactionsInMonth(_ date: Date = Date()) -> [Transaction] {
        let bounds = DateRangeHelper.monthBounds(for: date)
        return transactions.filter { transaction in
            transaction.isActive &&
            DateRangeHelper.isSameMonth(transaction.budgetPeriod, bounds.start)
        }
    }
    
    var currentMonthExpenses: Decimal {
        transactionsInMonth()
            .filter { !($0.category?.isIncome ?? false) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    var currentMonthIncome: Decimal {
        transactionsInMonth()
            .filter { $0.category?.isIncome ?? false }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    
    func expensesInMonth(_ date: Date) -> Decimal {
        transactionsInMonth(date)
            .filter { !($0.category?.isIncome ?? false) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    func incomeInMonth(_ date: Date) -> Decimal {
        transactionsInMonth(date)
            .filter { $0.category?.isIncome ?? false }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    func remainingInMonth(_ date: Date) -> Decimal {
        incomeInMonth(date) - expensesInMonth(date)
    }
    
    // MARK: - All-Time Computed Properties (Existing)
    
    // Computed properties
    var totalExpenses: Decimal {
        transactions
            .filter { !($0.category?.isIncome ?? false) && $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    var totalIncome: Decimal {
        transactions
            .filter { ($0.category?.isIncome ?? false) && $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }


    /// Total planned expenses (sum of allocations)
    func plannedExpenses(for date: Date = Date()) -> Decimal {
        categories
            .filter { !$0.isIncome && $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.allocatedAmount }
    }

    /// Total planned income (sum of allocations)
    func plannedIncome(for date: Date = Date()) -> Decimal {
        categories
            .filter { $0.isIncome && $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.allocatedAmount }
    }

    /// Difference for expenses (Planned - Actual)
    /// Positive means under budget (good), negative means over budget (bad)
    func expenseDiffInMonth(_ date: Date) -> Decimal {
        plannedExpenses(for: date) - expensesInMonth(date)
    }

    /// Difference for income (Actual - Planned)
    /// Positive means more income than planned (good), negative means less (bad)
    func incomeDiffInMonth(_ date: Date) -> Decimal {
        incomeInMonth(date) - plannedIncome(for: date)
    }
    
    func updateRemainingAmount() {
        remainingAmount = totalIncome - totalExpenses
        updatedAt = Date()
    }
}
