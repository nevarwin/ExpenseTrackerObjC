//
//  SettingsViewModel.swift
//  ExpenseTrackerSwift
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class SettingsViewModel {
    var showingAnalyticsAlert = false
    var pendingAnalyticsValue = false
    
    let appearanceService: SharedAppearanceService
    let analyticsService: AnalyticsServiceProtocol
    
    init(
        appearanceService: SharedAppearanceService? = nil,
        analyticsService: AnalyticsServiceProtocol? = nil
    ) {
        self.appearanceService = appearanceService ?? SharedAppearanceService.instance
        self.analyticsService = analyticsService ?? SharedAnalyticsService.instance
    }
    
    var isAnalyticsEnabled: Bool {
        get { appearanceService.isAnalyticsEnabled }
        set {
            pendingAnalyticsValue = newValue
            showingAnalyticsAlert = true
        }
    }
    
    func confirmAnalyticsToggle() {
        appearanceService.isAnalyticsEnabled = pendingAnalyticsValue
        analyticsService.setEnabled(pendingAnalyticsValue)
    }
    
    func trackScreen() {
        analyticsService.trackScreen("Settings")
    }
}
