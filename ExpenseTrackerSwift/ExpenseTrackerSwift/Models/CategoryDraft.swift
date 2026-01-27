import Foundation
import SwiftUI
import Combine

/// Temporary model for category data during budget creation/editing
/// Used to hold category information before persisting to SwiftData
/// Temporary model for category data during budget creation/editing
/// Used to hold category information before persisting to SwiftData
struct CategoryDraft: Identifiable {
    let id: UUID
    var name: String
    var allocatedAmount: String
    var isIncome: Bool
    var isInstallment: Bool
    var totalInstallmentAmount: String
    var installmentMonths: String
    var installmentStartDate: Date
    var originalCategory: Category?
    var isActive: Bool
    
    init(id: UUID = UUID(), 
         name: String = "", 
         allocatedAmount: String = "0", 
         isIncome: Bool = false,
         isInstallment: Bool = false,
         totalInstallmentAmount: String = "0",
         installmentMonths: String = "12",
         installmentStartDate: Date = Date(),
         originalCategory: Category? = nil,
         isActive: Bool = true) {
        self.id = id
        self.name = name
        self.allocatedAmount = allocatedAmount
        self.isIncome = isIncome
        self.isInstallment = isInstallment
        self.totalInstallmentAmount = totalInstallmentAmount
        self.installmentMonths = installmentMonths
        self.installmentStartDate = installmentStartDate
        self.originalCategory = originalCategory
        self.isActive = isActive
    }
    
    /// Computed property to get Decimal value from string input
    var allocatedDecimal: Decimal {
        if isInstallment {
            let total = Decimal(string: totalInstallmentAmount) ?? 0
            let months = Decimal(string: installmentMonths) ?? 1
            return months > 0 ? total / months : 0
        }
        return Decimal(string: allocatedAmount) ?? 0
    }
    
    /// Validation: Check if the draft has valid data
    var isValid: Bool {
        if isInstallment {
           return !name.trimmingCharacters(in: .whitespaces).isEmpty &&
                  (Decimal(string: totalInstallmentAmount) ?? 0) > 0 &&
                  (Int(installmentMonths) ?? 0) > 0
        }
        return !name.trimmingCharacters(in: .whitespaces).isEmpty &&
               allocatedDecimal > 0
    }
}
