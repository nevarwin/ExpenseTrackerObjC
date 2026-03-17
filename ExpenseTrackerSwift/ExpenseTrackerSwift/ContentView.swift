import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var currencyManager = CurrencyManager()
    @State private var budgetViewModel: BudgetViewModel?
    @State private var showingAddTransaction = false
    @State private var transactionViewModel: TransactionViewModel?
    
    @Query(filter: #Predicate<Budget> { $0.isActive == true })
    private var activeBudgets: [Budget]
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if hasCompletedOnboarding {
            mainContent
        } else {
            OnboardingView()
        }
    }
    
    private var mainContent: some View {
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
                        modelContext.autosaveEnabled = false
                        let vm = BudgetViewModel(modelContext: modelContext)
                        vm.loadBudgets()
                        self.budgetViewModel = vm
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
        let vm = TransactionViewModel(modelContext: modelContext)
        transactionViewModel = vm
        return vm
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
