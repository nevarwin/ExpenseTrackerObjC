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

@MainActor
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
        var budgetCalculator: BudgetCalculator!
        
        if let existing = try? modelContext.fetch(descriptor).first {
            budget = existing
            if existing.startDate > startDate {
                existing.startDate = startDate
            }
        } else {
            budget = Budget(name: budgetName, startDate: startDate, totalAmount: 0)
            modelContext.insert(budget)
        }
        
        budgetCalculator = BudgetCalculator(budget: budget)
        
        for item in csvBudget.items {
            let categoryName = item.categoryName
            let category: Category
            
            if let existingCategory = budget.categories.first(where: {
                $0.name.caseInsensitiveCompare(categoryName) == .orderedSame &&
                $0.budgetPeriod.isSameMonth(as: startDate)
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
            .filter { $0.isIncome && $0.isActive && $0.budgetPeriod.isSameMonth(as: startDate) }
            .reduce(Decimal.zero) { $0 + $1.allocatedAmount }
        if activeIncomeTotal > 0 {
            budget.totalAmount = activeIncomeTotal
        }
        
        budgetCalculator.updateRemainingAmount()
        
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
        let budgetCalculator = BudgetCalculator(budget: budget)
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
                $0.budgetPeriod.isSameMonth(as: budgetPeriod)
            }) {
                category = existing
            } else {
                let latestConfig = findLatestCategoryConfiguration(name: categoryName, before: budgetPeriod, budget: budget)
                let allocatedAmount = latestConfig?.allocatedAmount ?? 0
                
                category = Category(
                    name: categoryName,
                    allocatedAmount: allocatedAmount,
                    isIncome: csvTx.isIncome,
                    budgetPeriod: latestConfig?.period ?? budgetPeriod,
                    budget: budget
                )
                modelContext.insert(category)
                budget.categories.append(category)
            }
            
            // Handle Installment auto-linking if tagged
            var plan: InstallmentPlan? = nil
            if let totalMonths = csvTx.installmentTotalMonths, totalMonths > 0 {
                let cleanName = csvTx.cleanDescription
                let fetchDescriptor = FetchDescriptor<InstallmentPlan>()
                if let existingPlans = try? modelContext.fetch(fetchDescriptor),
                   let matched = existingPlans.first(where: { $0.name.caseInsensitiveCompare(cleanName) == .orderedSame && $0.totalMonths == totalMonths }) {
                    plan = matched
                } else {
                    let totalAmt = csvTx.amount * Decimal(totalMonths)
                    let newPlan = InstallmentPlan(
                        name: cleanName,
                        totalAmount: totalAmt,
                        monthlyAmount: csvTx.amount,
                        startDate: csvTx.date,
                        totalMonths: totalMonths
                    )
                    modelContext.insert(newPlan)
                    plan = newPlan
                }
            }
            
            let transaction = Transaction(
                amount: csvTx.amount,
                description: csvTx.cleanDescription,
                date: csvTx.date,
                budget: budget,
                category: category,
                budgetPeriod: budgetPeriod,
                installmentPlan: plan,
                installmentIndex: csvTx.installmentIndex,
                installmentTotalMonths: csvTx.installmentTotalMonths
            )
            modelContext.insert(transaction)
            if let plan = plan {
                plan.transactions.append(transaction)
            }
            
            category.usedAmount += csvTx.amount
            category.updatedAt = Date()
            
            count += 1
        }
        
        budgetCalculator.updateRemainingAmount()
        
        do {
            try modelContext.save()
        } catch {
            throw ImportError.dataPersistenceFailed(error.localizedDescription)
        }
        
        return count
    }
    
    func importCategories(from csvBudget: CSVBudget, into budget: Budget, for month: Date) throws {
        let budgetCalculator = BudgetCalculator(budget: budget)
        let normalizedMonth = month.monthBounds.start
        
        for item in csvBudget.items {
            let categoryName = item.categoryName
            
            if let existingCategory = budget.categories.first(where: {
                $0.name.caseInsensitiveCompare(categoryName) == .orderedSame &&
                $0.budgetPeriod.isSameMonth(as: normalizedMonth)
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
            .filter { $0.isIncome && $0.isActive && $0.budgetPeriod.isSameMonth(as: normalizedMonth) }
            .reduce(Decimal.zero) { $0 + $1.allocatedAmount }
        if activeIncomeTotal > 0 {
            budget.totalAmount = activeIncomeTotal
        }
        
        budgetCalculator.updateRemainingAmount()
        
        do {
            try modelContext.save()
        } catch {
            throw ImportError.dataPersistenceFailed(error.localizedDescription)
        }
    }
    
    private func findLatestCategoryConfiguration(name: String, before: Date, budget: Budget? = nil) -> (allocatedAmount: Decimal, period: Date)? {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.name == name && $0.budgetPeriod < before },
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
    
    // MARK: - Import XLSX Workbook
    
    func importFullXLSXWorkbook(from url: URL) throws -> ImportResult {
        let workbook = try XLSXParser.shared.parseWorkbook(from: url)
        
        var totalCategoriesImported = 0
        var totalTransactionsImported = 0
        var modifiedBudgets = Set<Budget>()
        
        let primaryBudgetName = "Monthly Budget"
        let primaryBudget = try getOrCreateBudget(named: primaryBudgetName)
        modifiedBudgets.insert(primaryBudget)
        
        for sheet in workbook.sheets {
            let sheetName = sheet.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowerName = sheetName.lowercased()
            
            if lowerName.hasPrefix("13th") {
                let yearStr = sheetName.suffix(2)
                let fullYear = Int(yearStr) != nil ? "20" + String(yearStr) : "2024"
                let budgetName = "13th Month Pay \(fullYear)"
                let targetBudget = try getOrCreateBudget(named: budgetName)
                modifiedBudgets.insert(targetBudget)
                
                let defaultDate = parseBudgetPeriod(from: sheetName) ?? Date()
                let txCount = try importXLSXTransactionsSheet(sheet, into: targetBudget, defaultPeriod: defaultDate)
                totalTransactionsImported += txCount
            } else if lowerName == "beacon computation" {
                let budgetName = "Beacon Computation"
                let targetBudget = try getOrCreateBudget(named: budgetName)
                modifiedBudgets.insert(targetBudget)
                
                let defaultDate = Date()
                let catCount = try importXLSXSummarySheet(sheet, into: targetBudget, budgetPeriod: defaultDate)
                totalCategoriesImported += catCount
            } else if lowerName.hasSuffix("ps") {
                guard let period = parseBudgetPeriod(from: sheetName) else { continue }
                let txCount = try importXLSXTransactionsSheet(sheet, into: primaryBudget, defaultPeriod: period)
                totalTransactionsImported += txCount
            } else {
                guard let period = parseBudgetPeriod(from: sheetName) else { continue }
                let catCount = try importXLSXSummarySheet(sheet, into: primaryBudget, budgetPeriod: period)
                totalCategoriesImported += catCount
            }
        }
        
        for budget in modifiedBudgets {
            let calculator = BudgetCalculator(budget: budget)
            calculator.updateRemainingAmount()
        }
        
        do {
            try modelContext.save()
        } catch {
            throw ImportError.dataPersistenceFailed(error.localizedDescription)
        }
        
        let message = "Successfully imported full workbook: \(totalCategoriesImported) category allocations and \(totalTransactionsImported) transactions across \(modifiedBudgets.count) budget(s)."
        
        return ImportResult(
            success: true,
            message: message,
            importedCount: totalTransactionsImported + totalCategoriesImported,
            fileCount: workbook.sheets.count,
            errorDescription: nil
        )
    }
    
    private func getOrCreateBudget(named name: String) throws -> Budget {
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate<Budget> { $0.name == name }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        } else {
            let newBudget = Budget(name: name, startDate: Date(), totalAmount: 0)
            modelContext.insert(newBudget)
            return newBudget
        }
    }
    
    private func importXLSXSummarySheet(_ sheet: XLSXSheet, into budget: Budget, budgetPeriod: Date) throws -> Int {
        let normalizedPeriod = budgetPeriod.monthBounds.start
        var importedCategoriesCount = 0
        
        for row in 28...45 {
            if let catNameCell = sheet.cell(row: row, column: 2),
               let catName = catNameCell.value?.trimmingCharacters(in: .whitespacesAndNewlines),
               !catName.isEmpty,
               catName.caseInsensitiveCompare("Totals") != .orderedSame,
               catName.caseInsensitiveCompare("Expenses") != .orderedSame {
                
                let plannedAmount = sheet.cell(row: row, column: 4)?.decimalValue ?? 0
                updateOrCreateCategory(name: catName, plannedAmount: plannedAmount, isIncome: false, budgetPeriod: normalizedPeriod, into: budget)
                importedCategoriesCount += 1
            }
            
            if let catNameCell = sheet.cell(row: row, column: 8),
               let catName = catNameCell.value?.trimmingCharacters(in: .whitespacesAndNewlines),
               !catName.isEmpty,
               catName.caseInsensitiveCompare("Totals") != .orderedSame,
               catName.caseInsensitiveCompare("Income") != .orderedSame {
                
                let plannedAmount = sheet.cell(row: row, column: 10)?.decimalValue ?? 0
                updateOrCreateCategory(name: catName, plannedAmount: plannedAmount, isIncome: true, budgetPeriod: normalizedPeriod, into: budget)
                importedCategoriesCount += 1
            }
        }
        
        return importedCategoriesCount
    }
    
    private func updateOrCreateCategory(name: String, plannedAmount: Decimal, isIncome: Bool, budgetPeriod: Date, into budget: Budget) {
        let (isInstallment, cleanName) = parseInstallmentCategoryName(from: name)
        let categoryName = cleanName.isEmpty ? name : cleanName
        
        let category: Category
        if let existing = budget.categories.first(where: {
            $0.name.caseInsensitiveCompare(categoryName) == .orderedSame &&
            $0.budgetPeriod.isSameMonth(as: budgetPeriod)
        }) {
            existing.allocatedAmount = plannedAmount
            existing.isIncome = isIncome
            existing.isActive = true
            existing.updatedAt = Date()
            category = existing
        } else {
            let newCat = Category(
                name: categoryName,
                allocatedAmount: plannedAmount,
                isIncome: isIncome,
                budgetPeriod: budgetPeriod,
                budget: budget
            )
            modelContext.insert(newCat)
            budget.categories.append(newCat)
            category = newCat
        }
        
        if isInstallment && plannedAmount > 0 {
            ensureInstallmentPlanExists(name: categoryName, monthlyAmount: plannedAmount, startDate: budgetPeriod)
        }
    }
    
    @discardableResult
    private func ensureInstallmentPlanExists(name: String, monthlyAmount: Decimal, startDate: Date, totalMonths: Int = 24) -> InstallmentPlan {
        let fetchDescriptor = FetchDescriptor<InstallmentPlan>()
        if let existingPlans = try? modelContext.fetch(fetchDescriptor),
           let matched = existingPlans.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return matched
        }
        
        let totalAmt = monthlyAmount * Decimal(totalMonths)
        let newPlan = InstallmentPlan(
            name: name,
            totalAmount: totalAmt,
            monthlyAmount: monthlyAmount,
            startDate: startDate,
            totalMonths: totalMonths
        )
        modelContext.insert(newPlan)
        return newPlan
    }
    
    private func importXLSXTransactionsSheet(_ sheet: XLSXSheet, into budget: Budget, defaultPeriod: Date) throws -> Int {
        var count = 0
        let budgetPeriod = defaultPeriod.monthBounds.start
        
        let maxR = sheet.maxRow
        guard maxR >= 5 else { return 0 }
        
        for r in 5...maxR {
            if let amtCell = sheet.cell(row: r, column: 3),
               let amount = amtCell.decimalValue, amount > 0 {
                
                let date = sheet.cell(row: r, column: 2)?.dateValue ?? defaultPeriod
                let rawDesc = sheet.cell(row: r, column: 4)?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let catName = sheet.cell(row: r, column: 5)?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Uncategorized"
                
                if !catName.isEmpty && catName.caseInsensitiveCompare("Totals") != .orderedSame {
                    importSingleXLSXTransaction(
                        date: date,
                        amount: amount,
                        description: rawDesc,
                        categoryName: catName,
                        isIncome: false,
                        budgetPeriod: budgetPeriod,
                        into: budget
                    )
                    count += 1
                }
            }
            
            if let amtCell = sheet.cell(row: r, column: 8),
               let amount = amtCell.decimalValue, amount > 0 {
                
                let date = sheet.cell(row: r, column: 7)?.dateValue ?? defaultPeriod
                let rawDesc = sheet.cell(row: r, column: 9)?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let catName = sheet.cell(row: r, column: 10)?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Income"
                
                if !catName.isEmpty && catName.caseInsensitiveCompare("Totals") != .orderedSame {
                    importSingleXLSXTransaction(
                        date: date,
                        amount: amount,
                        description: rawDesc,
                        categoryName: catName,
                        isIncome: true,
                        budgetPeriod: budgetPeriod,
                        into: budget
                    )
                    count += 1
                }
            }
        }
        
        return count
    }
    
    func importSingleXLSXTransaction(
        date: Date,
        amount: Decimal,
        description: String,
        categoryName: String,
        isIncome: Bool,
        budgetPeriod: Date,
        into budget: Budget
    ) {
        let (isInstallmentCategory, cleanCatName) = parseInstallmentCategoryName(from: categoryName)
        let resolvedCategoryName = cleanCatName.isEmpty ? categoryName : cleanCatName
        
        let category: Category
        if let existing = budget.categories.first(where: {
            $0.name.caseInsensitiveCompare(resolvedCategoryName) == .orderedSame &&
            $0.budgetPeriod.isSameMonth(as: budgetPeriod)
        }) {
            category = existing
        } else {
            let latestConfig = findLatestCategoryConfiguration(name: resolvedCategoryName, before: budgetPeriod, budget: budget)
            let allocatedAmount = latestConfig?.allocatedAmount ?? 0
            
            category = Category(
                name: resolvedCategoryName,
                allocatedAmount: allocatedAmount,
                isIncome: isIncome,
                budgetPeriod: budgetPeriod,
                budget: budget
            )
            modelContext.insert(category)
            budget.categories.append(category)
        }
        
        var (idx, total, cleanDesc) = parseInstallmentTag(from: description)
        
        var plan: InstallmentPlan? = nil
        if let totalMonths = total, totalMonths > 0 {
            let fetchDescriptor = FetchDescriptor<InstallmentPlan>()
            if let existingPlans = try? modelContext.fetch(fetchDescriptor),
               let matched = existingPlans.first(where: { $0.name.caseInsensitiveCompare(cleanDesc) == .orderedSame && $0.totalMonths == totalMonths }) {
                plan = matched
            } else {
                let totalAmt = amount * Decimal(totalMonths)
                let newPlan = InstallmentPlan(
                    name: cleanDesc,
                    totalAmount: totalAmt,
                    monthlyAmount: amount,
                    startDate: date,
                    totalMonths: totalMonths
                )
                modelContext.insert(newPlan)
                plan = newPlan
            }
        } else if isInstallmentCategory {
            plan = ensureInstallmentPlanExists(name: resolvedCategoryName, monthlyAmount: amount, startDate: date)
            if let p = plan {
                idx = p.elapsedMonths(asOf: date)
                total = p.totalMonths
            }
        } else {
            let fetchDescriptor = FetchDescriptor<InstallmentPlan>()
            if let existingPlans = try? modelContext.fetch(fetchDescriptor),
               let matched = existingPlans.first(where: {
                   $0.name.caseInsensitiveCompare(resolvedCategoryName) == .orderedSame ||
                   $0.name.caseInsensitiveCompare(cleanDesc) == .orderedSame
               }) {
                plan = matched
                idx = matched.elapsedMonths(asOf: date)
                total = matched.totalMonths
            }
        }
        
        let budgetID = budget.id
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { $0.budget?.id == budgetID }
        )
        
        let existingTxs = (try? modelContext.fetch(descriptor)) ?? []
        var existingTx: Transaction? = nil
        for tx in existingTxs {
            if tx.amount == amount &&
               tx.desc == cleanDesc &&
               Calendar.current.isDate(tx.date, inSameDayAs: date) &&
               tx.budgetPeriod.isSameMonth(as: budgetPeriod) {
                existingTx = tx
                break
            }
        }
        
        if let existingTx = existingTx {
            existingTx.category = category
            existingTx.installmentPlan = plan
            existingTx.installmentIndex = idx
            existingTx.installmentTotalMonths = total
        } else {
            let transaction = Transaction(
                amount: amount,
                description: cleanDesc,
                date: date,
                budget: budget,
                category: category,
                budgetPeriod: budgetPeriod,
                installmentPlan: plan,
                installmentIndex: idx,
                installmentTotalMonths: total
            )
            modelContext.insert(transaction)
            if let plan = plan {
                plan.transactions.append(transaction)
            }
            category.usedAmount += amount
            category.updatedAt = Date()
        }
    }
    
    private func parseInstallmentCategoryName(from rawCategoryName: String) -> (isInstallment: Bool, cleanName: String) {
        let trimmed = rawCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^(?:installment[:\s-]*|\[installment\]\s*)(.*)$"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)) {
            if let nameRange = Range(match.range(at: 1), in: trimmed) {
                let clean = String(trimmed[nameRange]).trimmingCharacters(in: .whitespaces)
                if !clean.isEmpty {
                    return (true, clean)
                }
            }
            return (true, trimmed)
        }
        return (false, trimmed)
    }
    
    private func parseInstallmentTag(from rawDesc: String) -> (index: Int?, total: Int?, cleanDesc: String) {
        let pattern = #"^\[Installment\s+(\d+)/(\d+)\]\s*(.*)$"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: rawDesc, options: [], range: NSRange(location: 0, length: rawDesc.utf16.count)) {
            if let idxRange = Range(match.range(at: 1), in: rawDesc),
               let totalRange = Range(match.range(at: 2), in: rawDesc),
               let descRange = Range(match.range(at: 3), in: rawDesc),
               let idx = Int(rawDesc[idxRange]),
               let total = Int(rawDesc[totalRange]) {
                let clean = String(rawDesc[descRange]).trimmingCharacters(in: .whitespaces)
                return (idx, total, clean.isEmpty ? rawDesc : clean)
            }
        }
        return (nil, nil, rawDesc)
    }
}
