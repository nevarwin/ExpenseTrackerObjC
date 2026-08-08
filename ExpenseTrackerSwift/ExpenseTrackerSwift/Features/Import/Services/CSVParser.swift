import Foundation

enum CSVParserError: Error, LocalizedError {
    case invalidFormat
    case fileReadFailed
    case parsingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat: return "The CSV file format is not recognized."
        case .fileReadFailed: return "Could not read the file."
        case .parsingFailed(let reason): return "Parsing failed: \(reason)"
        }
    }
}

struct CSVTransaction: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Decimal
    let description: String
    let category: String
    let isIncome: Bool
    let installmentIndex: Int?
    let installmentTotalMonths: Int?
    let cleanDescription: String
    
    init(
        date: Date,
        amount: Decimal,
        description: String,
        category: String,
        isIncome: Bool,
        installmentIndex: Int? = nil,
        installmentTotalMonths: Int? = nil,
        cleanDescription: String? = nil
    ) {
        self.date = date
        self.amount = amount
        self.description = description
        self.category = category
        self.isIncome = isIncome
        self.installmentIndex = installmentIndex
        self.installmentTotalMonths = installmentTotalMonths
        self.cleanDescription = cleanDescription ?? description
    }
}

struct CSVBudget {
    let name: String
    let items: [CSVBudgetItem]
}

struct CSVBudgetItem {
    let categoryName: String
    let plannedAmount: Decimal
    let actualAmount: Decimal
    let differenceAmount: Decimal
    let isIncome: Bool
    
    var amount: Decimal { plannedAmount }
}

class CSVParser {
    static let shared = CSVParser()
    
