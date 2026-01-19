import SwiftData
import Foundation

@Model
final class Category {
    var name: String
    var allocatedAmount: Decimal
    var usedAmount: Decimal
    var isIncome: Bool
    var isActive: Bool
    var isInstallment: Bool
    
    // Installment-specific properties
    var monthlyPayment: Decimal?
    var totalInstallmentAmount: Decimal?
    var installmentMonths: Int?
    var installmentStartDate: Date?
    var installmentEndDate: Date?
    
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
        isInstallment: Bool = false,
        budget: Budget? = nil
    ) {
        self.name = name
        self.allocatedAmount = allocatedAmount
        self.usedAmount = 0
        self.isIncome = isIncome
        self.isActive = true
        self.isInstallment = isInstallment
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
    
    // MARK: - Business Logic
    
    func isValid(for date: Date) -> Bool {
        guard isActive else { return false }
        
        // Check installment expiration
        if isInstallment, let endDate = installmentEndDate {
            return date <= endDate
        }
        
        return true
    }
    
    func hasTransactionInMonth(of date: Date, excluding: Transaction? = nil) -> Bool {
        guard isInstallment else { return false }
        
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.year, .month], from: date)
        
        return transactions.contains { transaction in
            // Skip excluded transaction (for edit mode)
            if let excluding = excluding, transaction.id == excluding.id {
                return false
            }
            
            // Skip inactive transactions
            guard transaction.isActive else { return false }
            
            let transactionComponents = calendar.dateComponents([.year, .month], from: transaction.date)
            return transactionComponents.year == targetComponents.year &&
                   transactionComponents.month == targetComponents.month
        }
    }
    
    func updateUsedAmount() {
        usedAmount = transactions
            .filter { $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.amount }
        updatedAt = Date()
    }
    
    // MARK: - Installment Helpers
    
    func configureInstallment(
        monthlyPayment: Decimal,
        totalAmount: Decimal,
        months: Int,
        startDate: Date
    ) {
        self.isInstallment = true
        self.monthlyPayment = monthlyPayment
        self.totalInstallmentAmount = totalAmount
        self.installmentMonths = months
        self.installmentStartDate = startDate
        
        // Calculate end date
        let calendar = Calendar.current
        self.installmentEndDate = calendar.date(
            byAdding: .month,
            value: months,
            to: startDate
        )
        
        self.updatedAt = Date()
    }
    
    var installmentProgress: Double {
        guard isInstallment,
              let total = totalInstallmentAmount,
              total > 0 else { return 0 }
        
        return Double(truncating: (usedAmount / total) as NSDecimalNumber)
    }
    
    var remainingInstallmentMonths: Int? {
        guard isInstallment,
              let endDate = installmentEndDate else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: Date(), to: endDate)
        return max(0, components.month ?? 0)
    }
}
