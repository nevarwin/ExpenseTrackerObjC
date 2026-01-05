//
//  BudgetListView.swift
//  ExpenseTracker
//
//  Created by raven on 8/4/25.
//

import SwiftUI
import CoreData

struct BudgetListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: BudgetListViewModel
    @State private var showBudgetForm = false
    
    init() {
        // Will use environment context
        _viewModel = StateObject(wrappedValue: BudgetListViewModel(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                budgetsList
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showBudgetForm) {
            BudgetDetailView(budget: nil, context: viewContext)
        }
        .onAppear {
            viewModel.fetchBudgets()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Budgets")
                .font(.system(size: 34, weight: .bold))
            Spacer()
            Button(action: {
                showBudgetForm = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var budgetsList: some View {
        List {
            Section(header: Text("Monthly Budgets"), 
                   footer: Text("Tap + to add a new budget category")) {
                ForEach(viewModel.budgets, id: \.objectID) { budget in
                    NavigationLink(destination: BudgetDetailView(budget: budget, context: viewContext)) {
                        BudgetRow(budget: budget, viewModel: viewModel)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteBudget(viewModel.budgets[index])
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct BudgetRow: View {
    let budget: Budget
    let viewModel: BudgetListViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(budget.name ?? "Unknown")
                .font(.system(size: 24, weight: .bold))
            
            if let createdAt = budget.createdAt {
                Text(createdAt, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Expenses: \(CurrencyFormatter.format(viewModel.totalExpenses(for: budget)))")
                Text("Income: \(CurrencyFormatter.format(viewModel.totalIncome(for: budget)))")
            }
            .font(.system(size: 14))
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BudgetListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

