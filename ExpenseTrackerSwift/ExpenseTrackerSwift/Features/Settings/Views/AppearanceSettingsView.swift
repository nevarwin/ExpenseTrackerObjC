//
//  AppearanceSettingsView.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var appearanceManager: SharedAppearanceService
    @Environment(\.analyticsService) private var analyticsService
    
    var body: some View {
        List {
            ForEach(Appearance.allCases) { appearance in
                Button {
                    appearanceManager.userAppearance = appearance
                    analyticsService.trackEvent("Appearance Changed", properties: ["appearance": appearance.title])
                } label: {
                    HStack {
                        Label(appearance.title, systemImage: appearance.icon)
                            .foregroundStyle(Color.appPrimary)
                        
                        Spacer()
                        
                        if appearanceManager.userAppearance == appearance {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                }
                .accessibilityIdentifier("appearance_option_\(appearance.rawValue)")
            }
        }
        .accessibilityIdentifier("appearance_list")
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AppearanceSettingsView()
        .environmentObject(SharedAppearanceService.instance)
}
