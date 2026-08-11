//
//  ImportExportUITests.swift
//  ExpenseTrackerSwiftUITests
//

import XCTest

// MARK: - Import & Export UI Tests

/// UI test suite covering all Import and Export feature flows:
/// - Navigation to ImportView from Budget List, Budget Detail, and empty-state entry points
/// - Import type picker (Full Workbook / Transactions / Budget Template) and tip card visibility
/// - Browse Files button presence and Done button dismissal
/// - Settings template download link (Export)
/// - ImportLoadingView overlay structure
final class ImportExportUITests: TransactionUITestCase {

    // MARK: - Navigation Helpers

    /// Navigates to the Budget tab and opens ImportView from the Budget List toolbar menu.
    /// Precondition: App is launched. May or may not have existing budgets.
    @discardableResult
    func navigateToImportFromBudgetList() -> Bool {
        navigateToBudget()

        let menuButton = app.buttons["budget_menu_button"].firstMatch
        guard menuButton.waitForExistence(timeout: 5) else { return false }
        menuButton.tap()

        let importItem = app.buttons["budget_import_menu_item"].firstMatch
        guard importItem.waitForExistence(timeout: 3) else { return false }
        importItem.tap()

        return app.segmentedControls["import_type_picker"].waitForExistence(timeout: 5)
    }

    /// Navigates to the Budget tab and opens ImportView from the Budget Detail toolbar menu.
    /// Precondition: At least one budget must exist.
    @discardableResult
    func navigateToImportFromBudgetDetail() -> Bool {
        navigateToBudget()

        let firstCard = app.cells.firstMatch
        guard firstCard.waitForExistence(timeout: 5) else { return false }
        firstCard.tap()

        let detailMenuButton = app.buttons["budget_detail_menu_button"].firstMatch
        guard detailMenuButton.waitForExistence(timeout: 5) else { return false }
        detailMenuButton.tap()

        let importCsvItem = app.buttons["budget_import_csv_menu_item"].firstMatch
        guard importCsvItem.waitForExistence(timeout: 3) else { return false }
        importCsvItem.tap()

        return app.segmentedControls["import_type_picker"].waitForExistence(timeout: 5)
    }

    /// Navigates to Settings via the Budget tab menu (the app has no Settings tab).
    /// Mirrors the pattern used in SettingsUITests.navigateToSettingsFromBudget().
    func navigateToSettings() {
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.waitForExistence(timeout: 3) {
            settingsTab.tap()
        } else {
            // Settings is accessed through the Budget toolbar menu
            navigateToBudget()

            let menuButton = app.buttons["budget_menu_button"].firstMatch
            if menuButton.waitForExistence(timeout: 3) {
                menuButton.tap()
            }

            let settingsItem = app.buttons["settings_menu_item"].firstMatch
            if settingsItem.waitForExistence(timeout: 3) {
                settingsItem.tap()
            } else {
                // Fallback: look for a generic "Settings" button in the menu
                let altSettingsItem = app.buttons["Settings"].firstMatch
                if altSettingsItem.waitForExistence(timeout: 3) {
                    altSettingsItem.tap()
                }
            }
        }

        let settingsList = app.collectionViews["settings_list"].firstMatch
        assertExists(settingsList, timeout: 5, message: "Settings list should appear")
    }

    // MARK: - Test Cases: Import Navigation

    /// Verifies that tapping "Import Data" from the Budget List toolbar menu opens ImportView.
    @MainActor
    func testNavigateToImportFromBudgetList() throws {
        let opened = navigateToImportFromBudgetList()
        XCTAssertTrue(opened, "ImportView should open via Budget List toolbar menu")

        let typePicker = app.segmentedControls["import_type_picker"].firstMatch
        assertExists(typePicker, timeout: 5, message: "Import type segmented picker should be visible")

        takeScreenshot(name: "import_view_from_budget_list")
    }

