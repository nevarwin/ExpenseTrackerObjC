import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    @StateObject private var appearanceManager = AppearanceManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appearanceManager)
                .preferredColorScheme(appearanceManager.userAppearance.colorScheme)
        }
        .modelContainer(for: [
            Budget.self,
            Category.self,
            Transaction.self,
            BudgetAllocation.self
        ])
    }
}
