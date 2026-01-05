//
//  Category+CoreDataProperties.swift
//  ExpenseTracker
//
//  Created by raven on 6/26/25.
//

import Foundation
import CoreData

extension Category {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }
    
    @NSManaged public var allocatedAmount: NSDecimalNumber?
    @NSManaged public var createdAt: Date?
    @NSManaged public var installmentEndDate: Date?
    @NSManaged public var installmentMonths: Int16
    @NSManaged public var installmentStartDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var isIncome: Bool
    @NSManaged public var isInstallment: Bool
    @NSManaged public var monthlyPayment: NSDecimalNumber?
    @NSManaged public var name: String?
    @NSManaged public var totalInstallmentAmount: NSDecimalNumber?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var usedAmount: NSDecimalNumber?
    @NSManaged public var budget: Budget?
    @NSManaged public var transactions: NSSet?
    
}

// MARK: Generated accessors for transactions
extension Category {
    
    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: Transaction)
    
    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: Transaction)
    
    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)
    
    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)
    
}

extension Category : Identifiable {
    
}
