import Foundation

extension Transaction {
    var shouldCensorAmount: Bool {
        guard let category = category else { return false }
        return isIncome && category.name.localizedCaseInsensitiveContains("paycheck")
    }
}
