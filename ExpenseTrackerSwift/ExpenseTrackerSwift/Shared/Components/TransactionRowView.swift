//
//  TransactionRowView.swift
//  ExpenseTrackerSwift
//

import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    @EnvironmentObject var currencyManager: SharedCurrencyService
    @EnvironmentObject var appearanceManager: SharedAppearanceService

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 40
    @State private var isRevealed: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            // Category Icon Badge
            ZStack {
                Circle()
                    .fill(Color.appLightGray)
                    .frame(width: iconSize, height: iconSize)
                
                if let category = transaction.category {
                    Image(systemName: category.iconName)
                        .foregroundStyle(appearanceManager.selectedAccent.color)
                        .font(.system(size: iconSize * 0.4))
                } else {
                    Image(systemName: "bag.fill")
                        .foregroundStyle(Color.appSecondary)
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs / 2) {
                Text(transaction.desc)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appPrimary)
                    .accessibilityIdentifier("transaction_desc")
                
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
                    .accessibilityIdentifier("transaction_amount_censored")
                    .onTapGesture {
                        appearanceManager.triggerHaptic(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            isRevealed.toggle()
                        }
                    }
            } else {
                Text(transaction.amount, format: .currency(code: currencyManager.currencyCode))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(transaction.isIncome ? Color.green : Color.appPrimary)
                    .accessibilityIdentifier("transaction_amount")
                    .onTapGesture {
                        if transaction.shouldCensorAmount {
                            appearanceManager.triggerHaptic(.light)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                isRevealed.toggle()
                            }
                        }
                    }
            }
        }
        .appCardStyle()
        .accessibilityIdentifier("transaction_row")
    }
}
