import SwiftUI
import SwiftData

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: CurrencyManager
    @ObservedObject var viewModel: BudgetViewModel

    @State private var name: String = ""
    @State private var categoryDrafts: [BudgetCategoryDraft] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var newCategoryName = ""
    
    // Track focused field if you want, but simple textfields work fine
    
    let existingBudget: Budget?

    init(viewModel: BudgetViewModel, existingBudget: Budget? = nil) {
        self.viewModel = viewModel
        self.existingBudget = existingBudget

        if let budget = existingBudget {
            _name = State(initialValue: budget.name)
            _categoryDrafts = State(initialValue: budget.categories.map { category in
                BudgetCategoryDraft(
                    name: category.name,
                    allocatedAmount: "\(category.allocatedAmount)",
                    isIncome: category.isIncome,
                    originalCategory: category,
                    isActive: category.isActive
                )
            })
        } else {
            _categoryDrafts = State(initialValue: [
                BudgetCategoryDraft(name: "", allocatedAmount: "0", isIncome: true)
            ])
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Budget Name
                Section {
                    TextField("Budget Name", text: $name)
                        .overlay(alignment: .trailing) {
                            if name.trimmingCharacters(in: .whitespaces).isEmpty {
                                Text("Required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.trailing, 8)
                            }
                        }
                } header: {
                    Text("Budget Details")
                }

                // MARK: Active Categories
                Section {
                    ForEach($categoryDrafts) { $draft in
                        if draft.isActive {
                            let isDuplicate = categoryDrafts.filter { $0.isActive && $0.name.trimmingCharacters(in: .whitespaces).lowercased() == draft.name.trimmingCharacters(in: .whitespaces).lowercased() }.count > 1
                            
                            EditableCategoryRow(draft: $draft, isDuplicate: isDuplicate)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    // Archive for existing, delete for new
                                    if draft.originalCategory != nil {
                                        Button {
                                            if let index = categoryDrafts.firstIndex(where: { $0.id == draft.id }) {
                                                withAnimation { categoryDrafts[index].isActive = false }
                                            }
                                        } label: {
                                            Label("Archive", systemImage: "archivebox")
                                        }
                                        .tint(.orange)
                                    } else {
                                        Button(role: .destructive) {
                                            categoryDrafts.removeAll { $0.id == draft.id }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }

                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                        TextField("Add new category...", text: $newCategoryName)
                            .onSubmit {
                                let trimmedName = newCategoryName.trimmingCharacters(in: .whitespaces)
                                if !trimmedName.isEmpty {
                                    withAnimation {
                                        categoryDrafts.append(BudgetCategoryDraft(name: trimmedName, allocatedAmount: "0", isIncome: false))
                                        newCategoryName = ""
                                    }
                                }
                            }
                    }
                } header: {
                    Text("Categories")
                } footer: {
                    categoryTotalsFooter
                }

                // MARK: Archived Categories
                if categoryDrafts.contains(where: { !$0.isActive }) {
                    Section("Archived Categories") {
                        ForEach(Array(categoryDrafts.enumerated()), id: \.element.id) { index, draft in
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
                                        withAnimation { categoryDrafts[index].isActive = true }
                                    } label: {
                                        Label("Restore", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                }

                // MARK: Delete Budget
                if existingBudget != nil {
                    Section {
                        Button(role: .destructive) {
                            deleteBudget()
                        } label: {
                            Label("Delete Budget", systemImage: "trash")
                        }
                    }
                }
                
                if let message = validationMessage {
                    Section {
                        Text(message)
                            .foregroundColor(.red)
                            .font(.caption)
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
            .overlay(alignment: .bottom) {
                if !isValid && !name.isEmpty {
                   // Optional: Simple toast or message if needed, but inline is better
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                PostHogManager.shared.trackScreen("Budget Form")
            }
        }
    }

    // MARK: - Footer

    @ViewBuilder
    private var categoryTotalsFooter: some View {
        let activeDrafts = categoryDrafts.filter { $0.isActive }
        let incomeTotal = activeDrafts.filter(\.isIncome).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }
        let expenseTotal = activeDrafts.filter { !$0.isIncome }.reduce(Decimal.zero) { $0 + $1.allocatedDecimal }

        VStack(alignment: .leading, spacing: 8) {
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

    // MARK: - Validation

    private enum ValidationReason {
        case emptyBudgetName
        case emptyCategoryName
        case duplicateCategoryNames
        case invalidAmount
    }

    private var validationError: ValidationReason? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return .emptyBudgetName
        }

        let activeDrafts = categoryDrafts.filter { $0.isActive }
        
        if activeDrafts.isEmpty {
            // A budget with no categories is technically valid, 
            // but usually we want at least one. However, the user didn't ask for this.
        }

        if activeDrafts.contains(where: { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }) {
            return .emptyCategoryName
        }

        let categoryNames = activeDrafts.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() }
        if categoryNames.count != Set(categoryNames).count {
            return .duplicateCategoryNames
        }

        if !activeDrafts.allSatisfy({ $0.isValid }) {
            return .invalidAmount
        }

        return nil
    }

    private var isValid: Bool {
        validationError == nil
    }

    private var validationMessage: String? {
        switch validationError {
        case .emptyBudgetName: return "Budget name is required"
        case .emptyCategoryName: return "All categories must have a name"
        case .duplicateCategoryNames: return "Category names must be unique"
        case .invalidAmount: return "One or more amounts are invalid"
        case .none: return nil
        }
    }

    // MARK: - Actions

    private func saveBudget() {
        let amount = categoryDrafts.filter(\.isIncome).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }

        do {
            let budget: Budget
            var keptCategories: Set<PersistentIdentifier> = []

            if let existing = existingBudget {
                try viewModel.updateBudget(existing, name: name, totalAmount: amount)
                budget = existing
                PostHogManager.shared.trackEvent("Budget Updated")
            } else {
                budget = try viewModel.createBudget(name: name, totalAmount: amount)
                PostHogManager.shared.trackEvent("Budget Created")
            }

            for draft in categoryDrafts where draft.isValid {
                let category: Category

                if let original = draft.originalCategory {
                    category = original
                    category.name = draft.name.trimmingCharacters(in: .whitespaces)
                    category.allocatedAmount = draft.allocatedDecimal
                    category.isIncome = draft.isIncome
                    category.isActive = draft.isActive
                    category.budgetPeriod = budget.startDate
                    category.updatedAt = Date()
                    keptCategories.insert(original.persistentModelID)
                } else {
                    category = Category(
                        name: draft.name.trimmingCharacters(in: .whitespaces),
                        allocatedAmount: draft.allocatedDecimal,
                        isIncome: draft.isIncome,
                        budgetPeriod: budget.startDate,
                        budget: budget
                    )
                    category.isActive = draft.isActive
                    viewModel.modelContext.insert(category)
                    budget.categories.append(category)
                }


            }

            if let existing = existingBudget {
                for category in existing.categories {
                    if !keptCategories.contains(category.persistentModelID) {
                        viewModel.modelContext.delete(category)
                    }
                }
            }

            try viewModel.modelContext.save()
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
            PostHogManager.shared.trackEvent("Budget Deleted")
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

// MARK: - Editable Category Row

/// Inline editable row shown in the category list
private struct EditableCategoryRow: View {
    @Binding var draft: BudgetCategoryDraft
    var isDuplicate: Bool
    @EnvironmentObject var currencyManager: CurrencyManager

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Category Name", text: $draft.name)
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                draft.name.trimmingCharacters(in: .whitespaces).isEmpty || isDuplicate 
                                ? Color.red.opacity(0.5) 
                                : Color.clear, 
                                lineWidth: 1
                            )
                    )
                
                if isDuplicate {
                    Text("Duplicate")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
                
                TextField("Amount", text: $draft.allocatedAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            
            HStack {
                Picker("Type", selection: $draft.isIncome) {
                    Text("Expense").tag(false)
                    Text("Income").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Budget.self, configurations: config)
    let viewModel = BudgetViewModel(modelContext: container.mainContext)

    BudgetFormView(viewModel: viewModel)
}

// MARK: - Local Category Draft

/// Temporary model for category data during budget creation/editing
/// Used to hold category information before persisting to SwiftData
struct BudgetCategoryDraft: Identifiable {
    let id: UUID
    var name: String
    var allocatedAmount: String
    var isIncome: Bool
    var originalCategory: Category?
    var isActive: Bool
    
    init(id: UUID = UUID(), 
         name: String = "", 
         allocatedAmount: String = "0", 
         isIncome: Bool = false,
         originalCategory: Category? = nil,
         isActive: Bool = true) {
        self.id = id
        self.name = name
        self.allocatedAmount = allocatedAmount
        self.isIncome = isIncome
        self.originalCategory = originalCategory
        self.isActive = isActive
    }
    
    /// Computed property to get Decimal value from string input
    var allocatedDecimal: Decimal {
        return Decimal(string: allocatedAmount) ?? 0
    }
    
    /// Validation: Check if the draft has valid data
    var isValid: Bool {
        // Simple validation: strictly check name as per user request
        return !name.trimmingCharacters(in: .whitespaces).isEmpty &&
               allocatedDecimal >= 0 // Changed from > 0 to allows 0
    }
}
