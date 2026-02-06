import SwiftUI
import Combine

class AppearanceManager: ObservableObject {
    @Published var userAppearance: Appearance = .system {
        didSet {
            UserDefaults.standard.set(userAppearance.rawValue, forKey: "userAppearance")
        }
    }
    
    init() {
        if let savedValue = UserDefaults.standard.string(forKey: "userAppearance"),
           let appearance = Appearance(rawValue: savedValue) {
            self.userAppearance = appearance
        }
    }
}

extension AppearanceManager {
    enum Appearance: String, CaseIterable, Identifiable {
        case system
        case light
        case dark
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
        
        var icon: String {
            switch self {
            case .system: return "gearshape"
            case .light: return "sun.max"
            case .dark: return "moon"
            }
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
}
