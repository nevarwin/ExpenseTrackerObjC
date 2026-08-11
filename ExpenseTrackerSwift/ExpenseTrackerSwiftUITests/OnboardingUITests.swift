import XCTest

// MARK: - Onboarding UI Tests

/// UI Tests for the Onboarding feature.
///
/// These tests launch the app WITHOUT `-skipOnboarding` and WITH `-resetOnboarding`
/// so the onboarding flow is always shown fresh. The base class `launchForOnboarding()`
/// helper configures these arguments automatically.
final class OnboardingUITests: TransactionUITestCase {

    // MARK: - Setup

    /// Each onboarding test launches the app showing the onboarding screen.
    override func setUpWithError() throws {
        continueAfterFailure = false
        // Note: we do NOT call super.setUpWithError() — instead we use launchForOnboarding()
        // so the app shows OnboardingView instead of skipping to MainTabView.
        launchForOnboarding()
    }

    // MARK: - Helpers

    /// Waits for the onboarding view to be visible.
    private func assertOnboardingVisible(timeout: TimeInterval = 5) {
        let onboardingView = app.otherElements["onboarding_view"].firstMatch
        assertExists(onboardingView, timeout: timeout, message: "OnboardingView should be visible on fresh launch")
    }

    /// Taps the Next / Get Started button.
    private func tapNextButton() {
        let btn = app.buttons["onboarding_next_button"].firstMatch
        assertExists(btn, timeout: 5, message: "Onboarding CTA button should exist")
        btn.tap()
    }

    // MARK: - Page 1 Content Test

    /// Verifies the first onboarding page shows the expected title and "Next" CTA.
    @MainActor
    func testFirstPageContent() throws {
        assertOnboardingVisible()

        let titleEl = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Track Your Expenses'")).firstMatch
        assertExists(titleEl, timeout: 5, message: "Page 1 title 'Track Your Expenses' should be visible")

        let nextBtn = app.buttons["onboarding_next_button"].firstMatch
        assertExists(nextBtn, message: "CTA button should exist on page 1")
        XCTAssertEqual(nextBtn.label, "Next", "Page 1 CTA should read 'Next'")

        takeScreenshot(name: "onboarding_page1")
    }

    // MARK: - Page Navigation Tests

    /// Verifies tapping "Next" progresses through all 3 pages and updates CTA text.
    @MainActor
    func testOnboardingPageNavigation() throws {
        assertOnboardingVisible()

        // --- Page 1 ---
        let nextBtn = app.buttons["onboarding_next_button"].firstMatch
        assertExists(nextBtn, timeout: 5, message: "CTA button should exist")
        XCTAssertEqual(nextBtn.label, "Next", "Page 1 CTA should read 'Next'")
        takeScreenshot(name: "onboarding_page1_nav")
        nextBtn.tap()

        // --- Page 2 ---
        let page2Title = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Instant Import'")).firstMatch
        assertExists(page2Title, timeout: 5, message: "Page 2 title should appear after tapping Next")
        XCTAssertEqual(nextBtn.label, "Next", "Page 2 CTA should still read 'Next'")
        takeScreenshot(name: "onboarding_page2_nav")
        nextBtn.tap()

        // --- Page 3 ---
        let page3Title = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Ready to Start'")).firstMatch
        assertExists(page3Title, timeout: 5, message: "Page 3 title should appear after tapping Next on page 2")
        XCTAssertEqual(nextBtn.label, "Get Started", "Page 3 CTA should read 'Get Started'")
        takeScreenshot(name: "onboarding_page3_nav")
    }

    // MARK: - Swipe Navigation Tests

    /// Verifies that swiping left on the TabView advances to the next onboarding page.
    @MainActor
    func testOnboardingPageSwiping() throws {
        assertOnboardingVisible()

        let page1Title = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Track Your Expenses'")).firstMatch
        assertExists(page1Title, timeout: 5, message: "Page 1 should be initially visible")

        // Swipe left on the scroll view (TabView page control) to advance to page 2
        let tabScrollView = app.scrollViews.firstMatch
        tabScrollView.swipeLeft()

        let page2Title = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Instant Import'")).firstMatch
        assertExists(page2Title, timeout: 5, message: "Page 2 should be visible after swiping left")
        takeScreenshot(name: "onboarding_page2_swipe")

        // Swipe right should return to page 1
        tabScrollView.swipeRight()
        assertExists(page1Title, timeout: 5, message: "Page 1 should be visible after swiping right")
        takeScreenshot(name: "onboarding_page1_swipe_back")
    }

    // MARK: - Completion Tests

    /// Verifies tapping "Get Started" on the last page transitions to MainTabView.
    @MainActor
    func testOnboardingCompletionNavigatesToMainApp() throws {
        assertOnboardingVisible()

        let nextBtn = app.buttons["onboarding_next_button"].firstMatch
        assertExists(nextBtn, timeout: 5)
        nextBtn.tap() // → Page 2

        let page2Title = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Instant Import'")).firstMatch
        assertExists(page2Title, timeout: 5, message: "Should reach page 2")
        nextBtn.tap() // → Page 3

        let page3Title = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Ready to Start'")).firstMatch
        assertExists(page3Title, timeout: 5, message: "Should reach page 3")

        // Tap "Get Started"
        XCTAssertEqual(nextBtn.label, "Get Started", "Final CTA should read 'Get Started'")
        nextBtn.tap()

        // Onboarding should disappear and the tab bar should appear
        let onboardingView = app.otherElements["onboarding_view"].firstMatch
        XCTAssertFalse(onboardingView.waitForExistence(timeout: 2), "OnboardingView should be dismissed after completion")

        let tabBar = app.tabBars.firstMatch
        assertExists(tabBar, timeout: 5, message: "MainTabView tab bar should appear after onboarding completion")

        takeScreenshot(name: "onboarding_completion_main_app")
    }

    // MARK: - Persistence Tests

    /// Verifies that after completing onboarding, re-launching the app (without -resetOnboarding)
    /// bypasses onboarding and goes directly to the main app.
    @MainActor
    func testOnboardingPersistenceAcrossLaunches() throws {
        assertOnboardingVisible()

        // Complete onboarding
        let nextBtn = app.buttons["onboarding_next_button"].firstMatch
        assertExists(nextBtn, timeout: 5)
        nextBtn.tap()
        nextBtn.tap() // → Page 3

        assertExists(nextBtn, timeout: 5)
        XCTAssertEqual(nextBtn.label, "Get Started", "Final CTA should read 'Get Started'")
        nextBtn.tap()

        let tabBar = app.tabBars.firstMatch
        assertExists(tabBar, timeout: 5, message: "Tab bar should appear after first onboarding completion")

        // Re-launch WITHOUT -resetOnboarding to simulate a real app re-open
        app.terminate()
        app.launchArguments = ["-UITestMode"]
        app.launch()

        let onboardingView = app.otherElements["onboarding_view"].firstMatch
        XCTAssertFalse(onboardingView.waitForExistence(timeout: 3), "Onboarding should NOT appear on second launch")

        let tabBarAfterRelaunch = app.tabBars.firstMatch
        assertExists(tabBarAfterRelaunch, timeout: 5, message: "Tab bar should appear directly on re-launch")

        takeScreenshot(name: "onboarding_persistence_relaunched")
    }
}
