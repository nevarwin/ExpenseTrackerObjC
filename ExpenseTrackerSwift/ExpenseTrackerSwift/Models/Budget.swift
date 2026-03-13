import Foundation
import GRDB

final class Budget: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var totalAmount: Decimal
    var remainingAmount: Decimal
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    // Populated after fetch via BudgetRepository.fetchWithRelations
    var categories: [Category] = []
    var transactions: [Transaction] = []
    var allocations: [BudgetAllocation] = []

    init(
        id: String = UUID().uuidString,
        name: String,
        totalAmount: Decimal,
        remainingAmount: Decimal? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.totalAmount = totalAmount
        self.remainingAmount = remainingAmount ?? totalAmount
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Monthly Period Filtering

    func transactionsInMonth(_ date: Date = Date()) -> [Transaction] {
        let bounds = DateRangeHelper.monthBounds(for: date)
        return transactions.filter { transaction in
            transaction.isActive &&
            DateRangeHelper.isSameMonth(transaction.budgetPeriod, bounds.start)
        }
    }

    // MARK: - Current Month Calculations

    var currentMonthExpenses: Decimal {
        transactionsInMonth()
            .filter { !($0.category?.isIncome ?? false) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    var currentMonthIncome: Decimal {
        transactionsInMonth()
            .filter { $0.category?.isIncome ?? false }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    var currentMonthRemaining: Decimal {
        totalAmount + currentMonthIncome - currentMonthExpenses
    }

    // MARK: - Any Month Calculations

    func expensesInMonth(_ date: Date) -> Decimal {
        transactionsInMonth(date)
            .filter { !($0.category?.isIncome ?? false) }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    func incomeInMonth(_ date: Date) -> Decimal {
        transactionsInMonth(date)
            .filter { $0.category?.isIncome ?? false }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    func remainingInMonth(_ date: Date) -> Decimal {
        totalAmount + incomeInMonth(date) - expensesInMonth(date)
    }

    // MARK: - All-Time

    var totalExpenses: Decimal {
        transactions
            .filter { !($0.category?.isIncome ?? false) && $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    var totalIncome: Decimal {
        transactions
            .filter { ($0.category?.isIncome ?? false) && $0.isActive }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    func updateRemainingAmount() {
        remainingAmount = totalAmount + totalIncome - totalExpenses
        updatedAt = Date()
    }
}

// MARK: - Hashable
extension Budget {
    static func == (lhs: Budget, rhs: Budget) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - GRDB

extension Budget: FetchableRecord, PersistableRecord {
    static let databaseTableName = "budget"

    enum Columns: String, ColumnExpression {
        case id, name, totalAmount, remainingAmount, isActive, createdAt, updatedAt
    }

    convenience init(row: Row) throws {
        self.init(
            id: row[Columns.id],
            name: row[Columns.name],
            totalAmount: row[Columns.totalAmount],
            remainingAmount: row[Columns.remainingAmount],
            isActive: row[Columns.isActive]
        )
        self.createdAt = Date(timeIntervalSince1970: row[Columns.createdAt])
        self.updatedAt = Date(timeIntervalSince1970: row[Columns.updatedAt])
    }

    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.totalAmount] = totalAmount
        container[Columns.remainingAmount] = remainingAmount
        container[Columns.isActive] = isActive
        container[Columns.createdAt] = createdAt.timeIntervalSince1970
        container[Columns.updatedAt] = updatedAt.timeIntervalSince1970
    }
}
