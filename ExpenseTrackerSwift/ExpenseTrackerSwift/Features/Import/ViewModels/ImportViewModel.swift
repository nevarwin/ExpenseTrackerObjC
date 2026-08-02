//
//  ImportViewModel.swift
//  ExpenseTrackerSwift
//

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class ImportViewModel {
    var isImporting = false
    var importResult: ImportResult? = nil
    var errorMessage: String? = nil
    var selectedImportType: ImportType = .transactions
    
    private let modelContext: ModelContext
    private let parser: CSVParser
    private let analyticsService: AnalyticsServiceProtocol
    
    init(
        modelContext: ModelContext,
        parser: CSVParser = CSVParser.shared,
        analyticsService: AnalyticsServiceProtocol = SharedAnalyticsService.instance
    ) {
        self.modelContext = modelContext
        self.parser = parser
        self.analyticsService = analyticsService
    }
    
    func importTransactionFiles(urls: [URL], into budget: Budget) {
        guard !urls.isEmpty else { return }
        
        isImporting = true
        errorMessage = nil
        importResult = nil
        
        var processedFiles: [(filename: String, transactions: [CSVTransaction])] = []
        var tempFileURLs: [URL] = []
        
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.copyItem(at: url, to: tempURL)
                tempFileURLs.append(tempURL)
                
                let transactions = try parser.parseTransactions(from: tempURL)
                processedFiles.append((url.lastPathComponent, transactions))
            } catch {
                print("Error processing transaction file \(url.lastPathComponent): \(error)")
            }
            
            url.stopAccessingSecurityScopedResource()
        }
        
        guard !processedFiles.isEmpty else {
            errorMessage = "Failed to parse any selected files."
            isImporting = false
            return
        }
        
        do {
            let manager = ImportManager(modelContext: modelContext)
            let totalCount = try manager.importBatchTransactions(files: processedFiles, into: budget)
            
            let message = totalCount > 0
                ? "Successfully imported \(totalCount) transactions from \(processedFiles.count) file(s)."
                : "No new transactions were imported. They might be duplicates."
            
            importResult = ImportResult(
                success: true,
                message: message,
                importedCount: totalCount,
                fileCount: processedFiles.count,
                errorDescription: nil
            )
            
            analyticsService.trackEvent("Transaction Import Success", properties: [
                "imported_count": totalCount,
                "file_count": processedFiles.count
            ])
        } catch {
            let errString = error.localizedDescription
            errorMessage = "Import failed: \(errString)"
            importResult = ImportResult(
                success: false,
                message: "Import operation failed.",
                importedCount: 0,
                fileCount: processedFiles.count,
                errorDescription: errString
            )
            analyticsService.trackEvent("Transaction Import Failed", properties: ["error": errString])
        }
        
        cleanupTempFiles(tempFileURLs)
        isImporting = false
    }
    
    func importBudgetFiles(urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        isImporting = true
        errorMessage = nil
        importResult = nil
        
        var processedBudgets: [CSVBudget] = []
        var tempFileURLs: [URL] = []
        
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else { continue }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.copyItem(at: url, to: tempURL)
                tempFileURLs.append(tempURL)
                
                let csvBudget = try parser.parseBudget(from: tempURL)
                processedBudgets.append(csvBudget)
            } catch {
                print("Error processing budget file \(url.lastPathComponent): \(error)")
            }
            
            url.stopAccessingSecurityScopedResource()
        }
        
        guard !processedBudgets.isEmpty else {
            errorMessage = "Failed to parse any selected budget template files."
            isImporting = false
            return
        }
        
        do {
            let manager = ImportManager(modelContext: modelContext)
            var count = 0
            for csvBudget in processedBudgets {
                _ = try manager.importBudget(from: csvBudget)
                count += csvBudget.items.count
            }
            
            let message = "Successfully imported \(count) category allocation(s) from \(processedBudgets.count) file(s)."
            importResult = ImportResult(
                success: true,
                message: message,
                importedCount: count,
                fileCount: processedBudgets.count,
                errorDescription: nil
            )
            
            analyticsService.trackEvent("Budget Template Import Success", properties: [
                "imported_categories": count,
                "file_count": processedBudgets.count
            ])
        } catch {
            let errString = error.localizedDescription
            errorMessage = "Import failed: \(errString)"
            importResult = ImportResult(
                success: false,
                message: "Budget import operation failed.",
                importedCount: 0,
                fileCount: processedBudgets.count,
                errorDescription: errString
            )
            analyticsService.trackEvent("Budget Template Import Failed", properties: ["error": errString])
        }
        
        cleanupTempFiles(tempFileURLs)
        isImporting = false
    }
    
    private func cleanupTempFiles(_ urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
