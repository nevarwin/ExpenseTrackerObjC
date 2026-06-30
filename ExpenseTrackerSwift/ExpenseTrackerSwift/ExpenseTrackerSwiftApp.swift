import SwiftUI
import SwiftData

@main
struct ExpenseMeApp: App {
    // Keep it as a StateObject for SwiftUI environment observation
    @StateObject private var appearanceManager: SharedAppearanceService
    
    init() {
        // 1. Configure services
        SharedAppearanceService.configure()
        SharedAnalyticsService.configure()
        
        // 2. Setup analytics
        SharedAnalyticsService.instance.setup()
        
        // 3. Initialize StateObject
        _appearanceManager = StateObject(wrappedValue: SharedAppearanceService.instance)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appearanceManager)
                .preferredColorScheme(appearanceManager.userAppearance.colorScheme)
        }
        .modelContainer(for: [
            Transaction.self,
            Category.self,
            Budget.self
        ])
    }
}
