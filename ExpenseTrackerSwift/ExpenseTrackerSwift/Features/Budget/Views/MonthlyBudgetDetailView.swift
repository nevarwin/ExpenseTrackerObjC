import SwiftUI
import SwiftData

struct MonthlyBudgetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
    let budget: Budget
    let month: Date
    var budgetViewModel: BudgetViewModel?
    var budgetCalculator: BudgetCalculator
    
    @State private var categoryViewModel: CategoryViewModel?
    
    // Inline Category Creation
    @State private var newCategoryName: String = ""
    @State private var newCategoryAmount: String = ""
    @State private var newCategoryIsIncome: Bool = false
    
    // Search Text State
    @State private var searchText: String = ""
    
    // Category Action States
    @State private var categoryToEdit: Category?
    @State private var categoryToDelete: Category?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            Section("Expense Overview") {
                let pExpense = budgetCalculator.plannedExpenses(date: month)
                let aExpense = budgetCalculator.expensesInMonth(date: month)
                let dExpense = budgetCalculator.expenseDiffInMonth(date: month)
                
                LabeledContent("Planned Expenses", value: pExpense.formatted(.currency(code: currencyManager.currencyCode)))
                LabeledContent("Actual Expenses", value: aExpense.formatted(.currency(code: currencyManager.currencyCode)))
                LabeledContent("Difference", value: dExpense.formatted(.currency(code: currencyManager.currencyCode)))
                    .foregroundStyle(dExpense >= 0 ? Color.emeraldPrimary : .red)
            }
            
            Section("Income Overview") {
                let pIncome = budgetCalculator.plannedIncome(date: month)
                let aIncome = budgetCalculator.incomeInMonth(date: month)
                let dIncome = budgetCalculator.incomeDiffInMonth(date: month)
                
                LabeledContent("Planned Income", value: pIncome.formatted(.currency(code: currencyManager.currencyCode)))
                LabeledContent("Actual Income", value: aIncome.formatted(.currency(code: currencyManager.currencyCode)))
                LabeledContent("Difference", value: dIncome.formatted(.currency(code: currencyManager.currencyCode)))
                    .foregroundStyle(dIncome >= 0 ? Color.emeraldPrimary : .red)
            }
            
            Section("Net Savings") {
                let savings = budgetCalculator.remainingInMonth(date: month)
                LabeledContent("Savings") {
                    Text(savings, format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(savings >= 0 ? Color.emeraldPrimary : .red)
                        .fontWeight(.semibold)
                }
            }
            
            if let viewModel = categoryViewModel {
                let searchResults = searchText.isEmpty 
                    ? viewModel.categories 
                    : viewModel.categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                
                let expenses = searchResults.filter { !$0.isIncome }
                let incomes = searchResults.filter { $0.isIncome }
                
                if viewModel.categories.isEmpty {
                    Section("Categories") {
                        Text("No categories")
                            .foregroundStyle(.secondary)
                    }
                } else if !searchText.isEmpty && searchResults.isEmpty {
                    Section("Categories") {
                        Text("No matching categories")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    if !expenses.isEmpty {
                        Section("Expense Categories") {
                            ForEach(expenses) { category in
                                NavigationLink(destination: CategoryTransactionsView(category: category, month: month)) {
                                    BudgetCategoryRowView(category: category, month: month)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        categoryToDelete = category
                                        showingDeleteAlert = true
                                    } label: {
                                        Label(String(localized: "Delete"), systemImage: "trash")
                                    }
                                    
                                    Button {
                                        categoryToEdit = category
                                    } label: {
                                        Label(String(localized: "Edit"), systemImage: "pencil")
                                    }
                                    .tint(Color.dynamicAccent)
                                }
                                .contextMenu {
                                    Button {
                                        categoryToEdit = category
                                    } label: {
                                        Label(String(localized: "Edit Category"), systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        categoryToDelete = category
                                        showingDeleteAlert = true
                                    } label: {
                                        Label(String(localized: "Delete Category"), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    
                    if !incomes.isEmpty {
                        Section("Income Categories") {
                            ForEach(incomes) { category in
                                NavigationLink(destination: CategoryTransactionsView(category: category, month: month)) {
                                    BudgetCategoryRowView(category: category, month: month)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        categoryToDelete = category
                                        showingDeleteAlert = true
                                    } label: {
                                        Label(String(localized: "Delete"), systemImage: "trash")
                                    }
                                    
                                    Button {
                                        categoryToEdit = category
                                    } label: {
                                        Label(String(localized: "Edit"), systemImage: "pencil")
                                    }
                                    .tint(Color.dynamicAccent)
                                }
                                .contextMenu {
                                    Button {
                                        categoryToEdit = category
                                    } label: {
                                        Label(String(localized: "Edit Category"), systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        categoryToDelete = category
                                        showingDeleteAlert = true
                                    } label: {
                                        Label(String(localized: "Delete Category"), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Inline Quick Create Row
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Add Category").font(.caption).foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            TextField("Name", text: $newCategoryName)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("quickadd_category_name_field")
                            
                            TextField("Amount", text: $newCategoryAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .accessibilityIdentifier("quickadd_category_amount_field")
                        }
                        
                        HStack {
                            Picker("Type", selection: $newCategoryIsIncome) {
                                Text("Expense").tag(false)
                                Text("Income").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 160)
                            .accessibilityIdentifier("quickadd_category_type_picker")
                            
                            Spacer()
                            
                            Button(action: addInlineCategory) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.dynamicAccent)
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty || (Decimal(string: newCategoryAmount) ?? 0) <= 0)
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("quickadd_category_save_button")
                        }
                    }
                    .padding(.vertical, 8)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search categories")
        .navigationTitle(month.monthYearString)
        .sheet(item: $categoryToEdit) { category in
            CategoryEditFormView(category: category)
                .environmentObject(currencyManager)
                .onDisappear {
                    categoryViewModel?.loadCategories(for: budget, month: month)
                }
        }
        .alert(String(localized: "Delete Category"), isPresented: $showingDeleteAlert, presenting: categoryToDelete) { category in
            Button(String(localized: "Delete"), role: .destructive) {
                withAnimation {
                    categoryViewModel?.deleteCategory(category)
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                categoryToDelete = nil
            }
        } message: { _ in
            Text(String(localized: "Are you sure you want to delete this category? It will be removed from this budget."))
        }
        .onAppear {
            if categoryViewModel == nil {
                categoryViewModel = CategoryViewModel(modelContext: modelContext)
            }
            categoryViewModel?.loadCategories(for: budget, month: month)
        }
    }
    
    private func addInlineCategory() {
        guard let viewModel = categoryViewModel else { return }
        let amount = Decimal(string: newCategoryAmount) ?? 0
        
        do {
            try viewModel.createCategory(
                name: newCategoryName.trimmingCharacters(in: .whitespaces),
                allocatedAmount: amount,
                isIncome: newCategoryIsIncome,
                budget: budget,
                month: month
            )
            
            withAnimation {
                newCategoryName = ""
                newCategoryAmount = ""
                newCategoryIsIncome = false
            }
            
            categoryViewModel?.loadCategories(for: budget, month: month)
        } catch {
            print("Failed to create category: \(error.localizedDescription)")
        }
    }
}
