import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var currencyManager = CurrencyManager()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            BudgetListView()
                .tabItem {
                    Label("Budgets", systemImage: "creditcard.fill")
                }
            
            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(currencyManager)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
