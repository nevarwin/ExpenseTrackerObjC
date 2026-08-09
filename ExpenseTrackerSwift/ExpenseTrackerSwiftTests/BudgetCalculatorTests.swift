//
//  BudgetCalculatorTests.swift
//  ExpenseTrackerSwiftTests
//

import XCTest
import SwiftData
@testable import ExpenseTrackerSwift

@MainActor
final class BudgetCalculatorTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Budget.self, Category.self, Transaction.self, configurations: config)
        context = container.mainContext
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    func testPlannedExpensesAndIncomePerMonth() throws {
        // AAA Pattern
        // Arrange
        let janDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let febDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!

        let budget = Budget(name: "2026 Budget", startDate: janDate, totalAmount: 10000)
        context.insert(budget)

        // Jan Categories: Expense = 500, Income = 2000
        let janExpense = Category(name: "Jan Rent", allocatedAmount: 500, isIncome: false, budgetPeriod: janDate, budget: budget)
        let janIncome = Category(name: "Jan Salary", allocatedAmount: 2000, isIncome: true, budgetPeriod: janDate, budget: budget)

        // Feb Categories: Expense = 800, Income = 2500
        let febExpense = Category(name: "Feb Rent", allocatedAmount: 800, isIncome: false, budgetPeriod: febDate, budget: budget)
        let febIncome = Category(name: "Feb Salary", allocatedAmount: 2500, isIncome: true, budgetPeriod: febDate, budget: budget)

        context.insert(janExpense)
        context.insert(janIncome)
        context.insert(febExpense)
        context.insert(febIncome)

        budget.categories.append(contentsOf: [janExpense, janIncome, febExpense, febIncome])
        try context.save()

        let calculator = BudgetCalculator(budget: budget)

        // Act & Assert
        // Jan planned amounts
        XCTAssertEqual(calculator.plannedExpenses(date: janDate), 500, "Jan planned expenses should only include Jan categories")
        XCTAssertEqual(calculator.plannedIncome(date: janDate), 2000, "Jan planned income should only include Jan categories")

        // Feb planned amounts
        XCTAssertEqual(calculator.plannedExpenses(date: febDate), 800, "Feb planned expenses should only include Feb categories")
        XCTAssertEqual(calculator.plannedIncome(date: febDate), 2500, "Feb planned income should only include Feb categories")
    }

    func testCategoriesInMonthAreAlphabetical() throws {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let budget = Budget(name: "Test Budget", startDate: date, totalAmount: 5000)
        context.insert(budget)

        let catZ = Category(name: "Utilities", allocatedAmount: 100, isIncome: false, budgetPeriod: date, budget: budget)
        let catA = Category(name: "Groceries", allocatedAmount: 200, isIncome: false, budgetPeriod: date, budget: budget)
        let catM = Category(name: "Dining Out", allocatedAmount: 150, isIncome: false, budgetPeriod: date, budget: budget)

        context.insert(catZ)
        context.insert(catA)
        context.insert(catM)
        budget.categories.append(contentsOf: [catZ, catA, catM])
        try context.save()

        let calculator = BudgetCalculator(budget: budget)
        let categories = calculator.categoriesInMonth(date: date)

        XCTAssertEqual(categories.map { $0.name }, ["Dining Out", "Groceries", "Utilities"])
    }
}
