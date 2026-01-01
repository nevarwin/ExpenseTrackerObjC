//
//  BudgetListViewModel.swift
//  ExpenseTracker
//
//  Created by raven on 8/4/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class BudgetListViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchBudgets()
    }
    
    func fetchBudgets() {
        let fetchRequest: NSFetchRequest<Budget> = Budget.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Budget.createdAt, ascending: false)]
        
        do {
            budgets = try context.fetch(fetchRequest)
        } catch {
            print("Error fetching budgets: \(error)")
        }
    }
    
    func deleteBudget(_ budget: Budget) {
        context.perform {
            budget.isActive = false
            
            if let transactions = budget.transactions as? Set<Transaction> {
                for transaction in transactions where transaction.isActive {
                    transaction.isActive = false
                }
            }
            
            do {
                try self.context.save()
                Task { @MainActor in
                    self.fetchBudgets()
                }
            } catch {
                print("Error deleting budget: \(error)")
            }
        }
    }
    
    func totalExpenses(for budget: Budget) -> Decimal {
        guard let categories = budget.category as? Set<Category> else { return 0 }
        return categories
            .filter { !$0.isIncome }
            .reduce(0) { $0 + ($1.allocatedAmount?.decimalValue ?? 0) }
    }
    
    func totalIncome(for budget: Budget) -> Decimal {
        guard let categories = budget.category as? Set<Category> else { return 0 }
        return categories
            .filter { $0.isIncome }
            .reduce(0) { $0 + ($1.allocatedAmount?.decimalValue ?? 0) }
    }
}

