import SwiftUI
import SwiftData

struct MonthlyBudgetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: CurrencyManager
    
    let budget: Budget
    let month: Date
    var budgetViewModel: BudgetViewModel?
    
    @State private var categoryViewModel: CategoryViewModel?
    
    // Inline Category Creation
    @State private var newCategoryName: String = ""
    @State private var newCategoryAmount: String = ""
    @State private var newCategoryIsIncome: Bool = false
    
    // Search Text State
    @State private var searchText: String = ""
    
    var body: some View {
        List {
            Section("Expense Overview") {
                let pExpense = budget.plannedExpenses(for: month)
                let aExpense = budget.expensesInMonth(month)
                let dExpense = budget.expenseDiffInMonth(month)
                
                LabeledContent("Planned Expense", value: pExpense, format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Actual Expense", value: aExpense, format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Difference") {
                    Text(dExpense, format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(dExpense >= 0 ? .green : .red)
                        .fontWeight(.semibold)
                }
            }
            
            Section("Income Overview") {
                let pIncome = budget.plannedIncome(for: month)
                let aIncome = budget.incomeInMonth(month)
                let dIncome = budget.incomeDiffInMonth(month)
                
                LabeledContent("Planned Income", value: pIncome, format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Actual Income", value: aIncome, format: .currency(code: currencyManager.currencyCode))
                LabeledContent("Difference") {
                    Text(dIncome, format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(dIncome >= 0 ? .green : .red)
                        .fontWeight(.semibold)
                }
            }

            Section("Total Savings") {
                let savings = budget.remainingInMonth(month)
                LabeledContent("Savings") {
                    Text(savings, format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(savings >= 0 ? .green : .red)
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
                                    CategoryRowView(category: category, month: month)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            }
                        }
                    }
                    
                    if !incomes.isEmpty {
                        Section("Income Categories") {
                            ForEach(incomes) { category in
                                NavigationLink(destination: CategoryTransactionsView(category: category, month: month)) {
                                    CategoryRowView(category: category, month: month)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
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
                            
                            TextField("Amount", text: $newCategoryAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Picker("Type", selection: $newCategoryIsIncome) {
                                Text("Expense").tag(false)
                                Text("Income").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 160)
                            
                            Spacer()
                            
                            Button(action: addInlineCategory) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.appAccent)
                            }
                            .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty || (Decimal(string: newCategoryAmount) ?? 0) <= 0)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search categories")
        .navigationTitle(DateRangeHelper.monthYearString(from: month))
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
