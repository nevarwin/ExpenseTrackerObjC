//
//  Budget.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import Foundation
import SwiftData

@Model
class Budget {
    var id: UUID = UUID()
    var name: String = ""
    var startDate: Date = Date()
    var totalAmount: Decimal = 0
    var remainingAmount: Decimal = 0
    var isActive: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    @Relationship(deleteRule: .cascade, inverse: \Category.budget)
    var categories: [Category] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.budget)
    var transactions: [Transaction] = []
    
    init(
        name: String,
        startDate: Date? = nil,
        totalAmount: Decimal,
        remainingAmount: Decimal? = nil,
        isActive: Bool = true
    ) {
        self.name = name
        self.startDate = startDate ?? Date()
        self.totalAmount = totalAmount
        self.remainingAmount = remainingAmount ?? totalAmount
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
}