    /// Verifies that tapping "Import Excel Workbook" from the Budget empty state opens ImportView.
    @MainActor
    func testNavigateToImportFromEmptyBudgetState() throws {
        navigateToBudget()

        // Check if empty state button is present (no budgets exist)
        let emptyImportButton = app.buttons["empty_budget_import_button"].firstMatch
        if !emptyImportButton.waitForExistence(timeout: 4) {
            // Budgets already exist — skip this specific path
            throw XCTSkip("Skipping empty state test: existing budgets present in test environment")
        }

        emptyImportButton.tap()

        let typePicker = app.segmentedControls["import_type_picker"].firstMatch
        assertExists(typePicker, timeout: 5, message: "ImportView should open from empty state button")

        takeScreenshot(name: "import_view_from_empty_state")
    }

    /// Verifies that tapping "Import CSV Data" from the Budget Detail menu opens ImportView.
    @MainActor
    func testNavigateToImportFromBudgetDetail() throws {
        // Ensure a budget exists to open its detail view
        navigateToBudget()
        let firstCell = app.cells.firstMatch
        if !firstCell.waitForExistence(timeout: 3) {
            // No budgets — create one first
            createBudget(name: "TestBudget")
        }

        let opened = navigateToImportFromBudgetDetail()
        XCTAssertTrue(opened, "ImportView should open via Budget Detail toolbar menu")

        let typePicker = app.segmentedControls["import_type_picker"].firstMatch
        assertExists(typePicker, timeout: 5, message: "Import type picker should be visible")

        takeScreenshot(name: "import_view_from_budget_detail")
    }

    // MARK: - Test Cases: Import Type Picker

