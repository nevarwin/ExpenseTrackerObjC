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
        appearanceService: SharedAppearanceService = SharedAppearanceService.instance,
        analyticsService: AnalyticsServiceProtocol = SharedAnalyticsService.instance
    ) {
        self.appearanceService = appearanceService
        self.analyticsService = analyticsService
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
