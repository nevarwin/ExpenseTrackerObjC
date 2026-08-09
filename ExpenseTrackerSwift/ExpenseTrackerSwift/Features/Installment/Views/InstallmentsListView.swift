//
//  InstallmentsListView.swift
//  ExpenseTrackerSwift
//

import SwiftUI
import SwiftData

struct InstallmentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InstallmentPlan.createdAt, order: .reverse) private var installmentPlans: [InstallmentPlan]
    
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if installmentPlans.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Active Installments")
                            .font(.headline)
                        Text("Add installment plans (such as a 2-year purchase) to track monthly elapsed payments and remaining balances.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                        
                        Button(action: { showingAddSheet = true }) {
                            Label("Add Installment Plan", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, AppSpacing.sm)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemGroupedBackground))
                } else {
                    List {
                        ForEach(installmentPlans) { plan in
                            NavigationLink(destination: InstallmentDetailView(plan: plan)) {
                                InstallmentRowView(plan: plan)
                            }
                        }
                        .onDelete(perform: deleteInstallments)
                    }
                }
            }
            .navigationTitle("Installments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                InstallmentFormView()
            }
        }
    }
    
    private func deleteInstallments(offsets: IndexSet) {
        let service = InstallmentService(modelContext: modelContext)
        for index in offsets {
            let plan = installmentPlans[index]
            try? service.deleteInstallmentPlan(plan)
        }
    }
}

struct InstallmentRowView: View {
    let plan: InstallmentPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text(plan.name)
                    .font(.headline)
                Spacer()
                Text("$\(NSDecimalNumber(decimal: plan.remainingBalance).stringValue) left")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(plan.isCompleted ? .green : .primary)
            }
            
            ProgressView(value: plan.progressPercentage)
                .tint(Color.emeraldPrimary)
                .padding(.vertical, 2)
            
            HStack {
                Text("Month \(plan.elapsedMonths()) of \(plan.totalMonths)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(NSDecimalNumber(decimal: plan.monthlyAmount).stringValue)/mo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}
