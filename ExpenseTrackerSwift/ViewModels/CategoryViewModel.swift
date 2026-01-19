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
    
    func loadCategories(for budget: Budget? = nil, isIncome: Bool? = nil) {
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
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            var fetchedCategories = try modelContext.fetch(descriptor)
            
            // Filter by budget if specified
            if let budget = budget {
                fetchedCategories = fetchedCategories.filter { $0.budget?.id == budget.id }
            }
            
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
        budget: Budget?
    ) throws {
        let category = Category(
            name: name,
            allocatedAmount: allocatedAmount,
            isIncome: isIncome,
            budget: budget
        )
        modelContext.insert(category)
        try modelContext.save()
        categories.insert(category, at: 0)
    }
    
    func createInstallmentCategory(
        name: String,
        allocatedAmount: Decimal,
        monthlyPayment: Decimal,
        totalAmount: Decimal,
        months: Int,
        startDate: Date,
        budget: Budget?
    ) throws {
        let category = Category(
            name: name,
            allocatedAmount: allocatedAmount,
            isIncome: false,
            isInstallment: true,
            budget: budget
        )
        
        category.configureInstallment(
            monthlyPayment: monthlyPayment,
            totalAmount: totalAmount,
            months: months,
            startDate: startDate
        )
        
        modelContext.insert(category)
        try modelContext.save()
        categories.insert(category, at: 0)
    }
    
    func updateCategory(_ category: Category, name: String, allocatedAmount: Decimal) throws {
        category.name = name
        category.allocatedAmount = allocatedAmount
        category.updatedAt = Date()
        try modelContext.save()
    }
    
    func deleteCategory(_ category: Category) throws {
        modelContext.delete(category)
        try modelContext.save()
        categories.removeAll { $0.id == category.id }
    }
}
