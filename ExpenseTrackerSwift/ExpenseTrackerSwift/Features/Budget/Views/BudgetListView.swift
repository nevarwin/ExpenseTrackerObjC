//
//  BudgetListView.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BudgetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.analyticsService) private var analyticsService
    @State private var internalViewModel: BudgetViewModel?
    private let injectedViewModel: BudgetViewModel?
    
    private var viewModel: BudgetViewModel? {
        injectedViewModel ?? internalViewModel
    }
    
    init(viewModel: BudgetViewModel? = nil) {
        self.injectedViewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                
                if let viewModel = viewModel {
                    HomeContent(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(String(localized: "Budgets"))
            .onAppear {
                analyticsService.trackScreen("Home")
                if injectedViewModel == nil && internalViewModel == nil {
                    let vm = BudgetViewModel(modelContext: modelContext)
                    self.internalViewModel = vm
                    vm.loadBudgets()
                }
            }
        }
    }
}

struct HomeContent: View {
    @Environment(\.analyticsService) private var analyticsService
    @ObservedObject var viewModel: BudgetViewModel
    
    @State private var showingAddBudget = false
    @State private var budgetToEdit: Budget?
    @State private var showingError = false
    @State private var budgetToDelete: Budget?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Cards
                if viewModel.budgets.isEmpty {
                    EmptyBudgetCard(viewModel: viewModel) {
                        showingAddBudget = true
                    }
                    .padding(.horizontal)
                } else {
                    ForEach(viewModel.budgets) { budget in
                        NavigationLink(destination: BudgetDetailView(budget: budget, viewModel: viewModel)) {
                            BudgetCardView(budget: budget)
                                .padding(.horizontal)
                                .id(budget.id)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                budgetToDelete = budget
                            } label: {
                                Label(String(localized: "Delete"), systemImage: "trash")
                            }
                            
                            Button {
                                budgetToEdit = budget
                                analyticsService.trackEvent("Budget Edit Swiped")
                            } label: {
                                Label(String(localized: "Edit"), systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            viewModel.loadBudgets()
        }
        .sheet(
            isPresented: $showingAddBudget,
            onDismiss: {
                viewModel.loadBudgets()
            }
        ) {
            BudgetFormView(viewModel: viewModel)
        }
        .sheet(item: $budgetToEdit, onDismiss: {
            viewModel.loadBudgets()
        }) { budget in
            BudgetFormView(viewModel: viewModel, existingBudget: budget)
        }
        .alert(String(localized: "Error"), isPresented: $showingError) {
            Button(String(localized: "OK")) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? String(localized: "An error occurred"))
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            showingError = newValue != nil
        }
        .confirmationDialog(
            String(localized: "Delete Budget"),
            isPresented: Binding(
                get: { budgetToDelete != nil },
                set: { if !$0 { budgetToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive) {
                if let budget = budgetToDelete {
                    try? viewModel.deleteBudget(budget)
                    analyticsService.trackEvent("Budget Delete Confirmed", properties: ["budget_name": budget.name])
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                budgetToDelete = nil
            }
        } message: {
            Text(String(localized: "Are you sure you want to delete this budget? All associated categories and transactions will be permanently deleted."))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    toolbarMenu
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityLabel(String(localized: "Menu"))
                        .accessibilityIdentifier("budget_menu_button")
                }
            }
        }
    }
    
    @ViewBuilder
    private var toolbarMenu: some View {
        Button {
            showingAddBudget = true
            analyticsService.trackEvent("Budget Add Button Clicked")
        } label: {
            Label(String(localized: "Add Budget"), systemImage: "plus")
        }
        
        Divider()
        
        NavigationLink {
            SettingsView()
        } label: {
            Label(String(localized: "Settings"), systemImage: "gearshape.fill")
        }
        .accessibilityIdentifier("settings_menu_item")
    }
}

struct BudgetCardView: View {
    let budget: Budget
    @State private var selectedMonthIndex: Int = 0
    private let budgetCalculator: BudgetCalculator
    @EnvironmentObject var currencyManager: SharedCurrencyService
    @State private var animatedProgress: Double = 0
    
    init(budget: Budget) {
        self.budget = budget
        self.budgetCalculator = BudgetCalculator(budget: budget)
    }
    
    private var availableMonths: [Date] {
        let activePeriods = budgetCalculator.activeBudgetPeriods()
        return activePeriods.isEmpty ? [Date()] : activePeriods
    }
    
    private var displayMonth: Date {
        if selectedMonthIndex < availableMonths.count {
            return availableMonths[selectedMonthIndex]
        }
        return availableMonths.last ?? Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: Budget Name & Month Selector
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.appPrimary)
                    
                    Text("\(displayMonth.monthYearString) Budget")
                        .subheaderStyle()
                }
                
                Spacer()
                
                // Month Selector Pill
                if availableMonths.count > 1 {
                    Menu {
                        ForEach(Array(availableMonths.enumerated()), id: \.offset) { index, month in
                            Button {
                                selectedMonthIndex = index
                            } label: {
                                HStack {
                                    Text(month.monthYearString)
                                    if index == selectedMonthIndex {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(displayMonth.monthYearString)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.appPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.appLightGray)
                        .clipShape(Capsule())
                    }
                } else {
                    Text(displayMonth.monthYearString)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.appSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.appLightGray)
                        .clipShape(Capsule())
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(String(localized: "Income"))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(budgetCalculator.incomeInMonth(date: displayMonth), format: .currency(code: currencyManager.currencyCode))
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                            Text("/ " + budgetCalculator.plannedIncome(date: displayMonth).formatted(.currency(code: currencyManager.currencyCode)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(String(localized: "Expenses"))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(budgetCalculator.expensesInMonth(date: displayMonth), format: .currency(code: currencyManager.currencyCode))
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(budgetCalculator.expensesInMonth(date: displayMonth) > budgetCalculator.plannedExpenses(date: displayMonth) ? .red : .appPrimary)
                            Text("/ " + budgetCalculator.plannedExpenses(date: displayMonth).formatted(.currency(code: currencyManager.currencyCode)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Progress Bar (Expense vs Planned)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appLightGray)
                            .frame(height: 12)
                        
                        let isOverBudget = budgetCalculator.expensesInMonth(date: displayMonth) > budgetCalculator.plannedExpenses(date: displayMonth) && budgetCalculator.plannedExpenses(date: displayMonth) > 0
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        isOverBudget ? Color.red : Color.appAccent,
                                        isOverBudget ? Color.orange : Color.cyan
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(geometry.size.width * animatedProgress, geometry.size.width)), height: 12)
                    }
                }
                .frame(height: 12)
                .accessibilityLabel(String(localized: "Budget Progress"))
                .accessibilityValue(String(localized: "\(Int(animatedProgress * 100))% spent"))
            }
        }
        .appCardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "View details for budget \(budget.name)"))
        .onAppear {
            updateProgress()
        }
        .onChange(of: budget.transactions) { _, _ in
            updateProgress()
        }
        .onChange(of: budget.categories) { _, _ in
            updateProgress()
        }
    }
    
    private func updateProgress() {
        let planned = budgetCalculator.plannedExpenses(date: displayMonth)
        let spent = budgetCalculator.expensesInMonth(date: displayMonth)
        let progress = planned > 0 ? min(max(0, Double(truncating: (spent / planned) as NSDecimalNumber)), 1.0) : 0
        
        withAnimation(.spring(duration: 1.0)) {
            animatedProgress = progress
        }
    }
}

struct EmptyBudgetCard: View {
    @Environment(\.analyticsService) private var analyticsService
    var viewModel: BudgetViewModel?
    var onAddBudget: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.appAccent)
                .padding(.top, 8)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text(String(localized: "No Active Budget"))
                    .headerStyle()
                
                Text(String(localized: "Create your first budget to start tracking your expenses effectively."))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.appSecondary)
                    .padding(.horizontal)
            }
            
            Button(action: {
                onAddBudget?()
                analyticsService.trackEvent("Budget Create New Clicked (Empty State)")
            }) {
                Text(String(localized: "Create New Budget"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appAccent)
                    .cornerRadius(12)
                    .shadow(color: Color.appAccent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .appCardStyle()
    }
}


#Preview {
    BudgetListView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
        .environmentObject(SharedCurrencyService())
}

