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
    
    init(id: UUID = UUID(), name: String = "", allocatedAmount: String = "0", isIncome: Bool = false) {
        self.id = id
        self.name = name
        self.allocatedAmount = allocatedAmount
        self.isIncome = isIncome
    }
    
    /// Computed property to get Decimal value from string input
    var allocatedDecimal: Decimal {
        Decimal(string: allocatedAmount) ?? 0
    }
    
    /// Validation: Check if the draft has valid data
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        allocatedDecimal > 0
    }
}
