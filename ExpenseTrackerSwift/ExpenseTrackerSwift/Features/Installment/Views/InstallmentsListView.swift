//
//  InstallmentsListView.swift
//  ExpenseTrackerSwift
//

import SwiftUI
import SwiftData

struct InstallmentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InstallmentPlan.createdAt, order: .reverse) private var installmentPlans: [InstallmentPlan]
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if installmentPlans.isEmpty {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.appSecondary)
                        Text("No Active Installments")
                            .headerStyle()
                        Text("Add installment plans (such as a 2-year purchase) to track monthly elapsed payments and remaining balances.")
                            .font(.body)
                            .foregroundStyle(Color.appSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                        
                        Button(action: { showingAddSheet = true }) {
                            Label("Add Installment Plan", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.emeraldPrimary)
                        .padding(.top, AppSpacing.sm)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .systemGroupedBackground))
                } else {
                    List {
                        ForEach(installmentPlans) { plan in
                            ZStack {
                                InstallmentRowView(plan: plan)
                                
                                NavigationLink(destination: InstallmentDetailView(plan: plan)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .onDelete(perform: deleteInstallments)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemGroupedBackground))
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
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                CategoryIconBadge(iconName: "creditcard.fill")
                
                VStack(alignment: .leading, spacing: AppSpacing.xs / 2) {
                    Text(plan.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.appPrimary)
                    Text("Month \(plan.elapsedMonths()) of \(plan.totalMonths)")
                        .font(.caption)
                        .foregroundStyle(Color.appSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.remainingBalance, format: .currency(code: currencyManager.currencyCode))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(plan.isCompleted ? Color.emeraldPrimary : Color.appPrimary)
                    Text("\(plan.monthlyAmount.formatted(.currency(code: currencyManager.currencyCode)))/mo")
                        .font(.caption2)
                        .foregroundStyle(Color.appSecondary)
                }
            }
            
            AppProgressBar(progress: plan.progressPercentage)
        }
        .appCardStyle()
    }
}

#Preview {
    InstallmentsListView()
        .modelContainer(for: [InstallmentPlan.self, Transaction.self, Budget.self])
        .environmentObject(SharedCurrencyService())
}
