import SwiftData
import Foundation

@Model
final class Category {
    var name: String
    var budgetPeriod: Date
    var allocatedAmount: Decimal
    var usedAmount: Decimal
    var isIncome: Bool
    var isActive: Bool

    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var budget: Budget?
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.category)
    var transactions: [Transaction] = []
    
    init(
        name: String,
        allocatedAmount: Decimal,
        isIncome: Bool,
        budgetPeriod: Date? = nil,
        budget: Budget? = nil
    ) {
        self.name = name
        self.allocatedAmount = allocatedAmount
        self.budgetPeriod = budgetPeriod ?? budget?.startDate ?? Date()
        self.usedAmount = 0
        self.isIncome = isIncome
        self.isActive = true

        self.budget = budget
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var remainingAmount: Decimal {
        allocatedAmount - usedAmount
    }
    
    var usagePercentage: Double {
        guard allocatedAmount > 0 else { return 0 }
        return Double(truncating: (usedAmount / allocatedAmount) as NSDecimalNumber)
    }
    
    var isOverBudget: Bool {
        usedAmount > allocatedAmount
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
    
    /// Used amount for the current month only
    var currentMonthUsedAmount: Decimal {
        transactionsInMonth()
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    /// Calculate used amount for a specific month
    /// - Parameter date: The date within the month to calculate
    /// - Returns: Total used amount for that month
    func usedAmountInMonth(_ date: Date) -> Decimal {
        transactionsInMonth(date)
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    /// Remaining amount for the current month (allocated - used in current month)
    var currentMonthRemainingAmount: Decimal {
        allocatedAmount - currentMonthUsedAmount
    }
    
    /// Calculate remaining amount for a specific month
    /// - Parameter date: The date within the month to calculate
    /// - Returns: Remaining amount for that month
    func remainingAmountInMonth(_ date: Date) -> Decimal {
        allocatedAmount - usedAmountInMonth(date)
    }
    
    // MARK: - Business Logic
    
    func isValid(for date: Date) -> Bool {
        return isActive
    }
    

    
    func updateUsedAmount() {
        usedAmount = transactions
            .filter { $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.amount }
        updatedAt = Date()
    }
    
}
