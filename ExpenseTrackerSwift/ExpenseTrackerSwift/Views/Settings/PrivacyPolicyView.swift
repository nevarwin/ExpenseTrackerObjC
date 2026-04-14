import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()
                
                Text("Last Updated: April 14, 2026")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Group {
                    policySection(title: "1. Introduction", content: "Welcome to ExpenseMe. We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, and safeguard your data.")
                    
                    policySection(title: "2. Data We Collect", content: "Local Data: All your financial entries, budgets, and categories are stored locally on your device using Apple's SwiftData. If you enable iCloud sync, this data is securely mirrored to your private iCloud container.\n\nAnalytics: We use PostHog to collect anonymous usage data (e.g., which screens you visit) to help us improve the app experience. This data does not include your financial transactions or personally identifiable information.")
                    
                    policySection(title: "3. How We Use Your Data", content: "We use the data strictly for providing the app's functionality and improving the user interface. We do not sell or share your personal data with third parties for marketing purposes.")
                    
                    policySection(title: "4. Third-Party Services", content: "PostHog: Used for anonymous usage analytics.\nApple iCloud: Used for cross-device synchronization if enabled by the user.")
                }
                
                Group {
                    policySection(title: "5. Your Choices", content: "You can opt-out of analytics at any time via the Settings menu. You can also disable iCloud sync in your device's system settings.")
                    
                    policySection(title: "6. Security", content: "We use industry-standard security measures provided by Apple (Keychain, iCloud encryption) to ensure your data remains private and secure.")
                    
                    policySection(title: "7. Contact Us", content: "If you have any questions about this Privacy Policy, please contact us at ravencsolis@gmail.com.")
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundColor(.primary.opacity(0.8))
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
