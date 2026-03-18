import SwiftUI
import SwiftData

@main
struct ExpenseMeApp: App {
    @StateObject private var appearanceManager = AppearanceManager()
    
    init() {
        PostHogManager.shared.setup()
    }
    
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
