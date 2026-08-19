//
//  TransactionFormViewModelTests.swift
//  ExpenseTrackerSwiftTests
//

import XCTest
import SwiftData
@testable import ExpenseTrackerSwift

@MainActor
final class TransactionFormViewModelTests: XCTestCase {
    
    private var container: ModelContainer!
    private var modelContext: ModelContext!
    private var viewModel: TransactionViewModel!
    
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Budget.self, Category.self, Transaction.self, InstallmentPlan.self, configurations: config)
        modelContext = container.mainContext
        viewModel = TransactionViewModel(modelContext: modelContext)
    }
    
    override func tearDown() {
        container = nil
        modelContext = nil
        viewModel = nil
        super.tearDown()
    }
    
    func testMonthPeriodIsolationForCategories() throws {
        let calendar = Calendar.current
        let janDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let febDate = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        
        let budget = Budget(name: "2026 Budget", totalAmount: 10000)
        modelContext.insert(budget)
        
        let janFood = Category(name: "Food", allocatedAmount: 500, isIncome: false, budgetPeriod: janDate, budget: budget)
        let febFood = Category(name: "Food", allocatedAmount: 600, isIncome: false, budgetPeriod: febDate, budget: budget)
        let janSalary = Category(name: "Salary", allocatedAmount: 3000, isIncome: true, budgetPeriod: janDate, budget: budget)
        
        modelContext.insert(janFood)
        modelContext.insert(febFood)
        modelContext.insert(janSalary)
        try modelContext.save()
        
        // Load for January
        viewModel.loadAvailableCategories(transactionDate: janDate, budget: budget)
        XCTAssertEqual(viewModel.availableCategories.count, 2)
        XCTAssertTrue(viewModel.availableCategories.contains(where: { $0.id == janFood.id }))
        XCTAssertTrue(viewModel.availableCategories.contains(where: { $0.id == janSalary.id }))
        XCTAssertFalse(viewModel.availableCategories.contains(where: { $0.id == febFood.id }))
        
        // Load for February
        viewModel.loadAvailableCategories(transactionDate: febDate, budget: budget)
        XCTAssertEqual(viewModel.availableCategories.count, 1)
        XCTAssertTrue(viewModel.availableCategories.contains(where: { $0.id == febFood.id }))
        XCTAssertFalse(viewModel.availableCategories.contains(where: { $0.id == janFood.id }))
    }
    
    func testBudgetIsolationForCategories() throws {
        let testDate = Date().monthBounds.start
        
        let budgetA = Budget(name: "Budget A", totalAmount: 5000)
        let budgetB = Budget(name: "Budget B", totalAmount: 5000)
        modelContext.insert(budgetA)
        modelContext.insert(budgetB)
        
        let catA = Category(name: "Groceries", allocatedAmount: 400, isIncome: false, budgetPeriod: testDate, budget: budgetA)
        let catB = Category(name: "Rent", allocatedAmount: 1000, isIncome: false, budgetPeriod: testDate, budget: budgetB)
        modelContext.insert(catA)
        modelContext.insert(catB)
        try modelContext.save()
        
        viewModel.loadAvailableCategories(transactionDate: testDate, budget: budgetA)
        XCTAssertEqual(viewModel.availableCategories.count, 1)
        XCTAssertEqual(viewModel.availableCategories.first?.name, "Groceries")
    }
    
    func testRetainInactiveCategoryForExistingTransaction() throws {
        let testDate = Date().monthBounds.start
        let budget = Budget(name: "Main Budget", totalAmount: 5000)
        modelContext.insert(budget)
        
        let activeCat = Category(name: "Active Food", allocatedAmount: 500, isIncome: false, budgetPeriod: testDate, budget: budget)
        let inactiveCat = Category(name: "Old Archived Service", allocatedAmount: 200, isIncome: false, budgetPeriod: testDate, budget: budget)
        inactiveCat.isActive = false
        
        modelContext.insert(activeCat)
        modelContext.insert(inactiveCat)
        
        let transaction = Transaction(amount: 150, description: "Old Payment", date: testDate, budget: budget, category: inactiveCat, budgetPeriod: testDate)
        modelContext.insert(transaction)
        try modelContext.save()
        
        // Without existing transaction passed: inactive category should NOT appear
        viewModel.loadAvailableCategories(transactionDate: testDate, budget: budget)
        XCTAssertEqual(viewModel.availableCategories.count, 1)
        XCTAssertEqual(viewModel.availableCategories.first?.id, activeCat.id)
        
        // With existing transaction passed: inactive category SHOULD be preserved
        viewModel.loadAvailableCategories(transactionDate: testDate, budget: budget, excluding: transaction)
        XCTAssertEqual(viewModel.availableCategories.count, 2)
        XCTAssertTrue(viewModel.availableCategories.contains(where: { $0.id == inactiveCat.id }))
    }
}
