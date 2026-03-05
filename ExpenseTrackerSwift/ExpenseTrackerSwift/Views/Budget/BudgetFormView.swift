import SwiftUI
import SwiftData

struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: CurrencyManager
    @ObservedObject var viewModel: BudgetViewModel

    @State private var name: String = ""
    @State private var categoryDrafts: [CategoryDraft] = []
    @State private var showingError = false
    @State private var errorMessage = ""

    // Sheet state: editing index (nil = adding new)
    @State private var editingDraftIndex: Int? = nil
    @State private var showingCategorySheet = false
    @State private var newDraft: CategoryDraft = CategoryDraft(name: "", allocatedAmount: "0", isIncome: false)

    let existingBudget: Budget?

    init(viewModel: BudgetViewModel, existingBudget: Budget? = nil) {
        self.viewModel = viewModel
        self.existingBudget = existingBudget

        if let budget = existingBudget {
            _name = State(initialValue: budget.name)
            _categoryDrafts = State(initialValue: budget.categories.map { category in
                CategoryDraft(
                    name: category.name,
                    allocatedAmount: "\(category.allocatedAmount)",
                    isIncome: category.isIncome,
                    originalCategory: category,
                    isActive: category.isActive
                )
            })
        } else {
            _categoryDrafts = State(initialValue: [
                CategoryDraft(name: "", allocatedAmount: "0", isIncome: true)
            ])
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Budget Name
                Section("Budget Details") {
                    TextField("Budget Name", text: $name)
                }

                // MARK: Active Categories
                Section {
                    ForEach(Array(categoryDrafts.enumerated()), id: \.element.id) { index, draft in
                        if draft.isActive {
                            Button {
                                editingDraftIndex = index
                                showingCategorySheet = true
                            } label: {
                                CategorySummaryRow(draft: draft)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Archive for existing, delete for new
                                if draft.originalCategory != nil {
                                    Button {
                                        withAnimation { categoryDrafts[index].isActive = false }
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

                    Button {
                        newDraft = CategoryDraft(name: "", allocatedAmount: "0", isIncome: false)
                        editingDraftIndex = nil
                        showingCategorySheet = true
                    } label: {
                        Label("Add Category", systemImage: "plus.circle.fill")
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
            // Sheet: add new category
            .sheet(isPresented: $showingCategorySheet) {
                if let index = editingDraftIndex {
                    CategoryDetailSheet(draft: $categoryDrafts[index], isNew: false)
                } else {
                    CategoryDetailSheet(draft: $newDraft, isNew: true)
                        .onDisappear {
                            // Only append if the user tapped Done (name is non-empty)
                            if !newDraft.name.trimmingCharacters(in: .whitespaces).isEmpty {
                                categoryDrafts.append(newDraft)
                            }
                        }
                }
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

    private var isValid: Bool {
        let activeDrafts = categoryDrafts.filter { $0.isActive }
        let incomeTotal = activeDrafts.filter(\.isIncome).reduce(Decimal.zero) { $0 + $1.allocatedDecimal }

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              incomeTotal > 0,
              activeDrafts.contains(where: { $0.isIncome }) else { return false }

        let categoryNames = activeDrafts.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() }
        guard categoryNames.count == Set(categoryNames).count else { return false }

        return activeDrafts.allSatisfy { $0.isValid }
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
            } else {
                budget = try viewModel.createBudget(name: name, totalAmount: amount)
            }

            for draft in categoryDrafts where draft.isValid {
                let category: Category

                if let original = draft.originalCategory {
                    category = original
                    category.name = draft.name.trimmingCharacters(in: .whitespaces)
                    category.allocatedAmount = draft.allocatedDecimal
                    category.isIncome = draft.isIncome
                    category.isActive = draft.isActive
                    category.updatedAt = Date()
                    keptCategories.insert(original.persistentModelID)
                } else {
                    category = Category(
                        name: draft.name.trimmingCharacters(in: .whitespaces),
                        allocatedAmount: draft.allocatedDecimal,
                        isIncome: draft.isIncome,
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

// MARK: - Category Summary Row

/// Read-only summary row shown in the category list
private struct CategorySummaryRow: View {
    let draft: CategoryDraft
    @EnvironmentObject var currencyManager: CurrencyManager

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(draft.name.isEmpty ? "Unnamed Category" : draft.name)
                    .foregroundStyle(draft.name.isEmpty ? .secondary : .primary)


            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(formatCurrency(draft.allocatedDecimal))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(draft.isIncome ? .green : Color.appPrimary)

                Text(draft.isIncome ? "Income" : "Expense")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(draft.isIncome ? Color.green.opacity(0.15) : Color.appAccent.opacity(0.15))
                    .foregroundStyle(draft.isIncome ? .green : Color.appAccent)
                    .clipShape(Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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
