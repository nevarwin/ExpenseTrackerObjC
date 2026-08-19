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
    
    @Query(filter: #Predicate<Budget> { $0.isActive == true }, sort: \Budget.startDate, order: .reverse)
    private var activeBudgets: [Budget]
    
    @State private var showingPayOffAlert = false
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedTransaction: Transaction?
    @State private var transactionToDelete: Transaction?
    @State private var errorMessage: String?
    @State private var transactionViewModel: TransactionViewModel?
    
    private var activeBudget: Budget? {
        activeBudgets.first
    }
    
    var body: some View {
        List {
            // Hero Status Card
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.appPrimary)
                                .accessibilityIdentifier("installment_detail_title")
                            
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
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Elapsed Duration")
                                .font(.caption)
                                .foregroundStyle(Color.appSecondary)
                            Text("\(plan.elapsedMonths()) / \(plan.totalMonths) Months")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.appPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Remaining Balance")
                                .font(.caption)
                                .foregroundStyle(Color.appSecondary)
                            Text(plan.remainingBalance, format: .currency(code: currencyManager.currencyCode))
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(plan.isCompleted ? Color.emeraldPrimary : Color.appPrimary)
                        }
                    }
                }
                .appCardStyle()
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
            
            // Financial Breakdown
            Section(header: Text("Financial Overview")) {
                LabeledContent("Total Amount", value: plan.totalAmount.formatted(.currency(code: currencyManager.currencyCode)))
                LabeledContent("Monthly Payment", value: plan.monthlyAmount.formatted(.currency(code: currencyManager.currencyCode)))
                LabeledContent("Total Paid", value: plan.totalPaidAmount.formatted(.currency(code: currencyManager.currencyCode)))
                LabeledContent("Remaining Months", value: "\(plan.remainingMonthsCount)")
                if !plan.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    LabeledContent("Notes", value: plan.notes)
                }
            }
            
            // Pay Off Early Primary Action
            if !plan.isCompleted && plan.remainingBalance > 0 {
                Section {
                    Button(action: { showingPayOffAlert = true }) {
                        HStack {
                            Spacer()
                            Label("Pay Off Remaining Balance Early", systemImage: "checkmark.circle.fill")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.emeraldPrimary)
                    .bouncyButtonStyle()
                    .accessibilityIdentifier("installment_pay_off_early_button")
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            
            // Generated Transactions List
            Section {
                if plan.transactions.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundStyle(Color.appSecondary.opacity(0.6))
                        Text("No transactions logged yet")
                            .font(.subheadline)
                            .foregroundStyle(Color.appSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(plan.transactions.sorted(by: { $0.date > $1.date })) { tx in
                        Button {
                            selectedTransaction = tx
                        } label: {
                            TransactionRowView(transaction: tx)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .accessibilityIdentifier("installment_transaction_row")
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                transactionToDelete = tx
                            } label: {
                                Label(String(localized: "Delete"), systemImage: "trash")
                            }
                            .accessibilityIdentifier("installment_tx_delete_button")
                            
                            Button {
                                selectedTransaction = tx
                            } label: {
                                Label(String(localized: "Edit"), systemImage: "pencil")
                            }
                            .tint(Color.emeraldPrimary)
                            .accessibilityIdentifier("installment_tx_edit_button")
                        }
                    }
                }
            } header: {
                Text("Generated Transactions (\(plan.transactions.count))")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appSecondary)
                    .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Installment Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label(String(localized: "Edit Plan"), systemImage: "pencil")
                    }
                    .accessibilityIdentifier("installment_detail_edit_menu_item")
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label(String(localized: "Delete Plan"), systemImage: "trash")
                    }
                    .accessibilityIdentifier("installment_detail_delete_menu_item")
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel(String(localized: "Menu"))
                        .accessibilityIdentifier("installment_detail_menu_button")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            InstallmentFormView(planToEdit: plan)
        }
        .sheet(item: $selectedTransaction) { transaction in
            if let budget = transaction.budget ?? activeBudget {
                TransactionFormView(
                    activeBudgets: activeBudgets,
                    initialBudget: budget,
                    viewModel: getTransactionViewModel(),
                    existingTransaction: transaction
                )
            }
        }
        .alert("Pay Off Early?", isPresented: $showingPayOffAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm Pay Off", role: .destructive) {
                payOffEarly()
            }
        } message: {
            Text("This will log a final transaction of \(plan.remainingBalance.formatted(.currency(code: currencyManager.currencyCode))) for the remaining balance and mark this installment plan as completed.")
        }
        .alert(String(localized: "Delete Installment Plan"), isPresented: $showingDeleteConfirmation) {
            Button(String(localized: "Delete"), role: .destructive) {
                deletePlan()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "Are you sure you want to delete this installment plan? All associated transactions will be permanently deleted."))
        }
        .alert(String(localized: "Delete Transaction"), isPresented: Binding(
            get: { transactionToDelete != nil },
            set: { if !$0 { transactionToDelete = nil } }
        )) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let tx = transactionToDelete {
                    deleteTransaction(tx)
                }
                transactionToDelete = nil
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                transactionToDelete = nil
            }
        } message: {
            Text(String(localized: "Are you sure you want to delete this generated installment transaction?"))
        }
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "OK")) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? String(localized: "An error occurred"))
        }
    }
    
    private func getTransactionViewModel() -> TransactionViewModel {
        if let vm = transactionViewModel {
            return vm
        }
        let vm = TransactionViewModel(modelContext: modelContext)
        transactionViewModel = vm
        return vm
    }
    
    private func payOffEarly() {
        guard let budget = activeBudget, let category = plan.transactions.first?.category ?? budget.categories.first else {
            errorMessage = "No active budget or category found for early payoff."
            return
        }
        let service = InstallmentService(modelContext: modelContext)
        do {
            try service.payOffEarly(plan: plan, in: budget, category: category)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func deleteTransaction(_ tx: Transaction) {
        if let cat = tx.category {
            cat.usedAmount = max(0, cat.usedAmount - tx.amount)
        }
        if let idx = plan.transactions.firstIndex(where: { $0.id == tx.id }) {
            plan.transactions.remove(at: idx)
        }
        modelContext.delete(tx)
        try? modelContext.save()
    }
    
    private func deletePlan() {
        let service = InstallmentService(modelContext: modelContext)
        do {
            try service.deleteInstallmentPlan(plan)
            dismiss()
        } catch {
            errorMessage = "Failed to delete plan: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        InstallmentDetailView(plan: InstallmentPlan(name: "Sample Plan", totalAmount: 1200, monthlyAmount: 100, startDate: Date(), totalMonths: 12))
            .environmentObject(SharedCurrencyService())
    }
}
