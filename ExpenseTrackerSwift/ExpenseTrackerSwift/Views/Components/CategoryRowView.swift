import SwiftUI
import SwiftData

struct CategoryRowView: View {
    let category: Category
    let month: Date?  // Optional month to display specific period data
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @Query(filter: #Predicate<Transaction> { $0.isActive == true })
    private var allTransactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text(category.name)
                        .font(.headline)
                    if let month = month {
                        Text(DateRangeHelper.monthYearString(from: month))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(spentAmount, format: .currency(code: currencyManager.currencyCode))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(isOverBudget ? .red : Color.appPrimary)
                    Text("of \(formatCurrency(category.allocatedAmount))")
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
                Text("\(transactionsCount) transaction\(transactionsCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
