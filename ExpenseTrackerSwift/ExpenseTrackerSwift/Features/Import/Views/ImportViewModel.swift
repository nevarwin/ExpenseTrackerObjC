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
    var currentProgress: ImportProgress? = nil
    var importResult: ImportResult? = nil
    var errorMessage: String? = nil
    var selectedImportType: ImportType = .transactions
    
    private var importTask: Task<Void, Never>? = nil
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
    
    func cancelImport() {
        importTask?.cancel()
        modelContext.rollback()
        
        currentProgress = ImportProgress(
            stage: .cancelled,
            fractionCompleted: 1.0,
            currentFileName: currentProgress?.currentFileName,
            statusDetail: "Import cancelled by user. Partial database changes were rolled back.",
            processedCount: 0,
            totalCount: nil,
            canCancel: false
        )
        
        importResult = ImportResult(
            success: false,
            message: "Import was cancelled.",
            importedCount: 0,
            fileCount: 0,
            errorDescription: "Cancelled by user",
            wasCancelled: true
        )
        
        analyticsService.trackEvent("Import Cancelled", properties: [:])
    }
    
    func dismissLoading() {
        isImporting = false
        currentProgress = nil
    }
    
    func importTransactionFiles(urls: [URL], into budget: Budget) {
        guard !urls.isEmpty else { return }
        
        isImporting = true
        errorMessage = nil
        importResult = nil
        
        let initialFileName = urls.first?.lastPathComponent ?? ""
        currentProgress = ImportProgress(
            stage: .readingFile(filename: initialFileName),
            fractionCompleted: 0.1,
            currentFileName: initialFileName,
            statusDetail: "Reading transaction CSV files...",
            processedCount: 0,
            totalCount: urls.count,
            canCancel: true
        )
        
        importTask = Task {
            var processedFiles: [(filename: String, transactions: [CSVTransaction])] = []
            var tempFileURLs: [URL] = []
            
            for (index, url) in urls.enumerated() {
                if Task.isCancelled { break }
                
                let fileName = url.lastPathComponent
                currentProgress = ImportProgress(
                    stage: .readingFile(filename: fileName),
                    fractionCompleted: 0.1 + (Double(index) / Double(urls.count)) * 0.2,
                    currentFileName: fileName,
                    statusDetail: "Reading file \(index + 1) of \(urls.count)...",
                    processedCount: index,
                    totalCount: urls.count,
                    canCancel: true
                )
                
                guard url.startAccessingSecurityScopedResource() else { continue }
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    tempFileURLs.append(tempURL)
                    
                    currentProgress = ImportProgress(
                        stage: .parsingData(filename: fileName, current: index + 1, total: urls.count),
                        fractionCompleted: 0.3 + (Double(index + 1) / Double(urls.count)) * 0.2,
                        currentFileName: fileName,
                        statusDetail: "Parsing CSV transaction records...",
                        processedCount: index + 1,
                        totalCount: urls.count,
                        canCancel: true
                    )
                    
                    let transactions = try parser.parseTransactions(from: tempURL)
                    processedFiles.append((fileName, transactions))
                } catch {
                    print("Error processing transaction file \(fileName): \(error)")
                }
                
                url.stopAccessingSecurityScopedResource()
            }
            
            if Task.isCancelled {
                self.modelContext.rollback()
                self.cleanupTempFiles(tempFileURLs)
                return
            }
            
            guard !processedFiles.isEmpty else {
                self.errorMessage = "Failed to parse any selected files."
                self.currentProgress = ImportProgress(
                    stage: .failed(reason: "Failed to parse selected files."),
                    fractionCompleted: 1.0,
                    statusDetail: "Failed to parse any transaction records.",
                    canCancel: false
                )
                self.cleanupTempFiles(tempFileURLs)
                return
            }
            
            let totalTransactionsCount = processedFiles.reduce(0) { $0 + $1.transactions.count }
            currentProgress = ImportProgress(
                stage: .importingRecords(current: 0, total: totalTransactionsCount),
                fractionCompleted: 0.6,
                currentFileName: processedFiles.first?.filename,
                statusDetail: "Importing \(totalTransactionsCount) transaction(s) into budget '\(budget.name)'...",
                processedCount: 0,
                totalCount: totalTransactionsCount,
                canCancel: true
            )
            
            do {
                if Task.isCancelled {
                    self.modelContext.rollback()
                    self.cleanupTempFiles(tempFileURLs)
                    return
                }
                
                let manager = ImportManager(modelContext: self.modelContext)
                let totalCount = try await manager.importBatchTransactions(files: processedFiles, into: budget)
                
                if Task.isCancelled {
                    self.modelContext.rollback()
                    self.cleanupTempFiles(tempFileURLs)
                    return
                }
                
                currentProgress = ImportProgress(
                    stage: .savingDatabase,
                    fractionCompleted: 0.9,
                    currentFileName: nil,
                    statusDetail: "Saving transactions to storage...",
                    processedCount: totalCount,
                    totalCount: totalTransactionsCount,
                    canCancel: false
                )
                
                let message = totalCount > 0
                    ? "Successfully imported \(totalCount) transactions from \(processedFiles.count) file(s)."
                    : "No new transactions were imported. They might be duplicates."
                
                self.importResult = ImportResult(
                    success: true,
                    message: message,
                    importedCount: totalCount,
                    fileCount: processedFiles.count,
                    errorDescription: nil
                )
                
                currentProgress = ImportProgress(
                    stage: .completed,
                    fractionCompleted: 1.0,
                    currentFileName: nil,
                    statusDetail: message,
                    processedCount: totalCount,
                    totalCount: totalTransactionsCount,
                    canCancel: false
                )
                
                self.analyticsService.trackEvent("Transaction Import Success", properties: [
                    "imported_count": totalCount,
                    "file_count": processedFiles.count
                ])
            } catch {
                self.modelContext.rollback()
                let errString = error.localizedDescription
                self.errorMessage = "Import failed: \(errString)"
                self.importResult = ImportResult(
                    success: false,
                    message: "Import operation failed.",
                    importedCount: 0,
                    fileCount: processedFiles.count,
                    errorDescription: errString
                )
                self.currentProgress = ImportProgress(
                    stage: .failed(reason: errString),
                    fractionCompleted: 1.0,
                    statusDetail: errString,
                    canCancel: false
                )
                self.analyticsService.trackEvent("Transaction Import Failed", properties: ["error": errString])
            }
            
            self.cleanupTempFiles(tempFileURLs)
        }
    }
    
    func importBudgetFiles(urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        isImporting = true
        errorMessage = nil
        importResult = nil
        
        let initialFileName = urls.first?.lastPathComponent ?? ""
        currentProgress = ImportProgress(
            stage: .readingFile(filename: initialFileName),
            fractionCompleted: 0.1,
            currentFileName: initialFileName,
            statusDetail: "Reading budget template files...",
            processedCount: 0,
            totalCount: urls.count,
            canCancel: true
        )
        
        importTask = Task {
            var processedBudgets: [CSVBudget] = []
            var tempFileURLs: [URL] = []
            
            for (index, url) in urls.enumerated() {
                if Task.isCancelled { break }
                
                let fileName = url.lastPathComponent
                currentProgress = ImportProgress(
                    stage: .parsingData(filename: fileName, current: index + 1, total: urls.count),
                    fractionCompleted: 0.2 + (Double(index + 1) / Double(urls.count)) * 0.3,
                    currentFileName: fileName,
                    statusDetail: "Parsing budget template \(index + 1) of \(urls.count)...",
                    processedCount: index + 1,
                    totalCount: urls.count,
                    canCancel: true
                )
                
                guard url.startAccessingSecurityScopedResource() else { continue }
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    tempFileURLs.append(tempURL)
                    
                    let csvBudget = try self.parser.parseBudget(from: tempURL)
                    processedBudgets.append(csvBudget)
                } catch {
                    print("Error processing budget file \(fileName): \(error)")
                }
                
                url.stopAccessingSecurityScopedResource()
            }
            
            if Task.isCancelled {
                self.modelContext.rollback()
                self.cleanupTempFiles(tempFileURLs)
                return
            }
            
            guard !processedBudgets.isEmpty else {
                self.errorMessage = "Failed to parse any selected budget template files."
                self.currentProgress = ImportProgress(
                    stage: .failed(reason: "Failed to parse selected budget template files."),
                    fractionCompleted: 1.0,
                    statusDetail: "Failed to parse any budget template files.",
                    canCancel: false
                )
                self.cleanupTempFiles(tempFileURLs)
                return
            }
            
            do {
                if Task.isCancelled {
                    self.modelContext.rollback()
                    self.cleanupTempFiles(tempFileURLs)
                    return
                }
                
                let manager = ImportManager(modelContext: self.modelContext)
                var count = 0
                for (bIndex, csvBudget) in processedBudgets.enumerated() {
                    if Task.isCancelled { break }
                    
                    currentProgress = ImportProgress(
                        stage: .importingRecords(current: bIndex + 1, total: processedBudgets.count),
                        fractionCompleted: 0.5 + (Double(bIndex + 1) / Double(processedBudgets.count)) * 0.3,
                        currentFileName: csvBudget.name,
                        statusDetail: "Importing category allocations for '\(csvBudget.name)'...",
                        processedCount: bIndex + 1,
                        totalCount: processedBudgets.count,
                        canCancel: true
                    )
                    
                    _ = try manager.importBudget(from: csvBudget)
                    count += csvBudget.items.count
                }
                
                if Task.isCancelled {
                    self.modelContext.rollback()
                    self.cleanupTempFiles(tempFileURLs)
                    return
                }
                
                currentProgress = ImportProgress(
                    stage: .savingDatabase,
                    fractionCompleted: 0.9,
                    currentFileName: nil,
                    statusDetail: "Saving budget allocations to storage...",
                    processedCount: count,
                    totalCount: count,
                    canCancel: false
                )
                
                let message = "Successfully imported \(count) category allocation(s) from \(processedBudgets.count) file(s)."
                self.importResult = ImportResult(
                    success: true,
                    message: message,
                    importedCount: count,
                    fileCount: processedBudgets.count,
                    errorDescription: nil
                )
                
                currentProgress = ImportProgress(
                    stage: .completed,
                    fractionCompleted: 1.0,
                    currentFileName: nil,
                    statusDetail: message,
                    processedCount: count,
                    totalCount: count,
                    canCancel: false
                )
                
                self.analyticsService.trackEvent("Budget Template Import Success", properties: [
                    "imported_categories": count,
                    "file_count": processedBudgets.count
                ])
            } catch {
                self.modelContext.rollback()
                let errString = error.localizedDescription
                self.errorMessage = "Import failed: \(errString)"
                self.importResult = ImportResult(
                    success: false,
                    message: "Budget import operation failed.",
                    importedCount: 0,
                    fileCount: processedBudgets.count,
                    errorDescription: errString
                )
                self.currentProgress = ImportProgress(
                    stage: .failed(reason: errString),
                    fractionCompleted: 1.0,
                    statusDetail: errString,
                    canCancel: false
                )
                self.analyticsService.trackEvent("Budget Template Import Failed", properties: ["error": errString])
            }
            
            self.cleanupTempFiles(tempFileURLs)
        }
    }
    
    func importWorkbookFile(url: URL) {
        isImporting = true
        errorMessage = nil
        importResult = nil
        
        let fileName = url.lastPathComponent
        currentProgress = ImportProgress(
            stage: .readingFile(filename: fileName),
            fractionCompleted: 0.1,
            currentFileName: fileName,
            statusDetail: "Reading full Excel workbook...",
            processedCount: 0,
            totalCount: 1,
            canCancel: true
        )
        
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Failed to access security-scoped resource."
            currentProgress = ImportProgress(
                stage: .failed(reason: "Failed security access"),
                fractionCompleted: 1.0,
                statusDetail: "Failed to access security-scoped file resource.",
                canCancel: false
            )
            return
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.copyItem(at: url, to: tempURL)
        } catch {
            url.stopAccessingSecurityScopedResource()
            errorMessage = "Failed to prepare workbook file: \(error.localizedDescription)"
            currentProgress = ImportProgress(
                stage: .failed(reason: error.localizedDescription),
                fractionCompleted: 1.0,
                statusDetail: error.localizedDescription,
                canCancel: false
            )
            return
        }
        
        importTask = Task {
            defer {
                url.stopAccessingSecurityScopedResource()
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            currentProgress = ImportProgress(
                stage: .parsingData(filename: fileName, current: 1, total: 1),
                fractionCompleted: 0.3,
                currentFileName: fileName,
                statusDetail: "Parsing workbook sheets and budgets...",
                processedCount: 0,
                totalCount: 1,
                canCancel: true
            )
            
            if Task.isCancelled {
                self.modelContext.rollback()
                return
            }
            
            currentProgress = ImportProgress(
                stage: .importingRecords(current: 1, total: 1),
                fractionCompleted: 0.6,
                currentFileName: fileName,
                statusDetail: "Creating budgets, categories, and transaction records...",
                processedCount: 0,
                totalCount: 1,
                canCancel: true
            )
            
            do {
                let manager = ImportManager(modelContext: self.modelContext)
                let result = try manager.importFullXLSXWorkbook(from: tempURL)
                
                if Task.isCancelled {
                    self.modelContext.rollback()
                    return
                }
                
                currentProgress = ImportProgress(
                    stage: .savingDatabase,
                    fractionCompleted: 0.9,
                    currentFileName: nil,
                    statusDetail: "Saving imported workbook data...",
                    processedCount: result.importedCount,
                    totalCount: result.importedCount,
                    canCancel: false
                )
                
                self.importResult = result
                
                currentProgress = ImportProgress(
                    stage: .completed,
                    fractionCompleted: 1.0,
                    currentFileName: nil,
                    statusDetail: result.message,
                    processedCount: result.importedCount,
                    totalCount: result.importedCount,
                    canCancel: false
                )
                
                self.analyticsService.trackEvent("Full XLSX Workbook Import Success", properties: [
                    "imported_count": result.importedCount,
                    "file_count": result.fileCount
                ])
            } catch {
                self.modelContext.rollback()
                let errString = error.localizedDescription
                self.errorMessage = "Full Workbook Import failed: \(errString)"
                self.importResult = ImportResult(
                    success: false,
                    message: "Workbook import failed.",
                    importedCount: 0,
                    fileCount: 1,
                    errorDescription: errString
                )
                self.currentProgress = ImportProgress(
                    stage: .failed(reason: errString),
                    fractionCompleted: 1.0,
                    statusDetail: errString,
                    canCancel: false
                )
                self.analyticsService.trackEvent("Full XLSX Workbook Import Failed", properties: ["error": errString])
            }
        }
    }
    
    private func cleanupTempFiles(_ urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
