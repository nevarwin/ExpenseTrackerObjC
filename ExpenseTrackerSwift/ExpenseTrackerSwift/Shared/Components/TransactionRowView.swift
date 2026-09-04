//
//  TransactionRowView.swift
//  ExpenseTrackerSwift
//

import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    var showOutline: Bool = true
    var showIconBelow: Bool = true

    @EnvironmentObject var currencyManager: SharedCurrencyService
    @EnvironmentObject var appearanceManager: SharedAppearanceService

    @State private var isRevealed: Bool = false

    private var outlineColor: Color? {
        guard showOutline else { return nil }
        return transaction.isIncome ? Color.emeraldPrimary : Color.red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Top row: Description and Amount
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Text(transaction.desc)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appPrimary)
                    .accessibilityIdentifier("transaction_desc")
                
                Spacer()
                
                amountView
            }
            
            // Middle row: Date and Budget Period
            HStack(spacing: AppSpacing.xs) {
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(Color.appSecondary)
                    .accessibilityIdentifier("transaction_date")
                
                Text("•")
                    .font(.caption)
                    .foregroundStyle(Color.appSecondary)
                
                Text(transaction.budgetPeriod.monthYearString)
                    .font(.caption)
                    .foregroundStyle(Color.appSecondary)
                    .accessibilityIdentifier("transaction_budget_period")
                
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
                        .accessibilityIdentifier("transaction_installment_badge")
                }
            }
            
            // Bottom row: Category icon and category name below the date & budget period
            if showIconBelow {
                HStack(spacing: 4) {
                    Image(systemName: transaction.iconName)
                        .font(.caption2)
                        .foregroundStyle(transaction.isIncome ? Color.emeraldPrimary : Color.dynamicAccent)
                    
                    if let categoryName = transaction.category?.name, !categoryName.isEmpty {
                        Text(categoryName)
                            .font(.caption2)
                            .foregroundStyle(Color.appSecondary)
                    }
                }
                .accessibilityIdentifier("transaction_category_below")
            }
        }
        .appCardStyle(
            borderColor: outlineColor,
            borderWidth: 1
        )
        .accessibilityIdentifier("transaction_row")
    }

    @ViewBuilder
    private var amountView: some View {
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
}

#Preview {
    let expenseCategory = Category(name: "Groceries", allocatedAmount: 500, isIncome: false, budgetPeriod: Date())
    let incomeCategory = Category(name: "Salary", allocatedAmount: 5000, isIncome: true, budgetPeriod: Date())

    let expenseTx = Transaction(
        amount: 84.50,
        description: "Whole Foods Market",
        date: Date(),
        category: expenseCategory
    )

    let incomeTx = Transaction(
        amount: 3200.00,
        description: "Monthly Paycheck",
        date: Date(),
        category: incomeCategory
    )

    VStack(spacing: 16) {
        TransactionRowView(transaction: expenseTx)
        TransactionRowView(transaction: incomeTx)
        TransactionRowView(transaction: expenseTx, showIconBelow: false)
    }
    .padding()
    .background(Color.appBackground)
    .environmentObject(SharedCurrencyService())
    .environmentObject(SharedAppearanceService())
}
