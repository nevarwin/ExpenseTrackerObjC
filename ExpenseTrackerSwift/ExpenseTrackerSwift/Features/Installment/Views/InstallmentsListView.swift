//
//  InstallmentsListView.swift
//  ExpenseTrackerSwift
//

import SwiftUI
import SwiftData

enum InstallmentFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    
    var id: String { rawValue }
}

struct InstallmentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InstallmentPlan.createdAt, order: .reverse) private var installmentPlans: [InstallmentPlan]
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
    @State private var selectedFilter: InstallmentFilter = .all
    @State private var searchText: String = ""
    @State private var showingAddSheet = false
    @State private var installmentToDelete: InstallmentPlan?
    @State private var installmentToEdit: InstallmentPlan?
    
    private var activePlans: [InstallmentPlan] {
        installmentPlans.filter { !$0.isCompleted }
    }
    
    private var completedPlans: [InstallmentPlan] {
        installmentPlans.filter { $0.isCompleted }
    }
    
    private var totalRemainingCommitment: Decimal {
        activePlans.reduce(0) { $0 + $1.remainingBalance }
    }
    
    private var totalMonthlyCommitment: Decimal {
        activePlans.reduce(0) { $0 + $1.monthlyAmount }
    }
    
    private var filteredPlans: [InstallmentPlan] {
        var result = installmentPlans
        switch selectedFilter {
        case .all:
            break
        case .active:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        }
        
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(trimmed) ||
                $0.notes.localizedCaseInsensitiveContains(trimmed)
            }
        }
        return result
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if installmentPlans.isEmpty {
                    emptyStateView
                } else {
                    List {
                        // Section 1: Summary Header Card
                        Section {
                            InstallmentsSummaryCardView(
                                totalRemaining: totalRemainingCommitment,
                                monthlyTotal: totalMonthlyCommitment,
                                activeCount: activePlans.count,
                                completedCount: completedPlans.count
                            )
                            .accessibilityIdentifier("installment_summary_header")
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        
                        // Section 2: Filter Segment
                        Section {
                            Picker("Filter", selection: $selectedFilter) {
                                ForEach(InstallmentFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityIdentifier("installment_filter_picker")
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                        
                        // Section 3: List items or search empty state
                        if filteredPlans.isEmpty {
                            VStack(spacing: AppSpacing.sm) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.appSecondary)
                                Text("No Matching Installments")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundStyle(Color.appPrimary)
                                Text("Try adjusting your search or filter options.")
                                    .font(.caption)
                                    .foregroundStyle(Color.appSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.xl)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .accessibilityIdentifier("installment_no_matches_view")
                        } else {
                            ForEach(filteredPlans) { plan in
                                ZStack {
                                    InstallmentRowView(plan: plan)
                                    
                                    NavigationLink(destination: InstallmentDetailView(plan: plan)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        installmentToDelete = plan
                                    } label: {
                                        Label(String(localized: "Delete"), systemImage: "trash")
                                    }
                                    .accessibilityIdentifier("installment_delete_button")
                                    
                                    Button {
                                        installmentToEdit = plan
                                    } label: {
                                        Label(String(localized: "Edit"), systemImage: "pencil")
                                    }
                                    .tint(Color.emeraldPrimary)
                                    .accessibilityIdentifier("installment_edit_button")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemGroupedBackground))
                    .searchable(text: $searchText, prompt: "Search installments...")
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationTitle("Installments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("installment_add_toolbar_button")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                InstallmentFormView()
            }
            .sheet(item: $installmentToEdit) { plan in
                InstallmentFormView(planToEdit: plan)
            }
            .alert(
                String(localized: "Delete Installment"),
                isPresented: Binding(
                    get: { installmentToDelete != nil },
                    set: { if !$0 { installmentToDelete = nil } }
                )
            ) {
                Button(String(localized: "Delete"), role: .destructive) {
                    if let plan = installmentToDelete {
                        deleteInstallment(plan)
                    }
                    installmentToDelete = nil
                }
                Button(String(localized: "Cancel"), role: .cancel) {
                    installmentToDelete = nil
                }
            } message: {
                Text(String(localized: "Are you sure you want to delete this installment plan? All associated transactions will be permanently deleted."))
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
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
            .bouncyButtonStyle()
            .padding(.top, AppSpacing.sm)
            .accessibilityIdentifier("installment_empty_add_button")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .accessibilityIdentifier("installment_empty_state_view")
    }
    
    private func deleteInstallment(_ plan: InstallmentPlan) {
        let service = InstallmentService(modelContext: modelContext)
        try? service.deleteInstallmentPlan(plan)
    }
}

// MARK: - Installments Summary Card View

struct InstallmentsSummaryCardView: View {
    let totalRemaining: Decimal
    let monthlyTotal: Decimal
    let activeCount: Int
    let completedCount: Int
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Remaining Debt")
                        .font(.caption)
                        .foregroundStyle(Color.appSecondary)
                    
                    Text(totalRemaining, format: .currency(code: currencyManager.currencyCode))
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.appPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Monthly Commitment")
                        .font(.caption)
                        .foregroundStyle(Color.appSecondary)
                    
                    Text("\(monthlyTotal.formatted(.currency(code: currencyManager.currencyCode)))/mo")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.emeraldPrimary)
                }
            }
            
            HStack(spacing: AppSpacing.sm) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.emeraldPrimary)
                        .frame(width: 6, height: 6)
                    Text("\(activeCount) Active")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.emeraldSurface)
                .foregroundStyle(Color.emeraldPrimary)
                .clipShape(Capsule())
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.appSecondary)
                        .frame(width: 6, height: 6)
                    Text("\(completedCount) Completed")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.appLightGray)
                .foregroundStyle(Color.appPrimary)
                .clipShape(Capsule())
                
                Spacer()
            }
        }
        .appCardStyle()
    }
}

