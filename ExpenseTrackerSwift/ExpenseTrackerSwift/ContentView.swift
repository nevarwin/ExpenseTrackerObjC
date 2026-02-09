import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var currencyManager = CurrencyManager()
    @State private var budgetViewModel: BudgetViewModel?
    
    @Query(filter: #Predicate<Budget> { $0.isActive == true })
    private var activeBudgets: [Budget]
    
    var body: some View {
        Group {
            if let viewModel = budgetViewModel {
                TabView {
                    HomeView(viewModel: viewModel)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    
                    BudgetListView(viewModel: viewModel)
                        .tabItem {
                            Label("Budgets", systemImage: "creditcard.fill")
                        }
                    
                    TransactionListView()
                        .tabItem {
                            Label("Transactions", systemImage: "list.bullet")
                        }
                }
            } else {
                ProgressView()
                    .onAppear {
                        // Initialize shared ViewModel and disable autosave
                        modelContext.autosaveEnabled = false
                        
                        let vm = BudgetViewModel(modelContext: modelContext)
                        vm.loadBudgets()
                        self.budgetViewModel = vm
                    }
            }
        }
        .environmentObject(currencyManager)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
