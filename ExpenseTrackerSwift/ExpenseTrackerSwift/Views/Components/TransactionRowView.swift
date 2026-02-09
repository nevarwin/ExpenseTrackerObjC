import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    @EnvironmentObject var currencyManager: CurrencyManager
    
    @State private var isRevealed: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.appLightGray)
                    .frame(width: 40, height: 40)
                
                if let category = transaction.category {
                    Image(systemName: IconHelper.icon(for: category.name))
                        .foregroundStyle(Color.appAccent)
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "bag.fill")
                    .foregroundStyle(Color.appSecondary)
                    .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.desc)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appPrimary)
                
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(Color.appSecondary)
            }
            
            Spacer()
            
            if transaction.shouldCensorAmount && !isRevealed {
                Text("****")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(transaction.isIncome ? Color.green : Color.appPrimary)
                    .onTapGesture {
                        withAnimation {
                            isRevealed.toggle()
                        }
                    }
            } else {
                Text(transaction.amount, format: .currency(code: currencyManager.currencyCode))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(transaction.isIncome ? Color.green : Color.appPrimary)
                    .onTapGesture {
                        if transaction.shouldCensorAmount {
                            withAnimation {
                                isRevealed.toggle()
                            }
                        }
                    }
            }
        }
    }
}
