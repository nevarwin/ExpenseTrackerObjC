import SwiftData
import Foundation

@Model
final class Category {
    var name: String = ""
    var budgetPeriod: Date = Date()
    var allocatedAmount: Decimal = 0
    var usedAmount: Decimal = 0
    var isIncome: Bool = false
    var isActive: Bool = true

    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
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
        self.budgetPeriod = (budgetPeriod ?? budget?.startDate ?? Date()).monthBounds.start
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
        let bounds = date.monthBounds
        return transactions.filter { transaction in
            transaction.isActive &&
            transaction.budgetPeriod.isSameMonth(as: bounds.start)
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

// MARK: - View Helpers
extension Category {
    var iconName: String {
        let n = name.lowercased()
        if n.contains("food") || n.contains("eat") || n.contains("restaurant") { return "fork.knife" }
        if n.contains("transport") || n.contains("travel") || n.contains("gas") || n.contains("car") { return "car.fill" }
        if n.contains("shop") || n.contains("cloth") || n.contains("buy") { return "bag.fill" }
        if n.contains("house") || n.contains("rent") || n.contains("home") { return "house.fill" }
        if n.contains("bill") || n.contains("utility") || n.contains("electric") { return "bolt.fill" }
        if n.contains("entertainment") || n.contains("movie") || n.contains("game") { return "tv.fill" }
        if n.contains("health") || n.contains("med") || n.contains("doctor") { return "heart.fill" }
        if n.contains("work") || n.contains("salary") { return "briefcase.fill" }
        if n.contains("money") || n.contains("cash") { return "banknote.fill" }
        return "tag.fill"
    }
}

