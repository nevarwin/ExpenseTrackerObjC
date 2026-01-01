//
//  TransactionsViewModel.swift
//  ExpenseTracker
//
//  Created by raven on 6/26/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var selectedTypeIndex: Int = 2 // 0: Expense, 1: Income, 2: All
    @Published var selectedWeekIndex: Int = 0
    @Published var currentDateComponents: DateComponents
    @Published var dateRange: String = ""
    
    private let context: NSManagedObjectContext
    private var fetchedResultsController: NSFetchedResultsController<Transaction>?
    
    init(context: NSManagedObjectContext) {
        self.context = context
        let calendar = Calendar.current
        let today = Date()
        self.currentDateComponents = calendar.dateComponents([.year, .month], from: today)
        
        setupFetchedResultsController()
    }
    
    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.createdAt, ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
            transactions = fetchedResultsController?.fetchedObjects ?? []
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    func updateFilters() {
        var predicates: [NSPredicate] = [NSPredicate(format: "isActive == YES")]
        
        // Type filter
        if selectedTypeIndex != 2 {
            let isIncome = selectedTypeIndex == 1
            predicates.append(NSPredicate(format: "category.isIncome == %@", NSNumber(value: isIncome)))
        }
        
        // Week filter
        if selectedWeekIndex >= 0 {
            let calendar = Calendar.current
            var cal = calendar
            cal.firstWeekday = 2 // Monday
            
            var components = DateComponents()
            components.year = currentDateComponents.year
            components.month = currentDateComponents.month
            components.day = 1
            
            guard let startOfMonth = cal.date(from: components) else { return }
            
            let weekday = cal.component(.weekday, from: startOfMonth)
            let daysToSubtract = (weekday == 1) ? 6 : (weekday - 2)
            guard let firstMonday = cal.date(byAdding: .day, value: -daysToSubtract, to: startOfMonth) else { return }
            
            guard let weekStart = cal.date(byAdding: .day, value: selectedWeekIndex * 7, to: firstMonday) else { return }
            guard let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart) else { return }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            let startString = formatter.string(from: weekStart)
            let endString = formatter.string(from: cal.date(byAdding: .day, value: -1, to: weekEnd) ?? weekEnd)
            
            dateRange = "From: \(startString) - \(endString)"
            
            predicates.append(NSPredicate(format: "date >= %@ AND date < %@", weekStart as NSDate, weekEnd as NSDate))
        }
        
        let fetchRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.createdAt, ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
            transactions = fetchedResultsController?.fetchedObjects ?? []
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        context.perform {
            transaction.isActive = false
            
            if let category = transaction.category,
               let usedAmount = category.usedAmount {
                category.usedAmount = usedAmount.subtracting(transaction.amount ?? 0)
                if category.usedAmount!.compare(NSDecimalNumber.zero) == .orderedAscending {
                    category.usedAmount = NSDecimalNumber.zero
                }
            }
            
            do {
                try self.context.save()
            } catch {
                print("Error deleting transaction: \(error)")
            }
        }
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
        updateFilters()
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
        updateFilters()
    }
    
    var monthYearString: String {
        let months = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        let monthIndex = (currentDateComponents.month ?? 1) - 1
        let year = currentDateComponents.year ?? 2025
        return "\(months[monthIndex]) \(year)"
    }
}

extension TransactionsViewModel: NSFetchedResultsControllerDelegate {
    nonisolated func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        Task { @MainActor in
            transactions = fetchedResultsController?.fetchedObjects ?? []
        }
    }
}

