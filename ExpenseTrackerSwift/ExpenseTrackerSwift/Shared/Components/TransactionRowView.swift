//
//  TransactionRowView.swift
//  ExpenseTrackerSwift
//

import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    @EnvironmentObject var currencyManager: SharedCurrencyService
    @EnvironmentObject var appearanceManager: SharedAppearanceService

    @State private var isRevealed: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.xs / 2) {
                Text(transaction.desc)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appPrimary)
                    .accessibilityIdentifier("transaction_desc")
                
                HStack(spacing: AppSpacing.xs) {
                    Text(transaction.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color.appSecondary)
                    
                    if let idx = transaction.installmentIndex, let total = transaction.installmentTotalMonths {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(Color.appSecondary)
                        
                        Text("Month \(idx)/\(total)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appLightGray)
                            .foregroundStyle(Color.appPrimary)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            if transaction.shouldCensorAmount && !isRevealed {
                Text("****")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(transaction.isIncome ? Color.emeraldPrimary : Color.appPrimary)
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
                    .foregroundStyle(transaction.isIncome ? Color.emeraldPrimary : Color.appPrimary)
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
