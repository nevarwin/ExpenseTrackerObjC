import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        List {
            ForEach(AppearanceManager.Appearance.allCases) { appearance in
                Button {
                    appearanceManager.userAppearance = appearance
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
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
