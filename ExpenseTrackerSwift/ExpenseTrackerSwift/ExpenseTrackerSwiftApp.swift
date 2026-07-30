import SwiftUI
import SwiftData

@main
struct ExpenseMeApp: App {
    @StateObject private var appearanceManager: SharedAppearanceService
    @StateObject private var currencyManager: SharedCurrencyService

    init() {
        // 1. Configure services
        SharedAppearanceService.configure()
        SharedAnalyticsService.configure()
        SharedCurrencyService.configure()
        SharedPermissionService.configure()

        // 2. Setup analytics
        SharedAnalyticsService.instance.setup()

        // 3. Initialize StateObjects
        _appearanceManager = StateObject(wrappedValue: SharedAppearanceService.instance)
        _currencyManager = StateObject(wrappedValue: SharedCurrencyService.instance)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appearanceManager)
                .environmentObject(currencyManager)
                .preferredColorScheme(appearanceManager.userAppearance.colorScheme)
        }
        .modelContainer(for: [
            Transaction.self,
            Category.self,
            Budget.self
        ])
    }
}
