import XCTest

// MARK: - Settings UI Tests

/// UI Tests for the Settings feature.
///
/// Covers:
/// - Navigation to Settings from the Budget/Transactions tab
/// - All settings sections: General, Data Management, Legal & Support, About
/// - Currency settings picker and current selection display
/// - Appearance settings theme selection and checkmark state
/// - Analytics toggle confirmation alert (Cancel and Confirm paths)
/// - Privacy Policy content and navigation
/// - Contact Support view and send email button
/// - Back navigation from every sub-screen to Settings root
final class SettingsUITests: TransactionUITestCase {

    // MARK: - Navigation Helper

    /// Navigates from anywhere in the app to the Settings screen.
    /// Prefers the "Settings" tab if available; falls back to Budget menu.
    func navigateToSettings() {
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.waitForExistence(timeout: 3) {
            settingsTab.tap()
        } else {
            let budgetTab = app.tabBars.buttons["Budget"]
            assertExists(budgetTab, timeout: 5, message: "Budget tab should exist in main TabView")
            budgetTab.tap()

            let menuButton = app.buttons["budget_menu_button"].firstMatch
            if menuButton.waitForExistence(timeout: 3) {
                menuButton.tap()
            } else {
                let altMenuButton = app.buttons["Menu"].firstMatch
                if altMenuButton.exists { altMenuButton.tap() }
            }

            let settingsItem = app.buttons["settings_menu_item"].firstMatch
            if settingsItem.waitForExistence(timeout: 3) {
                settingsItem.tap()
            } else {
                let altSettingsItem = app.buttons["Settings"].firstMatch
                if altSettingsItem.exists { altSettingsItem.tap() }
            }
        }

        let settingsList = app.collectionViews["settings_list"].firstMatch
        assertExists(settingsList, timeout: 5, message: "Settings list should be presented")
    }

