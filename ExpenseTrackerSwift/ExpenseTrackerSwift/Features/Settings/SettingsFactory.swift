//  
//  SettingsFactory.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import SwiftUI

final class SettingsFactory {

    @MainActor
        static func make() -> some View {
            SettingsView(
                appearanceService: SharedAppearanceService.instance,
                analyticsService: SharedAnalyticsService.instance
            )
        }

}
