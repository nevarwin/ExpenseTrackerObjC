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

            Section(header: Text("Accent Color")) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: AppSpacing.md) {
                    ForEach(AccentTheme.allCases) { theme in
                        Button {
                            appearanceManager.selectedAccent = theme
                            appearanceManager.triggerHaptic(.medium)
                            analyticsService.trackEvent("Accent Theme Changed", properties: ["accent": theme.title])
                        } label: {
                            VStack(spacing: AppSpacing.xs) {
                                ZStack {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 44, height: 44)
                                    
                                    if appearanceManager.selectedAccent == theme {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                
                                Text(theme.title)
                                    .font(.caption2)
                                    .foregroundStyle(Color.appSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(BouncyButtonStyle())
                        .accessibilityIdentifier("accent_option_\(theme.rawValue)")
                    }
                }
                .padding(.vertical, AppSpacing.sm)
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
