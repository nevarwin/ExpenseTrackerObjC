import SwiftUI
import SwiftData

struct BudgetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let budget: Budget
    
    @State private var categoryViewModel: CategoryViewModel?
    @State private var transactionViewModel: TransactionViewModel?
    @State private var showingEditSheet = false
    
    var body: some View {
        List {
            Section("Budget Overview") {
                LabeledContent("Total Budget", value: budget.totalAmount, format: .currency(code: "USD"))
                LabeledContent("Total Income", value: budget.totalIncome, format: .currency(code: "USD"))
                LabeledContent("Total Expenses", value: budget.totalExpenses, format: .currency(code: "USD"))
                LabeledContent("Remaining") {
                    Text(budget.remainingAmount, format: .currency(code: "USD"))
                        .foregroundStyle(budget.remainingAmount >= 0 ? .green : .red)
                        .fontWeight(.semibold)
                }
            }
            
            Section("Categories") {
                if let viewModel = categoryViewModel {
                    if viewModel.categories.isEmpty {
                        Text("No categories")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.categories) { category in
                            CategoryRowView(category: category)
                        }
                    }
                }
            }
            
            Section("Recent Transactions") {
                if let viewModel = transactionViewModel {
                    if viewModel.transactions.isEmpty {
                        Text("No transactions")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.transactions.prefix(10)) { transaction in
                            TransactionRowView(transaction: transaction)
                        }
                    }
                }
            }
        }
        .navigationTitle(budget.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            BudgetFormView(
                viewModel: BudgetViewModel(modelContext: modelContext),
                existingBudget: budget
            )
        }
        .onAppear {
            if categoryViewModel == nil {
                categoryViewModel = CategoryViewModel(modelContext: modelContext)
                categoryViewModel?.loadCategories(for: budget)
            }
            
            if transactionViewModel == nil {
                transactionViewModel = TransactionViewModel(modelContext: modelContext)
                transactionViewModel?.loadTransactions(for: budget)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Budget.self, configurations: config)
    let budget = Budget(name: "Monthly Budget", totalAmount: 5000)
    container.mainContext.insert(budget)
    
    return NavigationStack {
        BudgetDetailView(budget: budget)
            .modelContainer(container)
    }
}