// MARK: - Installment Row View

struct InstallmentRowView: View {
    let plan: InstallmentPlan
    @EnvironmentObject var currencyManager: SharedCurrencyService
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                CategoryIconBadge(
                    iconName: "creditcard.fill",
                    tintColor: plan.isCompleted ? Color.emeraldPrimary : Color.dynamicAccent
                )
                .accessibilityIdentifier("installment_icon_badge")
                
                VStack(alignment: .leading, spacing: AppSpacing.xs / 2) {
                    Text(plan.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.appPrimary)
                        .accessibilityIdentifier("installment_row_name")
                    
                    HStack(spacing: AppSpacing.xs) {
                        Text("Month \(plan.elapsedMonths()) of \(plan.totalMonths)")
                            .font(.caption)
                            .foregroundStyle(Color.appSecondary)
                        
                        if plan.isCompleted {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(Color.appSecondary)
                            
                            Text("Completed")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.emeraldSurface)
                                .foregroundStyle(Color.emeraldPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.remainingBalance, format: .currency(code: currencyManager.currencyCode))
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(plan.isCompleted ? Color.emeraldPrimary : Color.appPrimary)
                        .accessibilityIdentifier("installment_row_remaining_balance")
                    
                    Text("\(plan.monthlyAmount.formatted(.currency(code: currencyManager.currencyCode)))/mo")
                        .font(.caption2)
                        .foregroundStyle(Color.appSecondary)
                }
            }
            
            AppProgressBar(progress: plan.progressPercentage)
            
            HStack {
                Label("\(Int(plan.progressPercentage * 100))% paid", systemImage: plan.isCompleted ? "checkmark.circle.fill" : "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(plan.isCompleted ? Color.emeraldPrimary : Color.appSecondary)
                
                Spacer()
                
                Text(plan.isCompleted ? "All settled" : "\(plan.remainingMonthsCount) mo\(plan.remainingMonthsCount == 1 ? "" : "s") left")
                    .font(.caption)
                    .foregroundStyle(Color.appSecondary)
            }
        }
        .appCardStyle()
        .accessibilityIdentifier("installment_row_\(plan.name)")
    }
}

#Preview {
    InstallmentsListView()
        .modelContainer(for: [InstallmentPlan.self, Transaction.self, Budget.self])
        .environmentObject(SharedCurrencyService())
}
