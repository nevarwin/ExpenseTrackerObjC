import SwiftUI

struct ContentView: View {
    @StateObject private var currencyManager = CurrencyManager()
    @State private var budgetViewModel: BudgetViewModel?
    @State private var showingAddTransaction = false
    @State private var transactionViewModel: TransactionViewModel?
    @State private var activeBudgets: [Budget] = []

    var body: some View {
        Group {
            if let viewModel = budgetViewModel {
                TabView {
                    HomeView(viewModel: viewModel)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    
                    TransactionListView()
                        .tabItem {
                            Label("Transactions", systemImage: "list.bullet")
                        }
                }
            } else {
                ProgressView()
                    .onAppear {
                        let vm = BudgetViewModel()
                        vm.loadBudgets()
                        self.budgetViewModel = vm
                        // Load active budgets for quick-add sheet
                        activeBudgets = (try? BudgetRepository().fetchAll().filter { $0.isActive }) ?? []
                    }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            if let firstBudget = activeBudgets.first {
                QuickAddTransactionSheet(
                    viewModel: getTransactionViewModel(),
                    activeBudgets: activeBudgets,
                    initialBudget: firstBudget
                )
            }
        }
        .environmentObject(currencyManager)
    }
    
    private func getTransactionViewModel() -> TransactionViewModel {
        if let vm = transactionViewModel {
            return vm
        }
        let vm = TransactionViewModel()
        transactionViewModel = vm
        return vm
    }
}

#Preview {
    ContentView()
}
