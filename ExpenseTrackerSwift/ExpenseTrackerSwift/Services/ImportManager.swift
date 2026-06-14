import Foundation
import SwiftData

enum ImportError: Error, LocalizedError {
    case budgetNotFound
    case dataPersistenceFailed(String)
    case invalidFilenameForBudgetPeriod
    
    var errorDescription: String? {
        switch self {
        case .budgetNotFound: return "Target budget not found."
        case .dataPersistenceFailed(let reason): return "Failed to save data: \(reason)"
        case .invalidFilenameForBudgetPeriod: return "Could not determine the budget period from the filename. Ensure it contains a valid month and year (e.g., 'Dec25.csv')."
        }
    }
}

class ImportManager {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Import Budget
    
    private func extractBaseBudgetName(from filename: String) -> String {
        let monthNames = ["january", "february", "march", "april", "may", "june",
                          "july", "august", "september", "october", "november", "december"]
        let monthAbbreviations = ["jan", "feb", "mar", "apr", "may", "jun",
                                  "jul", "aug", "sep", "oct", "nov", "dec"]
        let extraAbbreviations = ["sept": 9]
        
        let monthGroup = "(" + (monthNames + monthAbbreviations + Array(extraAbbreviations.keys)).joined(separator: "|") + ")"
        let pattern = monthGroup + "[\\s_.-]*(\\d{4}|\\d{2})"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return filename
        }
        
