import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    NavigationLink(destination: CurrencySettingsView()) {
                        Label("Currency", systemImage: "dollarsign.circle")
                    }
                }
                
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CurrencyManager())
}
