//
//  TransactionFormViewModel.swift
//  ExpenseTracker
//
//  Created by raven on 6/27/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class TransactionFormViewModel: ObservableObject {
    @Published var amount: String = ""
    @Published var description: String = ""
    @Published var date: Date = Date()
    @Published var selectedBudgetID: NSManagedObjectID?
    @Published var selectedCategoryID: NSManagedObjectID?
    @Published var selectedTypeIndex: Int = 3 // 3 means not selected
    @Published var budgets: [Budget] = []
    @Published var categories: [Category] = []
    
    private let context: NSManagedObjectContext
    let existingTransaction: Transaction?
    let isEditMode: Bool
    
    init(context: NSManagedObjectContext, existingTransaction: Transaction? = nil) {
        self.context = context
        self.existingTransaction = existingTransaction
        self.isEditMode = existingTransaction != nil
        
        if let transaction = existingTransaction {
            amount = transaction.amount?.stringValue ?? ""
            description = transaction.desc ?? ""
            date = transaction.date ?? Date()
            selectedBudgetID = transaction.budget?.objectID
            selectedCategoryID = transaction.category?.objectID
            selectedTypeIndex = transaction.category?.isIncome == true ? 1 : 0
        }
        
        fetchBudgets()
        if selectedBudgetID != nil {
            fetchCategories()
        }
    }
    
    func fetchBudgets() {
        let fetchRequest: NSFetchRequest<Budget> = Budget.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        
        do {
            budgets = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching budgets: \(error)")
        }
    }
    
    func fetchCategories() {
        guard let budgetID = selectedBudgetID else { return }
        
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        let isIncome = selectedTypeIndex == 1
        fetchRequest.predicate = NSPredicate(
            format: "budget == %@ AND isIncome == %@",
            context.object(with: budgetID),
            NSNumber(value: isIncome)
        )
        
        do {
            categories = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching categories: \(error)")
        }
    }
    
    func saveTransaction(ignoreExceeded: Bool = false) throws {
        guard let amountValue = Decimal(string: amount),
              amountValue > 0,
              let budgetID = selectedBudgetID,
              let categoryID = selectedCategoryID else {
            throw TransactionFormError.invalidInput
        }
        
        let transaction = isEditMode ? existingTransaction! :
            NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: context) as! Transaction
        
        // If editing, subtract old amount first
        if isEditMode, let oldCategory = existingTransaction?.category,
           let oldAmount = existingTransaction?.amount {
            let oldUsedAmount = oldCategory.usedAmount ?? NSDecimalNumber.zero
            oldCategory.usedAmount = oldUsedAmount.subtracting(oldAmount)
        }
        
        transaction.amount = NSDecimalNumber(decimal: amountValue)
        transaction.desc = description.isEmpty ? nil : description
        transaction.date = date
        transaction.budget = context.object(with: budgetID) as? Budget
        transaction.category = context.object(with: categoryID) as? Category
        transaction.updatedAt = Date()
        
        if !isEditMode {
            transaction.createdAt = Date()
            transaction.isActive = true
        }
        
        // Update category used amount
        if let category = transaction.category {
            let usedAmount = category.usedAmount ?? NSDecimalNumber.zero
            let newUsedAmount = usedAmount.adding(transaction.amount ?? NSDecimalNumber.zero)
            
            if !ignoreExceeded && newUsedAmount.compare(category.allocatedAmount ?? NSDecimalNumber.zero) == .orderedDescending {
                category.usedAmount = newUsedAmount
                throw TransactionFormError.amountExceeded
            } else {
                category.usedAmount = newUsedAmount
            }
        }
        
        try context.save()
    }
    
    enum TransactionFormError: LocalizedError {
        case invalidInput
        case amountExceeded
        
        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "Please fill all fields correctly."
            case .amountExceeded:
                return "The amount exceeds the budget allocated, but the transaction will still be saved."
            }
        }
    }
}