        let nsRange = NSRange(filename.startIndex..<filename.endIndex, in: filename)
        if let match = regex.firstMatch(in: filename, options: [], range: nsRange) {
            let matchedRange = match.range
            var modifiedString = filename
            if let swiftRange = Range(matchedRange, in: filename) {
                modifiedString.removeSubrange(swiftRange)
            }
            let trimmed = modifiedString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "-_")))
            return trimmed.isEmpty ? "Monthly Budget" : trimmed
        }
        
        return filename
    }
    
    func importBudget(from csvBudget: CSVBudget) throws -> Budget {
        let filename = csvBudget.name
        let budgetName = extractBaseBudgetName(from: filename)
        let startDate = parseBudgetPeriod(from: filename) ?? Date()
        
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> { $0.name == budgetName }
        )
        
        var budget: Budget!
        if let existing = try? modelContext.fetch(descriptor).first {
            budget = existing
            if existing.startDate > startDate {
                existing.startDate = startDate
            }
        } else {
            budget = Budget(name: budgetName, startDate: startDate, totalAmount: 0)
            modelContext.insert(budget)
        }
        
        for item in csvBudget.items {
            let categoryName = item.categoryName
            let category: Category
            
            if let existingCategory = budget.categories.first(where: {
                $0.name.caseInsensitiveCompare(categoryName) == .orderedSame &&
                DateRangeHelper.isSameMonth($0.budgetPeriod, startDate)
            }) {
                category = existingCategory
                category.allocatedAmount = item.plannedAmount
                category.isIncome = item.isIncome
                category.isActive = true
                category.updatedAt = Date()
            } else {
                category = Category(
                    name: categoryName,
                    allocatedAmount: item.plannedAmount,
                    isIncome: item.isIncome,
                    budgetPeriod: startDate,
                    budget: budget
                )
                modelContext.insert(category)
                budget.categories.append(category)
            }
        }
        
        let activeIncomeTotal = budget.categories
            .filter { $0.isIncome && $0.isActive && DateRangeHelper.isSameMonth($0.budgetPeriod, startDate) }
            .reduce(Decimal.zero) { $0 + $1.allocatedAmount }
        if activeIncomeTotal > 0 {
            budget.totalAmount = activeIncomeTotal
        }
        
        budget.updateRemainingAmount()
        
        do {
            try modelContext.save()
        } catch {
            throw ImportError.dataPersistenceFailed(error.localizedDescription)
        }
        
        return budget
    }
    
    // MARK: - Import Transactions
    
    private func parseBudgetPeriod(from filename: String) -> Date? {
        let calendar = Calendar.current
        let lowerFilename = filename.lowercased()
        
        let monthNames = ["january", "february", "march", "april", "may", "june",
                          "july", "august", "september", "october", "november", "december"]
        let monthAbbreviations = ["jan", "feb", "mar", "apr", "may", "jun",
                                  "jul", "aug", "sep", "oct", "nov", "dec"]
        let extraAbbreviations = ["sept": 9]
        
        let monthGroup = "(" + (monthNames + monthAbbreviations + Array(extraAbbreviations.keys)).joined(separator: "|") + ")"
        let pattern = monthGroup + "[\\s_.-]*(\\d{4}|\\d{2})"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let nsRange = NSRange(lowerFilename.startIndex..<lowerFilename.endIndex, in: lowerFilename)
        
        if let match = regex.firstMatch(in: lowerFilename, options: [], range: nsRange) {
            guard let monthRange = Range(match.range(at: 1), in: lowerFilename),
                  let yearRange = Range(match.range(at: 2), in: lowerFilename) else {
                return nil
            }
            
            let monthStr = String(lowerFilename[monthRange])
            let yearStr = String(lowerFilename[yearRange])
            
            let monthIndex: Int
            if let index = monthNames.firstIndex(of: monthStr) {
                monthIndex = index + 1
            } else if let index = monthAbbreviations.firstIndex(of: monthStr) {
                monthIndex = index + 1
            } else if let customIndex = extraAbbreviations[monthStr] {
                monthIndex = customIndex
            } else {
                return nil
            }
            
            guard let yearInt = Int(yearStr) else { return nil }
            let fullYear: Int
            if yearInt < 100 {
                fullYear = yearInt < 50 ? 2000 + yearInt : 1900 + yearInt
            } else {
                fullYear = yearInt
            }
            
            let components = DateComponents(year: fullYear, month: monthIndex, day: 1)
            return calendar.date(from: components)
        }
        
        return nil
    }
    
    func importBatchTransactions(files: [(filename: String, transactions: [CSVTransaction])], into budget: Budget) throws -> Int {
        var totalImported = 0
        for file in files {
            totalImported += try importTransactions(from: file.transactions, into: budget, filename: file.filename)
        }
        return totalImported
    }
    
    func importTransactions(from csvTransactions: [CSVTransaction], into budget: Budget, filename: String) throws -> Int {
        var count = 0
        
        guard let parsedPeriod = parseBudgetPeriod(from: filename) else {
            throw ImportError.invalidFilenameForBudgetPeriod
        }
        let budgetPeriod: Date = parsedPeriod
        
        for csvTx in csvTransactions {
            let categoryName = csvTx.category
            
            let category: Category
            if let existing = budget.categories.first(where: {
                $0.name.caseInsensitiveCompare(categoryName) == .orderedSame &&
                DateRangeHelper.isSameMonth($0.budgetPeriod, budgetPeriod)
            }) {
                category = existing
            } else {
                let latestConfig = findLatestCategoryConfiguration(name: categoryName, before: budgetPeriod, budget: budget)
                let allocatedAmount = latestConfig?.allocatedAmount ?? 0
                
                category = Category(
                    name: categoryName,
                    allocatedAmount: allocatedAmount,
                    isIncome: csvTx.isIncome,
                    budgetPeriod: budgetPeriod,
                    budget: budget
                )
                modelContext.insert(category)
                budget.categories.append(category)
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
            
            category.usedAmount += csvTx.amount
            category.updatedAt = Date()
            
            count += 1
        }
        
        budget.updateRemainingAmount()
        
        do {
            try modelContext.save()
        } catch {
            throw ImportError.dataPersistenceFailed(error.localizedDescription)
        }
        
        return count
    }
    
    func importCategories(from csvBudget: CSVBudget, into budget: Budget, for month: Date) throws {
        let normalizedMonth = DateRangeHelper.monthBounds(for: month).start
        
        for item in csvBudget.items {
            let categoryName = item.categoryName
            
            if let existingCategory = budget.categories.first(where: {
                $0.name.caseInsensitiveCompare(categoryName) == .orderedSame &&
                DateRangeHelper.isSameMonth($0.budgetPeriod, normalizedMonth)
            }) {
                existingCategory.allocatedAmount = item.plannedAmount
                existingCategory.isIncome = item.isIncome
                existingCategory.isActive = true
                existingCategory.updatedAt = Date()
            } else {
                let category = Category(
                    name: categoryName,
                    allocatedAmount: item.plannedAmount,
                    isIncome: item.isIncome,
                    budgetPeriod: normalizedMonth,
                    budget: budget
                )
                modelContext.insert(category)
                budget.categories.append(category)
            }
        }
        
        let activeIncomeTotal = budget.categories
            .filter { $0.isIncome && $0.isActive && DateRangeHelper.isSameMonth($0.budgetPeriod, normalizedMonth) }
            .reduce(Decimal.zero) { $0 + $1.allocatedAmount }
        if activeIncomeTotal > 0 {
            budget.totalAmount = activeIncomeTotal
        }
        
        budget.updateRemainingAmount()
        
        do {
            try modelContext.save()
        } catch {
            throw ImportError.dataPersistenceFailed(error.localizedDescription)
        }
    }
    
    private func findLatestCategoryConfiguration(name: String, before: Date, budget: Budget) -> (allocatedAmount: Decimal, period: Date)? {
        let budgetID = budget.id
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.name == name && $0.budgetPeriod < before && $0.budget?.id == budgetID },
            sortBy: [SortDescriptor(\.budgetPeriod, order: .reverse)]
        )
        
        do {
            if let latest = try modelContext.fetch(descriptor).first {
                return (latest.allocatedAmount, latest.budgetPeriod)
            }
        } catch {
        }
        return nil
    }
}
