import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @StateObject private var appearanceManager = AppearanceManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appearanceManager)
                .preferredColorScheme(appearanceManager.userAppearance.colorScheme)
        }
    }
}
