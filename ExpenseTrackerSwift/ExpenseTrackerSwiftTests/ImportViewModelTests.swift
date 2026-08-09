//
//  ImportViewModelTests.swift
//  ExpenseTrackerSwiftTests
//

import XCTest
import SwiftData
@testable import ExpenseTrackerSwift

@MainActor
final class ImportViewModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var viewModel: ImportViewModel!
    
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Budget.self, Category.self, Transaction.self, configurations: config)
        context = container.mainContext
        viewModel = ImportViewModel(modelContext: context)
    }
    
    override func tearDown() {
        viewModel = nil
        context = nil
        container = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isImporting)
        XCTAssertNil(viewModel.currentProgress)
        XCTAssertNil(viewModel.importResult)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testCancelImportRollsBackAndUpdatesProgress() {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let budget = Budget(name: "Test Budget", startDate: date, totalAmount: 1000)
        context.insert(budget)
        
        // Start an import with an invalid/empty list to trigger stage initialization
        viewModel.importTransactionFiles(urls: [], into: budget)
        
        // Explicitly invoke cancel
        viewModel.cancelImport()
        
        XCTAssertEqual(viewModel.currentProgress?.stage, .cancelled)
        XCTAssertEqual(viewModel.currentProgress?.fractionCompleted, 1.0)
        XCTAssertTrue(viewModel.importResult?.wasCancelled == true)
        XCTAssertEqual(viewModel.importResult?.success, false)
    }
    
    func testDismissLoadingResetsState() {
        viewModel.isImporting = true
        viewModel.currentProgress = ImportProgress(stage: .completed, fractionCompleted: 1.0)
        
        viewModel.dismissLoading()
        
        XCTAssertFalse(viewModel.isImporting)
        XCTAssertNil(viewModel.currentProgress)
    }
}
