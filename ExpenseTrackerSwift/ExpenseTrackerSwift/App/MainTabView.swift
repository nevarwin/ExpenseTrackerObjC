//
//  MainTabView.swift
//  ExpenseTrackerSwift
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var budgetViewModel: BudgetViewModel?
    @State private var transactionViewModel: TransactionViewModel?
    @State private var showingAddTransaction = false
    
    @Query(filter: #Predicate<Budget> { $0.isActive == true })
    private var activeBudgets: [Budget]
    
    var body: some View {
        Group {
            if let viewModel = budgetViewModel {
                TabView {
                    TransactionListView()
                        .tabItem {
                            Label(String(localized: "Transactions"), systemImage: "list.bullet")
                        }
                    
                    BudgetListView(viewModel: viewModel)
                        .tabItem {
                            Label(String(localized: "Budget"), systemImage: "creditcard.fill")
                        }
                    
                    InstallmentsListView()
                        .tabItem {
                            Label(String(localized: "Installments"), systemImage: "calendar.badge.clock")
                        }
                }
            } else {
                ProgressView()
                    .onAppear {
                        modelContext.autosaveEnabled = false
                        let vm = BudgetViewModel(modelContext: modelContext)
                        vm.loadBudgets()
                        self.budgetViewModel = vm
                    }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            if let firstBudget = activeBudgets.first {
                TransactionQuickAddSheet(
                    viewModel: getTransactionViewModel(),
                    activeBudgets: activeBudgets,
                    initialBudget: firstBudget
                )
            }
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
}

#Preview {
    MainTabView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self, InstallmentPlan.self])
}
