
import XCTest
@testable import ExpenseTrackerSwift

final class CSVParserTests: XCTestCase {

    var parser: CSVParser!
    
    override func setUp() {
        super.setUp()
        parser = CSVParser.shared
    }
    
    // MARK: - Transaction Parsing (Dec25PS.csv)
    
    func testParseTransactions_Dec25PS_Format() throws {
        // Mock CSV Data mimicking Dec25PS.csv
        let csvString = """
        ,Change or add categories by updating the Expenses and Income tables in the Summary sheet.,,,,,,,,
        ,Expenses,,,,,Income,,,
        Date,Amount,Description,Category,,Date,Amount,Description,Category
        12/30/2025,"$3,000.00",savings,Savings,,12/29/2025,"$13,666.00",salary,Paycheck
        12/17/2025,$224.00,sunscreen,Personal/Wallet,,,,
        """
        
        // Write to temp file
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Dec25PS.csv")
        try csvString.write(to: url, atomically: true, encoding: .utf8)
        
        // Parse
        let transactions = try parser.parseTransactions(from: url)
        
        // Verify
        XCTAssertEqual(transactions.count, 3) // 2 Expenses, 1 Income
        
        // Check Expense 1 (Row 4 Left)
        let exp1 = transactions.first { $0.description == "savings" }
        XCTAssertNotNil(exp1)
        XCTAssertEqual(exp1?.amount, 3000)
        XCTAssertEqual(exp1?.category, "Savings")
        XCTAssertFalse(exp1!.isIncome)
        
        // Check Expense 2 (Row 5 Left)
        let exp2 = transactions.first { $0.description == "sunscreen" }
        XCTAssertNotNil(exp2)
        XCTAssertEqual(exp2?.amount, 224)
        XCTAssertEqual(exp2?.category, "Personal/Wallet")
        
        // Check Income 1 (Row 4 Right)
        let inc1 = transactions.first { $0.description == "salary" }
        XCTAssertNotNil(inc1)
        XCTAssertEqual(inc1?.amount, 13666)
        XCTAssertEqual(inc1?.category, "Paycheck")
        XCTAssertTrue(inc1!.isIncome)
    }
    
    // MARK: - Budget Parsing (Dec25.csv - Complex)
    
    func testParseBudget_Dec25_Format() throws {
        let csvString = """
        ,,,,,,,,,,,
        ,Expenses,,,,,,Income,,,,
        ,,,Planned,Actual,Diff.,,,,Planned,Actual,Diff.
        ,Totals,,"$22,656","$26,722","-$4,066",,Totals,,"$26,000","$33,333","+$7,333"
        ,,,,,,,,,,,
        ,Groceries,,"$1,000","$1,000",$0,,Savings,,$0,$0,$0
        ,Food Money,,"$4,000","$3,000","+$1,000",,Paycheck,,"$26,000","$26,845",+$845
        """
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Dec25.csv")
        try csvString.write(to: url, atomically: true, encoding: .utf8)
        
        let budget = try parser.parseBudget(from: url)
        
        XCTAssertEqual(budget.name, "Dec25")
        
        // Verify Items
        // Expected: Groceries (1000), Food Money (4000), Paycheck (26000 - Income)
        // Savings has 0 planned, so likely should be ignored if > 0 check works
        
        let groceries = budget.items.first { $0.categoryName == "Groceries" }
        XCTAssertNotNil(groceries)
        XCTAssertEqual(groceries?.amount, 1000)
        XCTAssertFalse(groceries!.isIncome)
        
        let paycheck = budget.items.first { $0.categoryName == "Paycheck" }
        XCTAssertNotNil(paycheck)
        XCTAssertEqual(paycheck?.amount, 26000)
        XCTAssertTrue(paycheck!.isIncome)
        
        let savings = budget.items.first { $0.categoryName == "Savings" }
        XCTAssertNil(savings) // Should be nil because amount is 0
    }
    
    // MARK: - Budget Parsing (13th25.csv - Simple)
    
    func testParseBudget_13th25_Format() throws {
        let csvString = """
        ,,,,,,,,,,
        ,Initial,"$13,328.00",,,,,,,,
        ,Sum,"$12,096.00",,,,,,,,
        """
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("13th25.csv")
        try csvString.write(to: url, atomically: true, encoding: .utf8)
        
        let budget = try parser.parseBudget(from: url)
        
        XCTAssertEqual(budget.name, "13th25")
        
        let initial = budget.items.first { $0.categoryName == "Initial" }
        XCTAssertNotNil(initial)
        XCTAssertEqual(initial?.amount, 13328)
    }
}
