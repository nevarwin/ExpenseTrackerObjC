//
//  SettingsView.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import SwiftUI

@MainActor
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    
    init(viewModel: SettingsViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? SettingsViewModel())
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "General")) {
                    NavigationLink(destination: CurrencySettingsView()) {
                        Label(String(localized: "Currency"), systemImage: "dollarsign.circle")
                    }
                    .accessibilityIdentifier("settings_currency_link")
                    
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Label {
                            Text(String(localized: "Appearance"))
                        } icon: {
                            Image(systemName: "sun.max")
                        }
                    }
                    .accessibilityIdentifier("settings_appearance_link")
                    
                    Toggle(isOn: $viewModel.isAnalyticsEnabled) {
                        Label(String(localized: "Analytics"), systemImage: "chart.bar")
                    }
                    .accessibilityIdentifier("settings_analytics_toggle")
                }
                
                Section(String(localized: "Data Management")) {
                    if let templateURL = Bundle.main.excelTemplateURL {
                        ShareLink(item: templateURL, preview: SharePreview(String(localized: "Import Template"), image: Image(systemName: "tablecells"))) {
                            Label(String(localized: "Download Import Template"), systemImage: "square.and.arrow.down")
                        }
                        .accessibilityIdentifier("settings_download_template_link")
                    }
                }
                
                Section(String(localized: "Legal & Support")) {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label(String(localized: "Privacy Policy"), systemImage: "shield.lefthalf.filled")
                    }
                    .accessibilityIdentifier("settings_privacy_link")
                    
                    NavigationLink(destination: ContactSupportView()) {
                        Label(String(localized: "Contact Support"), systemImage: "envelope")
                    }
                    .accessibilityIdentifier("settings_contact_link")
                }
                
                Section(String(localized: "About")) {
                    LabeledContent(String(localized: "Version"), value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .accessibilityIdentifier("settings_version_label")
                }
            }
            .accessibilityIdentifier("settings_list")
            .navigationTitle(String(localized: "Settings"))
            .onAppear {
                viewModel.trackScreen()
            }
        }
        .alert(
            viewModel.pendingAnalyticsValue ? String(localized: "Enable Analytics?") : String(localized: "Disable Analytics?"),
            isPresented: $viewModel.showingAnalyticsAlert
        ) {
            Button(
                viewModel.pendingAnalyticsValue ? String(localized: "Enable") : String(localized: "Disable"),
                role: viewModel.pendingAnalyticsValue ? .none : .destructive
            ) {
                viewModel.confirmAnalyticsToggle()
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            if viewModel.pendingAnalyticsValue {
                Text(String(localized: "Enabling analytics helps us improve the app by understanding how it's used. No personal data is collected."))
            } else {
                Text(String(localized: "Are you sure you want to disable analytics? This will limit our ability to improve the app based on your usage."))
            }
        }
    }
}

