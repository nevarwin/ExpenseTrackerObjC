import Foundation
import GRDB

// MARK: - Decimal ↔ SQLite Storage
// Decimal is stored as TEXT to preserve exact precision.
extension Decimal: @retroactive DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        self.description.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Decimal? {
        guard let str = String.fromDatabaseValue(dbValue) else { return nil }
        return Decimal(string: str)
    }
}
