//  
//  SettingsFactory.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import Foundation
import SwiftUI

@MainActor
final class SettingsFactory {

    static func make() -> UIViewController {
        let view = SettingsView(
            appearanceService: SharedAppearanceService.instance,
            analyticsService: SharedAnalyticsService.instance
        )
        return UIHostingController(rootView: view)
    }

}
