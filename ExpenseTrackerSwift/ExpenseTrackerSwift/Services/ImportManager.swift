import Foundation

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

final class ImportManager {
    private let budgetRepo: BudgetRepository
    private let categoryRepo: CategoryRepository
    private let transactionRepo: TransactionRepository

    init(
        budgetRepo: BudgetRepository = BudgetRepository(),
        categoryRepo: CategoryRepository = CategoryRepository(),
        transactionRepo: TransactionRepository = TransactionRepository()
    ) {
        self.budgetRepo = budgetRepo
        self.categoryRepo = categoryRepo
        self.transactionRepo = transactionRepo
    }

    // MARK: - Import Budget

    func importBudget(from csvBudget: CSVBudget) throws -> Budget {
        let budgetName = csvBudget.name
        let budget: Budget

        // Find-or-create
        let existing = try budgetRepo.fetchAll().first(where: { $0.name == budgetName })
        if let existing {
            budget = existing
        } else {
            let totalIncome = csvBudget.items
                .filter { $0.isIncome }
                .reduce(Decimal.zero) { $0 + $1.plannedAmount }
            budget = Budget(name: budgetName, totalAmount: totalIncome > 0 ? totalIncome : 0)
            try budgetRepo.insert(budget)
        }

        // Process categories
        let existingCategories = try categoryRepo.fetchAll(budgetId: budget.id)
        for item in csvBudget.items {
            let categoryName = item.categoryName
            if let existing = existingCategories.first(where: { $0.name.caseInsensitiveCompare(categoryName) == .orderedSame }) {
                existing.allocatedAmount = item.plannedAmount
                try categoryRepo.update(existing)
            } else {
                let category = Category(
                    name: categoryName,
                    allocatedAmount: item.plannedAmount,
                    isIncome: item.isIncome,
                    budgetId: budget.id,
                    budget: budget
                )
                try categoryRepo.insert(category)
            }
        }

        return budget
    }

    // MARK: - Import Transactions

    private func parseBudgetPeriod(from filename: String) -> Date? {
        let calendar = Calendar.current
        let monthAbbreviations = ["jan","feb","mar","apr","may","jun",
                                  "jul","aug","sep","oct","nov","dec"]
        let lowerFilename = filename.lowercased()

        for (index, abbrev) in monthAbbreviations.enumerated() {
            if lowerFilename.hasPrefix(abbrev) {
                let yearPart = lowerFilename.dropFirst(abbrev.count)
                    .replacingOccurrences(of: "th", with: "")
                    .trimmingCharacters(in: .letters)
                if let year2Digit = Int(yearPart), year2Digit < 100 {
                    let fullYear = year2Digit < 50 ? 2000 + year2Digit : 1900 + year2Digit
                    return calendar.date(from: DateComponents(year: fullYear, month: index + 1, day: 1))
                }
            }
        }

        let monthNames = ["january","february","march","april","may","june",
                          "july","august","september","october","november","december"]
        for (index, monthName) in monthNames.enumerated() {
            if lowerFilename.hasPrefix(monthName) {
                let yearPart = lowerFilename.dropFirst(monthName.count).trimmingCharacters(in: .letters)
                if let fullYear = Int(yearPart) {
                    return calendar.date(from: DateComponents(year: fullYear, month: index + 1, day: 1))
                }
            }
        }

        return nil
    }

    func importTransactions(
        from csvTransactions: [CSVTransaction],
        into budget: Budget,
        filename: String? = nil,
        budgetPeriod overridePeriod: Date? = nil
    ) throws -> Int {
        var count = 0
        let existingCategories = try categoryRepo.fetchAll(budgetId: budget.id)
        let existingTransactions = try transactionRepo.fetchAll(budgetId: budget.id)

        for csvTx in csvTransactions {
            let categoryName = csvTx.category

            // Find or create category
            let category: Category
            if let existing = existingCategories.first(where: { $0.name.caseInsensitiveCompare(categoryName) == .orderedSame }) {
                category = existing
            } else {
                let newCat = Category(name: categoryName, allocatedAmount: 0, isIncome: csvTx.isIncome, budgetId: budget.id, budget: budget)
                try categoryRepo.insert(newCat)
                category = newCat
            }

            // Deduplication check
            let alreadyExists = existingTransactions.contains { tx in
                Calendar.current.isDate(tx.date, inSameDayAs: csvTx.date) &&
                tx.amount == csvTx.amount &&
                tx.desc == csvTx.description
            }
            guard !alreadyExists else { continue }

            // Determine budget period
            let budgetPeriod: Date
            if let overridePeriod {
                budgetPeriod = DateRangeHelper.monthBounds(for: overridePeriod).start
            } else if let filename, let parsedPeriod = parseBudgetPeriod(from: filename) {
                budgetPeriod = parsedPeriod
            } else {
                budgetPeriod = DateRangeHelper.monthBounds(for: csvTx.date).start
            }

            let transaction = Transaction(
                amount: csvTx.amount,
                description: csvTx.description,
                date: csvTx.date,
                budgetId: budget.id,
                categoryId: category.id,
                budget: budget,
                category: category,
                budgetPeriod: budgetPeriod
            )
            try transactionRepo.insert(transaction)

            category.usedAmount += csvTx.amount
            category.updatedAt = Date()
            try categoryRepo.update(category)

            count += 1
        }

        // Update budget remaining
        let allTransactions = try transactionRepo.fetchAll(budgetId: budget.id)
        let allCategories = try categoryRepo.fetchAll(budgetId: budget.id)
        budget.transactions = allTransactions
        for txn in allTransactions {
            txn.category = allCategories.first { $0.id == txn.categoryId }
        }
        budget.updateRemainingAmount()
        try budgetRepo.save(budget)

        return count
    }
}
