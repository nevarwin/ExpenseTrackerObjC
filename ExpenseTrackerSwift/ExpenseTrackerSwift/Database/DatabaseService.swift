import Foundation
import GRDB

/// Singleton that manages the SQLite database connection and schema migrations.
final class DatabaseService {

    static let shared = DatabaseService()

    let queue: DatabaseQueue

    private init() {
        do {
            // Store the DB in Application Support so it survives app updates.
            let appSupport = try FileManager.default
                .url(for: .applicationSupportDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
            let dbURL = appSupport.appendingPathComponent("expenses.sqlite")
            queue = try DatabaseQueue(path: dbURL.path)
            try migrate(queue)
        } catch {
            fatalError("DatabaseService failed to initialise: \(error)")
        }
    }

    // MARK: - In-Memory (for unit tests)

    static func makeInMemory() throws -> DatabaseQueue {
        let q = try DatabaseQueue()
        try shared.migrate(q)
        return q
    }

    // MARK: - Migrations

    private func migrate(_ db: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial_schema") { db in
            // Budget
            try db.create(table: "budget", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("totalAmount", .text).notNull()
                t.column("remainingAmount", .text).notNull()
                t.column("isActive", .boolean).notNull().defaults(to: true)
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
            }

            // Category
            try db.create(table: "category", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("allocatedAmount", .text).notNull()
                t.column("usedAmount", .text).notNull().defaults(to: "0")
                t.column("isIncome", .boolean).notNull().defaults(to: false)
                t.column("isActive", .boolean).notNull().defaults(to: true)
                t.column("budgetId", .text)
                    .references("budget", onDelete: .cascade)
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
            }

            // Transaction (named transaction_record to avoid SQLite keyword clash)
            try db.create(table: "transaction_record", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("amount", .text).notNull()
                t.column("desc", .text).notNull().defaults(to: "")
                t.column("date", .double).notNull()
                t.column("budgetPeriod", .double).notNull()
                t.column("isActive", .boolean).notNull().defaults(to: true)
                t.column("budgetId", .text)
                    .references("budget", onDelete: .cascade)
                t.column("categoryId", .text)
                    .references("category", onDelete: .setNull)
                t.column("createdAt", .double).notNull()
                t.column("updatedAt", .double).notNull()
            }

            // Budget Allocation
            try db.create(table: "budget_allocation", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("budgetId", .text).notNull()
                    .references("budget", onDelete: .cascade)
                t.column("amount", .text).notNull()
                t.column("allocatedAt", .double).notNull()
                t.column("notes", .text)
            }

            // Indices for common queries
            try db.create(index: "idx_transaction_budget_date",
                          on: "transaction_record",
                          columns: ["budgetId", "date"],
                          ifNotExists: true)

            try db.create(index: "idx_category_budget",
                          on: "category",
                          columns: ["budgetId"],
                          ifNotExists: true)
        }

        try migrator.migrate(db)
    }
}
