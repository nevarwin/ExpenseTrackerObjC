//
//  Transaction+CoreDataProperties.swift
//  ExpenseTracker
//
//  Created by raven on 6/26/25.
//

import Foundation
import CoreData

extension Transaction {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }
    
    @NSManaged public var amount: NSDecimalNumber?
    @NSManaged public var createdAt: Date?
    @NSManaged public var date: Date?
    @NSManaged public var desc: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var updatedAt: Date?
    @NSManaged public var budget: Budget?
    @NSManaged public var category: Category?
    
}

extension Transaction : Identifiable {
    
}
