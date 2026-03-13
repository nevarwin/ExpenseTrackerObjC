import SwiftUI
import GRDB

@Observable
final class CategoryViewModel {
    var categories: [Category] = []
    var selectedCategory: Category?
    var isLoading = false
    var errorMessage: String?

    private let categoryRepo: CategoryRepository

    init(categoryRepo: CategoryRepository = CategoryRepository()) {
        self.categoryRepo = categoryRepo
    }

    func loadCategories(for budget: Budget? = nil, isIncome: Bool? = nil) {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try categoryRepo.fetchAll(
                budgetId: budget?.id,
                isActive: true,
                isIncome: isIncome
            )
            categories = fetched
            // Wire budget back-reference
            if let budget {
                for cat in categories { cat.budget = budget }
            }
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func createCategory(
        name: String,
        allocatedAmount: Decimal,
        isIncome: Bool,
        budget: Budget?
    ) throws {
        let category = Category(
            name: name,
            allocatedAmount: allocatedAmount,
            isIncome: isIncome,
            budgetId: budget?.id,
            budget: budget
        )
        try categoryRepo.insert(category)
        categories.insert(category, at: 0)
    }
}
