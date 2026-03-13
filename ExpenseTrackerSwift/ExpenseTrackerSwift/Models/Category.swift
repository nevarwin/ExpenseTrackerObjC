import Foundation
import GRDB

final class Category: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var allocatedAmount: Decimal
    var usedAmount: Decimal
    var isIncome: Bool
    var isActive: Bool
    var budgetId: String?
    var createdAt: Date
    var updatedAt: Date

    // Resolved after fetch
    var budget: Budget?
    var transactions: [Transaction] = []

    init(
        id: String = UUID().uuidString,
        name: String,
        allocatedAmount: Decimal,
        isIncome: Bool,
        budgetId: String? = nil,
        budget: Budget? = nil
    ) {
        self.id = id
        self.name = name
        self.allocatedAmount = allocatedAmount
        self.usedAmount = 0
        self.isIncome = isIncome
        self.isActive = true
        self.budgetId = budgetId ?? budget?.id
        self.budget = budget
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    var remainingAmount: Decimal {
        allocatedAmount - usedAmount
    }

    var usagePercentage: Double {
        guard allocatedAmount > 0 else { return 0 }
        return Double(truncating: (usedAmount / allocatedAmount) as NSDecimalNumber)
    }

    var isOverBudget: Bool {
        usedAmount > allocatedAmount
    }

    // MARK: - Monthly Period Filtering

    func transactionsInMonth(_ date: Date = Date()) -> [Transaction] {
        let bounds = DateRangeHelper.monthBounds(for: date)
        return transactions.filter { transaction in
            transaction.isActive &&
            DateRangeHelper.isSameMonth(transaction.budgetPeriod, bounds.start)
        }
    }

    var currentMonthUsedAmount: Decimal {
        transactionsInMonth().reduce(Decimal.zero) { $0 + $1.amount }
    }

    func usedAmountInMonth(_ date: Date) -> Decimal {
        transactionsInMonth(date).reduce(Decimal.zero) { $0 + $1.amount }
    }

    var currentMonthRemainingAmount: Decimal {
        allocatedAmount - currentMonthUsedAmount
    }

    func remainingAmountInMonth(_ date: Date) -> Decimal {
        allocatedAmount - usedAmountInMonth(date)
    }

    // MARK: - Business Logic

    func isValid(for date: Date) -> Bool {
        return isActive
    }

    func updateUsedAmount() {
        usedAmount = transactions
            .filter { $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.amount }
        updatedAt = Date()
    }
}

// MARK: - Hashable
extension Category {
    static func == (lhs: Category, rhs: Category) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - GRDB

extension Category: FetchableRecord, PersistableRecord {
    static let databaseTableName = "category"

    enum Columns: String, ColumnExpression {
        case id, name, allocatedAmount, usedAmount, isIncome, isActive,
             budgetId, createdAt, updatedAt
    }

    convenience init(row: Row) throws {
        self.init(
            id: row[Columns.id],
            name: row[Columns.name],
            allocatedAmount: row[Columns.allocatedAmount],
            isIncome: row[Columns.isIncome],
            budgetId: row[Columns.budgetId]
        )
        self.usedAmount = row[Columns.usedAmount]
        self.isActive = row[Columns.isActive]
        self.createdAt = Date(timeIntervalSince1970: row[Columns.createdAt])
        self.updatedAt = Date(timeIntervalSince1970: row[Columns.updatedAt])
    }

    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.allocatedAmount] = allocatedAmount
        container[Columns.usedAmount] = usedAmount
        container[Columns.isIncome] = isIncome
        container[Columns.isActive] = isActive
        container[Columns.budgetId] = budgetId
        container[Columns.createdAt] = createdAt.timeIntervalSince1970
        container[Columns.updatedAt] = updatedAt.timeIntervalSince1970
    }
}
