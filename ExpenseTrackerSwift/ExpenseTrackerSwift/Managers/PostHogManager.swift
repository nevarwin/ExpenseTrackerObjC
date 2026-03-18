import Foundation
import PostHog

final class PostHogManager {
    static let shared = PostHogManager()
    
    private init() {}
    
    func setup() {
        // Retrieve the API Key from Info.plist, which gets it from Secrets.xcconfig
        guard let posthogKey = Bundle.main.object(forInfoDictionaryKey: "PostHogAPIKey") as? String,
              !posthogKey.isEmpty else {
            print("Warning: PostHogAPIKey is missing from Info.plist / Secrets.xcconfig")
            return
        }
        
        let configuration = PostHogConfig(
            apiKey: posthogKey,
            host: "https://us.i.posthog.com"
        )
        
        #if DEBUG
        configuration.debug = true
        // Flush every event immediately instead of batching it every 30s
        configuration.flushAt = 1
        #endif
        
        // Disable automatic screen tracking if you want to manually track only specific screens
        // configuration.captureScreenViews = false 
        
        PostHogSDK.shared.setup(configuration)
    }
    
    func trackScreen(_ screenName: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.screen(screenName, properties: properties)
    }
    
    func trackEvent(_ eventName: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.capture(eventName, properties: properties)
    }
}
