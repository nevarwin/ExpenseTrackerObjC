import SwiftData
import Foundation

@Model
final class BudgetAllocation {
    var amount: Decimal
    var allocatedAt: Date
    var notes: String?
    
    init(amount: Decimal, notes: String? = nil) {
        self.amount = amount
        self.allocatedAt = Date()
        self.notes = notes
    }
}
