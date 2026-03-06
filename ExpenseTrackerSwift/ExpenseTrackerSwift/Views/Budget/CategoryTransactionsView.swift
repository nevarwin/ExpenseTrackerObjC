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

    private var usedAmount: Decimal {
        category.usedAmountInMonth(month)
    }

    private var usagePercentage: Double {
        guard category.allocatedAmount > 0 else { return 0 }
        return Double(truncating: (usedAmount / category.allocatedAmount) as NSDecimalNumber)
    }

    private var isOverBudget: Bool {
        usedAmount > category.allocatedAmount
    }

    var body: some View {
        List {
            // Category Summary Header
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: IconHelper.icon(for: category.name))
                            .font(.title2)
                            .foregroundStyle(Color.appAccent)
                            .padding(10)
                            .background(Color.appAccent.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.headline)
                            Text(DateRangeHelper.monthYearString(from: month))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(usedAmount, format: .currency(code: currencyManager.currencyCode))
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(isOverBudget ? .red : Color.appPrimary)
                            Text("of \(category.allocatedAmount.formatted(.currency(code: currencyManager.currencyCode)))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.appLightGray)
                                .frame(height: 6)
                            Capsule()
                                .fill(isOverBudget ? Color.red : Color.appAccent)
                                .frame(width: geometry.size.width * min(max(0, usagePercentage), 1.0), height: 6)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Label("\(Int(usagePercentage * 100))% used", systemImage: "chart.bar.fill")
                            .font(.caption)
                            .foregroundStyle(isOverBudget ? .red : Color.appAccent)
                        Spacer()
                        Text("\(transactions.count) transaction\(transactions.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

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
