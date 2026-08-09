import XCTest
import SwiftData
@testable import ExpenseTrackerSwift

@MainActor
final class XLSXImporterTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var importManager: ImportManager!
    let candidateFileURLs = [
        URL(fileURLWithPath: "/Users/raven/Downloads/Monthly budget (1).xlsx"),
        URL(fileURLWithPath: "/Users/raven/Downloads/Monthly budget.xlsx")
    ]
    
    var fileURL: URL? {
        candidateFileURLs.first(where: { FileManager.default.fileExists(atPath: $0.path) })
    }
    
    override func setUp() {
        super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: Budget.self, Category.self, Transaction.self, InstallmentPlan.self, configurations: config)
        context = container.mainContext
        importManager = ImportManager(modelContext: context)
    }
    
    func testXLSXParserReadsWorkbook() throws {
        guard let url = fileURL else {
            throw XCTSkip("Sample workbook file not found")
        }
        
        let workbook = try XLSXParser.shared.parseWorkbook(from: url)
        XCTAssertGreaterThan(workbook.sheets.count, 0, "Workbook should contain sheets")
        XCTAssertNotNil(workbook.sheet(named: "Jul24"))
    }
    
    func testFullXLSXWorkbookImport() throws {
        guard let url = fileURL else {
            throw XCTSkip("Sample workbook file not found")
        }
        
        let result = try importManager.importFullXLSXWorkbook(from: url)
        XCTAssertTrue(result.success)
        XCTAssertGreaterThan(result.importedCount, 0)
        
        // Fetch budgets
        let budgetFetch = FetchDescriptor<Budget>()
        let budgets = try context.fetch(budgetFetch)
        
        let budgetNames = Set(budgets.map { $0.name })
        XCTAssertTrue(budgetNames.contains("Monthly Budget"))
        XCTAssertTrue(budgetNames.contains("13th Month Pay 2024"))
        XCTAssertTrue(budgetNames.contains("13th Month Pay 2025"))
        XCTAssertTrue(budgetNames.contains("Beacon Computation"))
        
        // Fetch transactions for primary budget
        if let monthlyBudget = budgets.first(where: { $0.name == "Monthly Budget" }) {
            let txFetch = FetchDescriptor<Transaction>()
            let allTx = try context.fetch(txFetch)
            let monthlyTx = allTx.filter { $0.budget?.id == monthlyBudget.id }
            XCTAssertGreaterThan(monthlyTx.count, 50, "Should have imported transaction records into Monthly Budget")
        }
    }
    
    func testIdempotentReImport() throws {
        guard let url = fileURL else {
            throw XCTSkip("Sample workbook file not found")
        }
        
        // First import
        _ = try importManager.importFullXLSXWorkbook(from: url)
        let txFetch = FetchDescriptor<Transaction>()
        let firstCount = try context.fetch(txFetch).count
        
        // Second import (Overwrite mode)
        _ = try importManager.importFullXLSXWorkbook(from: url)
        let secondCount = try context.fetch(txFetch).count
        
        XCTAssertEqual(firstCount, secondCount, "Re-importing should overwrite without creating duplicate transactions")
    }
    
    func testDiagnosticImportSummary() throws {
        guard let url = fileURL else {
            throw XCTSkip("Sample workbook file not found")
        }
        
        let result = try importManager.importFullXLSXWorkbook(from: url)
        print("\n================ FULL IMPORT DIAGNOSTIC SUMMARY ================")
        print("Import Result Message: \(result.message)")
        print("Total Sheets Processed: \(result.fileCount)")
        print("Total Items Imported: \(result.importedCount)")
        
        let budgetFetch = FetchDescriptor<Budget>()
        let budgets = try context.fetch(budgetFetch)
        print("\n--- BUDGETS CREATED (\(budgets.count)) ---")
        
        let txFetch = FetchDescriptor<Transaction>()
        let allTxs = try context.fetch(txFetch)
        
        let catFetch = FetchDescriptor<ExpenseTrackerSwift.Category>()
        let allCats = try context.fetch(catFetch)
        
        for b in budgets.sorted(by: { $0.name < $1.name }) {
            let bCats = allCats.filter { $0.budget?.id == b.id }
            let bTxs = allTxs.filter { $0.budget?.id == b.id }
            let expTxs = bTxs.filter { !$0.isIncome }
            let incTxs = bTxs.filter { $0.isIncome }
            let totalExp = expTxs.reduce(Decimal.zero) { $0 + $1.amount }
            let totalInc = incTxs.reduce(Decimal.zero) { $0 + $1.amount }
            
            print("\nBudget: \(b.name)")
            print("  Category Allocations: \(bCats.count)")
            print("  Transactions: \(bTxs.count) (\(expTxs.count) Expenses, \(incTxs.count) Income)")
            print("  Total Expenses Sum: ₱\(totalExp)")
            print("  Total Income Sum: ₱\(totalInc)")
            
            // Group by month for Monthly Budget
            if b.name == "Monthly Budget" {
                let fmt = DateFormatter()
                fmt.dateFormat = "MMM yyyy"
                let months = Set(bCats.map { fmt.string(from: $0.budgetPeriod) }).sorted()
                print("  Monthly Periods (\(months.count)): \(months.joined(separator: ", "))")
            }
        }
        print("=================================================================\n")
    }
    
    func testImportCategoryWithInstallmentPrefixCreatesInstallmentPlan() throws {
        let budget = Budget(name: "Test Budget", startDate: Date(), totalAmount: 10000)
        context.insert(budget)
        
        let targetMonth = Date()
        let catNameWithPrefix = "Installment: Midea Aircon"
        
        // Import single transaction with Installment category prefix
        importManager.importSingleXLSXTransaction(
            date: targetMonth,
            amount: 2775,
            description: "Aircon Midea 2hp",
            categoryName: catNameWithPrefix,
            isIncome: false,
            budgetPeriod: targetMonth,
            into: budget
        )
        
        // Verify Category name was cleaned
        let catFetch = FetchDescriptor<ExpenseTrackerSwift.Category>()
        let categories = try context.fetch(catFetch)
        let matchedCategory = categories.first(where: { $0.name == "Midea Aircon" })
        XCTAssertNotNil(matchedCategory, "Category name should be cleaned to 'Midea Aircon'")
        
        // Verify InstallmentPlan was auto-created and linked
        let planFetch = FetchDescriptor<InstallmentPlan>()
        let plans = try context.fetch(planFetch)
        let matchedPlan = plans.first(where: { $0.name == "Midea Aircon" })
        XCTAssertNotNil(matchedPlan, "An InstallmentPlan named 'Midea Aircon' should be automatically created")
        XCTAssertEqual(matchedPlan?.monthlyAmount, 2775)
    }
    
    func testBudgetScopedDeduplicationPreservesMultiMonthTransactions() throws {
        let budget = Budget(name: "Test Budget", startDate: Date(), totalAmount: 10000)
        context.insert(budget)
        
        let mayPeriod = Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let augPeriod = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        let transactionDate = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 4))!
        
        // Import in May period
        importManager.importSingleXLSXTransaction(
            date: transactionDate,
            amount: 2775,
            description: "Aircon Midea 2hp",
            categoryName: "Midea Aircon",
            isIncome: false,
            budgetPeriod: mayPeriod,
            into: budget
        )
        
        // Import in August period with same transaction date, amount, description
        importManager.importSingleXLSXTransaction(
            date: transactionDate,
            amount: 2775,
            description: "Aircon Midea 2hp",
            categoryName: "Midea Aircon",
            isIncome: false,
            budgetPeriod: augPeriod,
            into: budget
        )
        
        let txFetch = FetchDescriptor<Transaction>()
        let allTxs = try context.fetch(txFetch)
        XCTAssertEqual(allTxs.count, 2, "Transactions in separate budget periods should not be collapsed into 1")
        
        let mayTx = allTxs.first(where: { $0.budgetPeriod.isSameMonth(as: mayPeriod) })
        let augTx = allTxs.first(where: { $0.budgetPeriod.isSameMonth(as: augPeriod) })
        XCTAssertNotNil(mayTx, "Transaction for May budget period should exist")
        XCTAssertNotNil(augTx, "Transaction for August budget period should exist")
    }
}
