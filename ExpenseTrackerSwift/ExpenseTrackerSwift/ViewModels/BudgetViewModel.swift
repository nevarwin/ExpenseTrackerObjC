import SwiftUI
import SwiftData
import Combine

final class BudgetViewModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    @Published var budgets: [Budget] = []
    @Published var selectedBudget: Budget?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadBudgets() {
        isLoading = true
        errorMessage = nil
        
        let descriptor = FetchDescriptor<Budget>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            budgets = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load budgets: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createBudget(name: String, totalAmount: Decimal) throws {
        let budget = Budget(name: name, totalAmount: totalAmount)
        modelContext.insert(budget)
        
        try modelContext.save()
        budgets.insert(budget, at: 0)
    }
    
    func updateBudget(_ budget: Budget, name: String, totalAmount: Decimal) throws {
        budget.name = name
        budget.totalAmount = totalAmount
        budget.updatedAt = Date()
        
        try modelContext.save()
    }
    
    func deleteBudget(_ budget: Budget) throws {
        modelContext.delete(budget)
        try modelContext.save()
        budgets.removeAll { $0.id == budget.id }
    }
    
    func toggleBudgetStatus(_ budget: Budget) throws {
        budget.isActive.toggle()
        budget.updatedAt = Date()
        try modelContext.save()
    }
}
