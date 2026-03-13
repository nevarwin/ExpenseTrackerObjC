import Foundation
import GRDB

final class TransactionRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue = DatabaseService.shared.queue) {
        self.db = db
    }

    // MARK: - Read

    /// Fetch all transactions for a budget (all time, no date filter).
    func fetchAll(budgetId: String) throws -> [Transaction] {
        try db.read { db in
            try Transaction.filter(Column("budgetId") == budgetId)
                .order(Column("date").desc)
                .fetchAll(db)
        }
    }

    /// Fetch transactions filtered by date range (single date or range).
    func fetch(budgetId: String? = nil, start: Date, end: Date, isActive: Bool = true) throws -> [Transaction] {
        try db.read { db in
            let startTs = start.timeIntervalSince1970
            let endTs = end.timeIntervalSince1970
            var query = Transaction.filter(
                Column("isActive") == isActive &&
                Column("date") >= startTs &&
                Column("date") < endTs
            )
            if let budgetId {
                query = query.filter(Column("budgetId") == budgetId)
            }
            return try query.order(Column("date").desc).fetchAll(db)
        }
    }

    /// Fetch transaction dates (for calendar dot indicators) in a given month.
    func fetchDates(budgetId: String? = nil, monthStart: Date, monthEnd: Date) throws -> Set<Date> {
        let transactions = try fetch(budgetId: budgetId, start: monthStart, end: monthEnd)
        let calendar = Calendar.current
        let dates = transactions.map { calendar.startOfDay(for: $0.date) }
        return Set(dates)
    }

    /// Full-text search on description.
    func search(text: String, isActive: Bool = true) throws -> [Transaction] {
        try db.read { db in
            try Transaction.filter(
                Column("isActive") == isActive &&
                Column("desc").like("%\(text)%")
            )
            .order(Column("date").desc)
            .fetchAll(db)
        }
    }

    // MARK: - Write

    func insert(_ transaction: Transaction) throws {
        try db.write { db in
            try transaction.insert(db)
        }
    }

    func update(_ transaction: Transaction) throws {
        transaction.updatedAt = Date()
        try db.write { db in
            try transaction.update(db)
        }
    }

    func delete(id: String) throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM transaction_record WHERE id = ?", arguments: [id])
        }
    }

    func save(_ transaction: Transaction) throws {
        try db.write { db in
            try transaction.save(db)
        }
    }
}
