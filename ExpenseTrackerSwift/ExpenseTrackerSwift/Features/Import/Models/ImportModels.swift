//
//  ImportModels.swift
//  ExpenseTrackerSwift
//

import Foundation

/// Type of import operation
enum ImportType: String, CaseIterable, Identifiable {
    case transactions = "Transactions"
    case budgetTemplate = "Budget Template"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .transactions:
            return "arrow.down.doc.fill"
        case .budgetTemplate:
            return "chart.bar.doc.horizontal.fill"
        }
    }
    
    var description: String {
        switch self {
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
}
