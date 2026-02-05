import Foundation
import SwiftData

enum ImportError: Error, LocalizedError {
    case budgetNotFound
    case dataPersistenceFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .budgetNotFound: return "Target budget not found."
        case .dataPersistenceFailed(let reason): return "Failed to save data: \(reason)"
        }
    }
}

class ImportManager {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Import Budget
    
    func importBudget(from csvBudget: CSVBudget) throws -> Budget {
        // 1. Check if budget exists, else create
        // We match by Name for now
        let budgetName = csvBudget.name
        var budget: Budget!
        
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> { $0.name == budgetName }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            budget = existing
        } else {
            // Calculate total amount from items? Or just start with 0 and let allocations define it?
            // The CSV doesn't explicitly give a total usually, but 13th25 had a "Sum".
            // Let's sum up income items as the Total Amount? Or just input 0.
            // For Dec25.csv, "Income" section had "Planned".
            
            let totalIncome = csvBudget.items
                .filter { $0.isIncome }
                .reduce(Decimal.zero) { $0 + $1.amount }
                
            let totalInitial = totalIncome > 0 ? totalIncome : 0
            
            budget = Budget(name: budgetName, totalAmount: totalInitial)
            modelContext.insert(budget)
        }
        
        // 2. Process Categories
        for item in csvBudget.items {
            let categoryName = item.categoryName
            
            // Find or Create Category in this Budget
            // Note: SwiftData predicate limit on relationships can be tricky.
            // We'll iterate the budget's categories or fetch filtered.
            // Easier to fetch all categories for budget and filter in memory if list is small.
            // Or use direct relationship.
            
            let category: Category
            
            if let existingCategory = budget.categories.first(where: { $0.name.caseInsensitiveCompare(categoryName) == .orderedSame }) {
                category = existingCategory
                // Update allocation if imported
                if !item.isIncome {
                    category.allocatedAmount = item.amount
                }
            } else {
                category = Category(
                    name: categoryName,
                    allocatedAmount: item.isIncome ? 0 : item.amount,
                    isIncome: item.isIncome,
                    budget: budget
                )
                modelContext.insert(category)
                budget.categories.append(category) // Explicitly append if relationship needs it
            }
        }
        
        // Save
        do {
            try modelContext.save()
        } catch {
            throw ImportError.dataPersistenceFailed(error.localizedDescription)
        }
        
        return budget
    }
    
    // MARK: - Import Transactions
    
    func importTransactions(from csvTransactions: [CSVTransaction], into budget: Budget) throws -> Int {
        var count = 0
        
        // Cache categories for performance
        // (Re-fetch budget to ensure we have latest categories if just imported)
        // But `budget` object should be managed.
        
        let existingCategories = budget.categories
        
        print("DEBUG: Processing \(csvTransactions.count) transactions")
        for csvTx in csvTransactions {
            let categoryName = csvTx.category
            
            // 1. Find or Create Category
            // In transaction import, if category doesn't exist, we create it (with 0 allocation)
            let category: Category
            if let existing = existingCategories.first(where: { $0.name.caseInsensitiveCompare(categoryName) == .orderedSame }) {
                category = existing
            } else {
                print("DEBUG: Creating new category: \(categoryName)")
                category = Category(name: categoryName, allocatedAmount: 0, isIncome: csvTx.isIncome, budget: budget)
                modelContext.insert(category)
                budget.categories.append(category)
            }
            
            // 2. Create Transaction
            // Check Logic: Deduplication?
            // Simple check: Same date, same amount, same description.
            let alreadyExists = budget.transactions.contains { tx in
                Calendar.current.isDate(tx.date, inSameDayAs: csvTx.date) &&
                tx.amount == csvTx.amount &&
                tx.desc == csvTx.description
            }
            
            if alreadyExists {
                print("DEBUG: Skipping duplicate transaction: \(csvTx.description) - \(csvTx.amount)")
            }

            guard !alreadyExists else { continue }
            
            let transaction = Transaction(
                amount: csvTx.amount,
                description: csvTx.description,
                date: csvTx.date,
                budget: budget,
                category: category
            )
            modelContext.insert(transaction)
            
            // 3. Update Category Usage
            category.usedAmount += csvTx.amount
            category.updatedAt = Date()
            
            count += 1
        }
        print("DEBUG: Imported \(count) new transactions")
        
        // 4. Update Budget Totals
        budget.updateRemainingAmount()
        
        do {
            try modelContext.save()
        } catch {
            throw ImportError.dataPersistenceFailed(error.localizedDescription)
        }
        
        return count
    }
}
