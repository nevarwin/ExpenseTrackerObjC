//
//  CategoryFormViewModel.swift
//  ExpenseTracker
//
//  Created by raven on 10/13/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class CategoryFormViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var amount: String = ""
    @Published var isInstallment: Bool = false
    @Published var startDate: Date = Date()
    @Published var months: String = "1"
    @Published var monthlyPayment: String = ""
    
    private let context: NSManagedObjectContext
    let budget: Budget
    let isIncome: Bool
    let existingCategory: Category?
    let isEditMode: Bool
    
    init(context: NSManagedObjectContext, budget: Budget, isIncome: Bool, existingCategory: Category? = nil) {
        self.context = context
        self.budget = budget
        self.isIncome = isIncome
        self.existingCategory = existingCategory
        self.isEditMode = existingCategory != nil
        
        if let category = existingCategory {
            name = category.name ?? ""
            amount = category.totalInstallmentAmount?.stringValue ?? ""
            isInstallment = category.isInstallment
            startDate = category.installmentStartDate ?? Date()
            months = String(category.installmentMonths)
            monthlyPayment = category.monthlyPayment?.stringValue ?? ""
        }
    }
    
    func computeMonthlyAmount() {
        guard let monthsValue = Int(months),
              let amountValue = Double(amount),
              monthsValue > 0 else {
            monthlyPayment = ""
            return
        }
        
        let monthly = amountValue / Double(monthsValue)
        monthlyPayment = String(format: "%.2f", monthly)
    }
    
    func saveCategory() throws {
        guard !name.isEmpty,
              !amount.isEmpty,
              let amountValue = Decimal(string: amount),
              amountValue > 0 else {
            throw CategoryFormError.invalidInput
        }
        
        if isInstallment {
            guard !months.isEmpty,
                  !monthlyPayment.isEmpty,
                  Int(months) ?? 0 > 0 else {
                throw CategoryFormError.invalidInstallment
            }
        }
        
        // Check for duplicate category name
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        var predicates: [NSPredicate] = [
            NSPredicate(format: "budget == %@ AND name ==[c] %@", budget, name)
        ]
        
        if isEditMode, let existing = existingCategory {
            predicates.append(NSPredicate(format: "self != %@", existing))
        }
        
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let count = try context.count(for: fetchRequest)
        if count > 0 {
            throw CategoryFormError.duplicateName
        }
        
        let category = existingCategory ?? NSEntityDescription.insertNewObject(forEntityName: "Category", into: context) as! Category
        
        category.name = name
        category.isIncome = isIncome
        category.isInstallment = isInstallment
        category.allocatedAmount = isInstallment ? NSDecimalNumber(string: monthlyPayment) : NSDecimalNumber(decimal: amountValue)
        category.totalInstallmentAmount = NSDecimalNumber(decimal: amountValue)
        category.budget = budget
        
        if isInstallment {
            category.installmentStartDate = startDate
            category.installmentMonths = Int16(months) ?? 1
            
            let calendar = Calendar.current
            if let endDate = calendar.date(byAdding: .month, value: Int(category.installmentMonths), to: startDate) {
                category.installmentEndDate = endDate
            }
            
            category.monthlyPayment = NSDecimalNumber(string: monthlyPayment)
        }
        
        if !isEditMode {
            category.createdAt = Date()
            category.isActive = true
            category.usedAmount = NSDecimalNumber.zero
        }
        
        category.updatedAt = Date()
        
        try context.save()
    }
    
    enum CategoryFormError: LocalizedError {
        case invalidInput
        case invalidInstallment
        case duplicateName
        
        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "Category name and allocated amount are required."
            case .invalidInstallment:
                return "Please fill in all installment fields."
            case .duplicateName:
                return "Category already exists, please choose a different category title."
            }
        }
    }
}

