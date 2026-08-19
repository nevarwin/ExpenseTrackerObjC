//
//  InstallmentPlanTests.swift
//  ExpenseTrackerSwiftTests
//

import XCTest
import SwiftData
@testable import ExpenseTrackerSwift

@MainActor
final class InstallmentPlanTests: XCTestCase {
    
    private var container: ModelContainer!
    private var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Budget.self, Category.self, Transaction.self, InstallmentPlan.self, configurations: config)
        modelContext = container.mainContext
    }
    
    override func tearDown() {
        container = nil
        modelContext = nil
        super.tearDown()
    }

    func testElapsedMonthsCalculation() {
        let calendar = Calendar.current
        let now = Date()
        
        // Start date 12 months ago
        guard let startDate = calendar.date(byAdding: .month, value: -12, to: now) else {
            XCTFail("Date math failed")
            return
        }
        
        let plan = InstallmentPlan(
            name: "MacBook Pro",
            totalAmount: 2400,
            monthlyAmount: 100,
            startDate: startDate,
            totalMonths: 24
        )
        
        // Month difference: 12 months ago + current month = 13 elapsed months
        XCTAssertEqual(plan.elapsedMonths(asOf: now), 13)
        XCTAssertEqual(plan.remainingMonthsCount, 11)
        XCTAssertFalse(plan.isCompleted)
    }

    func testProgressPercentage() {
        let plan = InstallmentPlan(
            name: "Phone",
            totalAmount: 1200,
            monthlyAmount: 100,
            startDate: Date(),
            totalMonths: 12
        )
        
        XCTAssertGreaterThan(plan.progressPercentage, 0)
        XCTAssertLessThanOrEqual(plan.progressPercentage, 1.0)
    }

    func testTransactionFormattedDescriptionForExport() {
        let tx = Transaction(
            amount: 100,
            description: "Laptop Purchase",
            date: Date(),
            installmentIndex: 13,
            installmentTotalMonths: 24
        )
        
        XCTAssertEqual(tx.formattedDescriptionForExport, "[Installment 13/24] Laptop Purchase")
    }
    
    func testUpdateInstallmentPlanTotalMonthsCascadesToTransactions() throws {
        let budget = Budget(name: "2026 Budget", startDate: Date(), totalAmount: 10000)
        modelContext.insert(budget)
        
        let category = Category(name: "Gadgets", allocatedAmount: 5000, isIncome: false, budget: budget)
        modelContext.insert(category)
        
        let service = InstallmentService(modelContext: modelContext)
        let plan = try service.createInstallmentPlan(
            name: "MacBook Pro",
            totalAmount: 2400,
            monthlyAmount: 100,
            startDate: Date(),
            totalMonths: 24,
            category: category,
            budget: budget,
            notes: "Initial 24-month term"
        )
        
        XCTAssertEqual(plan.totalMonths, 24)
        XCTAssertFalse(plan.transactions.isEmpty)
        for tx in plan.transactions {
            XCTAssertEqual(tx.installmentTotalMonths, 24)
            XCTAssertTrue(tx.formattedDescriptionForExport.contains("/24]"))
        }
        
        // Update tenure to 36 months and change monthly amount
        try service.updateInstallmentPlan(
            plan,
            name: "MacBook Pro 16-inch",
            totalAmount: 2400,
            monthlyAmount: Decimal(string: "66.67")!,
            startDate: plan.startDate,
            totalMonths: 36,
            category: category,
            notes: "Extended to 36-month term"
        )
        
        XCTAssertEqual(plan.totalMonths, 36)
        XCTAssertEqual(plan.name, "MacBook Pro 16-inch")
        XCTAssertEqual(plan.monthlyAmount, Decimal(string: "66.67")!)
        
        // Verify all linked transactions received the updated totalMonths
        for tx in plan.transactions {
            XCTAssertEqual(tx.installmentTotalMonths, 36)
            XCTAssertEqual(tx.desc, "MacBook Pro 16-inch")
            XCTAssertTrue(tx.formattedDescriptionForExport.contains("/36]"))
        }
    }
    
    func testShorteningTenureCompletion() throws {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .month, value: -5, to: Date()) else {
            XCTFail("Date math failed")
            return
        }
        
        let plan = InstallmentPlan(
            name: "Camera",
            totalAmount: 600,
            monthlyAmount: 100,
            startDate: startDate,
            totalMonths: 12
        )
        modelContext.insert(plan)
        
        // 6 elapsed months out of 12
        XCTAssertEqual(plan.elapsedMonths(), 6)
        XCTAssertEqual(plan.remainingMonthsCount, 6)
        XCTAssertFalse(plan.isCompleted)
        
        // Shorten tenure to 6 months
        plan.totalMonths = 6
        XCTAssertEqual(plan.elapsedMonths(), 6)
        XCTAssertEqual(plan.remainingMonthsCount, 0)
        XCTAssertEqual(plan.progressPercentage, 1.0)
        XCTAssertTrue(plan.isCompleted)
    }
}
