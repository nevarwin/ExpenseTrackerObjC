import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var budgetViewModel: BudgetViewModel?
    @State private var showingAddTransaction = false
    @State private var transactionViewModel: TransactionViewModel?
    
    @Query(filter: #Predicate<Budget> { $0.isActive == true })
    private var activeBudgets: [Budget]
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if hasCompletedOnboarding || shouldSkipOnboarding {
            mainContent
        } else {
            OnboardingView()
        }
    }
    
    /// Returns true when the app is launched with the `-skipOnboarding` argument.
    /// Used exclusively by UI tests — has no effect in normal or release builds.
    private var shouldSkipOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("-skipOnboarding")
    }
    
    private var mainContent: some View {
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
    ContentView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
