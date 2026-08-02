//
//  DependencyInjectionTests.swift
//  ExpenseTrackerSwiftTests
//

import XCTest
import SwiftData
@testable import ExpenseTrackerSwift

@MainActor
final class DependencyInjectionTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var mockAnalytics: MockAnalyticsService!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Budget.self, Category.self, Transaction.self, configurations: config)
        context = container.mainContext
        mockAnalytics = MockAnalyticsService()
    }

    override func tearDown() {
        container = nil
        context = nil
        mockAnalytics = nil
        super.tearDown()
    }

    func testTransactionViewModelAnalyticsInjection() throws {
        let viewModel = TransactionViewModel(
            modelContext: context,
            analyticsService: mockAnalytics
        )

        let budget = Budget(name: "Test Budget", startDate: Date(), totalAmount: 1000)
        let category = Category(name: "Food", allocatedAmount: 200, isIncome: false, budgetPeriod: Date(), budget: budget)
        context.insert(budget)
        context.insert(category)

        // Test Add Transaction Event
        try viewModel.saveTransaction(
            amount: 50.0,
            description: "Lunch",
            date: Date(),
            budget: budget,
            category: category,
            budgetPeriod: Date(),
            existing: nil
        )

        XCTAssertTrue(mockAnalytics.trackedEvents.contains(where: { $0.name == "Transaction Added" }), "Expected 'Transaction Added' event to be tracked")

        // Test Update Transaction Event
        if let transaction = viewModel.transactions.first {
            try viewModel.saveTransaction(
                amount: 60.0,
                description: "Lunch",
                date: Date(),
                budget: budget,
                category: category,
                budgetPeriod: Date(),
                existing: transaction
            )
            XCTAssertTrue(mockAnalytics.trackedEvents.contains(where: { $0.name == "Transaction Updated" }), "Expected 'Transaction Updated' event to be tracked")

            // Test Delete Transaction Event
            try viewModel.deleteTransaction(transaction)
            XCTAssertTrue(mockAnalytics.trackedEvents.contains(where: { $0.name == "Transaction Deleted" }), "Expected 'Transaction Deleted' event to be tracked")
        } else {
            XCTFail("Transaction should have been created")
        }
    }

    func testImportViewModelAnalyticsInjection() throws {
        let importViewModel = ImportViewModel(
            modelContext: context,
            analyticsService: mockAnalytics
        )

        let budget = Budget(name: "Import Test Budget", startDate: Date(), totalAmount: 500)
        context.insert(budget)

        // Calling import with empty URLs should fail gracefully without crash and handle logic
        importViewModel.importTransactionFiles(urls: [], into: budget)

        XCTAssertFalse(importViewModel.isImporting)
    }
}
