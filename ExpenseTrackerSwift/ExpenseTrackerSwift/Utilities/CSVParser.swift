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
}

struct CSVBudget {
    let name: String
    let items: [CSVBudgetItem]
}

struct CSVBudgetItem {
    let categoryName: String
    let amount: Decimal
    let isIncome: Bool
}

class CSVParser {
    static let shared = CSVParser()
    
    private init() {}
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy" // Matches "12/30/2025"
        return formatter
    }()
    
    func parseTransactions(from url: URL) throws -> [CSVTransaction] {
        guard let data = try? String(contentsOf: url) else {
            throw CSVParserError.fileReadFailed
        }
        
        let rows = data.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard rows.count > 2 else { return [] }
        
        // Skip first 2 header rows
        let dataRows = rows.dropFirst(2)
        var transactions: [CSVTransaction] = []
        
        for (index, row) in dataRows.enumerated() {
            let columns = parseCSVRow(row)
            
            // Debug: Print first row to verify columns
            if index == 0 {
                print("DEBUG: First row columns: \(columns)")
            }
            
            // Indices adjusted for empty first column (leading comma)
            // Expenses: 1 (Date), 2 (Amount), 3 (Desc), 4 (Category)
            
            // Parse Expense (Left side)
            if columns.indices.contains(4),
               let date = parseDate(columns[1]),
               let amount = parseCurrency(columns[2]),
               !columns[4].isEmpty {
                
                transactions.append(CSVTransaction(
                    date: date,
                    amount: amount,
                    description: columns[3],
                    category: columns[4],
                    isIncome: false
                ))
            } else if columns.indices.contains(1) && !columns[1].isEmpty {
                 // Debug failure
                 // print("DEBUG: Failed to parse expense row: \(columns)")
            }
            
            // Income: 6 (Date), 7 (Amount), 8 (Desc), 9 (Category)
            // Parse Income (Right side)
            if columns.indices.contains(9),
               let date = parseDate(columns[6]),
               let amount = parseCurrency(columns[7]),
               !columns[9].isEmpty {
                
                transactions.append(CSVTransaction(
                    date: date,
                    amount: amount,
                    description: columns[8],
                    category: columns[9],
                    isIncome: true
                ))
            }
        }
        
        return transactions
    }
    
    func parseBudget(from url: URL) throws -> CSVBudget {
        guard let data = try? String(contentsOf: url) else {
            throw CSVParserError.fileReadFailed
        }
        
        // Simple heuristic: Determine format based on content
        // Dec25.csv (Detailed) has "Planned" and "Diff." headers, and side-by-side tables
        // 13th25.csv (Simple) has simple Key-Value pairs
        
        let rows = data.components(separatedBy: .newlines)
        let filename = url.deletingPathExtension().lastPathComponent
        
        // Check for Dec25.csv format (complex summary)
        if data.contains("Planned") && data.contains("Actual") && data.contains("Diff.") {
            return parseComplexBudget(rows: rows, name: filename)
        } else {
            return parseSimpleBudget(rows: rows, name: filename)
        }
    }
    
    private func parseComplexBudget(rows: [String], name: String) -> CSVBudget {
        var items: [CSVBudgetItem] = []
        var parsingData = false
        
        for row in rows {
            let columns = parseCSVRow(row)
            
            // Start parsing after finding the sub-header row or just skip until we find data
            // Based on analysis: Row 24 starts data.
            // Heuristic: Look for row with "Totals" or verify if it's a data row
            
            // If col 1 has text and col 3 has amount -> Expense
            // If col 7 has text and col 9 has amount -> Income
            
            if columns.indices.contains(9) {
                // Check Expense (Left)
                // Col 1: Category Name, Col 3: Planned Amount
                if !columns[1].isEmpty && columns[1] != "Totals" && columns[1] != "Expenses" {
                    if let amount = parseCurrency(columns[3]), amount > 0 {
                        items.append(CSVBudgetItem(categoryName: columns[1], amount: amount, isIncome: false))
                    }
                }
                
                // Check Income (Right)
                // Col 7: Category Name, Col 9: Planned Amount
                if !columns[7].isEmpty && columns[7] != "Totals" && columns[7] != "Income" {
                    if let amount = parseCurrency(columns[9]), amount > 0 {
                        items.append(CSVBudgetItem(categoryName: columns[7], amount: amount, isIncome: true))
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
            
            // Expected: Col 1 (Category), Col 2 (Amount) -> indices 1 and 2
            // Note: csv often has empty first col if it was "Col B" in Excel
            
            if columns.indices.contains(2) {
                let categoryName = columns[1]
                let amountStr = columns[2]
                
                if !categoryName.isEmpty, let amount = parseCurrency(amountStr), amount > 0 {
                    // Assume expense by default for simple budget lists unless specified
                    // Or maybe check if name indicates income? For 13th25.csv it seems to be allocations.
                    items.append(CSVBudgetItem(categoryName: categoryName, amount: amount, isIncome: false))
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
