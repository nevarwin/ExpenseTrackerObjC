//
//  BudgetDetailView.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BudgetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.analyticsService) private var analyticsService
    @EnvironmentObject var currencyManager: SharedCurrencyService
    let budget: Budget
    private let budgetCalculator: BudgetCalculator
    var viewModel: BudgetViewModel?
    
    init(budget: Budget, viewModel: BudgetViewModel? = nil) {
        self.budget = budget
        self.viewModel = viewModel
        self.budgetCalculator = BudgetCalculator(budget: budget)
    }
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
    // Add Month States
    @State private var showingAddMonthPicker = false
    @State private var pickerMonth = Calendar.current.component(.month, from: Date())
    @State private var pickerYear = Calendar.current.component(.year, from: Date())
    
    // Import Sheet State
    @State private var showingImportSheet = false

    var body: some View {
        List {
            // Add Month section
            Section {
                Button(action: { showingAddMonthPicker = true }) {
                    Label("Add Month", systemImage: "calendar.badge.plus")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.dynamicAccent)
                }
                .accessibilityIdentifier("budget_add_month_button")
            }
            
            // List of months
            Section("Budget Periods") {
                let periods = budgetCalculator.activeBudgetPeriods()
                if periods.isEmpty {
                    Text("No active budget months. Tap 'Add Month' or import templates to initialize.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(periods.reversed(), id: \.self) { month in
                        NavigationLink(destination: MonthlyBudgetDetailView(budget: budget, month: month, budgetViewModel: viewModel, budgetCalculator: budgetCalculator)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(month.monthYearString)
                                        .font(.headline)
                                    
                                    // Small summary of spent vs planned
                                    let planned = budgetCalculator.plannedExpenses(date: month)
                                    let spent = budgetCalculator.expensesInMonth(date: month)
                                    Text("Spent: \(spent.formatted(.currency(code: currencyManager.currencyCode))) / Planned: \(planned.formatted(.currency(code: currencyManager.currencyCode)))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                
                                // Progress pill
                                let remaining = budgetCalculator.remainingInMonth(date: month)
                                Text(remaining >= 0 ? "Under" : "Over")
                                    .font(.system(.caption2, design: .rounded))
                                    .fontWeight(.bold)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, 4)
                                    .background(remaining >= 0 ? Color.emeraldSurface : Color.red.opacity(0.12))
                                    .foregroundStyle(remaining >= 0 ? Color.emeraldPrimary : Color.red)
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle(budget.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        DefaultBudgetService.instance.setDefault(budget: budget)
                    } label: {
                        Label(
                            DefaultBudgetService.instance.isDefault(budget: budget) ? String(localized: "Default Budget") : String(localized: "Set as Default Budget"),
                            systemImage: DefaultBudgetService.instance.isDefault(budget: budget) ? "star.fill" : "star"
                        )
                    }
                    .disabled(DefaultBudgetService.instance.isDefault(budget: budget))
                    .accessibilityIdentifier("budget_set_default_menu_item")

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label(String(localized: "Delete Budget"), systemImage: "trash")
                    }
                    .accessibilityIdentifier("budget_delete_menu_item")
                    
                    Divider()
                    
                    Button {
                        showingEditSheet = true
                        analyticsService.trackEvent("Budget Edit Clicked (Detail)")
                    } label: {
                        Label(String(localized: "Edit Budget"), systemImage: "pencil")
                    }
                    .accessibilityIdentifier("budget_edit_menu_item")
                    
                    Divider()

                    Button {
                        showingImportSheet = true
                        analyticsService.trackEvent("Import CSV Clicked")
                    } label: {
                        Label("Import CSV Data", systemImage: "square.and.arrow.down")
                    }
                    .accessibilityIdentifier("budget_import_csv_menu_item")
                    
                    Divider()

                    NavigationLink {
                        BudgetHistoryView(budget: budget)
                    } label: {
                        Label("View History", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .accessibilityIdentifier("budget_history_menu_item")
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .accessibilityIdentifier("budget_detail_menu_button")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            BudgetFormView(
                viewModel: viewModel ?? BudgetViewModel(modelContext: modelContext),
                existingBudget: budget
            )
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView(targetBudget: budget)
        }
        .sheet(isPresented: $showingAddMonthPicker) {
            VStack(spacing: 20) {
                Text("Choose Month & Year")
                    .font(.headline)
                    .padding(.top)
                
                HStack(spacing: 0) {
                    Picker("Month", selection: $pickerMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(Calendar.current.monthSymbols[month - 1]).tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 150)
                    
                    Picker("Year", selection: $pickerYear) {
                        let currentYear = Calendar.current.component(.year, from: Date())
                        ForEach((currentYear - 5)...(currentYear + 5), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                }
                
                Button("Initialize Month") {
                    var components = DateComponents()
                    components.year = pickerYear
                    components.month = pickerMonth
                    if let selectedDate = Calendar.current.date(from: components) {
                        if let vm = viewModel {
                            try? vm.addBudgetPeriod(for: budget, month: selectedDate)
                        } else {
                            let vm = BudgetViewModel(modelContext: modelContext)
                            try? vm.addBudgetPeriod(for: budget, month: selectedDate)
                        }
                    }
                    showingAddMonthPicker = false
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .presentationDetents([.height(300)])
            .onAppear {
                pickerMonth = Calendar.current.component(.month, from: Date())
                pickerYear = Calendar.current.component(.year, from: Date())
            }
        }
        .alert(String(localized: "Delete Budget"), isPresented: $showingDeleteConfirmation) {
            Button(String(localized: "Delete"), role: .destructive) {
                deleteBudget()
                analyticsService.trackEvent("Budget Delete Confirmed (Detail)", properties: ["budget_name": budget.name])
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "Are you sure you want to delete this budget? All associated categories and transactions will be permanently deleted."))
        }
    }
    
    private func deleteBudget() {
        if let vm = viewModel {
            try? vm.deleteBudget(budget)
        } else {
            modelContext.delete(budget)
            try? modelContext.save()
        }
        dismiss()
    }
}
