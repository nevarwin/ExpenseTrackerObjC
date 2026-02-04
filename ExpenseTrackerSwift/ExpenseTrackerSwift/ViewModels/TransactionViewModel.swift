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
    
    // Calendar State
    var selectedDate: Date = Date() // Main focus date (or start of single selection)
    var selectedDateRange: ClosedRange<Date>? = nil // For range selection
    var isRangeMode: Bool = false
    
    // Derived Calendar Properties
    var currentYear: Int {
        Calendar.current.component(.year, from: selectedDate)
    }
    
    var currentMonth: Int {
        Calendar.current.component(.month, from: selectedDate)
    }
    
    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        if isRangeMode, let range = selectedDateRange {
            return "\(formatter.string(from: range.lowerBound)) - \(formatter.string(from: range.upperBound))"
        } else {
            return formatter.string(from: selectedDate)
        }
    }
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Filter Logic
    
    func loadTransactions(for budget: Budget? = nil) {
        isLoading = true
        errorMessage = nil
        
        let transactionPredicate: Predicate<Transaction>
        let budgetID = budget?.id
        
        // Calculate effective start and end dates
        let start: Date
        let end: Date
        
        if isRangeMode, let range = selectedDateRange {
            start = Calendar.current.startOfDay(for: range.lowerBound)
            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: range.upperBound) {
                 end = Calendar.current.startOfDay(for: nextDay)
            } else {
                end = Date.distantFuture // Fallback
            }
        } else {
            // Single date mode: From start of selectedDate to start of next day
            start = Calendar.current.startOfDay(for: selectedDate)
            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
                end = Calendar.current.startOfDay(for: nextDay)
            } else {
                end = Date.distantFuture
            }
        }
        
        if let budgetID {
             transactionPredicate = #Predicate<Transaction> { transaction in
                transaction.isActive == true &&
                transaction.budget?.id == budgetID &&
                transaction.date >= start &&
                transaction.date < end
            }
        } else {
             transactionPredicate = #Predicate<Transaction> { transaction in
                transaction.isActive == true &&
                transaction.date >= start &&
                transaction.date < end
            }
        }
        
        let descriptor = FetchDescriptor<Transaction>(
            predicate: transactionPredicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            transactions = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Calendar Actions
    
    func updateMonth(year: Int, month: Int) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.year = year
        components.month = month
        // Try to keep the day, but clamp it if needed (e.g. Jan 31 -> Feb 28)
        // Calendar.date(from:) usually handles overflow by moving to next month, which we might want to avoid.
        // Better to set day = 1 if we are just switching months, OR handle it carefully.
        // For simple navigation, resetting to day 1 is safer, but user might find it annoying if they were on the 15th.
        // Let's try to keep the day, but use validDate check?
        // Actually, let's just create the date and let Calendar handle it, but maybe verify we are in the target month.
        
        if let newDate = Calendar.current.date(from: components) {
            selectedDate = newDate
        } else {
            // Fallback: Day 1
            components.day = 1
            if let newDate = Calendar.current.date(from: components) {
                selectedDate = newDate
            }
        }
        
        // If single mode, this updates the view.
        // If range mode, we might just be navigating the calendar view without changing selection yet?
        // For now, let's assume navigating updates the focus.
        if !isRangeMode {
            loadTransactions() // Reload for the new date
        }
    }
    
    func selectDate(_ date: Date) {
        if isRangeMode {
            if let range = selectedDateRange {
                // If we already have a range, are we starting a new one?
                // Or extending? Let's say: if we have a full range, reset. If we have partial?
                // Let's simplify: Range Selection typically involves Tap 1 (Start), Tap 2 (End).
                // But `selectedDateRange` is closed.
                // Let's implement a simple logic:
                // If we assume the user is building a range:
                // 1. If currently nil, set both to date.
                // 2. If we have a range where start == end (effectively one day selected), update end to new date.
                // 3. If we have a different range, reset to new start.
                
                if range.lowerBound == range.upperBound {
                    // Extending
                    if date < range.lowerBound {
                         selectedDateRange = date...range.upperBound
                    } else {
                         selectedDateRange = range.lowerBound...date
                    }
                } else {
                    // Resetting
                    selectedDateRange = date...date
                }
            } else {
                selectedDateRange = date...date
            }
        } else {
            selectedDate = date
            loadTransactions()
        }
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
        loadTransactions(for: budget)
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
        loadTransactions(for: transaction.budget)
    }
}
