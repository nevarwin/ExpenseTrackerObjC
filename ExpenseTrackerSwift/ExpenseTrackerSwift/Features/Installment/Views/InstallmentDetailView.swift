//
//  InstallmentDetailView.swift
//  ExpenseTrackerSwift
//

import SwiftUI
import SwiftData

struct InstallmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
    let plan: InstallmentPlan
    
    @Query(sort: \Budget.startDate, order: .reverse) private var budgets: [Budget]
    @State private var showingPayOffAlert = false
    @State private var errorMessage: String?
    
    private var activeBudget: Budget? {
        budgets.first
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.appPrimary)
                            Text("Started \(plan.startDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(Color.appSecondary)
                        }
                        Spacer()
                        Text(plan.isCompleted ? "Completed" : "Active")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 4)
                            .background(plan.isCompleted ? Color.emeraldSurface : Color.appLightGray)
                            .foregroundStyle(plan.isCompleted ? Color.emeraldPrimary : Color.appPrimary)
                            .clipShape(Capsule())
                    }
                    
                    AppProgressBar(progress: plan.progressPercentage)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Elapsed")
                                .font(.caption)
                                .foregroundStyle(Color.appSecondary)
                            Text("\(plan.elapsedMonths()) / \(plan.totalMonths) Months")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.appPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Remaining Balance")
                                .font(.caption)
                                .foregroundStyle(Color.appSecondary)
                            Text(plan.remainingBalance, format: .currency(code: currencyManager.currencyCode))
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(plan.isCompleted ? Color.emeraldPrimary : .red)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.sm)
            }
            
            Section(header: Text("Financial Overview")) {
                LabeledContent("Total Amount", value: plan.totalAmount.formatted(.currency(code: currencyManager.currencyCode)))
                LabeledContent("Monthly Amount", value: plan.monthlyAmount.formatted(.currency(code: currencyManager.currencyCode)))
                LabeledContent("Total Paid", value: plan.totalPaidAmount.formatted(.currency(code: currencyManager.currencyCode)))
                LabeledContent("Remaining Months", value: "\(plan.remainingMonthsCount)")
            }
            
            if !plan.isCompleted && plan.remainingBalance > 0 {
                Section {
                    Button(action: { showingPayOffAlert = true }) {
                        HStack {
                            Spacer()
                            Label("Pay Off Remaining Balance Early", systemImage: "checkmark.circle.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .tint(Color.emeraldPrimary)
                }
            }
            
            Section(header: Text("Generated Transactions (\(plan.transactions.count))")) {
                if plan.transactions.isEmpty {
                    Text("No transactions logged yet.")
                        .foregroundStyle(Color.appSecondary)
                        .font(.subheadline)
                } else {
                    ForEach(plan.transactions.sorted(by: { $0.date > $1.date })) { tx in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tx.formattedDescriptionForExport)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.appPrimary)
                                Text(tx.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(Color.appSecondary)
                            }
                            Spacer()
                            Text(tx.amount, format: .currency(code: currencyManager.currencyCode))
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Installment Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Pay Off Early?", isPresented: $showingPayOffAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm Pay Off", role: .destructive) {
                payOffEarly()
            }
        } message: {
            Text("This will log a final transaction of \(plan.remainingBalance.formatted(.currency(code: currencyManager.currencyCode))) for the remaining balance and mark this installment plan as completed.")
        }
    }
    
    private func payOffEarly() {
        guard let budget = activeBudget, let category = plan.transactions.first?.category ?? budget.categories.first else {
            return
        }
        let service = InstallmentService(modelContext: modelContext)
        do {
            try service.payOffEarly(plan: plan, in: budget, category: category)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        InstallmentDetailView(plan: InstallmentPlan(name: "Sample Plan", totalAmount: 1200, monthlyAmount: 100, startDate: Date(), totalMonths: 12))
            .environmentObject(SharedCurrencyService())
    }
}
