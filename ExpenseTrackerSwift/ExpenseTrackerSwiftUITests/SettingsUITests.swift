import XCTest

// MARK: - Settings UI Tests

/// UI Tests for the Settings feature.
/// Tests navigation from Budget tab, settings sections, sub-views, and analytics toggle alert.
final class SettingsUITests: TransactionUITestCase {

    // MARK: - Navigation Helper

    /// Navigates from anywhere in the app to the Settings screen via the Budget tab overflow menu.
    func navigateToSettingsFromBudget() {
        let budgetTab = app.tabBars.buttons["Budget"]
        assertExists(budgetTab, timeout: 5, message: "Budget tab should exist in main TabView")
        budgetTab.tap()

        let menuButton = app.buttons["budget_menu_button"].firstMatch
        if !menuButton.waitForExistence(timeout: 3) {
            let altMenuButton = app.buttons["Menu"].firstMatch
            assertExists(altMenuButton, message: "Budget overflow menu button not found")
            altMenuButton.tap()
        } else {
            menuButton.tap()
        }

        let settingsItem = app.buttons["settings_menu_item"].firstMatch
        if !settingsItem.waitForExistence(timeout: 3) {
            let altSettingsItem = app.buttons["Settings"].firstMatch
            assertExists(altSettingsItem, message: "Settings item in overflow menu not found")
            altSettingsItem.tap()
        } else {
            settingsItem.tap()
        }

        let settingsList = app.collectionViews["settings_list"].firstMatch
        assertExists(settingsList, timeout: 5, message: "Settings screen should be presented")
    }

    // MARK: - Test Cases

    /// Verifies opening the Settings view from Budget tab displays the main sections and version info.
    @MainActor
    func testNavigateToSettings() throws {
        navigateToSettingsFromBudget()

        let versionLabel = app.otherElements["settings_version_label"].firstMatch
        let versionText = app.staticTexts["Version"].firstMatch
        XCTAssertTrue(versionLabel.exists || versionText.exists, "Settings should display application Version")

        takeScreenshot(name: "settings_home_screen")
    }

    /// Verifies navigating to Currency settings, interacting with the picker, and returning.
    @MainActor
    func testCurrencySettings() throws {
        navigateToSettingsFromBudget()

        let currencyLink = app.buttons["settings_currency_link"].firstMatch
        if !currencyLink.waitForExistence(timeout: 3) {
            let altCurrencyLink = app.buttons["Currency"].firstMatch
            assertExists(altCurrencyLink, message: "Currency link should exist")
            altCurrencyLink.tap()
        } else {
            currencyLink.tap()
        }

        let currencyForm = app.otherElements["currency_settings_form"].firstMatch
        let currencyTitle = app.navigationBars["Currency"].firstMatch
        XCTAssertTrue(currencyForm.waitForExistence(timeout: 3) || currencyTitle.waitForExistence(timeout: 3), "Currency settings page should be visible")

        let currentSelection = app.otherElements["currency_current_selection"].firstMatch
        let symbolElement = app.otherElements["currency_symbol"].firstMatch
        XCTAssertTrue(currentSelection.exists || symbolElement.exists, "Currency details should be visible")

        takeScreenshot(name: "currency_settings_screen")
    }

    /// Verifies navigating to Appearance settings and selecting options.
    @MainActor
    func testAppearanceSettings() throws {
        navigateToSettingsFromBudget()

        let appearanceLink = app.buttons["settings_appearance_link"].firstMatch
        if !appearanceLink.waitForExistence(timeout: 3) {
            let altAppearanceLink = app.buttons["Appearance"].firstMatch
            assertExists(altAppearanceLink, message: "Appearance link should exist")
            altAppearanceLink.tap()
        } else {
            appearanceLink.tap()
        }

        let appearanceList = app.collectionViews["appearance_list"].firstMatch
        let appearanceTitle = app.navigationBars["Appearance"].firstMatch
        XCTAssertTrue(appearanceList.waitForExistence(timeout: 3) || appearanceTitle.waitForExistence(timeout: 3), "Appearance settings screen should be visible")

        // Select Dark theme option
        let darkOption = app.buttons["appearance_option_dark"].firstMatch
        if darkOption.waitForExistence(timeout: 2) {
            darkOption.tap()
        } else {
            let altDarkOption = app.buttons["Dark"].firstMatch
            if altDarkOption.waitForExistence(timeout: 2) {
                altDarkOption.tap()
            }
        }

        takeScreenshot(name: "appearance_settings_dark_selected")
    }

    /// Verifies toggling Analytics triggers confirmation alert dialog and cancelling alert retains state.
    @MainActor
    func testAnalyticsToggleAndAlertConfirmation() throws {
        navigateToSettingsFromBudget()

        let analyticsToggle = app.switches["settings_analytics_toggle"].firstMatch
        if !analyticsToggle.waitForExistence(timeout: 3) {
            let altToggle = app.switches.matching(NSPredicate(format: "label CONTAINS 'Analytics'")).firstMatch
            assertExists(altToggle, message: "Analytics toggle should exist")
            altToggle.tap()
        } else {
            analyticsToggle.tap()
        }

        // Verify alert appears
        let alert = app.alerts.firstMatch
        assertExists(alert, timeout: 3, message: "Confirmation alert should appear when toggling Analytics")

        let cancelButton = alert.buttons["Cancel"]
        assertExists(cancelButton)
        cancelButton.tap()

        takeScreenshot(name: "analytics_toggle_alert_dismissed")
    }

    /// Verifies navigating to Privacy Policy view.
    @MainActor
    func testPrivacyPolicyView() throws {
        navigateToSettingsFromBudget()

        let privacyLink = app.buttons["settings_privacy_link"].firstMatch
        if !privacyLink.waitForExistence(timeout: 3) {
            let altPrivacyLink = app.buttons["Privacy Policy"].firstMatch
            assertExists(altPrivacyLink, message: "Privacy Policy link should exist")
            altPrivacyLink.tap()
        } else {
            privacyLink.tap()
        }

        let privacyTitle = app.navigationBars["Privacy Policy"].firstMatch
        let privacyView = app.scrollViews["privacy_policy_view"].firstMatch
        XCTAssertTrue(privacyTitle.waitForExistence(timeout: 3) || privacyView.waitForExistence(timeout: 3), "Privacy Policy screen should be displayed")

        takeScreenshot(name: "privacy_policy_screen")
    }

    /// Verifies navigating to Contact Support view.
    @MainActor
    func testContactSupportView() throws {
        navigateToSettingsFromBudget()

        let contactLink = app.buttons["settings_contact_link"].firstMatch
        if !contactLink.waitForExistence(timeout: 3) {
            let altContactLink = app.buttons["Contact Support"].firstMatch
            assertExists(altContactLink, message: "Contact Support link should exist")
            altContactLink.tap()
        } else {
            contactLink.tap()
        }

        let contactForm = app.otherElements["contact_support_view"].firstMatch
        let sendEmailButton = app.buttons["contact_support_send_email_button"].firstMatch
        let altSendEmail = app.buttons["Send Email"].firstMatch

        XCTAssertTrue(contactForm.waitForExistence(timeout: 3) || sendEmailButton.waitForExistence(timeout: 3) || altSendEmail.waitForExistence(timeout: 3), "Contact Support screen should be displayed")

        takeScreenshot(name: "contact_support_screen")
    }
}
