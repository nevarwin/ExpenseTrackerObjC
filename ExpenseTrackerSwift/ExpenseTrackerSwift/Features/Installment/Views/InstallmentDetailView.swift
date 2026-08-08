//
//  InstallmentDetailView.swift
//  ExpenseTrackerSwift
//

import SwiftUI
import SwiftData

struct InstallmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
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
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Started \(plan.startDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(plan.isCompleted ? "Completed" : "Active")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 4)
                            .background(plan.isCompleted ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                            .foregroundColor(plan.isCompleted ? .green : .blue)
                            .clipShape(Capsule())
                    }
                    
                    ProgressView(value: plan.progressPercentage)
                        .tint(plan.isCompleted ? .green : .blue)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Elapsed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(plan.elapsedMonths()) / \(plan.totalMonths) Months")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Remaining Balance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(NSDecimalNumber(decimal: plan.remainingBalance).stringValue)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(plan.isCompleted ? .primary : .red)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.sm)
            }
            
            Section(header: Text("Financial Overview")) {
                LabeledContent("Total Amount", value: "$\(NSDecimalNumber(decimal: plan.totalAmount).stringValue)")
                LabeledContent("Monthly Amount", value: "$\(NSDecimalNumber(decimal: plan.monthlyAmount).stringValue)")
                LabeledContent("Total Paid", value: "$\(NSDecimalNumber(decimal: plan.totalPaidAmount).stringValue)")
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
                    .tint(.blue)
                }
            }
            
            Section(header: Text("Generated Transactions (\(plan.transactions.count))")) {
                if plan.transactions.isEmpty {
                    Text("No transactions logged yet.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(plan.transactions.sorted(by: { $0.date > $1.date })) { tx in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tx.formattedDescriptionForExport)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(tx.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("$\(NSDecimalNumber(decimal: tx.amount).stringValue)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
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
            Text("This will log a final transaction of $\(NSDecimalNumber(decimal: plan.remainingBalance).stringValue) for the remaining balance and mark this installment plan as completed.")
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
