//
//  SharedAnalyticsService.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import Foundation
import PostHog

protocol AnalyticsServiceProtocol: Sendable {
    func setup()
    func trackScreen(_ screenName: String, properties: [String: Any]?)
    func trackEvent(_ eventName: String, properties: [String: Any]?)
    func setEnabled(_ enabled: Bool)
}

final class SharedAnalyticsService: AnalyticsServiceProtocol {

    private static var _instance: SharedAnalyticsService?
    
    static var instance: AnalyticsServiceProtocol {
        guard let instance = _instance else {
            fatalError("Please configure SharedAnalyticsService first.")
        }
        return instance
    }
    
    static func configure() {
        guard _instance == nil else { return }
        _instance = SharedAnalyticsService()
    }
    
    private init() {}
    
    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "isAnalyticsEnabled")
    }
    
    func setup() {
        guard let posthogKey = Bundle.main.object(forInfoDictionaryKey: "PostHogAPIKey") as? String,
              !posthogKey.isEmpty else {
            print("Warning: PostHogAPIKey is missing from Info.plist / Secrets.xcconfig")
            return
        }
        
        let configuration = PostHogConfig(
            apiKey: posthogKey,
            host: "https://us.i.posthog.com"
        )
        PostHogSDK.shared.setup(configuration)
        
        if isEnabled {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
        }
    }
    
    func trackScreen(_ screenName: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        PostHogSDK.shared.screen(screenName, properties: properties)
    }
    
    func trackEvent(_ eventName: String, properties: [String: Any]? = nil) {
        guard isEnabled else { return }
        PostHogSDK.shared.capture(eventName, properties: properties)
    }
    
    func setEnabled(_ enabled: Bool) {
        if enabled {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
        }
    }
}
