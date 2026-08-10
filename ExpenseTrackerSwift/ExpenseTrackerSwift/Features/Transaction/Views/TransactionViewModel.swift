import SwiftUI
import SwiftData

@Observable
@MainActor
final class TransactionViewModel {

    // MARK: - Nested Types

    enum CalendarScope {
        case month
        case week
    }

    var transactions: [Transaction] = []
    var availableCategories: [Category] = []
    var selectedCategory: Category?
    var errorMessage: String?
    var isLoading = false
    
    // Calendar State
    var selectedDate: Date = Date() // Main focus date (or start of single selection)
    var selectedDateRange: ClosedRange<Date>? = nil // For range selection
    var isRangeMode: Bool = false
    var calendarScope: CalendarScope = .month
    var transactionDates: Set<Date> = []
    var incomeTransactionDates: Set<Date> = []
    var expenseTransactionDates: Set<Date> = []
    
    // Search State
    var searchText: String = ""
    var searchHighlightDates: Set<Date> = []
    
    // Financial Metrics for Active Selection
    var totalIncome: Decimal {
        transactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Decimal {
        transactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    
    var netBalance: Decimal {
        totalIncome - totalExpense
    }
    
    // Derived Calendar Properties
    var currentYear: Int {
        Calendar.current.component(.year, from: selectedDate)
    }
    
    var currentMonth: Int {
        Calendar.current.component(.month, from: selectedDate)
    }
    
    private let modelContext: ModelContext
    private let analyticsService: AnalyticsServiceProtocol
    
    init(
        modelContext: ModelContext,
        analyticsService: AnalyticsServiceProtocol = SharedAnalyticsService.instance
    ) {
        self.modelContext = modelContext
        self.analyticsService = analyticsService
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
        
        if let newDate = Calendar.current.date(from: components) {
            selectedDate = newDate
        } else {
            components.day = 1
            if let newDate = Calendar.current.date(from: components) {
                selectedDate = newDate
            }
        }
        
        if !isRangeMode {
            loadTransactions()
        }
        loadTransactionDates()
    }
    
    func selectDate(_ date: Date) {
        if isRangeMode {
            if let range = selectedDateRange {
                if range.lowerBound == range.upperBound {
                    if date < range.lowerBound {
                         selectedDateRange = date...range.upperBound
                    } else {
                         selectedDateRange = range.lowerBound...date
                    }
                } else {
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
        let budgetID = budget.id
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { category in
                category.isActive == true &&
                category.budget?.id == budgetID
            }
        )
        
        do {
            let categories = try modelContext.fetch(descriptor)
            
            availableCategories = categories.filter { category in
                category.isValid(for: transactionDate)
            }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
            availableCategories = []
        }
    }
    
    func checkOverflow(
        amount: Decimal,
        date: Date,
        budget: Budget,
        category: Category,
        existing: Transaction? = nil
    ) -> Bool {
        guard !category.isIncome else { return false }
        
        var currentUsed = category.usedAmountInMonth(date)
        
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
        budgetPeriod: Date,
        existing: Transaction? = nil
    ) throws {
        if let existing = existing, 
           let oldCategory = existing.category, 
           oldCategory.id != category.id {
            oldCategory.usedAmount -= existing.amount
            oldCategory.updatedAt = Date()
        }
        
        var newUsage = category.usedAmount
        if let existing = existing, 
           let oldCategory = existing.category, 
           oldCategory.id == category.id {
            newUsage -= existing.amount
        }
        newUsage += amount
        
        category.usedAmount = newUsage
        category.updatedAt = Date()
        
        if let existing = existing {
            existing.amount = amount
            existing.desc = description
            existing.date = date
            existing.budgetPeriod = budgetPeriod
            existing.budget = budget
            existing.category = category
            existing.updatedAt = Date()
            analyticsService.trackEvent("Transaction Updated")
        } else {
            let transaction = Transaction(
                amount: amount,
                description: description,
                date: date,
                budget: budget,
                category: category,
                budgetPeriod: budgetPeriod
            )
            modelContext.insert(transaction)
            transactions.insert(transaction, at: 0)
            analyticsService.trackEvent("Transaction Added")
        }
        
        let budgetCalculator = BudgetCalculator(budget: budget)
        budgetCalculator.updateRemainingAmount()
        
        try modelContext.save()
        loadTransactions(for: budget)
        loadTransactionDates(for: budget)
    }
    
    func deleteTransaction(_ transaction: Transaction) throws {
        let budget = transaction.budget
        
        if let category = transaction.category {
            category.usedAmount -= transaction.amount
            category.updatedAt = Date()
        }
        
        if let budget = budget {
            let budgetCalculator = BudgetCalculator(budget: budget)
            budgetCalculator.updateRemainingAmount()
        }
        
        modelContext.delete(transaction)
        try modelContext.save()
        
        analyticsService.trackEvent("Transaction Deleted")
        
        loadTransactions(for: budget)
        loadTransactionDates(for: budget)
    }
    
    // MARK: - Calendar Data
    
    func loadTransactionDates(for budget: Budget? = nil) {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return
        }
        
        let budgetID = budget?.id
        let descriptor: FetchDescriptor<Transaction>
        if let budgetID {
            descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate<Transaction> { transaction in
                    transaction.isActive == true &&
                    transaction.budget?.id == budgetID &&
                    transaction.date >= monthStart &&
                    transaction.date < monthEnd
                }
            )
        } else {
            descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate<Transaction> { transaction in
                    transaction.isActive == true &&
                    transaction.date >= monthStart &&
                    transaction.date < monthEnd
                }
            )
        }
        
        do {
            let fetchedTransactions = try modelContext.fetch(descriptor)
            var allDates = Set<Date>()
            var incDates = Set<Date>()
            var expDates = Set<Date>()
            
            for tx in fetchedTransactions {
                let day = calendar.startOfDay(for: tx.date)
                allDates.insert(day)
                if tx.isIncome {
                    incDates.insert(day)
                } else {
                    expDates.insert(day)
                }
            }
            
            transactionDates = allDates
            incomeTransactionDates = incDates
            expenseTransactionDates = expDates
        } catch {
            print("Failed to load transaction dates: \(error)")
        }
    }
    
    func generateCalendarDays(offset: Int = 0) -> [Date?] {
        let calendar = Calendar.current
        
        let component: Calendar.Component = calendarScope == .month ? .month : .weekOfYear
        guard let baseDate = calendar.date(byAdding: component, value: offset, to: selectedDate) else {
            return []
        }
        
        switch calendarScope {
        case .month:
            let year = calendar.component(.year, from: baseDate)
            let month = calendar.component(.month, from: baseDate)
            let components = DateComponents(year: year, month: month)
            guard let startOfMonth = calendar.date(from: components),
                  let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
                return []
            }
            
            let weekday = calendar.component(.weekday, from: startOfMonth) // 1 = Sun
            let offsetDays = weekday - 1
            
            var days: [Date?] = Array(repeating: nil, count: offsetDays)
            
            for day in 1...range.count {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                    days.append(date)
                }
            }
            
            let remaining = 42 - days.count
            if remaining > 0 {
                days.append(contentsOf: Array(repeating: nil, count: remaining))
            }
            return days
            
        case .week:
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: baseDate)) else {
                return []
            }
            
            var days: [Date?] = []
            for day in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: day, to: startOfWeek) {
                    days.append(date)
                }
            }
            return days
        }
    }
    
    func nextPage() {
        let calendar = Calendar.current
        let component: Calendar.Component = calendarScope == .month ? .month : .weekOfYear
        
        if let newDate = calendar.date(byAdding: component, value: 1, to: selectedDate) {
            selectedDate = newDate
            if !isRangeMode {
                loadTransactions()
            }
            loadTransactionDates()
        }
    }
    
    func previousPage() {
        let calendar = Calendar.current
        let component: Calendar.Component = calendarScope == .month ? .month : .weekOfYear
        
        if let newDate = calendar.date(byAdding: component, value: -1, to: selectedDate) {
            selectedDate = newDate
            if !isRangeMode {
                loadTransactions()
            }
            loadTransactionDates()
        }
    }
    
    func performGlobalSearch() {
        isLoading = true
        errorMessage = nil
        
        let text = searchText
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { transaction in
                transaction.isActive == true &&
                transaction.desc.localizedStandardContains(text)
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            transactions = try modelContext.fetch(descriptor)
            let dates = transactions.map { Calendar.current.startOfDay(for: $0.date) }
            searchHighlightDates = Set(dates)
        } catch {
            errorMessage = "Failed to search transactions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
