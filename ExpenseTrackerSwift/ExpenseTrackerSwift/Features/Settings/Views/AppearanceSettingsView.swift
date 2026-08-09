//
//  AppearanceSettingsView.swift
//  ExpenseTrackerSwift
//

import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var appearanceManager: SharedAppearanceService
    @Environment(\.analyticsService) private var analyticsService

    var body: some View {
        List {
            Section(header: Text("Theme Mode")) {
                ForEach(Appearance.allCases) { appearance in
                    Button {
                        appearanceManager.userAppearance = appearance
                        appearanceManager.triggerHaptic(.light)
                        analyticsService.trackEvent("Appearance Changed", properties: ["appearance": appearance.title])
                    } label: {
                        HStack {
                            Label(appearance.title, systemImage: appearance.icon)
                                .foregroundStyle(Color.appPrimary)
                            
                            Spacer()
                            
                            if appearanceManager.userAppearance == appearance {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(appearanceManager.selectedAccent.color)
                            }
                        }
                    }
                    .accessibilityIdentifier("appearance_option_\(appearance.rawValue)")
                }
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
