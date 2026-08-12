//
//  CSVExporter.swift
//  ExpenseTrackerSwift
//

import Foundation

final class CSVExporter {
    static let shared = CSVExporter()
    
    private init() {}
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter
    }()
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    /// Exports transactions into an Excel-compatible CSV string matching the original spreadsheet structure
    func exportToCSV(transactions: [Transaction], budgetName: String = "Export") -> String {
        var csvLines: [String] = []
        
        // Excel template headers
        csvLines.append(",Change or add categories by updating the Expenses and Income tables in the Summary sheet.,,,,,,,,")
        csvLines.append(",Expenses,,,,,Income,,,")
        csvLines.append("Date,Amount,Description,Category,,Date,Amount,Description,Category")
        
        let expenses = transactions.filter { !$0.isIncome && $0.isActive }
        let income = transactions.filter { $0.isIncome && $0.isActive }
        
        let maxRows = max(expenses.count, income.count)
        
        for i in 0..<maxRows {
            var expDateStr = ""
            var expAmountStr = ""
            var expDescStr = ""
            var expCatStr = ""
            
            if i < expenses.count {
                let tx = expenses[i]
                expDateStr = dateFormatter.string(from: tx.date)
                let num = NSDecimalNumber(decimal: tx.amount)
                expAmountStr = escapeCSVField(currencyFormatter.string(from: num) ?? "$\(tx.amount)")
                expDescStr = escapeCSVField(tx.formattedDescriptionForExport)
                expCatStr = escapeCSVField(tx.category?.name ?? "General")
            }
            
            var incDateStr = ""
            var incAmountStr = ""
            var incDescStr = ""
            var incCatStr = ""
            
            if i < income.count {
                let tx = income[i]
                incDateStr = dateFormatter.string(from: tx.date)
                let num = NSDecimalNumber(decimal: tx.amount)
                incAmountStr = escapeCSVField(currencyFormatter.string(from: num) ?? "$\(tx.amount)")
                incDescStr = escapeCSVField(tx.formattedDescriptionForExport)
                incCatStr = escapeCSVField(tx.category?.name ?? "Income")
            }
            
            let line = "\(expDateStr),\(expAmountStr),\(expDescStr),\(expCatStr),,\(incDateStr),\(incAmountStr),\(incDescStr),\(incCatStr)"
            csvLines.append(line)
        }
        
        return csvLines.joined(separator: "\n")
    }
    
    private func escapeCSVField(_ text: String) -> String {
        var sanitized = text
        // Prevent CSV Formula Injection (=, +, -, @)
        if let firstChar = sanitized.first, ["=", "+", "-", "@"].contains(firstChar) {
            sanitized = "'\(sanitized)"
        }
        if sanitized.contains(",") || sanitized.contains("\"") || sanitized.contains("\n") {
            let escaped = sanitized.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return sanitized
    }
}
