import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    
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
                    
                    Toggle(isOn: $appearanceManager.isAnalyticsEnabled) {
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
                    
                    Button {
                        let email = "ravencsolis@gmail.com"
                        let subject = String(localized: "ExpenseMe Support Request")
                        let body = "\n\n--- \(String(localized: "Device Info")) ---\n\(String(localized: "Version")): \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
                        
                        let mailto = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                        
                        if let url = URL(string: mailto) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
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
    }
}

#Preview {
    SettingsView()
        .environmentObject(CurrencyManager())
}
