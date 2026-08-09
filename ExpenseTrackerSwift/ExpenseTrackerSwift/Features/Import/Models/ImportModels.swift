//
//  ImportModels.swift
//  ExpenseTrackerSwift
//

import Foundation

/// Type of import operation
enum ImportType: String, CaseIterable, Identifiable {
    case fullWorkbook = "Full Excel Workbook (.xlsx)"
    case transactions = "Transactions"
    case budgetTemplate = "Budget Template"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .fullWorkbook:
            return "tablecells.fill"
        case .transactions:
            return "arrow.down.doc.fill"
        case .budgetTemplate:
            return "chart.bar.doc.horizontal.fill"
        }
    }
    
    var description: String {
        switch self {
        case .fullWorkbook:
            return "Import full monthly budget workbook containing all sheets, budget templates, and transaction records."
        case .transactions:
            return "Import transaction records from CSV files into a budget."
        case .budgetTemplate:
            return "Import category allocations and planned amounts from budget template CSV files."
        }
    }
}

/// Result payload for an import operation
struct ImportResult {
    let success: Bool
    let message: String
    let importedCount: Int
    let fileCount: Int
    let errorDescription: String?
    let wasCancelled: Bool
    
    init(
        success: Bool,
        message: String,
        importedCount: Int,
        fileCount: Int,
        errorDescription: String? = nil,
        wasCancelled: Bool = false
    ) {
        self.success = success
        self.message = message
        self.importedCount = importedCount
        self.fileCount = fileCount
        self.errorDescription = errorDescription
        self.wasCancelled = wasCancelled
    }
}
