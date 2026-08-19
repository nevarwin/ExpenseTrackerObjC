import SwiftUI
import SwiftData

struct BudgetCategoryRowView: View {
    let category: Category
    let month: Date?  // Optional month to display specific period data
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
    @Query(filter: #Predicate<Transaction> { $0.isActive == true })
    private var allTransactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs / 2) {
                    Text(category.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.appPrimary)
                    if let month = month {
                        Text(month.monthYearString)
                            .font(.caption)
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(spentAmount, format: .currency(code: currencyManager.currencyCode))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(isOverBudget ? .red : Color.appPrimary)
                    Text("of \(formatCurrency(category.allocatedAmount))")
                        .font(.caption2)
                        .foregroundStyle(Color.appSecondary)
                }
            }
            
            // Standardized Progress bar
            AppProgressBar(progress: usagePercentage, isOverBudget: isOverBudget)
            
            HStack {
                Label("\(Int(usagePercentage * 100))% used", systemImage: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(isOverBudget ? .red : Color.emeraldPrimary)
                Spacer()
                Text("\(transactionsCount) transaction\(transactionsCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(Color.appSecondary)
            }
        }
        .appCardStyle()
    }
    
    // MARK: - Computed Properties
    
    private var spentAmount: Decimal {
        if let month = month {
            return category.usedAmountInMonth(month)
        } else {
            return category.usedAmount
        }
    }
    
    private var usagePercentage: Double {
        if let month = month {
            // Guard against division by zero
            guard category.allocatedAmount > 0 else { return 0.0 }
            
            let used = category.usedAmountInMonth(month)
            return Double(truncating: NSDecimalNumber(decimal: used / category.allocatedAmount))
        } else {
            return category.usagePercentage
        }
    }
    
    private var isOverBudget: Bool {
        if let month = month {
            return category.usedAmountInMonth(month) > category.allocatedAmount
        } else {
            return category.isOverBudget
        }
    }
    
    private var transactionsCount: Int {
        if let month = month {
            return category.transactionsInMonth(month).count
        } else {
            return category.transactions.count
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyManager.currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currencyManager.currencySymbol)0.00"
    }
}