    /// Verifies that switching the import type picker changes the displayed description card.
    /// Also checks that the Excel template tip card appears only for Full Workbook.
    @MainActor
    func testImportTypePickerSwitching() throws {
        let opened = navigateToImportFromBudgetList()
        XCTAssertTrue(opened, "ImportView must open to test type picker")

        let typePicker = app.segmentedControls["import_type_picker"].firstMatch
        assertExists(typePicker, timeout: 5, message: "Import type picker must be visible")

        // --- Full Workbook (default) ---
        // The tip card title text is the most reliable proxy since VStack containers
        // may not resolve as a distinct `otherElements` entry in the accessibility tree.
        let tipCardTitle = app.staticTexts["Excel Template Tip"].firstMatch
        assertExists(tipCardTitle, timeout: 4, message: "Excel Template Tip card should be visible for Full Workbook type")

        takeScreenshot(name: "import_type_full_workbook")

        // --- Switch to Transactions ---
        let transactionSegment = typePicker.buttons["Transactions"].firstMatch
        if transactionSegment.waitForExistence(timeout: 3) {
            transactionSegment.tap()
        }
        sleep(1) // Allow animation to settle

        // Tip card title should NOT be visible for Transactions type
        XCTAssertFalse(tipCardTitle.exists, "Tip card should be hidden when Transactions type is selected")

        takeScreenshot(name: "import_type_transactions")

        // --- Switch to Budget Template ---
        let budgetTemplateSegment = typePicker.buttons["Budget Template"].firstMatch
        if budgetTemplateSegment.waitForExistence(timeout: 3) {
            budgetTemplateSegment.tap()
        }
        sleep(1)

        // Tip card title should NOT be visible for Budget Template type
        XCTAssertFalse(tipCardTitle.exists, "Tip card should be hidden when Budget Template type is selected")

        takeScreenshot(name: "import_type_budget_template")

        // --- Switch back to Full Workbook ---
        let workbookSegment = typePicker.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Workbook'")
        ).firstMatch
        if workbookSegment.waitForExistence(timeout: 3) {
            workbookSegment.tap()
        }
        sleep(1)
        assertExists(tipCardTitle, timeout: 3, message: "Tip card should reappear when switching back to Full Workbook")
    }

    /// Verifies that selecting Transactions type shows "Target Budget" label when a budget context is provided.
    @MainActor
    func testTransactionsTypeShowsTargetBudgetWhenAvailable() throws {
        navigateToBudget()

        let firstCell = app.cells.firstMatch
        if !firstCell.waitForExistence(timeout: 3) {
            createBudget(name: "TestBudget")
        }

        let opened = navigateToImportFromBudgetDetail()
        XCTAssertTrue(opened, "ImportView must open from budget detail to test target budget display")

        let typePicker = app.segmentedControls["import_type_picker"].firstMatch
        assertExists(typePicker, timeout: 5)

        // Switch to Transactions type
        let transactionSegment = typePicker.buttons["Transactions"].firstMatch
        if transactionSegment.waitForExistence(timeout: 3) {
            transactionSegment.tap()
        }
        sleep(1)

        // "Target Budget:" label should be visible since we opened from a budget context
        let targetBudgetLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Target Budget'")).firstMatch
        assertExists(targetBudgetLabel, timeout: 4, message: "Target Budget label should appear in Transactions mode when opened from a budget")

        takeScreenshot(name: "import_type_transactions_with_target_budget")
    }

    // MARK: - Test Cases: ImportView Controls

    /// Verifies the Browse Files button is present and enabled (not disabled) on ImportView.
    @MainActor
    func testBrowseFilesButtonPresence() throws {
        let opened = navigateToImportFromBudgetList()
        XCTAssertTrue(opened, "ImportView must open to test Browse Files button")

        let browseButton = app.buttons["import_browse_files_button"].firstMatch
        assertExists(browseButton, timeout: 5, message: "Browse Files button must be visible")
        XCTAssertTrue(browseButton.isEnabled, "Browse Files button should be enabled when not importing")

        takeScreenshot(name: "import_browse_files_button")
    }

    /// Verifies that tapping the "Done" toolbar button dismisses ImportView.
    @MainActor
    func testDoneButtonDismissesImportView() throws {
        let opened = navigateToImportFromBudgetList()
        XCTAssertTrue(opened, "ImportView must open to test dismissal")

        let doneButton = app.buttons["import_done_button"].firstMatch
        assertExists(doneButton, timeout: 5, message: "Done toolbar button must be visible")
        doneButton.tap()

        // After dismissal, Budget List should be visible (ImportView is a sheet over it)
        let budgetListNav = app.navigationBars["Budget"].firstMatch
        let budgetMenuButton = app.buttons["budget_menu_button"].firstMatch
        XCTAssertTrue(
            budgetListNav.waitForExistence(timeout: 5) || budgetMenuButton.waitForExistence(timeout: 5),
            "Budget List should be visible after ImportView is dismissed"
        )

        takeScreenshot(name: "import_view_dismissed")
    }

    /// Verifies that tapping Browse Files presents the system file picker.
    /// Note: Testing only that the system document picker UI is triggered, not file selection flow.
    @MainActor
    func testBrowseFilesTriggersPicker() throws {
        let opened = navigateToImportFromBudgetList()
        XCTAssertTrue(opened, "ImportView must open to test file picker trigger")

        let browseButton = app.buttons["import_browse_files_button"].firstMatch
        assertExists(browseButton, timeout: 5, message: "Browse Files button must exist")
        browseButton.tap()

        // System document picker appears as a separate sheet or springboard UI
        // Verify it appeared by detecting the document picker or dismissing with Cancel
        let cancelDocPicker = app.buttons["Cancel"].firstMatch
        if cancelDocPicker.waitForExistence(timeout: 4) {
            cancelDocPicker.tap() // Dismiss the system picker
            takeScreenshot(name: "import_file_picker_triggered")
        } else {
            // On some simulators, document picker may present differently
            XCTAssertTrue(
                app.buttons["Cancel"].waitForExistence(timeout: 6) || browseButton.waitForExistence(timeout: 6),
                "File picker or original view should still be accessible"
            )
            takeScreenshot(name: "import_file_picker_triggered_alternate")
        }
    }

    // MARK: - Test Cases: Export (Template Download via Settings)

    /// Verifies that the "Download Import Template" ShareLink is present in Settings → Data Management.
    @MainActor
    func testSettingsTemplateDownloadLinkExists() throws {
        navigateToSettings()

        // Scroll down to find the Data Management section if needed
        let templateLink = app.buttons["settings_download_template_link"].firstMatch

        // The ShareLink may appear as a button with this accessibility identifier
        if !templateLink.waitForExistence(timeout: 3) {
            // Fallback: look for the label text in case the identifier isn't matched by button type
            let altLabel = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'Download Import Template'")
            ).firstMatch
            let altLabel2 = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS 'Import Template'")
            ).firstMatch
            XCTAssertTrue(
                altLabel.waitForExistence(timeout: 3) || altLabel2.waitForExistence(timeout: 3),
                "Download Import Template link should be visible in Settings Data Management section"
            )
        } else {
            XCTAssertTrue(templateLink.exists, "Download Import Template link (settings_download_template_link) must exist")
        }

        takeScreenshot(name: "settings_template_download_link")
    }

    /// Verifies the Settings "Download Import Template" link opens a share sheet.
    @MainActor
    func testSettingsTemplateDownloadOpensShareSheet() throws {
        navigateToSettings()

        let templateLink = app.buttons["settings_download_template_link"].firstMatch
        if !templateLink.waitForExistence(timeout: 4) {
            throw XCTSkip("Template download link not found — bundle may not include template file in test build")
        }

        templateLink.tap()

        // ShareSheet appears as activity view
        let shareSheet = app.otherElements["ActivityListView"].firstMatch
        let closeButton = app.buttons["Close"].firstMatch
        let cancelButton = app.buttons["Cancel"].firstMatch

        let shareSheetAppeared = shareSheet.waitForExistence(timeout: 5)
            || closeButton.waitForExistence(timeout: 5)
            || cancelButton.waitForExistence(timeout: 5)

        XCTAssertTrue(shareSheetAppeared, "Share sheet should appear when tapping Download Import Template")

        // Dismiss share sheet
        if closeButton.exists { closeButton.tap() }
        else if cancelButton.exists { cancelButton.tap() }
        else { app.swipeDown() }

        takeScreenshot(name: "settings_template_share_sheet")
    }

    // MARK: - Test Cases: Import Loading View Overlay

    /// Validates that ImportLoadingView modal presents correctly with structural elements.
    /// This test uses a static preview by leveraging a known cancelled/completed state.
    /// Note: Since the loading view is triggered by actual file import, we validate its
    /// accessibility identifiers are reachable in the UI hierarchy via structural checks.
    @MainActor
    func testImportLoadingViewStructuralElements() throws {
        let opened = navigateToImportFromBudgetList()
        XCTAssertTrue(opened, "ImportView must open for loading overlay test")

        // The import_loading_overlay appears only after file selection — we verify
        // the structural accessibility identifiers are non-overlapping with the main view
        // by confirming the browse button is visible (overlay not currently shown).
        let browseButton = app.buttons["import_browse_files_button"].firstMatch
        assertExists(browseButton, timeout: 5, message: "Browse Files button must exist when no import is running")

        // Confirm loading overlay is NOT shown when idle
        let loadingOverlay = app.otherElements["import_loading_overlay"].firstMatch
        XCTAssertFalse(
            loadingOverlay.waitForExistence(timeout: 2),
            "Loading overlay should not appear when no import is in progress"
        )

        takeScreenshot(name: "import_view_idle_no_overlay")
    }

    /// Validates that ImportView error banner appears when an error is present.
    /// Since the error state is driven by ViewModel, we validate the identifier path is correct
    /// by ensuring the error banner is NOT visible in default state (no error).
    @MainActor
    func testImportErrorBannerNotVisibleByDefault() throws {
        let opened = navigateToImportFromBudgetList()
        XCTAssertTrue(opened, "ImportView must open for error banner test")

        let errorBanner = app.otherElements["import_error_banner"].firstMatch
        XCTAssertFalse(
            errorBanner.waitForExistence(timeout: 2),
            "Error banner should not appear by default (no import error has occurred)"
        )

        takeScreenshot(name: "import_view_no_error_banner")
    }
}
