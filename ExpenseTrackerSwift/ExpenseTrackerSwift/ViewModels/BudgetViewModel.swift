import Combine
import SwiftData
import SwiftUI

final class BudgetViewModel: ObservableObject {

    
    @Published var budgets: [Budget] = []
    @Published var selectedBudget: Budget?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let selectedBudgetKey = "SelectedBudgetID"
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadBudgets() {
        isLoading = true
        errorMessage = nil
        
        let descriptor = FetchDescriptor<Budget>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            budgets = try modelContext.fetch(descriptor)
            
            // Restore selection or default to first active
            if let savedIdString = UserDefaults.standard.string(forKey: selectedBudgetKey),
               let savedId = UUID(uuidString: savedIdString),
               let found = budgets.first(where: { $0.id == savedId }) {
                selectedBudget = found
            } else {
                selectedBudget = budgets.first(where: { $0.isActive })
            }
            
        } catch {
            errorMessage = "Failed to load budgets: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func selectBudget(_ budget: Budget) {
        selectedBudget = budget
        UserDefaults.standard.set(budget.id.uuidString, forKey: selectedBudgetKey)
    }
    
    @discardableResult
    func createBudget(name: String, totalAmount: Decimal) throws -> Budget {
        let budget = Budget(name: name, totalAmount: totalAmount)
        modelContext.insert(budget)
        budgets.insert(budget, at: 0)
        
        // Auto-select newly created budget
        selectedBudget = budget
        UserDefaults.standard.set(budget.id.uuidString, forKey: selectedBudgetKey)
        
        return budget
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
        
        // If deleted budget was selected, select another one BEFORE reloading
        if selectedBudget?.id == budget.id {
            selectedBudget = nil
        }
        
        // Reload budgets from database instead of manually manipulating array
        // This prevents index mismatch with SwiftUI's list
        loadBudgets()
    }
    
    func toggleBudgetStatus(_ budget: Budget) throws {
        budget.isActive.toggle()
        budget.updatedAt = Date()
        try modelContext.save()
    }
}
