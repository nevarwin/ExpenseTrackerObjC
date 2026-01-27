import SwiftUI
import SwiftData

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currencyManager: CurrencyManager
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
                    isIncome: category.isIncome,
                    isInstallment: category.isInstallment,
                    totalInstallmentAmount: category.totalInstallmentAmount?.description ?? "0",
                    installmentMonths: category.installmentMonths?.description ?? "12",
                    installmentStartDate: category.installmentStartDate ?? Date(),
                    originalCategory: category,
                    isActive: category.isActive
                )
            })
        } else {
            // Initialize with one default category for new budget
            _categoryDrafts = State(initialValue: [
                CategoryDraft(name: "", allocatedAmount: "0", isIncome: true)
            ])
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Details") {
                    TextField("Budget Name", text: $name)
                }
                
                Section {
                    ForEach($categoryDrafts) { $draft in
                        if draft.isActive {
                            CategoryInputRow(draft: $draft) {
                                deleteOrArchiveCategory(draft)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if draft.originalCategory != nil {
                                    Button {
                                        withAnimation {
                                            draft.isActive = false
                                        }
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                    .tint(.orange)
                                }
                            }
                        }
                    }
                    
                    Button(action: addCategory) {
                        Label("Add Category", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Categories")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        let activeDrafts = categoryDrafts.filter { $0.isActive }
                        let incomeTotal = activeDrafts.filter({ $0.isIncome }).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }
                        let expenseTotal = activeDrafts.filter({ !$0.isIncome }).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }
                        
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
                
                if !categoryDrafts.filter({ !$0.isActive }).isEmpty {
                    Section("Archived Categories") {
                        ForEach($categoryDrafts) { $draft in
                            if !draft.isActive {
                                HStack {
                                    Text(draft.name)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("Archived")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        withAnimation {
                                            draft.isActive = true
                                        }
                                    } label: {
                                        Label("Restore", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
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
        let activeDrafts = categoryDrafts.filter { $0.isActive }
        let incomeTotal = activeDrafts.filter({ $0.isIncome }).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }
        
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              incomeTotal > 0,
              activeDrafts.filter({ $0.isIncome }).count > 0 else {
            return false
        }
        
        // Check for duplicate category names (among active ones)
        let categoryNames = activeDrafts.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() }
        let uniqueNames = Set(categoryNames)
        guard categoryNames.count == uniqueNames.count else {
            return false
        }
        
        // All active categories must be valid
        return activeDrafts.allSatisfy { $0.isValid }
    }
    
    private func addCategory() {
        categoryDrafts.append(CategoryDraft(
            name: "",
            allocatedAmount: "0",
            isIncome: false
        ))
    }
    
    private func deleteOrArchiveCategory(_ draft: CategoryDraft) {
        if draft.originalCategory != nil {
            // If it's an existing category, just archive it
            if let index = categoryDrafts.firstIndex(where: { $0.id == draft.id }) {
                withAnimation {
                    categoryDrafts[index].isActive = false
                }
            }
        } else {
            // If it's a new draft, actually delete it
            categoryDrafts.removeAll { $0.id == draft.id }
        }
    }
    
    private func saveBudget() {
        // Calculate total from income categories
        let amount = categoryDrafts.filter({ $0.isIncome }).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }
        
        do {
            let budget: Budget
            var keptCategories: Set<PersistentIdentifier> = []
            
            if let existing = existingBudget {
                // Update existing budget
                try viewModel.updateBudget(existing, name: name, totalAmount: amount)
                budget = existing
            } else {
                // Create new budget and get the returned instance
                budget = try viewModel.createBudget(name: name, totalAmount: amount)
            }
            
            // Process drafts
            for draft in categoryDrafts where draft.isValid {
                let category: Category
                
                if let original = draft.originalCategory {
                    // Update existing category
                    category = original
                    category.name = draft.name.trimmingCharacters(in: .whitespaces)
                    category.allocatedAmount = draft.allocatedDecimal
                    category.isIncome = draft.isIncome
                    category.isActive = draft.isActive // Update active state
                    category.updatedAt = Date()
                    
                    keptCategories.insert(original.persistentModelID)
                } else {
                    // Create new category
                    category = Category(
                        name: draft.name.trimmingCharacters(in: .whitespaces),
                        allocatedAmount: draft.allocatedDecimal,
                        isIncome: draft.isIncome,
                        isInstallment: draft.isInstallment,
                        budget: budget
                    )
                    // New categories are active by default, but relying on init
                    category.isActive = draft.isActive
                    modelContext.insert(category)
                }
                
                // Update installment details
                if draft.isInstallment {
                    let total = Decimal(string: draft.totalInstallmentAmount) ?? 0
                    let months = Int(draft.installmentMonths) ?? 1
                    
                    category.configureInstallment(
                        monthlyPayment: draft.allocatedDecimal,
                        totalAmount: total,
                        months: months,
                        startDate: draft.installmentStartDate
                    )
                } else {
                    category.isInstallment = false
                    category.monthlyPayment = nil
                    category.totalInstallmentAmount = nil
                    category.installmentMonths = nil
                    category.installmentStartDate = nil
                    category.installmentEndDate = nil
                }
            }
            
            // Delete categories that are no longer in drafts (only for existing budget)
            if let existing = existingBudget {
                for category in existing.categories {
                    // If a category was in drafts but removed (not just archived, but removed from list)
                    // then we delete it. Note: 'keptCategories' tracks categories we updated.
                    // If a category is missing from drafts completely, it is deleted.
                    if !keptCategories.contains(category.persistentModelID) {
                        modelContext.delete(category)
                    }
                }
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
        formatter.currencyCode = currencyManager.currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currencyManager.currencySymbol)0.00"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Budget.self, configurations: config)
    let viewModel = BudgetViewModel(modelContext: container.mainContext)
    
    BudgetFormView(viewModel: viewModel)
}
