//
//  InstallmentPlan.swift
//  ExpenseTrackerSwift
//

import Foundation
import SwiftData

@Model
final class InstallmentPlan {
    var id: UUID = UUID()
    var name: String = ""
    var totalAmount: Decimal = 0
    var monthlyAmount: Decimal = 0
    var startDate: Date = Date()
    var totalMonths: Int = 24
    var notes: String = ""
    var isActive: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Transaction.installmentPlan)
    var transactions: [Transaction] = []
    
    init(
        name: String,
        totalAmount: Decimal,
        monthlyAmount: Decimal,
        startDate: Date,
        totalMonths: Int = 24,
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.totalAmount = totalAmount
        self.monthlyAmount = monthlyAmount
        self.startDate = startDate
        self.totalMonths = totalMonths
        self.notes = notes
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    
    /// Calculates the number of months elapsed from startDate up to reference date (defaulting to today)
    func elapsedMonths(asOf referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        let refComponents = calendar.dateComponents([.year, .month], from: referenceDate)
        
        let yearDiff = (refComponents.year ?? 0) - (startComponents.year ?? 0)
        let monthDiff = (refComponents.month ?? 0) - (startComponents.month ?? 0)
        
        let months = yearDiff * 12 + monthDiff + 1
        return max(1, min(totalMonths, months))
    }
    
    var remainingMonthsCount: Int {
        let elapsed = elapsedMonths()
        return max(0, totalMonths - elapsed)
    }
    
    var totalPaidAmount: Decimal {
        transactions.filter { $0.isActive }.reduce(0) { $0 + $1.amount }
    }
    
    var remainingBalance: Decimal {
        max(0, totalAmount - totalPaidAmount)
    }
    
    var progressPercentage: Double {
        guard totalMonths > 0 else { return 0.0 }
        return min(1.0, Double(elapsedMonths()) / Double(totalMonths))
    }
    
    var isCompleted: Bool {
        elapsedMonths() >= totalMonths || remainingBalance <= 0
    }
}
