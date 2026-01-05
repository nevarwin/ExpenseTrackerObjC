//
//  Budget+CoreDataProperties.swift
//  ExpenseTracker
//
//  Created by raven on 6/26/25.
//

import Foundation
import CoreData

extension Budget {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Budget> {
        return NSFetchRequest<Budget>(entityName: "Budget")
    }
    
    @NSManaged public var createdAt: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var name: String?
    @NSManaged public var remainingAmount: NSDecimalNumber?
    @NSManaged public var totalAmount: NSDecimalNumber?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var category: NSSet?
    @NSManaged public var transactions: NSSet?
    
}

// MARK: Generated accessors for category
extension Budget {
    
    @objc(addCategoryObject:)
    @NSManaged public func addToCategory(_ value: Category)
    
    @objc(removeCategoryObject:)
    @NSManaged public func removeFromCategory(_ value: Category)
    
    @objc(addCategory:)
    @NSManaged public func addToCategory(_ values: NSSet)
    
    @objc(removeCategory:)
    @NSManaged public func removeFromCategory(_ values: NSSet)
    
}

// MARK: Generated accessors for transactions
extension Budget {
    
    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: Transaction)
    
    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: Transaction)
    
    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)
    
    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)
    
}

extension Budget : Identifiable {
    
}
