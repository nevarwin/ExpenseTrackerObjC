import SwiftData
import Foundation

@Model
final class Transaction {
    var amount: Decimal
    var desc: String
    var date: Date
    var budgetPeriod: Date  // First day of the month this transaction belongs to
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    var budget: Budget?
    var category: Category?
    
    init(
        amount: Decimal,
        description: String,
        date: Date,
        budget: Budget? = nil,
        category: Category? = nil,
        budgetPeriod: Date? = nil
    ) {
        self.amount = amount
        self.desc = description
        self.date = date
        // Auto-assign budgetPeriod to the start of the transaction date's month if not provided
        self.budgetPeriod = budgetPeriod ?? DateRangeHelper.monthBounds(for: date).start
        self.isActive = true
        self.budget = budget
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var isIncome: Bool {
        category?.isIncome ?? false
    }
    
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - Business Logic
    
    func softDelete() {
        isActive = false
        updatedAt = Date()
    }
    
}
