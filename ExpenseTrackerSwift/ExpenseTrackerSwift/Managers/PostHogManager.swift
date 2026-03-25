import Foundation
import PostHog

final class PostHogManager {
    static let shared = PostHogManager()
    
    private init() {}
    
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
    }
    
    func trackScreen(_ screenName: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.screen(screenName, properties: properties)
    }
    
    func trackEvent(_ eventName: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.capture(eventName, properties: properties)
    }
}
