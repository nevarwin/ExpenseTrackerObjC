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
