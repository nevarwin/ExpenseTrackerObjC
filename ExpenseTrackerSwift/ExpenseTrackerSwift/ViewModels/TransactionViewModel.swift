import SwiftUI
import SwiftData

@Observable
final class TransactionViewModel {
    var transactions: [Transaction] = []
    var availableCategories: [Category] = []
    var selectedCategory: Category?
    var amountOverflow = false
    var errorMessage: String?
    var isLoading = false
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadTransactions(for budget: Budget? = nil) {
        isLoading = true
        errorMessage = nil
        
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            var fetchedTransactions = try modelContext.fetch(descriptor)
            
            if let budget = budget {
                fetchedTransactions = fetchedTransactions.filter { $0.budget?.id == budget.id }
            }
            
            transactions = fetchedTransactions
        } catch {
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadAvailableCategories(
        transactionDate: Date,
        budget: Budget,
        excluding: Transaction? = nil
    ) {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { category in
                category.isActive == true
            }
        )
        
        do {
            let allCategories = try modelContext.fetch(descriptor)
            
            // Filter by budget and validation rules
            availableCategories = allCategories.filter { category in
                // Must belong to the same budget
                guard category.budget?.id == budget.id else { return false }
                
                // Check installment duplicate rule
                if category.isInstallment {
                    if category.hasTransactionInMonth(of: transactionDate, excluding: excluding) {
                        return false
                    }
                }
                
                // Check if category is valid for the date
                return category.isValid(for: transactionDate)
            }
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
            availableCategories = []
        }
    }
    
    func checkOverflow(
        amount: Decimal,
        budget: Budget,
        category: Category,
        existing: Transaction? = nil
    ) -> Bool {
        var currentUsed = category.usedAmount
        
        // If editing, subtract the previous amount from the usage
        if let existing = existing, let oldCategory = existing.category, oldCategory.id == category.id {
            currentUsed -= existing.amount
        }
        
        let totalUsed = currentUsed + amount
        return totalUsed > category.allocatedAmount
    }
    
    func saveTransaction(
        amount: Decimal,
        description: String,
        date: Date,
        budget: Budget,
        category: Category,
        existing: Transaction? = nil
    ) throws {
        // Update old category if editing and category changed
        if let existing = existing, 
           let oldCategory = existing.category, 
           oldCategory.id != category.id {
            oldCategory.usedAmount -= existing.amount
            oldCategory.updatedAt = Date()
        }
        
        // Prepare new category usage
        // Note: If we are editing in the SAME category, we need to adjust for the diff
        var newUsage = category.usedAmount
        if let existing = existing, 
           let oldCategory = existing.category, 
           oldCategory.id == category.id {
            newUsage -= existing.amount
        }
        newUsage += amount
        
        // Update category
        category.usedAmount = newUsage
        category.updatedAt = Date()
        
        // Create or update transaction
        if let existing = existing {
            existing.amount = amount
            existing.desc = description
            existing.date = date
            existing.budget = budget
            existing.category = category
            existing.updatedAt = Date()
        } else {
            let transaction = Transaction(
                amount: amount,
                description: description,
                date: date,
                budget: budget,
                category: category
            )
            modelContext.insert(transaction)
            transactions.insert(transaction, at: 0)
        }
        
        // Update budget remaining amount
        budget.updateRemainingAmount()
        
        try modelContext.save()
    }
    
    func deleteTransaction(_ transaction: Transaction) throws {
        // Store budget reference before deletion
        let budget = transaction.budget
        
        // Update category used amount
        if let category = transaction.category {
            category.usedAmount -= transaction.amount
            category.updatedAt = Date()
        }
        
        // Update budget
        budget?.updateRemainingAmount()
        
        modelContext.delete(transaction)
        try modelContext.save()
        
        // Reload transactions from database instead of manually manipulating array
        loadTransactions(for: budget)
    }
    
    func softDeleteTransaction(_ transaction: Transaction) throws {
        transaction.softDelete()
        
        // Update category used amount
        if let category = transaction.category {
            category.updateUsedAmount()
        }
        
        // Update budget
        transaction.budget?.updateRemainingAmount()
        
        try modelContext.save()
    }
}
