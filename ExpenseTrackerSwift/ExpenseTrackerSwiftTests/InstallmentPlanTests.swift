//
//  InstallmentPlanTests.swift
//  ExpenseTrackerSwiftTests
//

import XCTest
@testable import ExpenseTrackerSwift

final class InstallmentPlanTests: XCTestCase {

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
}
