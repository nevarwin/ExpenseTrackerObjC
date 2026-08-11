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

// MARK: - UI Test Lifecycle

extension ContentView {
    /// Resets the onboarding gate when launched with `-resetOnboarding`.
    /// Allows Onboarding UI tests to start from a clean state without
    /// manipulating UserDefaults from the test target.
    private static func resetOnboardingIfNeeded() {
        if ProcessInfo.processInfo.arguments.contains("-resetOnboarding") {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
    }

    /// Call this once at init time (invoked from the App entry point for tests).
    static func applyUITestOverrides() {
        resetOnboardingIfNeeded()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self])
}
