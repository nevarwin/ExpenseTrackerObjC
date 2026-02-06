import SwiftUI
import SwiftData

struct CategoryRowView: View {
    let category: Category
    @EnvironmentObject var currencyManager: CurrencyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category.name)
                    .font(.body)
                
                if category.isInstallment {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(Color.appAccent)
                }
                
                Spacer()
                
                Text("\(Int(category.usagePercentage * 100))%")
                    .font(.caption)
                    .foregroundStyle(Color.appSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.appLightGray)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(category.isOverBudget ? Color.red : Color.appAccent)
                        .frame(width: geometry.size.width * min(category.usagePercentage, 1.0), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            if category.isInstallment {
                HStack {
                    Text(category.remainingInstallmentMonths.map { "\($0) months left" } ?? "")
                    Spacer()
                    if let total = category.totalInstallmentAmount {
                        Text("Total: \(formatCurrency(total))")
                    }
                }
                .font(.caption2)
                .foregroundStyle(Color.appSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyManager.currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currencyManager.currencySymbol)0.00"
    }
}
