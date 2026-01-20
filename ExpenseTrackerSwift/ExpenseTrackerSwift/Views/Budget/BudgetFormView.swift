import SwiftUI
import SwiftData

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: BudgetViewModel
    
    @State private var name: String = ""
    @State private var categoryDrafts: [CategoryDraft] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let existingBudget: Budget?
    
    init(viewModel: BudgetViewModel, existingBudget: Budget? = nil) {
        self.viewModel = viewModel
        self.existingBudget = existingBudget
        
        if let budget = existingBudget {
            _name = State(initialValue: budget.name)
            
            // Load existing categories into drafts
            _categoryDrafts = State(initialValue: budget.categories.map { category in
                CategoryDraft(
                    name: category.name,
                    allocatedAmount: "\(category.allocatedAmount)",
                    isIncome: category.isIncome
                )
            })
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Details") {
                    TextField("Budget Name", text: $name)
                }
                
                Section {
                    ForEach(categoryDrafts) { draft in
                        CategoryInputRow(draft: draft) {
                            categoryDrafts.removeAll { $0.id == draft.id }
                        }
                    }
                    
                    Button(action: addCategory) {
                        Label("Add Category", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Categories")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        let incomeTotal = categoryDrafts.filter({ $0.isIncome }).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }
                        let expenseTotal = categoryDrafts.filter({ !$0.isIncome }).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }
                        
                        HStack {
                            Text("Total Income:")
                            Spacer()
                            Text(formatCurrency(incomeTotal))
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                        
                        HStack {
                            Text("Total Expenses:")
                            Spacer()
                            Text(formatCurrency(expenseTotal))
                                .fontWeight(.medium)
                                .foregroundStyle(.red)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Budget Total:")
                            Spacer()
                            Text(formatCurrency(incomeTotal))
                                .fontWeight(.bold)
                        }
                    }
                    .font(.subheadline)
                }
                
                if existingBudget != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteBudget()
                        } label: {
                            Label("Delete Budget", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(existingBudget == nil ? "New Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveBudget() }
                        .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        let incomeTotal = categoryDrafts.filter({ $0.isIncome }).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }
        
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              incomeTotal > 0,
              categoryDrafts.filter({ $0.isIncome }).count > 0,
              categoryDrafts.filter({ !$0.isIncome }).count > 0 else {
            return false
        }
        
        // Check for duplicate category names
        let categoryNames = categoryDrafts.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() }
        let uniqueNames = Set(categoryNames)
        guard categoryNames.count == uniqueNames.count else {
            return false
        }
        
        // All categories must be valid
        return categoryDrafts.allSatisfy { $0.isValid }
    }
    
    private func addCategory() {
        categoryDrafts.append(CategoryDraft(
            name: "",
            allocatedAmount: "0",
            isIncome: false
        ))
    }
    
    private func saveBudget() {
        // Calculate total from income categories
        let amount = categoryDrafts.filter({ $0.isIncome }).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }
        
        do {
            let budget: Budget
            
            if let existing = existingBudget {
                // Update existing budget
                try viewModel.updateBudget(existing, name: name, totalAmount: amount)
                budget = existing
                
                // Delete all existing categories (we'll recreate from drafts)
                for category in existing.categories {
                    modelContext.delete(category)
                }
            } else {
                // Create new budget and get the returned instance
                budget = try viewModel.createBudget(name: name, totalAmount: amount)
            }
            
            // Create categories from drafts
            for draft in categoryDrafts where draft.isValid {
                let category = Category(
                    name: draft.name.trimmingCharacters(in: .whitespaces),
                    allocatedAmount: draft.allocatedDecimal,
                    isIncome: draft.isIncome,
                    budget: budget
                )
                modelContext.insert(category)
            }
            
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func deleteBudget() {
        guard let budget = existingBudget else { return }
        
        do {
            try viewModel.deleteBudget(budget)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Budget.self, configurations: config)
    let viewModel = BudgetViewModel(modelContext: container.mainContext)
    
    BudgetFormView(viewModel: viewModel)
}
