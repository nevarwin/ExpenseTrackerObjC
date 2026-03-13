import Foundation
import GRDB

final class BudgetRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue = DatabaseService.shared.queue) {
        self.db = db
    }

    // MARK: - Read

    func fetchAll() throws -> [Budget] {
        try db.read { db in
            try Budget.order(Column("createdAt").desc).fetchAll(db)
        }
    }

    /// Fetch a budget with its categories and transactions pre-populated.
    func fetchWithRelations(id: String, categoryRepository: CategoryRepository, transactionRepository: TransactionRepository) throws -> Budget? {
        guard let budget = try db.read({ db in
            try Budget.fetchOne(db, key: id)
        }) else { return nil }

        budget.categories = try categoryRepository.fetchAll(budgetId: id)
        budget.transactions = try transactionRepository.fetchAll(budgetId: id)

        // Wire up back-references so computed properties work
        for category in budget.categories {
            category.budget = budget
        }
        for transaction in budget.transactions {
            transaction.budget = budget
            transaction.category = budget.categories.first { $0.id == transaction.categoryId }
        }
        // Also wire up category.transactions
        for category in budget.categories {
            category.transactions = budget.transactions.filter { $0.categoryId == category.id }
        }

        return budget
    }

    // MARK: - Write

    func insert(_ budget: Budget) throws {
        try db.write { db in
            try budget.insert(db)
        }
    }

    func update(_ budget: Budget) throws {
        budget.updatedAt = Date()
        try db.write { db in
            try budget.update(db)
        }
    }

    func delete(id: String) throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM budget WHERE id = ?", arguments: [id])
        }
    }

    func save(_ budget: Budget) throws {
        try db.write { db in
            try budget.save(db)
        }
    }
}
