import SwiftUI
import SwiftData

struct CategoryTransactionsView: View {
    let category: Category
    let month: Date
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currencyManager: CurrencyManager

    @Query(filter: #Predicate<Budget> { $0.isActive == true })
    private var activeBudgets: [Budget]

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
                } else {
                    ForEach(transactions) { transaction in
                        Button {
                            selectedTransaction = transaction
                        } label: {
                            TransactionRowView(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                try? transactionViewModel?.deleteTransaction(transaction)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                selectedTransaction = transaction
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            } header: {
                Text("Transactions")
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            if transactionViewModel == nil {
                transactionViewModel = TransactionViewModel(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    @Previewable @State var category: Category = {
        let c = Category(name: "Food & Dining", allocatedAmount: 500, isIncome: false)
        return c
    }()

    NavigationStack {
        CategoryTransactionsView(category: category, month: Date())
            .environmentObject(CurrencyManager())
    }
}