    private init() {}
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy" // Matches "12/30/2025"
        return formatter
    }()
    
    /// Helper to parse `[Installment 13/24] Laptop` tag pattern from description string
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
    
    func parseTransactions(from url: URL) throws -> [CSVTransaction] {
        guard let data = try? String(contentsOf: url, encoding: .utf8) else {
            throw CSVParserError.fileReadFailed
        }
        
        let rows = data.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard rows.count > 2 else { return [] }
        
        let dataRows = rows.dropFirst(2)
        var transactions: [CSVTransaction] = []
        
        for row in dataRows {
            let columns = parseCSVRow(row)
            
            // Determine offset for Left side (Expenses): 0 if column 0 is Date, 1 if column 1 is Date
            let offset: Int? = {
                if columns.indices.contains(0), parseDate(columns[0]) != nil {
                    return 0
                } else if columns.indices.contains(1), parseDate(columns[1]) != nil {
                    return 1
                }
                return nil
            }()
            
            // Parse Left side (Expenses)
            let expOffset = offset ?? (columns.indices.contains(0) && !columns[0].isEmpty ? 0 : 1)
            let expDateIdx = 0 + expOffset
            let expAmountIdx = 1 + expOffset
            let expDescIdx = 2 + expOffset
            let expCatIdx = 3 + expOffset
            
            if columns.indices.contains(expCatIdx),
               let date = parseDate(columns[expDateIdx]),
               let amount = parseCurrency(columns[expAmountIdx]),
               !columns[expCatIdx].isEmpty {
                
                let rawDesc = columns.indices.contains(expDescIdx) ? columns[expDescIdx] : ""
                let (idx, total, cleanDesc) = parseInstallmentTag(from: rawDesc)
                
                transactions.append(CSVTransaction(
                    date: date,
                    amount: amount,
                    description: rawDesc,
                    category: columns[expCatIdx],
                    isIncome: false,
                    installmentIndex: idx,
                    installmentTotalMonths: total,
                    cleanDescription: cleanDesc
                ))
            }
            
            // Parse Right side (Income)
            let incOffset = {
                if columns.indices.contains(5), parseDate(columns[5]) != nil {
                    return 0
                } else if columns.indices.contains(6), parseDate(columns[6]) != nil {
                    return 1
                }
                return offset ?? 0
            }()
            
            let incDateIdx = 5 + incOffset
            let incAmountIdx = 6 + incOffset
            let incDescIdx = 7 + incOffset
            let incCatIdx = 8 + incOffset
            
            if columns.indices.contains(incCatIdx),
               let date = parseDate(columns[incDateIdx]),
               let amount = parseCurrency(columns[incAmountIdx]),
               !columns[incCatIdx].isEmpty {
                
                let rawDesc = columns.indices.contains(incDescIdx) ? columns[incDescIdx] : ""
                let (idx, total, cleanDesc) = parseInstallmentTag(from: rawDesc)
                
                transactions.append(CSVTransaction(
                    date: date,
                    amount: amount,
                    description: rawDesc,
                    category: columns[incCatIdx],
                    isIncome: true,
                    installmentIndex: idx,
                    installmentTotalMonths: total,
                    cleanDescription: cleanDesc
                ))
            }
        }
        
        return transactions
    }
    
    func parseBudget(from url: URL) throws -> CSVBudget {
        guard let data = try? String(contentsOf: url, encoding: .utf8) else {
            throw CSVParserError.fileReadFailed
        }
        
        let rows = data.components(separatedBy: .newlines)
        let filename = url.deletingPathExtension().lastPathComponent
        
        if data.contains("Planned") && data.contains("Actual") && data.contains("Diff.") {
            return parseComplexBudget(rows: rows, name: filename)
        } else {
            return parseSimpleBudget(rows: rows, name: filename)
        }
    }
    
    private func parseComplexBudget(rows: [String], name: String) -> CSVBudget {
        var items: [CSVBudgetItem] = []
        
        for row in rows {
            let columns = parseCSVRow(row)
            
            if columns.indices.contains(3) {
                let expenseSub1 = columns.indices.contains(1) ? columns[1].trimmingCharacters(in: .whitespaces) : ""
                let expenseSub2 = columns.indices.contains(2) ? columns[2].trimmingCharacters(in: .whitespaces) : ""
                
                let expenseNameParts = [expenseSub1, expenseSub2].filter { !$0.isEmpty }
                let expenseName = expenseNameParts.joined(separator: " - ")
                
                if !expenseName.isEmpty && expenseSub1 != "Totals" && expenseSub1 != "Expenses" {
                    if let planned = parseCurrency(columns[3]), planned > 0 {
                        let actual = columns.indices.contains(4) ? (parseCurrency(columns[4]) ?? 0) : 0
                        let diff = columns.indices.contains(5) ? (parseCurrency(columns[5]) ?? 0) : 0
                        items.append(CSVBudgetItem(categoryName: expenseName, plannedAmount: planned, actualAmount: actual, differenceAmount: diff, isIncome: false))
                    }
                }
            }
            
            if columns.indices.contains(9) {
                let incomeSub1 = columns.indices.contains(7) ? columns[7].trimmingCharacters(in: .whitespaces) : ""
                let incomeSub2 = columns.indices.contains(8) ? columns[8].trimmingCharacters(in: .whitespaces) : ""
                
                let incomeNameParts = [incomeSub1, incomeSub2].filter { !$0.isEmpty }
                let incomeName = incomeNameParts.joined(separator: " - ")
                
                if !incomeName.isEmpty && incomeSub1 != "Totals" && incomeSub1 != "Income" {
                    if let planned = parseCurrency(columns[9]), planned > 0 {
                        let actual = columns.indices.contains(10) ? (parseCurrency(columns[10]) ?? 0) : 0
                        let diff = columns.indices.contains(11) ? (parseCurrency(columns[11]) ?? 0) : 0
                        items.append(CSVBudgetItem(categoryName: incomeName, plannedAmount: planned, actualAmount: actual, differenceAmount: diff, isIncome: true))
                    }
                }
            }
        }
        
        return CSVBudget(name: name, items: items)
    }
    
    private func parseSimpleBudget(rows: [String], name: String) -> CSVBudget {
        var items: [CSVBudgetItem] = []
        
        for row in rows {
            let columns = parseCSVRow(row)
            
            if columns.indices.contains(2) {
                let categoryName = columns[1]
                let amountStr = columns[2]
                
                if !categoryName.isEmpty, let amount = parseCurrency(amountStr), amount > 0 {
                    items.append(CSVBudgetItem(categoryName: categoryName, plannedAmount: amount, actualAmount: 0, differenceAmount: 0, isIncome: false))
                }
            }
        }
        
        return CSVBudget(name: name, items: items)
    }
    
    // MARK: - Helpers
    
    /// Parses a CSV row respecting quotes, e.g. "1,000" should be one token
    func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current)
        return result
    }
    
    private func parseCurrency(_ string: String) -> Decimal? {
        let clean = string.replacingOccurrences(of: "$", with: "")
                          .replacingOccurrences(of: ",", with: "")
                          .replacingOccurrences(of: "\"", with: "")
                          .trimmingCharacters(in: .whitespaces)
        return Decimal(string: clean)
    }
    
    private func parseDate(_ string: String) -> Date? {
        return dateFormatter.date(from: string.trimmingCharacters(in: .whitespaces))
    }
}
