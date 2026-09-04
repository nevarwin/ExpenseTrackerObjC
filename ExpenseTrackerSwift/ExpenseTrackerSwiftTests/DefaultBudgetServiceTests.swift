//
//  DefaultBudgetServiceTests.swift
//  ExpenseTrackerSwiftTests
//
//  Created by raven on 9/5/26.
//

import XCTest
import SwiftData
@testable import ExpenseTrackerSwift

@MainActor
final class DefaultBudgetServiceTests: XCTestCase {
    private var testUserDefaults: UserDefaults!
    private let suiteName = "DefaultBudgetServiceTestsSuite"

    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: suiteName)
        testUserDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: suiteName)
        testUserDefaults = nil
        super.tearDown()
    }

    func testSetAndGetDefaultBudget() {
        let service = DefaultBudgetService(userDefaults: testUserDefaults)
        let budgetA = Budget(name: "Budget A", totalAmount: 1000)
        let budgetB = Budget(name: "Budget B", totalAmount: 2000)

        XCTAssertNil(service.defaultBudgetID)
        XCTAssertFalse(service.isDefault(budget: budgetA))
        XCTAssertFalse(service.isDefault(budget: budgetB))

        service.setDefault(budget: budgetA)
        XCTAssertEqual(service.defaultBudgetID, budgetA.id)
        XCTAssertTrue(service.isDefault(budget: budgetA))
        XCTAssertFalse(service.isDefault(budget: budgetB))

        // Switch default to B
        service.setDefault(budget: budgetB)
        XCTAssertEqual(service.defaultBudgetID, budgetB.id)
        XCTAssertFalse(service.isDefault(budget: budgetA))
        XCTAssertTrue(service.isDefault(budget: budgetB))

        // Clear default
        service.clearDefault()
        XCTAssertNil(service.defaultBudgetID)
        XCTAssertFalse(service.isDefault(budget: budgetB))
    }

    func testPersistenceInUserDefaults() {
        let service1 = DefaultBudgetService(userDefaults: testUserDefaults)
        let budget = Budget(name: "Persistent Budget", totalAmount: 5000)

        service1.setDefault(budget: budget)
        XCTAssertEqual(service1.defaultBudgetID, budget.id)

        // Instantiate new service with same userDefaults suite
        let service2 = DefaultBudgetService(userDefaults: testUserDefaults)
        XCTAssertEqual(service2.defaultBudgetID, budget.id)
        XCTAssertTrue(service2.isDefault(budget: budget))
    }

    func testResolveDefaultBudgetReturnsDesignatedBudget() {
        let service = DefaultBudgetService(userDefaults: testUserDefaults)
        let budgetA = Budget(name: "Budget A", totalAmount: 1000)
        let budgetB = Budget(name: "Budget B", totalAmount: 2000)
        let budgetC = Budget(name: "Budget C", totalAmount: 3000)

        service.setDefault(budget: budgetB)

        let resolved = service.resolveDefaultBudget(from: [budgetA, budgetB, budgetC])
        XCTAssertEqual(resolved?.id, budgetB.id)
    }

    func testResolveDefaultBudgetFallsBackToFirstActiveWhenNoneDesignated() {
        let service = DefaultBudgetService(userDefaults: testUserDefaults)
        let budgetA = Budget(name: "Budget A", totalAmount: 1000)
        let budgetB = Budget(name: "Budget B", totalAmount: 2000)

        let resolved = service.resolveDefaultBudget(from: [budgetA, budgetB])
        XCTAssertEqual(resolved?.id, budgetA.id)
    }

    func testResolveDefaultBudgetFallsBackWhenDesignatedIsInactive() {
        let service = DefaultBudgetService(userDefaults: testUserDefaults)
        let budgetA = Budget(name: "Budget A", totalAmount: 1000)
        let budgetB = Budget(name: "Budget B", totalAmount: 2000, isActive: false)

        service.setDefault(budget: budgetB)

        let resolved = service.resolveDefaultBudget(from: [budgetA, budgetB])
        XCTAssertEqual(resolved?.id, budgetA.id)
    }

    func testResolveDefaultBudgetReturnsNilWhenEmpty() {
        let service = DefaultBudgetService(userDefaults: testUserDefaults)
        let resolved = service.resolveDefaultBudget(from: [])
        XCTAssertNil(resolved)
    }
}
