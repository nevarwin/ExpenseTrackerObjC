import SwiftUI
import SwiftData

struct BudgetCategoryRowView: View {
    let category: Category
    let month: Date?  // Optional month to display specific period data
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                CategoryIconBadge(
                    iconName: category.iconName,
                    tintColor: category.isIncome ? Color.emeraldPrimary : Color.dynamicAccent
                )
                .accessibilityIdentifier("category_row_icon_badge")
                
                VStack(alignment: .leading, spacing: AppSpacing.xs / 2) {
                    Text(category.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.appPrimary)
                    
                    Text(statusSubtitle.text)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(statusSubtitle.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(spentAmount, format: .currency(code: currencyManager.currencyCode))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(isOverBudget ? .red : Color.appPrimary)
                    Text(category.isIncome ? "goal \(formatCurrency(category.allocatedAmount))" : "of \(formatCurrency(category.allocatedAmount))")
                        .font(.caption2)
                        .foregroundStyle(Color.appSecondary)
                }
            }
            
            // Standardized Progress bar with 3-tier status
            AppProgressBar(progress: usagePercentage, status: progressStatus)
            
            HStack {
                Label(usageLabelText, systemImage: usageIconName)
                    .font(.caption)
                    .foregroundStyle(usageLabelColor)
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
        guard !category.isIncome else { return false }
        if let month = month {
            return category.usedAmountInMonth(month) > category.allocatedAmount
        } else {
            return category.isOverBudget
        }
    }
    
    private var progressStatus: AppProgressBar.Status {
        if category.isIncome {
            return .healthy
        }
        if isOverBudget {
            return .critical
        }
        if usagePercentage >= 0.8 {
            return .warning
        }
        return .healthy
    }
    
    private var statusSubtitle: (text: String, color: Color) {
        if category.isIncome {
            let diff = spentAmount - category.allocatedAmount
            if diff >= 0 {
                if diff == 0 {
                    return ("Goal reached", Color.emeraldPrimary)
                } else {
                    return ("+\(formatCurrency(diff)) surplus", Color.emeraldPrimary)
                }
            } else {
                let remainingToGoal = category.allocatedAmount - spentAmount
                return ("\(formatCurrency(remainingToGoal)) to goal", Color.appSecondary)
            }
        } else {
            let diff = category.allocatedAmount - spentAmount
            if diff >= 0 {
                return ("\(formatCurrency(diff)) left", Color.appSecondary)
            } else {
                let over = spentAmount - category.allocatedAmount
                return ("-\(formatCurrency(over)) over", .red)
            }
        }
    }
    
    private var usageLabelText: String {
        let percentage = Int(usagePercentage * 100)
        if category.isIncome {
            return "\(percentage)% of goal"
        } else {
            return "\(percentage)% used"
        }
    }
    
    private var usageIconName: String {
        if category.isIncome {
            return "target"
        } else if isOverBudget {
            return "exclamationmark.circle.fill"
        } else {
            return "chart.bar.fill"
        }
    }
    
    private var usageLabelColor: Color {
        switch progressStatus {
        case .critical:
            return .red
        case .warning:
            return .orange
        case .healthy:
            return Color.emeraldPrimary
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

