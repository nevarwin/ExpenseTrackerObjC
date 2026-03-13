import SwiftUI
import GRDB

@Observable
final class TransactionViewModel {
    var transactions: [Transaction] = []
    var availableCategories: [Category] = []
    var selectedCategory: Category?
    var errorMessage: String?
    var isLoading = false

    // Calendar State
    var selectedDate: Date = Date()
    var selectedDateRange: ClosedRange<Date>? = nil
    var isRangeMode: Bool = false
    var calendarScope: CalendarScope = .month
    var transactionDates: Set<Date> = []

    // Search State
    var searchText: String = ""
    var searchHighlightDates: Set<Date> = []

    // Derived Calendar Properties
    var currentYear: Int { Calendar.current.component(.year, from: selectedDate) }
    var currentMonth: Int { Calendar.current.component(.month, from: selectedDate) }

    private let transactionRepo: TransactionRepository
    private let categoryRepo: CategoryRepository

    init(
        transactionRepo: TransactionRepository = TransactionRepository(),
        categoryRepo: CategoryRepository = CategoryRepository()
    ) {
        self.transactionRepo = transactionRepo
        self.categoryRepo = categoryRepo
    }

    // MARK: - Filter Logic

    func loadTransactions(for budget: Budget? = nil) {
        isLoading = true
        errorMessage = nil

        let start: Date
        let end: Date

        if isRangeMode, let range = selectedDateRange {
            start = Calendar.current.startOfDay(for: range.lowerBound)
            end = Calendar.current.date(byAdding: .day, value: 1, to: range.upperBound)
                .map { Calendar.current.startOfDay(for: $0) } ?? Date.distantFuture
        } else {
            start = Calendar.current.startOfDay(for: selectedDate)
            end = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)
                .map { Calendar.current.startOfDay(for: $0) } ?? Date.distantFuture
        }

        do {
            let fetched = try transactionRepo.fetch(budgetId: budget?.id, start: start, end: end)
            // Resolve categories if budget provided
            let cats = budget.map { $0.categories } ?? []
            for txn in fetched {
                txn.budget = budget
                txn.category = cats.first { $0.id == txn.categoryId }
            }
            transactions = fetched
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
            if let newDate = Calendar.current.date(from: components) { selectedDate = newDate }
        }
        if !isRangeMode { loadTransactions() }
    }

    func selectDate(_ date: Date) {
        if isRangeMode {
            if let range = selectedDateRange {
                if range.lowerBound == range.upperBound {
                    selectedDateRange = date < range.lowerBound ? date...range.upperBound : range.lowerBound...date
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

    func loadAvailableCategories(transactionDate: Date, budget: Budget, excluding: Transaction? = nil) {
        do {
            let allCategories = try categoryRepo.fetchAll(budgetId: budget.id, isActive: true)
            availableCategories = allCategories.filter { $0.isValid(for: transactionDate) }
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
            availableCategories = []
        }
    }

    func checkOverflow(amount: Decimal, budget: Budget, category: Category, existing: Transaction? = nil) -> Bool {
        var currentUsed = category.usedAmount
        if let existing, existing.categoryId == category.id {
            currentUsed -= existing.amount
        }
        return (currentUsed + amount) > category.allocatedAmount
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
        // Adjust old category if category changed
        if let existing, let oldCatId = existing.categoryId, oldCatId != category.id {
            if let oldCat = budget.categories.first(where: { $0.id == oldCatId }) {
                oldCat.usedAmount -= existing.amount
                oldCat.updatedAt = Date()
                try categoryRepo.update(oldCat)
            }
        }

        // Adjust new category usage
        var newUsage = category.usedAmount
        if let existing, existing.categoryId == category.id {
            newUsage -= existing.amount
        }
        newUsage += amount
        category.usedAmount = newUsage
        category.updatedAt = Date()
        try categoryRepo.update(category)

        // Create or update transaction
        if let existing {
            existing.amount = amount
            existing.desc = description
            existing.date = date
            existing.budgetPeriod = budgetPeriod
            existing.budgetId = budget.id
            existing.categoryId = category.id
            existing.updatedAt = Date()
            try transactionRepo.update(existing)
        } else {
            let transaction = Transaction(
                amount: amount,
                description: description,
                date: date,
                budgetId: budget.id,
                categoryId: category.id,
                budget: budget,
                category: category,
                budgetPeriod: budgetPeriod
            )
            try transactionRepo.insert(transaction)
            transactions.insert(transaction, at: 0)
        }

        // Update budget remaining
        budget.updateRemainingAmount()
        try DatabaseService.shared.queue.write { db in try budget.update(db) }

        loadTransactions(for: budget)
    }

    func deleteTransaction(_ transaction: Transaction) throws {
        let budget = transaction.budget

        // Update category
        if let catId = transaction.categoryId,
           let category = budget?.categories.first(where: { $0.id == catId }) {
            category.usedAmount -= transaction.amount
            category.updatedAt = Date()
            try categoryRepo.update(category)
        }

        // Update budget
        budget?.updateRemainingAmount()
        if let budget {
            try DatabaseService.shared.queue.write { db in try budget.update(db) }
        }

        try transactionRepo.delete(id: transaction.id)
        loadTransactions(for: budget)
    }

    // MARK: - Calendar Data

    func loadTransactionDates(for budget: Budget? = nil) {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return }

        do {
            transactionDates = try transactionRepo.fetchDates(budgetId: budget?.id, monthStart: monthStart, monthEnd: monthEnd)
        } catch {
            print("Failed to load transaction dates: \(error)")
        }
    }

    func generateCalendarDays() -> [Date?] {
        let calendar = Calendar.current
        switch calendarScope {
        case .month:
            let components = DateComponents(year: currentYear, month: currentMonth)
            guard let startOfMonth = calendar.date(from: components),
                  let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return [] }
            let weekday = calendar.component(.weekday, from: startOfMonth)
            var days: [Date?] = Array(repeating: nil, count: weekday - 1)
            for day in 1...range.count {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                    days.append(date)
                }
            }
            return days

        case .week:
            guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) else { return [] }
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        }
    }

    func nextPage() {
        let component: Calendar.Component = calendarScope == .month ? .month : .weekOfYear
        if let newDate = Calendar.current.date(byAdding: component, value: 1, to: selectedDate) {
            selectedDate = newDate
            if !isRangeMode { loadTransactions() }
            loadTransactionDates()
        }
    }

    func previousPage() {
        let component: Calendar.Component = calendarScope == .month ? .month : .weekOfYear
        if let newDate = Calendar.current.date(byAdding: component, value: -1, to: selectedDate) {
            selectedDate = newDate
            if !isRangeMode { loadTransactions() }
            loadTransactionDates()
        }
    }

    func performGlobalSearch() {
        isLoading = true
        errorMessage = nil
        let text = searchText

        do {
            transactions = try transactionRepo.search(text: text)
            let dates = transactions.map { Calendar.current.startOfDay(for: $0.date) }
            searchHighlightDates = Set(dates)
        } catch {
            errorMessage = "Failed to search transactions: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

enum CalendarScope {
    case month
    case week
}
