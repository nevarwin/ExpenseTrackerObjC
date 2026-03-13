import Foundation
import GRDB

final class BudgetAllocationRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue = DatabaseService.shared.queue) {
        self.db = db
    }

    func fetch(budgetId: String) throws -> [BudgetAllocation] {
        try db.read { db in
            try BudgetAllocation.filter(Column("budgetId") == budgetId)
                .order(Column("allocatedAt").desc)
                .fetchAll(db)
        }
    }

    func insert(_ allocation: BudgetAllocation) throws {
        try db.write { db in
            try allocation.insert(db)
        }
    }
}
