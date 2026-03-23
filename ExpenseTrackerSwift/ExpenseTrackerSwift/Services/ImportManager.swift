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
                .reduce(Decimal.zero) { $0 + $1.plannedAmount }
                
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
                category.allocatedAmount = item.plannedAmount
            } else {
                category = Category(
                    name: categoryName,
                    allocatedAmount: item.plannedAmount,
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
    
    /// Parse budget period (month start date) from filename
    /// Supports formats like: "Dec25", "June24", "January2025", "transactions_Dec25", etc.
    private func parseBudgetPeriod(from filename: String) -> Date? {
        let calendar = Calendar.current
        let lowerFilename = filename.lowercased()
        
        // Month abbreviations and full names
        let monthNames = ["january", "february", "march", "april", "may", "june",
                          "july", "august", "september", "october", "november", "december"]
        let monthAbbreviations = ["jan", "feb", "mar", "apr", "may", "jun",
                                  "jul", "aug", "sep", "oct", "nov", "dec"]
        
        // Build regex pattern to match month followed by optional delimiters and year
        // e.g., (january|...|jan|...)[\s_-]*(\d{2}|\d{4})
        let monthGroup = "(" + (monthNames + monthAbbreviations).joined(separator: "|") + ")"
        let pattern = monthGroup + "[\\s_-]*(\\d{2}|\\d{4})"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let nsRange = NSRange(lowerFilename.startIndex..<lowerFilename.endIndex, in: lowerFilename)
        
        if let match = regex.firstMatch(in: lowerFilename, options: [], range: nsRange) {
            guard let monthRange = Range(match.range(at: 1), in: lowerFilename),
                  let yearRange = Range(match.range(at: 2), in: lowerFilename) else {
                return nil
            }
            
            let monthStr = String(lowerFilename[monthRange])
            let yearStr = String(lowerFilename[yearRange])
            
            // Determine month index (1-based)
            let monthIndex: Int
            if let index = monthNames.firstIndex(of: monthStr) {
                monthIndex = index + 1
            } else if let index = monthAbbreviations.firstIndex(of: monthStr) {
                monthIndex = index + 1
            } else {
                return nil
            }
            
            // Determine full year
            guard let yearInt = Int(yearStr) else { return nil }
            let fullYear: Int
            if yearInt < 100 {
                // Assume 20xx for 00-49, 19xx for 50-99
                fullYear = yearInt < 50 ? 2000 + yearInt : 1900 + yearInt
            } else {
                fullYear = yearInt
            }
            
            let components = DateComponents(year: fullYear, month: monthIndex, day: 1)
            return calendar.date(from: components)
        }
        
        return nil
    }
    
    /// Import transactions from multiple files simultaneously
    func importBatchTransactions(files: [(filename: String, transactions: [CSVTransaction])], into budget: Budget) throws -> Int {
        var totalImported = 0
        for file in files {
            // Note: we let parseBudgetPeriod handle the filename. If it fails,
            // importTransactions will fallback to the transaction's own date.
            totalImported += try importTransactions(from: file.transactions, into: budget, filename: file.filename, budgetPeriod: nil)
        }
        return totalImported
    }
    
    func importTransactions(from csvTransactions: [CSVTransaction], into budget: Budget, filename: String? = nil, budgetPeriod overridePeriod: Date? = nil) throws -> Int {
        var count = 0
        
        let existingCategories = budget.categories
        
        print("DEBUG: Processing \(csvTransactions.count) transactions")
        for csvTx in csvTransactions {
            let categoryName = csvTx.category
            
            // 1. Find or Create Category
            let category: Category
            if let existing = existingCategories.first(where: { $0.name.caseInsensitiveCompare(categoryName) == .orderedSame }) {
                category = existing
            } else {
                print("DEBUG: Creating new category: \(categoryName)")
                category = Category(name: categoryName, allocatedAmount: 0, isIncome: csvTx.isIncome, budget: budget)
                modelContext.insert(category)
                budget.categories.append(category)
            }
            
            // 2. Deduplication check
            let alreadyExists = budget.transactions.contains { tx in
                Calendar.current.isDate(tx.date, inSameDayAs: csvTx.date) &&
                tx.amount == csvTx.amount &&
                tx.desc == csvTx.description
            }
            
            if alreadyExists {
                print("DEBUG: Skipping duplicate transaction: \(csvTx.description) - \(csvTx.amount)")
            }

            guard !alreadyExists else { continue }
            
            // Determine budget period: user-selected > filename-parsed > transaction date
            let budgetPeriod: Date
            if let overridePeriod = overridePeriod {
                budgetPeriod = DateRangeHelper.monthBounds(for: overridePeriod).start
            } else if let filename = filename,
               let parsedPeriod = parseBudgetPeriod(from: filename) {
                budgetPeriod = parsedPeriod
            } else {
                budgetPeriod = DateRangeHelper.monthBounds(for: csvTx.date).start
            }
            
            let transaction = Transaction(
                amount: csvTx.amount,
                description: csvTx.description,
                date: csvTx.date,
                budget: budget,
                category: category,
                budgetPeriod: budgetPeriod
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