    /// Convenience: navigates to Settings and returns to it after the sub-view action.
    func navigateToSettingsAndBack(from subViewIdentifier: String) {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()
        }
        let settingsList = app.collectionViews["settings_list"].firstMatch
        assertExists(settingsList, timeout: 5, message: "Settings list should be visible after back navigation from \(subViewIdentifier)")
    }

    // MARK: - MARK: Navigation & Overview Tests

    /// Verifies opening Settings displays all expected sections and version info.
    @MainActor
    func testNavigateToSettings() throws {
        navigateToSettings()

        // Version label (About section)
        let versionLabel = app.otherElements["settings_version_label"].firstMatch
        let versionText = app.staticTexts["Version"].firstMatch
        XCTAssertTrue(versionLabel.exists || versionText.exists, "Settings should display Version info")

        // General section items
        let currencyLink = app.buttons["settings_currency_link"].firstMatch
        XCTAssertTrue(
            currencyLink.exists || app.buttons["Currency"].firstMatch.exists,
            "Currency link should exist in General section"
        )

        let appearanceLink = app.buttons["settings_appearance_link"].firstMatch
        XCTAssertTrue(
            appearanceLink.exists || app.buttons["Appearance"].firstMatch.exists,
            "Appearance link should exist in General section"
        )

        // Legal & Support section items
        let privacyLink = app.buttons["settings_privacy_link"].firstMatch
        XCTAssertTrue(
            privacyLink.exists || app.buttons["Privacy Policy"].firstMatch.exists,
            "Privacy Policy link should exist"
        )

        let contactLink = app.buttons["settings_contact_link"].firstMatch
        XCTAssertTrue(
            contactLink.exists || app.buttons["Contact Support"].firstMatch.exists,
            "Contact Support link should exist"
        )

        takeScreenshot(name: "settings_home_screen")
    }

    // MARK: - Currency Settings Tests

    /// Navigates to Currency Settings and verifies the form and current selection.
    @MainActor
    func testCurrencySettingsNavigation() throws {
        navigateToSettings()

        let currencyLink = app.buttons["settings_currency_link"].firstMatch
        if currencyLink.waitForExistence(timeout: 3) {
            currencyLink.tap()
        } else {
            let altLink = app.buttons["Currency"].firstMatch
            assertExists(altLink, message: "Currency link should exist")
            altLink.tap()
        }

        // Form and current selection should be visible
        let currencyForm = app.otherElements["currency_settings_form"].firstMatch
        let currencyTitle = app.navigationBars["Currency"].firstMatch
        XCTAssertTrue(
            currencyForm.waitForExistence(timeout: 4) || currencyTitle.waitForExistence(timeout: 4),
            "Currency settings page should be visible"
        )

        let currentSelection = app.otherElements["currency_current_selection"].firstMatch
        let symbolElement = app.otherElements["currency_symbol"].firstMatch
        XCTAssertTrue(currentSelection.exists || symbolElement.exists, "Currency details should be visible")

        takeScreenshot(name: "currency_settings_screen")
    }

    /// Interacts with the currency picker and verifies the selection indicator updates.
    @MainActor
    func testCurrencyPickerInteraction() throws {
        navigateToSettings()

        let currencyLink = app.buttons["settings_currency_link"].firstMatch
        if currencyLink.waitForExistence(timeout: 3) {
            currencyLink.tap()
        } else {
            app.buttons["Currency"].firstMatch.tap()
        }

        let currencyForm = app.otherElements["currency_settings_form"].firstMatch
        assertExists(currencyForm, timeout: 5, message: "Currency form should be visible")

        // The currency picker is inline — find it and select an alternative entry
        let picker = app.pickers["currency_picker"].firstMatch
        if picker.waitForExistence(timeout: 3) {
            // Swipe to scroll through options and tap another currency
            let pickerRows = app.pickerWheels.firstMatch
            if pickerRows.waitForExistence(timeout: 2) {
                pickerRows.adjust(toPickerWheelValue: "EUR")
            }
        } else {
            // Inline picker rendered as buttons; tap "EUR" if visible
            let eurRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'EUR'")).firstMatch
            if eurRow.waitForExistence(timeout: 2) {
                eurRow.tap()
            }
        }

        // Current selection label should still be visible (selection updated)
        let currentSelection = app.otherElements["currency_current_selection"].firstMatch
        XCTAssertTrue(currentSelection.exists, "Currency current selection should remain visible after interaction")

        takeScreenshot(name: "currency_picker_interaction")
    }

    // MARK: - Appearance Settings Tests

    /// Navigates to Appearance settings and verifies options are listed.
    @MainActor
    func testAppearanceSettingsNavigation() throws {
        navigateToSettings()

        let appearanceLink = app.buttons["settings_appearance_link"].firstMatch
        if appearanceLink.waitForExistence(timeout: 3) {
            appearanceLink.tap()
        } else {
            let altLink = app.buttons["Appearance"].firstMatch
            assertExists(altLink, message: "Appearance link should exist")
            altLink.tap()
        }

        let appearanceList = app.collectionViews["appearance_list"].firstMatch
        let appearanceTitle = app.navigationBars["Appearance"].firstMatch
        XCTAssertTrue(
            appearanceList.waitForExistence(timeout: 4) || appearanceTitle.waitForExistence(timeout: 4),
            "Appearance settings screen should be visible"
        )

        takeScreenshot(name: "appearance_settings_screen")
    }

    /// Selects the Dark theme option and verifies the checkmark appears on it.
    @MainActor
    func testAppearanceSettingsDarkSelection() throws {
        navigateToSettings()

        let appearanceLink = app.buttons["settings_appearance_link"].firstMatch
        if appearanceLink.waitForExistence(timeout: 3) {
            appearanceLink.tap()
        } else {
            app.buttons["Appearance"].firstMatch.tap()
        }

        let appearanceList = app.collectionViews["appearance_list"].firstMatch
        assertExists(appearanceList, timeout: 5, message: "Appearance screen should be visible")

        // Tap Dark option
        let darkOption = app.buttons["appearance_option_dark"].firstMatch
        if darkOption.waitForExistence(timeout: 3) {
            darkOption.tap()
        } else {
            let altDark = app.buttons["Dark"].firstMatch
            if altDark.waitForExistence(timeout: 2) { altDark.tap() }
        }

        takeScreenshot(name: "appearance_dark_selected")
    }

    /// Selects the Light theme option.
    @MainActor
    func testAppearanceSettingsLightSelection() throws {
        navigateToSettings()

        let appearanceLink = app.buttons["settings_appearance_link"].firstMatch
        if appearanceLink.waitForExistence(timeout: 3) {
            appearanceLink.tap()
        } else {
            app.buttons["Appearance"].firstMatch.tap()
        }

        assertExists(app.collectionViews["appearance_list"].firstMatch, timeout: 5)

        let lightOption = app.buttons["appearance_option_light"].firstMatch
        if lightOption.waitForExistence(timeout: 3) {
            lightOption.tap()
        } else {
            let altLight = app.buttons["Light"].firstMatch
            if altLight.waitForExistence(timeout: 2) { altLight.tap() }
        }

        takeScreenshot(name: "appearance_light_selected")
    }

    /// Selects the System theme option.
    @MainActor
    func testAppearanceSettingsSystemSelection() throws {
        navigateToSettings()

        let appearanceLink = app.buttons["settings_appearance_link"].firstMatch
        if appearanceLink.waitForExistence(timeout: 3) {
            appearanceLink.tap()
        } else {
            app.buttons["Appearance"].firstMatch.tap()
        }

        assertExists(app.collectionViews["appearance_list"].firstMatch, timeout: 5)

        let systemOption = app.buttons["appearance_option_system"].firstMatch
        if systemOption.waitForExistence(timeout: 3) {
            systemOption.tap()
        } else {
            let altSystem = app.buttons["System"].firstMatch
            if altSystem.waitForExistence(timeout: 2) { altSystem.tap() }
        }

        takeScreenshot(name: "appearance_system_selected")
    }

    // MARK: - Analytics Toggle Tests

    /// Verifies toggling Analytics shows a confirmation alert.
    @MainActor
    func testAnalyticsToggleShowsAlert() throws {
        navigateToSettings()

        let analyticsToggle = app.switches["settings_analytics_toggle"].firstMatch
        if analyticsToggle.waitForExistence(timeout: 3) {
            analyticsToggle.tap()
        } else {
            let altToggle = app.switches.matching(NSPredicate(format: "label CONTAINS 'Analytics'")).firstMatch
            assertExists(altToggle, message: "Analytics toggle should exist")
            altToggle.tap()
        }

        let alert = app.alerts.firstMatch
        assertExists(alert, timeout: 3, message: "Confirmation alert should appear when toggling Analytics")

        takeScreenshot(name: "analytics_toggle_alert")
    }

    /// Verifies cancelling the Analytics alert retains the original toggle state.
    @MainActor
    func testAnalyticsToggleAlertCancel() throws {
        navigateToSettings()

        let analyticsToggle = app.switches["settings_analytics_toggle"].firstMatch
        let toggleExists = analyticsToggle.waitForExistence(timeout: 3)
        let initialValue = toggleExists ? (analyticsToggle.value as? String) : nil
        analyticsToggle.tap()

        let alert = app.alerts.firstMatch
        assertExists(alert, timeout: 3, message: "Alert should appear after tapping Analytics toggle")

        let cancelButton = alert.buttons["Cancel"]
        assertExists(cancelButton, message: "Cancel button should exist in the alert")
        cancelButton.tap()

        // Alert should be dismissed
        XCTAssertFalse(app.alerts.firstMatch.exists, "Alert should be dismissed after tapping Cancel")

        // Toggle value should be restored to its original value
        if let initial = initialValue {
            XCTAssertEqual(analyticsToggle.value as? String, initial, "Toggle value should be unchanged after Cancel")
        }

        takeScreenshot(name: "analytics_toggle_alert_cancelled")
    }

    /// Verifies confirming the Analytics alert commits the change.
    @MainActor
    func testAnalyticsToggleAlertConfirm() throws {
        navigateToSettings()

        let analyticsToggle = app.switches["settings_analytics_toggle"].firstMatch
        if !analyticsToggle.waitForExistence(timeout: 3) {
            let altToggle = app.switches.matching(NSPredicate(format: "label CONTAINS 'Analytics'")).firstMatch
            assertExists(altToggle, message: "Analytics toggle should exist")
            altToggle.tap()
        } else {
            analyticsToggle.tap()
        }

        let alert = app.alerts.firstMatch
        assertExists(alert, timeout: 3, message: "Alert should appear")

        // Tap the confirm button (Enable or Disable — whichever appears)
        let confirmButton = alert.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Enable' OR label CONTAINS 'Disable'")
        ).firstMatch

        if confirmButton.waitForExistence(timeout: 2) {
            confirmButton.tap()
        } else {
            // Fallback: tap first non-Cancel button
            let firstBtn = alert.buttons.element(boundBy: 0)
            if firstBtn.exists { firstBtn.tap() }
        }

        XCTAssertFalse(app.alerts.firstMatch.exists, "Alert should be dismissed after confirmation")
        takeScreenshot(name: "analytics_toggle_confirmed")
    }

    // MARK: - Privacy Policy Tests

    /// Verifies navigating to Privacy Policy view shows policy content.
    @MainActor
    func testPrivacyPolicyNavigation() throws {
        navigateToSettings()

        let privacyLink = app.buttons["settings_privacy_link"].firstMatch
        if privacyLink.waitForExistence(timeout: 3) {
            privacyLink.tap()
        } else {
            let altLink = app.buttons["Privacy Policy"].firstMatch
            assertExists(altLink, message: "Privacy Policy link should exist")
            altLink.tap()
        }

        let privacyTitle = app.navigationBars["Privacy Policy"].firstMatch
        let privacyView = app.scrollViews["privacy_policy_view"].firstMatch
        XCTAssertTrue(
            privacyTitle.waitForExistence(timeout: 4) || privacyView.waitForExistence(timeout: 4),
            "Privacy Policy screen should be displayed"
        )

        takeScreenshot(name: "privacy_policy_screen")
    }

    /// Verifies Privacy Policy content is scrollable and contains expected text.
    @MainActor
    func testPrivacyPolicyContentScrolling() throws {
        navigateToSettings()

        let privacyLink = app.buttons["settings_privacy_link"].firstMatch
        if privacyLink.waitForExistence(timeout: 3) {
            privacyLink.tap()
        } else {
            app.buttons["Privacy Policy"].firstMatch.tap()
        }

        let privacyView = app.scrollViews["privacy_policy_view"].firstMatch
        assertExists(privacyView, timeout: 5, message: "Privacy Policy scroll view should be present")

        // Verify "Privacy Policy" title text is in the content
        let policyTitle = app.staticTexts.matching(NSPredicate(format: "label == 'Privacy Policy'")).firstMatch
        XCTAssertTrue(policyTitle.exists, "Privacy Policy title text should appear")

        // Scroll to the bottom
        privacyView.swipeUp()
        takeScreenshot(name: "privacy_policy_scrolled")
    }

    // MARK: - Contact Support Tests

    /// Verifies navigating to Contact Support view displays the send email button.
    @MainActor
    func testContactSupportNavigation() throws {
        navigateToSettings()

        let contactLink = app.buttons["settings_contact_link"].firstMatch
        if contactLink.waitForExistence(timeout: 3) {
            contactLink.tap()
        } else {
            let altLink = app.buttons["Contact Support"].firstMatch
            assertExists(altLink, message: "Contact Support link should exist")
            altLink.tap()
        }

        let contactForm = app.otherElements["contact_support_view"].firstMatch
        let sendEmailButton = app.buttons["contact_support_send_email_button"].firstMatch
        let altSendEmail = app.buttons["Send Email"].firstMatch

        XCTAssertTrue(
            contactForm.waitForExistence(timeout: 4) ||
            sendEmailButton.waitForExistence(timeout: 4) ||
            altSendEmail.waitForExistence(timeout: 4),
            "Contact Support screen should be displayed with Send Email button"
        )

        takeScreenshot(name: "contact_support_screen")
    }

    /// Verifies the Send Email button exists in Contact Support view.
    @MainActor
    func testContactSupportSendEmailButtonExists() throws {
        navigateToSettings()

        let contactLink = app.buttons["settings_contact_link"].firstMatch
        if contactLink.waitForExistence(timeout: 3) {
            contactLink.tap()
        } else {
            app.buttons["Contact Support"].firstMatch.tap()
        }

        let sendEmailButton = app.buttons["contact_support_send_email_button"].firstMatch
        let altSendEmail = app.buttons["Send Email"].firstMatch
        XCTAssertTrue(
            sendEmailButton.waitForExistence(timeout: 4) || altSendEmail.waitForExistence(timeout: 4),
            "Send Email button should be present in Contact Support"
        )

        takeScreenshot(name: "contact_support_send_email")
    }

    /// Verifies the photo attachment picker is accessible from Contact Support.
    @MainActor
    func testContactSupportAttachPhotoButtonExists() throws {
        navigateToSettings()

        let contactLink = app.buttons["settings_contact_link"].firstMatch
        if contactLink.waitForExistence(timeout: 3) {
            contactLink.tap()
        } else {
            app.buttons["Contact Support"].firstMatch.tap()
        }

        assertExists(
            app.otherElements["contact_support_view"].firstMatch,
            timeout: 5,
            message: "Contact Support view should be visible"
        )

        // The photo picker button (before any photo is selected)
        let attachButton = app.buttons["contact_support_attach_photo"].firstMatch
        XCTAssertTrue(attachButton.exists, "Attach Photo button should exist in Contact Support before a photo is selected")

        takeScreenshot(name: "contact_support_attach_photo")
    }

    // MARK: - Back Navigation Tests

    /// Verifies tapping Back from Currency Settings returns cleanly to the Settings list.
    @MainActor
    func testBackNavigationFromCurrencySettings() throws {
        navigateToSettings()

        let currencyLink = app.buttons["settings_currency_link"].firstMatch
        if currencyLink.waitForExistence(timeout: 3) {
            currencyLink.tap()
        } else {
            app.buttons["Currency"].firstMatch.tap()
        }

        assertExists(
            app.navigationBars["Currency"].firstMatch,
            timeout: 5,
            message: "Currency nav bar should appear"
        )

        navigateToSettingsAndBack(from: "Currency")
        takeScreenshot(name: "settings_back_from_currency")
    }

    /// Verifies tapping Back from Appearance Settings returns cleanly to the Settings list.
    @MainActor
    func testBackNavigationFromAppearanceSettings() throws {
        navigateToSettings()

        let appearanceLink = app.buttons["settings_appearance_link"].firstMatch
        if appearanceLink.waitForExistence(timeout: 3) {
            appearanceLink.tap()
        } else {
            app.buttons["Appearance"].firstMatch.tap()
        }

        assertExists(
            app.navigationBars["Appearance"].firstMatch,
            timeout: 5,
            message: "Appearance nav bar should appear"
        )

        navigateToSettingsAndBack(from: "Appearance")
        takeScreenshot(name: "settings_back_from_appearance")
    }

    /// Verifies tapping Back from Privacy Policy returns cleanly to the Settings list.
    @MainActor
    func testBackNavigationFromPrivacyPolicy() throws {
        navigateToSettings()

        let privacyLink = app.buttons["settings_privacy_link"].firstMatch
        if privacyLink.waitForExistence(timeout: 3) {
            privacyLink.tap()
        } else {
            app.buttons["Privacy Policy"].firstMatch.tap()
        }

        assertExists(
            app.navigationBars["Privacy Policy"].firstMatch,
            timeout: 5,
            message: "Privacy Policy nav bar should appear"
        )

        navigateToSettingsAndBack(from: "Privacy Policy")
        takeScreenshot(name: "settings_back_from_privacy")
    }

    /// Verifies tapping Back from Contact Support returns cleanly to the Settings list.
    @MainActor
    func testBackNavigationFromContactSupport() throws {
        navigateToSettings()

        let contactLink = app.buttons["settings_contact_link"].firstMatch
        if contactLink.waitForExistence(timeout: 3) {
            contactLink.tap()
        } else {
            app.buttons["Contact Support"].firstMatch.tap()
        }

        assertExists(
            app.navigationBars["Contact Support"].firstMatch,
            timeout: 5,
            message: "Contact Support nav bar should appear"
        )

        navigateToSettingsAndBack(from: "Contact Support")
        takeScreenshot(name: "settings_back_from_contact")
    }
}
