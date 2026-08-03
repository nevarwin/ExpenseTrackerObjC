import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if hasCompletedOnboarding || shouldSkipOnboarding {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
    
    /// Returns true when the app is launched with the `-skipOnboarding` argument.
    /// Used exclusively by UI tests — has no effect in normal or release builds.
    private var shouldSkipOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("-skipOnboarding")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
