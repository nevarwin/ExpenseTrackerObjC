import SwiftData
import Foundation

@Model
final class Budget {
    var id: UUID = UUID()
    var name: String
    var totalAmount: Decimal
    var remainingAmount: Decimal
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Category.budget)
    var categories: [Category] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.budget)
    var transactions: [Transaction] = []
    
    @Relationship(deleteRule: .cascade)
    var allocations: [BudgetAllocation] = []
    
    init(
        name: String,
        totalAmount: Decimal,
        remainingAmount: Decimal? = nil,
        isActive: Bool = true
    ) {
        self.name = name
        self.totalAmount = totalAmount
        self.remainingAmount = remainingAmount ?? totalAmount
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    
    // MARK: - Monthly Period Filtering
    
    /// Get transactions for a specific month
    /// - Parameter date: The date within the month to filter (defaults to current date)
    /// - Returns: Array of active transactions assigned to that month
    func transactionsInMonth(_ date: Date = Date()) -> [Transaction] {
        let bounds = DateRangeHelper.monthBounds(for: date)
        return transactions.filter { transaction in
            transaction.isActive &&
            DateRangeHelper.isSameMonth(transaction.budgetPeriod, bounds.start)
        }
    }
    
    // MARK: - Current Month Calculations
    
    /// Total expenses for the current month only
    var currentMonthExpenses: Decimal {
        transactionsInMonth()
            .filter { !($0.category?.isIncome ?? false) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    /// Total income for the current month only
    var currentMonthIncome: Decimal {
        transactionsInMonth()
            .filter { $0.category?.isIncome ?? false }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    /// Remaining amount for the current month (total budget + current month income - current month expenses)
    var currentMonthRemaining: Decimal {
        totalAmount + currentMonthIncome - currentMonthExpenses
    }
    
    // MARK: - Any Month Calculations
    
    /// Calculate total expenses for a specific month
    /// - Parameter date: The date within the month to calculate
    /// - Returns: Total expenses for that month
    func expensesInMonth(_ date: Date) -> Decimal {
        transactionsInMonth(date)
            .filter { !($0.category?.isIncome ?? false) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    /// Calculate total income for a specific month
    /// - Parameter date: The date within the month to calculate
    /// - Returns: Total income for that month
    func incomeInMonth(_ date: Date) -> Decimal {
        transactionsInMonth(date)
            .filter { $0.category?.isIncome ?? false }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    /// Calculate remaining amount for a specific month
    /// - Parameter date: The date within the month to calculate
    /// - Returns: Remaining amount for that month
    func remainingInMonth(_ date: Date) -> Decimal {
        totalAmount + incomeInMonth(date) - expensesInMonth(date)
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
    
    func updateRemainingAmount() {
        remainingAmount = totalAmount + totalIncome - totalExpenses
        updatedAt = Date()
    }
}
