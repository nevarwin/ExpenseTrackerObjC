import SwiftUI
import SwiftData

struct CategoryTransactionsView: View {
    let category: Category
    let month: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: SharedCurrencyService

    @Query(filter: #Predicate<Transaction> { $0.isActive == true }, sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]
    
    @Query(filter: #Predicate<Budget> { $0.isActive == true })
    private var activeBudgets: [Budget]

    @State private var showingAddTransaction = false
    @State private var showingEditCategory = false
    @State private var selectedTransaction: Transaction?
    @State private var transactionViewModel: TransactionViewModel?

    private var transactions: [Transaction] {
        category.transactionsInMonth(month).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            // Transactions
            Section {
                if transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundStyle(Color.appSecondary.opacity(0.4))
                        Text("No transactions this month")
                            .font(.subheadline)
                            .foregroundStyle(Color.appSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .accessibilityIdentifier("category_transactions_empty")
                } else {
                    ForEach(transactions) { transaction in
                        Button {
                            selectedTransaction = transaction
                        } label: {
                            TransactionRowView(transaction: transaction)
                        }
                        .accessibilityIdentifier("category_transaction_row")
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                try? transactionViewModel?.deleteTransaction(transaction)
                            } label: {
                                Label(String(localized: "Delete"), systemImage: "trash")
                            }
                            .accessibilityIdentifier("category_transaction_delete_button")
                            
                            Button {
                                selectedTransaction = transaction
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Color.emeraldPrimary)
                        }
                    }
                }
            } header: {
                Text("Transactions")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appSecondary)
                    .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditCategory = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityIdentifier("category_edit_button")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(activeBudgets.isEmpty)
                .accessibilityIdentifier("category_add_transaction_button")
            }
        }
        .sheet(item: $selectedTransaction) { transaction in
            if let budget = transaction.budget {
                TransactionFormView(
                    activeBudgets: activeBudgets.isEmpty ? [budget] : activeBudgets,
                    initialBudget: budget,
                    viewModel: transactionViewModel ?? TransactionViewModel(modelContext: modelContext),
                    existingTransaction: transaction
                )
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            if let budget = activeBudgets.first(where: { $0 == category.budget }) ?? activeBudgets.first {
                TransactionFormView(
                    activeBudgets: activeBudgets,
                    initialBudget: budget,
                    viewModel: transactionViewModel ?? TransactionViewModel(modelContext: modelContext),
                    initialCategory: category,
                    initialDate: month // Pre-fill with the month being viewed
                )
            }
        }
        .sheet(isPresented: $showingEditCategory) {
            CategoryEditFormView(category: category)
        }
        .onChange(of: category.isActive) { _, newValue in
            if !newValue {
                dismiss()
            }
        }
        .onAppear {
            if transactionViewModel == nil {
                transactionViewModel = TransactionViewModel(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    @Previewable @State var category: Category = {
        let c = Category(name: "Food & Dining", allocatedAmount: 500, isIncome: false, budgetPeriod: Date())
        return c
    }()

    NavigationStack {
        CategoryTransactionsView(category: category, month: Date())
            .environmentObject(SharedCurrencyService())
    }
}
