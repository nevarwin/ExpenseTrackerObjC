//
//  BudgetDetailViewModel.swift
//  ExpenseTracker
//
//  Created by raven on 8/26/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class BudgetDetailViewModel: ObservableObject {
    @Published var budget: Budget
    @Published var expenseCategories: [Category] = []
    @Published var incomeCategories: [Category] = []
    @Published var currentDateComponents: DateComponents
    @Published var isBudgetSectionExpanded: Bool = true
    
    private let context: NSManagedObjectContext
    
    init(budget: Budget, context: NSManagedObjectContext) {
        self.budget = budget
        self.context = context
        let calendar = Calendar.current
        let today = Date()
        self.currentDateComponents = calendar.dateComponents([.year, .month], from: today)
        
        fetchCategories()
    }
    
    func fetchCategories() {
        guard let categories = budget.category as? Set<Category> else { return }
        
        let month = currentDateComponents.month ?? 1
        let year = currentDateComponents.year ?? 2025
        
        expenseCategories = []
        incomeCategories = []
        
        for category in categories {
            processCategory(category, month: month, year: year)
            
            if category.isActive {
                if category.isIncome {
                    incomeCategories.append(category)
                } else {
                    expenseCategories.append(category)
                }
            }
        }
    }
    
    private func processCategory(_ category: Category, month: Int, year: Int) {
        if let installmentEndDate = category.installmentEndDate {
            let calendar = Calendar.current
            let endComponents = calendar.dateComponents([.year, .month], from: installmentEndDate)
            let isWithinRange = (year < endComponents.year ?? 0) ||
                               (year == endComponents.year && month <= (endComponents.month ?? 0))
            
            if !isWithinRange {
                category.isActive = false
                return
            }
            category.isActive = true
        }
        
        guard let transactions = category.transactions as? Set<Transaction> else {
            category.usedAmount = NSDecimalNumber.zero
            return
        }
        
        let calendar = Calendar.current
        let activeTransactions = transactions.filter { transaction in
            guard transaction.isActive,
                  let date = transaction.date else { return false }
            let components = calendar.dateComponents([.month, .year], from: date)
            return components.month == month && components.year == year
        }
        
        let totalUsed = activeTransactions.reduce(NSDecimalNumber.zero) { result, transaction in
            result.adding(transaction.amount ?? NSDecimalNumber.zero)
        }
        
        category.usedAmount = totalUsed
    }
    
    func previousMonth() {
        var month = currentDateComponents.month ?? 1
        var year = currentDateComponents.year ?? 2025
        
        month -= 1
        if month < 1 {
            month = 12
            year -= 1
        }
        
        currentDateComponents.month = month
        currentDateComponents.year = year
        fetchCategories()
    }
    
    func nextMonth() {
        var month = currentDateComponents.month ?? 1
        var year = currentDateComponents.year ?? 2025
        
        month += 1
        if month > 12 {
            month = 1
            year += 1
        }
        
        currentDateComponents.month = month
        currentDateComponents.year = year
        fetchCategories()
    }
    
    var monthYearString: String {
        let months = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        let monthIndex = (currentDateComponents.month ?? 1) - 1
        let year = currentDateComponents.year ?? 2025
        return "\(months[monthIndex]) \(year)"
    }
    
    var totalExpenses: Decimal {
        expenseCategories.reduce(0) { $0 + ($1.allocatedAmount?.decimalValue ?? 0) }
    }
    
    var totalIncome: Decimal {
        incomeCategories.reduce(0) { $0 + ($1.allocatedAmount?.decimalValue ?? 0) }
    }
    
    var totalUsedBudget: Decimal {
        expenseCategories.reduce(0) { $0 + ($1.usedAmount?.decimalValue ?? 0) }
    }
    
    var remainingBudget: Decimal {
        totalIncome - totalUsedBudget
    }
    
    func saveBudget(name: String) {
        context.perform {
            self.budget.name = name
            self.budget.totalAmount = NSDecimalNumber(decimal: self.totalIncome)
            self.budget.updatedAt = Date()
            
            // Ensure all categories are linked to budget
            for category in self.expenseCategories {
                category.budget = self.budget
            }
            for category in self.incomeCategories {
                category.budget = self.budget
            }
            
            do {
                try self.context.save()
            } catch {
                print("Error saving budget: \(error)")
            }
        }
    }
}

