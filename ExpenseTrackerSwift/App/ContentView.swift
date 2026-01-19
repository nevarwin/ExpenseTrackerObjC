import SwiftUI

struct ContentView: View {
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
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
