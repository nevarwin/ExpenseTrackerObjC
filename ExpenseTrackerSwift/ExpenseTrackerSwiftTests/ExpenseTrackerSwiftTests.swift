//
//  ExpenseTrackerSwiftTests.swift
//  ExpenseTrackerSwiftTests
//
//  Created by raven on 1/19/26.
//

import Testing
import SwiftData
import Foundation
@testable import ExpenseTrackerSwift

struct ExpenseTrackerSwiftTests {

    @Test func testAppProgressBarStatusCases() {
        let healthy = AppProgressBar.Status.healthy
        let warning = AppProgressBar.Status.warning
        let critical = AppProgressBar.Status.critical
        
        #expect(healthy != warning)
        #expect(warning != critical)
    }

    @Test @MainActor func testCategoryViewModelDeleteCategorySoftDeletes() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Budget.self, Category.self, Transaction.self, configurations: config)
        let context = container.mainContext
        
        let budget = Budget(name: "Test Budget", startDate: Date(), totalAmount: 1000)
        context.insert(budget)
        
        let category = Category(name: "Groceries", allocatedAmount: 200, isIncome: false, budgetPeriod: Date(), budget: budget)
        context.insert(category)
        try context.save()
        
        let viewModel = CategoryViewModel(modelContext: context)
        viewModel.categories = [category]
        
        #expect(viewModel.categories.count == 1)
        #expect(category.isActive == true)
        
        viewModel.deleteCategory(category)
        
        #expect(viewModel.categories.isEmpty)
        #expect(category.isActive == false)
    }

}

