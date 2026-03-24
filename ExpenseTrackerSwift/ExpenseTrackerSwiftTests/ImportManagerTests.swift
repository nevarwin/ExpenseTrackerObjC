import XCTest
import SwiftData
@testable import ExpenseTrackerSwift

final class ImportManagerTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var importManager: ImportManager!
    
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Budget.self, Category.self, Transaction.self, configurations: config)
        context = container.mainContext
        importManager = ImportManager(modelContext: context)
    }
    
    func testCategoryInheritance() throws {
        // 1. Setup: Create a budget for Dec 25 with a "Dining" category
        let decDate = Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 1))!
        let decBudget = Budget(name: "Dec25", startDate: decDate, totalAmount: 1000)
        context.insert(decBudget)
        
        let diningCategory = Category(
            name: "Dining",
            allocatedAmount: 150,
            isIncome: false,
            budgetPeriod: decDate,
            budget: decBudget
        )
        context.insert(diningCategory)
        decBudget.categories.append(diningCategory)
        try context.save()
        
        // 2. Action: Import a transaction for "Dining" in Jan 26 budget
        // The Jan 26 budget doesn't exist yet, ImportManager will create it if we use importBudget first
        // or we can mock the budget existence.
        
        let janDate = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let janBudget = Budget(name: "Jan26", startDate: janDate, totalAmount: 1000)
        context.insert(janBudget)
        
        let csvTx = CSVTransaction(
            date: janDate,
            amount: 25.0,
            description: "Lunch",
            category: "Dining",
            isIncome: false
        )
        
        let count = try importManager.importTransactions(from: [csvTx], into: janBudget, filename: "Jan26.csv")
        
        // 3. Verify
        XCTAssertEqual(count, 1)
        
        let janDining = janBudget.categories.first { $0.name == "Dining" }
        XCTAssertNotNil(janDining)
        XCTAssertEqual(janDining?.allocatedAmount, 150, "Should inherit allocatedAmount from Dec 25")
        XCTAssertEqual(janDining?.budgetPeriod, decDate, "Should indicate it uses Dec 25 configuration")
        
        // 4. Action: Manually "modify" the category in Jan 26
        janDining?.allocatedAmount = 200
        janDining?.budgetPeriod = janDate
        try context.save()
        
        // 5. Action: Import for Feb 26
        let febDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let febBudget = Budget(name: "Feb26", startDate: febDate, totalAmount: 1000)
        context.insert(febBudget)
        
        let febTx = CSVTransaction(
            date: febDate,
            amount: 30.0,
            description: "Dinner",
            category: "Dining",
            isIncome: false
        )
        
        _ = try importManager.importTransactions(from: [febTx], into: febBudget, filename: "Feb26.csv")
        
        // 6. Verify Inheritance from Jan 26
        let febDining = febBudget.categories.first { $0.name == "Dining" }
        XCTAssertNotNil(febDining)
        XCTAssertEqual(febDining?.allocatedAmount, 200, "Should inherit updated allocatedAmount from Jan 26")
        XCTAssertEqual(febDining?.budgetPeriod, janDate, "Should indicate it uses Jan 26 configuration")
    }
}
