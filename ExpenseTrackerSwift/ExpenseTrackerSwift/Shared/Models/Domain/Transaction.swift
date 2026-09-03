import SwiftData
import Foundation

@Model
final class Transaction {
    var amount: Decimal = 0
    var desc: String = ""
    var date: Date = Date()
    var budgetPeriod: Date = Date()
    var isActive: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Relationships
    var budget: Budget?
    var category: Category?
    var installmentPlan: InstallmentPlan?
    
    var installmentIndex: Int?
    var installmentTotalMonths: Int?
    
    init(
        amount: Decimal,
        description: String,
        date: Date,
        budget: Budget? = nil,
        category: Category? = nil,
        budgetPeriod: Date? = nil,
        installmentPlan: InstallmentPlan? = nil,
        installmentIndex: Int? = nil,
        installmentTotalMonths: Int? = nil
    ) {
        self.amount = amount
        self.desc = description
        self.date = date
        // Auto-assign budgetPeriod to the start of the transaction date's month if not provided
        self.budgetPeriod = budgetPeriod ?? date.monthBounds.start
        self.isActive = true
        self.budget = budget
        self.category = category
        self.installmentPlan = installmentPlan
        self.installmentIndex = installmentIndex
        self.installmentTotalMonths = installmentTotalMonths
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var isIncome: Bool {
        category?.isIncome ?? false
    }
    
    var iconName: String {
        if installmentPlan != nil {
            return "creditcard.fill"
        }
        if let category = category {
            return category.iconName
        }
        return CategoryIconHelper.iconName(for: desc, isIncome: isIncome)
    }
    
    var monthYear: String {
        date.formatted(.dateTime.month(.wide).year())
    }
    
    /// Formats description for CSV Export: "[Installment 13/24] Description" if linked to an installment
    var formattedDescriptionForExport: String {
        if let idx = installmentIndex, let total = installmentTotalMonths {
            return "[Installment \(idx)/\(total)] \(desc)"
        }
        return desc
    }
    
    // MARK: - Business Logic
    
    func softDelete() {
        isActive = false
        updatedAt = Date()
    }
    
}
