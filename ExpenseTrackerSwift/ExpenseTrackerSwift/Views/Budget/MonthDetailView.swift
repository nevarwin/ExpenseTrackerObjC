import SwiftUI
import SwiftData

struct MonthDetailView: View {
    let budget: Budget
    let month: Date
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currencyManager: CurrencyManager
    
    private var isCurrentMonth: Bool {
        DateRangeHelper.isInCurrentMonth(month)
    }
    
    private var transactions: [Transaction] {
        budget.transactionsInMonth(month).sorted { $0.date > $1.date }
    }
    
    private var categories: [Category] {
        budget.categories.filter { $0.isActive }
    }
    
    var body: some View {
        List {
            // Overview Section
            Section("Overview") {
                LabeledContent("Budget Amount", value: budget.totalAmount, format: .currency(code: currencyManager.currencyCode))
                
                LabeledContent("Total Income") {
                    Text(budget.incomeInMonth(month), format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(.green)
                }
                
                LabeledContent("Total Expenses") {
                    Text(budget.expensesInMonth(month), format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(Color.appPrimary)
                }
                
                LabeledContent("Remaining") {
                    Text(budget.remainingInMonth(month), format: .currency(code: currencyManager.currencyCode))
                        .foregroundStyle(budget.remainingInMonth(month) >= 0 ? .green : .red)
                        .fontWeight(.semibold)
                }
            }
            
            // Transactions Section
            Section {
                if transactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.largeTitle)
                            .foregroundStyle(Color.appSecondary.opacity(0.3))
                        Text("No transactions")
                            .font(.subheadline)
                            .foregroundStyle(Color.appSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(transactions) { transaction in
                        TransactionRowView(transaction: transaction)
                    }
                }
            } header: {
                HStack {
                    Text("Transactions (\(transactions.count))")
                    Spacer()
                }
            }
            
            // Categories Section
            Section("Category Breakdown") {
                if categories.isEmpty {
                    Text("No categories")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(categories) { category in
                        CategoryMonthDetailRow(category: category, month: month)
                    }
                }
            }
        }
        .navigationTitle(DateRangeHelper.monthYearString(from: month))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCurrentMonth {
                ToolbarItem(placement: .primaryAction) {
                    Text("Current Month")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.appAccent)
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct CategoryMonthDetailRow: View {
    let category: Category
    let month: Date
    @EnvironmentObject var currencyManager: CurrencyManager
    
    private var usedAmount: Decimal {
        category.usedAmountInMonth(month)
    }
    
    private var remainingAmount: Decimal {
        category.remainingAmountInMonth(month)
    }
    
    private var usagePercentage: Double {
        guard category.allocatedAmount > 0 else { return 0 }
        return Double(truncating: (usedAmount / category.allocatedAmount) as NSDecimalNumber)
    }
    
    private var isOverBudget: Bool {
        usedAmount > category.allocatedAmount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: IconHelper.icon(for: category.name))
                    .foregroundStyle(Color.appAccent)
                    .font(.caption)
                    .padding(6)
                    .background(Color.appAccent.opacity(0.1))
                    .clipShape(Circle())
                
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(usedAmount, format: .currency(code: currencyManager.currencyCode))
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                    
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
                    
                    let progress = min(max(0, usagePercentage), 1.0)
                    Capsule()
                        .fill(isOverBudget ? Color.red : Color.appAccent)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    @Previewable @State var budget: Budget = {
        let b = Budget(name: "February Budget", totalAmount: 5000)
        return b
    }()
    
    NavigationStack {
        MonthDetailView(budget: budget, month: Date())
            .environmentObject(CurrencyManager())
    }
}

