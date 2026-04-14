import Foundation
import PostHog

final class PostHogManager {
    static let shared = PostHogManager()
    
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
        
        // Initial state
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
