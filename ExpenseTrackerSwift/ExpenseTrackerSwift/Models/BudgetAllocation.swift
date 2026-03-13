import Foundation
import GRDB

final class BudgetAllocation: Identifiable, Codable {
    var id: String
    var budgetId: String
    var amount: Decimal
    var allocatedAt: Date
    var notes: String?

    init(
        id: String = UUID().uuidString,
        budgetId: String,
        amount: Decimal,
        notes: String? = nil
    ) {
        self.id = id
        self.budgetId = budgetId
        self.amount = amount
        self.allocatedAt = Date()
        self.notes = notes
    }
}

// MARK: - GRDB

extension BudgetAllocation: FetchableRecord, PersistableRecord {
    static let databaseTableName = "budget_allocation"

    enum Columns: String, ColumnExpression {
        case id, budgetId, amount, allocatedAt, notes
    }

    convenience init(row: Row) throws {
        self.init(
            id: row[Columns.id],
            budgetId: row[Columns.budgetId],
            amount: row[Columns.amount],
            notes: row[Columns.notes]
        )
        self.allocatedAt = Date(timeIntervalSince1970: row[Columns.allocatedAt])
    }

    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.budgetId] = budgetId
        container[Columns.amount] = amount
        container[Columns.allocatedAt] = allocatedAt.timeIntervalSince1970
        container[Columns.notes] = notes
    }
}
