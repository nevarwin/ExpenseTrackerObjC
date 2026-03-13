import Foundation
import GRDB

final class CategoryRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue = DatabaseService.shared.queue) {
        self.db = db
    }

    // MARK: - Read

    func fetchAll(budgetId: String? = nil, isActive: Bool? = nil, isIncome: Bool? = nil) throws -> [Category] {
        try db.read { db in
            var query = Category.all()
            if let budgetId { query = query.filter(Column("budgetId") == budgetId) }
            if let isActive { query = query.filter(Column("isActive") == isActive) }
            if let isIncome { query = query.filter(Column("isIncome") == isIncome) }
            return try query.order(Column("createdAt").desc).fetchAll(db)
        }
    }

    // MARK: - Write

    func insert(_ category: Category) throws {
        try db.write { db in
            try category.insert(db)
        }
    }

    func update(_ category: Category) throws {
        category.updatedAt = Date()
        try db.write { db in
            try category.update(db)
        }
    }

    func delete(id: String) throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM category WHERE id = ?", arguments: [id])
        }
    }

    func save(_ category: Category) throws {
        try db.write { db in
            try category.save(db)
        }
    }
}
