import Foundation
import GRDB

final class Transaction: Identifiable, Codable {
    var id: String
    var amount: Decimal
    var desc: String
    var date: Date
    var budgetPeriod: Date
    var isActive: Bool
    var budgetId: String?
    var categoryId: String?
    var createdAt: Date
    var updatedAt: Date

    // Resolved after fetch
    var budget: Budget?
    var category: Category?

    init(
        id: String = UUID().uuidString,
        amount: Decimal,
        description: String,
        date: Date,
        budgetId: String? = nil,
        categoryId: String? = nil,
        budget: Budget? = nil,
        category: Category? = nil,
        budgetPeriod: Date? = nil
    ) {
        self.id = id
        self.amount = amount
        self.desc = description
        self.date = date
        self.budgetPeriod = budgetPeriod ?? DateRangeHelper.monthBounds(for: date).start
        self.isActive = true
        self.budgetId = budgetId ?? budget?.id
        self.categoryId = categoryId ?? category?.id
        self.budget = budget
        self.category = category
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    var isIncome: Bool {
        category?.isIncome ?? false
    }

    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Business Logic

    func softDelete() {
        isActive = false
        updatedAt = Date()
    }
}

// MARK: - GRDB

extension Transaction: FetchableRecord, PersistableRecord {
    static let databaseTableName = "transaction_record"

    enum Columns: String, ColumnExpression {
        case id, amount, desc, date, budgetPeriod, isActive,
             budgetId, categoryId, createdAt, updatedAt
    }

    convenience init(row: Row) throws {
        self.init(
            id: row[Columns.id],
            amount: row[Columns.amount],
            description: row[Columns.desc],
            date: Date(timeIntervalSince1970: row[Columns.date]),
            budgetId: row[Columns.budgetId],
            categoryId: row[Columns.categoryId],
            budgetPeriod: Date(timeIntervalSince1970: row[Columns.budgetPeriod])
        )
        self.isActive = row[Columns.isActive]
        self.createdAt = Date(timeIntervalSince1970: row[Columns.createdAt])
        self.updatedAt = Date(timeIntervalSince1970: row[Columns.updatedAt])
    }

    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.amount] = amount
        container[Columns.desc] = desc
        container[Columns.date] = date.timeIntervalSince1970
        container[Columns.budgetPeriod] = budgetPeriod.timeIntervalSince1970
        container[Columns.isActive] = isActive
        container[Columns.budgetId] = budgetId
        container[Columns.categoryId] = categoryId
        container[Columns.createdAt] = createdAt.timeIntervalSince1970
        container[Columns.updatedAt] = updatedAt.timeIntervalSince1970
    }
}
