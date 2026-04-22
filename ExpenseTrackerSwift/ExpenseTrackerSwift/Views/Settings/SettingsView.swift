import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    @State private var showingAnalyticsAlert = false
    @State private var pendingAnalyticsValue = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "General")) {
                    NavigationLink(destination: CurrencySettingsView()) {
                        Label(String(localized: "Currency"), systemImage: "dollarsign.circle")
                    }
                    
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Label {
                            Text(String(localized: "Appearance"))
                        } icon: {
                            Image(systemName: "sun.max")
                        }
                    }
                    
                    Toggle(isOn: Binding(
                        get: { appearanceManager.isAnalyticsEnabled },
                        set: { newValue in
                            pendingAnalyticsValue = newValue
                            showingAnalyticsAlert = true
                        }
                    )) {
                        Label(String(localized: "Analytics"), systemImage: "chart.bar")
                    }
                    .onChange(of: appearanceManager.isAnalyticsEnabled) { _, newValue in
                        PostHogManager.shared.setEnabled(newValue)
                    }
                }
                
                Section(String(localized: "Legal & Support")) {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label(String(localized: "Privacy Policy"), systemImage: "shield.lefthalf.filled")
                    }
                    
                    NavigationLink(destination: ContactSupportView()) {
                        Label(String(localized: "Contact Support"), systemImage: "envelope")
                    }
                }
                
                Section(String(localized: "About")) {
                    LabeledContent(String(localized: "Version"), value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .onAppear {
                PostHogManager.shared.trackScreen("Settings")
            }
        }
        .alert(pendingAnalyticsValue ? String(localized: "Enable Analytics?") : String(localized: "Disable Analytics?"), isPresented: $showingAnalyticsAlert) {
            Button(pendingAnalyticsValue ? String(localized: "Enable") : String(localized: "Disable"), role: pendingAnalyticsValue ? .none : .destructive) {
                appearanceManager.isAnalyticsEnabled = pendingAnalyticsValue
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            if pendingAnalyticsValue {
                Text(String(localized: "Enabling analytics helps us improve the app by understanding how it's used. No personal data is collected."))
            } else {
                Text(String(localized: "Are you sure you want to disable analytics? This will limit our ability to improve the app based on your usage."))
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CurrencyManager())
}
