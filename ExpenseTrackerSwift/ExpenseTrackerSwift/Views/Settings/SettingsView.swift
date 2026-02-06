import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    NavigationLink(destination: CurrencySettingsView()) {
                        Label("Currency", systemImage: "dollarsign.circle")
                    }
                    
                    NavigationLink(destination: AppearanceSettingsView()) {
                        Label {
                            Text("Appearance")
                        } icon: {
                            Image(systemName: "sun.max.fill") // Generic icon for the menu item
                        }
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
