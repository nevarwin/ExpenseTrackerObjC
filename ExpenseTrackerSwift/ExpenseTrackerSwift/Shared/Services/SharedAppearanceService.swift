//
//  SharedAppearanceService.swift
//  ExpenseTrackerSwift
//

import SwiftUI
import Combine
import UIKit

// MARK: - Appearance Enum

enum Appearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "gearshape"
        case .light:  return "sun.max"
        case .dark:   return "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Protocol

protocol AppearanceServiceProtocol: ObservableObject {
    var userAppearance: Appearance { get set }
    var selectedAccent: AccentTheme { get set }
    var isAnalyticsEnabled: Bool { get set }
    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle)
}

// MARK: - Service

final class SharedAppearanceService: AppearanceServiceProtocol {

    private static var _instance: SharedAppearanceService?

    static var instance: SharedAppearanceService {
        guard let instance = _instance else {
            fatalError("Please configure SharedAppearanceService first.")
        }
        return instance
    }

    static func configure() {
        guard _instance == nil else { return }
        _instance = SharedAppearanceService()
    }

    @Published var userAppearance: Appearance = .system {
        didSet {
            UserDefaults.standard.set(userAppearance.rawValue, forKey: "userAppearance")
        }
    }

    var selectedAccent: AccentTheme {
        get { .emerald }
        set { }
    }

    @Published var isAnalyticsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isAnalyticsEnabled, forKey: "isAnalyticsEnabled")
        }
    }

    init() {
        if let savedValue = UserDefaults.standard.string(forKey: "userAppearance"),
           let appearance = Appearance(rawValue: savedValue) {
            self.userAppearance = appearance
        }

        if UserDefaults.standard.object(forKey: "isAnalyticsEnabled") == nil {
            self.isAnalyticsEnabled = true
        } else {
            self.isAnalyticsEnabled = UserDefaults.standard.bool(forKey: "isAnalyticsEnabled")
        }
    }

    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
