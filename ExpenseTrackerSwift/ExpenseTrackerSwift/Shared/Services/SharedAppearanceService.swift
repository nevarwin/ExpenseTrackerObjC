//
//  SharedAppearanceService.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import SwiftUI
import Combine

protocol AppearanceServiceProtocol: ObservableObject {
    var userAppearance: AppearanceManager.Appearance { get set }
    var isAnalyticsEnabled: Bool { get set }
}

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
    
    @Published var userAppearance: AppearanceManager.Appearance = .system {
        didSet {
            UserDefaults.standard.set(userAppearance.rawValue, forKey: "userAppearance")
        }
    }
    
    @Published var isAnalyticsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isAnalyticsEnabled, forKey: "isAnalyticsEnabled")
        }
    }
    
    init() {
        if let savedValue = UserDefaults.standard.string(forKey: "userAppearance"),
           let appearance = AppearanceManager.Appearance(rawValue: savedValue) {
            self.userAppearance = appearance
        }
        
        if UserDefaults.standard.object(forKey: "isAnalyticsEnabled") == nil {
            self.isAnalyticsEnabled = true
        } else {
            self.isAnalyticsEnabled = UserDefaults.standard.bool(forKey: "isAnalyticsEnabled")
        }
    }
}

