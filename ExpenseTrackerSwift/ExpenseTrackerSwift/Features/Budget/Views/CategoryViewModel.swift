import SwiftUI
import SwiftData

@Observable
final class CategoryViewModel {
    var categories: [Category] = []
    var selectedCategory: Category?
    var isLoading = false
    var errorMessage: String?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadCategories(for budget: Budget? = nil, isIncome: Bool? = nil, month: Date? = nil) {
        isLoading = true
        errorMessage = nil
        
        var predicate: Predicate<Category>?
        
        if let isIncome = isIncome {
            predicate = #Predicate<Category> { category in
                category.isActive == true && category.isIncome == isIncome
            }
        } else {
            predicate = #Predicate<Category> { $0.isActive == true }
        }
        
        let descriptor = FetchDescriptor<Category>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        
        do {
            var fetchedCategories = try modelContext.fetch(descriptor)
            
            // Filter by budget if specified
            if let budget = budget {
                fetchedCategories = fetchedCategories.filter { $0.budget?.id == budget.id }
            }
            
            // Filter by month if specified
            if let month = month {
                let bounds = month.monthBounds
                fetchedCategories = fetchedCategories.filter { category in
                    category.budgetPeriod.isSameMonth(as: bounds.start)
                }
            }
            
            fetchedCategories.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            categories = fetchedCategories
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createCategory(
        name: String,
        allocatedAmount: Decimal,
        isIncome: Bool,
        budget: Budget?,
        month: Date? = nil
    ) throws {
        let category = Category(
            name: name,
            allocatedAmount: allocatedAmount,
            isIncome: isIncome,
            budgetPeriod: month ?? budget?.startDate,
            budget: budget
        )
        modelContext.insert(category)
        try modelContext.save()
        categories.append(category)
        categories.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
