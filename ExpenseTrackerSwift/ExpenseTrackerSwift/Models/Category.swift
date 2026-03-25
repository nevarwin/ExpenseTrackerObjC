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
    
    
    func transactionsInMonth(_ date: Date = Date()) -> [Transaction] {
        let bounds = DateRangeHelper.monthBounds(for: date)
        return transactions.filter { transaction in
            transaction.isActive &&
            DateRangeHelper.isSameMonth(transaction.budgetPeriod, bounds.start)
        }
    }
    
    
    func usedAmountInMonth(_ date: Date) -> Decimal {
        transactionsInMonth(date)
            .reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    
    
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
